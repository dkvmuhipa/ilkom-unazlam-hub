-- Migration: 20261010_fcm_database_webhook.sql
-- Description: Trigger and Webhook setup to automatically invoke send-push-notification
-- when a new announcement or assignment is created in Supabase.

BEGIN;

-- 1. Helper function untuk memicu HTTP webhook ke Edge Function
CREATE OR REPLACE FUNCTION public.trigger_push_notification_webhook()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_supabase_url text := 'https://boffbpvyqhajfiqzyztx.supabase.co';
  v_function_url text;
  v_payload jsonb;
BEGIN
  v_function_url := v_supabase_url || '/functions/v1/send-push-notification';

  v_payload := jsonb_build_object(
    'table', TG_TABLE_NAME,
    'type', TG_OP,
    'record', row_to_json(NEW)
  );

  -- Panggil Edge Function via pg_net (ekstensi networking bawaan Supabase)
  -- Jika pg_net aktif, lakukan request asinkron non-blocking
  BEGIN
    PERFORM net.http_post(
      url := v_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json'
      ),
      body := v_payload
    );
  EXCEPTION WHEN OTHERS THEN
    -- Fallback/abaikan jika ekstensi pg_net belum dinyalakan agar transaksi insert data tidak gagal
    NULL;
  END;

  RETURN NEW;
END;
$$;

-- 2. Pasang Trigger pada Tabel announcements (Pengumuman Baru)
DROP TRIGGER IF EXISTS trigger_announcement_push ON public.announcements;
CREATE TRIGGER trigger_announcement_push
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification_webhook();

-- 3. Pasang Trigger pada Tabel assignments (Tugas Baru)
DROP TRIGGER IF EXISTS trigger_assignment_push ON public.assignments;
CREATE TRIGGER trigger_assignment_push
  AFTER INSERT ON public.assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification_webhook();

COMMIT;
