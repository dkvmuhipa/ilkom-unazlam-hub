import 'package:flutter/services.dart';

/// Implementasi pemutaran suara notifikasi untuk platform non-web (Android, iOS, Desktop)
void playPlatformNotificationSound() {
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.lightImpact();
  } catch (_) {}
}
