import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import 'dummy_data.dart';
import 'supabase_service.dart';

class SupabaseRepository {
  // 1. Ambil Data Mata Kuliah
  static Future<List<Course>> getCourses() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.courses;

    try {
      final response = await client.from('courses').select().order('hari');
      final list = (response as List).map((row) {
        return Course(
          id: row['id']?.toString() ?? '',
          kode: row['kode_mk'] ?? '',
          nama: row['nama_mk'] ?? '',
          sks: row['sks'] ?? 3,
          semester: row['semester'] ?? 4,
          dosen: row['dosen_pengampu'] ?? '',
          dosenWa: row['dosen_wa'],
          hari: row['hari'] ?? '',
          jamMulai: (row['jam_mulai'] as String?)?.substring(0, 5) ?? '08:00',
          jamSelesai: (row['jam_selesai'] as String?)?.substring(0, 5) ?? '10:00',
          ruangan: row['ruangan'] ?? '',
          linkVirtual: row['link_virtual'],
        );
      }).toList();

      return list.isNotEmpty ? list : DummyData.courses;
    } catch (e) {
      debugPrint('Error fetch courses dari Supabase: $e');
      return DummyData.courses;
    }
  }

  // 2. Ambil Data Pengumuman
  static Future<List<Announcement>> getAnnouncements() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.announcements;

    try {
      final response = await client
          .from('announcements')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final list = (response as List).map((row) {
        return Announcement(
          id: row['id']?.toString() ?? '',
          authorName: row['author_name'] ?? 'Komti',
          authorRole: row['author_role'] ?? 'Pengurus Kelas',
          judul: row['judul'] ?? '',
          isi: row['isi'] ?? '',
          isPinned: row['is_pinned'] ?? false,
          kategori: row['kategori'] ?? 'Akademik',
          createdAt: row['created_at'] != null
              ? DateTime.parse(row['created_at'])
              : DateTime.now(),
        );
      }).toList();

      return list.isNotEmpty ? list : DummyData.announcements;
    } catch (e) {
      debugPrint('Error fetch announcements dari Supabase: $e');
      return DummyData.announcements;
    }
  }

  // 3. Ambil Data Tugas
  static Future<List<Assignment>> getAssignments() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.assignments;

    try {
      final response = await client
          .from('assignments')
          .select('*, courses(nama_mk)')
          .order('deadline');

      final list = (response as List).map((row) {
        final courseMap = row['courses'] as Map<String, dynamic>?;
        final courseName = courseMap?['nama_mk'] ?? 'Mata Kuliah';

        return Assignment(
          id: row['id']?.toString() ?? '',
          courseId: row['course_id']?.toString() ?? '',
          courseName: courseName,
          judul: row['judul'] ?? '',
          deskripsi: row['deskripsi'] ?? '',
          kategori: row['kategori'] ?? 'Individu',
          deadline: row['deadline'] != null
              ? DateTime.parse(row['deadline'])
              : DateTime.now().add(const Duration(days: 3)),
          linkPengumpulan: row['link_pengumpulan'],
        );
      }).toList();

      return list.isNotEmpty ? list : DummyData.assignments;
    } catch (e) {
      debugPrint('Error fetch assignments dari Supabase: $e');
      return DummyData.assignments;
    }
  }

  // 4. Tambah Pengumuman Baru ke Supabase
  static Future<bool> createAnnouncement({
    required String judul,
    required String isi,
    required String kategori,
    bool isPinned = false,
    String authorName = 'Nur Farida (Ketua Kelas)',
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('announcements').insert({
        'judul': judul,
        'isi': isi,
        'kategori': kategori,
        'is_pinned': isPinned,
        'author_name': authorName,
        'author_role': 'Ketua Kelas',
      });
      return true;
    } catch (e) {
      debugPrint('Error post announcement ke Supabase: $e');
      return false;
    }
  }

  // 5. Tambah Catatan Presensi ke Supabase
  static Future<bool> logAttendance({
    required String courseId,
    required String studentNim,
    required int pertemuanKe,
    required String status,
    String? catatan,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('attendance_logs').insert({
        'course_id': courseId,
        'student_nim': studentNim,
        'pertemuan_ke': pertemuanKe,
        'status': status,
        'catatan': catatan,
      });
      return true;
    } catch (e) {
      debugPrint('Error log attendance ke Supabase: $e');
      return false;
    }
  }
}
