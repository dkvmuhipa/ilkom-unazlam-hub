class ClassItem {
  static const List<String> availableProdis = [
    'Ilmu Komunikasi',
    'Ilmu Pemerintahan',
    'Hubungan Internasional',
  ];

  final String? id;
  final String nama;
  final String prodi;
  final int semester;
  final int jumlahMahasiswa;
  final String academicYear;
  final int kapasitas;

  ClassItem({
    this.id,
    required this.nama,
    this.prodi = 'Ilmu Komunikasi',
    required this.semester,
    required this.jumlahMahasiswa,
    this.academicYear = '2026/2027',
    this.kapasitas = 30,
  });

  factory ClassItem.fromMap(Map<String, dynamic> map) => ClassItem(
        id: map['id']?.toString(),
        nama: map['nama']?.toString() ?? '',
        prodi: map['prodi']?.toString() ?? 'Ilmu Komunikasi',
        semester: (map['semester'] as num?)?.toInt() ?? 1,
        jumlahMahasiswa: 0,
        academicYear: map['academic_year']?.toString() ?? '',
        kapasitas: (map['kapasitas'] as num?)?.toInt() ?? 30,
      );
}

class AcademicYearItem {
  final String? id;
  final String tahun;
  bool isAktif;

  AcademicYearItem({this.id, required this.tahun, required this.isAktif});

  factory AcademicYearItem.fromMap(Map<String, dynamic> map) => AcademicYearItem(
        id: map['id']?.toString(),
        tahun: map['tahun']?.toString() ?? '',
        isAktif: map['is_aktif'] == true,
      );
}

class LecturerItem {
  final String id;
  final String nama;
  final String mataKuliah;
  final String email;

  LecturerItem({
    required this.id,
    required this.nama,
    required this.mataKuliah,
    required this.email,
  });

  factory LecturerItem.fromMap(Map<String, dynamic> map) => LecturerItem(
        id: map['id']?.toString() ?? '',
        nama: map['nama']?.toString() ?? '',
        mataKuliah: map['mata_kuliah']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
      );
}
