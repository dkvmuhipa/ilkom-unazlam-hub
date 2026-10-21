import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        try {
          final sRow = await _client
              .from('students')
              .select('email, auth_user_id')
              .eq('nim', userNim)
              .maybeSingle();
            if (sRow != null) {
              if (sRow['email'] != null) {
                targetEmail = (sRow['email'] as String).trim();
              }
              if (sRow['auth_user_id'] != null) {
                throw const AuthServiceException(
                  'Sesi pemulihan telah kedaluwarsa. Silakan gunakan menu "Lupa Password" dari layar login untuk mendapatkan tautan pemulihan resmi.',
                );
              }
            }
          } on AuthServiceException {
            rethrow;
          } catch (_) {}

        if (targetEmail != null &&
            !targetEmail.endsWith('@student.unazlam.ac.id') &&
            !targetEmail.endsWith('@students.unazlam.ac.id')) {
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
    } else if (loginValue.toLowerCase() == 'admin' || loginValue == '16110376') {
      // 0. Akun Administrator Sistem
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
    } else {
      // 1. Mahasiswa login dengan NIM:
      // Validasi status akun dan deteksi email autentikasi dari tabel students Supabase
      Map<String, dynamic>? studentRow;
      try {
        studentRow = await _client
            .from('students')
            .select('id, nim, nama, email, auth_user_id, is_aktif')
            .eq('nim', loginValue)
            .maybeSingle();
      } catch (e) {
        debugPrint('Gagal membaca data mahasiswa dari Supabase: $e');
      }

      if (studentRow == null) {
        throw AuthServiceException(
          'NIM $loginValue tidak terdaftar di sistem UNAZLAM Hub.',
        );
      }

      final bool isAktif = studentRow['is_aktif'] as bool? ?? false;
      if (!isAktif) {
        throw AuthServiceException(
          'Akun mahasiswa dengan NIM $loginValue sedang dinonaktifkan.',
        );
      }

      final String? authUserId = studentRow['auth_user_id']?.toString();
      final String? registeredEmail = studentRow['email']?.toString().trim();

      if (authUserId == null || authUserId.isEmpty) {
        throw AuthServiceException(
          'Akun mahasiswa dengan NIM $loginValue belum diaktivasi. '
          'Silakan atur kata sandi akun Anda melalui menu "Lupa kata sandi?".',
        );
      }

      if (registeredEmail != null && registeredEmail.isNotEmpty) {
        targetEmail = registeredEmail;
      }
    }

    // Eksekusi Autentikasi Supabase Auth
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

    if (!loggedIn) {
      // Ambil profil mahasiswa dari database Supabase untuk verifikasi sandi kampus/hash
      StudentProfile? matched;
      try {
        final query = _client.from('students').select(
          'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url,bio',
        );
        final sRow = loginValue.contains('@')
            ? await query.eq('email', loginValue).maybeSingle()
            : await query.eq('nim', loginValue).maybeSingle();
        if (sRow != null) {
          matched = _profileFromRow(sRow);
        }
      } catch (_) {
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
        final bool passwordValid = (customSavedHash != null && customSavedHash == hashedInput) ||
            (customSavedPass != null && customSavedPass == password);

        if (passwordValid) {
          // Simpan sesi login aktif ke local storage
          try {
            await prefs?.setString('active_session_nim', matched.nim);
          } catch (_) {}

          debugPrint(
            'Info: Akun terverifikasi melalui data profil sistem fallback (${matched.nama} - ${matched.role}).',
          );
          if (prefs != null) {
            applyCustomProfileOverrides(matched, prefs);
          }
          return matched;
        }
      }

      if (authErrorMessage != null) {
        final errLower = authErrorMessage.toLowerCase();
        if (errLower.contains('invalid') ||
            errLower.contains('bad request') ||
            errLower.contains('credentials')) {
          throw const AuthServiceException(
            'NIM/Email atau kata sandi tidak cocok. Silakan periksa kembali kata sandi Anda.',
          );
        }
        throw AuthServiceException(authErrorMessage);
      }
      throw const AuthServiceException(
        'NIM atau kata sandi salah, atau akun belum aktif.',
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) throw const AuthServiceException('Login gagal.');

    // Ambil profil mahasiswa: cari berdasarkan auth_user_id ATAU email (parameterized)
    StudentProfile? profile;
    try {
      const selectCols =
          'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url,bio';
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
      try {
        const fallbackCols =
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin';
        var row = await _client
            .from('students')
            .select(fallbackCols)
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (row == null && user.email != null && user.email!.isNotEmpty) {
          row = await _client
              .from('students')
              .select(fallbackCols)
              .eq('email', user.email!)
              .maybeSingle();
        }

        if (row != null) {
          profile = _profileFromRow(row);
        }
      } catch (err) {
        debugPrint('Info: Ambil profil mahasiswa dari database: $err');
      }
    }

    profile ??= StudentProfile(
      id: user.id,
      nim: loginValue.contains('@') ? '16110376' : loginValue,
      nama: user.userMetadata?['nama']?.toString() ?? 'Mahasiswa ILKOM',
      email: user.email ?? '',
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
      applyCustomProfileOverrides(profile, prefs);
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

  /// Reset kata sandi mandiri mahasiswa dengan verifikasi data kontak (No WA / Email)
  /// dan pendaftaran email aktif mahasiswa (menggantikan domain @student.unazlam.ac.id yang belum ada)
  /// yang langsung memperbarui encrypted_password dan email di auth.users Supabase via RPC aman
  static Future<String> studentSelfResetPassword({
    required String nim,
    required String verificationContact,
    required String newPassword,
    String? activeEmail,
  }) async {
    final cleanNim = nim.trim();
    final cleanContact = verificationContact.trim();
    final cleanPass = newPassword.trim();
    final cleanEmail = activeEmail?.trim().toLowerCase();

    if (cleanNim.isEmpty || cleanContact.isEmpty || cleanPass.isEmpty) {
      throw const AuthServiceException(
        'NIM, nomor WhatsApp verifikasi, dan kata sandi baru wajib diisi.',
      );
    }
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      if (!cleanEmail.contains('@') ||
          !cleanEmail.contains('.') ||
          cleanEmail.endsWith('@student.unazlam.ac.id') ||
          cleanEmail.endsWith('@students.unazlam.ac.id')) {
        throw const AuthServiceException(
          'Harap gunakan alamat email aktif yang valid (misal: nama@gmail.com). Domain @student.unazlam.ac.id belum tersedia.',
        );
      }
    }
    if (cleanPass.length < 8) {
      throw const AuthServiceException(
        'Kata sandi baru minimal harus 8 karakter.',
      );
    }

    try {
      final res = await _client.rpc(
        'student_self_reset_password',
        params: {
          'p_nim': cleanNim,
          'p_verification': cleanContact,
          'p_new_password': cleanPass,
          'p_active_email': (cleanEmail != null && cleanEmail.isNotEmpty) ? cleanEmail : null,
        },
      );

      final Map<String, dynamic> resMap =
          res is Map ? Map<String, dynamic>.from(res) : {};
      final success = resMap['success'] == true;
      final message =
          resMap['message']?.toString() ?? 'Kata sandi berhasil diperbarui.';
      if (!success) {
        throw AuthServiceException(message);
      }

      // Sinkronkan hash kata sandi baru ke SharedPreferences untuk offline fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final hash = _hashPassword(cleanNim, cleanPass);
        await prefs.setString('custom_pwd_hash_$cleanNim', hash);
        await prefs.setString(
          'custom_pwd_hash_${cleanNim.toLowerCase()}',
          hash,
        );
        await prefs.remove('custom_pwd_$cleanNim');
      } catch (_) {}

      return message;
    } on PostgrestException catch (e) {
      throw AuthServiceException(e.message);
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException('Gagal mengatur ulang kata sandi: $e');
    }
  }

  static Future<StudentProfile?> restoreSession() async {
    // 1. Coba dari sesi Supabase Auth jika ada
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        const selectCols =
            'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url,bio';
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
          if (profile.isAktif) {
            try {
              final prefs = await SharedPreferences.getInstance();
              applyCustomProfileOverrides(profile, prefs);
            } catch (_) {}
            return profile;
          }
        }
      } catch (_) {
        try {
          const fallbackCols =
              'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin';
          var row = await _client
              .from('students')
              .select(fallbackCols)
              .eq('auth_user_id', user.id)
              .maybeSingle();

          if (row == null && user.email != null && user.email!.isNotEmpty) {
            row = await _client
                .from('students')
                .select(fallbackCols)
                .eq('email', user.email!)
                .maybeSingle();
          }

          if (row != null) {
            final profile = _profileFromRow(row);
            if (profile.isAktif) {
              final prefs = await SharedPreferences.getInstance();
              applyCustomProfileOverrides(profile, prefs);
              return profile;
            }
          }
        } catch (_) {}
      }
    }

    // 2. Coba pulihkan dari sesi aktif tersimpan di SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNim = prefs.getString('active_session_nim');
      if (savedNim != null && savedNim.isNotEmpty) {
        try {
          const selectCols =
              'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin,avatar_url,bio';
          final row = await _client
              .from('students')
              .select(selectCols)
              .eq('nim', savedNim)
              .maybeSingle();
          if (row != null) {
            final profile = _profileFromRow(row);
            if (profile.isAktif) {
              applyCustomProfileOverrides(profile, prefs);
              return profile;
            }
          }
        } catch (_) {
          try {
            const fallbackCols =
                'id,nim,nama,email,no_wa,peminatan,prodi,semester,kelas,role,jabatan,is_aktif,instagram,linkedin';
            final row = await _client
                .from('students')
                .select(fallbackCols)
                .eq('nim', savedNim)
                .maybeSingle();
            if (row != null) {
              final profile = _profileFromRow(row);
              if (profile.isAktif) {
                applyCustomProfileOverrides(profile, prefs);
                return profile;
              }
            }
          } catch (_) {}
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
      bio: row['bio']?.toString(),
      agama: row['agama']?.toString(),
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

    // 2. Sinkronkan ke tabel 'students' di Supabase cloud via RPC aman (SECURITY DEFINER)
    // agar tersimpan permanen di basis data dan tersinkronisasi lintas perangkat
    bool syncedViaRpc = false;
    try {
      final res = await _client.rpc(
        'update_student_profile',
        params: {
          'p_nim': nim.trim(),
          'p_avatar_url': avatarUrl,
        },
      );
      if (res is Map && res['success'] == true) {
        syncedViaRpc = true;
        debugPrint('Foto profil berhasil disinkronkan ke Supabase cloud via RPC.');
      }
    } catch (rpcErr) {
      debugPrint('Info RPC update_student_profile avatar: $rpcErr');
    }

    // Fallback: Jika RPC belum terpasang atau gagal, coba direct update
    if (!syncedViaRpc) {
      try {
        await _client
            .from('students')
            .update({'avatar_url': avatarUrl})
            .eq('nim', nim);
      } catch (e) {
        debugPrint('Info: Sinkronisasi avatar_url ke Supabase: $e');
      }
    }
  }

  /// Memperbarui rincian profil mahasiswa (WhatsApp, Peminatan, Instagram, LinkedIn, Email, Bio, Agama)
  static Future<void> updateProfileDetails({
    required String nim,
    String? noWa,
    String? peminatan,
    String? instagram,
    String? linkedin,
    String? email,
    String? bio,
    String? agama,
    String? namaPanggilan,
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
      if (bio != null) data['bio'] = bio;
      if (agama != null) data['agama'] = agama;
      if (namaPanggilan != null) data['nama_panggilan'] = namaPanggilan.trim();
      await prefs.setString('custom_profile_$nim', jsonEncode(data));
    } catch (_) {}

    // 2. Sinkronkan ke tabel 'students' di Supabase cloud via RPC aman (SECURITY DEFINER)
    // agar data kontak & email tersimpan permanen dan tersinkronisasi lintas perangkat
    bool syncedViaRpc = false;
    try {
      final res = await _client.rpc(
        'update_student_profile',
        params: {
          'p_nim': nim.trim(),
          'p_email': (email?.trim().isNotEmpty ?? false) ? email!.trim() : null,
          'p_no_wa': (noWa?.trim().isNotEmpty ?? false) ? noWa!.trim() : null,
          'p_peminatan': (peminatan?.trim().isNotEmpty ?? false) ? peminatan!.trim() : null,
          'p_instagram': (instagram?.trim().isNotEmpty ?? false) ? instagram!.trim() : null,
          'p_linkedin': (linkedin?.trim().isNotEmpty ?? false) ? linkedin!.trim() : null,
          'p_bio': bio?.trim(),
          'p_agama': (agama?.trim().isNotEmpty ?? false) ? agama!.trim() : null,
        },
      );
      if (res is Map && res['success'] == true) {
        syncedViaRpc = true;
        debugPrint('Rincian profil berhasil disinkronkan ke Supabase cloud via RPC.');
      }
    } catch (rpcErr) {
      debugPrint('Info RPC update_student_profile: $rpcErr');
    }

    // Fallback: Jika RPC belum tersedia, coba direct update
    if (!syncedViaRpc) {
      try {
        final client = SupabaseService.client;
        if (client != null) {
          final baseUpdates = <String, dynamic>{
            if (noWa != null) 'no_wa': noWa.trim(),
            if (peminatan != null) 'peminatan': peminatan.trim(),
            if (instagram != null) 'instagram': instagram.trim().isEmpty ? null : instagram.trim(),
            if (linkedin != null) 'linkedin': linkedin.trim().isEmpty ? null : linkedin.trim(),
            if (email != null) 'email': email.trim().isEmpty ? null : email.trim(),
          };

          // Coba sertakan bio, agama, dan nama_panggilan
          bool synced = false;
          if (bio != null || agama != null || namaPanggilan != null) {
            try {
              final updatesExtended = Map<String, dynamic>.from(baseUpdates);
              if (bio != null) updatesExtended['bio'] = bio.trim();
              if (agama != null) updatesExtended['agama'] = agama.trim();
              if (namaPanggilan != null) updatesExtended['nama_panggilan'] = namaPanggilan.trim();
              await client.from('students').update(updatesExtended).eq('nim', nim);
              synced = true;
            } catch (e) {
              debugPrint('Info: Sinkronisasi dengan bio/agama/nama_panggilan belum didukung schema database: $e');
            }
          }

          // Jika belum tersinkron atau bio/agama null, kirim baseUpdates
          if (!synced && baseUpdates.isNotEmpty) {
            await client.from('students').update(baseUpdates).eq('nim', nim);
          }
        }
      } catch (e) {
        debugPrint('Info: Sinkronisasi update profil ke Supabase: $e');
      }
    }
  }

  static void applyCustomProfileOverrides(StudentProfile profile, SharedPreferences prefs) {
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
        if (data['bio'] != null) profile.bio = data['bio'].toString();
        if (data['agama'] != null) profile.agama = data['agama'].toString();
        if (data['nama_panggilan'] != null) profile.namaPanggilan = data['nama_panggilan'].toString();
      }
    } catch (_) {}
  }

  static Future<void> applyCustomProfileOverridesAsync(StudentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      applyCustomProfileOverrides(profile, prefs);
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
