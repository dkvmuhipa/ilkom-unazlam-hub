import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import 'supabase_service.dart';

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) throw const AuthServiceException('Layanan autentikasi belum dikonfigurasi.');
    return client;
  }

  static bool get hasActiveSession => _client.auth.currentSession != null;

  static Future<void> setPassword(String password) async {
    if (!hasActiveSession) {
      throw const AuthServiceException(
        'Sesi undangan tidak ditemukan. Tautan mungkin sudah kedaluwarsa; minta administrator mengirim tautan baru.',
      );
    }
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  static Future<StudentProfile> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthServiceException('Login gagal.');

    try {
      final row = await _client
          .from('students')
          .select('id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin')
          .eq('auth_user_id', user.id)
          .single();
      return _profileFromRow(row);
    } catch (_) {
      await _client.auth.signOut();
      throw const AuthServiceException('Akun belum ditautkan ke profil mahasiswa. Hubungi administrator.');
    }
  }

  static Future<StudentProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await _client
          .from('students')
          .select('id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin')
          .eq('auth_user_id', user.id)
          .single();
      final profile = _profileFromRow(row);
      if (!profile.isAktif) {
        await _client.auth.signOut();
        return null;
      }
      return profile;
    } catch (_) {
      await _client.auth.signOut();
      return null;
    }
  }

  static StudentProfile _profileFromRow(Map<String, dynamic> row) {
    final profile = StudentProfile(
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
    if (profile.nim.isEmpty || profile.nama.isEmpty || !profile.isAktif) {
      throw const AuthServiceException('Akun mahasiswa tidak aktif atau profilnya tidak lengkap.');
    }
    return profile;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
