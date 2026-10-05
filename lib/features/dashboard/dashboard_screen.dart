import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;
  final VoidCallback? onOpenDrawer;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    this.onOpenDrawer,
  });

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
                      const Row(
                        children: [
                          Text(
                            'Farida',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('👋', style: TextStyle(fontSize: 18)),
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
                        onTap: () => onNavigateTab(7), // Open Pengumuman
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
                      if (onOpenDrawer != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onOpenDrawer,
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

              // Hero Card: Kuliah Hari Ini (Gradient Purple matching mockup Screen 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B3DE8), Color(0xFF755BF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B3DE8).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: Kuliah Hari Ini
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Kuliah Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Course Title
                    Text(
                      firstCourse?.nama ?? 'Pendidikan Pancasila',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Details Row with Time, Room & Arrow Action Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    firstCourse != null
                                        ? '${firstCourse.jamMulai} - ${firstCourse.jamSelesai}'
                                        : '15.30 - 17.45',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    firstCourse?.ruangan ?? 'Ruang A2',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Circular white arrow action button
                        InkWell(
                          onTap: () => onNavigateTab(1), // Go to Jadwal Tab
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF5B3DE8),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Carousel indicator dots (4 dots, first active)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B3DE8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildDotIndicator(),
                  const SizedBox(width: 4),
                  _buildDotIndicator(),
                  const SizedBox(width: 4),
                  _buildDotIndicator(),
                ],
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
                    onTap: () => onNavigateTab(1),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Tugas',
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    onTap: () => onNavigateTab(2),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Absensi',
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () => onNavigateTab(5), // Absensi Saya
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Anggota',
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFEDE9FE),
                    onTap: () => onNavigateTab(3), // Anggota Tab
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
                    onTap: () => onNavigateTab(7), // Open Pengumuman
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
                onTap: () => onNavigateTab(7),
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

  Widget _buildDotIndicator() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(4),
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
