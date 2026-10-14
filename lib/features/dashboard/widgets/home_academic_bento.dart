import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/scale_button.dart';

class HomeAcademicBento extends StatelessWidget {
  final int? attendancePercent;
  final int hadirCount;
  final int totalAttendance;
  final bool? isKasLunas;
  final int kasNominal;
  final String currentPeriodLabel;
  final int todayCoursesCount;
  final bool todayClassesFinished;
  final int pendingAssignmentsCount;
  final bool isDark;
  final ValueChanged<int> onNavigateTab;

  const HomeAcademicBento({
    super.key,
    required this.attendancePercent,
    required this.hadirCount,
    required this.totalAttendance,
    required this.isKasLunas,
    required this.kasNominal,
    required this.currentPeriodLabel,
    required this.todayCoursesCount,
    required this.todayClassesFinished,
    required this.pendingAssignmentsCount,
    required this.isDark,
    required this.onNavigateTab,
  });

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isAttendanceSafe = attendancePercent != null && attendancePercent! >= 75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Eyebrow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RINGKASAN AKADEMIK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF94A3B8),
              ),
            ),
            ScaleButton(
              scaleDown: 0.95,
              onTap: () => onNavigateTab(15), // KHS
              child: const Row(
                children: [
                  Text(
                    'Lihat KHS & Nilai',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2x2 Bento Grid
        Row(
          children: [
            // Tile 1: Presensi Kehadiran
            Expanded(
              child: _buildBentoTile(
                title: 'Presensi',
                value: attendancePercent == null ? '-' : '$attendancePercent%',
                subValue: attendancePercent == null
                    ? 'Belum ada data'
                    : (isAttendanceSafe ? 'Aman UAS ($hadirCount Hadir)' : 'Pantau Presensi'),
                icon: Icons.how_to_reg_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                cardBg: cardBg,
                borderColor: borderColor,
                textMain: textMain,
                textSub: textSub,
                progressBarValue: attendancePercent == null ? null : (attendancePercent! / 100),
                progressBarColor: isAttendanceSafe
                    ? const Color(0xFF10B981)
                    : (attendancePercent! >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                onTap: () => onNavigateTab(5), // Presensi
              ),
            ),
            const SizedBox(width: 10),

            // Tile 2: Kas Kelas
            Expanded(
              child: _buildBentoTile(
                title: 'Kas Kelas',
                value: isKasLunas == true
                    ? 'Lunas'
                    : (isKasLunas == false ? _formatCurrency(kasNominal) : 'Iuran Kas'),
                subValue: isKasLunas == true
                    ? 'Terverifikasi Bendahara'
                    : (isKasLunas == false ? 'Perlu Dibayar' : currentPeriodLabel),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF0D9488),
                iconBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                cardBg: cardBg,
                borderColor: borderColor,
                textMain: textMain,
                textSub: textSub,
                statusChip: isKasLunas == true
                    ? 'LUNAS'
                    : (isKasLunas == false ? 'BELUM' : null),
                statusChipColor: isKasLunas == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                onTap: () => onNavigateTab(8), // Kas Kelas
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // Tile 3: Jadwal Kuliah Hari Ini
            Expanded(
              child: _buildBentoTile(
                title: 'Jadwal Hari Ini',
                value: todayCoursesCount > 0 ? '$todayCoursesCount Kuliah' : 'Bebas Kuliah',
                subValue: todayCoursesCount > 0
                    ? (todayClassesFinished ? 'Perkuliahan selesai' : 'Ada kuliah terjadwal')
                    : 'Tidak ada jam kuliah',
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF4F46E5),
                iconBg: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                cardBg: cardBg,
                borderColor: borderColor,
                textMain: textMain,
                textSub: textSub,
                onTap: () => onNavigateTab(4), // Jadwal Kuliah
              ),
            ),
            const SizedBox(width: 10),

            // Tile 4: Tugas & Deadline
            Expanded(
              child: _buildBentoTile(
                title: 'Tugas Kuliah',
                value: pendingAssignmentsCount > 0 ? '$pendingAssignmentsCount Tugas' : 'Bebas Tugas',
                subValue: pendingAssignmentsCount > 0
                    ? 'Perlu dikerjakan'
                    : 'Semua tugas tuntas',
                icon: Icons.assignment_turned_in_rounded,
                iconColor: const Color(0xFFE11D48),
                iconBg: isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6),
                cardBg: cardBg,
                borderColor: borderColor,
                textMain: textMain,
                textSub: textSub,
                statusChip: pendingAssignmentsCount > 0 ? '$pendingAssignmentsCount' : null,
                statusChipColor: const Color(0xFFE11D48),
                onTap: () => onNavigateTab(3), // Tugas
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required Color textMain,
    required Color textSub,
    double? progressBarValue,
    Color? progressBarColor,
    String? statusChip,
    Color? statusChipColor,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      scaleDown: 0.96,
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Chip / Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                if (statusChip != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (statusChipColor ?? const Color(0xFF10B981)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (statusChipColor ?? const Color(0xFF10B981)).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      statusChip,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: statusChipColor ?? const Color(0xFF10B981),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: textSub.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Value & Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Progress bar if available
                if (progressBarValue != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progressBarValue.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressBarColor ?? const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                Text(
                  subValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
