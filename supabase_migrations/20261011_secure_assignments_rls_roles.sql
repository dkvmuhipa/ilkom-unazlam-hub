-- ====================================================================
-- MIGRATION: 20261011_secure_assignments_rls_roles.sql
-- DESKRIPSI:
-- Memperketat Row Level Security (RLS) pada tabel assignments & student_assignments
-- 1. SELECT (Membaca): Diizinkan untuk semua akun (anon & authenticated) agar
--    seluruh mahasiswa dapat melihat daftar tugas perkuliahan.
-- 2. INSERT / UPDATE / DELETE (Kelola Tugas):
--    Hanya diizinkan untuk akun pengurus kelas (Admin, Ketua Kelas, Wakil Ketua Kelas, Sekretaris)
--    atau sesi terautentikasi resmi.
-- ====================================================================

BEGIN;

-- 1. TABEL ASSIGNMENTS
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

-- Drop policy lama yang terlalu permisif
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_read ON public.assignments;
DROP POLICY IF EXISTS assignments_officer_manage ON public.assignments;

-- Policy 1: Seluruh mahasiswa (anon & authenticated) dapat melihat tugas
CREATE POLICY assignments_read_all ON public.assignments
  FOR SELECT TO anon, authenticated
  USING (true);

-- Policy 2: Hanya pengurus (Admin, Ketua Kelas, Sekretaris) atau admin berwenang yang dapat INSERT/UPDATE/DELETE
CREATE POLICY assignments_officer_write ON public.assignments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('KETUA KELAS', 'WAKIL KETUA KELAS', 'SEKRETARIS', 'ADMIN')
        )
    )
    OR (auth.jwt()->>'role') = 'service_role'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('KETUA KELAS', 'WAKIL KETUA KELAS', 'SEKRETARIS', 'ADMIN')
        )
    )
    OR (auth.jwt()->>'role') = 'service_role'
  );

-- Fallback policy dev/anon sementara jika offline mock token digunakan (opsional, dapat dimatikan di production murni)
-- Dibatasi agar anon tidak bisa sembarangan truncate:
GRANT SELECT ON TABLE public.assignments TO anon;
GRANT ALL ON TABLE public.assignments TO authenticated;

-- 2. TABEL STUDENT_ASSIGNMENTS (Status & Pengumpulan Tugas Mahasiswa)
ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS student_assignments_all_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_manage ON public.student_assignments;

-- Seluruh mahasiswa dapat membaca tugas mereka
CREATE POLICY student_assignments_read_all ON public.student_assignments
  FOR SELECT TO anon, authenticated
  USING (true);

-- Mahasiswa dapat mengelola/mengumpulkan tugas milik dirinya sendiri
CREATE POLICY student_assignments_self_manage ON public.student_assignments
  FOR ALL TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
    )
  )
  WITH CHECK (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
    )
  );

GRANT SELECT, INSERT, UPDATE ON TABLE public.student_assignments TO anon, authenticated;

COMMIT;
