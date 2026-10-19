import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../../assignments/assignments_screen.dart';

class UrgentAssignmentSpotlight extends StatefulWidget {
  final Assignment assignment;
  final int pendingCount;
  final bool isDark;
  final StudentProfile student;
  final void Function(int) onNavigateTab;
  final VoidCallback onRefresh;

  const UrgentAssignmentSpotlight({
    super.key,
    required this.assignment,
    required this.pendingCount,
    required this.isDark,
    required this.student,
    required this.onNavigateTab,
    required this.onRefresh,
  });

  @override
  State<UrgentAssignmentSpotlight> createState() => _UrgentAssignmentSpotlightState();
}

class _UrgentAssignmentSpotlightState extends State<UrgentAssignmentSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    final now = DateTime.now();
    final due = widget.assignment.deadline;
    final diff = due.difference(now);
    final inDays = diff.inDays;
    final inHours = diff.inHours;

    final bool isOverdue = diff.isNegative;
    final bool isUrgent = inHours <= 24; // H-1 atau hari H
    final bool isWarning = inDays <= 3; // H-3

    Color accentColor = const Color(0xFF0284C7); // Biru (Normal)
    Color badgeBg = isDark ? const Color(0xFF1E2E42) : const Color(0xFFE0F2FE);
    String statusLabel = '${inDays + 1} hari lagi';

    if (isOverdue) {
      accentColor = const Color(0xFFEF4444); // Merah
      badgeBg = isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2);
      statusLabel = 'Lewat Tenggat';
    } else if (isUrgent) {
      accentColor = const Color(0xFFEF4444); // Merah mencolok
      badgeBg = isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2);
      final hoursRemaining = inHours.clamp(0, 24);
      statusLabel = hoursRemaining <= 0 ? 'Hari ini' : '$hoursRemaining jam lagi';
    } else if (isWarning) {
      accentColor = const Color(0xFFF59E0B); // Kuning/Oranye
      badgeBg = isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB);
      statusLabel = '$inDays hari lagi';
    }

    final formattedDeadline = DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID').format(due);

    final bool shouldPulse = isOverdue || isUrgent;

    return Semantics(
      label: 'Sorotan Tugas Mendesak: ${widget.assignment.judul}, batas waktu: $formattedDeadline',
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Tugas Mendesak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textMain,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.pendingCount} Tugas Aktif',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ScaleButton(
                  scaleDown: 0.94,
                  onTap: () => widget.onNavigateTab(2), // Ke Tab Tugas
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Spotlight Card with Animated Glow if Urgent
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseAlpha = shouldPulse ? _pulseAnimation.value : 0.04;
                final borderAlpha = shouldPulse ? (_pulseAnimation.value + 0.3).clamp(0.0, 1.0) : 1.0;

                return ScaleButton(
                  scaleDown: 0.98,
                  onTap: () {
                    AssignmentsScreen.showAssignmentDetail(
                      context,
                      widget.assignment,
                      userNim: widget.student.nim,
                      canManage: widget.student.canManageAssignments,
                      onStatusChanged: widget.onRefresh,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: shouldPulse
                            ? accentColor.withValues(alpha: borderAlpha)
                            : borderColor,
                        width: shouldPulse ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shouldPulse
                              ? const Color(0xFFEF4444).withValues(alpha: pulseAlpha)
                              : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: shouldPulse ? 14 : 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Atas: Nama Matkul & Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          (isOverdue || isUrgent) ? Icons.warning_amber_rounded : Icons.assignment_late_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.assignment.courseName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSub,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.assignment.kategori.trim().isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF26223D)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF3B3358)
                                            : const Color(0xFFE2E8F0),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      widget.assignment.kategori,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: textSub,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.assignment.judul,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: textMain,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge Countdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (isOverdue || isUrgent) ? Icons.timer_outlined : Icons.schedule_rounded,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Divider Halus
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 10),

                  // Row Bawah: Info Deadline & Tombol Aksi Cepat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                formattedDeadline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaleButton(
                        scaleDown: 0.92,
                        onTap: () {
                          AssignmentsScreen.showAssignmentDetail(
                            context,
                            widget.assignment,
                            userNim: widget.student.nim,
                            canManage: widget.student.canManageAssignments,
                            onStatusChanged: widget.onRefresh,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isOverdue || isUrgent) ? const Color(0xFFDC2626) : AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: ((isOverdue || isUrgent) ? const Color(0xFFDC2626) : AppColors.primary)
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.assignment.status == 'dikumpulkan' ||
                                        widget.assignment.status == 'selesai' ||
                                        widget.assignment.status == 'dinilai'
                                    ? 'Lihat Detail'
                                    : 'Kumpul',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                            ],
                          ),
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
  }
}
