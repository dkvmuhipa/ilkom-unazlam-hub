-- Migration: 20261011_allow_anon_directory_and_dues.sql
-- Description:
-- Mengatasi permission denied 401/42501 saat mengakses RPC get_class_directory dan tabel treasury_dues.
-- 1. Berikan hak akses eksekusi RPC get_class_directory() ke role anon dan authenticated.
--    Fungsi get_class_directory() bertipe SECURITY DEFINER dan hanya mengembalikan
--    data publik direktori mahasiswa aktif (nama, nim, peminatan, semester, prodi, kelas, no_wa, instagram, linkedin).
-- 2. Berikan hak akses SELECT pada tabel treasury_dues ke role anon dan authenticated,
--    serta tambahkan kebijakan RLS SELECT untuk anon agar modul kas kelas tidak memicu 401.
-- 3. Berikan hak akses SELECT pada tabel student_course_grades ke role anon dan authenticated
--    agar modul KHS/Transkrip Nilai dapat dibaca tanpa error 401.

BEGIN;

-- 1. Izin RPC get_class_directory() untuk anon dan authenticated
GRANT EXECUTE ON FUNCTION public.get_class_directory() TO anon, authenticated;

-- 2. Izin tabel treasury_dues untuk anon dan authenticated
GRANT SELECT ON TABLE public.treasury_dues TO anon, authenticated;

DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
CREATE POLICY treasury_dues_anon_read
  ON public.treasury_dues FOR SELECT TO anon
  USING (true);

-- 3. Izin tabel student_course_grades untuk anon dan authenticated
GRANT SELECT ON TABLE public.student_course_grades TO anon, authenticated;

DROP POLICY IF EXISTS student_course_grades_anon_read ON public.student_course_grades;
CREATE POLICY student_course_grades_anon_read
  ON public.student_course_grades FOR SELECT TO anon
  USING (true);

COMMIT;
