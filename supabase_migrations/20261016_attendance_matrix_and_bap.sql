-- Migration: 20261016_attendance_matrix_and_bap.sql
-- Description: Indexes and constraints for 16-Meeting Attendance Matrix & Exam Eligibility (BAP)

DO $$
BEGIN
  -- 1. Bersihkan duplikasi lama pada attendance_logs jika ada menggunakan ROW_NUMBER (aman untuk tipe UUID)
  DELETE FROM public.attendance_logs a
  WHERE a.id IN (
    SELECT sub.id FROM (
      SELECT id, ROW_NUMBER() OVER(
        PARTITION BY course_id, student_nim, pertemuan_ke 
        ORDER BY created_at DESC, id::text DESC
      ) as rn
      FROM public.attendance_logs
    ) sub
    WHERE sub.rn > 1
  );

  -- 2. Buat unique index komposit agar upsert presensi per pertemuan berjalan mulus
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'attendance_logs' 
      AND indexname = 'idx_attendance_logs_course_student_session'
  ) THEN
    CREATE UNIQUE INDEX idx_attendance_logs_course_student_session 
      ON public.attendance_logs (course_id, student_nim, pertemuan_ke);
  END IF;

  -- 3. Indeks performa untuk kueri matriks per mata kuliah
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'attendance_logs' 
      AND indexname = 'idx_attendance_logs_course_pertemuan'
  ) THEN
    CREATE INDEX idx_attendance_logs_course_pertemuan 
      ON public.attendance_logs (course_id, pertemuan_ke);
  END IF;
END $$;

-- 4. Pastikan akses RLS tabel attendance_logs terbuka untuk peran terkait
GRANT ALL ON TABLE public.attendance_logs TO anon, authenticated, service_role;
