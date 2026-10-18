-- Shared student groups with membership-scoped reads.
-- Students can only fetch groups where their authenticated NIM is a member.
-- Class officers can manage groups in their class; administrators can manage all.

BEGIN;

CREATE TABLE IF NOT EXISTS public.student_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_name text NOT NULL CHECK (length(trim(group_name)) BETWEEN 1 AND 100),
  course_name text NOT NULL CHECK (length(trim(course_name)) BETWEEN 1 AND 160),
  assignment_title text NOT NULL CHECK (length(trim(assignment_title)) BETWEEN 1 AND 200),
  drive_url text,
  class_key text NOT NULL,
  created_by_nim text NOT NULL REFERENCES public.students(nim) ON DELETE RESTRICT,
  tasks jsonb NOT NULL DEFAULT '[{"title":"Riset Topik & Studi Literatur","is_completed":false},{"title":"Penyusunan Makalah / Laporan","is_completed":false},{"title":"Pembuatan Slide Presentasi","is_completed":false},{"title":"Review Akhir & Pengumpulan","is_completed":false}]'::jsonb
    CHECK (jsonb_typeof(tasks) = 'array'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.student_group_members (
  group_id uuid NOT NULL REFERENCES public.student_groups(id) ON DELETE CASCADE,
  student_nim text NOT NULL REFERENCES public.students(nim) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, student_nim)
);

CREATE INDEX IF NOT EXISTS student_group_members_student_nim_idx
  ON public.student_group_members(student_nim);
CREATE INDEX IF NOT EXISTS student_groups_class_key_idx
  ON public.student_groups(class_key);

ALTER TABLE public.student_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_group_members ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.student_groups, public.student_group_members FROM PUBLIC, anon, authenticated;

-- Intentionally define no table policies and grant no table privileges.
-- All access goes through the authenticated, SECURITY DEFINER RPCs below;
-- this avoids recursive membership policies and prevents Data API bypasses.

CREATE OR REPLACE FUNCTION public.get_student_groups()
RETURNS TABLE (
  id uuid,
  group_name text,
  course_name text,
  assignment_title text,
  drive_url text,
  tasks jsonb,
  members jsonb
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_nim text := public.current_student_nim();
  v_class text;
  v_is_admin boolean := public.has_class_role(ARRAY['ADMIN']);
  v_is_officer boolean := public.has_class_role(ARRAY['KETUA KELAS', 'SEKRETARIS']);
BEGIN
  IF v_nim IS NULL THEN
    RAISE EXCEPTION 'Sesi mahasiswa tidak valid.';
  END IF;

  SELECT s.kelas INTO v_class FROM public.students s WHERE s.nim = v_nim;

  RETURN QUERY
  SELECT g.id, g.group_name, g.course_name, g.assignment_title, g.drive_url,
         g.tasks,
         COALESCE((
           SELECT jsonb_agg(jsonb_build_object('nim', s.nim, 'nama', s.nama) ORDER BY s.nama)
           FROM public.student_group_members gm
           JOIN public.students s ON s.nim = gm.student_nim
           WHERE gm.group_id = g.id
         ), '[]'::jsonb) AS members
  FROM public.student_groups g
  WHERE EXISTS (
          SELECT 1 FROM public.student_group_members gm
          WHERE gm.group_id = g.id AND gm.student_nim = v_nim
        )
     OR v_is_admin
     OR (v_is_officer AND g.class_key = v_class)
  ORDER BY g.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_student_group(
  p_group_name text,
  p_course_name text,
  p_assignment_title text,
  p_drive_url text,
  p_member_nims text[]
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_nim text := public.current_student_nim();
  v_class text;
  v_group_id uuid;
  v_members text[];
BEGIN
  IF v_nim IS NULL OR NOT public.has_class_role(ARRAY['ADMIN', 'KETUA KELAS', 'SEKRETARIS']) THEN
    RAISE EXCEPTION 'Hanya admin atau pengurus kelas yang dapat membentuk kelompok.';
  END IF;
  IF length(trim(coalesce(p_group_name, ''))) NOT BETWEEN 1 AND 100
     OR length(trim(coalesce(p_course_name, ''))) NOT BETWEEN 1 AND 160
     OR length(trim(coalesce(p_assignment_title, ''))) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'Nama kelompok, mata kuliah, dan judul tugas wajib diisi.';
  END IF;
  IF coalesce(array_length(p_member_nims, 1), 0) NOT BETWEEN 1 AND 30 THEN
    RAISE EXCEPTION 'Pilih antara 1 sampai 30 anggota.';
  END IF;

  SELECT s.kelas INTO v_class FROM public.students s WHERE s.nim = v_nim;
  SELECT array_agg(DISTINCT trim(nim)) INTO v_members
  FROM unnest(p_member_nims) AS nim
  WHERE length(trim(nim)) > 0;
  IF coalesce(cardinality(v_members), 0) = 0 OR EXISTS (
    SELECT 1 FROM unnest(v_members) selected(nim)
    LEFT JOIN public.students s ON s.nim = selected.nim AND s.is_aktif = true
    WHERE s.nim IS NULL OR s.kelas IS DISTINCT FROM v_class
  ) THEN
    RAISE EXCEPTION 'Semua anggota harus mahasiswa aktif di kelas pengurus.';
  END IF;

  INSERT INTO public.student_groups(group_name, course_name, assignment_title, drive_url, class_key, created_by_nim)
  VALUES (trim(p_group_name), trim(p_course_name), trim(p_assignment_title), nullif(trim(coalesce(p_drive_url, '')), ''), v_class, v_nim)
  RETURNING id INTO v_group_id;

  INSERT INTO public.student_group_members(group_id, student_nim)
  SELECT v_group_id, selected.nim FROM unnest(v_members) selected(nim);
  RETURN v_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_student_group_tasks(p_group_id uuid, p_tasks jsonb)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_tasks IS NULL
     OR jsonb_typeof(p_tasks) IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_tasks) > 100
     OR octet_length(p_tasks::text) > 20000
     OR EXISTS (
       SELECT 1 FROM jsonb_array_elements(p_tasks) task
       WHERE jsonb_typeof(task) IS DISTINCT FROM 'object'
          OR jsonb_typeof(task->'title') IS DISTINCT FROM 'string'
          OR length(trim(task->>'title')) NOT BETWEEN 1 AND 200
          OR jsonb_typeof(task->'is_completed') IS DISTINCT FROM 'boolean'
     ) THEN
    RAISE EXCEPTION 'Format checklist tidak valid.';
  END IF;
  UPDATE public.student_groups g
  SET tasks = p_tasks, updated_at = now()
  WHERE g.id = p_group_id
    AND (
      EXISTS (SELECT 1 FROM public.student_group_members m
              WHERE m.group_id = g.id AND m.student_nim = public.current_student_nim())
      OR public.has_class_role(ARRAY['ADMIN'])
      OR (public.has_class_role(ARRAY['KETUA KELAS', 'SEKRETARIS']) AND g.class_key = (
        SELECT s.kelas FROM public.students s WHERE s.nim = public.current_student_nim()
      ))
    );
  IF NOT FOUND THEN RAISE EXCEPTION 'Kelompok tidak ditemukan atau akses ditolak.'; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_student_group(p_group_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  DELETE FROM public.student_groups g
  WHERE g.id = p_group_id
    AND (
      public.has_class_role(ARRAY['ADMIN'])
      OR (public.has_class_role(ARRAY['KETUA KELAS', 'SEKRETARIS']) AND g.class_key = (
        SELECT s.kelas FROM public.students s WHERE s.nim = public.current_student_nim()
      ))
    );
  IF NOT FOUND THEN RAISE EXCEPTION 'Kelompok tidak ditemukan atau akses ditolak.'; END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_groups() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_student_group(text, text, text, text, text[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_student_group_tasks(uuid, jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_student_group(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_student_group(text, text, text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_student_group_tasks(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_student_group(uuid) TO authenticated;

COMMIT;
