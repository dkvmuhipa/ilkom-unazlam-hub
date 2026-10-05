import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback? onOpenDrawer;
  final String? userName;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    this.onOpenDrawer,
    this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _heroController;
  int _currentHeroPage = 0;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine today's real courses
    final now = DateTime.now();
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = dayNames[now.weekday];
    final todayCourses = DummyData.courses.where((s) => s.hari == todayName).toList();
    final firstCourse = todayCourses.isNotEmpty ? todayCourses.first : null;

    final latestAnnouncement = DummyData.announcements.isNotEmpty ? DummyData.announcements.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header matching Screen 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Halo,',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.userName != null && widget.userName!.isNotEmpty
                                ? widget.userName!.split(' ').first
                                : 'Farida',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Semester 1 • Ilmu Komunikasi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification Bell with unread dot
                      InkWell(
                        onTap: () => widget.onNavigateTab(7), // Open Pengumuman
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF111827)),
                              Positioned(
                                top: -1,
                                right: -1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onOpenDrawer != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onOpenDrawer,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.menu_rounded, size: 22, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Swipable Hero Carousel (PageView matching Screen 3)
              SizedBox(
                height: 172,
                child: PageView(
                  controller: _heroController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentHeroPage = index;
                    });
                  },
                  children: [
                    // Slide 0: Kuliah Hari Ini
                    _buildHeroCard(
                      gradientColors: const [Color(0xFF5B3DE8), Color(0xFF755BF7)],
                      shadowColor: const Color(0xFF5B3DE8),
                      badgeIcon: Icons.school_outlined,
                      badgeText: 'Kuliah Hari Ini',
                      title: firstCourse?.nama ?? 'Pendidikan Pancasila',
                      line1Icon: Icons.access_time_rounded,
                      line1Text: firstCourse != null
                          ? '${firstCourse.jamMulai} - ${firstCourse.jamSelesai}'
                          : '15.30 - 17.45 WITA',
                      line2Icon: Icons.location_on_outlined,
                      line2Text: firstCourse?.ruangan.isNotEmpty == true ? firstCourse!.ruangan : 'Ruang A2',
                      onTapArrow: () => widget.onNavigateTab(1),
                    ),

                    // Slide 1: Tugas Kelas Terdekat
                    _buildHeroCard(
                      gradientColors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                      shadowColor: const Color(0xFF4338CA),
                      badgeIcon: Icons.assignment_outlined,
                      badgeText: 'Tugas Terdekat',
                      title: 'Mencari ahli-ahli Ilmu Komunikasi',
                      line1Icon: Icons.calendar_today_outlined,
                      line1Text: 'Deadline: 8 Oktober 2026',
                      line2Icon: Icons.book_outlined,
                      line2Text: 'Pendidikan Kewarganegaraan',
                      onTapArrow: () => widget.onNavigateTab(2),
                    ),

                    // Slide 2: Absensi Saya
                    _buildHeroCard(
                      gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      shadowColor: const Color(0xFF0F766E),
                      badgeIcon: Icons.fact_check_outlined,
                      badgeText: 'Status Presensi',
                      title: '90% Kehadiran Perkuliahan',
                      line1Icon: Icons.check_circle_outline,
                      line1Text: '9 Hadir • 1 Izin • 0 Alpa',
                      line2Icon: Icons.info_outline_rounded,
                      line2Text: 'Total 10 Sesi Berjalan (Aman)',
                      onTapArrow: () => widget.onNavigateTab(5),
                    ),

                    // Slide 3: Kas Kelas
                    _buildHeroCard(
                      gradientColors: const [Color(0xFF6D28D9), Color(0xFF9333EA)],
                      shadowColor: const Color(0xFF6D28D9),
                      badgeIcon: Icons.account_balance_wallet_outlined,
                      badgeText: 'Kas Kelas ILKOM',
                      title: 'Transparan & Terbuka',
                      line1Icon: Icons.shield_outlined,
                      line1Text: 'Dikelola oleh Bendahara (Alya)',
                      line2Icon: Icons.payments_outlined,
                      line2Text: 'Lihat Pembukuan & Iuran Kas',
                      onTapArrow: () => widget.onNavigateTab(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Carousel Indicator Dots (4 dots with smooth animation)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isSelected = index == _currentHeroPage;
                  return InkWell(
                    onTap: () {
                      _heroController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 20 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Menu Cepat Title
              const Text(
                'Menu Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),

              // 4 Circular/Rounded Menu Cepat items matching Screen 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickMenuItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Jadwal',
                    color: const Color(0xFF5B3DE8),
                    bgColor: const Color(0xFFF3F0FF),
                    onTap: () => widget.onNavigateTab(1),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Tugas',
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    onTap: () => widget.onNavigateTab(2),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Absensi',
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () => widget.onNavigateTab(5), // Absensi Saya
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Anggota',
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFEDE9FE),
                    onTap: () => widget.onNavigateTab(3), // Anggota Tab
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Pengumuman Terbaru Header with "Lihat Semua"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengumuman Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.onNavigateTab(7), // Open Pengumuman
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B3DE8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Announcement Card matching Screen 3
              InkWell(
                onTap: () => widget.onNavigateTab(7),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFFB45309),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestAnnouncement?.judul ?? 'Perubahan Ruang Kuliah',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestAnnouncement?.isi ?? 'Kuliah Pendidikan Kewarganegaraan besok dipindahkan ke Ruang B2.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '5 Okt 2026',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required List<Color> gradientColors,
    required Color shadowColor,
    required IconData badgeIcon,
    required String badgeText,
    required String title,
    required IconData line1Icon,
    required String line1Text,
    required IconData line2Icon,
    required String line2Text,
    required VoidCallback onTapArrow,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Course / Feature Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Details Row with Time, Room & Arrow Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(line1Icon, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line1Text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(line2Icon, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line2Text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Circular white arrow action button
              InkWell(
                onTap: onTapArrow,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: gradientColors.first,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
