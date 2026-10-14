-- Migration: 20261014_update_fcm_webhook_auth.sql
-- Description: Update trigger_push_notification_webhook with bulletproof pg_net handling,
-- valid Supabase Edge Gateway Authorization headers, and automated table triggers.

BEGIN;

-- 1. Buat schema net jika belum ada, lalu aktifkan ekstensi pg_net
CREATE SCHEMA IF NOT EXISTS net;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Fungsi trigger webhook dengan Authorization header yang valid
CREATE OR REPLACE FUNCTION public.trigger_push_notification_webhook()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_supabase_url text := 'https://boffbpvyqhajfiqzyztx.supabase.co';
  v_anon_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvZmZicHZ5cWhhamZpcXp5enR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExMTY0MzQsImV4cCI6MjEwNjY5MjQzNH0.taJwWfaI0SuBOU3D7SFF2MRuXsCzkdj4Wrsc5DG5GJw';
  v_function_url text;
  v_payload jsonb;
BEGIN
  v_function_url := v_supabase_url || '/functions/v1/send-push-notification';

  v_payload := jsonb_build_object(
    'table', TG_TABLE_NAME,
    'type', TG_OP,
    'record', row_to_json(NEW)
  );

  -- Panggil Edge Function via pg_net (mendukung schema net maupun extensions)
  BEGIN
    IF EXISTS (
      SELECT 1 FROM pg_proc p 
      JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'net' AND p.proname = 'http_post'
    ) THEN
      PERFORM net.http_post(
        url := v_function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'apikey', v_anon_key,
          'Authorization', 'Bearer ' || v_anon_key,
          'x-webhook-secret', 'ilkom_unazlam_fcm_internal_secret_2026'
        ),
        body := v_payload
      );
    ELSIF EXISTS (
      SELECT 1 FROM pg_proc p 
      JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'extensions' AND p.proname = 'http_post'
    ) THEN
      PERFORM extensions.http_post(
        url := v_function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'apikey', v_anon_key,
          'Authorization', 'Bearer ' || v_anon_key,
          'x-webhook-secret', 'ilkom_unazlam_fcm_internal_secret_2026'
        ),
        body := v_payload
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Fallback aman: kegagalan network webhook tidak akan membatalkan insert data utama
    NULL;
  END;

  RETURN NEW;
END;
$$;

-- 3. Trigger pada Tabel announcements (Pengumuman Baru)
DROP TRIGGER IF EXISTS trigger_announcement_push ON public.announcements;
CREATE TRIGGER trigger_announcement_push
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification_webhook();

-- 4. Trigger pada Tabel assignments (Tugas Kuliah Baru)
DROP TRIGGER IF EXISTS trigger_assignment_push ON public.assignments;
CREATE TRIGGER trigger_assignment_push
  AFTER INSERT ON public.assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification_webhook();

-- 5. Trigger pada Tabel attendance_sessions (Presensi Dibuka)
DROP TRIGGER IF EXISTS trigger_attendance_session_push ON public.attendance_sessions;
CREATE TRIGGER trigger_attendance_session_push
  AFTER INSERT ON public.attendance_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification_webhook();

COMMIT;
