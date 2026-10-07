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
          'no_wa': noWa.trim(),
          'semester': semester,
          'peminatan': peminatan.trim(),
        },
      );

      if (response.status < 200 || response.status >= 300) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error']?.toString()
            : null;
        throw AdminAccountServiceException(
          message ?? 'Undangan akun gagal dikirim. Coba lagi.',
        );
      }
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map<String, dynamic>
          ? details['error']?.toString()
          : null;
      throw AdminAccountServiceException(
        message ?? 'Layanan pembuatan akun gagal dihubungi.',
      );
    } on AdminAccountServiceException {
      rethrow;
    } catch (_) {
      throw const AdminAccountServiceException(
        'Terjadi kendala saat membuat akun. Periksa koneksi lalu coba lagi.',
      );
    }
  }
}
