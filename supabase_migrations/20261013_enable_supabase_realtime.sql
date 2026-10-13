-- Migration: 20261013_enable_supabase_realtime.sql
-- Description: Enables Supabase Realtime on all critical class tables.
-- Allows live instantaneous updates for announcements, assignments, treasury, attendance, courses, and resources.

BEGIN;

-- 1. Pastikan REPLICA IDENTITY FULL untuk menangkap data lengkap saat event UPDATE / DELETE
ALTER TABLE IF EXISTS public.announcements REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.assignments REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.student_assignments REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.treasury_transactions REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.treasury_dues REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.courses REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.attendance_sessions REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.attendance_records REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.resources REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.students REPLICA IDENTITY FULL;

-- 2. Daftarkan tabel-tabel ke publication supabase_realtime
DO $$
BEGIN
  -- announcements
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'announcements') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'announcements'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
    END IF;
  END IF;

  -- assignments
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assignments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'assignments'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.assignments;
    END IF;
  END IF;

  -- student_assignments
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'student_assignments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'student_assignments'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.student_assignments;
    END IF;
  END IF;

  -- treasury_transactions
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'treasury_transactions') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'treasury_transactions'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.treasury_transactions;
    END IF;
  END IF;

  -- treasury_dues
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'treasury_dues') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'treasury_dues'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.treasury_dues;
    END IF;
  END IF;

  -- courses
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'courses') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'courses'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.courses;
    END IF;
  END IF;

  -- attendance_sessions
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_sessions') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'attendance_sessions'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_sessions;
    END IF;
  END IF;

  -- attendance_records
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'attendance_records') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'attendance_records'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_records;
    END IF;
  END IF;

  -- resources
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'resources') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'resources'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.resources;
    END IF;
  END IF;

  -- students
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'students') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'students'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.students;
    END IF;
  END IF;
END $$;

COMMIT;
