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
    final message = Uri.encodeComponent('Halo $name, saya teman sekelas dari S1 Ilmu Komunikasi UNAZLAM...');
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
                width: 40,
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
    final dayCourses = DummyData.courses.where((c) => c.hari == _selectedDay).toList();
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

    final nowFormatted = _formatIndonesianDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Executive Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
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
                                '${_getGreeting()}, Mahasiswa 👋',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textLight),
                              const SizedBox(width: 5),
                              Text(
                                nowFormatted,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onNavigateTab(3), // tab pengumuman
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
                            Positioned(
                              right: -1,
                              top: -1,
                              child: CircleAvatar(radius: 4, backgroundColor: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Midnight Royal Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D032D), Color(0xFF420968), Color(0xFF6714A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF420968).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Decorative glowing circles
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary.withValues(alpha: 0.08),
                            ),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 13, color: AppColors.secondary),
                                        SizedBox(width: 6),
                                        Text(
                                          'UNAZLAM FISIP • S1 ILKOM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF34D399)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Semester Ganjil 26/27',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Pusat Informasi & Akademik',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Jadwal resmi, presensi 75%, kas kelas, dan praktikum terintegrasi.',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                              ),
                              const SizedBox(height: 20),

                              // Quick Stat Capsules
                              Row(
                                children: [
                                  _buildStatCapsule('${DummyData.courses.length} MK', 'Jadwal Aktif', Icons.menu_book_rounded),
                                  const SizedBox(width: 8),
                                  _buildStatCapsule('18 SKS', 'Total Beban', Icons.auto_awesome_rounded),
                                  const SizedBox(width: 8),
                                  _buildStatCapsule('${DummyData.students.length} Mhs', 'Teman Sekelas', Icons.people_alt_rounded),
                                  const SizedBox(width: 8),
                                  _buildStatCapsule('100%', 'Presensi Awal', Icons.shield_rounded),
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

            // 3. Class Leadership Spotlight (Ketua & Bendahara)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      // Ketua Kelas Tile
                      Expanded(
                        child: InkWell(
                          onTap: () => _openWhatsApp(ketuaKelas.noWa, ketuaKelas.nama),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.secondarySoft,
                                child: Text(
                                  ketuaKelas.nama.isNotEmpty ? ketuaKelas.nama[0] : 'K',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'KETUA KELAS',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                    ),
                                    Text(
                                      ketuaKelas.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 28, width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      // Bendahara Tile
                      Expanded(
                        child: InkWell(
                          onTap: () => _openWhatsApp(bendahara.noWa, bendahara.nama),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFDCFCE7),
                                child: Text(
                                  bendahara.nama.isNotEmpty ? bendahara.nama[0] : 'B',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BENDAHARA',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                    ),
                                    Text(
                                      bendahara.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Quick Actions Grid (Bento 2-Kolom)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Layanan & Fitur Kelas', 'Semua Menu', () {}),
                    const SizedBox(height: 12),
                    _buildModernQuickGrid(context),
                  ],
                ),
              ),
            ),

            // 5. Interactive Schedule Section with Day Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Jadwal Perkuliahan', 'Lihat Semua', () => widget.onNavigateTab(1)),
                    const SizedBox(height: 12),

                    // Horizontal Interactive Day Pills
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
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                  boxShadow: isSelected ? AppColors.softShadow : null,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.22)
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : AppColors.textSub,
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
                    if (dayCourses.isEmpty)
                      _buildEmptyState('Tidak ada jadwal perkuliahan pada hari $_selectedDay.')
                    else
                      ...dayCourses.map((c) => _buildModernCourseCard(c)),
                  ],
                ),
              ),
            ),

            // 6. Pinned Announcement
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Info Resmi Kelas', 'Semua', () => widget.onNavigateTab(3)),
                    const SizedBox(height: 10),
                    if (pinnedAnnouncement != null)
                      _buildProfessionalPinnedCard(pinnedAnnouncement)
                    else
                      _buildEmptyState('Belum ada pengumuman resmi.'),
                  ],
                ),
              ),
            ),

            // 7. Tugas & Deadline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Tugas & Praktikum Berjalan', 'Semua', () => widget.onNavigateTab(2)),
                    const SizedBox(height: 10),
                    if (urgentAssignments.isEmpty)
                      _buildEmptyState('Belum ada tugas atau deadline praktikum aktif saat ini.')
                    else
                      ...urgentAssignments.map((a) => _buildModernAssignmentCard(a)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCapsule(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickGrid(BuildContext context) {
    final items = [
      {
        'title': 'Presensi 75%',
        'sub': '100% (Aman)',
        'icon': Icons.how_to_reg_rounded,
        'gradient': [const Color(0xFF6366F1), const Color(0xFF4338CA)],
        'tab': 4,
        'badge': '16 Sesi',
      },
      {
        'title': 'Kas Kelas',
        'sub': DummyData.totalKasSaldo == 0 ? 'Rp 0' : 'Rp ${DummyData.totalKasSaldo}',
        'icon': Icons.account_balance_wallet_rounded,
        'gradient': [const Color(0xFF10B981), const Color(0xFF047857)],
        'tab': 8,
        'badge': 'Transparan',
      },
      {
        'title': 'Gudang Materi',
        'sub': DummyData.resources.isEmpty ? 'Belum Ada Materi' : '${DummyData.resources.length} Berkas',
        'icon': Icons.menu_book_rounded,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'tab': 6,
        'badge': 'Bank Soal',
      },
      {
        'title': 'Tim Praktikum',
        'sub': DummyData.projectGroups.isEmpty ? 'Belum Ada Tim' : '${DummyData.projectGroups.length} Kelompok',
        'icon': Icons.groups_rounded,
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0E7490)],
        'tab': 5,
        'badge': 'Proyek',
      },
      {
        'title': 'Simulasi IPK',
        'sub': 'Target Mutu IPS',
        'icon': Icons.auto_graph_rounded,
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
        'tab': 9,
        'badge': '18 SKS',
      },
      {
        'title': 'Teman Sekelas',
        'sub': '${DummyData.students.length} Mahasiswa',
        'icon': Icons.people_alt_rounded,
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        'tab': 7,
        'badge': '${DummyData.students.length} Kontak',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final gradient = item['gradient'] as List<Color>;

        return InkWell(
          onTap: () => widget.onNavigateTab(item['tab'] as int),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(item['icon'] as IconData, size: 18, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        item['badge'] as String,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['sub'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textLight),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (action.isNotEmpty)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfessionalPinnedCard(Announcement ann) {
    return InkWell(
      onTap: () => _showAnnouncementModal(ann),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.2),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 11, color: Colors.black87),
                      SizedBox(width: 4),
                      Text(
                        'PINNED INFO',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ann.kategori,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                Text(
                  'Oleh ${ann.authorName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ann.judul,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            const SizedBox(height: 4),
            Text(
              ann.isi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCourseCard(Course c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.kode,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${c.sks} SKS', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F1F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${c.jamMulai} - ${c.jamSelesai}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.nama,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.dosen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSub, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F7FA),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            c.ruangan,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAssignmentCard(Assignment a) {
    final diff = a.deadline.difference(DateTime.now());
    final daysLeft = diff.inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.secondaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.courseName,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  a.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysLeft <= 2 ? AppColors.errorSoft : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysLeft <= 0 ? 'Hari ini' : '$daysLeft hari',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: daysLeft <= 2 ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.textSub, fontSize: 12, height: 1.4)),
      ),
    );
  }
}
