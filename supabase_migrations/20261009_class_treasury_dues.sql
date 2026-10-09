-- Persistent monthly class-dues records. Only students can view their own
-- status; administrators and class treasurers manage the full class ledger.
BEGIN;

CREATE TABLE IF NOT EXISTS public.treasury_dues (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  student_nim text NOT NULL REFERENCES public.students(nim) ON DELETE CASCADE,
  period text NOT NULL CHECK (period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  nominal bigint NOT NULL DEFAULT 20000 CHECK (nominal > 0),
  is_lunas boolean NOT NULL DEFAULT false,
  paid_at timestamptz,
  recorded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_nim, period),
  CHECK ((is_lunas AND paid_at IS NOT NULL) OR (NOT is_lunas AND paid_at IS NULL))
);

CREATE INDEX IF NOT EXISTS treasury_dues_period_status_idx
  ON public.treasury_dues (period, is_lunas);

ALTER TABLE public.treasury_dues ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.treasury_dues FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.treasury_dues TO authenticated;

DROP POLICY IF EXISTS treasury_dues_read_own_or_treasurer
  ON public.treasury_dues;
CREATE POLICY treasury_dues_read_own_or_treasurer
  ON public.treasury_dues FOR SELECT TO authenticated
  USING (
    student_nim = (SELECT public.current_student_nim())
    OR public.has_class_role(ARRAY['ADMIN','Bendahara'])
  );

DROP POLICY IF EXISTS treasury_dues_insert_treasurer
  ON public.treasury_dues;
CREATE POLICY treasury_dues_insert_treasurer
  ON public.treasury_dues FOR INSERT TO authenticated
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Bendahara']));

DROP POLICY IF EXISTS treasury_dues_update_treasurer
  ON public.treasury_dues;
CREATE POLICY treasury_dues_update_treasurer
  ON public.treasury_dues FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Bendahara']))
  WITH CHECK (public.has_class_role(ARRAY['ADMIN','Bendahara']));

DROP POLICY IF EXISTS treasury_dues_delete_treasurer
  ON public.treasury_dues;
CREATE POLICY treasury_dues_delete_treasurer
  ON public.treasury_dues FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Bendahara']));

COMMIT;
