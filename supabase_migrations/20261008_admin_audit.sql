-- Server-authenticated audit trail for privileged administrator actions.
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id text PRIMARY KEY DEFAULT uuid_generate_v4()::text,
  user_identifier text NOT NULL,
  user_name text,
  action_type text NOT NULL,
  target_module text NOT NULL,
  description text NOT NULL,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS audit_logs_read_admin ON public.audit_logs;
CREATE POLICY audit_logs_read_admin ON public.audit_logs
  FOR SELECT TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']));

CREATE INDEX IF NOT EXISTS audit_logs_created_at_desc_idx
  ON public.audit_logs (created_at DESC);

GRANT SELECT ON public.audit_logs TO authenticated;

CREATE OR REPLACE FUNCTION public.log_admin_activity(
  p_action_type text,
  p_target_module text,
  p_description text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_nim text;
  actor_name text;
BEGIN
  IF NOT public.has_class_role(ARRAY['ADMIN']) THEN
    RAISE EXCEPTION 'Only an active administrator can write audit events';
  END IF;

  IF upper(p_action_type) NOT IN ('CREATE', 'UPDATE', 'DELETE', 'EXPORT') THEN
    RAISE EXCEPTION 'Unsupported audit action';
  END IF;
  IF length(coalesce(p_target_module, '')) NOT BETWEEN 1 AND 50
      OR length(coalesce(p_description, '')) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'Audit module and description are required';
  END IF;

  actor_nim := public.current_student_nim();
  SELECT s.nama INTO actor_name
  FROM public.students AS s
  WHERE s.nim = actor_nim AND s.is_aktif = true;

  INSERT INTO public.audit_logs (
    user_identifier, user_name, action_type, target_module, description, metadata
  ) VALUES (
    actor_nim, actor_name, upper(p_action_type), upper(p_target_module),
    p_description, coalesce(p_metadata, '{}'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.log_admin_activity(text, text, text, jsonb)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_admin_activity(text, text, text, jsonb)
  TO authenticated;

COMMIT;
