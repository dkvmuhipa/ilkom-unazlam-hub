-- Migration: 20261013_full_crud_permissions_fix.sql
-- Description: Fix all CRUD permissions across all features (Announcements, Assignments, Treasury, Attendance, Courses, Resources, Agenda)
-- Ensures INSERT, UPDATE, and DELETE are 100% permitted for both anon and authenticated users,
-- preventing RLS rejections that cause deleted items to reappear or new items to disappear on reload.

BEGIN;

-- ====================================================================
-- 1. PENGUMUMAN KELAS (ANNOUNCEMENTS)
-- ====================================================================
ALTER TABLE IF EXISTS public.announcements ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.announcements TO anon, authenticated, service_role;

DROP POLICY IF EXISTS announcements_read_all ON public.announcements;
DROP POLICY IF EXISTS announcements_insert_all ON public.announcements;
DROP POLICY IF EXISTS announcements_update_all ON public.announcements;
DROP POLICY IF EXISTS announcements_delete_all ON public.announcements;
DROP POLICY IF EXISTS announcements_manage_all ON public.announcements;
DROP POLICY IF EXISTS announcements_read_authenticated ON public.announcements;
DROP POLICY IF EXISTS announcements_insert_officer ON public.announcements;
DROP POLICY IF EXISTS announcements_update_officer ON public.announcements;
DROP POLICY IF EXISTS announcements_delete_officer ON public.announcements;

CREATE POLICY announcements_read_all ON public.announcements
  FOR SELECT TO public USING (true);

CREATE POLICY announcements_insert_all ON public.announcements
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY announcements_update_all ON public.announcements
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY announcements_delete_all ON public.announcements
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 2. TUGAS KULIAH (ASSIGNMENTS & STUDENT_ASSIGNMENTS)
-- ====================================================================
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.assignments TO anon, authenticated, service_role;

DROP POLICY IF EXISTS assignments_read_all ON public.assignments;
DROP POLICY IF EXISTS assignments_insert_all ON public.assignments;
DROP POLICY IF EXISTS assignments_update_all ON public.assignments;
DROP POLICY IF EXISTS assignments_delete_all ON public.assignments;
DROP POLICY IF EXISTS assignments_read_authenticated ON public.assignments;
DROP POLICY IF EXISTS assignments_manage_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_read ON public.assignments;

CREATE POLICY assignments_read_all ON public.assignments
  FOR SELECT TO public USING (true);

CREATE POLICY assignments_insert_all ON public.assignments
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY assignments_update_all ON public.assignments
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY assignments_delete_all ON public.assignments
  FOR DELETE TO public USING (true);

-- SUBMISI TUGAS
ALTER TABLE IF EXISTS public.student_assignments ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.student_assignments TO anon, authenticated, service_role;

DROP POLICY IF EXISTS student_assignments_read_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_insert_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_update_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_delete_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_secure ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_update ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_anon_read ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_anon_insert ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_anon_update ON public.student_assignments;

CREATE POLICY student_assignments_read_all ON public.student_assignments
  FOR SELECT TO public USING (true);

CREATE POLICY student_assignments_insert_all ON public.student_assignments
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY student_assignments_update_all ON public.student_assignments
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY student_assignments_delete_all ON public.student_assignments
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 3. KAS KELAS (TREASURY_TRANSACTIONS & TREASURY_DUES)
-- ====================================================================
ALTER TABLE IF EXISTS public.treasury_transactions ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.treasury_transactions TO anon, authenticated, service_role;

DROP POLICY IF EXISTS treasury_read_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_insert_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_update_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_delete_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_insert_treasurer ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_update_treasurer ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_delete_treasurer ON public.treasury_transactions;

CREATE POLICY treasury_read_all ON public.treasury_transactions
  FOR SELECT TO public USING (true);

CREATE POLICY treasury_insert_all ON public.treasury_transactions
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY treasury_update_all ON public.treasury_transactions
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY treasury_delete_all ON public.treasury_transactions
  FOR DELETE TO public USING (true);

-- IURAN MAHASISWA
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'treasury_dues') THEN
    ALTER TABLE public.treasury_dues ENABLE ROW LEVEL SECURITY;
    GRANT ALL ON TABLE public.treasury_dues TO anon, authenticated, service_role;

    DROP POLICY IF EXISTS treasury_dues_read_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_insert_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_update_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_delete_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_secure_read ON public.treasury_dues;

    CREATE POLICY treasury_dues_read_all ON public.treasury_dues FOR SELECT TO public USING (true);
    CREATE POLICY treasury_dues_insert_all ON public.treasury_dues FOR INSERT TO public WITH CHECK (true);
    CREATE POLICY treasury_dues_update_all ON public.treasury_dues FOR UPDATE TO public USING (true) WITH CHECK (true);
    CREATE POLICY treasury_dues_delete_all ON public.treasury_dues FOR DELETE TO public USING (true);
  END IF;
END $$;



-- ====================================================================
-- 4. JADWAL KULIAH & MATA KULIAH (COURSES)
-- ====================================================================
ALTER TABLE IF EXISTS public.courses ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.courses TO anon, authenticated, service_role;

DROP POLICY IF EXISTS courses_read_all ON public.courses;
DROP POLICY IF EXISTS courses_insert_all ON public.courses;
DROP POLICY IF EXISTS courses_update_all ON public.courses;
DROP POLICY IF EXISTS courses_delete_all ON public.courses;
DROP POLICY IF EXISTS courses_anon_read ON public.courses;

CREATE POLICY courses_read_all ON public.courses
  FOR SELECT TO public USING (true);

CREATE POLICY courses_insert_all ON public.courses
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY courses_update_all ON public.courses
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY courses_delete_all ON public.courses
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 5. BERKAS & MATERI KULIAH (RESOURCES)
-- ====================================================================
ALTER TABLE IF EXISTS public.resources ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.resources TO anon, authenticated, service_role;

DROP POLICY IF EXISTS resources_read_all ON public.resources;
DROP POLICY IF EXISTS resources_insert_all ON public.resources;
DROP POLICY IF EXISTS resources_update_all ON public.resources;
DROP POLICY IF EXISTS resources_delete_all ON public.resources;
DROP POLICY IF EXISTS resources_insert_officer ON public.resources;
DROP POLICY IF EXISTS resources_update_officer ON public.resources;
DROP POLICY IF EXISTS resources_delete_officer ON public.resources;

CREATE POLICY resources_read_all ON public.resources
  FOR SELECT TO public USING (true);

CREATE POLICY resources_insert_all ON public.resources
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY resources_update_all ON public.resources
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY resources_delete_all ON public.resources
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 6. AGENDA KELAS (AGENDA_ITEMS)
-- ====================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'agenda_items') THEN
    ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;
    GRANT ALL ON TABLE public.agenda_items TO anon, authenticated, service_role;

    DROP POLICY IF EXISTS agenda_read_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_insert_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_update_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_delete_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_insert_officer ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_update_officer ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_delete_officer ON public.agenda_items;

    CREATE POLICY agenda_read_all ON public.agenda_items FOR SELECT TO public USING (true);
    CREATE POLICY agenda_insert_all ON public.agenda_items FOR INSERT TO public WITH CHECK (true);
    CREATE POLICY agenda_update_all ON public.agenda_items FOR UPDATE TO public USING (true) WITH CHECK (true);
    CREATE POLICY agenda_delete_all ON public.agenda_items FOR DELETE TO public USING (true);
  END IF;
END $$;


-- ====================================================================
-- 7. PRESENSI KELAS (ATTENDANCE_SESSIONS, ATTENDANCE_RECORDS, ATTENDANCE_LOGS)
-- ====================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_sessions') THEN
    ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
    GRANT ALL ON TABLE public.attendance_sessions TO anon, authenticated, service_role;

    DROP POLICY IF EXISTS attendance_sessions_read_all ON public.attendance_sessions;
    DROP POLICY IF EXISTS attendance_sessions_insert_all ON public.attendance_sessions;
    DROP POLICY IF EXISTS attendance_sessions_update_all ON public.attendance_sessions;
    DROP POLICY IF EXISTS attendance_sessions_delete_all ON public.attendance_sessions;
    DROP POLICY IF EXISTS attendance_sessions_anon_read ON public.attendance_sessions;

    CREATE POLICY attendance_sessions_read_all ON public.attendance_sessions FOR SELECT TO public USING (true);
    CREATE POLICY attendance_sessions_insert_all ON public.attendance_sessions FOR INSERT TO public WITH CHECK (true);
    CREATE POLICY attendance_sessions_update_all ON public.attendance_sessions FOR UPDATE TO public USING (true) WITH CHECK (true);
    CREATE POLICY attendance_sessions_delete_all ON public.attendance_sessions FOR DELETE TO public USING (true);
  END IF;
END $$;


DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_records') THEN
    ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
    GRANT ALL ON TABLE public.attendance_records TO anon, authenticated, service_role;

    DROP POLICY IF EXISTS attendance_records_read_all ON public.attendance_records;
    DROP POLICY IF EXISTS attendance_records_insert_all ON public.attendance_records;
    DROP POLICY IF EXISTS attendance_records_update_all ON public.attendance_records;
    DROP POLICY IF EXISTS attendance_records_delete_all ON public.attendance_records;

    CREATE POLICY attendance_records_read_all ON public.attendance_records FOR SELECT TO public USING (true);
    CREATE POLICY attendance_records_insert_all ON public.attendance_records FOR INSERT TO public WITH CHECK (true);
    CREATE POLICY attendance_records_update_all ON public.attendance_records FOR UPDATE TO public USING (true) WITH CHECK (true);
    CREATE POLICY attendance_records_delete_all ON public.attendance_records FOR DELETE TO public USING (true);
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_logs') THEN
    ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
    GRANT ALL ON TABLE public.attendance_logs TO anon, authenticated, service_role;

    DROP POLICY IF EXISTS attendance_logs_read_all ON public.attendance_logs;
    DROP POLICY IF EXISTS attendance_logs_insert_all ON public.attendance_logs;
    DROP POLICY IF EXISTS attendance_logs_update_all ON public.attendance_logs;
    DROP POLICY IF EXISTS attendance_logs_delete_all ON public.attendance_logs;

    CREATE POLICY attendance_logs_read_all ON public.attendance_logs FOR SELECT TO public USING (true);
    CREATE POLICY attendance_logs_insert_all ON public.attendance_logs FOR INSERT TO public WITH CHECK (true);
    CREATE POLICY attendance_logs_update_all ON public.attendance_logs FOR UPDATE TO public USING (true) WITH CHECK (true);
    CREATE POLICY attendance_logs_delete_all ON public.attendance_logs FOR DELETE TO public USING (true);
  END IF;
END $$;


-- ====================================================================
-- 8. DIREKTORI MAHASISWA (STUDENTS)
-- ====================================================================
ALTER TABLE IF EXISTS public.students ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.students TO anon, authenticated, service_role;

DROP POLICY IF EXISTS students_read_all ON public.students;
DROP POLICY IF EXISTS students_insert_all ON public.students;
DROP POLICY IF EXISTS students_update_all ON public.students;
DROP POLICY IF EXISTS students_delete_all ON public.students;

CREATE POLICY students_read_all ON public.students
  FOR SELECT TO public USING (true);

CREATE POLICY students_insert_all ON public.students
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY students_update_all ON public.students
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY students_delete_all ON public.students
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 9. ARSIP SURAT IZIN (PERMISSION_LETTERS)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.permission_letters (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    student_nim TEXT NOT NULL,
    student_name TEXT NOT NULL,
    letter_type TEXT NOT NULL DEFAULT 'Izin Sakit',
    dosen_name TEXT NOT NULL,
    course_name TEXT NOT NULL,
    reason TEXT NOT NULL,
    letter_date TEXT NOT NULL,
    full_content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE IF EXISTS public.permission_letters ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.permission_letters TO anon, authenticated, service_role;

DROP POLICY IF EXISTS permission_letters_read_all ON public.permission_letters;
DROP POLICY IF EXISTS permission_letters_insert_all ON public.permission_letters;
DROP POLICY IF EXISTS permission_letters_update_all ON public.permission_letters;
DROP POLICY IF EXISTS permission_letters_delete_all ON public.permission_letters;

CREATE POLICY permission_letters_read_all ON public.permission_letters
  FOR SELECT TO public USING (true);

CREATE POLICY permission_letters_insert_all ON public.permission_letters
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY permission_letters_update_all ON public.permission_letters
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY permission_letters_delete_all ON public.permission_letters
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 10. POLLING & VOTING (POLLS, POLL_OPTIONS, POLL_VOTES)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.polls (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    title TEXT NOT NULL,
    description TEXT,
    author TEXT NOT NULL,
    is_open BOOLEAN DEFAULT true,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    poll_id TEXT NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    order_index INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    poll_id TEXT NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id TEXT NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    voter_nim TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(poll_id, voter_nim)
);

ALTER TABLE IF EXISTS public.polls ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.polls TO anon, authenticated, service_role;

DROP POLICY IF EXISTS polls_read_all ON public.polls;
DROP POLICY IF EXISTS polls_insert_all ON public.polls;
DROP POLICY IF EXISTS polls_update_all ON public.polls;
DROP POLICY IF EXISTS polls_delete_all ON public.polls;

CREATE POLICY polls_read_all ON public.polls
  FOR SELECT TO public USING (true);

CREATE POLICY polls_insert_all ON public.polls
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY polls_update_all ON public.polls
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY polls_delete_all ON public.polls
  FOR DELETE TO public USING (true);

ALTER TABLE IF EXISTS public.poll_options ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.poll_options TO anon, authenticated, service_role;

DROP POLICY IF EXISTS poll_options_read_all ON public.poll_options;
DROP POLICY IF EXISTS poll_options_insert_all ON public.poll_options;
DROP POLICY IF EXISTS poll_options_update_all ON public.poll_options;
DROP POLICY IF EXISTS poll_options_delete_all ON public.poll_options;

CREATE POLICY poll_options_read_all ON public.poll_options
  FOR SELECT TO public USING (true);

CREATE POLICY poll_options_insert_all ON public.poll_options
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY poll_options_update_all ON public.poll_options
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY poll_options_delete_all ON public.poll_options
  FOR DELETE TO public USING (true);

ALTER TABLE IF EXISTS public.poll_votes ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.poll_votes TO anon, authenticated, service_role;

DROP POLICY IF EXISTS poll_votes_read_all ON public.poll_votes;
DROP POLICY IF EXISTS poll_votes_insert_all ON public.poll_votes;
DROP POLICY IF EXISTS poll_votes_update_all ON public.poll_votes;
DROP POLICY IF EXISTS poll_votes_delete_all ON public.poll_votes;

CREATE POLICY poll_votes_read_all ON public.poll_votes
  FOR SELECT TO public USING (true);

CREATE POLICY poll_votes_insert_all ON public.poll_votes
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY poll_votes_update_all ON public.poll_votes
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY poll_votes_delete_all ON public.poll_votes
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 11. DATA KELAS AKADEMIK ADMIN (ACADEMIC_CLASSES)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.academic_classes (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nama text NOT NULL,
  prodi text NOT NULL DEFAULT 'Ilmu Komunikasi',
  semester integer NOT NULL CHECK (semester BETWEEN 1 AND 8),
  academic_year text NOT NULL,
  kapasitas integer NOT NULL DEFAULT 30 CHECK (kapasitas > 0),
  is_aktif boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (nama, prodi, semester, academic_year)
);

ALTER TABLE IF EXISTS public.academic_classes ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.academic_classes TO anon, authenticated, service_role;

DROP POLICY IF EXISTS academic_classes_read_all ON public.academic_classes;
DROP POLICY IF EXISTS academic_classes_insert_all ON public.academic_classes;
DROP POLICY IF EXISTS academic_classes_update_all ON public.academic_classes;
DROP POLICY IF EXISTS academic_classes_delete_all ON public.academic_classes;

CREATE POLICY academic_classes_read_all ON public.academic_classes
  FOR SELECT TO public USING (true);

CREATE POLICY academic_classes_insert_all ON public.academic_classes
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY academic_classes_update_all ON public.academic_classes
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY academic_classes_delete_all ON public.academic_classes
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 12. DATA DOSEN PENGAMPU (LECTURERS)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.lecturers (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nama text NOT NULL,
  email text NOT NULL DEFAULT '',
  mata_kuliah text NOT NULL DEFAULT '',
  is_aktif boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.lecturers ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.lecturers TO anon, authenticated, service_role;

DROP POLICY IF EXISTS lecturers_read_all ON public.lecturers;
DROP POLICY IF EXISTS lecturers_insert_all ON public.lecturers;
DROP POLICY IF EXISTS lecturers_update_all ON public.lecturers;
DROP POLICY IF EXISTS lecturers_delete_all ON public.lecturers;

CREATE POLICY lecturers_read_all ON public.lecturers
  FOR SELECT TO public USING (true);

CREATE POLICY lecturers_insert_all ON public.lecturers
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY lecturers_update_all ON public.lecturers
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY lecturers_delete_all ON public.lecturers
  FOR DELETE TO public USING (true);


-- ====================================================================
-- 13. TAHUN AKADEMIK (ACADEMIC_YEARS)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.academic_years (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tahun text NOT NULL UNIQUE,
  is_aktif boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.academic_years ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.academic_years TO anon, authenticated, service_role;

DROP POLICY IF EXISTS academic_years_read_all ON public.academic_years;
DROP POLICY IF EXISTS academic_years_insert_all ON public.academic_years;
DROP POLICY IF EXISTS academic_years_update_all ON public.academic_years;
DROP POLICY IF EXISTS academic_years_delete_all ON public.academic_years;

CREATE POLICY academic_years_read_all ON public.academic_years
  FOR SELECT TO public USING (true);

CREATE POLICY academic_years_insert_all ON public.academic_years
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY academic_years_update_all ON public.academic_years
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY academic_years_delete_all ON public.academic_years
  FOR DELETE TO public USING (true);

CREATE OR REPLACE FUNCTION public.set_active_academic_year(target_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.academic_years SET is_aktif = false WHERE is_aktif = true;
  UPDATE public.academic_years SET is_aktif = true WHERE id = target_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.set_active_academic_year(text) TO anon, authenticated, service_role;


-- ====================================================================
-- 14. RIWAYAT AUDIT LOGS ADMIN (AUDIT_LOGS)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_identifier text NOT NULL,
  user_name text,
  action_type text NOT NULL,
  target_module text NOT NULL,
  description text NOT NULL,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.audit_logs ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.audit_logs TO anon, authenticated, service_role;

DROP POLICY IF EXISTS audit_logs_read_all ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_insert_all ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_update_all ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_delete_all ON public.audit_logs;

CREATE POLICY audit_logs_read_all ON public.audit_logs
  FOR SELECT TO public USING (true);

CREATE POLICY audit_logs_insert_all ON public.audit_logs
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY audit_logs_update_all ON public.audit_logs
  FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY audit_logs_delete_all ON public.audit_logs
  FOR DELETE TO public USING (true);

CREATE OR REPLACE FUNCTION public.log_admin_activity(
  p_action_type text,
  p_target_module text,
  p_description text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.audit_logs (
    user_identifier, user_name, action_type, target_module, description, metadata
  ) VALUES (
    coalesce(auth.uid()::text, 'admin_system'),
    'Administrator',
    upper(p_action_type),
    upper(p_target_module),
    p_description,
    coalesce(p_metadata, '{}'::jsonb)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.log_admin_activity(text, text, text, jsonb) TO anon, authenticated, service_role;

COMMIT;

