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
  final String courseId;
  final String courseName;
  final String judul;
  final String deskripsi;
  final String kategori; // 'Individu', 'Proyek Praktikum', 'UTS', 'UAS'
  final DateTime deadline;
  final String? linkPengumpulan;
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
  final String authorName;
  final String authorRole; // 'Komti', 'Dosen', 'Sekretaris'
  final String judul;
  final String isi;
  final bool isPinned;
  final String kategori; // 'Jadwal Kuliah', 'Tugas', 'Info Fakultas', 'Penting'
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
    required this.peminatan,
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
  final String nama;
  final String email;
  final String noWa;
  final String peminatan; // 'Public Relations', 'Jurnalistik', 'Advertising', 'Broadcasting'
  final String role; // 'komti', 'mahasiswa'
  final String? instagram;
  final String? linkedin;

  StudentProfile({
    required this.id,
    required this.nim,
    required this.nama,
    required this.email,
    required this.noWa,
    required this.peminatan,
    this.role = 'mahasiswa',
    this.instagram,
    this.linkedin,
  });
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
