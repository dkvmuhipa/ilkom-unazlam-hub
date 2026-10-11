-- Migration: 20261010_student_login_rpc.sql
-- Description: RPC function get_student_login_email to resolve student email from NIM
-- Allows students to login using NIM by looking up their registered email.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_student_login_email(p_nim text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_email text;
BEGIN
  -- 1. Cari email dari tabel students yang aktif
  SELECT s.email INTO v_email
  FROM public.students s
  WHERE s.nim = trim(p_nim)
    AND s.is_aktif = true
  LIMIT 1;

  -- 2. Jika di tabel students belum ada email, tetapi sudah ditautkan ke auth.users
  IF v_email IS NULL OR trim(v_email) = '' THEN
    SELECT u.email INTO v_email
    FROM public.students s
    JOIN auth.users u ON s.auth_user_id = u.id
    WHERE s.nim = trim(p_nim)
      AND s.is_aktif = true
    LIMIT 1;
  END IF;

  RETURN v_email;
END;
$$;

-- Berikan izin akses eksekusi ke anon (publik sebelum login) dan authenticated
GRANT EXECUTE ON FUNCTION public.get_student_login_email(text) TO anon, authenticated;

COMMIT;
