-- ====================================================================
-- MIGRATION: 20261011_enable_attendance_and_assignments.sql
-- DESKRIPSI:
-- 1. Mengaktifkan tabel attendance_sessions untuk sinkronisasi sesi presensi realtime
--    antara Pengurus Kelas (Ketua/Dosen) dan seluruh Mahasiswa di kelas.
-- 2. Membuka izin RLS tabel attendance_sessions & attendance_logs untuk anon & authenticated.
-- 3. Membuka izin RLS tabel assignments & student_assignments (fix hapus/edit tugas).
-- ====================================================================

BEGIN;

-- --------------------------------------------------------------------
-- 1. TABEL ATTENDANCE_SESSIONS (Sesi Presensi Aktif Kelas)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_id TEXT,
    course_name TEXT NOT NULL,
    pertemuan_ke INT NOT NULL,
    token TEXT NOT NULL,
    pin_code TEXT,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.attendance_sessions TO anon, authenticated;

DROP POLICY IF EXISTS attendance_sessions_all_ops ON public.attendance_sessions;
CREATE POLICY attendance_sessions_all_ops ON public.attendance_sessions
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- --------------------------------------------------------------------
-- 2. TABEL ATTENDANCE_LOGS (Catatan Kehadiran Mahasiswa)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attendance_logs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_id TEXT REFERENCES courses(id) ON DELETE SET NULL,
    student_nim TEXT NOT NULL,
    pertemuan_ke INT NOT NULL,
    status TEXT NOT NULL, -- 'Hadir', 'Izin', 'Sakit', 'Alpa'
    catatan TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.attendance_logs TO anon, authenticated;

DROP POLICY IF EXISTS attendance_logs_all_ops ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_read_self_or_officer ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_insert_self_or_officer ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_manage_officer ON public.attendance_logs;
DROP POLICY IF EXISTS attendance_delete_officer ON public.attendance_logs;

CREATE POLICY attendance_logs_all_ops ON public.attendance_logs
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- --------------------------------------------------------------------
-- 3. TABEL ASSIGNMENTS & STUDENT_ASSIGNMENTS (Fix Izin Tugas)
-- --------------------------------------------------------------------
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.assignments TO anon, authenticated;

DROP POLICY IF EXISTS assignments_manage_all ON public.assignments;
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_officer_write ON public.assignments;
DROP POLICY IF EXISTS assignments_read_all ON public.assignments;
DROP POLICY IF EXISTS assignments_read ON public.assignments;
DROP POLICY IF EXISTS assignments_manage ON public.assignments;

CREATE POLICY assignments_manage_all ON public.assignments
  FOR ALL TO anon, authenticated
  USING (true)
  WITH CHECK (true);

ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;
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

-- Bersihkan data uji coba lama jika ada
DELETE FROM public.student_assignments WHERE assignment_id = '72aace91-dee9-4e0c-8691-b0e4f099fa69';
DELETE FROM public.assignments WHERE id = '72aace91-dee9-4e0c-8691-b0e4f099fa69';

COMMIT;
