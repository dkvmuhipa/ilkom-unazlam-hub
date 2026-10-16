-- Migration: 20261016_broadcast_command_hub.sql
-- Description: Expand announcements table for Admin Broadcast Command Hub
-- Supports targeted broadcasts (ALL, ANGKATAN, KELAS), pinned priority, and fast indexing.

DO $$
BEGIN
  -- 1. Tambah kolom target_audience jika belum ada
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'announcements' 
      AND column_name = 'target_audience'
  ) THEN
    ALTER TABLE public.announcements ADD COLUMN target_audience text DEFAULT 'ALL';
  END IF;

  -- 2. Tambah kolom target_angkatan jika belum ada
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'announcements' 
      AND column_name = 'target_angkatan'
  ) THEN
    ALTER TABLE public.announcements ADD COLUMN target_angkatan text;
  END IF;

  -- 3. Tambah kolom target_kelas jika belum ada
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'announcements' 
      AND column_name = 'target_kelas'
  ) THEN
    ALTER TABLE public.announcements ADD COLUMN target_kelas text;
  END IF;
END $$;

-- 4. Indeks performa untuk feed pengumuman & filter target
CREATE INDEX IF NOT EXISTS idx_announcements_created_pinned 
  ON public.announcements (is_pinned DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_announcements_target 
  ON public.announcements (target_audience, target_angkatan);

-- 5. Pastikan hak akses RLS mengizinkan admin & pengurus kelas mengelola siaran
GRANT ALL ON TABLE public.announcements TO anon, authenticated, service_role;
