import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/models.dart';

class HomeBannerCarousel extends StatefulWidget {
  final List<Course> todayCourses;
  final List<Course> upcomingCourses;
  final String? upcomingDayLabel;
  final Assignment? nextAssignment;
  final Announcement? latestAnnouncement;
  final bool hasLoadError;
  final void Function(int) onNavigateTab;

  const HomeBannerCarousel({
    super.key,
    required this.todayCourses,
    required this.upcomingCourses,
    this.upcomingDayLabel,
    required this.nextAssignment,
    required this.latestAnnouncement,
    required this.hasLoadError,
    required this.onNavigateTab,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HeroSlide {
  final String label, title, detail, action;
  final IconData icon;
  final int destination;
  const _HeroSlide(
    this.label,
    this.title,
    this.detail,
    this.action,
    this.icon,
    this.destination,
  );
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _slides().length) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  List<_HeroSlide> _slides() {
    final now = DateTime.now();
    final slides = <_HeroSlide>[
      _HeroSlide(
        widget.hasLoadError ? 'DATA TERAKHIR' : 'RINGKASAN HARI INI',
        widget.hasLoadError
            ? 'Pembaruan data belum tersedia'
            : 'Aktivitas akademik Anda',
        widget.hasLoadError
            ? 'Periksa koneksi. Informasi yang tersedia mungkin belum diperbarui.'
            : '${widget.todayCourses.length} jadwal kuliah hari ini. Geser untuk melihat informasi akademik lainnya.',
        'Lihat jadwal',
        Icons.school_rounded,
        1,
      ),
    ];
    final activeClass = _activeOrNextClass(now);
    if (activeClass != null) {
      final (course, status, upcoming) = activeClass;
      final location = course.isOnlineOverride
          ? 'Kelas daring'
          : course.effectiveRuangan;
      slides.add(
        _HeroSlide(
          status,
          course.nama,
          '${upcoming ? '${widget.upcomingDayLabel ?? course.hari} · ' : ''}${course.effectiveJamMulai}–${course.effectiveJamSelesai} · ${location.isEmpty ? 'Lokasi belum tersedia' : location}',
          'Lihat jadwal',
          Icons.calendar_month_rounded,
          1,
        ),
      );
    }
    final assignment = widget.nextAssignment;
    if (assignment != null) {
      slides.add(
        _HeroSlide(
          assignment.deadline.isBefore(now)
              ? 'TUGAS MELEWATI TENGGAT'
              : 'TUGAS TERDEKAT',
          assignment.judul.isEmpty
              ? 'Tugas ${assignment.courseName}'
              : assignment.judul,
          '${assignment.courseName} · ${DateFormat('d MMM, HH:mm', 'id_ID').format(assignment.deadline.toLocal())}',
          'Lihat tugas',
          Icons.assignment_rounded,
          2,
        ),
      );
    }
    final announcement = widget.latestAnnouncement;
    if (announcement != null) {
      slides.add(
        _HeroSlide(
          'PENGUMUMAN TERBARU',
          announcement.judul,
          '${announcement.kategori} · ${DateFormat('d MMM yyyy', 'id_ID').format(announcement.createdAt.toLocal())}',
          'Lihat pengumuman',
          Icons.campaign_rounded,
          7,
        ),
      );
    }
    return slides;
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides();
    final height =
        210.0 +
        (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0, 32) * 7;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (page) => setState(() => _index = page),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Semantics(
                container: true,
                label: 'Informasi ${index + 1} dari ${slides.length}',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(slide.icon, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slide.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46A5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            widget.onNavigateTab(slide.destination),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(slide.action),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (slides.length > 1)
          LayoutBuilder(
            builder: (context, constraints) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (constraints.maxWidth >= 600)
                  IconButton(
                    tooltip: 'Informasi sebelumnya',
                    onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                ...List.generate(
                  slides.length,
                  (index) => Semantics(
                    selected: index == _index,
                    child: IconButton(
                      tooltip: 'Informasi ${index + 1} dari ${slides.length}',
                      onPressed: () => _goTo(index),
                      icon: Icon(
                        Icons.circle,
                        size: index == _index ? 9 : 6,
                        color: index == _index
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
                if (constraints.maxWidth >= 600)
                  IconButton(
                    tooltip: 'Informasi berikutnya',
                    onPressed: _index < slides.length - 1
                        ? () => _goTo(_index + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  (Course, String, bool)? _activeOrNextClass(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final today = List<Course>.from(widget.todayCourses)
      ..sort(
        (a, b) => (_toMinutes(a.effectiveJamMulai) ?? 1440).compareTo(
          _toMinutes(b.effectiveJamMulai) ?? 1440,
        ),
      );
    for (final course in today) {
      final start = _toMinutes(course.effectiveJamMulai);
      final end = _toMinutes(course.effectiveJamSelesai);
      if (start == null || end == null || course.isCancelledToday) continue;
      if (currentMinutes >= start && currentMinutes < end) {
        return (course, 'KELAS BERLANGSUNG', false);
      }
      if (currentMinutes < start) return (course, 'KULIAH BERIKUTNYA', false);
    }
    for (final course in widget.upcomingCourses) {
      if (!course.isCancelledToday) return (course, 'JADWAL BERIKUTNYA', true);
    }
    return null;
  }

  int? _toMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }
}
