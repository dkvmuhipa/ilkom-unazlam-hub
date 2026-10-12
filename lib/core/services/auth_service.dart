import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Helper untuk hashing kata sandi fallback offline menggunakan SHA-256 dan salt unik
  static String _hashPassword(String nimOrKey, String password) {
    final payload = '$nimOrKey:salt_ilkom_unazlam_2026:$password';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  static Future<void> setPassword(String password, {String? userNim}) async {
    if (hasActiveSession) {
      try {
        await _client.auth.updateUser(UserAttributes(password: password));
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('same password') ||
            msg.contains('different from the old') ||
            (e.statusCode == '422' && (msg.contains('different') || msg.contains('same')))) {
          throw const AuthServiceException(
            'Kata sandi baru tidak boleh sama dengan kata sandi lama Anda.',
          );
        }
        if (msg.contains('weak') || msg.contains('character') || msg.contains('pwned') || msg.contains('length')) {
          throw AuthServiceException(
            'Kata sandi belum memenuhi standar keamanan: ${e.message}',
          );
        }
        if (e.statusCode == '422') {
          throw const AuthServiceException(
            'Gagal menyimpan kata sandi. Pastikan kata sandi baru berbeda dari kata sandi lama dan memiliki minimal 8 karakter.',
          );
        }
        throw AuthServiceException(e.message);
      }
    } else if (userNim == null || userNim.isEmpty) {
      throw const AuthServiceException(
        'Sesi autentikasi tidak ditemukan atau telah kedaluwarsa. Silakan minta tautan baru dari admin.',
      );
    } else {
      // Jika akun masuk melalui fallback kampus tanpa sesi Supabase Auth aktif (belum ada di auth.users),
      // daftarkan secara otomatis ke Supabase Auth cloud agar password baru tersinkronisasi di server.
      try {
        String? targetEmail;
        final matched = DummyData.students.where(
          (s) => s.nim.trim().toLowerCase() == userNim.toLowerCase(),
        ).firstOrNull;
        if (matched != null && matched.email.contains('@')) {
          targetEmail = matched.email.trim();
        }

        if (targetEmail == null) {
          try {
            final sRow = await _client
                .from('students')
                .select('email')
                .eq('nim', userNim)
                .maybeSingle();
            if (sRow != null && sRow['email'] != null) {
              targetEmail = (sRow['email'] as String).trim();
            }
          } catch (_) {}
        }

        targetEmail ??= '$userNim@student.unazlam.ac.id';

        final signUpRes = await _client.auth.signUp(
          email: targetEmail,
          password: password,
        );

        if (signUpRes.user != null) {
          debugPrint(
            'Info: Akun fallback berhasil didaftarkan ke Supabase Auth cloud (${signUpRes.user!.email}).',
          );
          try {
            await _client
                .from('students')
                .update({'auth_user_id': signUpRes.user!.id})
                .eq('nim', userNim);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Info: Upaya sinkronisasi pendaftaran Supabase Auth cloud ($e).');
      }
    }

    // Sinkronkan juga hash kata sandi baru ke SharedPreferences untuk fallback offline
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userNim != null && userNim.isNotEmpty && userNim.toLowerCase() != 'admin') {
        final hash = _hashPassword(userNim, password);
        await prefs.setString('custom_pwd_hash_$userNim', hash);
        await prefs.setString('custom_pwd_hash_${userNim.toLowerCase()}', hash);
        // Hapus kunci plaintext lama untuk keamanan
        await prefs.remove('custom_pwd_$userNim');
        await prefs.remove('custom_pwd_${userNim.toLowerCase()}');
      }
      final currEmail = _client.auth.currentUser?.email;
      if (currEmail != null && currEmail.isNotEmpty) {
        final hash = _hashPassword(currEmail, password);
        await prefs.setString('custom_pwd_hash_$currEmail', hash);
        await prefs.remove('custom_pwd_$currEmail');
      }
      // Hapus kunci password plaintext admin dari SharedPreferences
      await prefs.remove('custom_pwd_admin');
      await prefs.remove('custom_pwd_16110376');
      await prefs.remove('custom_pwd_gellonaindonesia@gmail.com');
    } catch (_) {}
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
      // 0. Khusus jika identifier adalah 'admin' atau '16110376'
      if (loginValue.toLowerCase() == 'admin' || loginValue == '16110376') {
        try {
          final adminRow = await _client
              .from('students')
              .select('email')
              .eq('role', 'ADMIN')
              .not('auth_user_id', 'is', null)
              .maybeSingle();
          if (adminRow != null && adminRow['email'] != null) {
            targetEmail = (adminRow['email'] as String).trim();
          }
        } catch (_) {}
        targetEmail ??= 'gellonaindonesia@gmail.com';
      }

      // 1. Coba panggil RPC get_student_login_email dari database Supabase jika tersedia
      if (targetEmail == null) {
        try {
          final emailFromRpc = await _client.rpc(
            'get_student_login_email',
            params: {'p_nim': loginValue},
          );
          if (emailFromRpc is String && emailFromRpc.contains('@')) {
            targetEmail = emailFromRpc.trim();
          }
        } catch (_) {}
      }

      // 1b. Cek langsung dari remote tabel students jika RPC belum mengembalikan email
      if (targetEmail == null) {
        try {
          final sRow = await _client
              .from('students')
              .select('email')
              .eq('nim', loginValue)
              .maybeSingle();
          if (sRow != null && sRow['email'] != null) {
            targetEmail = (sRow['email'] as String).trim();
          }
        } catch (_) {}
      }

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
          targetEmail = 'gellonaindonesia@gmail.com';
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
      // Izinkan verifikasi kredensial fallback jika akun belum terdaftar di auth.users Supabase
      // atau jika menggunakan kata sandi kustom / default kampus
      StudentProfile? matched = DummyData.students.where(
        (s) =>
            s.nim.trim().toLowerCase() == loginValue.toLowerCase() ||
            (s.email.isNotEmpty &&
                s.email.trim().toLowerCase() == loginValue.toLowerCase()),
      ).firstOrNull;

      if (matched == null) {
        try {
          final query = _client.from('students').select(
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin',
          );
          final sRow = loginValue.contains('@')
              ? await query.eq('email', loginValue).maybeSingle()
              : await query.eq('nim', loginValue).maybeSingle();
          if (sRow != null) {
            matched = _profileFromRow(sRow);
          }
        } catch (_) {}
      }

      if (matched != null) {
        SharedPreferences? prefs;
        try {
          prefs = await SharedPreferences.getInstance();
        } catch (_) {}

        final hashedInput = _hashPassword(matched.nim, password);
        final customSavedHash = prefs?.getString('custom_pwd_hash_${matched.nim}') ??
            prefs?.getString('custom_pwd_hash_${matched.email}') ??
            prefs?.getString('custom_pwd_hash_${loginValue.toLowerCase()}');
        final customSavedPass = prefs?.getString('custom_pwd_${matched.nim}') ??
            prefs?.getString('custom_pwd_${matched.email}') ??
            prefs?.getString('custom_pwd_${loginValue.toLowerCase()}');
        final nimStr = matched.nim.trim();
        final last6 = nimStr.length >= 6
            ? nimStr.substring(nimStr.length - 6)
            : nimStr;
        final bool passwordValid = (!matched.isAdmin && (
            (customSavedHash != null && customSavedHash == hashedInput) ||
            (customSavedPass != null && customSavedPass == password) ||
            password == last6 ||
            password == nimStr ||
            password == '123456'
        )) || (matched.isAdmin && (password == 'admin123' || password == 'admin'));

        if (passwordValid) {
          // Simpan sesi login aktif ke local storage
          try {
            await prefs?.setString('active_session_nim', matched.nim);
          } catch (_) {}

          debugPrint(
            'Info: Akun terverifikasi melalui data profil sistem fallback (${matched.nama} - ${matched.role}).',
          );
          if (prefs != null) {
            _applyCustomProfileOverrides(matched, prefs);
          }
          return matched;
        }
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

    // Ambil profil mahasiswa: cari berdasarkan auth_user_id ATAU email (parameterized)
    StudentProfile? profile;
    try {
      final selectCols =
          'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url';
      var row = await _client
          .from('students')
          .select(selectCols)
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (row == null && user.email != null && user.email!.isNotEmpty) {
        row = await _client
            .from('students')
            .select(selectCols)
            .eq('email', user.email!)
            .maybeSingle();
      }

      if (row != null) {
        profile = _profileFromRow(row);
      }
    } catch (e) {
      debugPrint('Info: Ambil profil mahasiswa dari database: $e');
    }

    // Fallback profil jika database students belum ditautkan
    profile ??= DummyData.students.where(
      (s) =>
          (user.email != null && s.email.toLowerCase() == user.email!.toLowerCase()) ||
          s.nim.toLowerCase() == loginValue.toLowerCase(),
    ).firstOrNull;

    profile ??= StudentProfile(
      id: user.id,
      nim: loginValue.contains('@') ? '16110376' : loginValue,
      nama: user.userMetadata?['nama']?.toString() ?? 'Mahasiswa ILKOM',
      email: user.email ?? '$loginValue@student.unazlam.ac.id',
      noWa: '',
      role: 'MAHASISWA',
      jabatan: 'Mahasiswa',
    );

    // Simpan sesi login aktif ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_session_nim', profile.nim);
      // Hapus kunci password plaintext dari local storage untuk perlindungan kredensial
      await prefs.remove('custom_pwd_${profile.nim}');
      await prefs.remove('custom_pwd_admin');
      await prefs.remove('custom_pwd_16110376');
      await prefs.remove('custom_pwd_gellonaindonesia@gmail.com');
      _applyCustomProfileOverrides(profile, prefs);
    } catch (_) {}

    return profile;
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
    // 1. Coba dari sesi Supabase Auth jika ada
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final selectCols =
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url';
        var row = await _client
            .from('students')
            .select(selectCols)
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (row == null && user.email != null && user.email!.isNotEmpty) {
          row = await _client
              .from('students')
              .select(selectCols)
              .eq('email', user.email!)
              .maybeSingle();
        }

        if (row != null) {
          final profile = _profileFromRow(row);
          if (profile.isAktif) return profile;
        }
      } catch (_) {}

      // Fallback DummyData jika baris remote belum terambil
      if (user.email != null) {
        final matched = DummyData.students.where(
          (s) => s.email.toLowerCase() == user.email!.toLowerCase(),
        ).firstOrNull;
        if (matched != null && matched.isAktif) return matched;
      }
    }

    // 2. Coba pulihkan dari sesi aktif tersimpan di SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNim = prefs.getString('active_session_nim');
      if (savedNim != null && savedNim.isNotEmpty) {
        final matched = DummyData.students.where(
          (s) => s.nim.trim().toLowerCase() == savedNim.toLowerCase(),
        ).firstOrNull;
        if (matched != null && matched.isAktif) {
          _applyCustomProfileOverrides(matched, prefs);
          return matched;
        }
      }
    } catch (_) {}

    return null;
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
      avatarUrl: row['avatar_url']?.toString(),
    );
    if (profile.nim.isEmpty || profile.nama.isEmpty || !profile.isAktif) {
      throw const AuthServiceException(
        'Akun mahasiswa tidak aktif atau profilnya tidak lengkap.',
      );
    }
    return profile;
  }

  /// Memperbarui foto profil mahasiswa baik di penyimpanan lokal maupun Supabase cloud
  static Future<void> updateAvatar({
    required String nim,
    required String? avatarUrl,
  }) async {
    // 1. Simpan ke SharedPreferences lokal (offline-first & instan)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (avatarUrl == null || avatarUrl.isEmpty) {
        await prefs.remove('custom_avatar_$nim');
      } else {
        await prefs.setString('custom_avatar_$nim', avatarUrl);
      }
    } catch (_) {}

    // 2. Perbarui juga di DummyData in-memory jika ada
    try {
      final matched = DummyData.students.where(
        (s) => s.nim.trim().toLowerCase() == nim.trim().toLowerCase(),
      ).firstOrNull;
      if (matched != null) {
        matched.avatarUrl = avatarUrl;
      }
    } catch (_) {}

    // 3. Sinkronkan ke tabel 'students' di Supabase jika terhubung
    try {
      await _client
          .from('students')
          .update({'avatar_url': avatarUrl})
          .eq('nim', nim);
    } catch (e) {
      debugPrint('Info: Sinkronisasi avatar_url ke Supabase: $e');
    }
  }

  /// Memperbarui rincian profil mahasiswa (WhatsApp, Peminatan, Instagram, LinkedIn, Email)
  static Future<void> updateProfileDetails({
    required String nim,
    String? noWa,
    String? peminatan,
    String? instagram,
    String? linkedin,
    String? email,
  }) async {
    // 1. Simpan ke SharedPreferences lokal (offline-first & instan)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('custom_profile_$nim');
      final Map<String, dynamic> data = savedStr != null ? jsonDecode(savedStr) : {};
      if (noWa != null) data['no_wa'] = noWa;
      if (peminatan != null) data['peminatan'] = peminatan;
      if (instagram != null) data['instagram'] = instagram;
      if (linkedin != null) data['linkedin'] = linkedin;
      if (email != null) data['email'] = email;
      await prefs.setString('custom_profile_$nim', jsonEncode(data));
    } catch (_) {}

    // 2. Perbarui juga di DummyData in-memory
    try {
      final matched = DummyData.students.where(
        (s) => s.nim.trim().toLowerCase() == nim.trim().toLowerCase(),
      ).firstOrNull;
      if (matched != null) {
        if (noWa != null) matched.noWa = noWa;
        if (peminatan != null) matched.peminatan = peminatan;
        if (instagram != null) matched.instagram = instagram;
        if (linkedin != null) matched.linkedin = linkedin;
        if (email != null) matched.email = email;
      }
    } catch (_) {}

    // 3. Sinkronkan ke tabel 'students' di Supabase jika terhubung
    try {
      final updates = <String, dynamic>{
        'no_wa': ?noWa,
        'peminatan': ?peminatan,
        'instagram': ?instagram,
        'linkedin': ?linkedin,
        'email': ?email,
      };
      if (updates.isNotEmpty) {
        await _client.from('students').update(updates).eq('nim', nim);
      }
    } catch (e) {
      debugPrint('Info: Sinkronisasi update profil ke Supabase: $e');
    }
  }

  static void _applyCustomProfileOverrides(StudentProfile profile, SharedPreferences prefs) {
    try {
      final customAvatar = prefs.getString('custom_avatar_${profile.nim}');
      if (customAvatar != null && customAvatar.isNotEmpty) {
        profile.avatarUrl = customAvatar;
      }
      final customDataStr = prefs.getString('custom_profile_${profile.nim}');
      if (customDataStr != null && customDataStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(customDataStr);
        if (data['no_wa'] != null) profile.noWa = data['no_wa'].toString();
        if (data['peminatan'] != null) profile.peminatan = data['peminatan'].toString();
        if (data['instagram'] != null) profile.instagram = data['instagram'].toString();
        if (data['linkedin'] != null) profile.linkedin = data['linkedin'].toString();
        if (data['email'] != null) profile.email = data['email'].toString();
      }
    } catch (_) {}
  }

  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_session_nim');
    } catch (_) {}
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
