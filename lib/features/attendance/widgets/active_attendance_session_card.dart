import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/scale_button.dart';
import '../models/attendance_models.dart';

/// Ultra-modern, animated live card displaying active attendance session status
/// with pulsing indicator, countdown ring, 1-tap copy token/PIN, and quick action buttons.
class ActiveAttendanceSessionCard extends StatefulWidget {
  final ActiveAttendanceSession session;
  final String activeNim;
  final bool canManageClassAttendance;
  final bool isDark;
  final VoidCallback onShowScanQr;
  final VoidCallback onShowActiveQr;
  final VoidCallback onShowAbsenceRequest;
  final VoidCallback? onCloseSession;

  const ActiveAttendanceSessionCard({
    super.key,
    required this.session,
    required this.activeNim,
    required this.canManageClassAttendance,
    required this.isDark,
    required this.onShowScanQr,
    required this.onShowActiveQr,
    required this.onShowAbsenceRequest,
    this.onCloseSession,
  });

  @override
  State<ActiveAttendanceSessionCard> createState() => _ActiveAttendanceSessionCardState();
}

class _ActiveAttendanceSessionCardState extends State<ActiveAttendanceSessionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label "$value" berhasil disalin ke clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final secsLeft = session.remainingSeconds;
    final isUrgent = secsLeft < 180; // Less than 3 minutes
    final hasAttended = session.attendedNims.contains(widget.activeNim);

    // Calculate elapsed ratio
    final totalDuration = session.expiresAt.difference(session.startTime).inSeconds;
    final durationSanitized = totalDuration > 0 ? totalDuration : 900;
    final progress = (secsLeft / durationSanitized).clamp(0.0, 1.0);

    final statusColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final accentGlow = isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDark
                  ? [
                      isUrgent ? const Color(0xFF381014) : const Color(0xFF072418),
                      isUrgent ? const Color(0xFF1C0A0C) : const Color(0xFF0F172A),
                    ]
                  : [
                      isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                      isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFF5F3FF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: statusColor.withValues(
                alpha: widget.isDark ? 0.35 + (_pulseAnimation.value - 1.0) * 0.2 : 0.45,
              ),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: accentGlow.withValues(
                  alpha: widget.isDark ? 0.25 * _pulseAnimation.value : 0.12 * _pulseAnimation.value,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Live pulse badge & Countdown timer pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Breathing Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: widget.isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isUrgent ? 'SEGERA BERAKHIR' : 'SESI PRESENSI AKTIF',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Countdown Ring / Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: widget.isDark ? 0.4 : 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2.5,
                              backgroundColor: widget.isDark ? Colors.white12 : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _formatTimer(secsLeft),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Course Name & Pertemuan ke-N
                Text(
                  session.courseName,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9).withValues(alpha: widget.isDark ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pertemuan ${session.pertemuanKe}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Batas: ${_formatTimer(secsLeft)} tersisa',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Token & PIN Copyable Row
                Row(
                  children: [
                    // TOKEN Chip
                    Expanded(
                      child: ScaleButton(
                        onTap: () => _copyToClipboard(context, 'Token', session.token),
                        scaleDown: 0.96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.vpn_key_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOKEN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      session.token,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2563EB),
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: widget.isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // PIN Chip
                    Expanded(
                      child: ScaleButton(
                        onTap: () => _copyToClipboard(context, 'PIN', session.pinCode),
                        scaleDown: 0.96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_rounded, size: 14, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PIN CEPAT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      session.pinCode,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF7C3AED),
                                        letterSpacing: 1.2,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: widget.isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Attended status row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 13, color: Color(0xFF6D28D9)),
                          const SizedBox(width: 5),
                          Text(
                            '${session.attendedNims.length} Mahasiswa Hadir',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: hasAttended
                              ? (widget.isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                              : (widget.isDark ? const Color(0xFF3F2C0E) : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasAttended
                                ? (widget.isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC))
                                : (widget.isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasAttended ? Icons.check_circle_rounded : Icons.pending_rounded,
                              size: 13,
                              color: hasAttended ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                hasAttended ? 'Kamu Sudah Hadir' : 'Menunggu Presensi Kamu',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: hasAttended ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Buttons Row
                if (widget.canManageClassAttendance) ...[
                  // For Ketua / Dosen: Lihat QR & Tutup Sesi
                  Row(
                    children: [
                      Expanded(
                        child: ScaleButton(
                          onTap: widget.onShowActiveQr,
                          scaleDown: 0.95,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6D28D9), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Tampilkan QR Proyektor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.onCloseSession != null) ...[
                        const SizedBox(width: 8),
                        ScaleButton(
                          onTap: widget.onCloseSession,
                          scaleDown: 0.95,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.isDark ? const Color(0xFF2E1A1A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              children: [
                                Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626), size: 15),
                                SizedBox(width: 5),
                                Text(
                                  'Tutup Sesi',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // For Student: Presensi Sekarang / Ajukan Izin / Lihat QR
                  Row(
                    children: [
                      if (!hasAttended) ...[
                        Expanded(
                          flex: 3,
                          child: ScaleButton(
                            onTap: widget.onShowScanQr,
                            scaleDown: 0.95,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Presensi Sekarang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ScaleButton(
                            onTap: widget.onShowAbsenceRequest,
                            scaleDown: 0.95,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.isDark ? const Color(0xFF2E2415) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_outlined,
                                    color: widget.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Izin/Sakit',
                                    style: TextStyle(
                                      color: widget.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ScaleButton(
                            onTap: widget.onShowActiveQr,
                            scaleDown: 0.95,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.isDark ? const Color(0xFF3B82F6) : const Color(0xFFDDD6FE),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lihat Detail / QR Sesi',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
