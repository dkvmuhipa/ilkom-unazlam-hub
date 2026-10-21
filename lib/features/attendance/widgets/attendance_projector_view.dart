import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/qr_widget.dart';
import '../models/attendance_models.dart';
import '../services/dynamic_attendance_service.dart';

/// Halaman Layar Lebar (Mode Presenter Proyektor / TV Kelas)
/// Dirancang untuk diproyeksikan ke layar proyektor atau smart TV di depan kelas.
/// Menampilkan QR Code ekstra besar, PIN 4 digit besar, timer 30 detik anti-cheat,
/// dan counter mahasiswa yang hadir secara real-time.
class AttendanceProjectorView extends StatefulWidget {
  final ActiveAttendanceSession active;
  final bool initialDynamicMode;
  final VoidCallback? onClosed;

  const AttendanceProjectorView({
    super.key,
    required this.active,
    this.initialDynamicMode = true,
    this.onClosed,
  });

  @override
  State<AttendanceProjectorView> createState() => _AttendanceProjectorViewState();
}

class _AttendanceProjectorViewState extends State<AttendanceProjectorView> {
  late bool _isDynamicMode;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _isDynamicMode = widget.initialDynamicMode;
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
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final qrSize = (isLandscape
                    ? (constraints.maxHeight * 0.52)
                    : (constraints.maxWidth * 0.65))
                .clamp(200.0, 320.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
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
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.cast_connected_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.courseName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Pertemuan ${active.pertemuanKe} • Mode Layar Lebar Proyektor Kelas',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white),
                          tooltip: 'Tutup Layar Lebar',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Anti-Fraud Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isDynamicMode
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDynamicMode
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isDynamicMode
                                ? Icons.verified_user_rounded
                                : Icons.lock_outline_rounded,
                            size: 18,
                            color: _isDynamicMode
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDynamicMode
                                ? 'PROTEKSI ANTI-JOKI AKTIF: QR & PIN BERPUTAR OTOMATIS'
                                : 'MODE PRESENSI STATIS AKTIF',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: _isDynamicMode
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Big QR Card with Live Rotation Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated rotation halo
                        if (_isDynamicMode)
                          Container(
                            width: qrSize + 36,
                            height: qrSize + 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  timerColor.withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                        // QR Box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              if (_isDynamicMode)
                                BoxShadow(
                                  color: timerColor.withValues(alpha: 0.3),
                                  blurRadius: 24,
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

                    const SizedBox(height: 20),

                    // Dynamic 30s Countdown Bar
                    if (_isDynamicMode) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        value: windowProgress,
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Penyegaran QR Otomatis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: timerColor.withValues(alpha: 0.15),
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
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'PIN 4 DIGIT KELAS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFC4B5FD),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pinDisplay,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFA78BFA),
                                      letterSpacing: 6,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Bagi mahasiswa berkamera rusak',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Token Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'KODE TOKEN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF93C5FD),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tokenDisplay,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF60A5FA),
                                      letterSpacing: 4,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Input manual alternatif',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bottom Status Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                '${active.attendedNims.length} Mahasiswa Hadir',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Text(
                                'Sesi berakhir dalam ${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
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
