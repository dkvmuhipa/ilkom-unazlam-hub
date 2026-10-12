-- ====================================================================
-- MIGRATION: 20261012_security_audit_rls_hardening.sql
-- DESKRIPSI:
-- Hasil Audit Keamanan OWASP Top 10 (Broken Access Control):
-- 1. Menutup izin 'FOR ALL TO anon' pada tabel assignments & student_assignments.
-- 2. Memastikan hanya pengurus resmi (Admin, Ketua Kelas, Sekretaris) yang dapat
--    menghapus, mengubah, atau membuat tugas baru.
-- 3. Memastikan mahasiswa hanya dapat mengumpulkan dan melihat tugas miliknya sendiri.
-- 4. Menutup izin publik anon pada tabel student_course_grades (KHS Nilai Mahasiswa)
--    dan treasury_dues (Catatan Keuangan/Tunggakan Kas Mahasiswa).
-- 5. Membatasi tabel attendance_sessions & attendance_logs agar tidak dapat dipalsukan.
-- ====================================================================

BEGIN;

-- 1. PERKUAT TABEL ASSIGNMENTS (Tugas Kelas)
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

-- Bersihkan policy lama yang terlalu longgar
DROP POLICY IF EXISTS assignments_manage_all ON public.assignments;
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_read_all ON public.assignments;
DROP POLICY IF EXISTS assignments_read_authenticated ON public.assignments;
DROP POLICY IF EXISTS assignments_manage_officer ON public.assignments;

-- Seluruh mahasiswa (terautentikasi) dapat membaca tugas
CREATE POLICY assignments_read_authenticated ON public.assignments
  FOR SELECT TO authenticated
  USING (true);

-- Hanya Pengurus Kelas (Ketua Kelas, Sekretaris, Admin) yang dapat mengelola tugas
CREATE POLICY assignments_manage_officer ON public.assignments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'WAKIL KETUA KELAS', 'SEKRETARIS')
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
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'WAKIL KETUA KELAS', 'SEKRETARIS')
        )
    )
    OR (auth.jwt()->>'role') = 'service_role'
  );

-- 2. PERKUAT TABEL STUDENT_ASSIGNMENTS (Submisi Tugas Mahasiswa)
ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS student_assignments_manage_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_all_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_anon_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_secure ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_update ON public.student_assignments;

-- Mahasiswa hanya dapat membaca tugas dirinya sendiri, atau pengurus kelas
CREATE POLICY student_assignments_read_secure ON public.student_assignments
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
        )
    )
  );

-- Mahasiswa hanya dapat mengumpulkan / mengubah data untuk NIM miliknya sendiri
CREATE POLICY student_assignments_self_manage ON public.student_assignments
  FOR INSERT TO authenticated
  WITH CHECK (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
  );

CREATE POLICY student_assignments_self_update ON public.student_assignments
  FOR UPDATE TO authenticated
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

-- 3. PERKUAT TABEL STUDENT_COURSE_GRADES (KHS / Transkrip Nilai)
ALTER TABLE public.student_course_grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS student_course_grades_anon_read ON public.student_course_grades;
DROP POLICY IF EXISTS student_course_grades_secure_read ON public.student_course_grades;

-- Hapus akses anon publik ke KHS
REVOKE SELECT ON TABLE public.student_course_grades FROM anon;

CREATE POLICY student_course_grades_secure_read ON public.student_course_grades
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) = 'ADMIN'
    )
  );

-- 4. PERKUAT TABEL TREASURY_DUES (Kas & Tunggakan Iuran Mahasiswa)
ALTER TABLE public.treasury_dues ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
DROP POLICY IF EXISTS treasury_dues_secure_read ON public.treasury_dues;

-- Hapus akses anon publik ke data iuran
REVOKE SELECT ON TABLE public.treasury_dues FROM anon;

CREATE POLICY treasury_dues_secure_read ON public.treasury_dues
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'BENDAHARA')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'BENDAHARA')
        )
    )
  );

-- 5. PERKUAT TABEL ATTENDANCE_SESSIONS & ATTENDANCE_LOGS (Presensi Kelas)
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.attendance_sessions FROM anon;
GRANT SELECT ON TABLE public.attendance_sessions TO authenticated;
GRANT ALL ON TABLE public.attendance_sessions TO authenticated;

DROP POLICY IF EXISTS attendance_sessions_all_ops ON public.attendance_sessions;
DROP POLICY IF EXISTS attendance_sessions_read_active ON public.attendance_sessions;
DROP POLICY IF EXISTS attendance_sessions_manage_officer ON public.attendance_sessions;

-- Seluruh mahasiswa terautentikasi dapat melihat sesi presensi aktif
CREATE POLICY attendance_sessions_read_active ON public.attendance_sessions
  FOR SELECT TO authenticated
  USING (true);

-- Hanya Admin dan Pengurus Kelas yang dapat mengelola sesi presensi
CREATE POLICY attendance_sessions_manage_officer ON public.attendance_sessions
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'WAKIL KETUA KELAS')
        )
    )
    OR (auth.jwt()->>'role') = 'service_role'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'WAKIL KETUA KELAS')
        )
    )
    OR (auth.jwt()->>'role') = 'service_role'
  );

ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.attendance_logs FROM anon;
GRANT SELECT, INSERT ON TABLE public.attendance_logs TO authenticated;
GRANT ALL ON TABLE public.attendance_logs TO authenticated;

DROP POLICY IF EXISTS attendance_logs_all_ops ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_logs_read ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_logs_insert_self ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_logs_manage_officer ON public.attendance_logs;

-- Mahasiswa hanya dapat melihat catatan kehadirannya sendiri, atau dibaca oleh pengurus
CREATE POLICY attendance_logs_read ON public.attendance_logs
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS', 'WAKIL KETUA KELAS', 'SEKRETARIS')
        )
    )
  );

-- Mahasiswa hanya dapat mengisi catatan kehadiran untuk NIM miliknya sendiri
CREATE POLICY attendance_logs_insert_self ON public.attendance_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) = 'ADMIN'
    )
  );

-- Hanya Pengurus / Admin yang dapat mengubah atau menghapus catatan kehadiran
CREATE POLICY attendance_logs_manage_officer ON public.attendance_logs
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS')
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND (
          UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS')
          OR UPPER(COALESCE(s.jabatan, '')) IN ('ADMIN', 'KETUA KELAS')
        )
    )
  );

COMMIT;
