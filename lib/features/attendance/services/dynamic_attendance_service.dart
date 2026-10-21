import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/attendance_models.dart';

/// Hasil verifikasi kode/QR presensi
class DynamicVerificationResult {
  final bool isValid;
  final bool isDynamic;
  final bool isExpiredDynamic;
  final String message;
  final int? window;

  const DynamicVerificationResult({
    required this.isValid,
    this.isDynamic = false,
    this.isExpiredDynamic = false,
    required this.message,
    this.window,
  });

  factory DynamicVerificationResult.success({
    bool isDynamic = false,
    int? window,
    String? message,
  }) {
    return DynamicVerificationResult(
      isValid: true,
      isDynamic: isDynamic,
      window: window,
      message: message ??
          (isDynamic
              ? 'Presensi dinamis terverifikasi sah di kelas!'
              : 'Presensi berhasil diverifikasi.'),
    );
  }

  factory DynamicVerificationResult.expiredDynamic(String message) {
    return DynamicVerificationResult(
      isValid: false,
      isDynamic: true,
      isExpiredDynamic: true,
      message: message,
    );
  }

  factory DynamicVerificationResult.failed(String message) {
    return DynamicVerificationResult(
      isValid: false,
      message: message,
    );
  }
}

/// Token & PIN dinamis yang dihitung deterministik untuk interval waktu tertentu
class DynamicAttendanceToken {
  final int window;
  final int secondsRemaining;
  final double progress;
  final String dynamicToken;
  final String dynamicPin;
  final String qrPayload;

  const DynamicAttendanceToken({
    required this.window,
    required this.secondsRemaining,
    required this.progress,
    required this.dynamicToken,
    required this.dynamicPin,
    required this.qrPayload,
  });
}

/// Layanan QR Code & PIN Presensi Dinamis (Anti-Kecurangan / Anti-Joki)
///
/// Menggunakan algoritma berbasis HMAC-SHA256 mirip TOTP (Time-Based One-Time Password)
/// dengan interval rotasi 30 detik.
/// Mahasiswa yang memfoto QR atau screenshot tidak dapat membagikannya kepada rekan yang
/// tidak hadir, karena token akan kedaluwarsa dalam 30 detik.
class DynamicAttendanceService {
  /// Interval rotasi token dalam detik (30 detik)
  static const int rotationIntervalSeconds = 30;

  /// Karakter aman untuk token 6 digit (tanpa 0, O, 1, I agar tidak membingungkan)
  static const String _tokenAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Mendapatkan indeks window waktu saat ini
  static int get currentWindow =>
      DateTime.now().millisecondsSinceEpoch ~/ (rotationIntervalSeconds * 1000);

  /// Sisa detik pada window waktu saat ini (1 sampai 30)
  static int get windowRemainingSeconds {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final rem = rotationIntervalSeconds - (nowSeconds % rotationIntervalSeconds);
    return rem == 0 ? rotationIntervalSeconds : rem;
  }

  /// Progres waktu pada window saat ini (0.0 sampai 1.0)
  static double get windowProgress =>
      (windowRemainingSeconds / rotationIntervalSeconds).clamp(0.0, 1.0);

  /// Menghitung token, PIN, dan payload QR dinamis untuk sesi tertentu pada window saat ini
  static DynamicAttendanceToken generate(ActiveAttendanceSession session,
      {int? customWindow}) {
    final w = customWindow ?? currentWindow;
    final seed = (session.id != null && session.id!.isNotEmpty)
        ? session.id!
        : session.token;

    final result = generateForSeed(
      seed: seed,
      courseName: session.courseName,
      pertemuanKe: session.pertemuanKe,
      window: w,
    );

    return result;
  }

  /// Menghitung token dan PIN deterministik dari seed rahasia sesi
  static DynamicAttendanceToken generateForSeed({
    required String seed,
    required String courseName,
    required int pertemuanKe,
    int? window,
  }) {
    final w = window ?? currentWindow;
    final hmac = Hmac(sha256, utf8.encode('ILKOM_SECRET_$seed'));
    final digest = hmac.convert(utf8.encode('ROLLING_WINDOW_$w'));
    final bytes = digest.bytes;

    // Hitung 4-digit dynamic PIN
    final rawInt =
        ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3])
            .abs();
    final dynamicPin = (rawInt % 10000).toString().padLeft(4, '0');

    // Hitung 6-karakter dynamic token
    final tokenBuffer = StringBuffer();
    for (int i = 0; i < 6; i++) {
      final idx = bytes[4 + i] % _tokenAlphabet.length;
      tokenBuffer.write(_tokenAlphabet[idx]);
    }
    final dynamicToken = tokenBuffer.toString();

    // Buat compact QR payload berformat JSON terstruktur
    final qrMap = {
      'v': 2,
      'sid': seed,
      'w': w,
      'c': dynamicToken,
      'p': dynamicPin,
      'crs': courseName,
      'pt': pertemuanKe,
    };

    final qrPayload = jsonEncode(qrMap);

    return DynamicAttendanceToken(
      window: w,
      secondsRemaining: windowRemainingSeconds,
      progress: windowProgress,
      dynamicToken: dynamicToken,
      dynamicPin: dynamicPin,
      qrPayload: qrPayload,
    );
  }

  /// Memverifikasi input dari scanner kamera atau form manual
  /// Mendukung payload JSON QR dinamis, PIN dinamis 4-digit, serta token statis fallback
  static DynamicVerificationResult verify({
    required String input,
    required ActiveAttendanceSession session,
  }) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return DynamicVerificationResult.failed(
          'Kode presensi tidak boleh kosong.');
    }

    final curWin = currentWindow;
    final seed = (session.id != null && session.id!.isNotEmpty)
        ? session.id!
        : session.token;

    // 1. Coba parse sebagai payload JSON QR dinamis (Format v2)
    if (cleanInput.startsWith('{') && cleanInput.endsWith('}')) {
      try {
        final Map<String, dynamic> data = jsonDecode(cleanInput);
        if (data['v'] == 2) {
          final sid = data['sid']?.toString() ?? '';
          final w = (data['w'] as num?)?.toInt() ?? 0;
          final c = (data['c'] ?? data['code'])?.toString().toUpperCase() ?? '';
          final p = (data['p'] ?? data['pin'])?.toString().toUpperCase() ?? '';

          // Periksa apakah sesi cocok
          final bool sessionMatches = sid == seed ||
              sid == session.token ||
              (session.id != null && sid == session.id);

          if (!sessionMatches) {
            return DynamicVerificationResult.failed(
              'QR Code ini bukan untuk mata kuliah ${session.courseName}.',
            );
          }

          // Periksa kedaluwarsa window (toleransi +/- 1 window = maks 60 detik)
          final int windowDiff = curWin - w;

          if (windowDiff > 1) {
            final int expiredMinutes = (windowDiff * rotationIntervalSeconds) ~/ 60;
            return DynamicVerificationResult.expiredDynamic(
              'QR Code dinamis telah kedaluwarsa '
              '${expiredMinutes > 0 ? "sekitar $expiredMinutes menit yang lalu" : "beberapa detik yang lalu"}. '
              'Silakan scan QR code terbaru yang tampil di layar kelas!',
            );
          }

          if (windowDiff < -1) {
            return DynamicVerificationResult.expiredDynamic(
              'Waktu perangkat Anda tidak sinkron dengan waktu server kelas. Periksa jam perangkat Anda.',
            );
          }

          // Verifikasi keaslian hash token untuk window w
          final expected = generateForSeed(
            seed: seed,
            courseName: session.courseName,
            pertemuanKe: session.pertemuanKe,
            window: w,
          );

          if (c == expected.dynamicToken || p == expected.dynamicPin) {
            return DynamicVerificationResult.success(
              isDynamic: true,
              window: w,
              message: 'QR Code dinamis terverifikasi sah di kelas!',
            );
          } else {
            return DynamicVerificationResult.failed(
              'Kode verifikasi QR tidak valid atau telah dimodifikasi.',
            );
          }
        }
      } catch (_) {
        // Bukan JSON valid, lanjutkan ke pengecekan kode biasa
      }
    }

    final upperInput = cleanInput.toUpperCase();

    // 2. Cek PIN 4-digit (bisa PIN Dinamis atau PIN Statis)
    if (RegExp(r'^\d{4}$').hasMatch(upperInput)) {
      // 2a. Periksa PIN Dinamis untuk window sekarang, lalu window sebelumnya (-1), lalu (+1)
      for (final w in [curWin, curWin - 1, curWin + 1]) {
        final gen = generateForSeed(
          seed: seed,
          courseName: session.courseName,
          pertemuanKe: session.pertemuanKe,
          window: w,
        );
        if (upperInput == gen.dynamicPin) {
          return DynamicVerificationResult.success(
            isDynamic: true,
            window: w,
            message: 'PIN 4 digit dinamis terverifikasi!',
          );
        }
      }

      // 2b. Periksa apakah mahasiswa memasukkan PIN dinamis dari window lama (> 1 window lalu)
      for (int pastW = curWin - 2; pastW >= curWin - 6; pastW--) {
        final gen = generateForSeed(
          seed: seed,
          courseName: session.courseName,
          pertemuanKe: session.pertemuanKe,
          window: pastW,
        );
        if (upperInput == gen.dynamicPin) {
          return DynamicVerificationResult.expiredDynamic(
            'PIN 4 digit dinamis tersebut sudah kedaluwarsa. Masukkan PIN terbaru di layar!',
          );
        }
      }

      // 2c. Fallback ke PIN statis sesi
      if (upperInput == session.pinCode.toUpperCase()) {
        return DynamicVerificationResult.success(
          isDynamic: false,
          message: 'PIN sesi terverifikasi.',
        );
      }
    }

    // 3. Cek Token 6-karakter (bisa Token Dinamis atau Token Statis)
    // 3a. Cek Token Dinamis (+/- 1 window)
    for (final w in [curWin, curWin - 1, curWin + 1]) {
      final gen = generateForSeed(
        seed: seed,
        courseName: session.courseName,
        pertemuanKe: session.pertemuanKe,
        window: w,
      );
      if (upperInput == gen.dynamicToken) {
        return DynamicVerificationResult.success(
          isDynamic: true,
          window: w,
          message: 'Token dinamis terverifikasi sah!',
        );
      }
    }

    // 3b. Cek jika token dinamis dari window lama
    for (int pastW = curWin - 2; pastW >= curWin - 6; pastW--) {
      final gen = generateForSeed(
        seed: seed,
        courseName: session.courseName,
        pertemuanKe: session.pertemuanKe,
        window: pastW,
      );
      if (upperInput == gen.dynamicToken) {
        return DynamicVerificationResult.expiredDynamic(
          'Token dinamis tersebut sudah kedaluwarsa. Periksa token terbaru di layar kelas!',
        );
      }
    }

    // 3c. Fallback ke Token Statis sesi asli
    if (upperInput == session.token.toUpperCase()) {
      return DynamicVerificationResult.success(
        isDynamic: false,
        message: 'Token sesi terverifikasi.',
      );
    }

    return DynamicVerificationResult.failed(
      'Kode PIN atau Token salah. Pastikan Anda memasukkan kode yang tampil di kelas saat ini.',
    );
  }
}
