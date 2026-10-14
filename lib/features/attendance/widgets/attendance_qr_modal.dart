import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/qr_widget.dart';
import '../../../core/widgets/scale_button.dart';
import '../models/attendance_models.dart';

/// Ultra-modern modal presenting the active attendance session's QR code,
/// quick-copy Token & PIN, live countdown timer, and attended roster count.
class AttendanceQrModal {
  static void show(
    BuildContext context, {
    required ActiveAttendanceSession active,
    VoidCallback? onClosed,
  }) {
    if (active.isExpired) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttendanceQrModalContent(
        active: active,
        onClosed: onClosed,
      ),
    );
  }
}

class _AttendanceQrModalContent extends StatefulWidget {
  final ActiveAttendanceSession active;
  final VoidCallback? onClosed;

  const _AttendanceQrModalContent({
    required this.active,
    this.onClosed,
  });

  @override
  State<_AttendanceQrModalContent> createState() => _AttendanceQrModalContentState();
}

class _AttendanceQrModalContentState extends State<_AttendanceQrModalContent> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
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

  void _copy(String label, String val) {
    Clipboard.setData(ClipboardData(text: val));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label "$val" berhasil disalin!'),
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
    final active = widget.active;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secsLeft = active.remainingSeconds;
    final isUrgent = secsLeft < 180;

    final totalDuration = active.expiresAt.difference(active.startTime).inSeconds;
    final durationSanitized = totalDuration > 0 ? totalDuration : 900;
    final progress = (secsLeft / durationSanitized).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pertemuan ${active.pertemuanKe} • QR Sesi Presensi Aktif',
                      style: TextStyle(
                        fontSize: 11.5,
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

          const SizedBox(height: 18),

          // QR Box with clean white background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: QrCodeWidget(
              data: active.token,
              size: 210,
            ),
          ),

          const SizedBox(height: 16),

          // Token & PIN Copyable Chips
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  onTap: () => _copy('Token', active.token),
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252538) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.vpn_key_rounded, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOKEN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              active.token,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScaleButton(
                  onTap: () => _copy('PIN', active.pinCode),
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252538) : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pin_rounded, size: 15, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PIN CEPAT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              active.pinCode,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Attendance Status and Countdown Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 6),
                    Text(
                      '${active.attendedNims.length} Mahasiswa Hadir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.2,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa: ${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Sorotkan ke layar proyektor ruang kelas atau bagikan PIN 4 digit kepada rekan mahasiswa untuk presensi instan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
