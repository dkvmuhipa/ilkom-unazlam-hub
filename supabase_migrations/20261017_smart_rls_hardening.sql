-- ====================================================================
-- MIGRATION: 20261017_smart_rls_hardening.sql
-- DESCRIPTION:
-- Audit Keamanan OWASP Top 10 (A01: Broken Access Control).
-- Menutup izin publik longgar (USING true) dan menerapkan Smart Hardening RLS:
-- 1. Hak BACA (SELECT): Tetap terbuka untuk umum/anonim (jadwal, pengumuman, materi, transparansi kas).
-- 2. Hak MUTASI (INSERT, UPDATE, DELETE): Ditarik total dari 'anon' dan hanya diberikan kepada 'authenticated' & 'service_role'.
-- 3. Penegakan Peran Berbasis Database (Role-Based Access Control):
--    - Kas Kelas -> Hanya BENDAHARA & ADMIN
--    - Pengumuman & Tugas -> Hanya KETUA KELAS, SEKRETARIS, & ADMIN
--    - Jadwal & Kelas -> Hanya KETUA KELAS & ADMIN
--    - Profil Mahasiswa -> Hanya PEMILIK AKUN (NIM/Auth UID) & ADMIN
--    - Submisi Tugas & Surat Izin -> Hanya MAHASISWA BERSANGKUTAN & ADMIN
--    - Log Audit -> Hanya ADMIN (Immutable/Append-Only)
-- ====================================================================

BEGIN;

-- ====================================================================
-- 1. FUNGSI HELPER & OTORISASI PERAN KELAS
-- ====================================================================

-- Ambil NIM mahasiswa yang sedang login berdasarkan auth.uid() atau email JWT
CREATE OR REPLACE FUNCTION public.current_student_nim()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT s.nim
  FROM public.students AS s
  WHERE (s.auth_user_id = (SELECT auth.uid()) OR s.email = (auth.jwt()->>'email'))
    AND s.is_aktif = true
  LIMIT 1;
$$;

-- Periksa apakah pemanggil memiliki salah satu peran/jabatan yang diizinkan
CREATE OR REPLACE FUNCTION public.has_class_role(allowed_roles text[])
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT (auth.jwt()->>'role') = 'service_role'
     OR EXISTS (
       SELECT 1
       FROM public.students AS s
       WHERE (s.auth_user_id = (SELECT auth.uid()) OR s.email = (auth.jwt()->>'email'))
         AND s.is_aktif = true
         AND EXISTS (
           SELECT 1
           FROM unnest(allowed_roles) AS r(role_name)
           WHERE upper(coalesce(s.role, '')) = upper(r.role_name)
              OR upper(coalesce(s.jabatan, '')) = upper(r.role_name)
         )
     );
$$;

-- Cegah eskalasi hak istimewa (mahasiswa biasa dilarang mempromosikan diri ke Admin/Pengurus)
CREATE OR REPLACE FUNCTION public.prevent_student_privilege_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF (auth.jwt()->>'role') != 'service_role' AND NOT public.has_class_role(ARRAY['ADMIN']) THEN
    IF NEW.role IS DISTINCT FROM OLD.role 
       OR NEW.jabatan IS DISTINCT FROM OLD.jabatan 
       OR NEW.is_aktif IS DISTINCT FROM OLD.is_aktif THEN
      RAISE EXCEPTION 'Akses Ditolak: Perubahan role, jabatan, atau status akun hanya diizinkan bagi Administrator.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_privilege_escalation ON public.students;
CREATE TRIGGER trg_prevent_privilege_escalation
  BEFORE UPDATE OF role, jabatan, is_aktif ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.prevent_student_privilege_escalation();

-- Izin eksekusi helper
GRANT EXECUTE ON FUNCTION public.current_student_nim() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_class_role(text[]) TO anon, authenticated, service_role;


-- ====================================================================
-- 2. PENGUMUMAN KELAS (ANNOUNCEMENTS)
-- ====================================================================
ALTER TABLE IF EXISTS public.announcements ENABLE ROW LEVEL SECURITY;

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

CREATE POLICY announcements_insert_officer ON public.announcements
  FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']));

CREATE POLICY announcements_update_officer ON public.announcements
  FOR UPDATE TO authenticated
  USING (
    author_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  )
  WITH CHECK (
    author_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  );

CREATE POLICY announcements_delete_officer ON public.announcements
  FOR DELETE TO authenticated
  USING (
    author_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  );


-- ====================================================================
-- 3. JADWAL KULIAH & RESCHEDULE (COURSES & OVERRIDES)
-- ====================================================================
ALTER TABLE IF EXISTS public.courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS courses_read_all ON public.courses;
DROP POLICY IF EXISTS courses_insert_all ON public.courses;
DROP POLICY IF EXISTS courses_update_all ON public.courses;
DROP POLICY IF EXISTS courses_delete_all ON public.courses;
DROP POLICY IF EXISTS courses_anon_read ON public.courses;
DROP POLICY IF EXISTS courses_insert_officer ON public.courses;
DROP POLICY IF EXISTS courses_update_officer ON public.courses;
DROP POLICY IF EXISTS courses_delete_officer ON public.courses;

CREATE POLICY courses_read_all ON public.courses
  FOR SELECT TO public USING (true);

CREATE POLICY courses_manage_officer ON public.courses
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));

-- Override Jadwal Dinamis
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'course_schedule_overrides') THEN
    ALTER TABLE public.course_schedule_overrides ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS overrides_read_all ON public.course_schedule_overrides;
    DROP POLICY IF EXISTS overrides_manage_officer ON public.course_schedule_overrides;
    DROP POLICY IF EXISTS overrides_insert_all ON public.course_schedule_overrides;
    DROP POLICY IF EXISTS overrides_update_all ON public.course_schedule_overrides;
    DROP POLICY IF EXISTS overrides_delete_all ON public.course_schedule_overrides;

    CREATE POLICY overrides_read_all ON public.course_schedule_overrides
      FOR SELECT TO public USING (true);

    CREATE POLICY overrides_manage_officer ON public.course_schedule_overrides
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;
END $$;


-- ====================================================================
-- 4. KAS KELAS (TREASURY_TRANSACTIONS & TREASURY_DUES)
-- ====================================================================
ALTER TABLE IF EXISTS public.treasury_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS treasury_read_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_insert_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_update_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_delete_all ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_insert_treasurer ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_update_treasurer ON public.treasury_transactions;
DROP POLICY IF EXISTS treasury_delete_treasurer ON public.treasury_transactions;

CREATE POLICY treasury_read_all ON public.treasury_transactions
  FOR SELECT TO public USING (true);

CREATE POLICY treasury_manage_treasurer ON public.treasury_transactions
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN', 'Bendahara']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Bendahara']));

-- Iuran Mahasiswa (treasury_dues)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'treasury_dues') THEN
    ALTER TABLE public.treasury_dues ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS treasury_dues_read_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_insert_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_update_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_delete_all ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_secure_read ON public.treasury_dues;
    DROP POLICY IF EXISTS treasury_dues_manage_treasurer ON public.treasury_dues;

    CREATE POLICY treasury_dues_read_all ON public.treasury_dues
      FOR SELECT TO public USING (true);

    CREATE POLICY treasury_dues_manage_treasurer ON public.treasury_dues
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Bendahara']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Bendahara']));
  END IF;
END $$;


-- ====================================================================
-- 5. TUGAS KULIAH (ASSIGNMENTS & SUBMISI TUGAS)
-- ====================================================================
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS assignments_read_all ON public.assignments;
DROP POLICY IF EXISTS assignments_insert_all ON public.assignments;
DROP POLICY IF EXISTS assignments_update_all ON public.assignments;
DROP POLICY IF EXISTS assignments_delete_all ON public.assignments;
DROP POLICY IF EXISTS assignments_read_authenticated ON public.assignments;
DROP POLICY IF EXISTS assignments_manage_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_anon_read ON public.assignments;

CREATE POLICY assignments_read_all ON public.assignments
  FOR SELECT TO public USING (true);

CREATE POLICY assignments_manage_officer ON public.assignments
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']));

-- Submisi Tugas Mahasiswa (student_assignments)
ALTER TABLE IF EXISTS public.student_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS student_assignments_read_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_insert_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_update_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_delete_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_read_secure ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_manage ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_self_update ON public.student_assignments;

CREATE POLICY student_assignments_read_secure ON public.student_assignments
  FOR SELECT TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris'])
  );

CREATE POLICY student_assignments_self_insert ON public.student_assignments
  FOR INSERT TO authenticated
  WITH CHECK (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  );

CREATE POLICY student_assignments_self_update ON public.student_assignments
  FOR UPDATE TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  )
  WITH CHECK (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
  );

CREATE POLICY student_assignments_self_delete ON public.student_assignments
  FOR DELETE TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN'])
  );


-- ====================================================================
-- 6. DATA MAHASISWA & PROFIL (STUDENTS)
-- ====================================================================
ALTER TABLE IF EXISTS public.students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS students_read_all ON public.students;
DROP POLICY IF EXISTS students_insert_all ON public.students;
DROP POLICY IF EXISTS students_update_all ON public.students;
DROP POLICY IF EXISTS students_delete_all ON public.students;
DROP POLICY IF EXISTS students_anon_read ON public.students;
DROP POLICY IF EXISTS students_manage_admin ON public.students;
DROP POLICY IF EXISTS students_update_self_or_admin ON public.students;

-- Direktori aktif dibaca oleh seluruh civitas kelas
CREATE POLICY students_read_all ON public.students
  FOR SELECT TO public
  USING (is_aktif = true OR public.has_class_role(ARRAY['ADMIN']));

-- Penambahan akun hanya oleh Admin / migrasi
CREATE POLICY students_insert_admin ON public.students
  FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

-- Pembaruan profil oleh pemilik akun sendiri atau Admin
CREATE POLICY students_update_self_or_admin ON public.students
  FOR UPDATE TO authenticated
  USING (
    nim = (SELECT public.current_student_nim())
    OR auth_user_id = (SELECT auth.uid())
    OR public.has_class_role(ARRAY['ADMIN'])
  )
  WITH CHECK (
    nim = (SELECT public.current_student_nim())
    OR auth_user_id = (SELECT auth.uid())
    OR public.has_class_role(ARRAY['ADMIN'])
  );

-- Penghapusan akun hanya oleh Admin
CREATE POLICY students_delete_admin ON public.students
  FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']));


-- ====================================================================
-- 7. BERKAS KULIAH & AGENDA KELAS (RESOURCES & AGENDA_ITEMS)
-- ====================================================================
ALTER TABLE IF EXISTS public.resources ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS resources_read_all ON public.resources;
DROP POLICY IF EXISTS resources_insert_all ON public.resources;
DROP POLICY IF EXISTS resources_update_all ON public.resources;
DROP POLICY IF EXISTS resources_delete_all ON public.resources;

CREATE POLICY resources_read_all ON public.resources
  FOR SELECT TO public USING (true);

CREATE POLICY resources_manage_officer ON public.resources
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']));

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'agenda_items') THEN
    ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS agenda_read_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_insert_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_update_all ON public.agenda_items;
    DROP POLICY IF EXISTS agenda_delete_all ON public.agenda_items;

    CREATE POLICY agenda_read_all ON public.agenda_items
      FOR SELECT TO public USING (true);

    CREATE POLICY agenda_manage_officer ON public.agenda_items
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris']));
  END IF;
END $$;


-- ====================================================================
-- 8. ABSENSI PERKULIAH (SESSIONS, LOGS, RECORDS)
-- ====================================================================
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_sessions') THEN
    ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS att_sessions_read_all ON public.attendance_sessions;
    DROP POLICY IF EXISTS att_sessions_manage_officer ON public.attendance_sessions;

    CREATE POLICY att_sessions_read_all ON public.attendance_sessions
      FOR SELECT TO public USING (true);

    CREATE POLICY att_sessions_manage_officer ON public.attendance_sessions
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_logs') THEN
    ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS att_logs_read_all ON public.attendance_logs;
    DROP POLICY IF EXISTS att_logs_insert_self_or_officer ON public.attendance_logs;
    DROP POLICY IF EXISTS att_logs_manage_officer ON public.attendance_logs;

    CREATE POLICY att_logs_read_all ON public.attendance_logs
      FOR SELECT TO public USING (true);

    CREATE POLICY att_logs_insert_self_or_officer ON public.attendance_logs
      FOR INSERT TO authenticated
      WITH CHECK (
        student_nim = (SELECT public.current_student_nim())
        OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas'])
      );

    CREATE POLICY att_logs_manage_officer ON public.attendance_logs
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_records') THEN
    ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS att_records_read_all ON public.attendance_records;
    DROP POLICY IF EXISTS att_records_manage_officer ON public.attendance_records;

    CREATE POLICY att_records_read_all ON public.attendance_records
      FOR SELECT TO public USING (true);

    CREATE POLICY att_records_manage_officer ON public.attendance_records
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;
END $$;


-- ====================================================================
-- 9. SURAT IZIN (PERMISSION_LETTERS)
-- ====================================================================
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'permission_letters') THEN
    ALTER TABLE public.permission_letters ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS permission_letters_read_all ON public.permission_letters;
    DROP POLICY IF EXISTS permission_letters_insert_all ON public.permission_letters;
    DROP POLICY IF EXISTS permission_letters_update_all ON public.permission_letters;
    DROP POLICY IF EXISTS permission_letters_delete_all ON public.permission_letters;

    CREATE POLICY permission_letters_read_secure ON public.permission_letters
      FOR SELECT TO authenticated
      USING (
        student_nim = (SELECT public.current_student_nim())
        OR public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas', 'Sekretaris'])
      );

    CREATE POLICY permission_letters_insert_self ON public.permission_letters
      FOR INSERT TO authenticated
      WITH CHECK (
        student_nim = (SELECT public.current_student_nim())
        OR public.has_class_role(ARRAY['ADMIN'])
      );

    CREATE POLICY permission_letters_manage_self_or_admin ON public.permission_letters
      FOR ALL TO authenticated
      USING (
        student_nim = (SELECT public.current_student_nim())
        OR public.has_class_role(ARRAY['ADMIN'])
      )
      WITH CHECK (
        student_nim = (SELECT public.current_student_nim())
        OR public.has_class_role(ARRAY['ADMIN'])
      );
  END IF;
END $$;


-- ====================================================================
-- 10. POLLING KELAS (POLLS, POLL_OPTIONS, POLL_VOTES)
-- ====================================================================
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'polls') THEN
    ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS polls_read_all ON public.polls;
    DROP POLICY IF EXISTS polls_manage_officer ON public.polls;

    CREATE POLICY polls_read_all ON public.polls
      FOR SELECT TO public USING (true);

    CREATE POLICY polls_manage_officer ON public.polls
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'poll_options') THEN
    ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS poll_options_read_all ON public.poll_options;
    DROP POLICY IF EXISTS poll_options_manage_officer ON public.poll_options;

    CREATE POLICY poll_options_read_all ON public.poll_options
      FOR SELECT TO public USING (true);

    CREATE POLICY poll_options_manage_officer ON public.poll_options
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN', 'Ketua Kelas']));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'poll_votes') THEN
    ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS poll_votes_read_all ON public.poll_votes;
    DROP POLICY IF EXISTS poll_votes_insert_self ON public.poll_votes;
    DROP POLICY IF EXISTS poll_votes_manage_admin ON public.poll_votes;

    CREATE POLICY poll_votes_read_all ON public.poll_votes
      FOR SELECT TO public USING (true);

    CREATE POLICY poll_votes_insert_self ON public.poll_votes
      FOR INSERT TO authenticated
      WITH CHECK (voter_nim = (SELECT public.current_student_nim()));

    CREATE POLICY poll_votes_manage_admin ON public.poll_votes
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN']));
  END IF;
END $$;


-- ====================================================================
-- 11. TABEL ADMINISTRASI & MASTER DATA KAMPUS
-- ====================================================================
DO $$ BEGIN
  -- Academic Classes
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'academic_classes') THEN
    ALTER TABLE public.academic_classes ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS classes_read_all ON public.academic_classes;
    DROP POLICY IF EXISTS classes_manage_admin ON public.academic_classes;

    CREATE POLICY classes_read_all ON public.academic_classes
      FOR SELECT TO public USING (true);

    CREATE POLICY classes_manage_admin ON public.academic_classes
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN']));
  END IF;

  -- Lecturers
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'lecturers') THEN
    ALTER TABLE public.lecturers ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS lecturers_read_all ON public.lecturers;
    DROP POLICY IF EXISTS lecturers_manage_admin ON public.lecturers;

    CREATE POLICY lecturers_read_all ON public.lecturers
      FOR SELECT TO public USING (true);

    CREATE POLICY lecturers_manage_admin ON public.lecturers
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN']));
  END IF;

  -- Academic Years
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'academic_years') THEN
    ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS years_read_all ON public.academic_years;
    DROP POLICY IF EXISTS years_manage_admin ON public.academic_years;

    CREATE POLICY years_read_all ON public.academic_years
      FOR SELECT TO public USING (true);

    CREATE POLICY years_manage_admin ON public.academic_years
      FOR ALL TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN']))
      WITH CHECK (public.has_class_role(ARRAY['ADMIN']));
  END IF;

  -- Audit Logs (Append-Only: Hanya bisa dibaca oleh Admin)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'audit_logs') THEN
    ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS audit_logs_read_admin ON public.audit_logs;
    DROP POLICY IF EXISTS audit_logs_insert_auth ON public.audit_logs;

    CREATE POLICY audit_logs_read_admin ON public.audit_logs
      FOR SELECT TO authenticated
      USING (public.has_class_role(ARRAY['ADMIN']));

    CREATE POLICY audit_logs_insert_auth ON public.audit_logs
      FOR INSERT TO authenticated
      WITH CHECK (true);
  END IF;
END $$;


-- ====================================================================
-- 12. PENEGASAN IZIN GRANULAR (REVOKE MUTASI DARI ANON)
-- ====================================================================
-- Izinkan SELECT untuk umum & anon
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;

-- Izinkan INSERT, UPDATE, DELETE hanya bagi authenticated & service_role
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;

-- Cabut seluruh izin mutasi (INSERT, UPDATE, DELETE) dari role anon
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM anon;

COMMIT;
