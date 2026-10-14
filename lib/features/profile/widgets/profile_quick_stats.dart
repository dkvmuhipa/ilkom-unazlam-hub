import 'package:flutter/material.dart';
import '../../../core/widgets/scale_button.dart';

/// 4 Academic overview capsules for Semester, SKS, Classroom, and Attendance
class ProfileQuickStats extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenClassInfo;

  const ProfileQuickStats({
    super.key,
    required this.isDark,
    required this.onOpenAttendance,
    required this.onOpenSchedule,
    required this.onOpenClassInfo,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCapsule(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                title: 'Semester 1',
                subtitle: 'Ganjil 2026/2027',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCapsule(
                icon: Icons.auto_stories_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFD97706).withValues(alpha: isDark ? 0.2 : 0.1),
                title: '20 SKS',
                subtitle: '8 Mata Kuliah Aktif',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: onOpenSchedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCapsule(
                icon: Icons.meeting_room_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                title: 'Ruang A2',
                subtitle: 'FISIP • Info Kelas ➔',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: onOpenClassInfo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCapsule(
                icon: Icons.fact_check_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.1),
                title: 'Presensi',
                subtitle: 'Buka Rekap Kehadiran ➔',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: const Color(0xFF8B5CF6),
                onTap: onOpenAttendance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapsule({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return ScaleButton(
        onTap: onTap,
        scaleDown: 0.96,
        child: content,
      );
    }
    return content;
  }
}
