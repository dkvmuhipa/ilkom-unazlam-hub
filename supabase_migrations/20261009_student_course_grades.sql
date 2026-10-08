-- Run after 20261008_secure_access.sql on the existing Supabase project.
-- Stores official final course grades and restricts reads to the student and
-- administrators. The admin role is the only role allowed to record changes.
BEGIN;

CREATE TABLE IF NOT EXISTS public.student_course_grades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_nim text NOT NULL REFERENCES public.students(nim) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE RESTRICT,
  course_code text NOT NULL DEFAULT '',
  course_name text NOT NULL,
  sks smallint NOT NULL CHECK (sks BETWEEN 1 AND 24),
  semester smallint NOT NULL CHECK (semester BETWEEN 1 AND 16),
  academic_year text NOT NULL,
  nilai_angka numeric(5,2) CHECK (nilai_angka IS NULL OR nilai_angka BETWEEN 0 AND 100),
  nilai_huruf text NOT NULL CHECK (nilai_huruf IN ('A','A-','B+','B','B-','C+','C','D','E')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_nim, course_id, semester, academic_year)
);

CREATE INDEX IF NOT EXISTS student_course_grades_student_term_idx
  ON public.student_course_grades (student_nim, academic_year, semester);

ALTER TABLE public.student_course_grades ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.student_course_grades FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.student_course_grades TO authenticated;

DROP POLICY IF EXISTS student_course_grades_read_own_or_admin
  ON public.student_course_grades;
CREATE POLICY student_course_grades_read_own_or_admin
  ON public.student_course_grades FOR SELECT TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN'])
  );

DROP POLICY IF EXISTS student_course_grades_insert_admin
  ON public.student_course_grades;
CREATE POLICY student_course_grades_insert_admin
  ON public.student_course_grades FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

DROP POLICY IF EXISTS student_course_grades_update_admin
  ON public.student_course_grades;
CREATE POLICY student_course_grades_update_admin
  ON public.student_course_grades FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN']));

DROP POLICY IF EXISTS student_course_grades_delete_admin
  ON public.student_course_grades;
CREATE POLICY student_course_grades_delete_admin
  ON public.student_course_grades FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']));

CREATE OR REPLACE FUNCTION public.set_student_course_grade_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_student_course_grade_updated_at
  ON public.student_course_grades;
CREATE TRIGGER set_student_course_grade_updated_at
  BEFORE UPDATE ON public.student_course_grades
  FOR EACH ROW EXECUTE FUNCTION public.set_student_course_grade_updated_at();

COMMIT;
