import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dummy_data.dart';

import 'package:intl/intl.dart';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart';
import '../../models/models.dart';

class ExportService {
  /// Trigger direct file download in browser or copy to clipboard on other platforms
  static void downloadFile(String fileName, String content) {
    if (kIsWeb) {
      downloadFilePlatform(fileName, content);
    } else {
      Clipboard.setData(ClipboardData(text: content));
    }
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
  static String exportAttendanceCsv(String courseName) {
    final buffer = StringBuffer();
    buffer.writeln(
      'No,NIM,Nama Mahasiswa,Program Studi,Status Kehadiran,Mata Kuliah',
    );

    final students = DummyData.students
        .where((s) => s.role != 'ADMIN')
        .toList();
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final status = (i % 8 == 0) ? 'Izin' : 'Hadir';
      buffer.writeln(
        '${i + 1},"${s.nim}","${s.nama}","${s.prodi}","$status","$courseName"',
      );
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

  /// Show Export & Download Sheet
  static void showExportSheet(
    BuildContext context, {
    required String title,
    required String fileName,
    required String content,
    String? subtitle,
  }) {
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
                    onPressed: () {
                      downloadFile(fileName, content);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'File "$fileName" berhasil diunduh ke perangkat Anda! 📁',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
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
