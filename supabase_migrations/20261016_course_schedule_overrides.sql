-- ====================================================================
-- MIGRASI: SISTEM PENANGANAN PERUBAHAN JADWAL KULIAH DINAMIS (OVERRIDES)
-- Tanggal: 16 Oktober 2026
-- Deskripsi: Menyimpan penyesuaian jadwal insidental (jam berubah, pindah
--            ruang, kelas daring, kelas batal) tanpa merusak master courses.
-- ====================================================================

CREATE TABLE IF NOT EXISTS public.course_schedule_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    override_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'RESCHEDULED' CHECK (status IN ('RESCHEDULED', 'ONLINE', 'ROOM_CHANGE', 'CANCELLED')),
    original_jam_mulai VARCHAR(10) NOT NULL,
    original_jam_selesai VARCHAR(10),
    new_jam_mulai VARCHAR(10),
    new_jam_selesai VARCHAR(10),
    new_ruangan VARCHAR(100),
    online_meeting_url TEXT,
    alasan TEXT,
    reported_by_nim VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT course_override_unique_date UNIQUE (course_id, override_date)
);

-- Indeks performa pencarian berdasarkan tanggal & mata kuliah
CREATE INDEX IF NOT EXISTS idx_course_overrides_date ON public.course_schedule_overrides(override_date);
CREATE INDEX IF NOT EXISTS idx_course_overrides_course ON public.course_schedule_overrides(course_id);

-- Hak akses tabel untuk peran anon, authenticated, & service_role
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.course_schedule_overrides TO anon, authenticated, service_role;

-- Kebijakan RLS (Row Level Security)
ALTER TABLE public.course_schedule_overrides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS course_schedule_overrides_read_policy ON public.course_schedule_overrides;
CREATE POLICY course_schedule_overrides_read_policy ON public.course_schedule_overrides
    FOR SELECT TO anon, authenticated, service_role
    USING (true);

DROP POLICY IF EXISTS course_schedule_overrides_write_policy ON public.course_schedule_overrides;
CREATE POLICY course_schedule_overrides_write_policy ON public.course_schedule_overrides
    FOR ALL TO anon, authenticated, service_role
    USING (true)
    WITH CHECK (true);

-- Tambahkan ke publikasi Realtime Supabase
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.course_schedule_overrides;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
  WHEN OTHERS THEN
    NULL;
END $$;
