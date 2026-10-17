import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

/// Status sesi WAHA (WhatsApp HTTP API)
enum WahaStatus {
  working,       // Sesi aktif & terhubung ke WhatsApp
  scanQrCode,    // Perlu scan QR code
  starting,      // Sedang proses booting/menghubungkan
  stopped,       // Sesi dimatikan
  failed,        // Terjadi kegagalan engine
  offline,       // Server WAHA tidak merespons (server mati / URL salah)
}

/// Model data sesi WAHA
class WahaSessionInfo {
  final String name;
  final WahaStatus status;
  final String statusRaw;
  final String? phoneNumber;
  final String? pushName;
  final String? errorMessage;

  const WahaSessionInfo({
    required this.name,
    required this.status,
    required this.statusRaw,
    this.phoneNumber,
    this.pushName,
    this.errorMessage,
  });

  bool get isConnected => status == WahaStatus.working;
  bool get needsScanQr => status == WahaStatus.scanQrCode;
  bool get isOffline => status == WahaStatus.offline;

  factory WahaSessionInfo.offline([String? error]) => WahaSessionInfo(
        name: 'default',
        status: WahaStatus.offline,
        statusRaw: 'OFFLINE',
        errorMessage: error ?? 'Server WAHA tidak dapat dihubungi.',
      );

  factory WahaSessionInfo.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? json['engine']?['state'] ?? 'STOPPED')
        .toString()
        .toUpperCase();

    WahaStatus parsed;
    if (rawStatus == 'WORKING' || rawStatus == 'CONNECTED') {
      parsed = WahaStatus.working;
    } else if (rawStatus == 'SCAN_QR_CODE' || rawStatus == 'QR') {
      parsed = WahaStatus.scanQrCode;
    } else if (rawStatus == 'STARTING') {
      parsed = WahaStatus.starting;
    } else if (rawStatus == 'STOPPED') {
      parsed = WahaStatus.stopped;
    } else {
      parsed = WahaStatus.failed;
    }

    final me = json['me'] as Map<String, dynamic>?;
    final rawPhone = me?['id']?.toString().split('@').first;
    final phone = rawPhone?.split(':').first;
    final name = me?['pushName']?.toString();

    return WahaSessionInfo(
      name: json['name']?.toString() ?? 'default',
      status: parsed,
      statusRaw: rawStatus,
      phoneNumber: phone,
      pushName: name,
    );
  }
}

/// Hasil pengiriman pesan tunggal
class WahaSendResult {
  final bool success;
  final String? messageId;
  final String? errorMessage;

  const WahaSendResult({
    required this.success,
    this.messageId,
    this.errorMessage,
  });
}

/// Hasil laporan pengiriman broadcast
class WahaBroadcastReport {
  final int total;
  final int successCount;
  final int failureCount;
  final List<String> failedRecipients;

  const WahaBroadcastReport({
    required this.total,
    required this.successCount,
    required this.failureCount,
    required this.failedRecipients,
  });

  double get successRate => total > 0 ? (successCount / total) * 100 : 0.0;
}

/// Konfigurasi Otomatisasi Pengingat Dosen (Kombinasi Cerdas)
class AutoReminderConfig {
  final bool enabled;
  final String komtiPhone;
  final String komtiName;
  final int delayMinutes;
  final String hMinusOneHour;
  final String todayHour;
  final bool autoSendIfNoReply;
  final int pendingCount;

  const AutoReminderConfig({
    required this.enabled,
    required this.komtiPhone,
    required this.komtiName,
    required this.delayMinutes,
    required this.hMinusOneHour,
    required this.todayHour,
    required this.autoSendIfNoReply,
    this.pendingCount = 0,
  });

  factory AutoReminderConfig.fromJson(Map<String, dynamic> json, [int pending = 0]) {
    return AutoReminderConfig(
      enabled: json['enabled'] ?? true,
      komtiPhone: json['komtiPhone']?.toString() ?? '',
      komtiName: json['komtiName']?.toString() ?? 'Ketua Kelas ILKOM',
      delayMinutes: (json['delayMinutes'] as num?)?.toInt() ?? 45,
      hMinusOneHour: json['hMinusOneHour']?.toString() ?? '18:00',
      todayHour: json['todayHour']?.toString() ?? '06:30',
      autoSendIfNoReply: json['autoSendIfNoReply'] ?? true,
      pendingCount: pending,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'komtiPhone': komtiPhone,
        'komtiName': komtiName,
        'delayMinutes': delayMinutes,
        'hMinusOneHour': hMinusOneHour,
        'todayHour': todayHour,
        'autoSendIfNoReply': autoSendIfNoReply,
      };
}

/// Layanan integrasi WAHA (WhatsApp HTTP API - devlikeapro/waha)
class WahaService {
  static const String _prefBaseUrlKey = 'waha_base_url';
  static const String _prefApiKeyKey = 'waha_api_key';
  static const String _prefSessionNameKey = 'waha_session_name';
  static const String _prefDefaultGroupKey = 'waha_default_group_id';
  static const String _prefIsCloudKey = 'waha_is_cloud_mode';

  static const String defaultLocalUrl = 'http://localhost:3000';
  static const String defaultSession = 'default';

  /// Mendapatkan konfigurasi URL server yang tersimpan
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefBaseUrlKey) ?? defaultLocalUrl;
  }

  /// Mendapatkan API Key WAHA yang tersimpan
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiKeyKey) ?? '';
  }

  /// Mendapatkan nama sesi yang tersimpan
  static Future<String> getSessionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefSessionNameKey) ?? defaultSession;
  }

  /// Mendapatkan ID grup kelas default (jika ada)
  static Future<String?> getDefaultGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefDefaultGroupKey);
  }

  /// Memeriksa apakah mode saat ini Cloud (true) atau Laptop Lokal (false)
  static Future<bool> isCloudMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefIsCloudKey) ?? false;
  }

  /// Menyimpan preferensi konfigurasi WAHA
  static Future<void> saveSettings({
    required String baseUrl,
    String? apiKey,
    String? sessionName,
    String? defaultGroupId,
    bool? isCloudMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = baseUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await prefs.setString(_prefBaseUrlKey, cleanUrl);
    await prefs.setString(_prefApiKeyKey, (apiKey ?? '').trim());
    await prefs.setString(_prefSessionNameKey, (sessionName ?? defaultSession).trim());
    if (defaultGroupId != null) {
      await prefs.setString(_prefDefaultGroupKey, defaultGroupId.trim());
    }
    if (isCloudMode != null) {
      await prefs.setBool(_prefIsCloudKey, isCloudMode);
    }
  }

  /// Normalisasi nomor HP ke format chatId WhatsApp (misal: 628123456789@c.us)
  static String formatToChatId(String raw) {
    var clean = raw.trim();
    if (clean.endsWith('@c.us') || clean.endsWith('@g.us')) {
      return clean;
    }
    // Hapus karakter non-digit selain @ dan .
    clean = clean.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      clean = '62$clean';
    } else if (clean.startsWith('62')) {
      // Sudah format 62
    }
    return '$clean@c.us';
  }

  /// Header HTTP request standar untuk WAHA
  static Future<Map<String, String>> _getHeaders() async {
    final apiKey = await getApiKey();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['X-Api-Key'] = apiKey;
    }
    return headers;
  }

  /// Memeriksa status sesi WAHA di server
  static Future<WahaSessionInfo> getSessionStatus() async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/sessions/$session');
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WahaSessionInfo.fromJson(data);
      } else if (response.statusCode == 404) {
        // Sesi belum dibuat di server WAHA
        return WahaSessionInfo(
          name: session,
          status: WahaStatus.stopped,
          statusRaw: 'STOPPED',
          errorMessage: 'Sesi "$session" belum dibuat atau diinisialisasi.',
        );
      } else {
        return WahaSessionInfo.offline(
          'Server WAHA merespons HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      return WahaSessionInfo.offline(
        'Koneksi ke server WAHA timed out (tidak merespons dalam 6 detik). Pastikan server aktif.',
      );
    } catch (e) {
      return WahaSessionInfo.offline('Gagal menghubungi WAHA: $e');
    }
  }

  /// Memulai sesi WhatsApp di WAHA
  static Future<bool> startSession() async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final headers = await _getHeaders();

      // Coba endpoint /api/sessions/start atau /api/sessions
      final startUri = Uri.parse('$baseUrl/api/sessions/$session/start');
      var response = await http.post(startUri, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      // Fallback endpoint POST /api/sessions
      final createUri = Uri.parse('$baseUrl/api/sessions');
      response = await http
          .post(createUri, headers: headers, body: jsonEncode({'name': session}))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error starting WAHA session: $e');
      return false;
    }
  }

  /// Menghentikan sesi WhatsApp di WAHA
  static Future<bool> stopSession() async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/sessions/$session/stop');
      final response = await http.post(uri, headers: headers).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error stopping WAHA session: $e');
      return false;
    }
  }

  /// Logout (putuskan tautan perangkat WhatsApp)
  static Future<bool> logoutSession() async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/sessions/$session/logout');
      final response = await http.post(uri, headers: headers).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error logging out WAHA session: $e');
      return false;
    }
  }

  /// Mengambil bytes gambar QR Code untuk scan tautan WhatsApp
  static Future<Uint8List?> getQrCodeBytes() async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final apiKey = await getApiKey();

      final headers = <String, String>{};
      if (apiKey.isNotEmpty) headers['X-Api-Key'] = apiKey;

      final uri = Uri.parse('$baseUrl/api/$session/auth/qr');
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching QR code from WAHA: $e');
      return null;
    }
  }

  /// Mengirim pesan teks tunggal via WAHA REST API (/api/sendText)
  static Future<WahaSendResult> sendTextMessage({
    required String recipient,
    required String text,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final session = await getSessionName();
      final headers = await _getHeaders();
      final chatId = formatToChatId(recipient);

      final uri = Uri.parse('$baseUrl/api/sendText');
      final body = jsonEncode({
        'session': session,
        'chatId': chatId,
        'text': text,
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final id = data is Map ? data['id']?.toString() : null;
        return WahaSendResult(success: true, messageId: id);
      } else {
        return WahaSendResult(
          success: false,
          errorMessage: 'Server WAHA merespons HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return WahaSendResult(
        success: false,
        errorMessage: 'Gagal mengirim pesan via WAHA: $e',
      );
    }
  }

  /// Mengirim broadcast pesan ke banyak nomor WhatsApp secara berurutan dengan throttle aman
  static Future<WahaBroadcastReport> broadcastMessage({
    required List<String> recipients,
    required String text,
    void Function(int done, int total, String currentTarget)? onProgress,
  }) async {
    int success = 0;
    int failure = 0;
    final failedList = <String>[];
    final total = recipients.length;

    for (int i = 0; i < total; i++) {
      final recipient = recipients[i];
      onProgress?.call(i + 1, total, recipient);

      final res = await sendTextMessage(recipient: recipient, text: text);
      if (res.success) {
        success++;
      } else {
        failure++;
        failedList.add(recipient);
      }

      // Jeda waktu 750ms antar pengiriman untuk menghindari rate-limit / spam flag WhatsApp
      if (i < total - 1) {
        await Future.delayed(const Duration(milliseconds: 750));
      }
    }

    return WahaBroadcastReport(
      total: total,
      successCount: success,
      failureCount: failure,
      failedRecipients: failedList,
    );
  }

  // ===========================================================================
  // TEMPLATE PESAN RESMI MAHASISWA & KAMPUS
  // ===========================================================================

  /// Format pesan broadcast warta pengumuman
  static String formatAnnouncementMessage(Announcement ann) {
    return '''📢 *PENGUMUMAN RESMI ILKOM UNAZLAM*
━━━━━━━━━━━━━━━━━━━━
*${ann.judul.toUpperCase()}*

${ann.isi}

━━━━━━━━━━━━━━━━━━━━
📌 *Kategori* : ${ann.kategori}
👤 *Penerbit* : ${ann.authorName} (${ann.authorRole})
🌐 *Portal*   : ilkom-unazlam-hub.web.app
_Pesan otomatis dikirim melalui Sistem Informasi Terpadu ILKOM UNAZLAM._''';
  }

  /// Format pengingat iuran kas kelas
  static String formatTreasuryReminderMessage({
    required String studentName,
    required String studentNim,
    required int unpaidMonthsCount,
    required int totalAmount,
    String? periodLabel,
  }) {
    return '''📋 *PENGINGAT IURAN KAS KELAS ILKOM UNAZLAM*
Halo *$studentName* (NIM: $studentNim),

Berikut informasi tagihan iuran kas kelas Anda:
━━━━━━━━━━━━━━━━━━━━
💰 *Jumlah Tunggakan* : $unpaidMonthsCount Bulan
💵 *Total Pembayaran* : Rp ${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}
📅 *Periode*          : ${periodLabel ?? 'Bulan Berjalan'}
━━━━━━━━━━━━━━━━━━━━

Pembayaran dapat ditransfer via QRIS atau diserahkan langsung ke Bendahara Kelas. Mohon konfirmasi setelah melakukan pembayaran. Terima kasih atas kerja samanya! 🙏✨

_Bendahara Kelas ILKOM UNAZLAM_''';
  }

  // ===========================================================================
  // OTOMATISASI PENGINGAT DOSEN (KOMBINASI CERDAS)
  // ===========================================================================

  /// Mengambil konfigurasi pengingat otomatis dari server WAHA Gateway
  static Future<AutoReminderConfig> getAutoReminderConfig() async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/auto-reminder/config');
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cfg = data['config'] as Map<String, dynamic>? ?? {};
        final pending = (data['pendingCount'] as num?)?.toInt() ?? 0;
        return AutoReminderConfig.fromJson(cfg, pending);
      }
    } catch (_) {}
    return const AutoReminderConfig(
      enabled: true,
      komtiPhone: '',
      komtiName: 'Ketua Kelas ILKOM',
      delayMinutes: 45,
      hMinusOneHour: '18:00',
      todayHour: '06:30',
      autoSendIfNoReply: true,
    );
  }

  /// Menyimpan konfigurasi pengingat otomatis ke server WAHA Gateway
  static Future<bool> saveAutoReminderConfig(AutoReminderConfig config) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/auto-reminder/config');
      final res = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(config.toJson()),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Menyinkronkan daftar jadwal mata kuliah ke server gateway
  static Future<bool> syncCoursesToGateway({
    required List<Course> courses,
    required String komtiPhone,
    String? komtiName,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/auto-reminder/sync-courses');
      final payload = {
        'komtiPhone': komtiPhone,
        'komtiName': komtiName ?? 'Ketua Kelas ILKOM',
        'courses': courses
            .map((c) => {
                  'id': c.id,
                  'kode': c.kode,
                  'nama': c.nama,
                  'dosen': c.dosen,
                  'dosenWa': c.dosenWa,
                  'hari': c.hari,
                  'jamMulai': c.effectiveJamMulai,
                  'jamSelesai': c.effectiveJamSelesai,
                  'ruangan': c.effectiveRuangan,
                  'linkVirtual': c.effectiveLinkVirtual,
                  'sks': c.sks,
                  'isCancelledToday': c.isCancelledToday,
                  'isRescheduled': c.isRescheduled,
                })
            .toList(),
      };
      final res = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Menjalankan simulasi uji coba pengingat sekarang (trigger test)
  static Future<Map<String, dynamic>> triggerAutoReminderSimulation() async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/auto-reminder/trigger-test');
      final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(res.body);
        return {'success': false, 'error': err['error'] ?? 'Gagal memicu simulasi'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Gagal menghubungi gateway: $e'};
    }
  }
}
