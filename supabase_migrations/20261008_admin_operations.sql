-- Persistent academic master data and protection for administrator access.
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.academic_classes (
  id text PRIMARY KEY DEFAULT uuid_generate_v4()::text,
  nama text NOT NULL,
  prodi text NOT NULL DEFAULT 'Ilmu Komunikasi',
  semester integer NOT NULL CHECK (semester BETWEEN 1 AND 8),
  academic_year text NOT NULL,
  kapasitas integer NOT NULL DEFAULT 30 CHECK (kapasitas > 0),
  is_aktif boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (nama, prodi, semester, academic_year)
);

CREATE TABLE IF NOT EXISTS public.lecturers (
  id text PRIMARY KEY DEFAULT uuid_generate_v4()::text,
  nama text NOT NULL,
  email text NOT NULL DEFAULT '',
  mata_kuliah text NOT NULL DEFAULT '',
  is_aktif boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.academic_years (
  id text PRIMARY KEY DEFAULT uuid_generate_v4()::text,
  tahun text NOT NULL UNIQUE,
  is_aktif boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS academic_years_one_active_idx
  ON public.academic_years (is_aktif) WHERE is_aktif = true;

ALTER TABLE public.academic_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.academic_classes, public.lecturers, public.academic_years TO authenticated;

DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = ANY(ARRAY['academic_classes','lecturers','academic_years'])
  LOOP
    EXECUTE format('DROP POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
  END LOOP;
END $$;

CREATE POLICY academic_classes_read ON public.academic_classes
  FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY academic_classes_admin_manage ON public.academic_classes
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

CREATE POLICY lecturers_read ON public.lecturers
  FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY lecturers_admin_manage ON public.lecturers
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

CREATE POLICY academic_years_read ON public.academic_years
  FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY academic_years_admin_manage ON public.academic_years
  FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

CREATE OR REPLACE FUNCTION public.set_active_academic_year(target_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_class_role(ARRAY['ADMIN']) THEN
    RAISE EXCEPTION 'Only an active administrator can change the academic year';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.academic_years WHERE id = target_id) THEN
    RAISE EXCEPTION 'Academic year not found';
  END IF;
  UPDATE public.academic_years SET is_aktif = false WHERE is_aktif = true;
  UPDATE public.academic_years SET is_aktif = true WHERE id = target_id;
END;
$$;
REVOKE ALL ON FUNCTION public.set_active_academic_year(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_active_academic_year(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.prevent_last_active_admin_removal()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE active_admins bigint;
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF upper(OLD.role) = 'ADMIN' AND OLD.is_aktif THEN
      SELECT count(*) INTO active_admins FROM public.students
        WHERE upper(role) = 'ADMIN' AND is_aktif = true AND auth_user_id IS NOT NULL;
      IF active_admins <= 1 THEN
        RAISE EXCEPTION 'The last active administrator cannot be removed';
      END IF;
    END IF;
    RETURN OLD;
  END IF;

  IF upper(OLD.role) = 'ADMIN' AND OLD.is_aktif
      AND (upper(NEW.role) <> 'ADMIN' OR NOT NEW.is_aktif) THEN
    SELECT count(*) INTO active_admins FROM public.students
      WHERE upper(role) = 'ADMIN' AND is_aktif = true AND auth_user_id IS NOT NULL;
    IF active_admins <= 1 THEN
      RAISE EXCEPTION 'The last active administrator cannot be removed';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_last_active_admin_update ON public.students;
CREATE TRIGGER prevent_last_active_admin_update
  BEFORE UPDATE OF role, is_aktif ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.prevent_last_active_admin_removal();
DROP TRIGGER IF EXISTS prevent_last_active_admin_delete ON public.students;
CREATE TRIGGER prevent_last_active_admin_delete
  BEFORE DELETE ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.prevent_last_active_admin_removal();

COMMIT;
