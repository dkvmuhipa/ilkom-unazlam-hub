-- Migration: 20261010_user_push_tokens.sql
-- Description: Create user_push_tokens table to store FCM device tokens for push notifications

BEGIN;

CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nim text NOT NULL REFERENCES public.students(nim) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  platform text NOT NULL DEFAULT 'android',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexing untuk pencarian cepat berdasarkan NIM dan token
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_nim ON public.user_push_tokens(nim);
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_token ON public.user_push_tokens(token);

-- Enable RLS
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

-- Policy RLS: Mahasiswa yang terotentikasi dapat membaca & menyimpan token perangkatnya sendiri
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'user_push_tokens'
  LOOP
    EXECUTE format('DROP POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
  END LOOP;
END $$;

CREATE POLICY user_push_tokens_own_access ON public.user_push_tokens
  FOR ALL TO authenticated
  USING (nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN']))
  WITH CHECK (nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN']));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_push_tokens TO authenticated;

COMMIT;
