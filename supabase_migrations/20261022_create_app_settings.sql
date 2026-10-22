-- Migration: 20261022_create_app_settings.sql
-- Description: Tabel penyimpanan konfigurasi sistem dan gateway WAHA agar tersinkronisasi antar perangkat dan tidak hilang saat cache browser / storage lokal dibersihkan.

BEGIN;

CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value text NOT NULL,
  description text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Aktifkan Row Level Security
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Berikan izin akses penuh ke anon, authenticated, dan service_role
GRANT ALL ON TABLE public.app_settings TO anon, authenticated, service_role;

-- Kebijakan baca untuk semua
DROP POLICY IF EXISTS app_settings_read_all ON public.app_settings;
CREATE POLICY app_settings_read_all ON public.app_settings
  FOR SELECT TO anon, authenticated, service_role
  USING (true);

-- Kebijakan tulis/modifikasi untuk semua
DROP POLICY IF EXISTS app_settings_manage_all ON public.app_settings;
CREATE POLICY app_settings_manage_all ON public.app_settings
  FOR ALL TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- Fungsi RPC untuk membaca seluruh setting aplikasi
CREATE OR REPLACE FUNCTION public.get_app_settings()
RETURNS TABLE (
  setting_key text,
  setting_value text,
  updated_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT s.key, s.value, s.updated_at
  FROM public.app_settings AS s;
$$;

-- Fungsi RPC untuk menyimpan setting aplikasi
CREATE OR REPLACE FUNCTION public.save_app_setting(
  p_key text,
  p_value text,
  p_description text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.app_settings (key, value, description, updated_at)
  VALUES (p_key, p_value, p_description, now())
  ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value,
      description = coalesce(EXCLUDED.description, public.app_settings.description),
      updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_app_settings() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_app_setting(text, text, text) TO anon, authenticated, service_role;

-- Nilai awal default jika belum pernah disetel
INSERT INTO public.app_settings (key, value, description)
VALUES 
  ('waha_base_url', 'https://ilkom-reminders-production.up.railway.app', 'Base URL Gateway WhatsApp WAHA'),
  ('waha_session_name', 'default', 'Nama Sesi WhatsApp WAHA'),
  ('waha_is_cloud_mode', 'true', 'Status Mode Cloud Gateway WAHA')
ON CONFLICT (key) DO NOTHING;

COMMIT;
