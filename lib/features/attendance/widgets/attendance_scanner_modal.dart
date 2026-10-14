import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../attendance_screen.dart';

class AttendanceScannerModal {
  static ActiveAttendanceSession? get currentSession => AttendanceScreen.currentSession;
  static set currentSession(ActiveAttendanceSession? s) => AttendanceScreen.currentSession = s;

  static void show(
    BuildContext context, {
    required String userNim,
    List<Course> courses = const [],
    VoidCallback? onSuccess,
  }) {
    final tokenController = TextEditingController();
    final pinController = TextEditingController();
    final session = currentSession;

    String selectedCourse = (session != null && !session.isExpired)
        ? session.courseName
        : (courses.isNotEmpty ? courses.first.nama : 'Mata Kuliah');

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
                  items: courses.isEmpty
                      ? [
                          DropdownMenuItem(
                            value: selectedCourse,
                            child: Text(selectedCourse, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ]
                      : courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
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
}
