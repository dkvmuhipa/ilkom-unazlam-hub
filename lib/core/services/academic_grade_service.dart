import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import 'supabase_service.dart';

class AcademicGradeService {
  static const Map<String, double> gradePoints = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  static Future<List<StudentCourseGrade>> listGrades(String studentNim) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    if (studentNim.isEmpty) throw ArgumentError('NIM mahasiswa wajib diisi.');

    final rows = await client
        .from('student_course_grades')
        .select()
        .eq('student_nim', studentNim)
        .order('academic_year', ascending: false)
        .order('semester');
    return List<Map<String, dynamic>>.from(rows)
        .map(StudentCourseGrade.fromMap)
        .toList();
  }

  static Future<List<StudentProfile>> listStudents() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    final rows = await client
        .from('students')
        .select('nim,nama,semester,prodi,kelas')
        .eq('is_aktif', true)
        .neq('role', 'ADMIN')
        .order('nama');
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => StudentProfile(
            id: row['nim']?.toString() ?? '',
            nim: row['nim']?.toString() ?? '',
            nama: row['nama']?.toString() ?? '',
            email: '',
            noWa: '',
            semester: (row['semester'] as num?)?.toInt() ?? 1,
            prodi: row['prodi']?.toString() ?? 'Ilmu Komunikasi',
            kelas: row['kelas']?.toString() ?? '',
          ),
        )
        .toList();
  }

  static Future<void> saveGrade({
    required StudentProfile student,
    required Course course,
    required int semester,
    required String academicYear,
    required String letterGrade,
    double? numericScore,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    if (student.nim.isEmpty || course.id.isEmpty) {
      throw ArgumentError('Mahasiswa dan mata kuliah wajib dipilih.');
    }
    if (semester < 1 || semester > 16) {
      throw ArgumentError('Semester harus antara 1 sampai 16.');
    }
    if (academicYear.trim().isEmpty) {
      throw ArgumentError('Tahun akademik wajib diisi.');
    }
    if (!gradePoints.containsKey(letterGrade)) {
      throw ArgumentError('Nilai huruf tidak dikenal.');
    }
    if (numericScore != null && (numericScore < 0 || numericScore > 100)) {
      throw ArgumentError('Nilai angka harus antara 0 sampai 100.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await client.from('student_course_grades').upsert({
      'student_nim': student.nim,
      'course_id': course.id,
      'course_code': course.kode,
      'course_name': course.nama,
      'sks': course.sks,
      'semester': semester,
      'academic_year': academicYear.trim(),
      'nilai_angka': numericScore,
      'nilai_huruf': letterGrade,
      'updated_by': client.auth.currentUser?.id,
      'updated_at': now,
    }, onConflict: 'student_nim,course_id,semester,academic_year');
  }
}
