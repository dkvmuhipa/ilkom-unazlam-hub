import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Supabase persistence for academic master data managed by administrators.
class AdminAcademicService {
  static dynamic get _client {
    final client = SupabaseService.client;
    if (client == null) throw const AdminAcademicException('Supabase belum terhubung.');
    return client;
  }

  static Future<List<Map<String, dynamic>>> listClasses() async {
    try {
      final rows = await _client.from('academic_classes').select().order('nama').order('semester');
      return List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Gagal memuat kelas: $error');
      throw AdminAcademicException(_message(error));
    }
  }

  static Future<void> saveClass({String? id, required String nama, required String prodi, required int semester, required String academicYear, required int capacity}) async {
    try {
      final payload = {'nama': nama, 'prodi': prodi, 'semester': semester, 'academic_year': academicYear, 'kapasitas': capacity};
      if (id == null) {
        await _client.from('academic_classes').insert(payload);
      } else {
        await _client.from('academic_classes').update(payload).eq('id', id);
      }
    } catch (error) {
      throw AdminAcademicException(_message(error));
    }
  }

  static Future<void> deleteClass(String id) async {
    try { await _client.from('academic_classes').delete().eq('id', id); }
    catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static Future<List<Map<String, dynamic>>> listLecturers() async {
    try {
      final rows = await _client.from('lecturers').select().order('nama');
      return List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Gagal memuat dosen: $error');
      throw AdminAcademicException(_message(error));
    }
  }

  static Future<void> saveLecturer({String? id, required String nama, required String email, required String course}) async {
    try {
      final payload = {'nama': nama, 'email': email, 'mata_kuliah': course};
      if (id == null) {
        await _client.from('lecturers').insert(payload);
      } else {
        await _client.from('lecturers').update(payload).eq('id', id);
      }
    } catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static Future<void> deleteLecturer(String id) async {
    try { await _client.from('lecturers').delete().eq('id', id); }
    catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static Future<List<Map<String, dynamic>>> listAcademicYears() async {
    try {
      final rows = await _client.from('academic_years').select().order('tahun', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Gagal memuat tahun akademik: $error');
      throw AdminAcademicException(_message(error));
    }
  }

  static Future<void> saveAcademicYear({String? id, required String year}) async {
    try {
      if (id == null) {
        await _client.from('academic_years').insert({'tahun': year});
      } else {
        await _client.from('academic_years').update({'tahun': year}).eq('id', id);
      }
    } catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static Future<void> setActiveAcademicYear(String id) async {
    try { await _client.rpc('set_active_academic_year', params: {'target_id': id}); }
    catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static Future<void> deleteAcademicYear(String id) async {
    try { await _client.from('academic_years').delete().eq('id', id); }
    catch (error) { throw AdminAcademicException(_message(error)); }
  }

  static String _message(Object error) {
    final value = error.toString();
    if (value.contains('academic_classes') || value.contains('academic_years') || value.contains('lecturers') || value.contains('set_active_academic_year')) {
      return 'Struktur data akademik belum diterapkan. Jalankan supabase_migrations/20261008_admin_operations.sql di Supabase SQL Editor.';
    }
    return value.replaceFirst('Exception: ', '');
  }
}

class AdminAcademicException implements Exception {
  final String message;
  const AdminAcademicException(this.message);
  @override
  String toString() => message;
}
