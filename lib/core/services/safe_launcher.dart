import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka URL eksternal yang aman untuk web, telepon, dan email.
Future<bool> safeLaunchUrl(
  String rawUrl, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final cleanUrl = rawUrl.trim();
  if (cleanUrl.isEmpty) return false;

  final uri = Uri.tryParse(cleanUrl);
  if (uri == null) {
    debugPrint('SafeLauncher: URL tidak valid ($cleanUrl)');
    return false;
  }

  const allowedSchemes = {'http', 'https', 'mailto', 'tel'};
  if (!allowedSchemes.contains(uri.scheme) ||
      ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty)) {
    debugPrint(
      'SafeLauncher: Skema tidak diizinkan (${uri.scheme}) pada $cleanUrl',
    );
    return false;
  }

  try {
    // Jangan mengandalkan canLaunchUrl: pada web dan beberapa konfigurasi
    // Android, pengecekan itu dapat mengembalikan false walau URL bisa dibuka.
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    debugPrint('SafeLauncher: Gagal membuka URL ($cleanUrl): $e');
  }
  return false;
}
