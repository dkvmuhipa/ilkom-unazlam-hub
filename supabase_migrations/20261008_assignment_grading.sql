-- Run after 20261008_secure_access.sql on the existing Supabase project.
-- Adds a protected grading workflow to each student's assignment submission.
BEGIN;

ALTER TABLE public.student_assignments
  ADD COLUMN IF NOT EXISTS nilai numeric(5,2),
  ADD COLUMN IF NOT EXISTS umpan_balik text,
  ADD COLUMN IF NOT EXISTS graded_by uuid,
  ADD COLUMN IF NOT EXISTS graded_at timestamptz;

ALTER TABLE public.student_assignments
  DROP CONSTRAINT IF EXISTS student_assignments_status_check;
ALTER TABLE public.student_assignments
  ADD CONSTRAINT student_assignments_status_check
  CHECK (status IN ('belum','sedang_dikerjakan','dikumpulkan','dinilai','selesai'));
ALTER TABLE public.student_assignments
  DROP CONSTRAINT IF EXISTS student_assignments_nilai_check;
ALTER TABLE public.student_assignments
  ADD CONSTRAINT student_assignments_nilai_check
  CHECK (nilai IS NULL OR (nilai >= 0 AND nilai <= 100));

DROP POLICY IF EXISTS student_assignments_read_own ON public.student_assignments;
CREATE POLICY student_assignments_read_own_or_grader
  ON public.student_assignments FOR SELECT TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])
  );

DROP POLICY IF EXISTS student_assignments_grade_update ON public.student_assignments;
CREATE POLICY student_assignments_grade_update
  ON public.student_assignments FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));

CREATE OR REPLACE FUNCTION public.protect_assignment_grade_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_class_role(ARRAY['ADMIN','Ketua Kelas']) THEN
    IF NEW.status = 'dinilai'
       OR NEW.nilai IS NOT NULL
       OR NEW.umpan_balik IS NOT NULL
       OR NEW.graded_by IS NOT NULL
       OR NEW.graded_at IS NOT NULL THEN
      RAISE EXCEPTION 'Only class graders can set assignment grades';
    END IF;
    IF TG_OP = 'UPDATE' AND (
        OLD.nilai IS DISTINCT FROM NEW.nilai
        OR OLD.umpan_balik IS DISTINCT FROM NEW.umpan_balik
        OR OLD.graded_by IS DISTINCT FROM NEW.graded_by
        OR OLD.graded_at IS DISTINCT FROM NEW.graded_at) THEN
      RAISE EXCEPTION 'Only class graders can change assignment grades';
    END IF;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_assignment_grade_fields ON public.student_assignments;
CREATE TRIGGER protect_assignment_grade_fields
  BEFORE INSERT OR UPDATE ON public.student_assignments
  FOR EACH ROW EXECUTE FUNCTION public.protect_assignment_grade_fields();

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'assignment-submissions',
  'assignment-submissions',
  false,
  20971520,
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip',
    'image/png',
    'image/jpeg',
    'application/octet-stream'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS assignment_submissions_read ON storage.objects;
CREATE POLICY assignment_submissions_read
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'assignment-submissions'
    AND (
      (storage.foldername(name))[1] = (SELECT public.current_student_nim())
      OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])
    )
  );

DROP POLICY IF EXISTS assignment_submissions_insert_own ON storage.objects;
CREATE POLICY assignment_submissions_insert_own
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'assignment-submissions'
    AND (storage.foldername(name))[1] = (SELECT public.current_student_nim())
  );

COMMIT;
