import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class HomeBannerCarousel extends StatefulWidget {
  final List<Course> todayCourses;
  final List<Course> upcomingCourses;
  final String? upcomingDayLabel;
  final Assignment? nextAssignment;
  final Announcement? latestAnnouncement;
  final bool hasLoadError;
  final void Function(int) onNavigateTab;
  final bool? isKasLunas;
  final int kasNominal;
  final String? currentPeriodLabel;
  final int? attendancePercent;

  const HomeBannerCarousel({
    super.key,
    required this.todayCourses,
    required this.upcomingCourses,
    this.upcomingDayLabel,
    required this.nextAssignment,
    required this.latestAnnouncement,
    required this.hasLoadError,
    required this.onNavigateTab,
    this.isKasLunas,
    this.kasNominal = 0,
    this.currentPeriodLabel,
    this.attendancePercent,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HeroSlide {
  final String label;
  final String? badge;
  final String title;
  final String detail;
  final String action;
  final IconData icon;
  final int destination;
  final Color accentColor;
  final Color buttonTextColor;
  final List<Color> lightGradientColors;
  final List<Color> darkGradientColors;
  // ignore: unused_field
  final List<Color>? gradientColors;

  const _HeroSlide({
    required this.label,
    this.badge,
    required this.title,
    required this.detail,
    required this.action,
    required this.icon,
    required this.destination,
    this.accentColor = const Color(0xFF4F46E5),
    this.buttonTextColor = const Color(0xFF1E3A8A),
    this.lightGradientColors = const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    this.darkGradientColors = const [Color(0xFF161936), Color(0xFF222659)],
    // ignore: unused_element_parameter
    this.gradientColors,
  });
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

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  List<_HeroSlide> _slides() {
    final now = DateTime.now();
    final slides = <_HeroSlide>[];

    // 1. SLIDE 0: RINGKASAN HARI INI / SPOTLIGHT JADWAL (Satu slide fokus, tidak menduplikasi jadwal)
    final activeClass = _activeOrNextClass(now);
    if (widget.hasLoadError) {
      slides.add(
        const _HeroSlide(
          label: 'DATA TERAKHIR',
          badge: 'OFFLINE',
          title: 'Pembaruan data belum tersedia',
          detail: 'Periksa koneksi. Informasi akademik mungkin belum diperbarui.',
          action: 'Lihat jadwal',
          icon: Icons.cloud_off_rounded,
          destination: 1,
          accentColor: Color(0xFF64748B),
          buttonTextColor: Color(0xFF334155),
          lightGradientColors: [Color(0xFF334155), Color(0xFF475569)],
          darkGradientColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      );
    } else if (activeClass != null) {
      final (course, status, upcoming) = activeClass;
      final location = course.isOnlineOverride
          ? 'Kelas daring'
          : (course.effectiveRuangan.isEmpty
              ? 'Ruangan TBA'
              : course.effectiveRuangan);
      final isNow = status == 'KELAS BERLANGSUNG';
      slides.add(
        _HeroSlide(
          label: 'RINGKASAN HARI INI',
          badge: status,
          title: course.nama,
          detail:
              '${upcoming ? '${widget.upcomingDayLabel ?? course.hari} · ' : ''}${course.effectiveJamMulai}–${course.effectiveJamSelesai} · $location',
          action: 'Lihat jadwal',
          icon: isNow ? Icons.timelapse_rounded : Icons.calendar_month_rounded,
          destination: 1,
          accentColor: isNow
              ? const Color(0xFF10B981)
              : const Color(0xFF3B82F6),
          buttonTextColor: isNow
              ? const Color(0xFF065F46)
              : const Color(0xFF1E3A8A),
          lightGradientColors: isNow
              ? const [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)]
              : const [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          darkGradientColors: isNow
              ? const [Color(0xFF0A2E20), Color(0xFF104431), Color(0xFF14563E)]
              : const [Color(0xFF121538), Color(0xFF1B1E4E), Color(0xFF252668)],
        ),
      );
    } else {
      slides.add(
        _HeroSlide(
          label: 'RINGKASAN HARI INI',
          badge: widget.todayCourses.isEmpty ? 'BEBAS KULIAH' : 'JADWAL',
          title: widget.todayCourses.isEmpty
              ? 'Hari Bebas Kuliah ✨'
              : '${widget.todayCourses.length} Kuliah Hari Ini',
          detail: widget.todayCourses.isEmpty
              ? (widget.upcomingCourses.isNotEmpty
                  ? 'Kuliah berikutnya: ${widget.upcomingCourses.first.nama} (${widget.upcomingDayLabel ?? widget.upcomingCourses.first.hari})'
                  : 'Tidak ada jadwal perkuliahan aktif untuk hari ini.')
              : '${widget.todayCourses.length} mata kuliah terjadwal. Ketuk untuk detail jam & ruangan.',
          action: 'Lihat jadwal',
          icon: Icons.school_rounded,
          destination: 1,
          accentColor: const Color(0xFF6366F1),
          buttonTextColor: const Color(0xFF312E81),
          lightGradientColors: const [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
          darkGradientColors: const [Color(0xFF151433), Color(0xFF1E1C48), Color(0xFF2A2466)],
        ),
      );
    }

    // 2. SLIDE TUGAS TERDEKAT
    final assignment = widget.nextAssignment;
    if (assignment != null) {
      final isOverdue = assignment.deadline.isBefore(now);
      final diff = assignment.deadline.difference(now);
      final String urgencyBadge;
      if (isOverdue) {
        urgencyBadge = 'LEWAT TENGGAT';
      } else if (diff.inHours < 24) {
        urgencyBadge = '${diff.inHours.clamp(0, 24)} JAM LAGI';
      } else {
        urgencyBadge = '${diff.inDays} HARI LAGI';
      }

      slides.add(
        _HeroSlide(
          label: isOverdue ? 'TUGAS MELEWATI TENGGAT' : 'TUGAS TERDEKAT',
          badge: urgencyBadge,
          title: assignment.judul.isEmpty
              ? 'Tugas ${assignment.courseName}'
              : assignment.judul,
          detail:
              '${assignment.courseName} · ${DateFormat('d MMM, HH:mm', 'id_ID').format(assignment.deadline.toLocal())}',
          action: 'Lihat tugas',
          icon: Icons.assignment_rounded,
          destination: 2,
          accentColor: isOverdue
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B),
          buttonTextColor: isOverdue
              ? const Color(0xFF991B1B)
              : const Color(0xFFB45309),
          lightGradientColors: isOverdue
              ? const [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFEF4444)]
              : const [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFEA580C)],
          darkGradientColors: isOverdue
              ? const [Color(0xFF361217), Color(0xFF4C151F), Color(0xFF651B2A)]
              : const [Color(0xFF361F0E), Color(0xFF4A2B11), Color(0xFF633A14)],
        ),
      );
    }

    // 3. SLIDE IURAN KAS KELAS (Multi-domain finansial mahasiswa)
    if (widget.isKasLunas != null) {
      final isLunas = widget.isKasLunas == true;
      slides.add(
        _HeroSlide(
          label: 'KAS KELAS',
          badge: isLunas ? 'LUNAS' : 'BELUM BAYAR',
          title: isLunas
              ? 'Iuran Kas Anda Lunas ✨'
              : (widget.kasNominal > 0
                  ? 'Tagihan Kas ${_formatCurrency(widget.kasNominal)}'
                  : 'Iuran Kas ${widget.currentPeriodLabel ?? "Bulan Ini"}'),
          detail: isLunas
              ? (widget.currentPeriodLabel != null &&
                      widget.currentPeriodLabel!.isNotEmpty
                  ? 'Periode ${widget.currentPeriodLabel} terbayar. Terima kasih!'
                  : 'Semua kewajiban kas kelas telah terpenuhi dengan baik.')
              : 'Segera lakukan pembayaran kas kelas via bendahara atau QRIS.',
          action: isLunas ? 'Cek kas' : 'Bayar kas',
          icon: isLunas
              ? Icons.verified_rounded
              : Icons.account_balance_wallet_rounded,
          destination: 8,
          accentColor: isLunas
              ? const Color(0xFF10B981)
              : const Color(0xFFF43F5E),
          buttonTextColor: isLunas
              ? const Color(0xFF065F46)
              : const Color(0xFF9F1239),
          lightGradientColors: isLunas
              ? const [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)]
              : const [Color(0xFF9F1239), Color(0xFFBE123C), Color(0xFFE11D48)],
          darkGradientColors: isLunas
              ? const [Color(0xFF0B2B20), Color(0xFF103D2E), Color(0xFF15533F)]
              : const [Color(0xFF361019), Color(0xFF4C1422), Color(0xFF66172D)],
        ),
      );
    }

    // 4. SLIDE REKAP PRESENSI KULIAH (Multi-domain kepatuhan akademik)
    if (widget.attendancePercent != null) {
      final percent = widget.attendancePercent!;
      final isWarning = percent < 75;
      slides.add(
        _HeroSlide(
          label: 'KEHADIRAN MAHASISWA',
          badge: '$percent%',
          title: isWarning
              ? 'Perhatian: Kehadiran $percent% ⚠️'
              : 'Presensi Terjaga Aman ($percent%) ✨',
          detail: isWarning
              ? 'Kehadiran di bawah 75% berisiko tidak memenuhi syarat ikut UAS.'
              : 'Kehadiran Anda memenuhi syarat minimal 75% kelayakan ujian.',
          action: 'Lihat presensi',
          icon: isWarning
              ? Icons.warning_amber_rounded
              : Icons.fact_check_rounded,
          destination: 5,
          accentColor: isWarning
              ? const Color(0xFFF97316)
              : const Color(0xFF06B6D4),
          buttonTextColor: isWarning
              ? const Color(0xFFC2410C)
              : const Color(0xFF0369A1),
          lightGradientColors: isWarning
              ? const [Color(0xFFC2410C), Color(0xFFEA580C), Color(0xFFF97316)]
              : const [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF0EA5E9)],
          darkGradientColors: isWarning
              ? const [Color(0xFF39160A), Color(0xFF501E0D), Color(0xFF6B260F)]
              : const [Color(0xFF0A2536), Color(0xFF0E354D), Color(0xFF124769)],
        ),
      );
    }

    // 5. SLIDE PENGUMUMAN TERBARU
    final announcement = widget.latestAnnouncement;
    if (announcement != null) {
      slides.add(
        _HeroSlide(
          label: 'PENGUMUMAN TERBARU',
          badge: announcement.kategori.toUpperCase(),
          title: announcement.judul,
          detail:
              '${announcement.kategori} · ${DateFormat('d MMM yyyy', 'id_ID').format(announcement.createdAt.toLocal())}',
          action: 'Lihat pengumuman',
          icon: Icons.campaign_rounded,
          destination: 7,
          accentColor: const Color(0xFFA855F7),
          buttonTextColor: const Color(0xFF5B21B6),
          lightGradientColors: const [Color(0xFF5B21B6), Color(0xFF6D28D9), Color(0xFF7C3AED)],
          darkGradientColors: const [Color(0xFF26103D), Color(0xFF361556), Color(0xFF481B74)],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = 152.0 +
        (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 32) * 5;

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
              final gradient = LinearGradient(
                colors: isDark
                    ? slide.darkGradientColors
                    : slide.lightGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

              return Semantics(
                container: true,
                label: 'Informasi ${index + 1} dari ${slides.length}',
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? slide.accentColor : Colors.black)
                              .withValues(alpha: isDark ? 0.35 : 0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => widget.onNavigateTab(slide.destination),
                      borderRadius: BorderRadius.circular(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // 1. Ambient Glow Aura
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: isDark ? 0.12 : 0.22,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 2. Translucent Studio Watermark Icon
                            Positioned(
                              right: -10,
                              bottom: -15,
                              child: Icon(
                                slide.icon,
                                size: 104,
                                color: Colors.white.withValues(
                                  alpha: isDark ? 0.08 : 0.13,
                                ),
                              ),
                            ),

                            // 3. Main Content Layer
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris Atas: Icon Badge & Eyebrow Label & Status Pill
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(7),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Icon(
                                          slide.icon,
                                          color: Colors.white,
                                          size: 13.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          slide.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      if (slide.badge != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7.5,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.4),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            slide.badge!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 7),

                                  // Judul Utama (High-contrast, bold)
                                  Text(
                                    slide.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2.5),

                                  // Detail Informasi
                                  Text(
                                    slide.detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Baris Bawah: Tombol Aksi Langsung (Tactile White Pill)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: ScaleButton(
                                          scaleDown: 0.94,
                                          onTap: () => widget.onNavigateTab(slide.destination),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.18),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    slide.action,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: slide.buttonTextColor,
                                                      letterSpacing: -0.1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 11.5,
                                                  color: slide.buttonTextColor,
                                                ),
                                              ],
                                            ),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (slides.length > 1)
          LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (constraints.maxWidth >= 600)
                    IconButton(
                      tooltip: 'Informasi sebelumnya',
                      onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ...List.generate(
                    slides.length,
                    (index) => Semantics(
                      selected: index == _index,
                      child: IconButton(
                        tooltip:
                            'Informasi ${index + 1} dari ${slides.length}',
                        onPressed: () => _goTo(index),
                        icon: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: index == _index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: index == _index
                                ? slides[index].accentColor
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  if (constraints.maxWidth >= 600)
                    IconButton(
                      tooltip: 'Informasi berikutnya',
                      onPressed: _index < slides.length - 1
                          ? () => _goTo(_index + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
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

