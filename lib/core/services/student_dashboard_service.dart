import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import 'supabase_service.dart';

class StudentDashboardSnapshot {
  final List<Map<String, dynamic>> attendance;
  final Assignment? nextAssignment;
  final Announcement? latestAnnouncement;

  const StudentDashboardSnapshot({
    required this.attendance,
    required this.nextAssignment,
    required this.latestAnnouncement,
  });
}

/// Loads dashboard data only from the signed-in student's Supabase project.
/// Unlike the legacy feature repositories, this service never substitutes demo
/// data when a request fails.
class StudentDashboardService {
  static Future<StudentDashboardSnapshot> load(String studentNim) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw Exception('Koneksi Supabase belum dikonfigurasi.');
    }
    if (studentNim.isEmpty) {
      throw Exception('NIM akun tidak ditemukan. Silakan masuk kembali.');
    }

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

    return StudentDashboardSnapshot(
      attendance: attendance,
      nextAssignment: assignments.isEmpty ? null : assignments.first,
      latestAnnouncement: announcement,
    );
  }
}
