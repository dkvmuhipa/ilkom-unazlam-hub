import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart';
import '../../models/models.dart';
import 'academic_grade_service.dart';

enum FileExportResult { downloaded, shared, dismissed, unavailable }

class ExportService {
  /// Downloads a file in a browser or opens the native share/save sheet.
  static Future<FileExportResult> exportFile(
    String fileName,
    String content,
  ) async {
    if (kIsWeb) {
      return downloadFilePlatform(fileName, content)
          ? FileExportResult.downloaded
          : FileExportResult.unavailable;
    }
    try {
      final mimeType = switch (fileName.split('.').last.toLowerCase()) {
        'csv' => 'text/csv',
        'json' => 'application/json',
        'ics' => 'text/calendar',
        'html' => 'text/html',
        'pdf' => 'application/pdf',
        _ => 'text/plain',
      };
      final result = await SharePlus.instance.share(
        ShareParams(
          title: fileName,
          files: [XFile.fromData(utf8.encode(content), mimeType: mimeType)],
          fileNameOverrides: [fileName],
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => FileExportResult.shared,
        ShareResultStatus.dismissed => FileExportResult.dismissed,
        ShareResultStatus.unavailable => FileExportResult.unavailable,
      };
    } catch (error) {
      debugPrint('ExportService: Gagal membagikan $fileName: $error');
      return FileExportResult.unavailable;
    }
  }

  /// Opens a printable HTML document in a new browser tab and starts print.
  static bool printHtml(String html) {
    if (kIsWeb) return printHtmlPlatform(html);
    return false;
  }

  /// Export Rekap Kas Kelas to CSV Format
  static String exportTreasuryCsv({
    required List<TreasuryTransaction> transactions,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Judul Transaksi,Kategori,Tipe,Nominal,Tanggal,Pencatat');

    for (var tx in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.tanggal);
      final type = tx.isPemasukan ? 'Pemasukan' : 'Pengeluaran';
      buffer.writeln(
        '"${tx.id}","${tx.judul}","${tx.kategori}","$type",${tx.nominal},"$dateStr","${tx.pencatat}"',
      );
    }

    return buffer.toString();
  }

  /// Export Rekap Presensi Mahasiswa to CSV Format (Khusus Pengurus / Admin)
  static String exportAttendanceCsv({
    required String courseName,
    List<Map<String, dynamic>> logs = const [],
    List<StudentProfile> students = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'No,NIM,Nama Mahasiswa,Program Studi,Status Kehadiran,Mata Kuliah,Waktu Catat',
    );

    final activeStudents = students.where((s) => s.role != 'ADMIN').toList();
    if (logs.isNotEmpty) {
      for (int i = 0; i < logs.length; i++) {
        final log = logs[i];
        final nim = (log['student_nim'] ?? '').toString();
        final status = (log['status'] ?? 'Hadir').toString();
        final time = (log['created_at'] ?? '-').toString();
        final student = activeStudents.firstWhere(
          (s) => s.nim == nim,
          orElse: () => StudentProfile(
            id: '',
            nim: nim,
            nama: 'Mahasiswa $nim',
            email: '',
            noWa: '',
          ),
        );
        final courseFromLog = (log['courses'] is Map ? log['courses']['nama_mk'] : null)?.toString();
        final effectiveCourse = (courseFromLog != null && courseFromLog.isNotEmpty) ? courseFromLog : courseName;
        buffer.writeln(
          '${i + 1},"$nim","${student.nama}","${student.prodi}","$status","$effectiveCourse","$time"',
        );
      }
    } else if (activeStudents.isNotEmpty) {
      for (int i = 0; i < activeStudents.length; i++) {
        final s = activeStudents[i];
        buffer.writeln(
          '${i + 1},"${s.nim}","${s.nama}","${s.prodi}","Belum ada catatan","$courseName","-"',
        );
      }
    } else {
      buffer.writeln('1,-,Belum ada data presensi,-,-,"$courseName",-');
    }

    return buffer.toString();
  }

  /// Export Matriks Presensi 16 Pertemuan & Kelayakan Ujian (BAP) ke CSV (Excel Friendly)
  static String exportAttendanceMatrixCsv({
    required String courseName,
    required String dosenName,
    required String semester,
    required String tahunAkademik,
    required List<StudentProfile> students,
    required Map<String, Map<int, String>> matrixData,
    int totalMeetingsHeld = 16,
    double thresholdPercent = 75.0,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BERITA ACARA & MATRIKS PRESENSI PERKULIAHAN (BAP)');
    buffer.writeln('UNIVERSITAS ABDUL AZIS LAMADJIDO (UNAZLAM)');
    buffer.writeln('Program Studi,"Ilmu Komunikasi"');
    buffer.writeln('Mata Kuliah,"$courseName"');
    buffer.writeln('Dosen Pengampu,"$dosenName"');
    buffer.writeln('Semester / T.A.,"$semester / $tahunAkademik"');
    buffer.writeln('Syarat Kehadiran Minimal Ujian,"$thresholdPercent%"');
    buffer.writeln(
      'Tanggal Rekap,"${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}"',
    );
    buffer.writeln('');

    // Header Kolom
    final headers = ['No', 'NIM', 'Nama Mahasiswa', 'Kelas'];
    for (int p = 1; p <= 16; p++) {
      if (p == 8) {
        headers.add('P8 (UTS)');
      } else if (p == 16) {
        headers.add('P16 (UAS)');
      } else {
        headers.add('P$p');
      }
    }
    headers.addAll([
      'Total Hadir',
      'Total Sesi',
      '% Kehadiran',
      'Status Kelayakan UAS',
    ]);
    buffer.writeln(headers.map((h) => '"$h"').join(','));

    // Rows
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final rowAttendance = matrixData[s.nim] ?? {};

      int hadirCount = 0;
      final meetingValues = <String>[];

      for (int p = 1; p <= 16; p++) {
        final status = (rowAttendance[p] ?? '').toLowerCase();
        if (status == 'hadir') {
          hadirCount++;
          meetingValues.add('Hadir');
        } else if (status == 'izin') {
          meetingValues.add('Izin');
        } else if (status == 'sakit') {
          meetingValues.add('Sakit');
        } else if (status == 'alpa' || status == 'alfa') {
          meetingValues.add('Alfa');
        } else {
          meetingValues.add('-');
        }
      }

      final activeMeetings = totalMeetingsHeld > 0 ? totalMeetingsHeld : 16;
      final percent = ((hadirCount / activeMeetings) * 100).round();
      final isEligible = percent >= thresholdPercent;
      final statusLabel = isEligible
          ? 'MEMENUHI SYARAT'
          : 'DICEKAL (<${thresholdPercent.toInt()}%)';

      final row = [
        '${i + 1}',
        '"${s.nim}"',
        '"${s.nama}"',
        '"${s.kelas}"',
        ...meetingValues.map((v) => '"$v"'),
        '$hadirCount',
        '$activeMeetings',
        '$percent%',
        '"$statusLabel"',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Export Rekap Presensi Pribadi Mahasiswa (Privat untuk Mahasiswa bersangkutan)
  static String exportPersonalAttendanceCsv({
    required String studentNim,
    required String studentName,
    required List<dynamic> history,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('REKAP PRESENSI PRIBADI MAHASISWA');
    buffer.writeln('NIM,"$studentNim"');
    buffer.writeln('Nama,"$studentName"');
    buffer.writeln(
      'Tanggal Cetak,"${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}"',
    );
    buffer.writeln('');
    buffer.writeln('No,Tanggal / Waktu,Mata Kuliah,Status Kehadiran');

    if (history.isEmpty) {
      buffer.writeln('1,-,Semua Mata Kuliah,Belum ada data presensi');
    } else {
      for (int i = 0; i < history.length; i++) {
        final item = history[i];
        final date = item.date;
        final course = item.courseName;
        final status = item.status;
        buffer.writeln('${i + 1},"$date","$course","$status"');
      }
    }

    return buffer.toString();
  }

  /// Export Kartu Hasil Studi (KHS) / Transkrip Nilai Mahasiswa
  static String exportKhsCsv({
    required StudentProfile student,
    required List<StudentCourseGrade> grades,
    required double gpa,
    required int totalSks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('KARTU HASIL STUDI (KHS) / TRANSKRIP AKADEMIK');
    buffer.writeln(
      'PORTAL ILKOM UNAZLAM - UNIVERSITAS ABDUL AZIS LAMADJIDO',
    );
    buffer.writeln('NIM,"${student.nim}"');
    buffer.writeln('Nama Mahasiswa,"${student.nama}"');
    buffer.writeln('Program Studi,"${student.prodi}"');
    buffer.writeln('Semester Aktif,${student.semester}');
    buffer.writeln('Indeks Prestasi Kumulatif (IPK),${gpa.toStringAsFixed(2)}');
    buffer.writeln('Total SKS Ditempuh,$totalSks SKS');
    buffer.writeln(
      'Tanggal Unduh,"${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}"',
    );
    buffer.writeln('');
    buffer.writeln(
      'No,Kode MK,Nama Mata Kuliah,SKS,Semester,Tahun Akademik,Nilai Huruf,Nilai Angka,Bobot',
    );

    if (grades.isEmpty) {
      buffer.writeln('1,-,Belum ada nilai yang dicatat,-,-,-,-,-,-');
    } else {
      for (int i = 0; i < grades.length; i++) {
        final g = grades[i];
        final bobot = (AcademicGradeService.gradePoints[g.letterGrade] ?? 0.0)
            .toStringAsFixed(1);
        final score = g.numericScore != null ? g.numericScore.toString() : '-';
        buffer.writeln(
          '${i + 1},"${g.courseCode}","${g.courseName}",${g.sks},${g.semester},"${g.academicYear}","${g.letterGrade}",$score,$bobot',
        );
      }
    }

    return buffer.toString();
  }

  /// Export Rekap Data Mahasiswa to CSV Format
  static String exportStudentsCsv({required List<StudentProfile> students}) {
    final buffer = StringBuffer();
    buffer.writeln(
      'No,NIM,Nama Mahasiswa,Program Studi,Semester,Kelas,Jabatan,Email,No WA,Status',
    );

    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final status = s.isAktif ? 'Aktif' : 'Nonaktif';
      buffer.writeln(
        '${i + 1},"${s.nim}","${s.nama}","${s.prodi}",${s.semester},"${s.kelas}","${s.jabatan}","${s.email}","${s.noWa}","$status"',
      );
    }

    return buffer.toString();
  }

  /// Export Rekap Distribusi Tugas Mahasiswa to CSV Format
  static String exportAssignmentsCsv({required List<Assignment> assignments}) {
    final buffer = StringBuffer();
    buffer.writeln('No,Mata Kuliah,Judul Tugas,Kategori,Tenggat Waktu,Status');

    for (int i = 0; i < assignments.length; i++) {
      final a = assignments[i];
      final deadlineStr = DateFormat('yyyy-MM-dd HH:mm').format(a.deadline);
      buffer.writeln(
        '${i + 1},"${a.courseName}","${a.judul}","${a.kategori}","$deadlineStr","${a.status}"',
      );
    }

    return buffer.toString();
  }

  /// Export Jadwal Kuliah to iCalendar (.ics) format for Google Calendar / Apple Calendar
  static String exportScheduleIcs({
    required List<Course> courses,
    String calendarName = 'Jadwal Kuliah ILKOM UNAZLAM',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//ILKOM UNAZLAM//Jadwal Kuliah//ID');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:$calendarName');
    buffer.writeln('X-WR-TIMEZONE:Asia/Jakarta');

    final dayToByDay = {
      'senin': 'MO',
      'selasa': 'TU',
      'rabu': 'WE',
      'kamis': 'TH',
      'jumat': 'FR',
      'sabtu': 'SA',
      'minggu': 'SU',
    };

    final dayToWeekday = {
      'senin': DateTime.monday,
      'selasa': DateTime.tuesday,
      'rabu': DateTime.wednesday,
      'kamis': DateTime.thursday,
      'jumat': DateTime.friday,
      'sabtu': DateTime.saturday,
      'minggu': DateTime.sunday,
    };

    final now = DateTime.now();

    for (var c in courses) {
      final cleanDay = c.hari.trim().toLowerCase();
      final byDay = dayToByDay[cleanDay] ?? 'MO';
      final targetWeekday = dayToWeekday[cleanDay] ?? DateTime.monday;

      final daysOffset = (targetWeekday - now.weekday);
      final refDate = now.add(Duration(days: daysOffset));

      int startH = 8, startM = 0;
      int endH = 9, endM = 40;
      try {
        final sp = c.jamMulai.split(':');
        startH = int.parse(sp[0]);
        startM = int.parse(sp[1]);
      } catch (_) {}
      try {
        final ep = c.jamSelesai.split(':');
        endH = int.parse(ep[0]);
        endM = int.parse(ep[1]);
      } catch (_) {}

      final startDt = DateTime(
        refDate.year,
        refDate.month,
        refDate.day,
        startH,
        startM,
      );
      final endDt = DateTime(
        refDate.year,
        refDate.month,
        refDate.day,
        endH,
        endM,
      );

      final dtFormat = DateFormat("yyyyMMdd'T'HHmmss");
      final dtStamp = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now.toUtc());

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln(
        'UID:${c.id.isNotEmpty ? c.id : c.nama.hashCode}_course@unazlam.ac.id',
      );
      buffer.writeln('DTSTAMP:$dtStamp');
      buffer.writeln('DTSTART;TZID=Asia/Jakarta:${dtFormat.format(startDt)}');
      buffer.writeln('DTEND;TZID=Asia/Jakarta:${dtFormat.format(endDt)}');
      buffer.writeln('RRULE:FREQ=WEEKLY;BYDAY=$byDay');
      buffer.writeln('SUMMARY:${c.nama} (${c.kode})');
      buffer.writeln(
        'LOCATION:${c.ruangan.isNotEmpty ? c.ruangan : "Ruang A2"}',
      );
      final desc =
          'Dosen: ${c.dosen} | ${c.sks} SKS${c.linkVirtual != null && c.linkVirtual!.isNotEmpty ? " | Link: ${c.linkVirtual}" : ""}';
      buffer.writeln('DESCRIPTION:$desc');
      buffer.writeln('STATUS:CONFIRMED');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Export Jadwal Kuliah to CSV Format
  static String exportScheduleCsv({required List<Course> courses}) {
    final buffer = StringBuffer();
    buffer.writeln(
      'No,Hari,Jam Mulai,Jam Selesai,Kode MK,Nama Mata Kuliah,SKS,Dosen Pengampu,Ruangan,Link Virtual',
    );

    for (int i = 0; i < courses.length; i++) {
      final c = courses[i];
      buffer.writeln(
        '${i + 1},"${c.hari}","${c.jamMulai}","${c.jamSelesai}","${c.kode}","${c.nama}",${c.sks},"${c.dosen}","${c.ruangan}","${c.linkVirtual ?? '-'}"',
      );
    }

    return buffer.toString();
  }

  /// Export Jadwal Kuliah as WhatsApp share text
  static String exportScheduleWhatsappText({required List<Course> courses}) {
    final buffer = StringBuffer();
    buffer.writeln('*📅 JADWAL KULIAH PRODI ILMU KOMUNIKASI*');
    buffer.writeln('*UNIVERSITAS ABDUL AZIS LAMADJIDO (UNAZLAM)*');
    buffer.writeln('────────────────────────────');

    final dayOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    for (final day in dayOrder) {
      final dayCourses = courses
          .where((c) => c.hari.trim().toLowerCase() == day.toLowerCase())
          .toList();
      if (dayCourses.isEmpty) continue;

      buffer.writeln('\n*📌 HARI ${day.toUpperCase()}*');
      for (final c in dayCourses) {
        buffer.writeln('• *${c.nama}* (${c.sks} SKS)');
        buffer.writeln('  ⏰ ${c.jamMulai} - ${c.jamSelesai} WITA');
        buffer.writeln('  📍 Ruang: ${c.ruangan}');
        buffer.writeln('  👨‍🏫 Dosen: ${c.dosen}');
        if (c.linkVirtual != null && c.linkVirtual!.isNotEmpty) {
          buffer.writeln('  🔗 Virtual: ${c.linkVirtual}');
        }
      }
    }
    buffer.writeln('\n────────────────────────────');
    buffer.writeln('_Diunduh otomatis via ILKOM UNAZLAM Hub_');
    return buffer.toString();
  }

  /// Export Direktori Mahasiswa to CSV Format
  static String exportDirectoryCsv({required List<StudentProfile> students}) {
    final buffer = StringBuffer();
    buffer.writeln(
      'No,NIM,Nama Lengkap,Nama Panggilan,Jabatan,Kelas,Semester,Peminatan,WhatsApp,Email,Instagram,LinkedIn',
    );
    final nonAdmin = students.where((s) => s.role != 'ADMIN').toList();
    for (int i = 0; i < nonAdmin.length; i++) {
      final s = nonAdmin[i];
      buffer.writeln(
        '${i + 1},"${s.nim}","${s.nama}","${s.namaPanggilan ?? '-'}","${s.jabatan}","${s.kelas}",${s.semester},"${s.peminatan.isEmpty ? '-' : s.peminatan}","${s.noWa.isEmpty ? '-' : s.noWa}","${s.email.isEmpty ? '-' : s.email}","${s.instagram ?? '-'}","${s.linkedin ?? '-'}"',
      );
    }
    return buffer.toString();
  }

  /// Export Direktori Mahasiswa as WhatsApp share text
  static String exportDirectoryWhatsappText({
    required List<StudentProfile> students,
  }) {
    final nonAdmin = students.where((s) => s.role != 'ADMIN').toList();
    final buffer = StringBuffer();
    buffer.writeln('*👥 DIREKTORI MAHASISWA ILMU KOMUNIKASI*');
    buffer.writeln('*UNIVERSITAS ABDUL AZIS LAMADJIDO (UNAZLAM)*');
    buffer.writeln('Total Terdaftar: *${nonAdmin.length} Mahasiswa*');
    buffer.writeln('────────────────────────────');

    final officers = nonAdmin.where((s) {
      final j = s.jabatan.toLowerCase();
      return j.contains('ketua') ||
          j.contains('bendahara') ||
          j.contains('sekretaris');
    }).toList();

    if (officers.isNotEmpty) {
      buffer.writeln('\n*⭐ PENGURUS KELAS*');
      for (final o in officers) {
        final waInfo = o.noWa.isNotEmpty ? ' • WA: ${o.noWa}' : '';
        buffer.writeln('• *${o.nama}* (${o.jabatan})$waInfo');
      }
    }

    buffer.writeln('\n*📋 DAFTAR ANGGOTA KELAS*');
    for (int i = 0; i < nonAdmin.length; i++) {
      final s = nonAdmin[i];
      final peminatan = (s.peminatan.isNotEmpty && s.peminatan != '-')
          ? ' [${s.peminatan}]'
          : '';
      buffer.writeln('${i + 1}. *${s.nama}* (${s.nim})$peminatan');
    }

    buffer.writeln('\n────────────────────────────');
    buffer.writeln('_Diekspor otomatis via ILKOM UNAZLAM Hub_');
    return buffer.toString();
  }

  /// Show Export & Download Sheet
  static void showExportSheet(
    BuildContext context, {
    required String title,
    required String fileName,
    required String content,
    String? subtitle,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File Info Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: Color(0xFF5B3DE8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CSV / Excel',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B3DE8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Preview Text Box
            const Text(
              'Pratinjau Data Laporan:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data CSV berhasil disalin! Anda bisa langsung paste di Excel / Google Sheets.',
                          ),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('Salin CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B3DE8),
                      side: const BorderSide(color: Color(0xFF5B3DE8)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await exportFile(fileName, content);
                      if (result == FileExportResult.dismissed) return;
                      if (result == FileExportResult.unavailable) {
                        await Clipboard.setData(ClipboardData(text: content));
                      }
                      if (!ctx.mounted || !context.mounted) return;
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(switch (result) {
                            FileExportResult.downloaded =>
                              'File "$fileName" berhasil diunduh.',
                            FileExportResult.shared =>
                              'Menu berbagi file terbuka. Pilih aplikasi untuk menyimpan "$fileName".',
                            FileExportResult.dismissed => '',
                            FileExportResult.unavailable => 'Ekspor file tidak tersedia. Data disalin ke clipboard.',
                          }),
                          backgroundColor:
                              result == FileExportResult.unavailable
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Unduh File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
