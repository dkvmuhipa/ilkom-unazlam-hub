-- Migration: 20261013_student_self_reset_password.sql
-- Description: RPC function for secure self-service password reset and active email setup for students.
-- Uses active personal email (e.g. Gmail), eliminating dependence on nonexistent student.unazlam.ac.id domain.
-- Verifies student identity via NIM and registered contact (WhatsApp/phone), hashes password with Bcrypt,
-- updates public.students.email to student's active email, and syncs auth.users.

BEGIN;

CREATE OR REPLACE FUNCTION public.student_self_reset_password(
  p_nim text,
  p_verification text,
  p_new_password text,
  p_active_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, pg_temp
AS $$
DECLARE
  v_student record;
  v_clean_input_contact text;
  v_clean_student_phone text;
  v_auth_user_id uuid;
  v_target_email text;
  v_encrypted_pass text;
BEGIN
  -- 1. Validasi input dasar
  IF p_nim IS NULL OR trim(p_nim) = '' THEN
    RETURN jsonb_build_object('success', false, 'message', 'NIM wajib diisi.');
  END IF;

  IF p_verification IS NULL OR trim(p_verification) = '' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nomor WhatsApp verifikasi wajib diisi.');
  END IF;

  IF p_new_password IS NULL OR length(trim(p_new_password)) < 8 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Kata sandi baru minimal harus 8 karakter.');
  END IF;

  -- 2. Cari data mahasiswa aktif
  SELECT id, nim, nama, email, no_wa, auth_user_id, is_aktif
  INTO v_student
  FROM public.students
  WHERE nim = trim(p_nim) AND is_aktif = true
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Mahasiswa dengan NIM tersebut tidak ditemukan atau akun dinonaktifkan.');
  END IF;

  -- 3. Verifikasi Keamanan: Cocokkan kontak verifikasi (WhatsApp ATAU Email)
  v_clean_input_contact := regexp_replace(trim(p_verification), '\D', '', 'g');
  v_clean_student_phone := regexp_replace(coalesce(v_student.no_wa, ''), '\D', '', 'g');

  -- Normalisasi nomor telepon (08... vs 628...)
  IF v_clean_input_contact LIKE '0%' AND v_clean_student_phone LIKE '62%' THEN
    v_clean_input_contact := '62' || substring(v_clean_input_contact FROM 2);
  ELSIF v_clean_input_contact LIKE '62%' AND v_clean_student_phone LIKE '0%' THEN
    v_clean_student_phone := '62' || substring(v_clean_student_phone FROM 2);
  END IF;

  IF (v_clean_input_contact = '' OR v_clean_input_contact != v_clean_student_phone)
     AND lower(trim(p_verification)) != lower(trim(coalesce(v_student.email, ''))) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Verifikasi gagal. Nomor WhatsApp tidak cocok dengan data profil Anda yang terdaftar.'
    );
  END IF;

  -- 4. Tentukan Email Aktif Mahasiswa (TIDAK MENGGUNAKAN domain student.unazlam.ac.id yang belum ada)
  IF p_active_email IS NOT NULL AND trim(p_active_email) != '' THEN
    v_target_email := lower(trim(p_active_email));
  ELSE
    -- Jika parameter email kosong, ambil dari data mahasiswa jika sudah email aktif nyata
    IF v_student.email IS NOT NULL 
       AND v_student.email NOT LIKE '%@student.unazlam.ac.id' 
       AND v_student.email NOT LIKE '%@students.unazlam.ac.id'
       AND v_student.email LIKE '%@%.%' THEN
      v_target_email := lower(trim(v_student.email));
    ELSE
      RETURN jsonb_build_object(
        'success', false,
        'message', 'Alamat email aktif (seperti Gmail/Yahoo) wajib diisi karena domain kampus belum tersedia.'
      );
    END IF;
  END IF;

  -- Validasi format email aktif
  IF v_target_email NOT LIKE '%@%.%' 
     OR v_target_email LIKE '%@student.unazlam.ac.id' 
     OR v_target_email LIKE '%@students.unazlam.ac.id' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Harap masukkan email aktif Anda yang valid (misal: nama@gmail.com). Jangan gunakan domain student.unazlam.ac.id.'
    );
  END IF;

  -- 5. Perbarui email profil mahasiswa di tabel public.students dengan email aktif yang nyata
  UPDATE public.students
  SET email = v_target_email
  WHERE nim = v_student.nim;

  -- 6. Enkripsi kata sandi baru menggunakan Bcrypt
  v_encrypted_pass := crypt(trim(p_new_password), gen_salt('bf'));

  -- 7. Cari / perbarui akun di auth.users Supabase
  IF v_student.auth_user_id IS NOT NULL THEN
    v_auth_user_id := v_student.auth_user_id;
  ELSE
    SELECT id INTO v_auth_user_id
    FROM auth.users
    WHERE lower(email) = v_target_email
    LIMIT 1;
  END IF;

  IF v_auth_user_id IS NOT NULL THEN
    -- Update kata sandi dan email aktif di auth.users secara instan
    UPDATE auth.users
    SET email = v_target_email,
        encrypted_password = v_encrypted_pass,
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_auth_user_id;

    UPDATE public.students
    SET auth_user_id = v_auth_user_id
    WHERE nim = v_student.nim AND auth_user_id IS NULL;
  ELSE
    -- Jika belum ada di auth.users, daftarkan akun baru dengan email aktif mahasiswa
    v_auth_user_id := gen_random_uuid();
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_auth_user_id,
      'authenticated',
      'authenticated',
      v_target_email,
      v_encrypted_pass,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('nama', v_student.nama, 'nim', v_student.nim),
      now(),
      now()
    );

    UPDATE public.students
    SET auth_user_id = v_auth_user_id
    WHERE nim = v_student.nim;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Kata sandi dan email aktif (' || v_target_email || ') berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.'
  );
END;
$$;

-- Izin eksekusi untuk pengguna di layar login
GRANT EXECUTE ON FUNCTION public.student_self_reset_password(text, text, text, text) TO anon, authenticated;

COMMIT;
