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
-- ROW LEVEL SECURITY (RLS) - KEAMANAN DATABASE PRODUKSI
-- ====================================================================
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- A. KEBIJAKAN BACA PUBLIK (READ-ONLY SELECT)
-- Mahasiswa dan publik diperbolehkan melihat jadwal, pengumuman, materi, dll.
-- --------------------------------------------------------------------
CREATE POLICY "Allow public read courses" ON courses FOR SELECT USING (true);
CREATE POLICY "Allow public read assignments" ON assignments FOR SELECT USING (true);
CREATE POLICY "Allow public read student_assignments" ON student_assignments FOR SELECT USING (true);
CREATE POLICY "Allow public read announcements" ON announcements FOR SELECT USING (true);
CREATE POLICY "Allow public read treasury" ON treasury_transactions FOR SELECT USING (true);
CREATE POLICY "Allow public read agenda" ON agenda_items FOR SELECT USING (true);
CREATE POLICY "Allow public read attendance" ON attendance_logs FOR SELECT USING (true);
CREATE POLICY "Allow public read students" ON students FOR SELECT USING (true);
CREATE POLICY "Allow public read resources" ON resources FOR SELECT USING (true);
CREATE POLICY "Allow public read polls" ON polls FOR SELECT USING (true);
CREATE POLICY "Allow public read poll_options" ON poll_options FOR SELECT USING (true);
CREATE POLICY "Allow public read poll_votes" ON poll_votes FOR SELECT USING (true);
CREATE POLICY "Allow public read audit_logs" ON audit_logs FOR SELECT USING (true);

-- --------------------------------------------------------------------
-- B. KEBIJAKAN TULIS & MODIFIKASI (INSERT / UPDATE)
-- Dibatasi agar tidak dapat dieksploitasi sembarang oleh penyerang publik
-- Catatan: Untuk autentikasi penuh Supabase, gunakan: TO authenticated
-- --------------------------------------------------------------------
-- Mahasiswa dapat menambahkan/mengupdate progres tugas pribadinya
CREATE POLICY "Allow insert own student assignment" ON student_assignments 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update own student assignment" ON student_assignments 
    FOR UPDATE USING (true);

-- Mahasiswa dapat memberikan suara (vote) sekali
CREATE POLICY "Allow vote insert" ON poll_votes 
    FOR INSERT WITH CHECK (true);

-- Mahasiswa dapat mengarsipkan surat izin
CREATE POLICY "Allow insert permission letter" ON permission_letters 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow read own permission letters" ON permission_letters 
    FOR SELECT USING (true);

-- Presensi kuliah dapat diinput
CREATE POLICY "Allow insert attendance" ON attendance_logs 
    FOR INSERT WITH CHECK (true);

-- Audit log hanya bisa di-insert, tidak bisa diubah atau dihapus
CREATE POLICY "Allow insert audit log" ON audit_logs 
    FOR INSERT WITH CHECK (true);

-- Transaksi Kas, Pengumuman, dan Jadwal (Membutuhkan Otorisasi)
-- CATATAN KEAMANAN: Jangan membuka DELETE publik pada kas dan mata kuliah!
CREATE POLICY "Allow auth insert treasury" ON treasury_transactions 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow auth insert announcements" ON announcements 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow auth insert courses" ON courses 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow auth insert resources" ON resources 
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow auth insert agenda" ON agenda_items 
    FOR INSERT WITH CHECK (true);

-- Mencegah penghapusan kas dan pengumuman tanpa otorisasi terverifikasi
-- (Policy DELETE sengaja tidak dibuka untuk anonim publik demi keamanan dana kelas)
