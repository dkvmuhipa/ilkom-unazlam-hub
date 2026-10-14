class Course {
  final String id;
  final String kode;
  final String nama;
  final int sks;
  final int semester;
  final String dosen;
  final String? dosenWa;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String ruangan;
  final String? linkVirtual;

  Course({
    required this.id,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.semester,
    required this.dosen,
    this.dosenWa,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    this.linkVirtual,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    String jamM = map['jam_mulai']?.toString() ?? '00:00';
    if (jamM.length >= 5) jamM = jamM.substring(0, 5);
    String jamS = map['jam_selesai']?.toString() ?? '00:00';
    if (jamS.length >= 5) jamS = jamS.substring(0, 5);

    return Course(
      id: map['id']?.toString() ?? '',
      kode: map['kode_mk']?.toString() ?? '',
      nama: map['nama_mk']?.toString() ?? '',
      sks: (map['sks'] as num?)?.toInt() ?? 2,
      semester: (map['semester'] as num?)?.toInt() ?? 1,
      dosen: map['dosen_pengampu']?.toString() ?? '-',
      dosenWa: map['dosen_wa']?.toString(),
      hari: map['hari']?.toString() ?? 'Senin',
      jamMulai: jamM,
      jamSelesai: jamS,
      ruangan: map['ruangan']?.toString() ?? '-',
      linkVirtual: map['link_virtual']?.toString(),
    );
  }
}

class Assignment {
  final String id;
  String courseId;
  String courseName;
  String judul;
  String deskripsi;
  String kategori; // 'Individu', 'Proyek Praktikum', 'UTS', 'UAS'
  DateTime deadline;
  String? linkPengumpulan;
  String status; // 'belum', 'sedang_dikerjakan', 'selesai'

  Assignment({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.deadline,
    this.linkPengumpulan,
    this.status = 'belum',
  });
}

class Announcement {
  final String id;
  String authorName;
  String authorRole; // 'Komti', 'Dosen', 'Sekretaris'
  String judul;
  String isi;
  bool isPinned;
  String kategori; // 'Jadwal Kuliah', 'Tugas', 'Info Fakultas', 'Penting'
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.judul,
    required this.isi,
    this.isPinned = false,
    required this.kategori,
    required this.createdAt,
  });
}

class GroupMember {
  final String nama;
  final String nim;
  final String peran; // 'Produser / Ketua', 'Editor Video', 'Scriptwriter', 'Presenter'
  final String peminatan;

  GroupMember({
    required this.nama,
    required this.nim,
    required this.peran,
    this.peminatan = '',
  });
}

class ProjectGroup {
  final String id;
  final String namaKelompok;
  final String assignmentTitle;
  final String courseName;
  final String? linkGDrive;
  final List<GroupMember> members;

  ProjectGroup({
    required this.id,
    required this.namaKelompok,
    required this.assignmentTitle,
    required this.courseName,
    this.linkGDrive,
    required this.members,
  });
}

class CourseAttendance {
  final String courseId;
  final String courseName;
  final int totalSesi; // biasanya 16
  final int sesiBerjalan;
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;

  CourseAttendance({
    required this.courseId,
    required this.courseName,
    this.totalSesi = 16,
    required this.sesiBerjalan,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
  });

  double get persentase => sesiBerjalan == 0 ? 100.0 : (hadir / sesiBerjalan) * 100;
  
  // Mahasiswa butuh minimal 75% dari 16 pertemuan = minimal 12 hadir, max 4 alpa
  int get sisaAlpaAman {
    final maxAlpaAllowed = (totalSesi * 0.25).floor(); // 4 kali
    return (maxAlpaAllowed - alpa).clamp(0, 4);
  }

  bool get isDangerZone => sisaAlpaAman <= 1;
}

class StudentCourseGrade {
  final String id;
  final String studentNim;
  final String courseId;
  final String courseCode;
  final String courseName;
  final int sks;
  final int semester;
  final String academicYear;
  final double? numericScore;
  final String letterGrade;
  final DateTime updatedAt;

  const StudentCourseGrade({
    required this.id,
    required this.studentNim,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.sks,
    required this.semester,
    required this.academicYear,
    required this.numericScore,
    required this.letterGrade,
    required this.updatedAt,
  });

  factory StudentCourseGrade.fromMap(Map<String, dynamic> map) {
    return StudentCourseGrade(
      id: map['id']?.toString() ?? '',
      studentNim: map['student_nim']?.toString() ?? '',
      courseId: map['course_id']?.toString() ?? '',
      courseCode: map['course_code']?.toString() ?? '',
      courseName: map['course_name']?.toString() ?? 'Mata Kuliah',
      sks: (map['sks'] as num?)?.toInt() ?? 0,
      semester: (map['semester'] as num?)?.toInt() ?? 1,
      academicYear: map['academic_year']?.toString() ?? '',
      numericScore: (map['nilai_angka'] as num?)?.toDouble(),
      letterGrade: map['nilai_huruf']?.toString() ?? '-',
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ResourceItem {
  final String id;
  final String courseName;
  final int? pertemuanKe;
  final String judul;
  final String jenis; // 'Slide PPT', 'Jurnal Ilmiah', 'E-Book', 'Bank Soal', 'Video'
  final String linkUrl;

  ResourceItem({
    required this.id,
    required this.courseName,
    this.pertemuanKe,
    required this.judul,
    required this.jenis,
    required this.linkUrl,
  });
}

class StudentProfile {
  final String id;
  final String nim;
  String nama;
  String email;
  String noWa;
  String peminatan; // 'Public Relations', 'Jurnalistik', 'Advertising', 'Broadcasting'
  final String prodi; // 'Ilmu Komunikasi'
  final int semester; // 1
  final String kelas; // 'Ilmu Komunikasi'
  final String role; // 'ADMIN' atau 'MAHASISWA'
  String jabatan; // 'Mahasiswa', 'Ketua Kelas', 'Bendahara', 'Sekretaris', 'Wakil Ketua'
  bool isAktif;
  String? instagram;
  String? linkedin;
  String? avatarUrl;
  String? bio;

  StudentProfile({
    required this.id,
    required this.nim,
    required this.nama,
    required this.email,
    required this.noWa,
    this.peminatan = '',
    this.prodi = 'Ilmu Komunikasi',
    this.semester = 1,
    this.kelas = 'Ilmu Komunikasi',
    this.role = 'MAHASISWA',
    this.jabatan = 'Mahasiswa',
    this.isAktif = true,
    this.instagram,
    this.linkedin,
    this.avatarUrl,
    this.bio,
  });

  StudentProfile copyWith({
    String? id,
    String? nim,
    String? nama,
    String? email,
    String? noWa,
    String? peminatan,
    String? prodi,
    int? semester,
    String? kelas,
    String? role,
    String? jabatan,
    bool? isAktif,
    String? instagram,
    String? linkedin,
    String? avatarUrl,
    String? bio,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noWa: noWa ?? this.noWa,
      peminatan: peminatan ?? this.peminatan,
      prodi: prodi ?? this.prodi,
      semester: semester ?? this.semester,
      kelas: kelas ?? this.kelas,
      role: role ?? this.role,
      jabatan: jabatan ?? this.jabatan,
      isAktif: isAktif ?? this.isAktif,
      instagram: instagram ?? this.instagram,
      linkedin: linkedin ?? this.linkedin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  // Role Checks
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isMahasiswa => role.toUpperCase() == 'MAHASISWA';

  // Jabatan Checks
  bool get isKetuaKelas => jabatan == 'Ketua Kelas';
  bool get isBendahara => jabatan == 'Bendahara';
  bool get isSekretaris => jabatan == 'Sekretaris';
  bool get isWakilKetua => jabatan == 'Wakil Ketua';

  // Permission Checks (Attribute-Based Access Control)
  bool get canManageAttendance => isAdmin || isKetuaKelas;
  bool get canPostAnnouncement => isAdmin || isKetuaKelas || isSekretaris;
  bool get canManageAgenda => isAdmin || isKetuaKelas || isSekretaris;
  bool get canManageTreasury => isAdmin || isBendahara;
  bool get canManageAssignments => isAdmin || isKetuaKelas;
  bool get canManageSystemData => isAdmin;
}

class TreasuryTransaction {
  final String id;
  final String judul;
  final int nominal;
  final bool isPemasukan;
  final String kategori; // 'Kas Bulanan', 'Fotokopi Modul', 'Sewa Studio', 'Kado Dosen'
  final DateTime tanggal;
  final String pencatat;

  TreasuryTransaction({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.isPemasukan,
    required this.kategori,
    required this.tanggal,
    required this.pencatat,
  });

  TreasuryTransaction copyWith({
    String? id,
    String? judul,
    int? nominal,
    bool? isPemasukan,
    String? kategori,
    DateTime? tanggal,
    String? pencatat,
  }) {
    return TreasuryTransaction(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      nominal: nominal ?? this.nominal,
      isPemasukan: isPemasukan ?? this.isPemasukan,
      kategori: kategori ?? this.kategori,
      tanggal: tanggal ?? this.tanggal,
      pencatat: pencatat ?? this.pencatat,
    );
  }
}

class StudioEquipment {
  final String id;
  final String namaAlat;
  final String kategori; // 'Kamera & Lensa', 'Audio & Mic', 'Lighting', 'Studio Room'
  final bool isTersedia;
  final String? peminjam;
  final String? estimasiKembali;
  final String lokasi;

  StudioEquipment({
    required this.id,
    required this.namaAlat,
    required this.kategori,
    required this.isTersedia,
    this.peminjam,
    this.estimasiKembali,
    required this.lokasi,
  });
}

class PermissionLetter {
  final String id;
  final String studentNim;
  final String studentName;
  final String letterType;
  final String dosenName;
  final String courseName;
  final String reason;
  final String letterDate;
  final String fullContent;
  final DateTime createdAt;

  PermissionLetter({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.letterType,
    required this.dosenName,
    required this.courseName,
    required this.reason,
    required this.letterDate,
    required this.fullContent,
    required this.createdAt,
  });

  factory PermissionLetter.fromMap(Map<String, dynamic> map) {
    return PermissionLetter(
      id: map['id']?.toString() ?? '',
      studentNim: map['student_nim']?.toString() ?? '',
      studentName: map['student_name']?.toString() ?? '',
      letterType: map['letter_type']?.toString() ?? 'Izin Sakit',
      dosenName: map['dosen_name']?.toString() ?? '',
      courseName: map['course_name']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      letterDate: map['letter_date']?.toString() ?? '',
      fullContent: map['full_content']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_nim': studentNim,
      'student_name': studentName,
      'letter_type': letterType,
      'dosen_name': dosenName,
      'course_name': courseName,
      'reason': reason,
      'letter_date': letterDate,
      'full_content': fullContent,
    };
  }
}

class PollOption {
  final String id;
  final String text;
  int votes;
  final List<String> votersNim;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    List<String>? votersNim,
  }) : votersNim = votersNim ?? [];

  factory PollOption.fromMap(Map<String, dynamic> map, {int votesCount = 0, List<String>? voters}) {
    return PollOption(
      id: map['id']?.toString() ?? '',
      text: map['option_text']?.toString() ?? '',
      votes: votesCount,
      votersNim: voters ?? [],
    );
  }
}

class ClassPoll {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime createdAt;
  final DateTime endsAt;
  bool isOpen;
  final List<PollOption> options;
  String? userVotedId;

  ClassPoll({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.createdAt,
    required this.endsAt,
    this.isOpen = true,
    required this.options,
    this.userVotedId,
  });

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.votes);

  factory ClassPoll.fromMap(Map<String, dynamic> map, List<PollOption> options, {String? userVotedId}) {
    return ClassPoll(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      author: map['author']?.toString() ?? 'Komti',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endsAt: map['ends_at'] != null
          ? DateTime.tryParse(map['ends_at'].toString()) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      isOpen: map['is_open'] == true,
      options: options,
      userVotedId: userVotedId,
    );
  }
}

