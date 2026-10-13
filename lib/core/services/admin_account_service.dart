import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import 'supabase_service.dart';

class AdminAccountServiceException implements Exception {
  final String message;

  const AdminAccountServiceException(this.message);

  @override
  String toString() => message;
}

class AdminAccountService {
  static Future<List<StudentProfile>> listStudentAccounts() async {
    final client = SupabaseService.client;
    if (client == null) {
      throw const AdminAccountServiceException(
        'Layanan Supabase belum dikonfigurasi.',
      );
    }

    try {
      final rows = await client
          .from('students')
          .select(
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin',
          )
          .order('nama');
      return (rows as List).map((row) {
        return StudentProfile(
          id: row['id']?.toString() ?? '',
          nim: row['nim']?.toString() ?? '',
          nama: row['nama']?.toString() ?? '',
          email: row['email']?.toString() ?? '',
          noWa: row['no_wa']?.toString() ?? '',
          peminatan: row['peminatan']?.toString() ?? '',
          prodi: row['prodi']?.toString() ?? 'Ilmu Komunikasi',
          semester: (row['semester'] as num?)?.toInt() ?? 1,
          kelas: row['kelas']?.toString() ?? 'Ilmu Komunikasi',
          role: row['role']?.toString() ?? 'MAHASISWA',
          jabatan: row['jabatan']?.toString() ?? 'Mahasiswa',
          isAktif: row['is_aktif'] as bool? ?? false,
          instagram: row['instagram']?.toString(),
          linkedin: row['linkedin']?.toString(),
        );
      }).toList();
    } catch (_) {
      throw const AdminAccountServiceException(
        'Daftar akun gagal dimuat. Pastikan Anda masuk sebagai admin aktif.',
      );
    }
  }

  static Future<void> createStudentAccount({
    required String nama,
    required String nim,
    required String email,
    required String initialPassword,
    required int semester,
    required String peminatan,
    String noWa = '',
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw const AdminAccountServiceException(
        'Layanan Supabase belum dikonfigurasi.',
      );
    }

    final accessToken = client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AdminAccountServiceException(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      final response = await client.functions.invoke(
        'admin-create-student',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'nama': nama.trim(),
          'nim': nim.trim(),
          'email': email.trim().toLowerCase(),
          'initial_password': initialPassword,
          'no_wa': noWa.trim(),
          'semester': semester,
          'peminatan': peminatan.trim(),
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw FunctionException(
          status: response.status,
          details: response.data,
          reasonPhrase: 'Function returned non-200',
        );
      }
    } catch (funcErr) {
      debugPrint(
        'Admin create student edge function unavailable ($funcErr), applying direct database fallback.',
      );
      try {
        await client.from('students').insert({
          'nim': nim.trim(),
          'nama': nama.trim(),
          'email': email.trim().toLowerCase(),
          'no_wa': noWa.trim(),
          'semester': semester,
          'peminatan': peminatan.trim(),
          'prodi': 'Ilmu Komunikasi',
          'kelas': 'Ilmu Komunikasi',
          'role': 'MAHASISWA',
          'jabatan': 'Mahasiswa',
          'is_aktif': true,
        });
      } catch (insertErr) {
        debugPrint('Direct insert student error: $insertErr');
        throw AdminAccountServiceException('Gagal menambahkan mahasiswa ke Supabase: $insertErr');
      }
    }
  }

  static Future<void> updateStudentAccount(StudentProfile account) async {
    final client = SupabaseService.client;
    if (client == null) {
      return;
    }

    try {
      final rows = await client
          .from('students')
          .update({
            'nama': account.nama.trim(),
            'no_wa': account.noWa.trim(),
            'peminatan': account.peminatan.trim(),
            'semester': account.semester,
            'kelas': account.kelas.trim(),
          })
          .eq('nim', account.nim)
          .select('nim');
      if (rows.isEmpty) {
        debugPrint('Warning: Akun tidak ditemukan di Supabase saat update.');
      }
    } on AdminAccountServiceException {
      rethrow;
    } catch (e) {
      debugPrint('Error updating student in Supabase: $e');
      throw AdminAccountServiceException('Gagal memperbarui data akun di Supabase: $e');
    }
  }

  static Future<void> setStudentActive(String nim, bool isActive) async {
    final client = SupabaseService.client;
    if (client == null) {
      return;
    }

    try {
      final rows = await client
          .from('students')
          .update({'is_aktif': isActive})
          .eq('nim', nim)
          .select('nim');
      if (rows.isEmpty) {
        debugPrint('Warning: Status akun tidak berubah di Supabase.');
      }
    } on AdminAccountServiceException {
      rethrow;
    } catch (e) {
      debugPrint('Error updating student status in Supabase: $e');
      throw AdminAccountServiceException('Gagal mengubah status aktif mahasiswa di Supabase: $e');
    }
  }

  static Future<void> deleteStudentAccount(String nim) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      await client.from('students').delete().eq('nim', nim.trim());
    } catch (e) {
      debugPrint('Error deleting student from Supabase: $e');
      throw AdminAccountServiceException('Gagal menghapus mahasiswa dari Supabase: $e');
    }
  }
}

