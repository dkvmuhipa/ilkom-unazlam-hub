-- ====================================================================
-- MIGRATION: 20261011_fix_assignments_edit_delete_rls.sql
-- DESKRIPSI:
-- Membuka izin penuh UPDATE dan DELETE pada tabel assignments & student_assignments
-- untuk peran anon dan authenticated, sehingga ketua kelas & admin dapat
-- melakukan edit dan hapus tugas tanpa terhalang RLS policy lama.
-- ====================================================================

BEGIN;

-- 1. Berikan hak akses penuh pada tabel assignments
GRANT ALL ON TABLE public.assignments TO anon, authenticated;

-- Drop policy lama yang membatasi update/delete pada authenticated
DROP POLICY IF EXISTS assignments_update_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_delete_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;

-- Buat policy baru yang mengizinkan seluruh operasi untuk anon & authenticated
CREATE POLICY assignments_all_manage ON public.assignments
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 2. Berikan hak akses penuh pada tabel student_assignments
GRANT ALL ON TABLE public.student_assignments TO anon, authenticated;

DROP POLICY IF EXISTS student_assignments_anon_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_all_manage ON public.student_assignments;

CREATE POLICY student_assignments_all_manage ON public.student_assignments
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

COMMIT;
