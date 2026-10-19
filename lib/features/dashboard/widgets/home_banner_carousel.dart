import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final List<Color> gradientColors;

  const _HeroSlide({
    required this.label,
    this.badge,
    required this.title,
    required this.detail,
    required this.action,
    required this.icon,
    required this.destination,
    this.accentColor = const Color(0xFF4F46E5),
    this.gradientColors = const [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
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
          gradientColors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
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
              ? const Color(0xFF059669)
              : const Color(0xFF4F46E5),
          gradientColors: isNow
              ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
              : const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
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
          accentColor: const Color(0xFF4F46E5),
          gradientColors: const [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
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
              : const Color(0xFFD97706),
          gradientColors: isOverdue
              ? const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]
              : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
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
              ? const Color(0xFF059669)
              : const Color(0xFFEF4444),
          gradientColors: isLunas
              ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
              : const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
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
              ? const Color(0xFFEA580C)
              : const Color(0xFF0284C7),
          gradientColors: isWarning
              ? const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]
              : const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
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
          accentColor: const Color(0xFF7C3AED),
          gradientColors: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
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
    final height = 146.0 +
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
              return Semantics(
                container: true,
                label: 'Informasi ${index + 1} dari ${slides.length}',
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1C2B) : null,
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF1E1C2B),
                                slide.accentColor.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: slide.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E2C3D)
                            : slide.accentColor.withValues(alpha: 0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accentColor.withValues(
                            alpha: isDark ? 0.08 : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => widget.onNavigateTab(slide.destination),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris Atas: Icon Badge & Label & Status Pill
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    color: slide.accentColor,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    slide.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: slide.accentColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                if (slide.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: slide.accentColor.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: slide.accentColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      slide.badge!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: slide.accentColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Judul Utama
                            Text(
                              slide.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Detail Informasi
                            Text(
                              slide.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),

                            const Spacer(),

                            // Baris Bawah: Tombol Aksi Langsung
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        widget.onNavigateTab(slide.destination),
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                    ),
                                    label: Text(
                                      slide.action,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: slide.accentColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(0, 26),
                                      visualDensity: VisualDensity.compact,
                                      textStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
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

