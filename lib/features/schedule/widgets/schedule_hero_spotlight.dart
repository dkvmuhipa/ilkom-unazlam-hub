import 'package:flutter/material.dart';
import '../../../core/services/course_schedule_service.dart';
import '../../../core/services/safe_launcher.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class ScheduleHeroSpotlight extends StatefulWidget {
  final List<Course> allCourses;
  final Function(Course course)? onCourseTap;

  const ScheduleHeroSpotlight({
    super.key,
    required this.allCourses,
    this.onCourseTap,
  });

  @override
  State<ScheduleHeroSpotlight> createState() => _ScheduleHeroSpotlightState();
}

class _ScheduleHeroSpotlightState extends State<ScheduleHeroSpotlight>
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
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Course? _findOngoingCourse(List<Course> todayCourses, DateTime now) {
    for (final c in todayCourses) {
      try {
        final startParts = c.jamMulai.split(':');
        final endParts = c.jamSelesai.split(':');
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
          return c;
        }
      } catch (_) {}
    }
    return null;
  }

  Course? _findNextUpcomingCourse(List<Course> todayCourses, DateTime now) {
    for (final c in todayCourses) {
      try {
        final startParts = c.jamMulai.split(':');
        final startDt = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        if (now.isBefore(startDt)) {
          return c;
        }
      } catch (_) {}
    }
    return null;
  }

  double _calculateProgress(Course c, DateTime now) {
    try {
      final startParts = c.jamMulai.split(':');
      final endParts = c.jamSelesai.split(':');
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
      final total = endDt.difference(startDt).inSeconds;
      final elapsed = now.difference(startDt).inSeconds;
      if (total <= 0) return 0.0;
      return (elapsed / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.5;
    }
  }

  int _calculateMinutesRemaining(Course c, DateTime now) {
    try {
      final endParts = c.jamSelesai.split(':');
      final endDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      return endDt.difference(now).inMinutes.clamp(0, 300);
    } catch (_) {
      return 0;
    }
  }

  int _calculateMinutesUntil(Course c, DateTime now) {
    try {
      final startParts = c.jamMulai.split(':');
      final startDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      return startDt.difference(now).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  bool _isOnline(Course c) {
    final r = c.ruangan.toLowerCase();
    final link = c.linkVirtual ?? '';
    return link.isNotEmpty ||
        r.contains('zoom') ||
        r.contains('online') ||
        r.contains('meet') ||
        r.contains('virtual');
  }

  bool _isHybrid(Course c) {
    return c.ruangan.toLowerCase().contains('hybrid');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayCourses = CourseScheduleService.getTodayCourses(
      widget.allCourses,
      now,
    );
    final ongoingCourse = _findOngoingCourse(todayCourses, now);
    final upcomingCourse = _findNextUpcomingCourse(todayCourses, now);
    final nextDayInfo = CourseScheduleService.getNextActiveDayInfo(
      widget.allCourses,
      now,
    );

    if (ongoingCourse != null) {
      return _buildOngoingHero(ongoingCourse, now);
    } else if (upcomingCourse != null) {
      return _buildUpcomingHero(upcomingCourse, now);
    } else {
      return _buildNoMoreClassesHero(nextDayInfo);
    }
  }

  Widget _buildOngoingHero(Course c, DateTime now) {
    final progress = _calculateProgress(c, now);
    final minutesLeft = _calculateMinutesRemaining(c, now);
    final isOnlineClass = _isOnline(c);

    return ScaleButton(
      onTap: () => widget.onCourseTap?.call(c),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF58138A), // UNAZLAM Logo Deep Purple
              Color(0xFF6D28D9), // UNAZLAM Royal Purple
              Color(0xFF7C3AED), // UNAZLAM Violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag: Live pulsing badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF86EFAC),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF86EFAC),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SEDANG BERLANGSUNG SEKARANG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$minutesLeft mnt lagi',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Course Title
              Text(
                c.nama,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Time & SKS
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${c.jamMulai} - ${c.jamSelesai} WITA (${c.sks} SKS)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF86EFAC),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Room / Link & Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnlineClass
                                  ? Icons.videocam_rounded
                                  : Icons.meeting_room_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnlineClass ? 'Online (Virtual)' : c.ruangan,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.dosen,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (c.linkVirtual != null && c.linkVirtual!.trim().isNotEmpty)
                        ScaleButton(
                          onTap: () => safeLaunchUrl(c.linkVirtual!.trim()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 13,
                                  color: Color(0xFF58138A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Gabung Meet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF58138A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Buka Kelas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF58138A),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Color(0xFF58138A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHero(Course c, DateTime now) {
    final minutesUntil = _calculateMinutesUntil(c, now);
    final isOnlineClass = _isOnline(c);
    final isHybridClass = _isHybrid(c);

    String timeLabel;
    if (minutesUntil < 60) {
      timeLabel = 'Dimulai $minutesUntil menit lagi';
    } else {
      final hours = minutesUntil ~/ 60;
      final mins = minutesUntil % 60;
      timeLabel = 'Dimulai dalam ${hours}j ${mins}m';
    }

    return ScaleButton(
      onTap: () => widget.onCourseTap?.call(c),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF58138A), // UNAZLAM Logo Deep Purple
              Color(0xFF6D28D9), // UNAZLAM Royal Purple
              Color(0xFF7C3AED), // UNAZLAM Bright Violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upcoming_rounded,
                          size: 13,
                          color: Color(0xFFFDE68A),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'KULIAH BERIKUTNYA HARI INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                c.nama,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Time
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Pukul ${c.jamMulai} - ${c.jamSelesai} WITA • ${c.sks} SKS',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mode badge & Dosen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnlineClass
                                  ? Icons.videocam_rounded
                                  : (isHybridClass
                                      ? Icons.sensors_rounded
                                      : Icons.meeting_room_outlined),
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnlineClass
                                  ? 'Online (Virtual)'
                                  : (isHybridClass ? 'Hybrid' : c.ruangan),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.dosen,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (c.linkVirtual != null && c.linkVirtual!.trim().isNotEmpty)
                        ScaleButton(
                          onTap: () => safeLaunchUrl(c.linkVirtual!.trim()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 12,
                                  color: Color(0xFF58138A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Link Meet',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF58138A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF58138A),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Color(0xFF58138A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMoreClassesHero(ScheduleDayInfo? nextDayInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF6D28D9),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semua Kelas Hari Ini Selesai! 🎉',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nextDayInfo != null
                      ? 'Kuliah berikutnya: ${nextDayInfo.dayLabel} (${nextDayInfo.courses.length} MK)'
                      : 'Waktunya istirahat atau belajar mandiri.',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
