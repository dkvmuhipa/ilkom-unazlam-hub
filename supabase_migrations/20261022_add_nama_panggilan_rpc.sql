-- ====================================================================
-- MIGRATION: 20261022_add_nama_panggilan_rpc.sql
-- DESCRIPTION:
-- Menambahkan kolom nama_panggilan ke tabel public.students dan
-- memperbarui RPC update_student_profile agar mendukung parameter
-- p_nama_panggilan untuk sinkronisasi native nama sapaan mahasiswa.
-- ====================================================================

BEGIN;

-- 1. Tambahkan kolom nama_panggilan ke tabel students jika belum ada
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS nama_panggilan TEXT;

-- 2. Update fungsi RPC update_student_profile dengan dukungan p_nama_panggilan
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
BEGIN
  -- 1. Validasi input NIM
  v_clean_nim := trim(coalesce(p_nim, ''));
  IF v_clean_nim = '' THEN
    RETURN jsonb_build_object('success', false, 'message', 'NIM mahasiswa tidak boleh kosong.');
  END IF;

  -- 2. Cari data mahasiswa di tabel public.students
  SELECT id, nim, nama, email, no_wa, auth_user_id, is_aktif
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

  -- 3. Sanitasi email jika diberikan
  IF p_email IS NOT NULL AND trim(p_email) != '' THEN
    v_target_email := lower(trim(p_email));
    IF v_target_email LIKE '%@student.unazlam.ac.id' OR v_target_email LIKE '%@students.unazlam.ac.id' THEN
      v_target_email := NULL;
    END IF;
  ELSE
    v_target_email := NULL;
  END IF;

  -- 4. Update data profil mahasiswa di tabel public.students
  UPDATE public.students
  SET
    email = CASE 
      WHEN v_target_email IS NOT NULL THEN v_target_email 
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
    avatar_url = CASE 
      WHEN p_avatar_url IS NOT NULL THEN p_avatar_url 
      ELSE avatar_url 
    END,
    nama_panggilan = CASE 
      WHEN p_nama_panggilan IS NOT NULL AND trim(p_nama_panggilan) != '' THEN trim(p_nama_panggilan) 
      ELSE nama_panggilan 
    END
  WHERE nim = v_clean_nim;

  -- 5. Jika mahasiswa terhubung ke auth.users dan email diperbarui, sinkronkan auth.users
  IF v_student.auth_user_id IS NOT NULL AND v_target_email IS NOT NULL THEN
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
    'message', 'Profil, foto, dan nama panggilan mahasiswa berhasil diperbarui di database.',
    'nim', v_clean_nim
  );
END;
$$;

-- Izin eksekusi untuk anon, authenticated, dan service_role
GRANT EXECUTE ON FUNCTION public.update_student_profile(text, text, text, text, text, text, text, text, text, text) TO anon, authenticated, service_role;

COMMIT;
