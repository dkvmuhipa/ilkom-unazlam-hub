import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka URL eksternal dengan validasi skema yang ketat (hanya http dan https)
/// untuk mencegah eksekusi skema berbahaya (javascript:, file:, intent:, dll).
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

  // Izinkan hanya skema HTTP dan HTTPS
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    debugPrint('SafeLauncher: Skema tidak diizinkan (${uri.scheme}) pada $cleanUrl');
    return false;
  }

  try {
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: mode);
    }
  } catch (e) {
    debugPrint('SafeLauncher: Gagal membuka URL ($cleanUrl): $e');
  }
  return false;
}
