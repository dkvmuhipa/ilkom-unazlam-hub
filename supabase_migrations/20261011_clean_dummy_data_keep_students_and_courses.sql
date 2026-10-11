-- ====================================================================
-- MIGRATION: 20261011_clean_dummy_data_keep_students_and_courses.sql
-- DESKRIPSI:
-- 1. Menghapus data testing / sampel sementara (Tugas Sampel, Pengumuman Sampel,
--    Transaksi Kas Sampel, Presensi/Absensi Sampel, Agenda, Modul Sampel, Polling).
-- 2. MEMPERTAHANKAN DATA REAL: 24 Data Mahasiswa & 8 Jadwal Kuliah Resmi FISIP UNAZLAM.
-- 3. Memberikan hak akses SELECT pada courses dan students untuk anon & authenticated
--    agar tidak terjadi error 401 / Unauthorized saat memuat data aplikasi.
-- ====================================================================

BEGIN;

-- ====================================================================
-- 1. BERSIHKAN DATA TESTING / SAMPEL SEMENTARA
-- ====================================================================

-- Hapus data dari tabel-tabel utama yang berisi data dummy
TRUNCATE TABLE
  public.student_assignments,
  public.assignments,
  public.announcements,
  public.treasury_transactions,
  public.treasury_dues,
  public.agenda_items,
  public.attendance_logs,
  public.resources,
  public.audit_logs
CASCADE;

-- Hapus data dari tabel pendukung jika tabel tersebut ada
DO $$ BEGIN
  IF to_regclass('public.student_course_grades') IS NOT NULL THEN
    TRUNCATE TABLE public.student_course_grades CASCADE;
  END IF;
  IF to_regclass('public.user_push_tokens') IS NOT NULL THEN
    TRUNCATE TABLE public.user_push_tokens CASCADE;
  END IF;
  IF to_regclass('public.poll_votes') IS NOT NULL THEN
    TRUNCATE TABLE public.poll_votes CASCADE;
  END IF;
  IF to_regclass('public.poll_options') IS NOT NULL THEN
    TRUNCATE TABLE public.poll_options CASCADE;
  END IF;
  IF to_regclass('public.polls') IS NOT NULL THEN
    TRUNCATE TABLE public.polls CASCADE;
  END IF;
  IF to_regclass('public.permission_letters') IS NOT NULL THEN
    TRUNCATE TABLE public.permission_letters CASCADE;
  END IF;
END $$;

-- ====================================================================
-- 2. PASTIKAN 8 JADWAL KULIAH RESMI FISIP UNAZLAM TERSEDIA
-- ====================================================================

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'courses_kode_mk_key'
  ) THEN
    ALTER TABLE public.courses ADD CONSTRAINT courses_kode_mk_key UNIQUE (kode_mk);
  END IF;
END $$;

INSERT INTO public.courses (kode_mk, nama_mk, sks, semester, dosen_pengampu, dosen_wa, hari, jam_mulai, jam_selesai, ruangan)
VALUES
  ('2 PK 100', 'Pendidikan Pancasila', 2, 1, 'Drs. H. M. Rusli, M.Si', '081234567890', 'Senin', '15:30:00', '17:00:00', 'Ruang A2'),
  ('2 PK 103', 'Pendidikan Kewarganegaraan', 2, 1, 'Dra. Hj. Nurhaida, M.Pd', '081234567891', 'Senin', '18:30:00', '20:00:00', 'Ruang B1'),
  ('3 PK 101A', 'Pendidikan Agama Islam *', 3, 1, 'Dr. H. Lukman Hakim, M.Ag', '081234567892', 'Selasa', '15:30:00', '17:45:00', 'Ruang A1'),
  ('3 PK 101B', 'Pendidikan Agama Kristen *', 3, 1, 'Pdt. Dr. Markus Somba, M.Th', '081234567893', 'Selasa', '15:30:00', '17:45:00', 'Ruang B1'),
  ('2 PK 106', 'Ilmu Kealaman Dasar *', 2, 1, 'Dr. Ir. Hendra Gunawan, M.Si', '081234567894', 'Selasa', '18:30:00', '20:45:00', 'Ruang A2'),
  ('3 PK 105', 'Bahasa Indonesia *', 3, 1, 'Dra. Hj. Nurhayati, M.Hum', '081234567895', 'Rabu', '15:30:00', '17:45:00', 'Ruang A2'),
  ('3 PK 104', 'Bahasa Inggris *', 3, 1, 'Farid Wajdi, S.Pd., M.A', '081234567896', 'Kamis', '18:30:00', '20:45:00', 'Ruang A1'),
  ('3 PK 201', 'Pengantar Ilmu Politik *', 3, 1, 'Dr. Muhammad Rizal, S.IP., M.Si', '081234567897', 'Jumat', '18:30:00', '20:45:00', 'Ruang B1')
ON CONFLICT (kode_mk) DO UPDATE SET
  nama_mk = EXCLUDED.nama_mk,
  sks = EXCLUDED.sks,
  semester = EXCLUDED.semester,
  dosen_pengampu = EXCLUDED.dosen_pengampu,
  dosen_wa = EXCLUDED.dosen_wa,
  hari = EXCLUDED.hari,
  jam_mulai = EXCLUDED.jam_mulai,
  jam_selesai = EXCLUDED.jam_selesai,
  ruangan = EXCLUDED.ruangan;

-- ====================================================================
-- 3. PASTIKAN 24 DATA MAHASISWA & ADMIN RESMI FISIP UNAZLAM TERSEDIA
-- ====================================================================

INSERT INTO public.students (nim, nama, email, no_wa, prodi, semester, kelas, role, jabatan, instagram)
VALUES
  ('admin', 'ADMINISTRATOR SISTEM', 'admin.ilkom@unazlam.ac.id', '081234567890', 'Ilmu Komunikasi', 1, 'Fakultas FISIP UNAZLAM', 'ADMIN', 'System Administrator', '@ilkom.unazlam'),
  ('260250001', 'HAPPY HELEN ANDINI', '260250001@student.unazlam.ac.id', '081241000101', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@happy.helen'),
  ('260250003', 'STELA GLORI. B', '260250003@student.unazlam.ac.id', '081241000102', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@stelaglori'),
  ('260250004', 'SINAR WAHYUNI', '260250004@student.unazlam.ac.id', '081241000103', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Wakil Ketua', '@sinar.wahyuni'),
  ('260250006', 'ANDI SUCI AMALIA RAMADHANI', '260250006@student.unazlam.ac.id', '081241000104', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@andisuciamalia'),
  ('260250008', 'STEFANI', '260250008@student.unazlam.ac.id', '081241000105', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Sekretaris', '@stefani_comm'),
  ('260250009', 'ARIEF PRAYUDHA RAMADHANSYAH', '260250009@student.unazlam.ac.id', '081241000106', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@arief.prayudha'),
  ('260250011', 'ALIFIA NASYAH RAMADANI', '260250011@student.unazlam.ac.id', '081241000107', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@alifia.nasyah'),
  ('260250014', 'SUSIAN', '260250014@student.unazlam.ac.id', '081241000108', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@susian_ilkom'),
  ('260250015', 'PUTRI SYAFWAH', '260250015@student.unazlam.ac.id', '081241000109', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@putri.syafwah'),
  ('260250017', 'DONI FERNANDO', '260250017@student.unazlam.ac.id', '081241000110', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@doni.fernando'),
  ('260250018', 'CELSI APRILIA', '260250018@student.unazlam.ac.id', '081241000111', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@celsi.aprilia'),
  ('260250019', 'NAZWA TRI AULIA', '260250019@student.unazlam.ac.id', '081241000112', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@nazwatriaulia'),
  ('260250020', 'ALYA NABILAH NA''ILAH', '260250020@student.unazlam.ac.id', '081241000113', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Bendahara', '@alyanabilah'),
  ('260250022', 'VALENTINO', '260250022@student.unazlam.ac.id', '081241000114', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@valentino_comm'),
  ('260250023', 'NUR FARIDA', '260250023@student.unazlam.ac.id', '081241000115', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Ketua Kelas', '@nur.farida'),
  ('260250026', 'WIRDAH RATU SABRINA', '260250026@student.unazlam.ac.id', '081241000116', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@wirdahratusabrina'),
  ('260250027', 'ALFEUS', '260250027@student.unazlam.ac.id', '081241000117', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@alfeus_comm'),
  ('260250030', 'AFRYLIYANA', '260250030@student.unazlam.ac.id', '081241000118', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@afryliyana'),
  ('260250031', 'TASYA', '260250031@student.unazlam.ac.id', '081241000119', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@tasya_ilkom'),
  ('260250034', 'AULIA RAHMA', '260250034@student.unazlam.ac.id', '081241000120', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Bendahara 2', '@aulia.rahma'),
  ('260250035', 'SHOFA AZZAHRA', '260250035@student.unazlam.ac.id', '081241000121', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@shofa.azzahra'),
  ('260250012', 'GILANG RAMADHAN', '260250012@student.unazlam.ac.id', '081241000122', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Koordinator Perlengkapan', '@gilang.ramadhan'),
  ('260250025', 'ALIEF PUTRA RAMADHAN', '260250025@student.unazlam.ac.id', '081241000123', 'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'MAHASISWA', 'Mahasiswa', '@alief.putra')
ON CONFLICT (nim) DO UPDATE SET
  nama = EXCLUDED.nama,
  email = EXCLUDED.email,
  no_wa = EXCLUDED.no_wa,
  prodi = EXCLUDED.prodi,
  semester = EXCLUDED.semester,
  kelas = EXCLUDED.kelas,
  role = EXCLUDED.role,
  jabatan = EXCLUDED.jabatan,
  instagram = EXCLUDED.instagram,
  is_aktif = true;

-- ====================================================================
-- 4. IZIN HAK AKSES & KEBIJAKAN RLS (MENCEGAH ERROR 401 / UNAUTHORIZED)
-- ====================================================================

-- 4a. Akses Jadwal Kuliah (courses)
GRANT SELECT ON TABLE public.courses TO anon, authenticated;
DROP POLICY IF EXISTS courses_anon_read ON public.courses;
CREATE POLICY courses_anon_read ON public.courses FOR SELECT TO anon USING (true);

-- 4b. Akses Direktori Mahasiswa (students & RPC get_class_directory)
GRANT SELECT ON TABLE public.students TO anon, authenticated;
DROP POLICY IF EXISTS students_anon_read ON public.students;
CREATE POLICY students_anon_read ON public.students FOR SELECT TO anon USING (is_aktif = true);

GRANT EXECUTE ON FUNCTION public.get_class_directory() TO anon, authenticated;

-- 4c. Akses Kas/Iuran (treasury_dues)
GRANT SELECT ON TABLE public.treasury_dues TO anon, authenticated;
DROP POLICY IF EXISTS treasury_dues_anon_read ON public.treasury_dues;
CREATE POLICY treasury_dues_anon_read ON public.treasury_dues FOR SELECT TO anon USING (true);

-- 4d. Akses Nilai/Transkrip (student_course_grades jika tabel ada)
DO $$ BEGIN
  IF to_regclass('public.student_course_grades') IS NOT NULL THEN
    GRANT SELECT ON TABLE public.student_course_grades TO anon, authenticated;
    DROP POLICY IF EXISTS student_course_grades_anon_read ON public.student_course_grades;
    CREATE POLICY student_course_grades_anon_read ON public.student_course_grades FOR SELECT TO anon USING (true);
  END IF;
END $$;

COMMIT;
