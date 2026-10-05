-- ====================================================================
-- SCHEMA LENGKAP DATABASE SUPABASE: ILKOM UNAZLAM HUB
-- ====================================================================
-- Skrip SQL ini mencakup seluruh tabel untuk semua fitur aplikasi:
-- 1. courses (Jadwal Perkuliahan & Mata Kuliah)
-- 2. assignments (Tugas Kelas & Status Pengerjaan)
-- 3. announcements (Pengumuman Kelas & Info Penting)
-- 4. treasury_transactions (Kas Kelas / Bendahara)
-- 5. agenda_items (Agenda Kegiatan & Kalender Kelas)
-- 6. attendance_logs (Absensi & Presensi Perkuliahan)
-- 7. students (Direktori Mahasiswa & Manajemen Akun)
-- 8. resources (Gudang Modul, Materi, & Slide Perkuliahan)
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
    course_id TEXT,
    course_name TEXT,
    judul TEXT NOT NULL,
    deskripsi TEXT,
    kategori TEXT DEFAULT 'Individu',
    deadline TIMESTAMPTZ NOT NULL,
    link_pengumpulan TEXT,
    status TEXT DEFAULT 'belum',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. TABEL ANNOUNCEMENTS (PENGUMUMAN KELAS)
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

-- 4. TABEL TREASURY_TRANSACTIONS (KAS KELAS)
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

-- 5. TABEL AGENDA_ITEMS (AGENDA & KEGIATAN KELAS)
CREATE TABLE IF NOT EXISTS agenda_items (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    day INT NOT NULL,
    month TEXT NOT NULL,
    title TEXT NOT NULL,
    course TEXT NOT NULL,
    color_value BIGINT NOT NULL DEFAULT 4284169704,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. TABEL ATTENDANCE_LOGS (CATATAN PRESENSI MAHASISWA)
CREATE TABLE IF NOT EXISTS attendance_logs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_id TEXT,
    student_nim TEXT NOT NULL,
    pertemuan_ke INT NOT NULL,
    status TEXT NOT NULL, -- 'Hadir', 'Izin', 'Sakit', 'Alpa'
    catatan TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. TABEL STUDENTS (DIREKTORI MAHASISWA & ROLE/JABATAN)
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
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. TABEL RESOURCES (GUDANG MATERI KULIAH)
CREATE TABLE IF NOT EXISTS resources (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    course_name TEXT NOT NULL,
    pertemuan_ke INT DEFAULT 1,
    judul TEXT NOT NULL,
    jenis TEXT DEFAULT 'Slide PPT',
    link_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ====================================================================
-- AKTIFKAN RLS (ROW LEVEL SECURITY) & BERIKAN AKSES ANON (PUBLIK)
-- ====================================================================
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- Kebijakan akses penuh untuk anonim / aplikasi publik
CREATE POLICY "Public Read All Courses" ON courses FOR SELECT USING (true);
CREATE POLICY "Public Insert Courses" ON courses FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Courses" ON courses FOR UPDATE USING (true);
CREATE POLICY "Public Delete Courses" ON courses FOR DELETE USING (true);

CREATE POLICY "Public Read All Assignments" ON assignments FOR SELECT USING (true);
CREATE POLICY "Public Insert Assignments" ON assignments FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Assignments" ON assignments FOR UPDATE USING (true);
CREATE POLICY "Public Delete Assignments" ON assignments FOR DELETE USING (true);

CREATE POLICY "Public Read All Announcements" ON announcements FOR SELECT USING (true);
CREATE POLICY "Public Insert Announcements" ON announcements FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Announcements" ON announcements FOR UPDATE USING (true);
CREATE POLICY "Public Delete Announcements" ON announcements FOR DELETE USING (true);

CREATE POLICY "Public Read All Treasury" ON treasury_transactions FOR SELECT USING (true);
CREATE POLICY "Public Insert Treasury" ON treasury_transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Treasury" ON treasury_transactions FOR UPDATE USING (true);
CREATE POLICY "Public Delete Treasury" ON treasury_transactions FOR DELETE USING (true);

CREATE POLICY "Public Read All Agenda" ON agenda_items FOR SELECT USING (true);
CREATE POLICY "Public Insert Agenda" ON agenda_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Agenda" ON agenda_items FOR UPDATE USING (true);
CREATE POLICY "Public Delete Agenda" ON agenda_items FOR DELETE USING (true);

CREATE POLICY "Public Read All Attendance" ON attendance_logs FOR SELECT USING (true);
CREATE POLICY "Public Insert Attendance" ON attendance_logs FOR INSERT WITH CHECK (true);

CREATE POLICY "Public Read All Students" ON students FOR SELECT USING (true);
CREATE POLICY "Public Insert Students" ON students FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Students" ON students FOR UPDATE USING (true);

CREATE POLICY "Public Read All Resources" ON resources FOR SELECT USING (true);
CREATE POLICY "Public Insert Resources" ON resources FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Delete Resources" ON resources FOR DELETE USING (true);
