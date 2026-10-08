import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

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
        getClassDirectory(),
      ]);
      debugPrint('Sinkronisasi data Supabase berhasil dimuat!');
    } catch (e) {
      debugPrint(
        'Sinkronisasi Supabase sebagian gagal (menggunakan cache lokal): $e',
      );
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

      DummyData.courses
        ..clear()
        ..addAll(list);
      return list;
    } catch (e) {
      debugPrint('Error fetch courses dari Supabase: $e');
      return DummyData.courses;
    }
  }

  static Future<List<Course>> getCoursesStrict() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final response = await client.from('courses').select().order('hari');
    return (response as List).map((row) {
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
  }

  static Future<bool> createCourse(Course course) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('courses').insert({
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
      return false;
    }
  }

  static Future<bool> updateCourse(Course course) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('courses')
          .update({
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
          })
          .eq('id', course.id);
      return true;
    } catch (e) {
      debugPrint('Error update course di Supabase: $e');
      return false;
    }
  }

  static Future<bool> deleteCourse(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('courses').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete course dari Supabase: $e');
      return false;
    }
  }

  static Future<List<ResourceItem>> getResources() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final rows = await client
        .from('resources')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => ResourceItem(
            id: row['id']?.toString() ?? '',
            courseName: row['course_name']?.toString() ?? '',
            pertemuanKe: (row['pertemuan_ke'] as num?)?.toInt(),
            judul: row['judul']?.toString() ?? '',
            jenis: row['jenis']?.toString() ?? 'Slide PPT',
            linkUrl: row['link_url']?.toString() ?? '',
          ),
        )
        .toList();
  }

  static Future<ResourceItem> createResource(ResourceItem item) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final row = await client
        .from('resources')
        .insert({
          'course_name': item.courseName,
          'pertemuan_ke': item.pertemuanKe,
          'judul': item.judul,
          'jenis': item.jenis,
          'link_url': item.linkUrl,
        })
        .select()
        .single();
    return ResourceItem(
      id: row['id']?.toString() ?? '',
      courseName: row['course_name']?.toString() ?? item.courseName,
      pertemuanKe: (row['pertemuan_ke'] as num?)?.toInt() ?? item.pertemuanKe,
      judul: row['judul']?.toString() ?? item.judul,
      jenis: row['jenis']?.toString() ?? item.jenis,
      linkUrl: row['link_url']?.toString() ?? item.linkUrl,
    );
  }

  static Future<void> deleteResource(String id) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    await client.from('resources').delete().eq('id', id);
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

      DummyData.announcements
        ..clear()
        ..addAll(list);
      return list;
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
    if (client == null) return false;
    try {
      final res = await client
          .from('announcements')
          .insert({
            'judul': judul,
            'isi': isi,
            'kategori': kategori,
            'is_pinned': isPinned,
            'author_name': authorName,
            'author_role': 'Ketua Kelas',
          })
          .select('id')
          .single();

      final newAnn = Announcement(
        id: res['id']?.toString() ?? '',
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
    } catch (e) {
      debugPrint('Sync announcement ke Supabase offline/error: $e');
      return false;
    }
  }

  static Future<bool> updateAnnouncement(Announcement announcement) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('announcements')
          .update({
            'judul': announcement.judul,
            'isi': announcement.isi,
            'kategori': announcement.kategori,
            'is_pinned': announcement.isPinned,
          })
          .eq('id', announcement.id)
          .select('id')
          .single();
      return true;
    } catch (e) {
      debugPrint('Error update announcement di Supabase: $e');
      return false;
    }
  }

  static Future<bool> deleteAnnouncement(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('announcements')
          .delete()
          .eq('id', id)
          .select('id')
          .single();
      DummyData.announcements.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      debugPrint('Sync delete announcement error: $e');
      return false;
    }
  }

  // ====================================================================
  // 3. TUGAS KELAS (ASSIGNMENTS)
  // ====================================================================
  static Future<List<Assignment>> getAssignments() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.assignments;

    try {
      final response = await client
          .from('assignments')
          .select()
          .order('deadline');

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
          // Completion is per student and is loaded from student_assignments.
          status: 'belum',
        );
      }).toList();

      DummyData.assignments
        ..clear()
        ..addAll(list);
      return list;
    } catch (e) {
      debugPrint('Error fetch assignments dari Supabase: $e');
      return DummyData.assignments;
    }
  }

  /// Loads assignments from Supabase without falling back to demo data.
  /// Use this on signed-in screens where showing stale sample work would be
  /// misleading.
  static Future<List<Assignment>> getAssignmentsStrict() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');

    final response = await client
        .from('assignments')
        .select()
        .order('deadline');
    final assignments = (response as List).map((row) {
      return Assignment(
        id: row['id']?.toString() ?? '',
        courseId: row['course_id']?.toString() ?? '',
        courseName: row['course_name']?.toString() ?? 'Mata Kuliah',
        judul: row['judul']?.toString() ?? '',
        deskripsi: row['deskripsi']?.toString() ?? '',
        kategori: row['kategori']?.toString() ?? 'Individu',
        deadline:
            DateTime.tryParse(row['deadline']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 3)),
        linkPengumpulan: row['link_pengumpulan']?.toString(),
        status: 'belum',
      );
    }).toList();

    DummyData.assignments
      ..clear()
      ..addAll(assignments);
    return assignments;
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
    if (client == null) return false;
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

      final res = await client
          .from('assignments')
          .insert(payload)
          .select('id')
          .single();
      final assignedId = res['id']?.toString() ?? '';

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
    } catch (e) {
      debugPrint('Sync assignment ke Supabase error: $e');
      return false;
    }
  }

  static Future<bool> updateAssignment(Assignment assignment) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('assignments')
          .update({
            'judul': assignment.judul,
            'course_id': assignment.courseId,
            'course_name': assignment.courseName,
            'deskripsi': assignment.deskripsi,
            'kategori': assignment.kategori,
            'deadline': assignment.deadline.toIso8601String(),
            'link_pengumpulan': assignment.linkPengumpulan,
          })
          .eq('id', assignment.id)
          .select('id')
          .single();
      return true;
    } catch (e) {
      debugPrint('Error update assignment di Supabase: $e');
      return false;
    }
  }

  static Future<bool> updateAssignmentStatus(
    String id,
    String status, {
    required String studentNim,
    String? submissionUrl,
    String? notes,
  }) async {
    final client = SupabaseService.client;
    if (client == null || studentNim.isEmpty) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from('student_assignments').upsert({
        'assignment_id': id,
        'student_nim': studentNim,
        'status': status,
        if (submissionUrl != null) 'link_pengumpulan': submissionUrl,
        if (notes != null) 'catatan': notes,
        if (status == 'dikumpulkan') 'submitted_at': now,
        'updated_at': now,
      }, onConflict: 'assignment_id,student_nim');
      return true;
    } catch (e) {
      debugPrint('Error update status assignment di Supabase: $e');
      return false;
    }
  }

  static Future<List<StudentProfile>> getClassDirectory() async {
    final client = SupabaseService.client;
    if (client == null) return DummyData.students;
    try {
      final rows = await client.rpc('get_class_directory');
      final students = (rows as List)
          .map(
            (row) => StudentProfile(
              id: row['id']?.toString() ?? '',
              nim: row['nim']?.toString() ?? '',
              nama: row['nama']?.toString() ?? '',
              email: '',
              noWa: row['no_wa']?.toString() ?? '',
              peminatan: row['peminatan']?.toString() ?? '',
              prodi: row['prodi']?.toString() ?? 'Ilmu Komunikasi',
              semester: (row['semester'] as num?)?.toInt() ?? 1,
              kelas: row['kelas']?.toString() ?? 'Ilmu Komunikasi',
              role: row['role']?.toString() ?? 'MAHASISWA',
              jabatan: row['jabatan']?.toString() ?? 'Mahasiswa',
              isAktif: row['is_aktif'] as bool? ?? true,
              instagram: row['instagram']?.toString(),
              linkedin: row['linkedin']?.toString(),
            ),
          )
          .toList();
      DummyData.students
        ..clear()
        ..addAll(students);
      return students;
    } catch (e) {
      debugPrint('Error fetch class directory: $e');
      return const [];
    }
  }

  static Future<Map<String, String>> getPersonalAssignmentStatuses(
    String studentNim,
  ) async {
    final client = SupabaseService.client;
    if (client == null || studentNim.isEmpty) return const {};
    try {
      final rows = await client
          .from('student_assignments')
          .select('assignment_id,status')
          .eq('student_nim', studentNim);
      return {
        for (final row in rows as List)
          row['assignment_id'].toString(): row['status'].toString(),
      };
    } catch (e) {
      debugPrint('Error fetch personal assignment statuses: $e');
      return const {};
    }
  }

  static Future<Map<String, String>> getPersonalAssignmentStatusesStrict(
    String studentNim,
  ) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    if (studentNim.isEmpty) {
      throw ArgumentError.value(studentNim, 'studentNim', 'NIM wajib diisi.');
    }
    final rows = await client
        .from('student_assignments')
        .select('assignment_id,status')
        .eq('student_nim', studentNim);
    return {
      for (final row in rows as List)
        row['assignment_id'].toString(): row['status'].toString(),
    };
  }

  static Future<Map<String, dynamic>?> getPersonalAssignmentSubmission(
    String assignmentId,
    String studentNim,
  ) async {
    final client = SupabaseService.client;
    if (client == null || studentNim.isEmpty) return null;
    try {
      return await client
          .from('student_assignments')
          .select(
            'link_pengumpulan,catatan,submitted_at,status,nilai,umpan_balik,graded_at',
          )
          .eq('assignment_id', assignmentId)
          .eq('student_nim', studentNim)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetch personal assignment submission: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final rows = await client
        .from('student_assignments')
        .select(
          'student_nim,status,link_pengumpulan,catatan,submitted_at,nilai,umpan_balik,graded_at',
        )
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false, nullsFirst: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> gradeAssignmentSubmission({
    required String assignmentId,
    required String studentNim,
    required double grade,
    required String feedback,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    if (grade < 0 || grade > 100) {
      throw ArgumentError.value(grade, 'grade', 'Nilai harus 0 sampai 100.');
    }
    await client
        .from('student_assignments')
        .update({
          'nilai': grade,
          'umpan_balik': feedback.trim().isEmpty ? null : feedback.trim(),
          'status': 'dinilai',
          'graded_by': client.auth.currentUser?.id,
          'graded_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('assignment_id', assignmentId)
        .eq('student_nim', studentNim);
  }

  static Future<String> uploadAssignmentSubmissionFile({
    required String assignmentId,
    required String studentNim,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$studentNim/$assignmentId/${DateTime.now().toUtc().millisecondsSinceEpoch}_$safeName';
    await client.storage
        .from('assignment-submissions')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    return path;
  }

  static Future<String> createAssignmentSubmissionSignedUrl(String path) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    return client.storage
        .from('assignment-submissions')
        .createSignedUrl(path, 60 * 60 * 24 * 7);
  }

  static Future<bool> deleteAssignment(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('assignments')
          .delete()
          .eq('id', id)
          .select('id')
          .single();
      DummyData.assignments.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      debugPrint('Error delete assignment dari Supabase: $e');
      return false;
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

      DummyData.treasuryTransactions
        ..clear()
        ..addAll(list);
      return list;
    } catch (e) {
      debugPrint('Error fetch treasury dari Supabase: $e');
      return DummyData.treasuryTransactions;
    }
  }

  static Future<bool> createTreasuryTransaction(
    TreasuryTransaction item,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return false;

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
      return false;
    }
  }

  static Future<bool> updateTreasuryTransaction(
    TreasuryTransaction item,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('treasury_transactions')
          .update({
            'judul': item.judul,
            'nominal': item.nominal,
            'is_pemasukan': item.isPemasukan,
            'kategori': item.kategori,
          })
          .eq('id', item.id);
      return true;
    } catch (e) {
      debugPrint('Error update treasury di Supabase: $e');
      return false;
    }
  }

  static Future<bool> deleteTreasuryTransaction(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('treasury_transactions').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete treasury dari Supabase: $e');
      return false;
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
    if (client == null) return false;

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
      return false;
    }
  }

  static Future<bool> deleteAgendaItem(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('agenda_items').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error delete agenda dari Supabase: $e');
      return false;
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
      // Resolve UUID if courseId is course name or short code
      String resolvedCourseId = courseId;
      final matchedCourse = DummyData.courses.firstWhere(
        (c) =>
            c.id == courseId || c.nama.toLowerCase() == courseId.toLowerCase(),
        orElse: () => DummyData.courses.first,
      );
      if (resolvedCourseId.length != 36) {
        resolvedCourseId = matchedCourse.id;
      }

      final normalizedStatus = status
          .toLowerCase(); // 'hadir', 'izin', 'sakit', 'alpa'

      await client.from('attendance_logs').insert({
        'course_id': resolvedCourseId,
        'student_nim': studentNim,
        'pertemuan_ke': pertemuanKe,
        'status': normalizedStatus,
        'catatan': catatan,
      });
      return true;
    } catch (e) {
      debugPrint('Error log attendance ke Supabase: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceLogs({
    String? studentNim,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return [];

    try {
      var query = client
          .from('attendance_logs')
          .select('*, courses(nama_mk, kode_mk)');
      if (studentNim != null && studentNim.isNotEmpty) {
        query = query.eq('student_nim', studentNim);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetch attendance logs: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceLogsStrict({
    String? studentNim,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final dynamic response = studentNim == null
        ? await client
              .from('attendance_logs')
              .select('*, courses(nama_mk, kode_mk)')
              .order('created_at', ascending: false)
        : await client
              .from('attendance_logs')
              .select('*, courses(nama_mk, kode_mk)')
              .eq('student_nim', studentNim)
              .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  static Future<bool> clearAttendanceLogs({String? studentNim}) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      if (studentNim != null && studentNim.isNotEmpty) {
        await client
            .from('attendance_logs')
            .delete()
            .eq('student_nim', studentNim);
      } else {
        await client
            .from('attendance_logs')
            .delete()
            .neq('id', '00000000-0000-0000-0000-000000000000');
      }
      return true;
    } catch (e) {
      debugPrint('Error clear attendance logs: $e');
      return false;
    }
  }

  // ====================================================================
  // 7. MANAJEMEN AKUN & MAHASISWA (STUDENTS)
  // ====================================================================
  static Future<bool> updateStudentJabatan(String nim, String jabatan) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('students').update({'jabatan': jabatan}).eq('nim', nim);
      return true;
    } catch (e) {
      debugPrint('Error update jabatan di Supabase: $e');
      return false;
    }
  }

  static Future<bool> toggleStudentStatus(String nim, bool isAktif) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('students')
          .update({'is_aktif': isAktif})
          .eq('nim', nim);
      return true;
    } catch (e) {
      debugPrint('Error toggle status di Supabase: $e');
      return false;
    }
  }
}
