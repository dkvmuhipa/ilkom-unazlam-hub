import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, PostgresChangeEvent, RealtimeChannel;

import '../../models/models.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class SupabaseRepository {
  // ====================================================================
  // SUPABASE REALTIME SUBSCRIPTIONS
  // ====================================================================

  /// Mendaftarkan listener realtime database Supabase untuk tabel tertentu
  static RealtimeChannel? subscribeToTable({
    required String table,
    required VoidCallback onDataChanged,
  }) {
    final client = SupabaseService.client;
    if (client == null) return null;
    try {
      final channelName = 'realtime_${table}_${DateTime.now().microsecondsSinceEpoch}';
      final channel = client.channel(channelName);
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          debugPrint('⚡ [Supabase Realtime] Perubahan terdeteksi di tabel $table (${payload.eventType})');
          onDataChanged();
        },
      ).subscribe();
      return channel;
    } catch (e) {
      debugPrint('Error mendaftar realtime channel untuk $table: $e');
      return null;
    }
  }

  /// Menghapus listener realtime saat widget di-dispose
  static Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (channel == null) return;
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await client.removeChannel(channel);
    } catch (e) {
      debugPrint('Error unsubscribe realtime channel: $e');
    }
  }

  /// Realtime stream listener untuk Pengumuman
  static RealtimeChannel? subscribeToAnnouncements(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'announcements', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Tugas Kelas
  static RealtimeChannel? subscribeToAssignments(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'assignments', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Status Pengumpulan Tugas Mahasiswa
  static RealtimeChannel? subscribeToStudentAssignments(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'student_assignments', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Kas Kelas (Transaksi)
  static RealtimeChannel? subscribeToTreasury(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'treasury_transactions', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Iuran Kas Mahasiswa
  static RealtimeChannel? subscribeToTreasuryDues(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'treasury_dues', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Sesi Presensi
  static RealtimeChannel? subscribeToAttendanceSessions(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'attendance_sessions', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Catatan Kehadiran
  static RealtimeChannel? subscribeToAttendanceRecords(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'attendance_records', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Mata Kuliah & Jadwal
  static RealtimeChannel? subscribeToCourses(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'courses', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Berkas & Materi Kuliah
  static RealtimeChannel? subscribeToResources(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'resources', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Agenda Kelas
  static RealtimeChannel? subscribeToAgenda(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'agenda_items', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Mahasiswa & Profil
  static RealtimeChannel? subscribeToStudents(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'students', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Arsip Surat Izin
  static RealtimeChannel? subscribeToPermissionLetters(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'permission_letters', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Polling Kelas
  static RealtimeChannel? subscribeToPolls(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'polls', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Suara Voting
  static RealtimeChannel? subscribeToPollVotes(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'poll_votes', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Kelas Akademik
  static RealtimeChannel? subscribeToAcademicClasses(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'academic_classes', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Dosen Pengampu
  static RealtimeChannel? subscribeToLecturers(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'lecturers', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Tahun Akademik
  static RealtimeChannel? subscribeToAcademicYears(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'academic_years', onDataChanged: onDataChanged);
  }

  /// Realtime stream listener untuk Audit Logs
  static RealtimeChannel? subscribeToAuditLogs(VoidCallback onDataChanged) {
    return subscribeToTable(table: 'audit_logs', onDataChanged: onDataChanged);
  }

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
    if (client == null) return [];

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

      return list;
    } catch (e) {
      debugPrint('Error fetch courses dari Supabase: $e');
      return [];
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
      try {
        await client.from('assignments').update({'course_id': null}).eq('course_id', id);
      } catch (_) {}
      try {
        await client.from('attendance_sessions').update({'course_id': null}).eq('course_id', id);
      } catch (_) {}
      try {
        await client.from('attendance_logs').update({'course_id': null}).eq('course_id', id);
      } catch (_) {}
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
    if (client == null) return;
    try {
      await client.from('resources').delete().eq('id', id);
    } catch (e) {
      debugPrint('Sync delete resource error: $e');
    }
  }

  // ====================================================================
  // 2. PENGUMUMAN KELAS (ANNOUNCEMENTS)
  // ====================================================================
  static Future<List<Announcement>> getAnnouncements() async {
    final client = SupabaseService.client;
    if (client == null) return [];

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

      return list;
    } catch (e) {
      debugPrint('Error fetch announcements dari Supabase: $e');
      return [];
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
      await client
          .from('announcements')
          .insert({
            'judul': judul,
            'isi': isi,
            'kategori': kategori,
            'is_pinned': isPinned,
            'author_name': authorName,
            'author_role': 'Ketua Kelas',
          });

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
          .eq('id', announcement.id);
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
      await client.from('announcements').delete().eq('id', id);
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
    if (client == null) return [];

    try {
      final response = await client
          .from('assignments')
          .select('*, courses(nama_mk)')
          .order('deadline');

      final list = (response as List).map((row) {
        String cName = row['course_name']?.toString() ?? '';
        final cId = row['course_id']?.toString() ?? '';
        if (cName.isEmpty && row['courses'] != null && row['courses'] is Map) {
          cName = (row['courses']['nama_mk'] ?? '').toString();
        }
        if (cName.isEmpty) cName = 'Mata Kuliah';

        return Assignment(
          id: row['id']?.toString() ?? '',
          courseId: cId,
          courseName: cName,
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

      return list;
    } catch (e) {
      debugPrint('Error fetch assignments dari Supabase: $e');
      return [];
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
        .select('*, courses(nama_mk)')
        .order('deadline');
    return (response as List).map((row) {
      String cName = row['course_name']?.toString() ?? '';
      final cId = row['course_id']?.toString() ?? '';
      if (cName.isEmpty && row['courses'] != null && row['courses'] is Map) {
        cName = (row['courses']['nama_mk'] ?? '').toString();
      }
      if (cName.isEmpty) cName = 'Mata Kuliah';

      return Assignment(
        id: row['id']?.toString() ?? '',
        courseId: cId,
        courseName: cName,
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
      String? resolvedCourseId;
      if (courseId.isNotEmpty && courseId.length == 36) {
        resolvedCourseId = courseId;
      }

      final payload = <String, dynamic>{
        'course_name': courseName,
        'judul': judul,
        'deskripsi': deskripsi,
        'kategori': kategori,
        'deadline': deadline.toIso8601String(),
        'link_pengumpulan': linkPengumpulan,
        'status': 'belum',
      };
      if (resolvedCourseId != null && resolvedCourseId.length == 36) {
        payload['course_id'] = resolvedCourseId;
      }

      try {
        await client.from('assignments').insert(payload);
      } catch (insertErr) {
        // Fallback jika skema di Supabase belum memiliki kolom course_name/status
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..remove('course_name')
          ..remove('status');
        await client.from('assignments').insert(fallbackPayload);
      }

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
      String? resolvedCourseId;
      if (assignment.courseId.isNotEmpty && assignment.courseId.length == 36) {
        resolvedCourseId = assignment.courseId;
      }

      final payload = <String, dynamic>{
        'judul': assignment.judul,
        'course_name': assignment.courseName,
        'deskripsi': assignment.deskripsi,
        'kategori': assignment.kategori,
        'deadline': assignment.deadline.toIso8601String(),
        'link_pengumpulan': assignment.linkPengumpulan,
      };

      if (resolvedCourseId != null && resolvedCourseId.length == 36) {
        payload['course_id'] = resolvedCourseId;
      }

      try {
        final res = await client
            .from('assignments')
            .update(payload)
            .eq('id', assignment.id)
            .select('id');
        if ((res as List).isEmpty) {
          debugPrint('Peringatan: 0 baris diperbarui di Supabase untuk assignment ${assignment.id}');
          return false;
        }
      } catch (updateErr) {
        // Fallback jika kolom course_name belum ada di skema
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..remove('course_name');
        final resFallback = await client
            .from('assignments')
            .update(fallbackPayload)
            .eq('id', assignment.id)
            .select('id');
        if ((resFallback as List).isEmpty) {
          debugPrint('Peringatan: 0 baris diperbarui di Supabase (fallback) untuk assignment ${assignment.id}');
          return false;
        }
      }

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
        'link_pengumpulan': ?submissionUrl,
        'catatan': ?notes,
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
    if (client == null) return [];
    try {
      return await getClassDirectoryStrict();
    } catch (e) {
      debugPrint('Info fetch class directory dari Supabase: $e');
      return [];
    }
  }

  static Future<List<StudentProfile>> getClassDirectoryStrict() async {
    final client = SupabaseService.client;
    if (client == null) return [];

    List<StudentProfile> result = [];

    // 1. Coba RPC get_class_directory
    try {
      final rows = await client.rpc('get_class_directory');
      if (rows is List && rows.isNotEmpty) {
        result = rows
            .map(
              (row) {
                final rawEmail = row['email']?.toString().trim() ?? '';
                final cleanEmail = rawEmail;
                return StudentProfile(
                  id: row['id']?.toString() ?? '',
                  nim: row['nim']?.toString() ?? '',
                  nama: row['nama']?.toString() ?? '',
                  email: cleanEmail,
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
                );
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Warning: get_class_directory RPC gagal ($e).');
    }

    // 2. Jika RPC mengembalikan kosong atau gagal, query langsung tabel students
    if (result.isEmpty) {
      try {
        final rows = await client
            .from('students')
            .select(
              'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin',
            )
            .eq('is_aktif', true)
            .order('nama');
        if (rows.isNotEmpty) {
          result = rows
              .map(
                (row) {
                  final rawEmail = row['email']?.toString().trim() ?? '';
                  final cleanEmail = rawEmail;
                  return StudentProfile(
                    id: row['id']?.toString() ?? '',
                    nim: row['nim']?.toString() ?? '',
                    nama: row['nama']?.toString() ?? '',
                    email: cleanEmail,
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
                  );
                },
              )
              .toList();
        }
      } catch (e) {
        debugPrint('Warning: query langsung tabel students gagal ($e).');
      }
    }

    // 3. Terapkan local storage overrides (custom profile) jika ada
    if (result.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        for (final profile in result) {
          AuthService.applyCustomProfileOverrides(profile, prefs);
        }
      } catch (_) {}
    }

    return result;
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
      // 1. Hapus catatan student_assignments terkait terlebih dahulu agar tidak terkunci foreign key
      try {
        await client
            .from('student_assignments')
            .delete()
            .eq('assignment_id', id);
      } catch (saErr) {
        debugPrint('Catatan student_assignments delete info: $saErr');
      }

      // 2. Hapus dari tabel assignments
      await client
          .from('assignments')
          .delete()
          .eq('id', id);

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
    if (client == null) return [];

    try {
      return await getTreasuryTransactionsStrict();
    } catch (e) {
      debugPrint('Error fetch treasury dari Supabase: $e');
      return [];
    }
  }

  static Future<List<TreasuryTransaction>>
  getTreasuryTransactionsStrict() async {
    final client = SupabaseService.client;
    if (client == null) return [];

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
          pencatat: row['pencatat'] ?? 'Pengurus Kelas',
        );
      }).toList();
      return list;
    } catch (e) {
      debugPrint('Warning: getTreasuryTransactionsStrict gagal ($e).');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTreasuryDuesForPeriod(
    String period,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('treasury_dues')
          .select('student_nim,period,nominal,is_lunas,paid_at')
          .eq('period', period);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('Warning: getTreasuryDuesForPeriod gagal ($e), mengembalikan data lokal kosong.');
      return const [];
    }
  }

  static Future<bool> saveTreasuryDue({
    required String studentNim,
    required String period,
    required int nominal,
    required bool isPaid,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('treasury_dues').upsert({
        'student_nim': studentNim,
        'period': period,
        'nominal': nominal,
        'is_lunas': isPaid,
        'paid_at': isPaid ? DateTime.now().toUtc().toIso8601String() : null,
        'recorded_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'student_nim,period');
      return true;
    } catch (e) {
      debugPrint('Error menyimpan status iuran di Supabase: $e');
      return false;
    }
  }

  static Future<bool> createTreasuryTransaction(
    TreasuryTransaction item,
  ) async {
    final payload = <String, dynamic>{
      'judul': item.judul,
      'nominal': item.nominal,
      'is_pemasukan': item.isPemasukan,
      'kategori': item.kategori,
      'tanggal': item.tanggal.toIso8601String(),
      'pencatat': item.pencatat,
    };
    // Hanya sertakan id jika berupa UUID resmi 36 karakter
    if (item.id.isNotEmpty && item.id.length == 36 && !item.id.startsWith('tx_')) {
      payload['id'] = item.id;
    }

    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('treasury_transactions').insert(payload);
      return true;
    } catch (e) {
      debugPrint('Sync insert treasury ke Supabase error: $e');
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
  static Future<List<Map<String, dynamic>>> getAgendaItems() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum terhubung.');

    final rows = await client
        .from('agenda_items')
        .select('id,day,month,title,course,color_value,created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

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
      final payload = <String, dynamic>{
        'day': day,
        'month': month,
        'title': title,
        'course': course,
        'color_value': colorValue,
      };
      if (id.isNotEmpty && (id.length == 36 || !id.startsWith('ag_'))) {
        payload['id'] = id;
      }
      try {
        await client.from('agenda_items').insert(payload);
      } catch (_) {
        if (!payload.containsKey('id')) {
          payload['id'] = id;
          await client.from('agenda_items').insert(payload);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Sync insert agenda ke Supabase: $e');
      return true;
    }
  }

  static Future<bool> updateAgendaItem({
    required String id,
    required String title,
    required String course,
    required int colorValue,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client
          .from('agenda_items')
          .update({'title': title, 'course': course, 'color_value': colorValue})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error update agenda di Supabase: $e');
      return false;
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
  // 6. CATATAN PRESENSI & SESI KELAS (ATTENDANCE & SESSIONS)
  // ====================================================================
  static Future<Map<String, dynamic>?> createAttendanceSession({
    required String courseName,
    required int pertemuanKe,
    required String token,
    String? pinCode,
    required DateTime expiresAt,
    String? createdBy,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      // 1. Nonaktifkan sesi aktif sebelumnya agar tidak tumpang tindih
      try {
        await client
            .from('attendance_sessions')
            .update({'is_active': false})
            .eq('is_active', true);
      } catch (_) {}

      // 2. Cari course_id jika nama mata kuliah cocok dengan master courses
      String? resolvedCourseId;
      try {
        final cRes = await client
            .from('courses')
            .select('id')
            .eq('nama_mk', courseName.trim())
            .maybeSingle();
        if (cRes != null && cRes['id'] != null) {
          resolvedCourseId = cRes['id'].toString();
        }
      } catch (_) {}

      final numericPart = token.replaceAll(RegExp(r'\D'), '');
      final effectivePin = pinCode ??
          (numericPart.length >= 4
              ? numericPart.substring(numericPart.length - 4)
              : (token.length >= 4 ? token.substring(token.length - 4) : '1234'));

      final payload = <String, dynamic>{
        'course_name': courseName,
        'pertemuan_ke': pertemuanKe,
        'token': token,
        'pin_code': effectivePin,
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
        'created_by': createdBy,
      };
      if (resolvedCourseId != null) {
        payload['course_id'] = resolvedCourseId;
      }

      final res = await client
          .from('attendance_sessions')
          .insert(payload)
          .select()
          .single();

      return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('Error create attendance session di Supabase: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActiveAttendanceSession() async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      final nowIso = DateTime.now().toIso8601String();
      final res = await client
          .from('attendance_sessions')
          .select()
          .eq('is_active', true)
          .gt('expires_at', nowIso)
          .order('created_at', ascending: false)
          .limit(1);

      if ((res as List).isEmpty) return null;

      final sessionData = Map<String, dynamic>.from(res.first);

      // Ambil daftar NIM mahasiswa yang sudah hadir pada sesi ini dari attendance_logs
      try {
        final logs = await client
            .from('attendance_logs')
            .select('student_nim')
            .eq('pertemuan_ke', sessionData['pertemuan_ke'])
            .eq('status', 'hadir');

        final attendedNims = (logs as List)
            .map((row) => row['student_nim']?.toString() ?? '')
            .where((nim) => nim.isNotEmpty)
            .toSet()
            .toList();

        sessionData['attended_nims'] = attendedNims;
      } catch (_) {}

      return sessionData;
    } catch (e) {
      debugPrint('Error get active attendance session: $e');
      return null;
    }
  }

  static Future<bool> closeAttendanceSession({String? sessionId}) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await client
            .from('attendance_sessions')
            .update({'is_active': false})
            .eq('id', sessionId);
      } else {
        await client
            .from('attendance_sessions')
            .update({'is_active': false})
            .eq('is_active', true);
      }
      return true;
    } catch (e) {
      debugPrint('Error close attendance session: $e');
      return false;
    }
  }

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
      // Resolve UUID jika courseId adalah nama mata kuliah
      String? resolvedCourseId;
      if (courseId.length == 36) {
        resolvedCourseId = courseId;
      } else {
        try {
          final cRes = await client
              .from('courses')
              .select('id')
              .eq('nama_mk', courseId.trim())
              .maybeSingle();
          if (cRes != null && cRes['id'] != null) {
            resolvedCourseId = cRes['id'].toString();
          }
        } catch (_) {}
      }

      final normalizedStatus = status.toLowerCase(); // 'hadir', 'izin', 'sakit', 'alpa'

      // Cek apakah mahasiswa ini sudah tercatat presensi pada pertemuan ini untuk mencegah duplikasi
      try {
        var dupQuery = client
            .from('attendance_logs')
            .select('id')
            .eq('student_nim', studentNim)
            .eq('pertemuan_ke', pertemuanKe);
        if (resolvedCourseId != null) {
          dupQuery = dupQuery.eq('course_id', resolvedCourseId);
        }
        final existing = await dupQuery.limit(1);
        if ((existing as List).isNotEmpty) {
          final logId = existing.first['id'];
          await client.from('attendance_logs').update({
            'status': normalizedStatus,
            'catatan': catatan,
          }).eq('id', logId);
          return true;
        }
      } catch (_) {}

      final payload = <String, dynamic>{
        'student_nim': studentNim,
        'pertemuan_ke': pertemuanKe,
        'status': normalizedStatus,
        'catatan': catatan,
      };
      if (resolvedCourseId != null) {
        payload['course_id'] = resolvedCourseId;
      }

      await client.from('attendance_logs').insert(payload);
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

  // ====================================================================
  // 8. ARSIP SURAT IZIN (PERMISSION_LETTERS)
  // ====================================================================
  static Future<List<PermissionLetter>> getPermissionLetters({String? studentNim}) async {
    final client = SupabaseService.client;
    if (client == null) return [];

    try {
      dynamic query = client.from('permission_letters').select();
      if (studentNim != null && studentNim.isNotEmpty) {
        query = query.eq('student_nim', studentNim);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => PermissionLetter.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Error get permission letters from Supabase: $e');
      return [];
    }
  }

  static Future<PermissionLetter?> createPermissionLetter(PermissionLetter letter) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      final payload = letter.toMap();
      final res = await client.from('permission_letters').insert(payload).select().single();
      return PermissionLetter.fromMap(res);
    } catch (e) {
      debugPrint('Error creating permission letter in Supabase: $e');
      return null;
    }
  }

  static Future<bool> deletePermissionLetter(String id) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('permission_letters').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting permission letter in Supabase: $e');
      return false;
    }
  }

  // ====================================================================
  // 9. POLLING & VOTING (POLLS, POLL_OPTIONS, POLL_VOTES)
  // ====================================================================
  static Future<List<ClassPoll>> getPolls({String? currentNim}) async {
    final client = SupabaseService.client;
    if (client == null) return [];

    try {
      final pollsRes = await client.from('polls').select().order('created_at', ascending: false);
      final optionsRes = await client.from('poll_options').select().order('order_index', ascending: true);
      final votesRes = await client.from('poll_votes').select();

      final List<Map<String, dynamic>> votesList = List<Map<String, dynamic>>.from(votesRes as List);
      final List<Map<String, dynamic>> optionsList = List<Map<String, dynamic>>.from(optionsRes as List);

      final List<ClassPoll> loaded = [];
      for (final pollMap in (pollsRes as List)) {
        final pollId = pollMap['id']?.toString() ?? '';
        final pollOptions = optionsList.where((o) => o['poll_id']?.toString() == pollId).map((optMap) {
          final optId = optMap['id']?.toString() ?? '';
          final optVotes = votesList.where((v) => v['option_id']?.toString() == optId).toList();
          final voterNims = optVotes.map((v) => v['voter_nim']?.toString() ?? '').toList();
          return PollOption.fromMap(optMap, votesCount: optVotes.length, voters: voterNims);
        }).toList();

        String? userVoted;
        if (currentNim != null && currentNim.isNotEmpty) {
          final userVote = votesList.firstWhere(
            (v) => v['poll_id']?.toString() == pollId && v['voter_nim']?.toString() == currentNim,
            orElse: () => {},
          );
          if (userVote.isNotEmpty) {
            userVoted = userVote['option_id']?.toString();
          }
        }

        loaded.add(ClassPoll.fromMap(pollMap, pollOptions, userVotedId: userVoted));
      }

      return loaded;
    } catch (e) {
      debugPrint('Error get polls from Supabase: $e');
      return [];
    }
  }

  static Future<ClassPoll?> createPoll({
    required String title,
    required String description,
    required String author,
    required List<String> options,
    DateTime? endsAt,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      final pollRes = await client.from('polls').insert({
        'title': title.trim(),
        'description': description.trim(),
        'author': author.trim(),
        'is_open': true,
        'ends_at': (endsAt ?? DateTime.now().add(const Duration(days: 7))).toIso8601String(),
      }).select().single();

      final pollId = pollRes['id']?.toString() ?? '';
      final List<PollOption> createdOptions = [];

      for (int i = 0; i < options.length; i++) {
        final optRes = await client.from('poll_options').insert({
          'poll_id': pollId,
          'option_text': options[i].trim(),
          'order_index': i,
        }).select().single();
        createdOptions.add(PollOption.fromMap(optRes));
      }

      return ClassPoll.fromMap(pollRes, createdOptions);
    } catch (e) {
      debugPrint('Error creating poll in Supabase: $e');
      return null;
    }
  }

  static Future<bool> castPollVote({
    required String pollId,
    required String optionId,
    required String voterNim,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('poll_votes').delete().match({'poll_id': pollId, 'voter_nim': voterNim});
      await client.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'voter_nim': voterNim,
      });
      return true;
    } catch (e) {
      debugPrint('Error casting vote in Supabase: $e');
      return false;
    }
  }

  static Future<bool> deletePoll(String pollId) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    try {
      await client.from('polls').delete().eq('id', pollId);
      return true;
    } catch (e) {
      debugPrint('Error deleting poll in Supabase: $e');
      return false;
    }
  }
}

