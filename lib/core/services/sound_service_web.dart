// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

String? _cachedNotificationWavUri;

String _getNotificationWavUri() {
  if (_cachedNotificationWavUri != null) return _cachedNotificationWavUri!;

  // Buat audio chime jernih & elegan: dual-frequency (E5 659Hz -> A5 880Hz)
  const sampleRate = 22050;
  const duration = 0.32;
  final numSamples = (sampleRate * duration).round();
  final byteData = ByteData(44 + numSamples * 2);

  // WAV RIFF header
  byteData.setUint32(0, 0x52494646, Endian.big); // 'RIFF'
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
  byteData.setUint32(8, 0x57415645, Endian.big); // 'WAVE'
  byteData.setUint32(12, 0x666d7420, Endian.big); // 'fmt '
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // Mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  byteData.setUint32(36, 0x64617461, Endian.big); // 'data'
  byteData.setUint32(40, numSamples * 2, Endian.little);

  // Sintesis harmonik lembut dengan decay eksponensial
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final decay = math.exp(-t * 9.0);
    final freq = (t < 0.08) ? 659.25 : 880.0;
    final sample = math.sin(2 * math.pi * freq * t) * decay * 0.30;
    final intSample = (sample * 32767).clamp(-32768, 32767).toInt();
    byteData.setInt16(44 + i * 2, intSample, Endian.little);
  }

  final base64String = base64Encode(byteData.buffer.asUint8List());
  _cachedNotificationWavUri = 'data:audio/wav;base64,$base64String';
  return _cachedNotificationWavUri!;
}

/// Implementasi pemutaran suara notifikasi untuk platform Web via HTML5 Audio
void playPlatformNotificationSound() {
  try {
    final uri = _getNotificationWavUri();
    final audio = html.AudioElement(uri);
    audio.play();
  } catch (_) {}
}
