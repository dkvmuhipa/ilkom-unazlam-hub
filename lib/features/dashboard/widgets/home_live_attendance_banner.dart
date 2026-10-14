import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../../attendance/attendance_screen.dart';

class HomeLiveAttendanceBanner extends StatefulWidget {
  final StudentProfile student;
  final bool isDark;
  final VoidCallback onRefresh;
  final ValueChanged<int> onNavigateTab;

  const HomeLiveAttendanceBanner({
    super.key,
    required this.student,
    required this.isDark,
    required this.onRefresh,
    required this.onNavigateTab,
  });

  @override
  State<HomeLiveAttendanceBanner> createState() => _HomeLiveAttendanceBannerState();
}

class _HomeLiveAttendanceBannerState extends State<HomeLiveAttendanceBanner> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (AttendanceScreen.currentSession != null) {
        setState(() {});
        if (AttendanceScreen.currentSession!.isExpired) {
          timer.cancel();
          widget.onRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AttendanceScreen.currentSession;
    final isDark = widget.isDark;

    // 1. Jika ada sesi aktif
    if (session != null && !session.isExpired) {
      final remaining = session.expiresAt.difference(DateTime.now());
      final minStr = remaining.inMinutes.toString().padLeft(2, '0');
      final secStr = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      final attended = session.attendedNims.contains(widget.student.nim);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SESI PRESENSI AKTIF',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFFDE047)),
                      const SizedBox(width: 4),
                      Text(
                        '$minStr:$secStr',
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Course Name
            Text(
              session.courseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              attended
                  ? 'Kamu sudah terdata hadir pada sesi ini 🎉'
                  : 'Pertemuan ke-${session.pertemuanKe} • Scan QR sekarang',
              style: TextStyle(
                fontSize: 12,
                color: attended ? const Color(0xFF6EE7B7) : Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Scan Action Button
            ScaleButton(
              scaleDown: 0.96,
              onTap: () {
                if (!widget.student.canManageAttendance && !attended) {
                  AttendanceScreen.showStudentScanner(
                    context,
                    userNim: widget.student.nim,
                    onSuccess: widget.onRefresh,
                  );
                } else {
                  widget.onNavigateTab(5); // Presensi
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.student.canManageAttendance
                          ? Icons.qr_code_rounded
                          : (attended ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded),
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.student.canManageAttendance
                          ? 'Kelola Kode QR Presensi'
                          : (attended ? 'Lihat Detail Presensi' : 'Scan QR Presensi Sekarang'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Jika pengurus & belum ada sesi aktif: prompt buka presensi
    if (widget.student.canManageAttendance) {
      final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
      final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

      return ScaleButton(
        scaleDown: 0.98,
        onTap: () => widget.onNavigateTab(5), // Buka Presensi
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buka Sesi Presensi Kuliah',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Jadwalkan & tampilkan QR code presensi kelas',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
