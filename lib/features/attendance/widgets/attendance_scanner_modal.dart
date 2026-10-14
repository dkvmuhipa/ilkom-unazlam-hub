import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../attendance_screen.dart';

/// Ultra-modern, scannable QR & 4-digit PIN attendance verification modal
/// with animated laser viewfinder, discrete OTP boxes, torch toggle, and tactile feedback.
class AttendanceScannerModal {
  static ActiveAttendanceSession? get currentSession => AttendanceScreen.currentSession;
  static set currentSession(ActiveAttendanceSession? s) => AttendanceScreen.currentSession = s;

  static void show(
    BuildContext context, {
    required String userNim,
    List<Course> courses = const [],
    VoidCallback? onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttendanceScannerSheetContent(
        userNim: userNim,
        courses: courses,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _AttendanceScannerSheetContent extends StatefulWidget {
  final String userNim;
  final List<Course> courses;
  final VoidCallback? onSuccess;

  const _AttendanceScannerSheetContent({
    required this.userNim,
    this.courses = const [],
    this.onSuccess,
  });

  @override
  State<_AttendanceScannerSheetContent> createState() => _AttendanceScannerSheetContentState();
}

class _AttendanceScannerSheetContentState extends State<_AttendanceScannerSheetContent>
    with SingleTickerProviderStateMixin {
  late TextEditingController _tokenController;
  late TextEditingController _pinController;
  MobileScannerController? _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late String _selectedCourse;
  int _inputMode = kIsWeb ? 1 : 0; // 0: Kamera QR, 1: PIN 4 Digit
  bool _useLongToken = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _pinController = TextEditingController();

    final session = AttendanceScannerModal.currentSession;
    _selectedCourse = (session != null && !session.isExpired)
        ? session.courseName
        : (widget.courses.isNotEmpty ? widget.courses.first.nama : 'Mata Kuliah');

    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _pinController.dispose();
    _scannerController?.dispose();
    _laserController.dispose();
    super.dispose();
  }

  void _executeVerification(String tokenToVerify) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final targetSession = AttendanceScannerModal.currentSession;

    // 1. Validasi sesi aktif
    if (targetSession == null || targetSession.isExpired) {
      setState(() => _isProcessing = false);
      HapticFeedback.vibrate();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Tidak ada sesi presensi aktif atau sesi telah berakhir! Minta dosen/ketua kelas membuka sesi.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final activeNim = widget.userNim;

    // 2. Validasi Token atau PIN jika diberikan (trim & case-insensitive)
    final cleanInput = tokenToVerify.trim().toUpperCase();
    final cleanSessionToken = targetSession.token.trim().toUpperCase();
    final cleanPin = targetSession.pinCode.trim().toUpperCase();
    final bool isValidCode = cleanInput.isNotEmpty &&
        (cleanInput == cleanSessionToken || cleanInput == cleanPin);

    if (!isValidCode) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Kode PIN/Token salah. Periksa kembali PIN 4 digit yang dibagikan.';
      });
      HapticFeedback.vibrate();
      return;
    }

    // 3. Validasi duplikasi presensi
    if (targetSession.attendedNims.contains(activeNim)) {
      setState(() => _isProcessing = false);
      HapticFeedback.lightImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NIM $activeNim sudah tercatat hadir untuk sesi ${targetSession.courseName} ini!'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // Success Haptic Feedback
    HapticFeedback.heavyImpact();

    // Simpan ke sesi aktif & Supabase
    targetSession.attendedNims.add(activeNim);
    SupabaseRepository.logAttendance(
      courseId: targetSession.courseName,
      studentNim: activeNim,
      pertemuanKe: targetSession.pertemuanKe,
      status: 'Hadir',
      catatan: tokenToVerify.isNotEmpty ? 'Presensi Token: $tokenToVerify' : 'Presensi Scanner QR',
    ).then((_) {
      widget.onSuccess?.call();
    });

    Navigator.pop(context);

    // Show rich success bottom sheet
    _showSuccessVerificationDialog(context, targetSession, activeNim);
  }

  void _showSuccessVerificationDialog(
    BuildContext context,
    ActiveAttendanceSession session,
    String studentNim,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Presensi Berhasil Terverifikasi! 🎉',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Kehadiran Anda pada sesi perkuliahan telah tersimpan secara resmi.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Summary Info Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Mata Kuliah', session.courseName, isDark, bold: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Pertemuan Ke', 'Pertemuan ${session.pertemuanKe}', isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('NIM Mahasiswa', studentNim, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Status Kehadiran', 'HADIR (Verifikasi QR/PIN)', isDark, color: const Color(0xFF10B981)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ScaleButton(
                onTap: () => Navigator.pop(ctx),
                scaleDown: 0.95,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Selesai & Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String title, String val, bool isDark, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveSession = AttendanceScannerModal.currentSession;
    final bool hasLiveSession = (liveSession != null && !liveSession.isExpired);
    final bool isLiveForSelectedCourse = hasLiveSession && liveSession.courseName == _selectedCourse;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final m = (liveSession?.remainingSeconds ?? 0) ~/ 60;
    final s = (liveSession?.remainingSeconds ?? 0) % 60;
    final timerStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(22, 14, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi Kuliah Mahasiswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pindai QR dosen atau masukkan 4 digit PIN',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Segmented Switcher: Kamera QR vs PIN 4 Digit
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252538) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ScaleButton(
                    onTap: () => setState(() {
                      _inputMode = 0;
                      _errorMessage = null;
                    }),
                    scaleDown: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _inputMode == 0
                            ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _inputMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 15,
                            color: _inputMode == 0 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kamera QR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _inputMode == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _inputMode == 0 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ScaleButton(
                    onTap: () => setState(() {
                      _inputMode = 1;
                      _errorMessage = null;
                    }),
                    scaleDown: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _inputMode == 1
                            ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _inputMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pin_rounded,
                            size: 15,
                            color: _inputMode == 1 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PIN 4 Digit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _inputMode == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: _inputMode == 1 ? const Color(0xFF1E40AF) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
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

          // Course Dropdown Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedCourse,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Mata Kuliah Yang Dihadiri',
              labelStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: widget.courses.isEmpty
                ? [
                    DropdownMenuItem(
                      value: _selectedCourse,
                      child: Text(_selectedCourse, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    ),
                  ]
                : widget.courses.map((c) => DropdownMenuItem(
                      value: c.nama,
                      child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    )).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCourse = val;
                  _errorMessage = null;
                });
              }
            },
          ),

          const SizedBox(height: 10),

          // Active session notice pill
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
                          ? 'Sesi Presensi Aktif: ${liveSession.courseName} (Sisa $timerStr)'
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

          // MODE 0: SCANNER KAMERA WITH LASER VIEWFINDER
          if (_inputMode == 0) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!kIsWeb && _scannerController != null)
                    MobileScanner(
                      controller: _scannerController!,
                      fit: BoxFit.cover,
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final rawVal = barcode.rawValue;
                          if (rawVal != null && rawVal.isNotEmpty) {
                            _executeVerification(rawVal);
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
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Input 4 angka PIN sesi cepat tanpa akses kamera.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            ScaleButton(
                              onTap: () => setState(() => _inputMode = 1),
                              scaleDown: 0.95,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E40AF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Beralih ke PIN 4 Digit',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Viewfinder Frame & Animated Laser
                  if (!kIsWeb)
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          children: [
                            // 4 Corner Brackets
                            CustomPaint(
                              size: const Size(150, 150),
                              painter: _ScannerFramePainter(
                                color: isLiveForSelectedCourse ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                            // Animated Laser Line
                            AnimatedBuilder(
                              animation: _laserAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _laserAnimation.value * 140 + 5,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: isLiveForSelectedCourse ? const Color(0xFF34D399) : const Color(0xFF60A5FA),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isLiveForSelectedCourse ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Controls Overlay: Torch & Flip camera
                  if (!kIsWeb && _scannerController != null) ...[
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        children: [
                          // Torch Toggle
                          ScaleButton(
                            onTap: () async {
                              await _scannerController?.toggleTorch();
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                            scaleDown: 0.9,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                size: 16,
                                color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Camera Flip
                          ScaleButton(
                            onTap: () async {
                              await _scannerController?.switchCamera();
                            },
                            scaleDown: 0.9,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flip_camera_ios_rounded, size: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
                ],
              ),
            ),
          ],

          // MODE 1: DISCRETE 4-DIGIT PIN QUICK BOXES
          if (_inputMode == 1) ...[
            if (!_useLongToken) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Masukkan 4 Digit PIN Sesi Kuliah',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4-Digit Display Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final text = _pinController.text;
                        final digit = index < text.length ? text[index] : '';
                        final isCurrent = index == text.length;

                        return Container(
                          width: 54,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF1E40AF)
                                  : (digit.isNotEmpty
                                      ? const Color(0xFF3B82F6)
                                      : (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFCBD5E1))),
                              width: isCurrent ? 2.4 : 1.5,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit.isNotEmpty ? digit : (isCurrent ? '•' : ''),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isCurrent ? const Color(0xFF1E40AF) : (isDark ? Colors.white : const Color(0xFF111827)),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Numeric text field (hidden/styled to receive digits)
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Ketik 4 angka PIN di sini',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _errorMessage = null;
                        });
                        HapticFeedback.selectionClick();
                        if (val.trim().length == 4) {
                          _executeVerification(val.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _pinController.clear();
                            setState(() {});
                          },
                          child: const Text('Hapus PIN', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _useLongToken = true),
                          child: const Text('Gunakan Token Huruf', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Long token input
              TextField(
                controller: _tokenController,
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
                  onPressed: () => setState(() => _useLongToken = false),
                  child: const Text('Kembali ke PIN 4 Digit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                ),
              ),
            ],
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Main Submit Verification Button
          ScaleButton(
            onTap: _isProcessing
                ? null
                : () {
                    final code = (_inputMode == 1 && !_useLongToken)
                        ? _pinController.text.trim()
                        : _tokenController.text.trim();

                    if (code.isEmpty) {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan masukkan PIN 4 digit atau scan QR sesi presensi!'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }
                    _executeVerification(code);
                  },
            scaleDown: 0.96,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Verifikasi Kehadiran',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Absence footer link
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
                    Navigator.pop(context);
                    AttendanceScreen.showAbsenceRequestModal(
                      context,
                      userNim: widget.userNim,
                      preselectedCourse: _selectedCourse,
                      onSuccess: widget.onSuccess,
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
  }
}

/// Custom painter to draw 4 high-tech corner brackets around the scanner viewfinder
class _ScannerFramePainter extends CustomPainter {
  final Color color;

  _ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const cornerRadius = 12.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..arcToPoint(Offset(size.width, cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - cornerRadius)
      ..arcToPoint(Offset(cornerRadius, size.height), radius: const Radius.circular(cornerRadius))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..arcToPoint(Offset(size.width, size.height - cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) => oldDelegate.color != color;
}
