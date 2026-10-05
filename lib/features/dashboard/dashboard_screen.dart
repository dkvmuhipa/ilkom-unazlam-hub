import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _selectedDay;
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _getDefaultDay();
  }

  String _getDefaultDay() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      default:
        return 'Senin';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _formatIndonesianDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent('Halo $name, saya mahasiswa S1 Ilmu Komunikasi UNAZLAM...');
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAnnouncementModal(Announcement ann) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENGUMUMAN RESMI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy').format(ann.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ann.judul,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Oleh ${ann.authorName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ann.isi,
                style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textMain),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayName = _getDefaultDay();
    final todayCourses = DummyData.courses.where((c) => c.hari == todayName).toList();
    final selectedDayCourses = DummyData.courses.where((c) => c.hari == _selectedDay).toList();
    final urgentAssignments = DummyData.assignments.where((a) => a.status != 'selesai').take(2).toList();

    final pinnedAnnouncement = DummyData.announcements.isNotEmpty
        ? DummyData.announcements.firstWhere(
            (ann) => ann.isPinned,
            orElse: () => DummyData.announcements.first,
          )
        : null;

    final ketuaKelas = DummyData.students.firstWhere(
      (s) => s.role == 'ketua_kelas' || s.role == 'komti',
      orElse: () => DummyData.students.first,
    );
    final bendahara = DummyData.students.firstWhere(
      (s) => s.role == 'bendahara',
      orElse: () => DummyData.students.first,
    );

    final nowFormatted = _formatIndonesianDate(now);
    final nextCourse = todayCourses.isNotEmpty ? todayCourses.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Clean iOS Surface
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Clean iOS Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    // University Logo
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.school_rounded, color: AppColors.primary, size: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_getGreeting()} 👋',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FISIP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nowFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification Button
                    InkWell(
                      onTap: () => widget.onNavigateTab(3), // Pengumuman
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF374151)),
                            Positioned(
                              right: -1,
                              top: -1,
                              child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Hero Widget: "Kuliah Berikutnya / Status Hari Ini" (iOS Spotlight Card)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C1078).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF5FF), // Subtle soft lavender
                            border: Border(bottom: BorderSide(color: Color(0xFFF3E8FF))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  nextCourse != null ? 'KULIAH HARI INI' : 'HARI BEBAS KULIAH',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                todayName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE9D5FF)),
                                ),
                                child: Text(
                                  '${todayCourses.length} Mata Kuliah',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: nextCourse != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nextCourse.nama,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF111827),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      nextCourse.dosen,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3E8FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            nextCourse.ruangan,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time_filled_rounded, size: 13, color: Color(0xFF4B5563)),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${nextCourse.jamMulai} - ${nextCourse.jamSelesai} WITA',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${nextCourse.sks} SKS',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () => widget.onNavigateTab(1),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Text(
                                                  'Semua Jadwal',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.weekend_outlined, size: 24, color: Color(0xFF6B7280)),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tidak Ada Kuliah Hari Ini',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Selamat beristirahat atau siapkan materi untuk sesi berikutnya.',
                                            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
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

            // 3. Modular Bento Hub Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Fitur & Layanan Utama', '', () {}),
                    const SizedBox(height: 12),
                    _buildCleanBentoGrid(context, ketuaKelas, bendahara),
                  ],
                ),
              ),
            ),

            // 4. Interactive Schedule with Day Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Jadwal Kuliah Mingguan', 'Lihat Lengkap', () => widget.onNavigateTab(1)),
                    const SizedBox(height: 12),

                    // Clean Day Picker Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _days.map((day) {
                          final isSelected = day == _selectedDay;
                          final count = DummyData.courses.where((c) => c.hari == day).length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedDay = day),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Course Cards for Selected Day
                    if (selectedDayCourses.isEmpty)
                      _buildEmptyState('Tidak ada jadwal perkuliahan pada hari $_selectedDay.')
                    else
                      ...selectedDayCourses.map((c) => _buildCleanCourseCard(c)),
                  ],
                ),
              ),
            ),

            // 5. Official Pinned Announcement
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Info Resmi Kelas', 'Semua', () => widget.onNavigateTab(3)),
                    const SizedBox(height: 10),
                    if (pinnedAnnouncement != null)
                      _buildCleanPinnedCard(pinnedAnnouncement)
                    else
                      _buildEmptyState('Belum ada pengumuman resmi.'),
                  ],
                ),
              ),
            ),

            // 6. Tugas & Praktikum Berjalan
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Tugas & Praktikum', 'Lihat Semua', () => widget.onNavigateTab(2)),
                    const SizedBox(height: 10),
                    if (urgentAssignments.isEmpty)
                      _buildCleanEmptyAssignmentCard()
                    else
                      ...urgentAssignments.map((a) => _buildCleanAssignmentCard(a)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanBentoGrid(BuildContext context, StudentProfile ketuaKelas, StudentProfile bendahara) {
    return Column(
      children: [
        // Row 1: Presensi 75% & Kas Kelas
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Presensi 75%',
                value: '100% Aman',
                badge: '16 Sesi',
                badgeColor: const Color(0xFFEDE9FE),
                badgeTextColor: AppColors.primary,
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFEDE9FE),
                onTap: () => widget.onNavigateTab(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'Kas Kelas',
                value: DummyData.totalKasSaldo == 0 ? 'Rp 0' : 'Rp ${DummyData.totalKasSaldo}',
                badge: 'Transparan',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF15803D),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                onTap: () => widget.onNavigateTab(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Pengurus Kelas Spotlight Card (Full Width)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ketua Tile
              Expanded(
                child: InkWell(
                  onTap: () => _openWhatsApp(ketuaKelas.noWa, ketuaKelas.nama),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.secondarySoft,
                        child: Text(
                          ketuaKelas.nama.isNotEmpty ? ketuaKelas.nama[0] : 'K',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KETUA KELAS',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                            Text(
                              ketuaKelas.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF22C55E)),
                    ],
                  ),
                ),
              ),
              Container(height: 24, width: 1, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 10)),
              // Bendahara Tile
              Expanded(
                child: InkWell(
                  onTap: () => _openWhatsApp(bendahara.noWa, bendahara.nama),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFDCFCE7),
                        child: Text(
                          bendahara.nama.isNotEmpty ? bendahara.nama[0] : 'B',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BENDAHARA',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                            ),
                            Text(
                              bendahara.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF22C55E)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 3: Teman Sekelas & Gudang Materi
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Teman Sekelas',
                value: '${DummyData.students.length} Mahasiswa',
                badge: 'Angkatan 2026',
                badgeColor: const Color(0xFFEFF6FF),
                badgeTextColor: const Color(0xFF2563EB),
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                onTap: () => widget.onNavigateTab(7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'Gudang Materi',
                value: 'Slide & Diktat',
                badge: 'Bank Soal',
                badgeColor: const Color(0xFFFEF3C7),
                badgeTextColor: const Color(0xFFD97706),
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                onTap: () => widget.onNavigateTab(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: Tim Praktikum & Simulasi IPK
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Tim Praktikum',
                value: 'Kelompok Tugas',
                badge: 'Proyek',
                badgeColor: const Color(0xFFECFEFF),
                badgeTextColor: const Color(0xFF0891B2),
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF0891B2),
                iconBg: const Color(0xFFECFEFF),
                onTap: () => widget.onNavigateTab(5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'Simulasi IPK',
                value: 'Target 4.00',
                badge: '18 SKS',
                badgeColor: const Color(0xFFFDF4FF),
                badgeTextColor: const Color(0xFFC026D3),
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFFC026D3),
                iconBg: const Color(0xFFFDF4FF),
                onTap: () => widget.onNavigateTab(9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanCourseCard(Course c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.kode,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text('${c.sks} SKS', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 11, color: Color(0xFF4B5563)),
                    const SizedBox(width: 4),
                    Text(
                      '${c.jamMulai} - ${c.jamSelesai}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            c.nama,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  c.dosen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563)),
                ),
              ),
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.ruangan,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanPinnedCard(Announcement ann) {
    return InkWell(
      onTap: () => _showAnnouncementModal(ann),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2), // Warm Amber border
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 11, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        'PINNED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ann.kategori,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                Text(
                  'Oleh ${ann.authorName}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ann.judul,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              ann.isi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanAssignmentCard(Assignment a) {
    final diff = a.deadline.difference(DateTime.now());
    final daysLeft = diff.inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, size: 20, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.courseName,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  a.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysLeft <= 2 ? const Color(0xFFFEE2E2) : const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysLeft <= 0 ? 'Hari ini' : '$daysLeft hari',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: daysLeft <= 2 ? const Color(0xFFDC2626) : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanEmptyAssignmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.check_rounded, size: 18, color: Color(0xFF16A34A)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Ada Tugas Aktif',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                SizedBox(height: 2),
                Text(
                  'Semua tugas perkuliahan telah selesai atau belum ada tugas baru.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (action.isNotEmpty)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.4)),
      ),
    );
  }
}
