import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import 'dummy_data.dart';
import 'supabase_service.dart';

class SupabaseRepository {
  // ====================================================================
  // SINKRONISASI LENGKAP PADA AWAL APLIKASI DIBUKA
  // ====================================================================
  static Future<void> syncAllFromCloud() async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      await Future.wait([
        getCourses(),
        getAnnouncements(),
        getAssignments(),
        getTreasuryTransactions(),
      ]);
      debugPrint('Sinkronisasi data Supabase berhasil dimuat!');
    } catch (e) {
      debugPrint('Sinkronisasi Supabase sebagian gagal (menggunakan cache lokal): $e');
    }
  }

  // ====================================================================
  // 1. MATA KULIAH & JADWAL KULIAH (COURSES)
  // ====================================================================
  static Future<List<Course>> getCourses() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.courses;

    try {
      final response = await client.from('courses').select().order('hari');
      final list = (response as List).map((row) {
        String jamM = row['jam_mulai']?.toString() ?? '08:00';
        if (jamM.length >= 5) jamM = jamM.substring(0, 5);
        String jamS = row['jam_selesai']?.toString() ?? '10:00';
        if (jamS.length >= 5) jamS = jamS.substring(0, 5);

        return Course(
          id: row['id']?.toString() ?? '',
          kode: row['kode_mk'] ?? '',
          nama: row['nama_mk'] ?? '',
          sks: (row['sks'] as num?)?.toInt() ?? 2,
          semester: (row['semester'] as num?)?.toInt() ?? 1,
          dosen: row['dosen_pengampu'] ?? '',
          dosenWa: row['dosen_wa'],
          hari: row['hari'] ?? '',
          jamMulai: jamM,
          jamSelesai: jamS,
          ruangan: row['ruangan'] ?? 'Ruang A2',
          linkVirtual: row['link_virtual'],
        );
      }).toList();

      if (list.isNotEmpty) {
        DummyData.courses
          ..clear()
          ..addAll(list);
        return list;
      }
      return DummyData.courses;
    } catch (e) {
      debugPrint('Error fetch courses dari Supabase: $e');
      return DummyData.courses;
    }
  }

  static Future<bool> createCourse(Course course) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('courses').insert({
        'id': course.id,
        'kode_mk': course.kode,
        'nama_mk': course.nama,
        'sks': course.sks,
        'semester': course.semester,
        'dosen_pengampu': course.dosen,
        'dosen_wa': course.dosenWa,
        'hari': course.hari,
        'jam_mulai': '${course.jamMulai}:00',
        'jam_selesai': '${course.jamSelesai}:00',
        'ruangan': course.ruangan,
      });
      return true;
    } catch (e) {
      debugPrint('Error insert course ke Supabase: $e');
      return true;
    }
  }

  static Future<bool> updateCourse(Course course) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('courses').update({
        'kode_mk': course.kode,
        'nama_mk': course.nama,
        'sks': course.sks,
        'semester': course.semester,
        'dosen_pengampu': course.dosen,
        'dosen_wa': course.dosenWa,
        'hari': course.hari,
        'jam_mulai': '${course.jamMulai}:00',
        'jam_selesai': '${course.jamSelesai}:00',
        'ruangan': course.ruangan,
      }).eq('id', course.id);
      return true;
    } catch (e) {
      debugPrint('Error update course di Supabase: $e');
      return true;
    }
  }

  static Future<bool> deleteCourse(String id) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('courses').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete course dari Supabase: $e');
      return true;
    }
  }

  // ====================================================================
  // 2. PENGUMUMAN KELAS (ANNOUNCEMENTS)
  // ====================================================================
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
          authorName: row['author_name'] ?? 'Nur Farida',
          authorRole: row['author_role'] ?? 'Ketua Kelas',
          judul: row['judul'] ?? '',
          isi: row['isi'] ?? '',
          isPinned: row['is_pinned'] ?? false,
          kategori: row['kategori'] ?? 'Akademik',
          createdAt: row['created_at'] != null
              ? DateTime.parse(row['created_at'])
              : DateTime.now(),
        );
      }).toList();

      if (list.isNotEmpty) {
        DummyData.announcements
          ..clear()
          ..addAll(list);
        return list;
      }
      return DummyData.announcements;
    } catch (e) {
      debugPrint('Error fetch announcements dari Supabase: $e');
      return DummyData.announcements;
    }
  }

  static Future<bool> createAnnouncement({
    required String judul,
    required String isi,
    required String kategori,
    bool isPinned = false,
    String authorName = 'Nur Farida (Ketua Kelas)',
  }) async {
    final client = SupabaseService.client;
    String assignedId = 'ann_${DateTime.now().millisecondsSinceEpoch}';

    if (client != null) {
      try {
        final res = await client.from('announcements').insert({
          'judul': judul,
          'isi': isi,
          'kategori': kategori,
          'is_pinned': isPinned,
          'author_name': authorName,
          'author_role': 'Ketua Kelas',
        }).select('id').single();

        if (res['id'] != null) {
          assignedId = res['id'].toString();
        }
      } catch (e) {
        debugPrint('Sync announcement ke Supabase offline/error: $e');
      }
    }

    final newAnn = Announcement(
      id: assignedId,
      authorName: authorName,
      authorRole: 'Ketua Kelas',
      judul: judul,
      isi: isi,
      isPinned: isPinned,
      kategori: kategori,
      createdAt: DateTime.now(),
    );
    DummyData.announcements.insert(0, newAnn);
    return true;
  }

  static Future<bool> updateAnnouncement(Announcement announcement) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('announcements').update({
        'judul': announcement.judul,
        'isi': announcement.isi,
        'kategori': announcement.kategori,
        'is_pinned': announcement.isPinned,
      }).eq('id', announcement.id);
      return true;
    } catch (e) {
      debugPrint('Error update announcement di Supabase: $e');
      return true;
    }
  }

  static Future<bool> deleteAnnouncement(String id) async {
    DummyData.announcements.removeWhere((a) => a.id == id);
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('announcements').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Sync delete announcement error: $e');
      return true;
    }
  }

  // ====================================================================
  // 3. TUGAS KELAS (ASSIGNMENTS)
  // ====================================================================
  static Future<List<Assignment>> getAssignments() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.assignments;

    try {
      final response = await client.from('assignments').select().order('deadline');

      final list = (response as List).map((row) {
        return Assignment(
          id: row['id']?.toString() ?? '',
          courseId: row['course_id']?.toString() ?? '',
          courseName: row['course_name'] ?? 'Mata Kuliah',
          judul: row['judul'] ?? '',
          deskripsi: row['deskripsi'] ?? '',
          kategori: row['kategori'] ?? 'Individu',
          deadline: row['deadline'] != null
              ? DateTime.parse(row['deadline'])
              : DateTime.now().add(const Duration(days: 3)),
          linkPengumpulan: row['link_pengumpulan'],
          status: row['status'] ?? 'belum',
        );
      }).toList();

      if (list.isNotEmpty) {
        DummyData.assignments
          ..clear()
          ..addAll(list);
        return list;
      }
      return DummyData.assignments;
    } catch (e) {
      debugPrint('Error fetch assignments dari Supabase: $e');
      return DummyData.assignments;
    }
  }

  static Future<bool> createAssignment({
    required String courseId,
    required String courseName,
    required String judul,
    required String deskripsi,
    required String kategori,
    required DateTime deadline,
    String? linkPengumpulan,
  }) async {
    final client = SupabaseService.client;
    String assignedId = 'asg_${DateTime.now().millisecondsSinceEpoch}';

    if (client != null) {
      try {
        final payload = <String, dynamic>{
          'course_name': courseName,
          'judul': judul,
          'deskripsi': deskripsi,
          'kategori': kategori,
          'deadline': deadline.toIso8601String(),
          'link_pengumpulan': linkPengumpulan,
          'status': 'belum',
        };
        // course_id on Supabase references courses(id) which may be UUID or nullable
        if (courseId.isNotEmpty && !courseId.startsWith('c')) {
          payload['course_id'] = courseId;
        }

        final res = await client.from('assignments').insert(payload).select('id').single();
        if (res['id'] != null) {
          assignedId = res['id'].toString();
        }
      } catch (e) {
        debugPrint('Sync assignment ke Supabase error: $e');
      }
    }

    final newAssignment = Assignment(
      id: assignedId,
      courseId: courseId,
      courseName: courseName,
      judul: judul,
      deskripsi: deskripsi,
      kategori: kategori,
      deadline: deadline,
      linkPengumpulan: linkPengumpulan,
      status: 'belum',
    );
    DummyData.assignments.insert(0, newAssignment);
    return true;
  }

  static Future<bool> updateAssignment(Assignment assignment) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('assignments').update({
        'judul': assignment.judul,
        'course_id': assignment.courseId,
        'course_name': assignment.courseName,
        'deskripsi': assignment.deskripsi,
        'kategori': assignment.kategori,
        'deadline': assignment.deadline.toIso8601String(),
        'link_pengumpulan': assignment.linkPengumpulan,
        'status': assignment.status,
      }).eq('id', assignment.id);
      return true;
    } catch (e) {
      debugPrint('Error update assignment di Supabase: $e');
      return true;
    }
  }

  static Future<bool> updateAssignmentStatus(String id, String status) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('assignments').update({'status': status}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error update status assignment di Supabase: $e');
      return true;
    }
  }

  static Future<bool> deleteAssignment(String id) async {
    DummyData.assignments.removeWhere((a) => a.id == id);
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('assignments').delete().eq('id', id);
      return true;
    } catch (e) {
      return true;
    }
  }

  // ====================================================================
  // 4. KAS KELAS (TREASURY TRANSACTIONS)
  // ====================================================================
  static Future<List<TreasuryTransaction>> getTreasuryTransactions() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.treasuryTransactions;

    try {
      final response = await client
          .from('treasury_transactions')
          .select()
          .order('tanggal', ascending: false);

      final list = (response as List).map((row) {
        return TreasuryTransaction(
          id: row['id']?.toString() ?? '',
          judul: row['judul'] ?? '',
          nominal: (row['nominal'] as num?)?.toInt() ?? 0,
          isPemasukan: row['is_pemasukan'] ?? true,
          kategori: row['kategori'] ?? 'Kas Bulanan',
          tanggal: row['tanggal'] != null
              ? DateTime.parse(row['tanggal'])
              : DateTime.now(),
          pencatat: row['pencatat'] ?? 'Farah Nabila (Bendahara)',
        );
      }).toList();

      if (list.isNotEmpty) {
        DummyData.treasuryTransactions
          ..clear()
          ..addAll(list);
        return list;
      }
      return DummyData.treasuryTransactions;
    } catch (e) {
      debugPrint('Error fetch treasury dari Supabase: $e');
      return DummyData.treasuryTransactions;
    }
  }

  static Future<bool> createTreasuryTransaction(TreasuryTransaction item) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('treasury_transactions').insert({
        'id': item.id,
        'judul': item.judul,
        'nominal': item.nominal,
        'is_pemasukan': item.isPemasukan,
        'kategori': item.kategori,
        'tanggal': item.tanggal.toIso8601String(),
        'pencatat': item.pencatat,
      });
      return true;
    } catch (e) {
      debugPrint('Sync insert treasury ke Supabase: $e');
      return true;
    }
  }

  static Future<bool> updateTreasuryTransaction(TreasuryTransaction item) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('treasury_transactions').update({
        'judul': item.judul,
        'nominal': item.nominal,
        'is_pemasukan': item.isPemasukan,
        'kategori': item.kategori,
      }).eq('id', item.id);
      return true;
    } catch (e) {
      debugPrint('Error update treasury di Supabase: $e');
      return true;
    }
  }

  static Future<bool> deleteTreasuryTransaction(String id) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('treasury_transactions').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete treasury dari Supabase: $e');
      return true;
    }
  }

  // ====================================================================
  // 5. AGENDA & KALENDER KELAS (AGENDA ITEMS)
  // ====================================================================
  static Future<bool> createAgendaItem({
    required String id,
    required int day,
    required String month,
    required String title,
    required String course,
    required int colorValue,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('agenda_items').insert({
        'id': id,
        'day': day,
        'month': month,
        'title': title,
        'course': course,
        'color_value': colorValue,
      });
      return true;
    } catch (e) {
      debugPrint('Sync insert agenda ke Supabase: $e');
      return true;
    }
  }

  static Future<bool> deleteAgendaItem(String id) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('agenda_items').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete agenda dari Supabase: $e');
      return true;
    }
  }

  // ====================================================================
  // 6. CATATAN PRESENSI (ATTENDANCE LOGS)
  // ====================================================================
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

  // ====================================================================
  // 7. MANAJEMEN AKUN & MAHASISWA (STUDENTS)
  // ====================================================================
  static Future<bool> updateStudentJabatan(String nim, String jabatan) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('students').update({'jabatan': jabatan}).eq('nim', nim);
      return true;
    } catch (e) {
      debugPrint('Error update jabatan di Supabase: $e');
      return true;
    }
  }

  static Future<bool> toggleStudentStatus(String nim, bool isAktif) async {
    final client = SupabaseService.client;
    if (client == null) return true;

    try {
      await client.from('students').update({'is_aktif': isAktif}).eq('nim', nim);
      return true;
    } catch (e) {
      debugPrint('Error toggle status di Supabase: $e');
      return true;
    }
  }
}
