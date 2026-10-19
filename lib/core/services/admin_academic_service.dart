import 'package:flutter/foundation.dart';
import 'supabase_service.dart';


/// Supabase persistence with local fallback for academic master data managed by administrators.
class AdminAcademicService {
  static final List<Map<String, dynamic>> _localClasses = [
    {
      'id': 'cls_1',
      'nama': 'Ilmu Komunikasi A (Reguler)',
      'prodi': 'Ilmu Komunikasi',
      'semester': 1,
      'academic_year': '2026/2027',
      'kapasitas': 35,
      'is_aktif': true,
    },
    {
      'id': 'cls_2',
      'nama': 'Ilmu Komunikasi B (Malam)',
      'prodi': 'Ilmu Komunikasi',
      'semester': 1,
      'academic_year': '2026/2027',
      'kapasitas': 30,
      'is_aktif': true,
    },
  ];

  static final List<Map<String, dynamic>> _localLecturers = [
    {
      'id': 'lec_1',
      'nama': 'Drs. H. M. Rusli, M.Si',
      'email': 'rusli@unazlam.ac.id',
      'mata_kuliah': 'Pendidikan Pancasila',
      'is_aktif': true,
    },
    {
      'id': 'lec_2',
      'nama': 'Dra. Hj. Nurhaida, M.Pd',
      'email': 'nurhaida@unazlam.ac.id',
      'mata_kuliah': 'Pendidikan Kewarganegaraan',
      'is_aktif': true,
    },
    {
      'id': 'lec_3',
      'nama': 'Dr. H. Lukman Hakim, M.Ag',
      'email': 'lukman@unazlam.ac.id',
      'mata_kuliah': 'Pendidikan Agama Islam',
      'is_aktif': true,
    },
    {
      'id': 'lec_4',
      'nama': 'Farid Wajdi, S.Pd., M.A',
      'email': 'farid@unazlam.ac.id',
      'mata_kuliah': 'Bahasa Inggris',
      'is_aktif': true,
    },
  ];

  static final List<Map<String, dynamic>> _localAcademicYears = [
    {
      'id': 'ay_1',
      'tahun': '2026/2027',
      'is_aktif': true,
    },
    {
      'id': 'ay_2',
      'tahun': '2025/2026',
      'is_aktif': false,
    },
  ];

  static dynamic get _client {
    return SupabaseService.client;
  }

  static Future<List<Map<String, dynamic>>> listClasses() async {
    final client = _client;
    if (client == null) return List.from(_localClasses);

    try {
      final rows = await client.from('academic_classes').select().order('nama').order('semester');
      final list = List<Map<String, dynamic>>.from(rows);
      _localClasses.clear();
      _localClasses.addAll(list);
      return list;
    } catch (error) {
      debugPrint('Gagal memuat kelas dari Supabase ($error), menggunakan cache lokal.');
      return List.from(_localClasses);
    }
  }

  static Future<void> saveClass({
    String? id,
    String? oldNama,
    required String nama,
    required String prodi,
    required int semester,
    required String academicYear,
    required int capacity,
  }) async {
    final payload = {
      'nama': nama,
      'prodi': prodi,
      'semester': semester,
      'academic_year': academicYear,
      'kapasitas': capacity,
      'is_aktif': true,
    };

    final client = _client;
    if (client == null) {
      if (id == null) {
        final newId = 'cls_${DateTime.now().millisecondsSinceEpoch}';
        _localClasses.add({'id': newId, ...payload});
      } else {
        final idx = _localClasses.indexWhere((c) => c['id']?.toString() == id);
        if (idx != -1) {
          _localClasses[idx] = {'id': id, ...payload};
        }
      }
      return;
    }

    try {
      if (id == null) {
        final res = await client.from('academic_classes').insert(payload).select().single();
        final createdId = res['id']?.toString();
        _localClasses.add({'id': createdId ?? 'cls_${DateTime.now().millisecondsSinceEpoch}', ...payload});
      } else {
        await client.from('academic_classes').update(payload).eq('id', id);
        final idx = _localClasses.indexWhere((c) => c['id']?.toString() == id);
        if (idx != -1) {
          _localClasses[idx] = {'id': id, ...payload};
        }
        // Pembaruan kaskade ke tabel mahasiswa jika nama kelas berubah
        final cleanOld = oldNama?.trim();
        final cleanNew = nama.trim();
        if (cleanOld != null && cleanOld.isNotEmpty && cleanOld != cleanNew) {
          try {
            await client.from('students').update({'kelas': cleanNew}).eq('kelas', cleanOld);
          } catch (cascadeError) {
            debugPrint('Warning: gagal update kaskade nama kelas mahasiswa: $cascadeError');
          }
        }
      }
    } catch (error) {
      debugPrint('Error save class di Supabase: $error');
      throw AdminAcademicException('Gagal menyimpan kelas ke Supabase: $error');
    }
  }

  static Future<void> deleteClass(String id) async {
    _localClasses.removeWhere((c) => c['id']?.toString() == id);

    final client = _client;
    if (client == null) return;

    try {
      await client.from('academic_classes').delete().eq('id', id);
    } catch (error) {
      debugPrint('Error delete class di Supabase: $error');
      throw AdminAcademicException('Gagal menghapus kelas dari Supabase: $error');
    }
  }

  /// Memasukkan banyak mahasiswa ke dalam kelas tertentu secara massal (Batch Update)
  static Future<int> assignStudentsToClass({
    required String targetClass,
    required List<String> studentNims,
  }) async {
    if (studentNims.isEmpty) return 0;
    final client = _client;
    if (client == null) return studentNims.length;

    try {
      await client
          .from('students')
          .update({'kelas': targetClass.trim()})
          .inFilter('nim', studentNims);
      return studentNims.length;
    } catch (error) {
      debugPrint('Error bulk assign students to class: $error');
      throw AdminAcademicException('Gagal memasukkan mahasiswa ke kelas: $error');
    }
  }

  /// Mengeluarkan mahasiswa dari kelas (mengosongkan atribut kelas)
  static Future<void> removeStudentFromClass(String nim) async {
    final client = _client;
    if (client == null) return;

    try {
      await client
          .from('students')
          .update({'kelas': ''})
          .eq('nim', nim);
    } catch (error) {
      debugPrint('Error removing student from class: $error');
      throw AdminAcademicException('Gagal mengeluarkan mahasiswa dari kelas: $error');
    }
  }

  static Future<List<Map<String, dynamic>>> listLecturers() async {
    final client = _client;
    if (client == null) return List.from(_localLecturers);

    try {
      final rows = await client.from('lecturers').select().order('nama');
      final list = List<Map<String, dynamic>>.from(rows);
      _localLecturers.clear();
      _localLecturers.addAll(list);
      return list;
    } catch (error) {
      debugPrint('Gagal memuat dosen dari Supabase ($error), menggunakan data default.');
      return List.from(_localLecturers);
    }
  }

  static Future<void> saveLecturer({
    String? id,
    required String nama,
    required String email,
    required String course,
  }) async {
    final payload = {
      'nama': nama,
      'email': email,
      'mata_kuliah': course,
      'is_aktif': true,
    };

    final client = _client;
    if (client == null) {
      if (id == null) {
        final newId = 'lec_${DateTime.now().millisecondsSinceEpoch}';
        _localLecturers.add({'id': newId, ...payload});
      } else {
        final idx = _localLecturers.indexWhere((l) => l['id']?.toString() == id);
        if (idx != -1) {
          _localLecturers[idx] = {'id': id, ...payload};
        }
      }
      return;
    }

    try {
      if (id == null) {
        final res = await client.from('lecturers').insert(payload).select().single();
        final createdId = res['id']?.toString();
        _localLecturers.add({'id': createdId ?? 'lec_${DateTime.now().millisecondsSinceEpoch}', ...payload});
      } else {
        await client.from('lecturers').update(payload).eq('id', id);
        final idx = _localLecturers.indexWhere((l) => l['id']?.toString() == id);
        if (idx != -1) {
          _localLecturers[idx] = {'id': id, ...payload};
        }
      }
    } catch (error) {
      debugPrint('Error save lecturer di Supabase: $error');
      throw AdminAcademicException('Gagal menyimpan dosen ke Supabase: $error');
    }
  }

  static Future<void> deleteLecturer(String id) async {
    _localLecturers.removeWhere((l) => l['id']?.toString() == id);

    final client = _client;
    if (client == null) return;

    try {
      await client.from('lecturers').delete().eq('id', id);
    } catch (error) {
      debugPrint('Error delete lecturer di Supabase: $error');
      throw AdminAcademicException('Gagal menghapus dosen dari Supabase: $error');
    }
  }

  static Future<List<Map<String, dynamic>>> listAcademicYears() async {
    final client = _client;
    if (client == null) return List.from(_localAcademicYears);

    try {
      final rows = await client.from('academic_years').select().order('tahun', ascending: false);
      final list = List<Map<String, dynamic>>.from(rows);
      _localAcademicYears.clear();
      _localAcademicYears.addAll(list);
      return list;
    } catch (error) {
      debugPrint('Gagal memuat tahun akademik dari Supabase ($error), menggunakan data default.');
      return List.from(_localAcademicYears);
    }
  }

  static Future<void> saveAcademicYear({String? id, required String year}) async {
    final client = _client;
    if (client == null) {
      if (id == null) {
        final newId = 'ay_${DateTime.now().millisecondsSinceEpoch}';
        _localAcademicYears.add({'id': newId, 'tahun': year, 'is_aktif': false});
      } else {
        final idx = _localAcademicYears.indexWhere((y) => y['id']?.toString() == id);
        if (idx != -1) {
          _localAcademicYears[idx]['tahun'] = year;
        }
      }
      return;
    }

    try {
      if (id == null) {
        final res = await client.from('academic_years').insert({'tahun': year, 'is_aktif': false}).select().single();
        final createdId = res['id']?.toString();
        _localAcademicYears.add({'id': createdId ?? 'ay_${DateTime.now().millisecondsSinceEpoch}', 'tahun': year, 'is_aktif': false});
      } else {
        await client.from('academic_years').update({'tahun': year}).eq('id', id);
        final idx = _localAcademicYears.indexWhere((y) => y['id']?.toString() == id);
        if (idx != -1) {
          _localAcademicYears[idx]['tahun'] = year;
        }
      }
    } catch (error) {
      debugPrint('Error save academic year di Supabase: $error');
      throw AdminAcademicException('Gagal menyimpan tahun akademik ke Supabase: $error');
    }
  }

  static Future<void> setActiveAcademicYear(String id) async {
    for (var y in _localAcademicYears) {
      y['is_aktif'] = (y['id']?.toString() == id);
    }

    final client = _client;
    if (client == null) return;

    try {
      await client.rpc('set_active_academic_year', params: {'target_id': id});
    } catch (_) {
      try {
        await client.from('academic_years').update({'is_aktif': false}).neq('id', id);
        await client.from('academic_years').update({'is_aktif': true}).eq('id', id);
      } catch (e) {
        debugPrint('Error set active academic year: $e');
        throw AdminAcademicException('Gagal mengubah tahun akademik aktif: $e');
      }
    }
  }

  static Future<void> deleteAcademicYear(String id) async {
    _localAcademicYears.removeWhere((y) => y['id']?.toString() == id);

    final client = _client;
    if (client == null) return;

    try {
      await client.from('academic_years').delete().eq('id', id);
    } catch (error) {
      debugPrint('Error delete academic year: $error');
      throw AdminAcademicException('Gagal menghapus tahun akademik dari Supabase: $error');
    }
  }
}

class AdminAcademicException implements Exception {
  final String message;
  const AdminAcademicException(this.message);
  @override
  String toString() => message;
}
