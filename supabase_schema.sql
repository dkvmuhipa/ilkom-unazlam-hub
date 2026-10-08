-- ====================================================================
-- SCHEMA LENGKAP & AMAN DATABASE SUPABASE: ILKOM UNAZLAM HUB
-- ====================================================================
-- Skrip SQL ini mencakup seluruh tabel untuk semua fitur aplikasi:
-- 1. courses (Jadwal Perkuliahan & Mata Kuliah)
-- 2. assignments (Tugas Kelas)
-- 3. student_assignments (Tracking Progres Tugas Personal Per-Mahasiswa)
-- 4. announcements (Pengumuman Kelas & Info Penting)
-- 5. treasury_transactions (Kas Kelas / Bendahara)
-- 6. agenda_items (Agenda Kegiatan & Kalender Kelas)
-- 7. attendance_logs (Absensi & Presensi Perkuliahan)
-- 8. students (Direktori Mahasiswa & Manajemen Akun)
-- 9. resources (Gudang Modul, Materi, & Slide Perkuliahan)
-- 10. polls & poll_options & poll_votes (Sistem Voting / Pemungutan Suara)
-- 11. permission_letters (Pengajuan Surat Izin Mahasiswa)
-- 12. audit_logs (Riwayat Aktivitas & Perubahan Data)
-- ====================================================================

-- Aktifkan ekstensi UUID jika belum aktif
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABEL COURSES (MATA KULIAH & JADWAL KULIAH)
CREATE TABLE IF NOT EXISTS courses (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    kode_mk TEXT NOT NULL,
    nama_mk TEXT NOT NULL,
    sks INT NOT NULL DEFAULT 2,
    semester INT NOT NULL DEFAULT 1,
    dosen_pengampu TEXT NOT NULL,
    dosen_wa TEXT,
    hari TEXT NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    ruangan TEXT NOT NULL DEFAULT 'Ruang A2',
    link_virtual TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. TABEL ASSIGNMENTS (TUGAS KELAS)
CREATE TABLE IF NOT EXISTS assignments (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_id TEXT REFERENCES courses(id) ON DELETE SET NULL,
    course_name TEXT,
    judul TEXT NOT NULL,
    deskripsi TEXT,
    kategori TEXT DEFAULT 'Individu',
    deadline TIMESTAMPTZ NOT NULL,
    link_pengumpulan TEXT,
    status TEXT DEFAULT 'belum',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. TABEL STUDENT_ASSIGNMENTS (STATUS TUGAS PERSONAL PER-MAHASISWA)
-- Memisahkan status pengerjaan personal dari master tabel tugas
CREATE TABLE IF NOT EXISTS student_assignments (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    assignment_id TEXT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_nim TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'belum', -- 'belum', 'sedang_dikerjakan', 'selesai'
    link_pengumpulan TEXT,
    catatan TEXT,
    submitted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(assignment_id, student_nim)
);

-- 4. TABEL ANNOUNCEMENTS (PENGUMUMAN KELAS)
CREATE TABLE IF NOT EXISTS announcements (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    author_name TEXT DEFAULT 'Nur Farida (Ketua Kelas)',
    author_role TEXT DEFAULT 'Ketua Kelas',
    judul TEXT NOT NULL,
    isi TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT false,
    kategori TEXT DEFAULT 'Akademik',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. TABEL TREASURY_TRANSACTIONS (KAS KELAS)
CREATE TABLE IF NOT EXISTS treasury_transactions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    judul TEXT NOT NULL,
    nominal BIGINT NOT NULL,
    is_pemasukan BOOLEAN NOT NULL DEFAULT true,
    kategori TEXT NOT NULL DEFAULT 'Kas Bulanan',
    tanggal TIMESTAMPTZ DEFAULT now(),
    pencatat TEXT DEFAULT 'Farah Nabila (Bendahara)',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. TABEL AGENDA_ITEMS (AGENDA & KEGIATAN KELAS)
CREATE TABLE IF NOT EXISTS agenda_items (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    day INT NOT NULL,
    month TEXT NOT NULL,
    title TEXT NOT NULL,
    course TEXT NOT NULL,
    color_value BIGINT NOT NULL DEFAULT 4284169704,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. TABEL ATTENDANCE_LOGS (CATATAN PRESENSI MAHASISWA)
CREATE TABLE IF NOT EXISTS attendance_logs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_id TEXT REFERENCES courses(id) ON DELETE SET NULL,
    student_nim TEXT NOT NULL,
    pertemuan_ke INT NOT NULL,
    status TEXT NOT NULL, -- 'Hadir', 'Izin', 'Sakit', 'Alpa'
    catatan TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. TABEL STUDENTS (DIREKTORI MAHASISWA & ROLE/JABATAN)
CREATE TABLE IF NOT EXISTS students (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    nim TEXT UNIQUE NOT NULL,
    nama TEXT NOT NULL,
    email TEXT,
    no_wa TEXT,
    peminatan TEXT DEFAULT '',
    prodi TEXT DEFAULT 'Ilmu Komunikasi',
    semester INT DEFAULT 1,
    kelas TEXT DEFAULT 'Ilmu Komunikasi',
    role TEXT DEFAULT 'MAHASISWA',
    jabatan TEXT DEFAULT 'Mahasiswa',
    is_aktif BOOLEAN DEFAULT true,
    instagram TEXT,
    linkedin TEXT,
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. TABEL RESOURCES (GUDANG MATERI KULIAH)
CREATE TABLE IF NOT EXISTS resources (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_name TEXT NOT NULL,
    pertemuan_ke INT DEFAULT 1,
    judul TEXT NOT NULL,
    jenis TEXT DEFAULT 'Slide PPT',
    link_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. TABEL POLLS & VOTING (FITUR POLLING KELAS)
CREATE TABLE IF NOT EXISTS polls (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    title TEXT NOT NULL,
    description TEXT,
    author TEXT NOT NULL,
    is_open BOOLEAN DEFAULT true,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS poll_options (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    poll_id TEXT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    order_index INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS poll_votes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    poll_id TEXT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id TEXT NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    voter_nim TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(poll_id, voter_nim)
);

-- 11. TABEL PERMISSION_LETTERS (ARSIP SURAT IZIN PERKULIAHAN)
CREATE TABLE IF NOT EXISTS permission_letters (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    student_nim TEXT NOT NULL,
    student_name TEXT NOT NULL,
    letter_type TEXT NOT NULL DEFAULT 'Izin Sakit',
    dosen_name TEXT NOT NULL,
    course_name TEXT NOT NULL,
    reason TEXT NOT NULL,
    letter_date TEXT NOT NULL,
    full_content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 12. TABEL AUDIT_LOGS (AUDIT TRAIL AKTIVITAS)
CREATE TABLE IF NOT EXISTS audit_logs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    user_identifier TEXT NOT NULL,
    user_name TEXT,
    action_type TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'EXPORT'
    target_module TEXT NOT NULL, -- 'TREASURY', 'COURSES', 'ASSIGNMENTS', etc.
    description TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ====================================================================
-- ROW LEVEL SECURITY: only active, linked students can access class data.
-- Run this script with the Supabase SQL Editor or CLI as a trusted operator.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.current_student_nim()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT s.nim FROM public.students s
  WHERE s.auth_user_id = (SELECT auth.uid()) AND s.is_aktif = true
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.has_class_role(allowed_roles text[])
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.students s
    WHERE s.auth_user_id = (SELECT auth.uid()) AND s.is_aktif = true
      AND EXISTS (
        SELECT 1 FROM unnest(allowed_roles) r(role_name)
        WHERE upper(s.role) = upper(r.role_name) OR upper(s.jabatan) = upper(r.role_name)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_class_directory()
RETURNS TABLE (id text, nim text, nama text, no_wa text, peminatan text,
  prodi text, semester integer, kelas text, role text, jabatan text,
  is_aktif boolean, instagram text, linkedin text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT s.id, s.nim, s.nama, s.no_wa, s.peminatan, s.prodi, s.semester,
    s.kelas, s.role, s.jabatan, s.is_aktif, s.instagram, s.linkedin
  FROM public.students s
  WHERE s.is_aktif = true
    AND (SELECT public.current_student_nim()) IS NOT NULL
  ORDER BY s.nama;
$$;

REVOKE ALL ON FUNCTION public.current_student_nim() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_class_role(text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_student_nim() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_class_role(text[]) TO authenticated;
REVOKE ALL ON FUNCTION public.get_class_directory() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_class_directory() TO authenticated;

CREATE OR REPLACE FUNCTION public.prevent_client_auth_link_change()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF (SELECT auth.uid()) IS NOT NULL
     AND NEW.auth_user_id IS DISTINCT FROM OLD.auth_user_id THEN
    RAISE EXCEPTION 'Auth account links can only be managed by a trusted administrator';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS prevent_client_auth_link_change ON public.students;
CREATE TRIGGER prevent_client_auth_link_change BEFORE UPDATE OF auth_user_id
  ON public.students FOR EACH ROW EXECUTE FUNCTION public.prevent_client_auth_link_change();

DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['courses','assignments','student_assignments','announcements',
    'treasury_transactions','agenda_items','attendance_logs','students','resources',
    'polls','poll_options','poll_votes','permission_letters','audit_logs'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'active_student_read', t);
  END LOOP;
END $$;

-- Remove policies from older versions of this script before installing the
-- scoped policies below. RLS policies are permissive by default, so stale
-- USING (true) policies would otherwise continue to grant access.
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = ANY(ARRAY[
      'courses','assignments','student_assignments','announcements','treasury_transactions',
      'agenda_items','attendance_logs','students','resources','polls','poll_options',
      'poll_votes','permission_letters','audit_logs'])
  LOOP EXECUTE format('DROP POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename); END LOOP;
END $$;

DO $$ BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON public.profiles FROM PUBLIC, anon, authenticated';
    EXECUTE 'ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY';
  END IF;
END $$;

CREATE POLICY active_student_read ON public.courses FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY assignments_read ON public.assignments FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY announcements_read ON public.announcements FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY treasury_read ON public.treasury_transactions FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY agenda_read ON public.agenda_items FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY resources_read ON public.resources FOR SELECT TO authenticated
  USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY students_read_self_or_officer ON public.students FOR SELECT TO authenticated
  USING (auth_user_id = (SELECT auth.uid()) OR public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY attendance_read_self_or_officer ON public.attendance_logs FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY student_assignments_read_own ON public.student_assignments FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY student_assignments_insert_own ON public.student_assignments FOR INSERT TO authenticated
  WITH CHECK (student_nim = (SELECT public.current_student_nim()));
CREATE POLICY student_assignments_update_own ON public.student_assignments FOR UPDATE TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()))
  WITH CHECK (student_nim = (SELECT public.current_student_nim()));
CREATE POLICY polls_read ON public.polls FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY poll_options_read ON public.poll_options FOR SELECT TO authenticated USING ((SELECT public.current_student_nim()) IS NOT NULL);
CREATE POLICY poll_votes_read_own ON public.poll_votes FOR SELECT TO authenticated
  USING (voter_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY poll_votes_insert_own ON public.poll_votes FOR INSERT TO authenticated
  WITH CHECK (voter_nim = (SELECT public.current_student_nim()));
CREATE POLICY permission_letters_read_own_or_officer ON public.permission_letters FOR SELECT TO authenticated
  USING (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY permission_letters_insert_own ON public.permission_letters FOR INSERT TO authenticated
  WITH CHECK (student_nim = (SELECT public.current_student_nim()));
CREATE POLICY audit_logs_read_admin ON public.audit_logs FOR SELECT TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY audit_logs_insert_own ON public.audit_logs FOR INSERT TO authenticated
  WITH CHECK (user_identifier = (SELECT public.current_student_nim()));

-- Authorized class maintenance.
CREATE POLICY courses_manage ON public.courses FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY assignments_manage ON public.assignments FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY announcements_manage ON public.announcements FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY treasury_manage ON public.treasury_transactions FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Bendahara'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Bendahara']));
CREATE POLICY agenda_manage ON public.agenda_items FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY resources_manage ON public.resources FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas','Sekretaris']));
CREATE POLICY students_update_admin ON public.students FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN']));
CREATE POLICY attendance_insert_self_or_officer ON public.attendance_logs FOR INSERT TO authenticated
  WITH CHECK (student_nim = (SELECT public.current_student_nim()) OR public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY attendance_manage_officer ON public.attendance_logs FOR UPDATE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY attendance_delete_officer ON public.attendance_logs FOR DELETE TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY polls_manage ON public.polls FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
CREATE POLICY poll_options_manage ON public.poll_options FOR ALL TO authenticated
  USING (public.has_class_role(ARRAY['ADMIN','Ketua Kelas'])) WITH CHECK (public.has_class_role(ARRAY['ADMIN','Ketua Kelas']));
