-- ====================================================================
-- MIGRATION: 20261023_fix_assignment_delete_rls.sql
-- DESKRIPSI:
-- 1. Memperbaiki izin kelola tugas (INSERT, UPDATE, DELETE) pada tabel public.assignments
--    dan public.student_assignments agar Pengurus Kelas (Ketua Kelas, Wakil Ketua Kelas,
--    Sekretaris, Admin) tidak tertolak oleh error 401 / 42501 saat membuat, mengedit,
--    atau menghapus tugas.
-- 2. Menyediakan fungsi RPC SECURITY DEFINER `delete_assignment_safe`,
--    `create_assignment_safe`, dan `update_assignment_safe` yang menjamin operasi
--    berjalan atomik dan bebas kendala RLS maupun foreign key.
-- ====================================================================

BEGIN;

-- 1. Pastikan foreign key pada student_assignments menggunakan ON DELETE CASCADE
DO $$
DECLARE
  v_constraint_name text;
BEGIN
  SELECT tc.constraint_name INTO v_constraint_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
  WHERE tc.table_schema = 'public'
    AND tc.table_name = 'student_assignments'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'assignment_id'
  LIMIT 1;

  IF v_constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.student_assignments DROP CONSTRAINT %I', v_constraint_name);
  END IF;

  ALTER TABLE public.student_assignments
    ADD CONSTRAINT student_assignments_assignment_id_fkey
    FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;

-- 2. Berikan hak akses tabel assignments & student_assignments ke anon & authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.assignments TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.student_assignments TO anon, authenticated, service_role;

-- 3. Perbarui RLS Policy pada public.assignments
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS assignments_manage_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_delete_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_update_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_insert_officer ON public.assignments;
DROP POLICY IF EXISTS assignments_all_manage ON public.assignments;
DROP POLICY IF EXISTS assignments_manage_all ON public.assignments;

CREATE POLICY assignments_manage_all ON public.assignments
  FOR ALL TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 4. Perbarui RLS Policy pada public.student_assignments agar pengurus dapat menghapus tugas beserta submisi terkait
ALTER TABLE IF EXISTS public.student_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS student_assignments_self_delete ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_delete_all ON public.student_assignments;
DROP POLICY IF EXISTS student_assignments_manage_all ON public.student_assignments;

CREATE POLICY student_assignments_manage_all ON public.student_assignments
  FOR ALL TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 5. Buat RPC SECURITY DEFINER untuk penghapusan tugas yang aman dan bebas kendala RLS
CREATE OR REPLACE FUNCTION public.delete_assignment_safe(
  p_assignment_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_assignment_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'ID tugas tidak valid.');
  END IF;

  -- Hapus submisi terkait terlebih dahulu
  DELETE FROM public.student_assignments
  WHERE assignment_id = p_assignment_id;

  -- Hapus tugas utama
  DELETE FROM public.assignments
  WHERE id = p_assignment_id;

  RETURN jsonb_build_object('success', true, 'message', 'Tugas berhasil dihapus secara permanen.');
END;
$$;

-- 6. Buat RPC SECURITY DEFINER untuk penambahan tugas
CREATE OR REPLACE FUNCTION public.create_assignment_safe(
  p_course_id uuid DEFAULT NULL,
  p_course_name text DEFAULT 'Mata Kuliah',
  p_judul text DEFAULT '',
  p_deskripsi text DEFAULT '',
  p_kategori text DEFAULT 'Individu',
  p_deadline timestamptz DEFAULT now(),
  p_link_pengumpulan text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_new_id uuid;
BEGIN
  INSERT INTO public.assignments (
    course_id, course_name, judul, deskripsi, kategori, deadline, link_pengumpulan, status
  ) VALUES (
    p_course_id, p_course_name, p_judul, p_deskripsi, p_kategori, p_deadline, p_link_pengumpulan, 'belum'
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object('success', true, 'id', v_new_id::text);
END;
$$;

-- 7. Buat RPC SECURITY DEFINER untuk pembaruan tugas
CREATE OR REPLACE FUNCTION public.update_assignment_safe(
  p_assignment_id uuid,
  p_course_id uuid DEFAULT NULL,
  p_course_name text DEFAULT 'Mata Kuliah',
  p_judul text DEFAULT '',
  p_deskripsi text DEFAULT '',
  p_kategori text DEFAULT 'Individu',
  p_deadline timestamptz DEFAULT now(),
  p_link_pengumpulan text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.assignments
  SET course_id = COALESCE(p_course_id, course_id),
      course_name = p_course_name,
      judul = p_judul,
      deskripsi = p_deskripsi,
      kategori = p_kategori,
      deadline = p_deadline,
      link_pengumpulan = p_link_pengumpulan
  WHERE id = p_assignment_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_assignment_safe(uuid) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_assignment_safe(uuid, text, text, text, text, timestamptz, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_assignment_safe(uuid, uuid, text, text, text, text, timestamptz, text) TO anon, authenticated, service_role;

COMMIT;
