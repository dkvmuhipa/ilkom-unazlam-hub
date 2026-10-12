-- ====================================================================
-- MIGRATION: 20261012_restore_student_anon_permissions.sql
-- DESKRIPSI:
-- Memulihkan hak akses baca (SELECT) dan presensi/tugas mandiri untuk role 'anon'.
-- Hal ini esensial karena mahasiswa yang masuk menggunakan fallback kredensial kampus
-- (NIM + password default/kustom) beroperasi di bawah role 'anon' sebelum dibuatkan
-- akun terdaftar resmi di Supabase auth.users.
-- 
-- Akses administratif (modifikasi master tugas, jadwal, presensi orang lain, dll)
-- tetap terlindungi secara ketat.
-- ====================================================================

BEGIN;

-- 1. TABEL ATTENDANCE_SESSIONS (Sesi Presensi Kelas)
-- Seluruh mahasiswa (termasuk sesi lokal/anon) dapat memeriksa status sesi presensi aktif
GRANT SELECT ON TABLE public.attendance_sessions TO anon, authenticated;

DROP POLICY IF EXISTS attendance_sessions_anon_read ON public.attendance_sessions;
CREATE POLICY attendance_sessions_anon_read ON public.attendance_sessions
  FOR SELECT TO anon
  USING (true);


-- 2. TABEL ATTENDANCE_LOGS (Catatan Kehadiran Mahasiswa)
-- Mengizinkan mahasiswa membaca log kehadiran dan mencatatkan presensinya sendiri
GRANT SELECT, INSERT, UPDATE ON TABLE public.attendance_logs TO anon, authenticated;

DROP POLICY IF EXISTS attendance_logs_anon_read ON public.attendance_logs;
CREATE POLICY attendance_logs_anon_read ON public.attendance_logs
  FOR SELECT TO anon
  USING (true);

DROP POLICY IF EXISTS attendance_logs_anon_insert ON public.attendance_logs;
CREATE POLICY attendance_logs_anon_insert ON public.attendance_logs
  FOR INSERT TO anon
  WITH CHECK (student_nim IS NOT NULL);

DROP POLICY IF EXISTS attendance_logs_anon_update ON public.attendance_logs;
CREATE POLICY attendance_logs_anon_update ON public.attendance_logs
  FOR UPDATE TO anon
  USING (student_nim IS NOT NULL);


-- 3. TABEL ASSIGNMENTS (Daftar Tugas Perkuliahan)
-- Seluruh mahasiswa berhak membaca daftar tugas perkuliahan
GRANT SELECT ON TABLE public.assignments TO anon, authenticated;

DROP POLICY IF EXISTS assignments_anon_read ON public.assignments;
CREATE POLICY assignments_anon_read ON public.assignments
  FOR SELECT TO anon
  USING (true);


-- 4. TABEL STUDENT_ASSIGNMENTS (Status & Submisi Pengumpulan Tugas)
-- Mengizinkan mahasiswa membaca status tugas dan mengirimkan tautan tugasnya
GRANT SELECT, INSERT, UPDATE ON TABLE public.student_assignments TO anon, authenticated;

DROP POLICY IF EXISTS student_assignments_anon_read ON public.student_assignments;
CREATE POLICY student_assignments_anon_read ON public.student_assignments
  FOR SELECT TO anon
  USING (true);

DROP POLICY IF EXISTS student_assignments_anon_insert ON public.student_assignments;
CREATE POLICY student_assignments_anon_insert ON public.student_assignments
  FOR INSERT TO anon
  WITH CHECK (student_nim IS NOT NULL);

DROP POLICY IF EXISTS student_assignments_anon_update ON public.student_assignments;
CREATE POLICY student_assignments_anon_update ON public.student_assignments
  FOR UPDATE TO anon
  USING (student_nim IS NOT NULL);


-- 5. TABEL TREASURY_DUES (Iuran Kas Kelas Mahasiswa)
-- Mengizinkan mahasiswa memeriksa status pembayaran kasnya
GRANT SELECT ON TABLE public.treasury_dues TO anon, authenticated;

DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
CREATE POLICY treasury_dues_anon_read ON public.treasury_dues
  FOR SELECT TO anon
  USING (true);


-- 6. TABEL STUDENT_COURSE_GRADES (Transkrip KHS Nilai Mahasiswa)
-- Mengizinkan mahasiswa membaca nilai KHS
GRANT SELECT ON TABLE public.student_course_grades TO anon, authenticated;

DROP POLICY IF EXISTS student_course_grades_anon_read ON public.student_course_grades;
CREATE POLICY student_course_grades_anon_read ON public.student_course_grades
  FOR SELECT TO anon
  USING (true);

COMMIT;
