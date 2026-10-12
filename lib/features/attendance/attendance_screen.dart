import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/qr_widget.dart';
import '../../core/widgets/scale_button.dart';
import '../../models/models.dart';

class AttendanceHistoryItem {
  final String date;
  final String courseName;
  final String status; // 'Hadir', 'Izin', 'Sakit', 'Alpa'
  final int? pertemuanKe;
  final String? catatan;

  const AttendanceHistoryItem({
    required this.date,
    required this.courseName,
    required this.status,
    this.pertemuanKe,
    this.catatan,
  });
}


class ActiveAttendanceSession {
  final String? id;
  final String courseName;
  final int pertemuanKe;
  final String token;
  final String pinCode;
  final DateTime startTime;
  final DateTime expiresAt;
  final Set<String> attendedNims;

  ActiveAttendanceSession({
    this.id,
    required this.courseName,
    required this.pertemuanKe,
    required this.token,
    String? pinCode,
    required this.startTime,
    required this.expiresAt,
    Set<String>? attendedNims,
  })  : pinCode = pinCode ??
            (token.replaceAll(RegExp(r'\D'), '').length >= 4
                ? token.replaceAll(RegExp(r'\D'), '').substring(token.replaceAll(RegExp(r'\D'), '').length - 4)
                : (token.length >= 4 ? token.substring(token.length - 4) : '1234')),
        attendedNims = attendedNims ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 9999);

  static ActiveAttendanceSession fromMap(Map<String, dynamic> map) {
    final start = DateTime.tryParse(map['start_time']?.toString() ?? '') ?? DateTime.now();
    final expires = DateTime.tryParse(map['expires_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(minutes: 15));
    final attended = (map['attended_nims'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    return ActiveAttendanceSession(
      id: map['id']?.toString(),
      courseName: map['course_name']?.toString() ?? '',
      pertemuanKe: (map['pertemuan_ke'] as num?)?.toInt() ?? 1,
      token: map['token']?.toString() ?? '',
      pinCode: map['pin_code']?.toString(),
      startTime: start,
      expiresAt: expires,
      attendedNims: attended,
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  final bool canManageClassAttendance;
  final String? userNim;
  final VoidCallback? onBack;

  const AttendanceScreen({
    super.key,
    this.canManageClassAttendance = false,
    this.userNim,
    this.onBack,
  });

  // Global Class-Wide Session state
  static ActiveAttendanceSession? currentSession;

  static Future<ActiveAttendanceSession?> syncActiveSessionFromCloud() async {
    try {
      final data = await SupabaseRepository.getActiveAttendanceSession();
      if (data != null) {
        final session = ActiveAttendanceSession.fromMap(data);
        currentSession = session;
        return session;
      } else {
        if (currentSession != null && currentSession!.isExpired) {
          currentSession = null;
        }
        return null;
      }
    } catch (_) {
      return currentSession;
    }
  }

  static void showActiveQrModal(
    BuildContext context, {
    ActiveAttendanceSession? session,
    VoidCallback? onClosed,
  }) {
    final active = session ?? currentSession;
    if (active == null || active.isExpired) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final secsLeft = active.remainingSeconds;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 22, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active.courseName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pertemuan ke-${active.pertemuanKe} • QR Sesi Aktif',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ISO-Compliant QR Code View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrCodeWidget(
                    data: active.token,
                    size: 210,
                  ),
                ),
                const SizedBox(height: 18),

                // Token Box with Tap-to-Copy
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      SelectableText(
                        'TOKEN: ${active.token}   •   PIN: ${active.pinCode}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Attendance Status and Countdown Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF1E40AF)),
                          const SizedBox(width: 6),
                          Text(
                            '${active.attendedNims.length} Mahasiswa Hadir',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            'Sisa: ${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Tunjukkan QR ini kepada mahasiswa untuk di-scan menggunakan kamera atau masukkan kode TOKEN langsung di layar presensi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      onClosed?.call();
    });
  }

  static void showStudentScanner(
    BuildContext context, {
    required String userNim,
    VoidCallback? onSuccess,
  }) {
    final tokenController = TextEditingController();
    final pinController = TextEditingController();
    final session = currentSession;

    String selectedCourse = (session != null && !session.isExpired)
        ? session.courseName
        : (DummyData.courses.isNotEmpty ? DummyData.courses.first.nama : 'Mata Kuliah');

    String? scanStatusMessage;
    int inputMode = kIsWeb ? 1 : 0; // 0: Scan Kamera QR, 1: PIN 4 Digit
    bool useLongToken = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final liveSession = currentSession;
          final bool hasLiveSession = (liveSession != null && !liveSession.isExpired);
          final bool isLiveForSelectedCourse = hasLiveSession && liveSession.courseName == selectedCourse;
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          void executeVerification(String tokenToVerify) {
            final targetSession = currentSession;

            // 1. Validasi sesi aktif
            if (targetSession == null || targetSession.isExpired) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Tidak ada sesi presensi aktif atau sesi telah berakhir! Silakan minta dosen/ketua kelas membuka sesi.'),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xFFEF4444),
                  duration: Duration(seconds: 4),
                ),
              );
              return;
            }

            final activeNim = userNim;

            // 2. Validasi Token atau PIN jika diberikan (trim & case-insensitive)
            final cleanInput = tokenToVerify.trim().toUpperCase();
            final cleanSessionToken = targetSession.token.trim().toUpperCase();
            final cleanPin = targetSession.pinCode.trim().toUpperCase();
            final bool isValidCode = cleanInput.isNotEmpty &&
                (cleanInput == cleanSessionToken || cleanInput == cleanPin);

            if (!isValidCode) {
              setModalState(() {
                scanStatusMessage = 'Kode token atau PIN tidak cocok dengan sesi aktif.';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode token atau PIN salah. Periksa kembali PIN/Token dari pengurus kelas.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
              return;
            }

            // 3. Validasi duplikasi presensi
            if (targetSession.attendedNims.contains(activeNim)) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('NIM $activeNim sudah tercatat hadir untuk sesi ${targetSession.courseName} ini!'),
                  backgroundColor: const Color(0xFFF59E0B),
                ),
              );
              return;
            }

            Navigator.pop(ctx);

            // Simpan ke sesi aktif & Supabase
            targetSession.attendedNims.add(activeNim);
            SupabaseRepository.logAttendance(
              courseId: targetSession.courseName,
              studentNim: activeNim,
              pertemuanKe: targetSession.pertemuanKe,
              status: 'Hadir',
              catatan: tokenToVerify.isNotEmpty ? 'Presensi Token: $tokenToVerify' : 'Presensi Scanner QR',
            ).then((_) {
              onSuccess?.call();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Presensi Hadir untuk "${targetSession.courseName}" berhasil diverifikasi! 🎉'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          final m = (liveSession?.remainingSeconds ?? 0) ~/ 60;
          final s = (liveSession?.remainingSeconds ?? 0) % 60;
          final timerStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presensi Kehadiran Kuliah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pindai QR dosen atau ketik 4 digit PIN sesi',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Selector Mode: Scan Kamera vs PIN 4 Digit
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => inputMode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: inputMode == 0
                                  ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: inputMode == 0
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 15,
                                  color: inputMode == 0 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kamera QR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: inputMode == 0 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => inputMode = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: inputMode == 1
                                  ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: inputMode == 1
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pin_rounded,
                                  size: 15,
                                  color: inputMode == 1 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PIN 4 Digit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: inputMode == 1 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedCourse = val;
                        scanStatusMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                if (hasLiveSession) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiveForSelectedCourse
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLiveForSelectedCourse ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiveForSelectedCourse ? Icons.sensors_rounded : Icons.info_outline_rounded,
                          size: 16,
                          color: isLiveForSelectedCourse ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLiveForSelectedCourse
                                ? 'Sesi Presensi Aktif: ${liveSession.courseName} ($timerStr)'
                                : 'Sesi aktif kelas saat ini: ${liveSession.courseName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLiveForSelectedCourse
                                  ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                  : (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // MODE 0: SCAN KAMERA QR
                if (inputMode == 0) ...[
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!kIsWeb)
                          MobileScanner(
                            fit: BoxFit.cover,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final rawVal = barcode.rawValue;
                                if (rawVal != null && rawVal.isNotEmpty) {
                                  executeVerification(rawVal);
                                  break;
                                }
                              }
                            },
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.pin_rounded, size: 32, color: Color(0xFF60A5FA)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Browser Web: Gunakan Tab "PIN 4 Digit"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Input 4 angka PIN cepat tanpa perlu akses kamera.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () => setModalState(() => inputMode = 1),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    child: const Text('Beralih ke PIN 4 Digit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!kIsWeb)
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF1E40AF), width: 2.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        if (!kIsWeb)
                          Positioned(
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 13, color: Colors.white70),
                                  SizedBox(width: 5),
                                  Text(
                                    'Arahkan kamera ke QR Code',
                                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // MODE 1: PIN 4 DIGIT CEPAT (OTP BOXES)
                if (inputMode == 1) ...[
                  if (!useLongToken) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Masukkan 4 Digit PIN Sesi Kuliah',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4-Digit Display Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final text = pinController.text;
                              final digit = index < text.length ? text[index] : '';
                              final isCurrent = index == text.length;

                              return Container(
                                width: 52,
                                height: 58,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF1E40AF)
                                        : (digit.isNotEmpty ? const Color(0xFF60A5FA) : (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFCBD5E1))),
                                    width: isCurrent ? 2.2 : 1.5,
                                  ),
                                  boxShadow: isCurrent
                                      ? [BoxShadow(color: const Color(0xFF1E40AF).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  digit.isNotEmpty ? digit : (isCurrent ? '•' : ''),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isCurrent ? const Color(0xFF1E40AF) : (isDark ? Colors.white : const Color(0xFF111827)),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),

                          // Numeric text input for PIN
                          TextField(
                            controller: pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            autofocus: true,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Ketik 4 angka PIN di sini',
                              hintStyle: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                              counterText: '',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                scanStatusMessage = null;
                              });
                              if (val.trim().length == 4) {
                                executeVerification(val.trim());
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  pinController.clear();
                                  setModalState(() {});
                                },
                                child: const Text('Hapus PIN', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                              ),
                              TextButton(
                                onPressed: () => setModalState(() => useLongToken = true),
                                child: const Text('Gunakan Token Huruf', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Long Token Input Field
                    TextField(
                      controller: tokenController,
                      textCapitalization: TextCapitalization.characters,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Kode Token Sesi (Contoh: PKN-0821)',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setModalState(() => useLongToken = false),
                        child: const Text('Kembali ke PIN 4 Digit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                      ),
                    ),
                  ],
                ],

                if (scanStatusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    scanStatusMessage!,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                  ),
                ],

                const SizedBox(height: 12),

                // Button Verifikasi
                ElevatedButton.icon(
                  onPressed: () {
                    final code = (inputMode == 1 && !useLongToken)
                        ? pinController.text.trim()
                        : tokenController.text.trim();

                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan masukkan PIN 4 digit atau scan QR sesi presensi!'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }
                    executeVerification(code);
                  },
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Verifikasi Kehadiran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Berhalangan hadir kuliah? ',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          AttendanceScreen.showAbsenceRequestModal(
                            context,
                            userNim: userNim,
                            preselectedCourse: selectedCourse,
                            onSuccess: onSuccess,
                          );
                        },
                        child: const Text(
                          'Ajukan Izin / Sakit di sini',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E40AF),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      tokenController.dispose();
      pinController.dispose();
    });
  }

  // =========================================================================
  // PENGAJUAN IZIN / SAKIT MANDIRI (SELF-REPORT ABSENCE)
  // =========================================================================
  static void showAbsenceRequestModal(
    BuildContext context, {
    required String userNim,
    String? preselectedCourse,
    int? preselectedPertemuan,
    VoidCallback? onSuccess,
  }) {
    final reasonController = TextEditingController();
    final liveSession = currentSession;
    String selectedCourse = preselectedCourse ??
        ((liveSession != null && !liveSession.isExpired)
            ? liveSession.courseName
            : (DummyData.courses.isNotEmpty ? DummyData.courses.first.nama : 'Mata Kuliah'));
    int selectedPertemuan = preselectedPertemuan ??
        ((liveSession != null && !liveSession.isExpired) ? liveSession.pertemuanKe : 1);
    String selectedStatus = 'Izin'; // 'Izin' or 'Sakit'
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: selectedStatus == 'Izin' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selectedStatus == 'Izin' ? Icons.assignment_late_rounded : Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengajuan Izin / Sakit Kuliah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Laporkan ketidakhadiran resmi ke sistem akademik kelas',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Selector (Izin vs Sakit)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = 'Izin'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedStatus == 'Izin'
                                ? (isDark ? const Color(0xFF713F12) : const Color(0xFFFEF3C7))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == 'Izin' ? const Color(0xFFF59E0B) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.watch_later_outlined,
                                size: 16,
                                color: selectedStatus == 'Izin' ? const Color(0xFFD97706) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Izin',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedStatus == 'Izin' ? const Color(0xFFD97706) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = 'Sakit'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedStatus == 'Sakit'
                                ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == 'Sakit' ? const Color(0xFF3B82F6) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.healing_rounded,
                                size: 16,
                                color: selectedStatus == 'Sakit' ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sakit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedStatus == 'Sakit' ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row: Mata Kuliah & Pertemuan
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCourse,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Mata Kuliah',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: DummyData.courses.map((c) => DropdownMenuItem(
                          value: c.nama,
                          child: Text(c.nama, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCourse = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedPertemuan,
                        decoration: InputDecoration(
                          labelText: 'Pertemuan',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: List.generate(16, (i) => i + 1).map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('Ke-$p', style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPertemuan = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Alasan Textfield
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alasan / Keterangan Lengkap',
                    hintText: selectedStatus == 'Izin'
                        ? 'Contoh: Menghadiri kegiatan dinas kampus / keperluan keluarga mendesak...'
                        : 'Contoh: Mengalami demam dan disarankan istirahat oleh dokter...',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintStyle: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Notice Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data izin/sakit akan tercatat resmi dalam sistem rekapitulasi kehadiran dan dapat diverifikasi oleh Ketua Kelas atau Dosen.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harap tuliskan alasan ketidakhadiran Anda!'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            await SupabaseRepository.logAttendance(
                              courseId: selectedCourse,
                              studentNim: userNim,
                              pertemuanKe: selectedPertemuan,
                              status: selectedStatus,
                              catatan: reason,
                            );

                            final current = currentSession;
                            if (current != null && current.courseName == selectedCourse && current.pertemuanKe == selectedPertemuan) {
                              current.attendedNims.add(userNim);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            onSuccess?.call();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Pengajuan $selectedStatus untuk "$selectedCourse" berhasil dicatat! 📄'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: selectedStatus == 'Izin' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengirim pengajuan: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan $selectedStatus',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStatus == 'Izin' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      reasonController.dispose();
    });
  }

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _countdownTimer;
  int _activeTab = 0; // 0: Presensi Saya, 1: Rekap Seluruh Kelas
  ActiveAttendanceSession? get currentSession => AttendanceScreen.currentSession;
  set currentSession(ActiveAttendanceSession? s) => AttendanceScreen.currentSession = s;

  List<AttendanceHistoryItem> _history = [];
  List<Map<String, dynamic>> _allClassLogs = [];
  bool _isLoadingAttendance = true;
  String? _attendanceLoadError;

  @override
  void initState() {
    super.initState();
    AttendanceScreen.syncActiveSessionFromCloud().then((_) {
      if (mounted) {
        setState(() {});
        _startTimerIfNeeded();
      }
    });
    _loadRealAttendanceData();
    _startTimerIfNeeded();
  }

  Future<void> _loadRealAttendanceData() async {
    final activeNim = widget.userNim ?? '';
    if (mounted) {
      setState(() {
        _isLoadingAttendance = true;
        _attendanceLoadError = null;
      });
    }

    try {
      if (!widget.canManageClassAttendance && activeNim.isEmpty) {
        throw StateError('NIM akun tidak ditemukan. Silakan masuk kembali.');
      }
      List<Map<String, dynamic>> rawLogs;
      try {
        rawLogs = await SupabaseRepository.getAttendanceLogsStrict(
          studentNim: widget.canManageClassAttendance ? null : activeNim,
        );
      } catch (err) {
        debugPrint('Warning: getAttendanceLogsStrict gagal ($err), mencoba getAttendanceLogs fallback');
        rawLogs = await SupabaseRepository.getAttendanceLogs(
          studentNim: widget.canManageClassAttendance ? null : activeNim,
        );
      }
      
      if (!mounted) return;

      setState(() {
        _allClassLogs = rawLogs;

        // 2. Filter riwayat presensi khusus untuk mahasiswa yang sedang aktif login
        final personalLogs = rawLogs.where((l) => l['student_nim'] == activeNim).toList();

        _history = personalLogs.map((l) {
          final createdAt = l['created_at'] != null ? DateTime.parse(l['created_at']) : DateTime.now();
          final formattedDate = '${DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(createdAt)} (${DateFormat('HH:mm').format(createdAt)} WITA)';

          String cName = 'Mata Kuliah';
          if (l['courses'] != null && l['courses']['nama_mk'] != null) {
            cName = l['courses']['nama_mk'].toString();
          } else if (l['course_id'] != null) {
            cName = 'Mata Kuliah';
          }

          final rawSt = (l['status'] ?? 'hadir').toString().toLowerCase();
          String stFormatted = 'Hadir';
          if (rawSt == 'izin') stFormatted = 'Izin';
          if (rawSt == 'sakit') stFormatted = 'Sakit';
          if (rawSt == 'alpa') stFormatted = 'Alpa';

          return AttendanceHistoryItem(
            date: formattedDate,
            courseName: cName,
            status: stFormatted,
            pertemuanKe: (l['pertemuan_ke'] as num?)?.toInt(),
            catatan: l['catatan']?.toString(),
          );
        }).toList();

        _isLoadingAttendance = false;
      });
    } catch (e) {
      debugPrint('Error load real attendance: $e');
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
          _attendanceLoadError =
              'Riwayat presensi gagal dimuat. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  void _confirmResetPersonalAttendance() {
    final activeNim = widget.userNim ?? '';
    if (activeNim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NIM akun tidak ditemukan. Masuk kembali sebelum mengubah riwayat.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Riwayat Presensi Pribadi?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Semua catatan scan presensi Anda akan dihapus karena belum ada aktivitas perkuliahan yang aktif. Riwayat Anda akan kembali bersih/kosong.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _history = [];
                _allClassLogs.removeWhere((l) => l['student_nim'] == activeNim);
              });
              await SupabaseRepository.clearAttendanceLogs(studentNim: activeNim);
              await _loadRealAttendanceData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat presensi pribadi telah berhasil dikosongkan.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Kosongkan Sekarang'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAllAttendance() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Rekap Seluruh Kelas?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Semua catatan log presensi kelas akan dibersihkan dari server karena belum ada perkuliahan aktif. Rekap kehadiran seluruh mahasiswa akan kembali ke kondisi awal (0 sesi).',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _history = [];
                _allClassLogs = [];
              });
              await SupabaseRepository.clearAttendanceLogs();
              await _loadRealAttendanceData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rekap presensi seluruh kelas telah berhasil dikosongkan.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Kosongkan Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _countdownTimer?.cancel();
    if (currentSession != null && !currentSession!.isExpired) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (currentSession == null || currentSession!.isExpired) {
          timer.cancel();
          setState(() {
            currentSession = null;
          });
        } else {
          setState(() {});
        }
      });
    }
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showClassAttendanceModal() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();
    final Map<String, String> statusMap = {
      for (var s in students) s.id: 'Hadir',
    };
    String selectedCourse = DummyData.courses.first.nama;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presensi Pertemuan Kelas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kelola absensi mahasiswa untuk mata kuliah ini',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Mahasiswa (${students.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          for (var s in students) {
                            statusMap[s.id] = 'Hadir';
                          }
                        });
                      },
                      icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF16A34A)),
                      label: const Text('Set Semua Hadir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final currentStatus = statusMap[s.id] ?? 'Hadir';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                              child: Text(s.nama.isNotEmpty ? s.nama[0] : 'M', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                                  Text('${s.nim} • ${s.jabatan}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((st) {
                                final isSel = currentStatus == st;
                                Color color = st == 'Hadir' ? const Color(0xFF16A34A) : (st == 'Izin' ? const Color(0xFFD97706) : (st == 'Sakit' ? const Color(0xFF2563EB) : const Color(0xFFDC2626)));
                                return InkWell(
                                  onTap: () => setModalState(() => statusMap[s.id] = st),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? color : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSel ? color : const Color(0xFFD1D5DB)),
                                    ),
                                    child: Text(
                                      st[0],
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSel ? Colors.white : const Color(0xFF4B5563)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menyimpan rekap presensi kelas untuk $selectedCourse...'),
                        backgroundColor: const Color(0xFF1E40AF),
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    for (var s in students) {
                      final st = statusMap[s.id] ?? 'Hadir';
                      await SupabaseRepository.logAttendance(
                        courseId: selectedCourse,
                        studentNim: s.nim,
                        pertemuanKe: 1,
                        status: st,
                        catatan: 'Rekap Presensi Cepat Pengurus',
                      );
                    }

                    await _loadRealAttendanceData();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Presensi kelas untuk $selectedCourse berhasil disimpan dan disinkronkan!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Simpan Rekap Presensi Kelas', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGenerateQrModal(BuildContext context) {
    String selectedCourse = DummyData.courses.first.nama;
    int pertemuan = 5;
    String token = _generateAttendanceToken();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QR Code Presensi Sesi Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                          SizedBox(height: 2),
                          Text('Tampilkan kode ini kepada mahasiswa di kelas', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedCourse = val;
                        token = _generateAttendanceToken();
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // ISO-Compliant QR Code View
                QrCodeWidget(
                  data: token,
                  size: 200,
                ),
                const SizedBox(height: 16),

                // Token Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      Text(
                        'TOKEN: $token',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      'Berlaku hingga 15 menit ke depan (10:15 WITA)',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    final expiresAt = now.add(const Duration(minutes: 15));
                    final newSession = ActiveAttendanceSession(
                      courseName: selectedCourse,
                      pertemuanKe: pertemuan,
                      token: token,
                      startTime: now,
                      expiresAt: expiresAt,
                    );

                    setState(() {
                      currentSession = newSession;
                      _startTimerIfNeeded();
                    });

                    // Simpan sesi presensi ke cloud Supabase agar realtime ke seluruh kelas
                    SupabaseRepository.createAttendanceSession(
                      courseName: selectedCourse,
                      pertemuanKe: pertemuan,
                      token: token,
                      pinCode: newSession.pinCode,
                      expiresAt: expiresAt,
                      createdBy: widget.userNim,
                    ).then((created) {
                      if (created != null && created['id'] != null && mounted) {
                        setState(() {
                          currentSession = ActiveAttendanceSession.fromMap(created);
                        });
                      }
                    });

                    // Broadcast class announcement so every classmate sees it in Notifications & Announcements
                    SupabaseRepository.createAnnouncement(
                      judul: 'Presensi Dibuka: $selectedCourse Pertemuan $pertemuan',
                      isi: 'Sesi presensi QR untuk mata kuliah $selectedCourse (Pertemuan $pertemuan) telah dibuka oleh pengurus kelas dan berlaku selama 15 menit. Silakan scan QR di kelas atau masukkan Token "$token" / PIN "${newSession.pinCode}" langsung di aplikasi.',
                      kategori: 'Kelas',
                      isPinned: true,
                      authorName: 'Pengurus Kelas (Ketua)',
                    );

                    Navigator.pop(ctx);

                    // Re-open persistent active session presenter modal so Ketua can project/show it to the entire class
                    AttendanceScreen.showActiveQrModal(context, session: newSession);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Sesi presensi "$selectedCourse" aktif selama 15 menit! Pengumuman kelas telah disiarkan.'),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                  label: const Text('Buka Sesi Presensi Sekarang (15 Menit)', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _generateAttendanceToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  void _showScanQrModal(BuildContext context) {
    AttendanceScreen.showStudentScanner(
      context,
      userNim: widget.userNim ?? '',
      onSuccess: () => _loadRealAttendanceData(),
    );
  }

  void _showAbsenceRequestSheet(BuildContext context, {String? preselectedCourse, int? preselectedPertemuan}) {
    AttendanceScreen.showAbsenceRequestModal(
      context,
      userNim: widget.userNim ?? '',
      preselectedCourse: preselectedCourse,
      preselectedPertemuan: preselectedPertemuan,
      onSuccess: () => _loadRealAttendanceData(),
    );
  }

  void _showCourseDetailModal(BuildContext context, Course course, bool isDark) {
    final courseLogs = _history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
    final courseHadir = courseLogs.where((h) => h.status == 'Hadir').length;
    final courseIzin = courseLogs.where((h) => h.status == 'Izin').length;
    final courseSakit = courseLogs.where((h) => h.status == 'Sakit').length;
    final courseAlpa = courseLogs.where((h) => h.status == 'Alpa').length;
    final int coursePct = courseLogs.isNotEmpty ? ((courseHadir / courseLogs.length) * 100).round() : 100;
    final bool isCourseSafe = coursePct >= 75;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.nama,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isCourseSafe
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                      : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCourseSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  courseLogs.isNotEmpty ? '$coursePct%' : '100%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isCourseSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isCourseSafe
                                                ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                                                : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isCourseSafe ? 'Syarat UAS Aman' : 'Batas Kritis (<75%)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isCourseSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target kelayakan: Min. 12 dari 16 pertemuan wajib hadir',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat('$courseHadir', 'Hadir', const Color(0xFF10B981), isDark),
                              _buildMiniStat('$courseIzin', 'Izin', const Color(0xFFF59E0B), isDark),
                              _buildMiniStat('$courseSakit', 'Sakit', const Color(0xFF3B82F6), isDark),
                              _buildMiniStat('$courseAlpa', 'Alpa', const Color(0xFFEF4444), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rincian 16 Pertemuan Kuliah',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${courseLogs.length} Sesi Terlaksana',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(16, (index) {
                      final pNum = index + 1;
                      AttendanceHistoryItem? matchedLog;
                      for (final l in courseLogs) {
                        if (l.pertemuanKe == pNum) {
                          matchedLog = l;
                          break;
                        }
                      }
                      if (matchedLog == null && pNum <= courseLogs.length) {
                        matchedLog = courseLogs[courseLogs.length - pNum];
                      }

                      final bool isRecorded = matchedLog != null;
                      final status = matchedLog?.status ?? 'Mendatang';
                      Color stColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
                      Color stBg = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9);

                      if (status == 'Hadir') {
                        stColor = const Color(0xFF10B981);
                        stBg = isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5);
                      } else if (status == 'Izin') {
                        stColor = const Color(0xFFF59E0B);
                        stBg = isDark ? const Color(0xFF713F12) : const Color(0xFFFFFBEB);
                      } else if (status == 'Sakit') {
                        stColor = const Color(0xFF3B82F6);
                        stBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
                      } else if (status == 'Alpa') {
                        stColor = const Color(0xFFEF4444);
                        stBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222234) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRecorded
                                ? (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isRecorded
                                    ? (stColor.withValues(alpha: 0.12))
                                    : (isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF8FAFC)),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'P$pNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isRecorded ? stColor : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pertemuan $pNum',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isRecorded
                                        ? (matchedLog.catatan != null && matchedLog.catatan!.isNotEmpty
                                            ? '${matchedLog.date} • ${matchedLog.catatan}'
                                            : matchedLog.date)
                                        : 'Belum dijadwalkan / Mendatang',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: stBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: stColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Footer Action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAbsenceRequestSheet(context, preselectedCourse: course.nama);
                      },
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                      label: const Text('Ajukan Izin / Sakit Matkul Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E40AF),
                        side: const BorderSide(color: Color(0xFF1E40AF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicWarningCard({
    required List<Course> atRiskCourses,
    required int remainingAlpa,
    required bool isDark,
  }) {
    final hasSpecificCourseRisk = atRiskCourses.isNotEmpty;
    final courseNames = atRiskCourses.map((c) => c.nama).join(', ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERINGATAN DINI KELAYAKAN UAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasSpecificCourseRisk
                          ? 'Kehadiran pada mata kuliah "$courseNames" berada di bawah standar 75% atau mendekati batas alpa.'
                          : 'Toleransi ketidakhadiran tersisa $remainingAlpa kali sesi kuliah sebelum kehilangan hak mengikuti UAS.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E0C0C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Sesuai panduan akademik UNAZLAM, batas minimum kehadiran UAS adalah 75% (maks 4 kali alpa).',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showAbsenceRequestSheet(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Ajukan Izin',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeNim = widget.userNim ?? '';
    final studentProfile = DummyData.students.firstWhere(
      (s) => s.nim == activeNim,
      orElse: () => StudentProfile(
        id: '',
        nim: activeNim,
        nama: activeNim.isEmpty ? 'Mahasiswa' : 'Mahasiswa $activeNim',
        email: '',
        noWa: '',
      ),
    );

    final totalSessions = _history.length;
    final hadirCount = _history.where((h) => h.status == 'Hadir').length;
    final izinCount = _history.where((h) => h.status == 'Izin').length;
    final sakitCount = _history.where((h) => h.status == 'Sakit').length;
    final alpaCount = _history.where((h) => h.status == 'Alpa').length;
    final double attendanceRatio = totalSessions > 0 ? (hadirCount / totalSessions) : 1.0;
    final int attendancePercent = (attendanceRatio * 100).round();
    final bool isSafeZone = attendancePercent >= 75;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF111827)),
          tooltip: 'Kembali',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.canManageClassAttendance ? 'Presensi & Kehadiran' : 'Presensi Saya',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.canManageClassAttendance
                  ? 'Akses Pengurus • ${studentProfile.nama}'
                  : '${studentProfile.nama} • ${studentProfile.nim}',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Prominent Buka QR / Scan QR Action Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.canManageClassAttendance) {
                  _showGenerateQrModal(context);
                } else {
                  _showScanQrModal(context);
                }
              },
              icon: Icon(
                widget.canManageClassAttendance ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                size: 16,
              ),
              label: Text(
                widget.canManageClassAttendance ? 'Buka QR' : 'Scan QR',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Export Button (Personal vs Class)
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: isDark ? Colors.white70 : const Color(0xFF374151), size: 22),
            tooltip: widget.canManageClassAttendance
                ? 'Export Rekap Presensi Kelas (Excel/CSV)'
                : 'Export Rekap Kehadiran Saya (CSV)',
            onPressed: () {
              if (widget.canManageClassAttendance) {
                ExportService.showExportSheet(
                  context,
                  title: 'Export Rekap Presensi Seluruh Kelas',
                  subtitle: 'Format data CSV kompatibel dengan Microsoft Excel & Google Sheets',
                  fileName: 'Rekap_Presensi_Kelas_ILKOM_UNAZLAM_2026.csv',
                  content: ExportService.exportAttendanceCsv(DummyData.courses.first.nama),
                );
              } else {
                ExportService.showExportSheet(
                  context,
                  title: 'Export Rekap Presensi Pribadi',
                  subtitle: 'Khusus data kehadiran atas nama ${studentProfile.nama} (${studentProfile.nim})',
                  fileName: 'Presensi_${studentProfile.nim}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                  content: ExportService.exportPersonalAttendanceCsv(
                    studentNim: studentProfile.nim,
                    studentName: studentProfile.nama,
                    history: _history,
                  ),
                );
              }
            },
          ),
          if (widget.canManageClassAttendance)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showClassAttendanceModal,
                icon: const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF1E40AF)),
                label: const Text('Input Kelas', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.canManageClassAttendance
          ? FloatingActionButton.extended(
              onPressed: () => _showGenerateQrModal(context),
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text(
                'Buka Presensi QR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            // ==========================================
            // ROLE SELECTOR TAB (ONLY FOR KETUA KELAS / ADMIN)
            // ==========================================
            if (widget.canManageClassAttendance) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? (isDark ? const Color(0xFF1E40AF) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: _activeTab == 0
                                    ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF1E40AF))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Presensi Saya',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                  color: _activeTab == 0
                                      ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF1E293B))
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? (isDark ? const Color(0xFF1E40AF) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: _activeTab == 1
                                    ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF1E40AF))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rekap Seluruh Kelas',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                  color: _activeTab == 1
                                      ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF1E293B))
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==========================================
            // KETUA KELAS / DOSEN: HERO CARD BUKA PRESENSI QR
            // ==========================================
            if (widget.canManageClassAttendance && (currentSession == null || currentSession!.isExpired)) ...[
              _buildStartAttendanceHeroCard(context, isDark),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // LIVE ACTIVE SESSION COUNTDOWN BANNER
            // ==========================================
            if (currentSession != null && !currentSession!.isExpired) ...[
              Builder(
                builder: (context) {
                  final session = currentSession!;
                  final secsLeft = session.remainingSeconds;
                  final isUrgent = secsLeft < 180;
                  final hasAttended = session.attendedNims.contains(activeNim);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                          : (isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUrgent
                            ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
                            : (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF16A34A)).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'SESI AKTIF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                    : (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimer(secsLeft),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          session.courseName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Token: ${session.token} • Pertemuan ke-${session.pertemuanKe}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF1E40AF)),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.canManageClassAttendance
                                        ? '${session.attendedNims.length} Hadir'
                                        : (hasAttended ? 'Tercatat Hadir' : 'Menunggu Presensi'),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Tombol Tampilkan QR Code (Dapat dilihat oleh siapapun/Ketua untuk proyektor)
                            TextButton.icon(
                              onPressed: () => AttendanceScreen.showActiveQrModal(context, session: session),
                              icon: const Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF1E40AF)),
                              label: const Text('Lihat QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: isDark ? const Color(0xFF2E2E3E) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            if (widget.canManageClassAttendance) ...[
                              TextButton.icon(
                                onPressed: () {
                                  final activeId = currentSession?.id;
                                  setState(() {
                                    currentSession = null;
                                    _countdownTimer?.cancel();
                                  });
                                  SupabaseRepository.closeAttendanceSession(sessionId: activeId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sesi presensi telah ditutup oleh pengurus kelas.'),
                                      backgroundColor: Color(0xFF374151),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.stop_circle_outlined, size: 15, color: Color(0xFFDC2626)),
                                label: const Text('Tutup', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: isDark ? const Color(0xFF2E1A1A) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ] else ...[
                              if (!hasAttended)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showScanQrModal(context),
                                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                                      label: const Text('Presensi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed: () => _showAbsenceRequestSheet(
                                        context,
                                        preselectedCourse: session.courseName,
                                        preselectedPertemuan: session.pertemuanKe,
                                      ),
                                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 13),
                                      label: const Text('Izin/Sakit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                        side: BorderSide(color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '✅ Sudah Hadir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // ==========================================
            // VIEW SEPARATION: TAB 1 (CLASS RECAP FOR ADMIN/KETUA)
            // ==========================================
            if (_attendanceLoadError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Text(_attendanceLoadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadRealAttendanceData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ] else if (_isLoadingAttendance) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                ),
              ),
            ] else if (widget.canManageClassAttendance && _activeTab == 1) ...[
              _buildClassRecapView(isDark),
            ] else ...[
              // ==========================================
              // VIEW SEPARATION: TAB 0 (PERSONAL ATTENDANCE VIEW)
              // ==========================================
              _buildPersonalAttendanceView(
                isDark: isDark,
                totalSessions: totalSessions,
                hadirCount: hadirCount,
                izinCount: izinCount,
                sakitCount: sakitCount,
                alpaCount: alpaCount,
                attendanceRatio: attendanceRatio,
                attendancePercent: attendancePercent,
                isSafeZone: isSafeZone,
                studentName: studentProfile.nama,
                studentNim: studentProfile.nim,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartAttendanceHeroCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFBBF24)),
                    SizedBox(width: 5),
                    Text(
                      'PENGURUS KELAS / DOSEN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.qr_code_2_rounded, size: 28, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Buka Sesi Presensi Kuliah',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate QR Code dinamis dan kode PIN 4 digit untuk presensi mahasiswa di kelas hari ini secara realtime.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showGenerateQrModal(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(
                    'Buka Presensi QR',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E40AF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showClassAttendanceModal,
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text(
                  'Input Manual',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 1: REKAP KELAS LENGKAP (KHUSUS PENGURUS & ADMIN)
  // =========================================================================
  Widget _buildClassRecapView(bool isDark) {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka QR Presensi Kuliah',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Generate QR Code & Token sesi 15 menit',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => _showGenerateQrModal(context),
                scaleDown: 0.92,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Buka Sesi',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Class Quick Overview
        Builder(
          builder: (context) {
            final totalLogs = _allClassLogs.length;
            final hadirLogs = _allClassLogs.where((l) => (l['status'] ?? '').toString().toLowerCase() == 'hadir').length;
            final classAvgStr = totalLogs > 0 ? '${((hadirLogs / totalLogs) * 100).toStringAsFixed(1)}%' : '0.0%';

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Mahasiswa',
                    value: '${students.length}',
                    subtitle: 'Mahasiswa Terdaftar',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF1E40AF),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Rata-Rata Kelas',
                    value: classAvgStr,
                    subtitle: totalLogs > 0 ? '$hadirLogs / $totalLogs Hadir' : 'Belum Ada Sesi',
                    icon: Icons.trending_up_rounded,
                    color: totalLogs > 0 ? const Color(0xFF10B981) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    isDark: isDark,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rekap Kehadiran Mahasiswa (${students.length})',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (_allClassLogs.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () => _confirmResetAllAttendance(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 15, color: Color(0xFFEF4444)),
                label: const Text(
                  'Kosongkan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
            ],
            TextButton.icon(
              onPressed: _showClassAttendanceModal,
              icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF1E40AF)),
              label: const Text(
                'Presensi Cepat',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Students Table List with Real Data from _allClassLogs
        ...students.map((s) {
          final sLogs = _allClassLogs.where((l) => l['student_nim'] == s.nim).toList();
          final sHadir = sLogs.where((l) => (l['status'] ?? '').toString().toLowerCase() == 'hadir').length;
          final int hadirPct = sLogs.isNotEmpty ? ((sHadir / sLogs.length) * 100).round() : 0;
          final String sessionInfo = sLogs.isNotEmpty ? '$sHadir/${sLogs.length} Sesi' : 'Belum Ada Sesi';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                  child: Text(
                    s.nama.isNotEmpty ? s.nama[0] : 'M',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nama,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.nim} • ${s.jabatan} • $sessionInfo',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sLogs.isNotEmpty
                        ? (hadirPct >= 75
                            ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
                            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)))
                        : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sLogs.isNotEmpty ? '$hadirPct%' : '-',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: sLogs.isNotEmpty
                          ? (hadirPct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // VIEW 2: TAMPILAN PRESENSI PRIBADI MAHASISWA (PRIVAT & USER FRIENDLY)
  // =========================================================================
  Widget _buildPersonalAttendanceView({
    required bool isDark,
    required int totalSessions,
    required int hadirCount,
    required int izinCount,
    required int sakitCount,
    required int alpaCount,
    required double attendanceRatio,
    required int attendancePercent,
    required bool isSafeZone,
    required String studentName,
    required String studentNim,
  }) {
    final maxAlpaAllowed = 4;
    final remainingAlpa = (maxAlpaAllowed - alpaCount).clamp(0, maxAlpaAllowed);

    final atRiskCourses = DummyData.courses.where((course) {
      final logs = _history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
      if (logs.isEmpty) return false;
      final hadir = logs.where((h) => h.status == 'Hadir').length;
      final pct = (hadir / logs.length) * 100;
      final alpaInCourse = logs.where((h) => h.status == 'Alpa').length;
      return pct < 75 || alpaInCourse >= 3;
    }).toList();

    final bool hasAcademicRisk = atRiskCourses.isNotEmpty || alpaCount >= 3 || remainingAlpa <= 1;

    return Column(
      children: [
        // 1. Scan QR Quick Trigger Banner (Khusus Mahasiswa)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi Kuliah Mandiri',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pindai QR, masukkan PIN, atau ajukan izin/sakit',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleButton(
                    onTap: () => _showScanQrModal(context),
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF1E40AF)),
                          SizedBox(width: 4),
                          Text(
                            'Presensi',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ScaleButton(
                    onTap: () => _showAbsenceRequestSheet(context),
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Izin/Sakit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // EARLY WARNING CARD JIKA ADA RISIKO UAS
        if (hasAcademicRisk)
          _buildAcademicWarningCard(
            atRiskCourses: atRiskCourses,
            remainingAlpa: remainingAlpa,
            isDark: isDark,
          ),

        // 2. HERO ATTENDANCE CARD (Donut Progress + Safe Zone Status)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Kehadiran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semester Ganjil 2026/2027',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Safe Zone Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: totalSessions == 0
                          ? (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9))
                          : (isSafeZone
                              ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: totalSessions == 0
                            ? (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0))
                            : (isSafeZone ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          totalSessions == 0
                              ? Icons.schedule_rounded
                              : (isSafeZone ? Icons.check_circle_rounded : Icons.warning_amber_rounded),
                          size: 13,
                          color: totalSessions == 0
                              ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                              : (isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          totalSessions == 0
                              ? 'Belum Ada Sesi'
                              : (isSafeZone ? 'Syarat Ujian Aman' : 'Batas Kritis (<75%)'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: totalSessions == 0
                                ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                                : (isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Circular Gauge Donut
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: totalSessions > 0 ? attendanceRatio : 0.0,
                        strokeWidth: 11,
                        backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFEFF6FF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSessions == 0
                              ? const Color(0xFF94A3B8)
                              : (isSafeZone ? const Color(0xFF1E40AF) : const Color(0xFFEF4444)),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totalSessions > 0 ? '$attendancePercent%' : '0%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Kehadiran',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4 Stat Counters in a Row (Hadir, Izin, Sakit, Alpa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('$hadirCount', 'Hadir', const Color(0xFF10B981), isDark),
                  _buildStatBox('$izinCount', 'Izin', const Color(0xFFF59E0B), isDark),
                  _buildStatBox('$sakitCount', 'Sakit', const Color(0xFF3B82F6), isDark),
                  _buildStatBox('$alpaCount', 'Alpa', const Color(0xFFEF4444), isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Safe Tolerance Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toleransi Alpa: sisa $remainingAlpa kali dari maks 4 pertemuan sebelum tidak memenuhi syarat UAS.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. COURSE ATTENDANCE BREAKDOWN (Per Mata Kuliah)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kehadiran Per Mata Kuliah',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Text(
              '8 Mata Kuliah',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...DummyData.courses.map((course) {
          // Check personal logs for this course
          final courseLogs = _history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
          final courseHadir = courseLogs.where((h) => h.status == 'Hadir').length;
          final int coursePct = courseLogs.isNotEmpty ? ((courseHadir / courseLogs.length) * 100).round() : 100;
          final String badgeText = courseLogs.isNotEmpty ? '$coursePct% Hadir ($courseHadir/${courseLogs.length})' : 'Belum Ada Sesi';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCourseDetailModal(context, course, isDark),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E40AF), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.nama,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: courseLogs.isNotEmpty
                                ? (coursePct >= 75
                                    ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: courseLogs.isNotEmpty
                                  ? (coursePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pertemuan Indicator Matrix (P1 - P16) based on real sessions recorded
                    Row(
                      children: List.generate(16, (i) {
                        final pNum = i + 1;
                        final isRecorded = pNum <= courseLogs.length;
                        final bool isHadir = isRecorded && courseLogs[courseLogs.length - pNum].status == 'Hadir';

                        Color dotColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0);
                        if (isRecorded) {
                          dotColor = isHadir ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                        }

                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: dotColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          courseLogs.isNotEmpty ? '${courseLogs.length}/16 Sesi Terlaksana' : 'P1 Belum Dimulai',
                          style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
                        ),
                        Text(
                          'Ketuk untuk detail 16 sesi ›',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // 4. PERSONAL ATTENDANCE LOGS TIMELINE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Riwayat Scan Presensi Pribadi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (_history.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () => _confirmResetPersonalAttendance(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 15, color: Color(0xFFEF4444)),
                label: const Text(
                  'Kosongkan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'Terbaru',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_reg_rounded, size: 32, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum Ada Riwayat Presensi Pribadi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Presensi kuliah Anda melalui pemindaian QR Code atau lembar absensi kelas akan tercatat aman di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ..._history.map((h) => _buildHistoryTile(h, isDark)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111827)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(AttendanceHistoryItem item, bool isDark) {
    final isHadir = item.status == 'Hadir';
    final isIzin = item.status == 'Izin';
    final isSakit = item.status == 'Sakit';

    Color statusColor = const Color(0xFFEF4444);
    Color statusBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);

    if (isHadir) {
      statusColor = const Color(0xFF10B981);
      statusBg = isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5);
    } else if (isIzin) {
      statusColor = const Color(0xFFF59E0B);
      statusBg = isDark ? const Color(0xFF713F12) : const Color(0xFFFFFBEB);
    } else if (isSakit) {
      statusColor = const Color(0xFF3B82F6);
      statusBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.pertemuanKe != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'P${item.pertemuanKe}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Keterangan: ${item.catatan}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
