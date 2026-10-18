import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/academic_grade_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/models.dart';
import '../../attendance/models/attendance_models.dart';

class AdminStudentSummary extends StatefulWidget {
  final StudentProfile student;
  final void Function(String message, {bool isError}) onShowMessage;

  const AdminStudentSummary({
    super.key,
    required this.student,
    required this.onShowMessage,
  });

  @override
  State<AdminStudentSummary> createState() => _AdminStudentSummaryState();
}

class _AdminStudentSummaryState extends State<AdminStudentSummary> {
  late Future<List<Map<String, dynamic>>> _attendance;
  late Future<Map<String, dynamic>?> _dues;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant AdminStudentSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.nim != widget.student.nim) _reload();
  }

  void _reload() {
    _attendance = SupabaseRepository.getAttendanceLogsStrict(
      studentNim: widget.student.nim,
    );
    _dues = _loadDues();
  }

  Future<Map<String, dynamic>?> _loadDues() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum terhubung.');
    return await client
        .from('treasury_dues')
        .select('is_lunas')
        .eq('student_nim', widget.student.nim)
        .eq('period', DateFormat('yyyy-MM').format(DateTime.now()))
        .maybeSingle();
  }

  Future<void> _export(bool khs) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final student = widget.student;
      late String csv;
      if (khs) {
        final grades = await AcademicGradeService.listGrades(student.nim);
        final sks = grades.fold<int>(0, (sum, grade) => sum + grade.sks);
        final points = grades.fold<double>(
          0,
          (sum, grade) =>
              sum +
              (AcademicGradeService.gradePoints[grade.letterGrade] ?? 0) *
                  grade.sks,
        );
        csv = ExportService.exportKhsCsv(
          student: student,
          grades: grades,
          gpa: sks == 0 ? 0 : points / sks,
          totalSks: sks,
        );
      } else {
        final rows = await SupabaseRepository.getAttendanceLogsStrict(
          studentNim: student.nim,
        );
        final history = rows.map((row) {
          final date = DateTime.tryParse(row['created_at']?.toString() ?? '');
          final course = row['courses'];
          return AttendanceHistoryItem(
            date: date == null
                ? '-'
                : DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal()),
            courseName: course is Map
                ? course['nama_mk']?.toString() ?? 'Mata Kuliah'
                : 'Mata Kuliah',
            status: row['status']?.toString() ?? '-',
          );
        }).toList();
        csv = ExportService.exportPersonalAttendanceCsv(
          studentNim: student.nim,
          studentName: student.nama,
          history: history,
        );
      }
      if (!mounted) return;
      ExportService.showExportSheet(
        context,
        title: '${khs ? 'KHS' : 'Presensi'} ${student.nama}',
        fileName: '${khs ? 'khs' : 'presensi'}_${student.nim}.csv',
        content: csv,
        subtitle: khs
            ? 'Nilai yang tercatat di database'
            : 'Rekap presensi individual',
      );
    } catch (error) {
      if (mounted) widget.onShowMessage('Ekspor gagal: $error', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ringkasan Kehadiran & Akademik',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _attendance,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Kehadiran gagal dimuat. Coba muat ulang.');
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final rows = snapshot.data!;
              final present = rows
                  .where(
                    (row) => row['status']?.toString().toLowerCase() == 'hadir',
                  )
                  .length;
              return Text(
                rows.isEmpty
                    ? 'Belum ada data presensi.'
                    : 'Kehadiran: ${(present * 100 / rows.length).round()}% ($present dari ${rows.length} catatan)',
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: _dues,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Status kas gagal dimuat. Coba muat ulang.');
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              final status = snapshot.data == null
                  ? 'Belum dicatat'
                  : snapshot.data!['is_lunas'] == true
                  ? 'Lunas'
                  : 'Belum lunas';
              return Text(
                'Kas ${DateFormat('MM/yyyy').format(DateTime.now())}: $status',
              );
            },
          ),
          TextButton.icon(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            label: const Text('Muat ulang ringkasan'),
          ),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(false),
            icon: const Icon(Icons.checklist_rtl_rounded),
            label: const Text('Ekspor Rekap Presensi Mahasiswa'),
          ),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(true),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Ekspor Kartu Hasil Studi (KHS)'),
          ),
          if (_exporting) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
