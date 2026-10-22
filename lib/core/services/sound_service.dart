import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sound_service_stub.dart'
    if (dart.library.html) 'sound_service_web.dart';

class SoundService {
  static const String _prefKey = 'app_notification_sound_enabled';
  static bool? _cachedSoundEnabled;
  static DateTime? _lastPlayedTime;

  /// Cek apakah suara notifikasi diaktifkan pengguna (default: true)
  static Future<bool> isSoundEnabled() async {
    if (_cachedSoundEnabled != null) return _cachedSoundEnabled!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedSoundEnabled = prefs.getBool(_prefKey) ?? true;
      return _cachedSoundEnabled!;
    } catch (_) {
      return true;
    }
  }

  /// Aktifkan atau nonaktifkan suara notifikasi
  static Future<void> setSoundEnabled(bool enabled) async {
    _cachedSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  /// Memutar suara notifikasi yang lembut dan elegan
  /// Dilengkapi debounce 400ms agar tidak saling tumpang tindih jika ada banyak event bersamaan
  static Future<void> playNotificationSound({bool force = false}) async {
    if (!force) {
      final enabled = await isSoundEnabled();
      if (!enabled) return;
    }

    final now = DateTime.now();
    if (_lastPlayedTime != null &&
        now.difference(_lastPlayedTime!).inMilliseconds < 400) {
      return; // Hindari audio overlap jika ada broadcast bersamaan
    }
    _lastPlayedTime = now;

    try {
      playPlatformNotificationSound();
    } catch (e) {
      debugPrint('Info: Gagal memutar suara notifikasi: $e');
    }
  }
}
