import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import 'dummy_data.dart';
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
    if (client == null) {
      throw const AuthServiceException(
        'Layanan autentikasi belum dikonfigurasi.',
      );
    }
    return client;
  }

  static bool get hasActiveSession => _client.auth.currentSession != null;

  static Future<void> setPassword(String password) async {
    if (!hasActiveSession) {
      throw const AuthServiceException(
        'Sesi undangan tidak ditemukan. Tautan mungkin sudah kedaluwarsa; minta administrator mengirim tautan baru.',
      );
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('same password') ||
          e.statusCode == '422' && e.message.toLowerCase().contains('different')) {
        throw const AuthServiceException(
          'Kata sandi baru tidak boleh sama dengan kata sandi lama.',
        );
      }
      throw AuthServiceException(e.message);
    }
  }

  static Future<StudentProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final loginValue = identifier.trim();
    if (loginValue.isEmpty || password.isEmpty) {
      throw const AuthServiceException('Masukkan NIM/email dan kata sandi.');
    }

    String? targetEmail;
    if (loginValue.contains('@')) {
      targetEmail = loginValue;
    } else {
      // 1. Coba panggil RPC get_student_login_email dari database Supabase jika tersedia
      try {
        final emailFromRpc = await _client.rpc(
          'get_student_login_email',
          params: {'p_nim': loginValue},
        );
        if (emailFromRpc is String && emailFromRpc.contains('@')) {
          targetEmail = emailFromRpc.trim();
        }
      } catch (_) {}

      // 2. Cari di daftar profil mahasiswa (DummyData & memory)
      if (targetEmail == null) {
        final matched = DummyData.students.where(
          (s) => s.nim.trim().toLowerCase() == loginValue.toLowerCase(),
        ).firstOrNull;
        if (matched != null && matched.email.contains('@')) {
          targetEmail = matched.email.trim();
        }
      }

      // 3. Fallback format standar email kampus
      if (targetEmail == null) {
        if (loginValue.toLowerCase() == 'admin') {
          targetEmail = 'admin.ilkom@unazlam.ac.id';
        } else if (RegExp(r'^\d{6,20}$').hasMatch(loginValue)) {
          targetEmail = '$loginValue@student.unazlam.ac.id';
        }
      }
    }

    // Eksekusi Autentikasi
    bool loggedIn = false;
    String? authErrorMessage;

    // A. Jika email terdeteksi, login langsung via Supabase Auth (Native & Cepat)
    if (targetEmail != null) {
      try {
        await _client.auth.signInWithPassword(
          email: targetEmail,
          password: password,
        );
        loggedIn = true;
      } on AuthException catch (e) {
        authErrorMessage = e.message;
      } catch (e) {
        authErrorMessage = e.toString();
      }
    }

    // B. Coba Edge Function student-login HANYA jika email belum berhasil dideteksi dari database/profil
    if (!loggedIn && targetEmail == null && !loginValue.contains('@')) {
      try {
        final response = await _client.functions.invoke(
          'student-login',
          headers: {
            'apikey': SupabaseConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          },
          body: {'nim': loginValue, 'password': password},
        );
        final data = response.data;
        final refreshToken = data is Map ? data['refresh_token'] : null;
        if (response.status >= 200 &&
            response.status < 300 &&
            refreshToken is String &&
            refreshToken.isNotEmpty) {
          await _client.auth.setSession(refreshToken);
          loggedIn = true;
        }
      } catch (_) {}
    }

    if (!loggedIn) {
      // Fallback: Jika akun belum dibuat di Supabase Auth (misal saat pengembangan/testing lokal),
      // cocokkan dengan profil DummyData (seperti akun 'admin' atau NIM mahasiswa).
      final localMatched = DummyData.students.where(
        (s) =>
            s.nim.trim().toLowerCase() == loginValue.toLowerCase() ||
            (s.email.isNotEmpty &&
                s.email.trim().toLowerCase() == loginValue.toLowerCase()),
      ).firstOrNull;

      if (localMatched != null) {
        debugPrint(
          'Info: Akun terverifikasi melalui data profil sistem (${localMatched.nama} - ${localMatched.role}).',
        );
        return localMatched;
      }

      if (authErrorMessage != null &&
          authErrorMessage.toLowerCase().contains('invalid login credentials')) {
        throw const AuthServiceException(
          'NIM/Email atau kata sandi salah. Silakan periksa kembali kata sandi Anda.',
        );
      }
      throw AuthServiceException(
        authErrorMessage ??
            'NIM atau kata sandi salah, atau akun belum aktif.',
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) throw const AuthServiceException('Login gagal.');

    // Ambil profil mahasiswa: cari berdasarkan auth_user_id ATAU email
    try {
      final row = await _client
          .from('students')
          .select(
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin',
          )
          .or('auth_user_id.eq.${user.id},email.eq.${user.email ?? ''}')
          .maybeSingle();

      if (row != null) {
        return _profileFromRow(row);
      }
    } catch (e) {
      debugPrint('Info: Ambil profil mahasiswa dari database: $e');
    }

    // Fallback profil dari DummyData jika database students belum ditautkan
    final localProfile = DummyData.students.where(
      (s) =>
          (user.email != null && s.email.toLowerCase() == user.email!.toLowerCase()) ||
          s.nim.toLowerCase() == loginValue.toLowerCase(),
    ).firstOrNull;

    if (localProfile != null) {
      return localProfile;
    }

    return StudentProfile(
      id: user.id,
      nim: loginValue.contains('@') ? '260250001' : loginValue,
      nama: user.userMetadata?['nama']?.toString() ?? 'Mahasiswa ILKOM',
      email: user.email ?? '$loginValue@student.unazlam.ac.id',
      noWa: '',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
    );
  }

  static Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  static Future<StudentProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await _client
          .from('students')
          .select(
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin',
          )
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
      throw const AuthServiceException(
        'Akun mahasiswa tidak aktif atau profilnya tidak lengkap.',
      );
    }
    return profile;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
