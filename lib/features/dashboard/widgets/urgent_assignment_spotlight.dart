import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/models.dart';
import '../../assignments/assignments_screen.dart';

class UrgentAssignmentSpotlight extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    final now = DateTime.now();
    final due = assignment.deadline;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tugas Mendesak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                    letterSpacing: -0.3,
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
                    '$pendingCount Tugas Aktif',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => onNavigateTab(2), // Ke Tab Tugas
              borderRadius: BorderRadius.circular(8),
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

        // Spotlight Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AssignmentsScreen.showAssignmentDetail(
                context,
                assignment,
                userNim: student.nim,
                canManage: student.canManageAssignments,
                onStatusChanged: onRefresh,
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isOverdue || isUrgent) ? accentColor.withValues(alpha: 0.6) : borderColor,
                  width: (isOverdue || isUrgent) ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOverdue || isUrgent)
                        ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.08)
                        : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
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
                            Text(
                              assignment.courseName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: textSub,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignment.judul,
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
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formattedDeadline,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          AssignmentsScreen.showAssignmentDetail(
                            context,
                            assignment,
                            userNim: student.nim,
                            canManage: student.canManageAssignments,
                            onStatusChanged: onRefresh,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
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
                                assignment.status == 'dikumpulkan' ||
                                        assignment.status == 'selesai' ||
                                        assignment.status == 'dinilai'
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
          ),
        ),
      ],
    );
  }
}
