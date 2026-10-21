import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/qr_widget.dart';
import '../models/attendance_models.dart';
import '../services/dynamic_attendance_service.dart';

/// Halaman Layar Lebar (Mode Presenter Proyektor / TV Kelas)
/// Dirancang untuk diproyeksikan ke layar proyektor atau smart TV di depan kelas.
/// Menampilkan QR Code ekstra besar, PIN 4 digit besar, timer 30 detik anti-cheat,
/// dan counter mahasiswa yang hadir secara real-time.
///
/// Secara default menggunakan tema terang (Light Mode) yang bersih, profesional,
/// dan elegan sesuai kebutuhan ruang kelas, dengan opsi beralih ke tema gelap.
class AttendanceProjectorView extends StatefulWidget {
  final ActiveAttendanceSession active;
  final bool initialDynamicMode;
  final bool defaultDarkMode;
  final VoidCallback? onClosed;

  const AttendanceProjectorView({
    super.key,
    required this.active,
    this.initialDynamicMode = true,
    this.defaultDarkMode = false,
    this.onClosed,
  });

  @override
  State<AttendanceProjectorView> createState() => _AttendanceProjectorViewState();
}

class _AttendanceProjectorViewState extends State<AttendanceProjectorView> {
  late bool _isDynamicMode;
  late bool _isDarkMode;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _isDynamicMode = widget.initialDynamicMode;
    _isDarkMode = widget.defaultDarkMode;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.active.isExpired) {
        _ticker?.cancel();
        Navigator.maybePop(context);
        widget.onClosed?.call();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final secsLeft = active.remainingSeconds;
    final isUrgent = secsLeft < 180;

    final dynamicInfo = _isDynamicMode
        ? DynamicAttendanceService.generate(active)
        : null;

    final qrData = _isDynamicMode ? dynamicInfo!.qrPayload : active.token;
    final pinDisplay = _isDynamicMode ? dynamicInfo!.dynamicPin : active.pinCode;
    final tokenDisplay = _isDynamicMode ? dynamicInfo!.dynamicToken : active.token;

    final windowSecs = dynamicInfo?.secondsRemaining ?? 30;
    final windowProgress = dynamicInfo?.progress ?? 1.0;

    // Window indicator color: emerald green -> amber -> red
    final Color timerColor = windowSecs > 10
        ? const Color(0xFF10B981)
        : (windowSecs > 4 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final qrSize = (isLandscape
                    ? (constraints.maxHeight * 0.48)
                    : (constraints.maxWidth * 0.60))
                .clamp(180.0, 300.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 28).clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top App Bar in Projector Mode
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: _isDarkMode ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: _isDarkMode ? 0.3 : 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.cast_connected_rounded,
                            color: Color(0xFF059669),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.courseName,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Pertemuan ${active.pertemuanKe} • Mode Layar Lebar Proyektor Kelas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dark / Light Mode Switch
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isDarkMode = !_isDarkMode;
                            });
                          },
                          icon: Icon(
                            _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                            color: _isDarkMode ? Colors.amber : const Color(0xFF475569),
                            size: 20,
                          ),
                          tooltip: _isDarkMode ? 'Beralih ke Tampilan Terang' : 'Beralih ke Tampilan Gelap',
                          style: IconButton.styleFrom(
                            backgroundColor: _isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Close / Exit Screen
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            size: 20,
                          ),
                          tooltip: 'Tutup Layar Lebar',
                          style: IconButton.styleFrom(
                            backgroundColor: _isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Anti-Fraud Banner (Responsive & Never Overflows)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? (_isDynamicMode
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.06))
                              : (_isDynamicMode
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isDarkMode
                                ? (_isDynamicMode
                                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                    : Colors.white12)
                                : (_isDynamicMode
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDynamicMode
                                  ? Icons.verified_user_rounded
                                  : Icons.lock_outline_rounded,
                              size: 16,
                              color: _isDynamicMode
                                  ? const Color(0xFF059669)
                                  : (_isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isDynamicMode
                                    ? 'PROTEKSI ANTI-JOKI AKTIF: QR & PIN BERPUTAR OTOMATIS'
                                    : 'MODE PRESENSI STATIS AKTIF',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: _isDarkMode
                                      ? (_isDynamicMode
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade300)
                                      : (_isDynamicMode
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF475569)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Big QR Card with Live Rotation Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated rotation halo
                        if (_isDynamicMode)
                          Container(
                            width: qrSize + 32,
                            height: qrSize + 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  timerColor.withValues(alpha: _isDarkMode ? 0.25 : 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                        // QR Box
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: _isDynamicMode
                                  ? timerColor.withValues(alpha: 0.4)
                                  : (_isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isDarkMode
                                    ? Colors.black.withValues(alpha: 0.4)
                                    : const Color(0xFF0F172A).withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              if (_isDynamicMode)
                                BoxShadow(
                                  color: timerColor.withValues(alpha: _isDarkMode ? 0.25 : 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: QrCodeWidget(
                            data: qrData,
                            size: qrSize,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dynamic 30s Countdown Bar
                    if (_isDynamicMode) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          value: windowProgress,
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                                          backgroundColor: _isDarkMode
                                              ? Colors.white12
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Penyegaran QR Otomatis',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _isDarkMode
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: timerColor.withValues(alpha: _isDarkMode ? 0.15 : 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${windowSecs}s',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: timerColor,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: windowProgress,
                                minHeight: 6,
                                backgroundColor: _isDarkMode
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Oversized 4-Digit PIN & Quick Token Display
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Giant PIN Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isDarkMode
                                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                                      : const Color(0xFFDDD6FE),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  if (!_isDarkMode)
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'PIN 4 DIGIT KELAS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _isDarkMode
                                          ? const Color(0xFFC4B5FD)
                                          : const Color(0xFF7C3AED),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      pinDisplay,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: _isDarkMode
                                            ? const Color(0xFFA78BFA)
                                            : const Color(0xFF6D28D9),
                                        letterSpacing: 6,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bagi mahasiswa berkamera rusak',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _isDarkMode
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Token Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isDarkMode
                                      ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                                      : const Color(0xFFBAE6FD),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  if (!_isDarkMode)
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'KODE TOKEN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _isDarkMode
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF0284C7),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      tokenDisplay,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: _isDarkMode
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF0369A1),
                                        letterSpacing: 4,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Input manual alternatif',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _isDarkMode
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Bottom Status Bar (Responsive with Wrap to prevent overflow)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            if (!_isDarkMode)
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    size: 18,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${active.attendedNims.length} Mahasiswa Hadir',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sisa Sesi: ${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isUrgent
                                          ? const Color(0xFFEF4444)
                                          : (_isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
