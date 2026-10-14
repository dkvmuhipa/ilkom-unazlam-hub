-- Migration: 20261014_update_fcm_webhook_auth.sql
-- Description: Update trigger_push_notification_webhook with required Supabase Edge Gateway
-- Authorization headers (apikey + Bearer anonKey) and attach triggers to announcements,
-- assignments, and attendance_sessions.

BEGIN;

-- 1. Pastikan ekstensi pg_net aktif (ekstensi HTTP Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA net;

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

  -- Panggil Edge Function via pg_net (asinkron non-blocking)
  BEGIN
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
