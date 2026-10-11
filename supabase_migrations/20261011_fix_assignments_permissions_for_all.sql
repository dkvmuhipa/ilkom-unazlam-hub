-- ====================================================================
-- MIGRATION: 20261011_fix_assignments_permissions_for_all.sql
-- DESKRIPSI:
-- Memperbaiki izin penuh INSERT, UPDATE, dan DELETE pada tabel assignments & student_assignments
-- agar dapat beroperasi baik dengan autentikasi langsung maupun mode anon / sesi lokal portal.
-- ====================================================================

BEGIN;

-- 1. TABEL ASSIGNMENTS
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

-- Berikan hak akses penuh pada tabel assignments
GRANT ALL ON TABLE public.assignments TO anon, authenticated;

-- Bersihkan seluruh policy lama yang berpotensi membatasi
DROP POLICY IF EXISTS assignments_manage_all ON public.assignments;
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_officer_write ON public.assignments;
DROP POLICY IF EXISTS assignments_read_all ON public.assignments;
DROP POLICY IF EXISTS assignments_read ON public.assignments;
DROP POLICY IF EXISTS assignments_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_update_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_delete_officer ON public.assignments;

-- Buat policy komprehensif: SELECT, INSERT, UPDATE, DELETE diizinkan untuk anon & authenticated
CREATE POLICY assignments_manage_all ON public.assignments
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 2. TABEL STUDENT_ASSIGNMENTS (Submisi & Catatan Pengumpulan Mahasiswa)
ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;

-- Berikan hak akses penuh pada tabel student_assignments
GRANT ALL ON TABLE public.student_assignments TO anon, authenticated;

DROP POLICY IF EXISTS student_assignments_manage_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_all_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_anon_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_own ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_insert_own ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_update_own ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_grade_update ON public.student_assignments;

CREATE POLICY student_assignments_manage_all ON public.student_assignments
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 3. Hapus data tugas uji coba (BLABLA TEST) yang sebelumnya gagal terhapus
DELETE FROM public.student_assignments WHERE assignment_id = '72aace91-dee9-4e0c-8691-b0e4f099fa69';
DELETE FROM public.assignments WHERE id = '72aace91-dee9-4e0c-8691-b0e4f099fa69';

COMMIT;
