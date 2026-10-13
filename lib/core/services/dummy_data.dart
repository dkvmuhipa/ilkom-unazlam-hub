/// ====================================================================
/// MASTER DATA RESMI FISIP UNAZLAM
/// ====================================================================
/// File ini menyimpan Data Real Mahasiswa dan Jadwal Kuliah resmi
/// Program Studi Ilmu Komunikasi Universitas Nahdlatul Ulama.
/// Bukan data dummy / testing.
/// ====================================================================
library;

import '../../models/models.dart';

class MasterData {
  /// Data Real Jadwal Perkuliahan Resmi Semester 1
  static final List<Course> courses = [
    Course(
      id: 'c1',
      kode: '2 PK 100',
      nama: 'Pendidikan Pancasila',
      sks: 2,
      semester: 1,
      dosen: 'Drs. H. M. Rusli, M.Si',
      dosenWa: '081234567890',
      hari: 'Senin',
      jamMulai: '15:30',
      jamSelesai: '17:00',
      ruangan: 'Ruang A2',
    ),
    Course(
      id: 'c2',
      kode: '2 PK 103',
      nama: 'Pendidikan Kewarganegaraan',
      sks: 2,
      semester: 1,
      dosen: 'Dra. Hj. Nurhaida, M.Pd',
      dosenWa: '081234567891',
      hari: 'Senin',
      jamMulai: '18:30',
      jamSelesai: '20:00',
      ruangan: 'Ruang B1',
    ),
    Course(
      id: 'c3',
      kode: '3 PK 101A',
      nama: 'Pendidikan Agama Islam *',
      sks: 3,
      semester: 1,
      dosen: 'Dr. H. Lukman Hakim, M.Ag',
      dosenWa: '081234567892',
      hari: 'Selasa',
      jamMulai: '15:30',
      jamSelesai: '17:45',
      ruangan: 'Ruang A1',
    ),
    Course(
      id: 'c4',
      kode: '3 PK 101B',
      nama: 'Pendidikan Agama Kristen *',
      sks: 3,
      semester: 1,
      dosen: 'Pdt. Dr. Markus Somba, M.Th',
      dosenWa: '081234567893',
      hari: 'Selasa',
      jamMulai: '15:30',
      jamSelesai: '17:45',
      ruangan: 'Ruang B1',
    ),
    Course(
      id: 'c5',
      kode: '2 PK 106',
      nama: 'Ilmu Kealaman Dasar *',
      sks: 2,
      semester: 1,
      dosen: 'Dr. Ir. Hendra Gunawan, M.Si',
      dosenWa: '081234567894',
      hari: 'Selasa',
      jamMulai: '18:30',
      jamSelesai: '20:45',
      ruangan: 'Ruang A2',
    ),
    Course(
      id: 'c6',
      kode: '3 PK 105',
      nama: 'Bahasa Indonesia *',
      sks: 3,
      semester: 1,
      dosen: 'Dra. Hj. Nurhayati, M.Hum',
      dosenWa: '081234567895',
      hari: 'Rabu',
      jamMulai: '15:30',
      jamSelesai: '17:45',
      ruangan: 'Ruang A2',
    ),
    Course(
      id: 'c7',
      kode: '3 PK 104',
      nama: 'Bahasa Inggris *',
      sks: 3,
      semester: 1,
      dosen: 'Farid Wajdi, S.Pd., M.A',
      dosenWa: '081234567896',
      hari: 'Kamis',
      jamMulai: '18:30',
      jamSelesai: '20:45',
      ruangan: 'Ruang A1',
    ),
    Course(
      id: 'c8',
      kode: '3 PK 201',
      nama: 'Pengantar Ilmu Politik *',
      sks: 3,
      semester: 1,
      dosen: 'Dr. Muhammad Rizal, S.IP., M.Si',
      dosenWa: '081234567897',
      hari: 'Jumat',
      jamMulai: '18:30',
      jamSelesai: '20:45',
      ruangan: 'Ruang B1',
    ),
  ];

  static final List<Assignment> assignments = [];

  static final List<Announcement> announcements = [];

  static final List<ProjectGroup> projectGroups = [];

  static final List<CourseAttendance> attendanceRecords = [];

  static final List<ResourceItem> resources = [];

  static final List<StudentProfile> students = [
    StudentProfile(
      id: '16110376',
      nim: '16110376',
      nama: 'ADMINISTRATOR SISTEM',
      email: 'gellonaindonesia@gmail.com',
      noWa: '081234567890',
      role: 'ADMIN',
      jabatan: 'System Administrator',
      prodi: 'Ilmu Komunikasi',
      semester: 1,
      kelas: 'Fakultas FISIP UNAZLAM',
      instagram: '@ilkom.unazlam',
    ),
    StudentProfile(
      id: 'adm1',
      nim: 'admin',
      nama: 'ADMINISTRATOR SISTEM',
      email: 'gellonaindonesia@gmail.com',
      noWa: '081234567890',
      role: 'ADMIN',
      jabatan: 'System Administrator',
      prodi: 'Ilmu Komunikasi',
      semester: 1,
      kelas: 'Fakultas FISIP UNAZLAM',
      instagram: '@ilkom.unazlam',
    ),
    StudentProfile(
      id: 's1',
      nim: '260250001',
      nama: 'HAPPY HELEN ANDINI',
      email: '',
      noWa: '081241000101',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@happy.helen',
    ),
    StudentProfile(
      id: 's2',
      nim: '260250003',
      nama: 'STELA GLORI. B',
      email: '',
      noWa: '081241000102',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@stelaglori',
    ),
    StudentProfile(
      id: 's3',
      nim: '260250004',
      nama: 'SINAR WAHYUNI',
      email: '',
      noWa: '081241000103',
      role: 'MAHASISWA',
      jabatan: 'Wakil Ketua',
      instagram: '@sinar.wahyuni',
    ),
    StudentProfile(
      id: 's4',
      nim: '260250006',
      nama: 'ANDI SUCI AMALIA RAMADHANI',
      email: '',
      noWa: '081241000104',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@andisuciamalia',
    ),
    StudentProfile(
      id: 's5',
      nim: '260250008',
      nama: 'STEFANI',
      email: '',
      noWa: '081241000105',
      role: 'MAHASISWA',
      jabatan: 'Sekretaris',
      instagram: '@stefani_comm',
    ),
    StudentProfile(
      id: 's6',
      nim: '260250009',
      nama: 'ARIEF PRAYUDHA RAMADHANSYAH',
      email: '',
      noWa: '081241000106',
      role: 'mahasiswa',
      instagram: '@arief.prayudha',
    ),
    StudentProfile(
      id: 's7',
      nim: '260250011',
      nama: 'ALIFIA NASYAH RAMADANI',
      email: '',
      noWa: '081241000107',
      role: 'mahasiswa',
      instagram: '@alifia.nasyah',
    ),
    StudentProfile(
      id: 's8',
      nim: '260250014',
      nama: 'SUSIAN',
      email: '',
      noWa: '081241000108',
      role: 'mahasiswa',
      instagram: '@susian_ilkom',
    ),
    StudentProfile(
      id: 's9',
      nim: '260250015',
      nama: 'PUTRI SYAFWAH',
      email: '',
      noWa: '081241000109',
      role: 'mahasiswa',
      instagram: '@putri.syafwah',
    ),
    StudentProfile(
      id: 's10',
      nim: '260250017',
      nama: 'DONI FERNANDO',
      email: '',
      noWa: '081241000110',
      role: 'mahasiswa',
      instagram: '@doni.fernando',
    ),
    StudentProfile(
      id: 's11',
      nim: '260250018',
      nama: 'CELSI APRILIA',
      email: '',
      noWa: '081241000111',
      role: 'mahasiswa',
      instagram: '@celsi.aprilia',
    ),
    StudentProfile(
      id: 's12',
      nim: '260250019',
      nama: 'NAZWA TRI AULIA',
      email: '',
      noWa: '081241000112',
      role: 'mahasiswa',
      instagram: '@nazwatriaulia',
    ),
    StudentProfile(
      id: 's13',
      nim: '260250020',
      nama: "ALYA NABILAH NA'ILAH",
      email: '',
      noWa: '081241000113',
      role: 'MAHASISWA',
      jabatan: 'Bendahara',
      instagram: '@alyanabilah',
    ),
    StudentProfile(
      id: 's14',
      nim: '260250022',
      nama: 'VALENTINO',
      email: '',
      noWa: '081241000114',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@valentino_comm',
    ),
    StudentProfile(
      id: 's15',
      nim: '260250023',
      nama: 'NUR FARIDA',
      email: '',
      noWa: '081241000115',
      role: 'MAHASISWA',
      jabatan: 'Ketua Kelas',
      instagram: '@nur.farida',
    ),
    StudentProfile(
      id: 's16',
      nim: '260250026',
      nama: 'WIRDAH RATU SABRINA',
      email: '',
      noWa: '081241000116',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@wirdahratusabrina',
    ),
    StudentProfile(
      id: 's17',
      nim: '260250027',
      nama: 'ALFEUS',
      email: '',
      noWa: '081241000117',
      role: 'mahasiswa',
      instagram: '@alfeus_comm',
    ),
    StudentProfile(
      id: 's18',
      nim: '260250030',
      nama: 'AFRYLIYANA',
      email: '',
      noWa: '081241000118',
      role: 'mahasiswa',
      instagram: '@afryliyana',
    ),
    StudentProfile(
      id: 's19',
      nim: '260250031',
      nama: 'TASYA',
      email: '',
      noWa: '081241000119',
      role: 'mahasiswa',
      instagram: '@tasya_ilkom',
    ),
    StudentProfile(
      id: 's20',
      nim: '260250034',
      nama: 'AULIA RAHMA',
      email: '',
      noWa: '081241000120',
      role: 'MAHASISWA',
      jabatan: 'Bendahara 2',
      instagram: '@aulia.rahma',
    ),
    StudentProfile(
      id: 's21',
      nim: '260250035',
      nama: 'SHOFA AZZAHRA',
      email: '',
      noWa: '081241000121',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@shofa.azzahra',
    ),
    StudentProfile(
      id: 's22',
      nim: '260250012',
      nama: 'GILANG RAMADHAN',
      email: '',
      noWa: '081241000122',
      role: 'MAHASISWA',
      jabatan: 'Koordinator Perlengkapan',
      instagram: '@gilang.ramadhan',
    ),
    StudentProfile(
      id: 's23',
      nim: '260250025',
      nama: 'ALIEF PUTRA RAMADHAN',
      email: '',
      noWa: '081241000123',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
      instagram: '@alief.putra',
    ),
  ];

  static final List<TreasuryTransaction> treasuryTransactions = [];

  static int get totalKasPemasukan {
    return treasuryTransactions.where((item) => item.isPemasukan).fold(0, (acc, item) => acc + item.nominal);
  }

  static int get totalKasPengeluaran {
    return treasuryTransactions.where((item) => !item.isPemasukan).fold(0, (acc, item) => acc + item.nominal);
  }

  static int get totalKasSaldo {
    return treasuryTransactions.fold(0, (acc, item) {
      return item.isPemasukan ? acc + item.nominal : acc - item.nominal;
    });
  }

  static final List<StudioEquipment> studioEquipments = [];

  static final List<PermissionLetter> permissionLetters = [];
  static final List<ClassPoll> classPolls = [];
}


/// Alias kompatibilitas
typedef DummyData = MasterData;
