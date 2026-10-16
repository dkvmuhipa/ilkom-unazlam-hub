-- Migration: 20261017_bulk_csv_ingestion_hub.sql
-- Description: Indexes and constraints for Bulk CSV Ingestion Hub (Students & Courses)

DO $$
BEGIN
  -- 1. Pastikan tabel students memiliki unique index pada kolom 'nim'
  -- Bersihkan duplikasi lama jika ada
  DELETE FROM public.students a
  WHERE a.id IN (
    SELECT sub.id FROM (
      SELECT id, ROW_NUMBER() OVER(
        PARTITION BY nim 
        ORDER BY created_at DESC NULLS LAST, id::text DESC
      ) as rn
      FROM public.students
    ) sub
    WHERE sub.rn > 1
  );

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'students' 
      AND indexname = 'idx_students_nim_unique'
  ) THEN
    CREATE UNIQUE INDEX idx_students_nim_unique ON public.students (nim);
  END IF;

  -- 2. Pastikan tabel courses memiliki unique index pada kolom 'kode_mk'
  -- Bersihkan duplikasi lama jika ada
  DELETE FROM public.courses a
  WHERE a.id IN (
    SELECT sub.id FROM (
      SELECT id, ROW_NUMBER() OVER(
        PARTITION BY kode_mk 
        ORDER BY id::text DESC
      ) as rn
      FROM public.courses
    ) sub
    WHERE sub.rn > 1
  );

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'courses' 
      AND indexname = 'idx_courses_kode_mk_unique'
  ) THEN
    CREATE UNIQUE INDEX idx_courses_kode_mk_unique ON public.courses (kode_mk);
  END IF;
END $$;

-- 3. Pastikan izin akses tabel terbuka untuk anon, authenticated, and service_role
GRANT ALL ON TABLE public.students TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.courses TO anon, authenticated, service_role;
