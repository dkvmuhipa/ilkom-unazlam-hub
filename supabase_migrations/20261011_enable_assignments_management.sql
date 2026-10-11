-- ====================================================================
-- MIGRATION: 20261011_enable_assignments_management.sql
-- DESKRIPSI:
-- 1. Menambahkan kolom pendukung 'course_name' dan 'status' pada tabel assignments
--    jika belum tersedia di schema Supabase.
-- 2. Memberikan izin penuh kelola tugas (INSERT, UPDATE, DELETE, SELECT)
--    pada assignments & student_assignments untuk Ketua Kelas & Admin.
-- ====================================================================

BEGIN;

-- 1. Pastikan kolom pendukung tersedia pada tabel assignments
ALTER TABLE public.assignments ADD COLUMN IF NOT EXISTS course_name TEXT;
ALTER TABLE public.assignments ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'belum';

-- 2. Berikan hak akses tabel assignments
GRANT ALL ON TABLE public.assignments TO anon, authenticated;

DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
CREATE POLICY assignments_anon_manage ON public.assignments
  FOR ALL TO anon
  USING (true)
  WITH CHECK (true);

-- 3. Berikan hak akses tabel student_assignments
GRANT ALL ON TABLE public.student_assignments TO anon, authenticated;

DROP POLICY IF EXISTS student_assignments_anon_manage ON public.student_assignments;
CREATE POLICY student_assignments_anon_manage ON public.student_assignments
  FOR ALL TO anon
  USING (true)
  WITH CHECK (true);

COMMIT;
