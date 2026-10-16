import 'dart:convert';

/// Model baris hasil parsing CSV Mahasiswa
class ParsedStudentRow {
  final int index;
  final String nim;
  final String nama;
  final String email;
  final String noWa;
  final String kelas;
  final int semester;
  final String peminatan;
  final String jabatan;
  final bool isValid;
  final List<String> errors;

  ParsedStudentRow({
    required this.index,
    required this.nim,
    required this.nama,
    required this.email,
    required this.noWa,
    required this.kelas,
    required this.semester,
    required this.peminatan,
    required this.jabatan,
    required this.isValid,
    required this.errors,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'nim': nim,
      'nama': nama,
      'email': email,
      'no_wa': noWa,
      'kelas': kelas,
      'semester': semester,
      'peminatan': peminatan,
      'prodi': 'Ilmu Komunikasi',
      'role': 'MAHASISWA',
      'jabatan': jabatan,
      'is_aktif': true,
    };
  }
}

/// Model baris hasil parsing CSV Mata Kuliah / Jadwal
class ParsedCourseRow {
  final int index;
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
  final bool isValid;
  final List<String> errors;

  ParsedCourseRow({
    required this.index,
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
    required this.isValid,
    required this.errors,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'kode_mk': kode,
      'nama_mk': nama,
      'sks': sks,
      'semester': semester,
      'dosen_pengampu': dosen,
      if (dosenWa != null && dosenWa!.isNotEmpty) 'dosen_wa': dosenWa,
      'hari': hari,
      'jam_mulai': jamMulai.length == 5 ? '$jamMulai:00' : jamMulai,
      'jam_selesai': jamSelesai.length == 5 ? '$jamSelesai:00' : jamSelesai,
      'ruangan': ruangan,
      if (linkVirtual != null && linkVirtual!.isNotEmpty) 'link_virtual': linkVirtual,
    };
  }
}

class BulkCsvService {
  /// Template CSV Mahasiswa Siap Pakai Excel
  static String getStudentCsvTemplate() {
    final buffer = StringBuffer();
    buffer.writeln('NIM,Nama,Email,No WA,Kelas,Semester,Peminatan,Jabatan');
    buffer.writeln('240101001,Ahmad Fadhil,ahmad.fadhil@student.unazlam.ac.id,081234567890,Ilmu Komunikasi,1,Public Relations,Mahasiswa');
    buffer.writeln('240101002,Siti Nurhaliza,siti.nurhaliza@student.unazlam.ac.id,081298765432,Ilmu Komunikasi,1,Broadcasting,Sekretaris');
    buffer.writeln('240101003,Budi Santoso,budi.santoso@student.unazlam.ac.id,082155667788,Ilmu Komunikasi,1,Jurnalistik,Mahasiswa');
    buffer.writeln('240101004,Dewi Lestari,dewi.lestari@student.unazlam.ac.id,087711223344,Ilmu Komunikasi,1,Advertising,Bendahara');
    return buffer.toString();
  }

  /// Template CSV Mata Kuliah / Jadwal Siap Pakai Excel
  static String getCourseCsvTemplate() {
    final buffer = StringBuffer();
    buffer.writeln('Kode MK,Nama Mata Kuliah,SKS,Semester,Dosen Pengampu,Dosen WA,Hari,Jam Mulai,Jam Selesai,Ruangan,Link Virtual');
    buffer.writeln('IK-101,Pengantar Ilmu Komunikasi,3,1,Dr. H. Muhammad Zainuddin M.Si,081234567890,Senin,08:00,10:30,Ruang Teori A1,https://meet.google.com/abc-defg-hij');
    buffer.writeln('IK-102,Teori Komunikasi Massa,2,1,Hj. Siti Aminah M.I.Kom,081398765432,Selasa,10:00,11:40,Ruang Lab Multimedia,-');
    buffer.writeln('IK-103,Dasar-Dasar Jurnalistik,2,1,Rahmat Hidayat M.A.,085712345678,Rabu,13:00,14:40,Ruang B2,-');
    buffer.writeln('IK-104,Komunikasi Antarbudaya,2,1,Dewi Kartika M.Sos,087812345678,Kamis,08:00,09:40,Ruang A2,-');
    return buffer.toString();
  }

  /// Parser cerdas yang mendukung pemisah koma (,), titik koma (;), atau tab (\t) dari Excel
  static List<List<String>> parseDelimited(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final lines = const LineSplitter().convert(rawText);
    if (lines.isEmpty) return [];

    // Deteksi pemisah terbaik dari baris pertama yang tidak kosong
    String delimiter = ',';
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final commaCount = ','.allMatches(line).length;
      final semiCount = ';'.allMatches(line).length;
      final tabCount = '\t'.allMatches(line).length;

      if (tabCount > commaCount && tabCount > semiCount) {
        delimiter = '\t';
      } else if (semiCount > commaCount) {
        delimiter = ';';
      } else {
        delimiter = ',';
      }
      break;
    }

    final result = <List<String>>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final row = <String>[];
      final sb = StringBuffer();
      bool inQuotes = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];

        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            sb.write('"');
            i++; // Lewati escaped quote
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == delimiter && !inQuotes) {
          row.add(sb.toString().trim());
          sb.clear();
        } else {
          sb.write(char);
        }
      }
      row.add(sb.toString().trim());
      result.add(row);
    }

    return result;
  }

  /// Normalisasi nama header agar toleran terhadap variasi penulisan admin
  static String _cleanHeader(String h) {
    return h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Parsing dan validasi baris Mahasiswa
  static List<ParsedStudentRow> parseStudents(String csvContent) {
    final table = parseDelimited(csvContent);
    if (table.isEmpty) return [];

    final headerRow = table.first;
    final dataRows = table.skip(1).toList();

    // Petakan indeks kolom
    int idxNim = -1;
    int idxNama = -1;
    int idxEmail = -1;
    int idxWa = -1;
    int idxKelas = -1;
    int idxSemester = -1;
    int idxPeminatan = -1;
    int idxJabatan = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final h = _cleanHeader(headerRow[i]);
      if (idxNim == -1 && (h == 'nim' || h.contains('nomorinduk') || h == 'id' || h.contains('studentid'))) {
        idxNim = i;
      } else if (idxNama == -1 && (h.contains('nama') || h == 'name' || h == 'fullname' || h == 'mahasiswa')) {
        idxNama = i;
      } else if (idxEmail == -1 && (h.contains('email') || h.contains('surel'))) {
        idxEmail = i;
      } else if (idxWa == -1 && (h.contains('wa') || h.contains('telepon') || h.contains('phone') || h.contains('hp'))) {
        idxWa = i;
      } else if (idxKelas == -1 && (h.contains('kelas') || h.contains('class') || h.contains('rombel'))) {
        idxKelas = i;
      } else if (idxSemester == -1 && (h.contains('semester') || h == 'smt')) {
        idxSemester = i;
      } else if (idxPeminatan == -1 && (h.contains('peminatan') || h.contains('konsentrasi') || h.contains('jurusan'))) {
        idxPeminatan = i;
      } else if (idxJabatan == -1 && (h.contains('jabatan') || h.contains('posisi') || h.contains('peran') || h.contains('role'))) {
        idxJabatan = i;
      }
    }

    // Jika header tidak terdeteksi sama sekali, fallback ke posisi default
    if (idxNim == -1 && headerRow.isNotEmpty) idxNim = 0;
    if (idxNama == -1 && headerRow.length > 1) idxNama = 1;

    final parsedRows = <ParsedStudentRow>[];
    final seenNims = <String>{};

    for (int r = 0; r < dataRows.length; r++) {
      final row = dataRows[r];
      if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) continue;

      String getCol(int idx, [String fallback = '']) {
        if (idx >= 0 && idx < row.length) {
          final val = row[idx].trim();
          return val.isNotEmpty ? val : fallback;
        }
        return fallback;
      }

      final nim = getCol(idxNim).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final nama = getCol(idxNama);
      var email = getCol(idxEmail);
      var noWa = getCol(idxWa);
      final kelas = getCol(idxKelas, 'Ilmu Komunikasi');
      final smtStr = getCol(idxSemester, '1');
      final peminatan = getCol(idxPeminatan);
      final jabatan = getCol(idxJabatan, 'Mahasiswa');

      final errors = <String>[];

      if (nim.isEmpty) {
        errors.add('NIM wajib diisi.');
      } else if (seenNims.contains(nim)) {
        errors.add('Duplikasi NIM di dalam file.');
      } else {
        seenNims.add(nim);
      }

      if (nama.isEmpty) {
        errors.add('Nama mahasiswa wajib diisi.');
      }

      // Autogenerate email jika kosong
      if (email.isEmpty && nim.isNotEmpty) {
        email = '${nim.toLowerCase()}@student.unazlam.ac.id';
      } else if (email.isNotEmpty && !email.contains('@')) {
        errors.add('Format email tidak valid.');
      }

      // Bersihkan no WA
      noWa = noWa.replaceAll(RegExp(r'[^0-9+]'), '');
      if (noWa.startsWith('62')) {
        noWa = '0${noWa.substring(2)}';
      } else if (noWa.startsWith('+62')) {
        noWa = '0${noWa.substring(3)}';
      }

      int semester = int.tryParse(smtStr) ?? 1;
      if (semester < 1 || semester > 14) semester = 1;

      parsedRows.add(
        ParsedStudentRow(
          index: r + 1,
          nim: nim,
          nama: nama,
          email: email,
          noWa: noWa,
          kelas: kelas,
          semester: semester,
          peminatan: peminatan,
          jabatan: jabatan,
          isValid: errors.isEmpty,
          errors: errors,
        ),
      );
    }

    return parsedRows;
  }

  /// Parsing dan validasi baris Mata Kuliah / Jadwal
  static List<ParsedCourseRow> parseCourses(String csvContent) {
    final table = parseDelimited(csvContent);
    if (table.isEmpty) return [];

    final headerRow = table.first;
    final dataRows = table.skip(1).toList();

    int idxKode = -1;
    int idxNama = -1;
    int idxSks = -1;
    int idxSemester = -1;
    int idxDosen = -1;
    int idxDosenWa = -1;
    int idxHari = -1;
    int idxJamMulai = -1;
    int idxJamSelesai = -1;
    int idxRuangan = -1;
    int idxLink = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final h = _cleanHeader(headerRow[i]);
      if (idxKode == -1 && (h.contains('kodemk') || h == 'kode' || h.contains('kodematkul') || h.contains('coursecode'))) {
        idxKode = i;
      } else if (idxNama == -1 && (h.contains('namamk') || h.contains('matakuliah') || h == 'nama' || h.contains('coursename'))) {
        idxNama = i;
      } else if (idxSks == -1 && (h == 'sks' || h.contains('kredit') || h.contains('credit'))) {
        idxSks = i;
      } else if (idxSemester == -1 && (h.contains('semester') || h == 'smt')) {
        idxSemester = i;
      } else if (idxDosen == -1 && (h.contains('dosen') && !h.contains('wa')) || h.contains('pengajar') || h.contains('lecturer')) {
        idxDosen = i;
      } else if (idxDosenWa == -1 && (h.contains('dosenwa') || h.contains('wadosen') || h.contains('nowadosen'))) {
        idxDosenWa = i;
      } else if (idxHari == -1 && (h.contains('hari') || h == 'day')) {
        idxHari = i;
      } else if (idxJamMulai == -1 && (h.contains('jammulai') || h.contains('mulai') || h.contains('start'))) {
        idxJamMulai = i;
      } else if (idxJamSelesai == -1 && (h.contains('jamselesai') || h.contains('selesai') || h.contains('end'))) {
        idxJamSelesai = i;
      } else if (idxRuangan == -1 && (h.contains('ruang') || h.contains('ruangan') || h.contains('room') || h.contains('lokasi'))) {
        idxRuangan = i;
      } else if (idxLink == -1 && (h.contains('link') || h.contains('virtual') || h.contains('zoom') || h.contains('meet'))) {
        idxLink = i;
      }
    }

    if (idxKode == -1 && headerRow.isNotEmpty) idxKode = 0;
    if (idxNama == -1 && headerRow.length > 1) idxNama = 1;

    final parsedRows = <ParsedCourseRow>[];
    final seenCodes = <String>{};

    for (int r = 0; r < dataRows.length; r++) {
      final row = dataRows[r];
      if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) continue;

      String getCol(int idx, [String fallback = '']) {
        if (idx >= 0 && idx < row.length) {
          final val = row[idx].trim();
          return val.isNotEmpty ? val : fallback;
        }
        return fallback;
      }

      final kode = getCol(idxKode).toUpperCase();
      final nama = getCol(idxNama);
      final sksStr = getCol(idxSks, '2');
      final smtStr = getCol(idxSemester, '1');
      final dosen = getCol(idxDosen, 'Dosen Pengampu');
      var dosenWa = getCol(idxDosenWa);
      var hari = getCol(idxHari, 'Senin');
      var jamMulai = getCol(idxJamMulai, '08:00');
      var jamSelesai = getCol(idxJamSelesai, '09:40');
      final ruangan = getCol(idxRuangan, 'Ruang A2');
      final linkVirtual = getCol(idxLink);

      final errors = <String>[];

      if (kode.isEmpty) {
        errors.add('Kode MK wajib diisi.');
      } else if (seenCodes.contains(kode)) {
        errors.add('Duplikasi Kode MK di dalam file.');
      } else {
        seenCodes.add(kode);
      }

      if (nama.isEmpty) {
        errors.add('Nama mata kuliah wajib diisi.');
      }

      int sks = int.tryParse(sksStr) ?? 2;
      if (sks < 1 || sks > 8) sks = 2;

      int semester = int.tryParse(smtStr) ?? 1;
      if (semester < 1 || semester > 8) semester = 1;

      // Format hari
      final dayLower = hari.toLowerCase();
      if (dayLower.startsWith('sen')) {
        hari = 'Senin';
      } else if (dayLower.startsWith('sel')) {
        hari = 'Selasa';
      } else if (dayLower.startsWith('rab')) {
        hari = 'Rabu';
      } else if (dayLower.startsWith('kam')) {
        hari = 'Kamis';
      } else if (dayLower.startsWith('jum')) {
        hari = 'Jumat';
      } else if (dayLower.startsWith('sab')) {
        hari = 'Sabtu';
      } else if (dayLower.startsWith('min')) {
        hari = 'Minggu';
      } else {
        hari = 'Senin';
      }

      // Normalisasi jam format HH:mm
      String fixTime(String t, String defaultT) {
        t = t.replaceAll('.', ':').trim();
        final parts = t.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 8;
          final m = int.tryParse(parts[1]) ?? 0;
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        }
        return defaultT;
      }

      jamMulai = fixTime(jamMulai, '08:00');
      jamSelesai = fixTime(jamSelesai, '09:40');

      if (dosenWa.isNotEmpty) {
        dosenWa = dosenWa.replaceAll(RegExp(r'[^0-9+]'), '');
        if (dosenWa.startsWith('62')) {
          dosenWa = '0${dosenWa.substring(2)}';
        } else if (dosenWa.startsWith('+62')) {
          dosenWa = '0${dosenWa.substring(3)}';
        }
      }

      parsedRows.add(
        ParsedCourseRow(
          index: r + 1,
          kode: kode,
          nama: nama,
          sks: sks,
          semester: semester,
          dosen: dosen,
          dosenWa: dosenWa.isNotEmpty ? dosenWa : null,
          hari: hari,
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          ruangan: ruangan,
          linkVirtual: linkVirtual.isNotEmpty && linkVirtual != '-' ? linkVirtual : null,
          isValid: errors.isEmpty,
          errors: errors,
        ),
      );
    }

    return parsedRows;
  }
}
