import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import 'course_schedule_service.dart';
import 'dummy_data.dart';
import 'supabase_service.dart';

class StudentDashboardSnapshot {
  final List<Map<String, dynamic>> attendance;
  final Assignment? nextAssignment;
  final List<Assignment> pendingAssignments;
  final Announcement? latestAnnouncement;
  final List<Course> todayCourses;
  final List<Course> upcomingCourses;
  final String nextActiveDayName;
  final String nextActiveDayLabel;
  final int daysUntilNext;
  final bool todayHasClasses;
  final bool todayClassesFinished;
  final List<Course> allCourses;
  final bool? isKasLunas;
  final int kasNominal;
  final String currentPeriodLabel;

  const StudentDashboardSnapshot({
    required this.attendance,
    required this.nextAssignment,
    this.pendingAssignments = const [],
    required this.latestAnnouncement,
    this.todayCourses = const [],
    this.upcomingCourses = const [],
    this.nextActiveDayName = '',
    this.nextActiveDayLabel = '',
    this.daysUntilNext = 0,
    this.todayHasClasses = false,
    this.todayClassesFinished = false,
    this.allCourses = const [],
    this.isKasLunas,
    this.kasNominal = 0,
    this.currentPeriodLabel = '',
  });
}

/// Loads dashboard data from the signed-in student's Supabase project.
class StudentDashboardService {
  static Future<StudentDashboardSnapshot> load(String studentNim) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw Exception('Koneksi Supabase belum dikonfigurasi.');
    }
    if (studentNim.isEmpty) {
      throw Exception('NIM akun tidak ditemukan. Silakan masuk kembali.');
    }

    final now = DateTime.now();
    final currentPeriod = DateFormat('yyyy-MM').format(now);
    final periodLabel = DateFormat('MMMM yyyy', 'id_ID').format(now);

    final results = await Future.wait<dynamic>([
      client
          .from('attendance_logs')
          .select('*, courses(nama_mk, kode_mk)')
          .eq('student_nim', studentNim)
          .order('created_at', ascending: false),
      client.from('assignments').select().order('deadline'),
      client
          .from('student_assignments')
          .select('assignment_id,status')
          .eq('student_nim', studentNim),
      client
          .from('announcements')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(1),
    ]);

    final attendance = List<Map<String, dynamic>>.from(results[0] as List);
    final statusRows = List<Map<String, dynamic>>.from(results[2] as List);
    final statuses = {
      for (final row in statusRows)
        row['assignment_id'].toString(): row['status']?.toString() ?? 'belum',
    };

    final assignments =
        List<Map<String, dynamic>>.from(results[1] as List)
            .map(
              (row) => Assignment(
                id: row['id']?.toString() ?? '',
                courseId: row['course_id']?.toString() ?? '',
                courseName: row['course_name']?.toString() ?? 'Mata Kuliah',
                judul: row['judul']?.toString() ?? '',
                deskripsi: row['deskripsi']?.toString() ?? '',
                kategori: row['kategori']?.toString() ?? 'Individu',
                deadline:
                    DateTime.tryParse(row['deadline']?.toString() ?? '') ??
                    DateTime.now(),
                linkPengumpulan: row['link_pengumpulan']?.toString(),
                status: statuses[row['id']?.toString()] ?? 'belum',
              ),
            )
            .where(
              (assignment) =>
                  assignment.status != 'selesai' &&
                  assignment.status != 'dinilai',
            )
            .toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

    final announcementRows = List<Map<String, dynamic>>.from(
      results[3] as List,
    );
    Announcement? announcement;
    if (announcementRows.isNotEmpty) {
      final row = announcementRows.first;
      announcement = Announcement(
        id: row['id']?.toString() ?? '',
        authorName: row['author_name']?.toString() ?? 'Admin kelas',
        authorRole: row['author_role']?.toString() ?? 'Pengurus',
        judul: row['judul']?.toString() ?? '',
        isi: row['isi']?.toString() ?? '',
        isPinned: row['is_pinned'] as bool? ?? false,
        kategori: row['kategori']?.toString() ?? 'Akademik',
        createdAt:
            DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }

    // Ambil daftar mata kuliah nyata dari Supabase
    List<Course> loadedCourses = [];
    try {
      final coursesRes = await client.from('courses').select().order('jam_mulai');
      loadedCourses = (coursesRes as List).map<Course>((row) {
        var start = row['jam_mulai']?.toString() ?? '08:00';
        var end = row['jam_selesai']?.toString() ?? '10:00';
        if (start.length >= 5) start = start.substring(0, 5);
        if (end.length >= 5) end = end.substring(0, 5);
        return Course(
          id: row['id']?.toString() ?? '',
          kode: row['kode_mk']?.toString() ?? '',
          nama: row['nama_mk']?.toString() ?? '',
          sks: (row['sks'] as num?)?.toInt() ?? 2,
          semester: (row['semester'] as num?)?.toInt() ?? 1,
          dosen: row['dosen_pengampu']?.toString() ?? '',
          dosenWa: row['dosen_wa']?.toString(),
          hari: row['hari']?.toString() ?? '',
          jamMulai: start,
          jamSelesai: end,
          ruangan: row['ruangan']?.toString() ?? 'Ruang A2',
          linkVirtual: row['link_virtual']?.toString(),
        );
      }).toList();

      if (loadedCourses.isNotEmpty) {
        DummyData.courses
          ..clear()
          ..addAll(loadedCourses);
      }
    } catch (e) {
      debugPrint('Error loading courses in StudentDashboardService: $e');
      loadedCourses = DummyData.courses;
    }

    final todayCourses = CourseScheduleService.getTodayCourses(loadedCourses, now);
    final nextDayInfo = CourseScheduleService.getNextActiveDayInfo(loadedCourses, now);
    final hasRemaining = CourseScheduleService.hasRemainingCoursesToday(todayCourses, now);
    final todayHasClasses = todayCourses.isNotEmpty;
    final todayFinished = todayHasClasses && !hasRemaining;

    // Ambil status iuran kas pribadi mahasiswa untuk periode berjalan
    bool? isKasLunas;
    int kasNominal = 0;
    try {
      final dueRow = await client
          .from('treasury_dues')
          .select('nominal, is_lunas')
          .eq('student_nim', studentNim)
          .eq('period', currentPeriod)
          .maybeSingle();

      if (dueRow != null) {
        isKasLunas = dueRow['is_lunas'] as bool? ?? false;
        kasNominal = (dueRow['nominal'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('Info: Status iuran kas Supabase ($e), fallback status lokal.');
    }

    return StudentDashboardSnapshot(
      attendance: attendance,
      nextAssignment: assignments.isEmpty ? null : assignments.first,
      pendingAssignments: assignments,
      latestAnnouncement: announcement,
      todayCourses: todayCourses,
      upcomingCourses: nextDayInfo?.courses ?? [],
      nextActiveDayName: nextDayInfo?.dayName ?? '',
      nextActiveDayLabel: nextDayInfo?.dayLabel ?? '',
      daysUntilNext: nextDayInfo?.daysAhead ?? 0,
      todayHasClasses: todayHasClasses,
      todayClassesFinished: todayFinished,
      allCourses: loadedCourses,
      isKasLunas: isKasLunas,
      kasNominal: kasNominal,
      currentPeriodLabel: periodLabel,
    );
  }
}
