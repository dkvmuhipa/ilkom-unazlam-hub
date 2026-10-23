-- ====================================================================
-- MIGRATION: 20261022_update_student_profile_rpc.sql
-- DESCRIPTION:
-- 1. Menambahkan kolom pendukung (bio, agama, avatar_url, nama_panggilan) jika belum ada.
-- 2. Membuat RPC function public.update_student_profile dengan proteksi anti-IDOR
--    dan validasi ukuran payload untuk menyimpan foto profil (avatar_url), email pribadi,
--    kontak, peminatan, agama, nama panggilan, dan bio ke tabel public.students.
-- 3. Memperbarui RPC public.get_class_directory agar turut mengembalikan agama
--    dan nama_panggilan.
-- ====================================================================

BEGIN;

-- 1. Pastikan kolom pendukung tersedia di tabel students
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS agama TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS nama_panggilan TEXT;

-- Hapus overload lama jika ada
DROP FUNCTION IF EXISTS public.update_student_profile(text, text, text, text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.update_student_profile(text, text, text, text, text, text, text, text, text, text);

-- 2. Fungsi RPC update_student_profile dengan validasi keamanan (Anti-IDOR & Payload Guard)
CREATE OR REPLACE FUNCTION public.update_student_profile(
  p_nim text,
  p_email text DEFAULT NULL,
  p_no_wa text DEFAULT NULL,
  p_peminatan text DEFAULT NULL,
  p_instagram text DEFAULT NULL,
  p_linkedin text DEFAULT NULL,
  p_bio text DEFAULT NULL,
  p_agama text DEFAULT NULL,
  p_avatar_url text DEFAULT NULL,
  p_nama_panggilan text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_student record;
  v_target_email text;
  v_clean_nim text;
  v_caller_uid uuid;
  v_is_admin boolean := false;
BEGIN
  -- 1. Validasi input NIM & batas ukuran payload (DoS prevention)
  v_clean_nim := trim(coalesce(p_nim, ''));
  IF v_clean_nim = '' THEN
    RETURN jsonb_build_object('success', false, 'message', 'NIM mahasiswa tidak boleh kosong.');
  END IF;

  IF p_avatar_url IS NOT NULL AND length(p_avatar_url) > 350000 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Ukuran data foto profil melebihi batas maksimal (350 KB).');
  END IF;

  IF p_bio IS NOT NULL AND length(p_bio) > 1000 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Bio maksimal 1000 karakter.');
  END IF;

  -- 2. Cari data mahasiswa di tabel public.students
  SELECT id, nim, nama, email, no_wa, role, auth_user_id, is_aktif
  INTO v_student
  FROM public.students
  WHERE nim = v_clean_nim AND is_aktif = true
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Mahasiswa dengan NIM ' || v_clean_nim || ' tidak ditemukan atau status akun tidak aktif.'
    );
  END IF;

  -- 3. Validasi Otorisasi Pemanggil (Anti-IDOR / Account Takeover Protection)
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.students
      WHERE auth_user_id = v_caller_uid AND role = 'ADMIN' AND is_aktif = true
    ) INTO v_is_admin;
  END IF;

  -- Proteksi akun ADMIN: hanya pemilik sesi ADMIN yang sah yang boleh mengubah profil ADMIN
  IF coalesce(v_student.role, '') = 'ADMIN' THEN
    IF v_caller_uid IS NULL OR (v_student.auth_user_id IS NOT NULL AND v_caller_uid != v_student.auth_user_id AND NOT v_is_admin) THEN
      RETURN jsonb_build_object('success', false, 'message', 'Akses ditolak: tidak memiliki izin untuk mengubah profil Administrator.');
    END IF;
  END IF;

  -- Jika pemanggil login via Supabase Auth (v_caller_uid IS NOT NULL), pastikan hanya mengubah profil miliknya sendiri (kecuali Admin)
  IF v_caller_uid IS NOT NULL AND v_student.auth_user_id IS NOT NULL THEN
    IF v_caller_uid != v_student.auth_user_id AND NOT v_is_admin THEN
      RETURN jsonb_build_object('success', false, 'message', 'Akses ditolak: Anda hanya dapat mengubah profil milik sendiri.');
    END IF;
  END IF;

  -- 4. Sanitasi email jika diberikan
  IF p_email IS NOT NULL AND trim(p_email) != '' THEN
    v_target_email := lower(trim(p_email));
    -- Cegah domain dummy kampus yang belum aktif
    IF v_target_email LIKE '%@student.unazlam.ac.id' OR v_target_email LIKE '%@students.unazlam.ac.id' THEN
      v_target_email := NULL;
    END IF;
  ELSE
    v_target_email := NULL;
  END IF;

  -- 5. Update data profil mahasiswa di tabel public.students
  UPDATE public.students
  SET
    email = CASE 
      WHEN v_target_email IS NOT NULL AND (
        (v_caller_uid IS NOT NULL AND (v_caller_uid = v_student.auth_user_id OR v_is_admin))
        OR v_student.auth_user_id IS NULL
        OR coalesce(email, '') = ''
        OR email LIKE '%@student.unazlam.ac.id'
        OR email LIKE '%@students.unazlam.ac.id'
      ) THEN v_target_email 
      ELSE email 
    END,
    no_wa = CASE 
      WHEN p_no_wa IS NOT NULL AND trim(p_no_wa) != '' THEN trim(p_no_wa) 
      ELSE no_wa 
    END,
    peminatan = CASE 
      WHEN p_peminatan IS NOT NULL AND trim(p_peminatan) != '' THEN trim(p_peminatan) 
      ELSE peminatan 
    END,
    instagram = CASE 
      WHEN p_instagram IS NOT NULL THEN NULLIF(trim(p_instagram), '') 
      ELSE instagram 
    END,
    linkedin = CASE 
      WHEN p_linkedin IS NOT NULL THEN NULLIF(trim(p_linkedin), '') 
      ELSE linkedin 
    END,
    bio = CASE 
      WHEN p_bio IS NOT NULL THEN trim(p_bio) 
      ELSE bio 
    END,
    agama = CASE 
      WHEN p_agama IS NOT NULL AND trim(p_agama) != '' THEN trim(p_agama) 
      ELSE agama 
    END,
    nama_panggilan = CASE 
      WHEN p_nama_panggilan IS NOT NULL THEN NULLIF(trim(p_nama_panggilan), '') 
      ELSE nama_panggilan 
    END,
    avatar_url = CASE 
      WHEN p_avatar_url IS NOT NULL THEN p_avatar_url 
      ELSE avatar_url 
    END
  WHERE nim = v_clean_nim;

  -- 6. Sinkronkan auth.users HANYA jika pemanggil terautentikasi sebagai pemilik akun atau Admin
  IF v_caller_uid IS NOT NULL
     AND (v_caller_uid = v_student.auth_user_id OR v_is_admin)
     AND v_student.auth_user_id IS NOT NULL
     AND v_target_email IS NOT NULL THEN
    BEGIN
      UPDATE auth.users
      SET email = v_target_email,
          updated_at = now()
      WHERE id = v_student.auth_user_id;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Profil dan foto mahasiswa berhasil diperbarui di database.',
    'nim', v_clean_nim
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_student_profile(text, text, text, text, text, text, text, text, text, text) TO anon, authenticated, service_role;

-- 3. Perbarui RPC get_class_directory agar mengembalikan agama dan nama_panggilan
DROP FUNCTION IF EXISTS public.get_class_directory();

CREATE OR REPLACE FUNCTION public.get_class_directory()
RETURNS TABLE (
  id text,
  nim text,
  nama text,
  email text,
  no_wa text,
  peminatan text,
  prodi text,
  semester integer,
  kelas text,
  role text,
  jabatan text,
  is_aktif boolean,
  instagram text,
  linkedin text,
  avatar_url text,
  bio text,
  agama text,
  nama_panggilan text
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT 
    s.id::text, 
    s.nim, 
    s.nama, 
    COALESCE(s.email, '') as email,
    COALESCE(s.no_wa, '') as no_wa, 
    COALESCE(s.peminatan, '') as peminatan, 
    COALESCE(s.prodi, 'Ilmu Komunikasi') as prodi, 
    COALESCE(s.semester, 1) as semester,
    COALESCE(s.kelas, 'Ilmu Komunikasi') as kelas, 
    COALESCE(s.role, 'MAHASISWA') as role, 
    COALESCE(s.jabatan, 'Mahasiswa') as jabatan, 
    COALESCE(s.is_aktif, true) as is_aktif, 
    s.instagram, 
    s.linkedin,
    s.avatar_url,
    s.bio,
    s.agama,
    s.nama_panggilan
  FROM public.students s
  WHERE s.is_aktif = true
  ORDER BY s.nama;
$$;

GRANT EXECUTE ON FUNCTION public.get_class_directory() TO anon, authenticated, service_role;

COMMIT;
