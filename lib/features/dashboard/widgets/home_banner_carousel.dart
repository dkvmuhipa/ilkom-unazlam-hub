import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_models.dart';

class HomeBannerCarousel extends StatefulWidget {
  final bool isDark;
  final void Function(int) onNavigateTab;

  const HomeBannerCarousel({
    super.key,
    required this.isDark,
    required this.onNavigateTab,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final banners = [
      HeroBannerData(
        badge: '🎯 UTS GANJIL 2026',
        badgeBg: const Color(0xFFFDE047),
        badgeTextColor: const Color(0xFF0F172A),
        title: 'Persiapkan Ujian & Akses E-Book',
        subtitle: 'Unduh modul, kisi-kisi, & bank soal semester ini.',
        buttonLabel: 'Buka Materi',
        gradientColors: isDark
            ? [const Color(0xFF2E1A66), const Color(0xFF4C2CE2)]
            : [const Color(0xFF3B1F8E), const Color(0xFF5B3DE8)],
        icon: Icons.school_rounded,
        tabIndex: 10, // Materi & Dokumen
      ),
      HeroBannerData(
        badge: '🏆 KOMPETISI KREATIF',
        badgeBg: const Color(0xFF6EE7B7),
        badgeTextColor: const Color(0xFF064E3B),
        title: 'Lomba UI/UX & Karya Ilmiah',
        subtitle: 'Bentuk tim praktikum dan raih prestasi untuk Ilkom.',
        buttonLabel: 'Bentuk Tim',
        gradientColors: isDark
            ? [const Color(0xFF064E3B), const Color(0xFF0D9488)]
            : [const Color(0xFF047857), const Color(0xFF10B981)],
        icon: Icons.emoji_events_rounded,
        tabIndex: 9, // Kelompok Praktikum
      ),
      HeroBannerData(
        badge: '💰 KAS KELAS UNAZLAM',
        badgeBg: const Color(0xFFBAE6FD),
        badgeTextColor: const Color(0xFF0C4A6E),
        title: 'Transparansi Kas & Iuran Kelas',
        subtitle: 'Laporan kas terperinci dan pembayaran instan via QRIS.',
        buttonLabel: 'Cek Kas',
        gradientColors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0284C7)]
            : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
        icon: Icons.account_balance_wallet_rounded,
        tabIndex: 8, // Kas Kelas
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 122,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: b.gradientColors.first.withValues(alpha: isDark ? 0.35 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Watermark Icon di Kanan Belakang
                    Positioned(
                      right: -8,
                      bottom: -15,
                      child: Icon(
                        b.icon,
                        size: 92,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge Kategori
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: b.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b.badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: b.badgeTextColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),

                        // Title & Subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Button Aksi
                        InkWell(
                          onTap: () => widget.onNavigateTab(b.tabIndex),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.buttonLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: b.gradientColors.first,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 11,
                                  color: b.gradientColors.first,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots (Active: Pill 14px, Inactive: Dot 5px)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
