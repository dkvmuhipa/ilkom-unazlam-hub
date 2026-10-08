-- Security migration for the existing ilkomunazlam project.
-- Before users can sign in, create Supabase Auth users and link each one to
-- public.students.auth_user_id using a trusted Dashboard/SQL Editor session.
-- This migration deliberately locks public.profiles out of the Data API because
-- it contains contact details and has no authenticated owner mapping.
BEGIN;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS auth_user_id uuid UNIQUE
  REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.student_assignments (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  -- Existing production projects use UUID assignment ids. The standalone
  -- schema for a new project uses text ids and does not use this migration.
  assignment_id uuid NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  student_nim text NOT NULL REFERENCES public.students(nim) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'belum'
    CHECK (status IN ('belum','sedang_dikerjakan','selesai')),
  link_pengumpulan text,
  catatan text,
  submitted_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (assignment_id, student_nim)
);

CREATE OR REPLACE FUNCTION public.current_student_nim()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT s.nim
  FROM public.students AS s
  WHERE s.auth_user_id = (SELECT auth.uid())
    AND s.is_aktif = true
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.has_class_role(allowed_roles text[])
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.students AS s
    WHERE s.auth_user_id = (SELECT auth.uid())
      AND s.is_aktif = true
      AND EXISTS (
        SELECT 1
        FROM unnest(allowed_roles) AS r(role_name)
        WHERE upper(s.role) = upper(r.role_name)
           OR upper(s.jabatan) = upper(r.role_name)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_class_directory()
RETURNS TABLE (id text, nim text, nama text, no_wa text, peminatan text,
  prodi text, semester integer, kelas text, role text, jabatan text,
  is_aktif boolean, instagram text, linkedin text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT s.id, s.nim, s.nama, s.no_wa, s.peminatan, s.prodi, s.semester,
    s.kelas, s.role, s.jabatan, s.is_aktif, s.instagram, s.linkedin
  FROM public.students s
  WHERE s.is_aktif = true
    AND (SELECT public.current_student_nim()) IS NOT NULL
  ORDER BY s.nama;
$$;

REVOKE ALL ON FUNCTION public.current_student_nim() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_class_role(text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_student_nim() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_class_role(text[]) TO authenticated;
REVOKE ALL ON FUNCTION public.get_class_directory() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_class_directory() TO authenticated;

CREATE OR REPLACE FUNCTION public.prevent_client_auth_link_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF (SELECT auth.uid()) IS NOT NULL
     AND NEW.auth_user_id IS DISTINCT FROM OLD.auth_user_id THEN
    RAISE EXCEPTION 'Auth account links can only be managed by a trusted administrator';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_client_auth_link_change ON public.students;
CREATE TRIGGER prevent_client_auth_link_change
  BEFORE UPDATE OF auth_user_id ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.prevent_client_auth_link_change();

-- Remove the actual permissive policies currently attached to the existing tables.
DROP POLICY IF EXISTS "Public Delete Agenda" ON public.agenda_items;
DROP POLICY IF EXISTS "Public Insert Agenda" ON public.agenda_items;
DROP POLICY IF EXISTS "Public Read All Agenda" ON public.agenda_items;
DROP POLICY IF EXISTS "Public Update Agenda" ON public.agenda_items;
DROP POLICY IF EXISTS "Public Delete Announcements" ON public.announcements;
DROP POLICY IF EXISTS "Public Insert Announcements" ON public.announcements;
DROP POLICY IF EXISTS "Public Read All Announcements" ON public.announcements;
DROP POLICY IF EXISTS "Public Update Announcements" ON public.announcements;
DROP POLICY IF EXISTS "Public Delete Assignments" ON public.assignments;
DROP POLICY IF EXISTS "Public Insert Assignments" ON public.assignments;
DROP POLICY IF EXISTS "Public Read All Assignments" ON public.assignments;
DROP POLICY IF EXISTS "Public Update Assignments" ON public.assignments;
DROP POLICY IF EXISTS "Public Insert Attendance" ON public.attendance_logs;
DROP POLICY IF EXISTS "Public Read All Attendance" ON public.attendance_logs;
DROP POLICY IF EXISTS "Public Delete Courses" ON public.courses;
DROP POLICY IF EXISTS "Public Insert Courses" ON public.courses;
DROP POLICY IF EXISTS "Public Read All Courses" ON public.courses;
DROP POLICY IF EXISTS "Public Update Courses" ON public.courses;
DROP POLICY IF EXISTS "Public Delete Resources" ON public.resources;
DROP POLICY IF EXISTS "Public Insert Resources" ON public.resources;
DROP POLICY IF EXISTS "Public Read All Resources" ON public.resources;
DROP POLICY IF EXISTS "Public Insert Students" ON public.students;
DROP POLICY IF EXISTS "Public Read All Students" ON public.students;
DROP POLICY IF EXISTS "Public Update Students" ON public.students;
DROP POLICY IF EXISTS "Public Delete Treasury" ON public.treasury_transactions;
DROP POLICY IF EXISTS "Public Insert Treasury" ON public.treasury_transactions;
DROP POLICY IF EXISTS "Public Read All Treasury" ON public.treasury_transactions;
DROP POLICY IF EXISTS "Public Update Treasury" ON public.treasury_transactions;

-- The existing profile table has no safe link to auth.users and contains PII.
DO $$ BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY';
    EXECUTE 'REVOKE ALL ON TABLE public.profiles FROM PUBLIC, anon, authenticated';
  END IF;
END $$;

ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;

-- These three legacy tables are not connected to app CRUD yet. Enable RLS and
-- allow authenticated reads only where the current app needs shared class data.
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['project_groups','group_members','course_resources'] LOOP
    IF to_regclass(format('public.%I', t)) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END IF;
  END LOOP;
END $$;

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['polls','poll_options','poll_votes','permission_letters','audit_logs'] LOOP
    IF to_regclass(format('public.%I', t)) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END IF;
  END LOOP;
END $$;

-- Remove every policy on these application tables first. Older deployments
-- used differently named public policies, which would remain permissive beside
-- the scoped policies below because PostgreSQL combines policies with OR.
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = ANY(ARRAY[
      'courses','assignments','student_assignments','announcements','treasury_transactions',
      'agenda_items','attendance_logs','students','resources','project_groups','group_members',
      'course_resources','polls','poll_options','poll_votes','permission_letters','audit_logs'])
  LOOP
    EXECUTE format('DROP POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
  END LOOP;
END $$;

-- Read access for signed-in members of the class.
CREATE POLICY courses_read ON public.courses FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY assignments_read ON public.assignments FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY announcements_read ON public.announcements FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY treasury_read ON public.treasury_transactions FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY agenda_read ON public.agenda_items FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY resources_read ON public.resources FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
DO $$ BEGIN
  IF to_regclass('public.project_groups') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY project_groups_read ON public.project_groups FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL)';
    EXECUTE 'CREATE POLICY project_groups_write_officer ON public.project_groups FOR ALL TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris''])) WITH CHECK (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris'']))';
  END IF;
  IF to_regclass('public.course_resources') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY course_resources_read ON public.course_resources FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL)';
    EXECUTE 'CREATE POLICY course_resources_write_officer ON public.course_resources FOR ALL TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris''])) WITH CHECK (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris'']))';
  END IF;
  IF to_regclass('public.group_members') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY group_members_read_officer ON public.group_members FOR SELECT TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris'']))';
    EXECUTE 'CREATE POLICY group_members_write_officer ON public.group_members FOR ALL TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris''])) WITH CHECK (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris'']))';
  END IF;
END $$;
CREATE POLICY students_read_self_or_officer ON public.students FOR SELECT TO authenticated
  USING (auth_user_id = (SELECT auth.uid()) OR public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY attendance_read_self_or_officer ON public.attendance_logs FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY student_assignments_read_own ON public.student_assignments FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY student_assignments_insert_own ON public.student_assignments FOR INSERT TO authenticated
  WITH CHECK (student_nim = (SELECT public.current_student_nim()));
CREATE POLICY student_assignments_update_own ON public.student_assignments FOR UPDATE TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()))
  WITH CHECK (student_nim = (SELECT public.current_student_nim()));
DO $$ BEGIN
  IF to_regclass('public.polls') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY polls_read ON public.polls FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL)';
    EXECUTE 'CREATE POLICY polls_write_officer ON public.polls FOR ALL TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas''])) WITH CHECK (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'']))';
  END IF;
  IF to_regclass('public.poll_options') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY poll_options_read ON public.poll_options FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL)';
    EXECUTE 'CREATE POLICY poll_options_write_officer ON public.poll_options FOR ALL TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas''])) WITH CHECK (public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'']))';
  END IF;
  IF to_regclass('public.poll_votes') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY poll_votes_read_own ON public.poll_votes FOR SELECT TO authenticated USING (voter_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'']))';
    EXECUTE 'CREATE POLICY poll_votes_insert_own ON public.poll_votes FOR INSERT TO authenticated WITH CHECK (voter_nim = (SELECT public.current_student_nim()))';
  END IF;
  IF to_regclass('public.permission_letters') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY permission_letters_read_own_or_officer ON public.permission_letters FOR SELECT TO authenticated USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY[''ADMIN'',''Ketua Kelas'',''Sekretaris'']))';
    EXECUTE 'CREATE POLICY permission_letters_insert_own ON public.permission_letters FOR INSERT TO authenticated WITH CHECK (student_nim = (SELECT public.current_student_nim()))';
  END IF;
  IF to_regclass('public.audit_logs') IS NOT NULL THEN
    EXECUTE 'CREATE POLICY audit_logs_read_admin ON public.audit_logs FOR SELECT TO authenticated USING (public.has_class_role(ARRAY[''ADMIN'']))';
    EXECUTE 'CREATE POLICY audit_logs_insert_own ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (user_identifier = (SELECT public.current_student_nim()))';
  END IF;
END $$;

-- Privileged academic/class maintenance.
CREATE POLICY courses_insert_officer ON public.courses FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY courses_update_officer ON public.courses FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY courses_delete_officer ON public.courses FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));

CREATE POLICY assignments_insert_officer ON public.assignments FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY assignments_update_officer ON public.assignments FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY assignments_delete_officer ON public.assignments FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));

CREATE POLICY announcements_insert_officer ON public.announcements FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY announcements_update_officer ON public.announcements FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY announcements_delete_officer ON public.announcements FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));

CREATE POLICY treasury_insert_treasurer ON public.treasury_transactions FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Bendahara']));
CREATE POLICY treasury_update_treasurer ON public.treasury_transactions FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Bendahara']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Bendahara']));
CREATE POLICY treasury_delete_treasurer ON public.treasury_transactions FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Bendahara']));

CREATE POLICY agenda_insert_officer ON public.agenda_items FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY agenda_update_officer ON public.agenda_items FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY agenda_delete_officer ON public.agenda_items FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));

CREATE POLICY resources_insert_officer ON public.resources FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY resources_update_officer ON public.resources FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY resources_delete_officer ON public.resources FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));

CREATE POLICY attendance_insert_self_or_officer ON public.attendance_logs FOR INSERT TO authenticated
  WITH CHECK (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])
  );
CREATE POLICY attendance_update_officer ON public.attendance_logs FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY attendance_delete_officer ON public.attendance_logs FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));

CREATE POLICY students_update_admin ON public.students FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

COMMIT;
