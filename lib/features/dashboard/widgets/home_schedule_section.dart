import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/safe_launcher.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../../schedule/schedule_screen.dart';

class HomeScheduleSection extends StatefulWidget {
  final List<Course> todayCourses;
  final List<Course> upcomingCourses;
  final String nextActiveDayName;
  final String nextActiveDayLabel;
  final bool todayHasClasses;
  final bool todayClassesFinished;
  final bool isDark;
  final StudentProfile student;
  final Animation<double> livePulseAnimation;
  final VoidCallback onRefresh;
  final ValueChanged<int> onNavigateTab;

  const HomeScheduleSection({
    super.key,
    required this.todayCourses,
    required this.upcomingCourses,
    required this.nextActiveDayName,
    required this.nextActiveDayLabel,
    required this.todayHasClasses,
    required this.todayClassesFinished,
    required this.isDark,
    required this.student,
    required this.livePulseAnimation,
    required this.onRefresh,
    required this.onNavigateTab,
  });

  @override
  State<HomeScheduleSection> createState() => _HomeScheduleSectionState();
}

class _HomeScheduleSectionState extends State<HomeScheduleSection> {
  int _viewMode = 0; // 0 = Hari Ini, 1 = Mendatang

  @override
  void initState() {
    super.initState();
    if (!widget.todayHasClasses || widget.todayClassesFinished) {
      _viewMode = 1; // Default ke jadwal mendatang jika hari ini tidak ada kuliah / sudah selesai
    }
  }

  Future<void> _openWhatsAppDosen(String phone, String lecturerName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone =
        cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo Bapak/Ibu $lecturerName, saya ${widget.student.nama} (NIM: ${widget.student.nim}) dari S1 Ilmu Komunikasi UNAZLAM...',
    );
    final uri = Uri.parse('https://wa.me/$internationalPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openVirtualClass(String url) async {
    await safeLaunchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    final showToday = _viewMode == 0;
    final displayCourses = showToday ? widget.todayCourses : widget.upcomingCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with View Mode Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AKTIVITAS KULIAH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showToday
                      ? (widget.todayHasClasses
                          ? (widget.todayClassesFinished ? 'Semua Kuliah Selesai' : 'Jadwal Hari Ini')
                          : 'Bebas Kuliah Hari Ini')
                      : (widget.nextActiveDayLabel.isNotEmpty
                          ? widget.nextActiveDayLabel
                          : 'Jadwal Mendatang'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),

            // Toggle Pill: Hari Ini vs Mendatang
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _buildTogglePill(
                    label: 'Hari Ini',
                    isActive: _viewMode == 0,
                    badgeCount: widget.todayCourses.length,
                    onTap: () => setState(() => _viewMode = 0),
                  ),
                  _buildTogglePill(
                    label: widget.nextActiveDayName.isNotEmpty
                        ? widget.nextActiveDayName
                        : 'Mendatang',
                    isActive: _viewMode == 1,
                    badgeCount: widget.upcomingCourses.length,
                    onTap: () => setState(() => _viewMode = 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Courses Carousel or Free Day Card
        if (showToday && !widget.todayHasClasses) ...[
          _buildFreeDayCard(isDark),
        ] else if (displayCourses.isEmpty) ...[
          _buildEmptyCoursesCard(isDark, showToday),
        ] else ...[
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: displayCourses.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final course = displayCourses[index];
                return _buildCourseCard(
                  course: course,
                  isDark: isDark,
                  isUpcomingDay: !showToday,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isActive,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      scaleDown: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : (widget.isDark ? const Color(0xFF26223D) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? Colors.white
                        : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required Course course,
    required bool isDark,
    required bool isUpcomingDay,
  }) {
    final now = DateTime.now();
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';
    final isToday = !isUpcomingDay && (course.hari.trim().toLowerCase() == todayName.toLowerCase());

    bool isLiveNow = false;
    bool isUpcomingSoon = false;
    int minutesUntilStart = 0;

    if (isToday) {
      try {
        final startParts = course.jamMulai.split(':');
        final endParts = course.jamSelesai.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startDt = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]),
          );
          final endDt = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );

          if (now.isAfter(startDt) && now.isBefore(endDt)) {
            isLiveNow = true;
          } else if (now.isBefore(startDt)) {
            final diff = startDt.difference(now).inMinutes;
            if (diff >= 0 && diff <= 60) {
              isUpcomingSoon = true;
              minutesUntilStart = diff;
            }
          }
        }
      } catch (_) {}
    }

    final String timeBadgeLabel = isLiveNow
        ? 'BERLANGSUNG'
        : (isUpcomingSoon
            ? '$minutesUntilStart MNT LAGI'
            : (isToday
                ? '${course.jamMulai} - ${course.jamSelesai}'
                : '${course.hari} • ${course.jamMulai} - ${course.jamSelesai}'));

    return ScaleButton(
      scaleDown: 0.97,
      onTap: () {
        ScheduleScreen.showCourseDetail(
          context,
          course,
          canManage: widget.student.isKetuaKelas || widget.student.isAdmin,
          onCourseUpdated: widget.onRefresh,
        );
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLiveNow
                ? const Color(0xFF10B981)
                : (isUpcomingSoon ? const Color(0xFFF59E0B) : borderColor),
            width: (isLiveNow || isUpcomingSoon) ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isLiveNow
                  ? const Color(0xFF10B981).withValues(alpha: 0.16)
                  : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Time badge & Room
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isLiveNow
                        ? (isDark ? const Color(0xFF0F392B) : const Color(0xFFDCFCE7))
                        : (isUpcomingSoon
                            ? (isDark ? const Color(0xFF3D2E14) : const Color(0xFFFEF3C7))
                            : (isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLiveNow
                          ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                          : (isUpcomingSoon
                              ? const Color(0xFFD97706).withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLiveNow) ...[
                        AnimatedBuilder(
                          animation: widget.livePulseAnimation,
                          builder: (context, child) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: widget.livePulseAnimation.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          isUpcomingSoon ? Icons.access_time_rounded : Icons.schedule_rounded,
                          size: 11,
                          color: isUpcomingSoon ? const Color(0xFFB45309) : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        timeBadgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                          color: isLiveNow
                              ? const Color(0xFF15803D)
                              : (isUpcomingSoon
                                  ? const Color(0xFFB45309)
                                  : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 11, color: textSub),
                      const SizedBox(width: 3),
                      Text(
                        course.ruangan.isNotEmpty ? course.ruangan : 'Lab A',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Middle: Course Name & Lecturer
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.dosen} • ${course.sks} SKS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Bottom: WA Dosen & Virtual Meet
            Row(
              children: [
                if (course.dosenWa != null && course.dosenWa!.trim().isNotEmpty) ...[
                  ScaleButton(
                    scaleDown: 0.92,
                    onTap: () => _openWhatsAppDosen(course.dosenWa!, course.dosen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF25D366).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'WA Dosen',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (course.linkVirtual != null && course.linkVirtual!.trim().isNotEmpty) ...[
                  ScaleButton(
                    scaleDown: 0.92,
                    onTap: () => _openVirtualClass(course.linkVirtual!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text(
                            'Virtual Meet',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded, size: 13, color: textSub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeDayCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 24,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hari Bebas Kuliah! 🎉',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada perkuliahan hari ini. Manfaatkan untuk belajar mandiri atau rehat sejenak.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCoursesCard(bool isDark, bool isToday) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          isToday
              ? 'Tidak ada perkuliahan hari ini.'
              : 'Belum ada jadwal perkuliahan mendatang.',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
