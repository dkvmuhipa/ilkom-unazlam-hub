-- Server-only read of today's and tomorrow's schedules, respecting overrides.
CREATE OR REPLACE FUNCTION public.get_reminder_schedule(p_timezone text DEFAULT 'Asia/Makassar')
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public
AS $$
  WITH dates AS (
    SELECT (now() AT TIME ZONE p_timezone)::date + n AS day FROM generate_series(0, 1) n
  )
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', c.id::text || '_' || d.day::text,
    'nama', c.nama_mk, 'kode', c.kode_mk, 'dosen', c.dosen_pengampu,
    'dosenWa', c.dosen_wa,
    'hari', (ARRAY['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'])[extract(dow FROM d.day)::int + 1],
    'targetDate', d.day::text,
    'jamMulai', left(COALESCE(o.new_jam_mulai::text, c.jam_mulai::text), 5),
    'jamSelesai', left(COALESCE(o.new_jam_selesai::text, c.jam_selesai::text), 5),
    'ruangan', COALESCE(o.new_ruangan, c.ruangan), 'isCancelledToday', false
  )), '[]'::jsonb)
  FROM dates d CROSS JOIN public.courses c
  LEFT JOIN LATERAL (
    SELECT * FROM public.course_schedule_overrides x
    WHERE x.course_id = c.id AND x.override_date = d.day
    ORDER BY x.created_at DESC LIMIT 1
  ) o ON true
  WHERE lower(c.hari) = lower((ARRAY['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'])[extract(dow FROM d.day)::int + 1])
    AND COALESCE(o.status, '') <> 'CANCELLED';
$$;
REVOKE ALL ON FUNCTION public.get_reminder_schedule(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_reminder_schedule(text) TO service_role;
