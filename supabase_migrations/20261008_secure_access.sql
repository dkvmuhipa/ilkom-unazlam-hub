-- Security migration for the existing ilkomunazlam project.
-- Before users can sign in, create Supabase Auth users and link each one to
-- public.students.auth_user_id using a trusted Dashboard/SQL Editor session.
-- This migration deliberately locks public.profiles out of the Data API because
-- it contains contact details and has no authenticated owner mapping.
BEGIN;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS auth_user_id uuid UNIQUE
  REFERENCES auth.users(id) ON DELETE SET NULL;

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
           OR s.jabatan = r.role_name
      )
  );
$$;

REVOKE ALL ON FUNCTION public.current_student_nim() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_class_role(text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_student_nim() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_class_role(text[]) TO authenticated;

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
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.profiles FROM PUBLIC, anon, authenticated;

-- These three legacy tables are not connected to app CRUD yet. Enable RLS and
-- allow authenticated reads only where the current app needs shared class data.
ALTER TABLE public.project_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_resources ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- Read access for signed-in members of the class.
CREATE POLICY courses_read ON public.courses FOR SELECT TO authenticated USING (true);
CREATE POLICY assignments_read ON public.assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY announcements_read ON public.announcements FOR SELECT TO authenticated USING (true);
CREATE POLICY treasury_read ON public.treasury_transactions FOR SELECT TO authenticated USING (true);
CREATE POLICY agenda_read ON public.agenda_items FOR SELECT TO authenticated USING (true);
CREATE POLICY resources_read ON public.resources FOR SELECT TO authenticated USING (true);
CREATE POLICY project_groups_read ON public.project_groups FOR SELECT TO authenticated USING (true);
CREATE POLICY course_resources_read ON public.course_resources FOR SELECT TO authenticated USING (true);
CREATE POLICY group_members_read_officer ON public.group_members FOR SELECT TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY students_read_self_or_officer ON public.students FOR SELECT TO authenticated
  USING (auth_user_id = (SELECT auth.uid()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY attendance_read_self_or_officer ON public.attendance_logs FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));

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

CREATE POLICY project_groups_write_officer ON public.project_groups FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY group_members_write_officer ON public.group_members FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY course_resources_write_officer ON public.course_resources FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));

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
