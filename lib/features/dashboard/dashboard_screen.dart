import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getTodayName() {
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
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
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

  void _showMoreFeaturesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
            const SizedBox(height: 16),
            const Text(
              'Fitur Tambahan Mahasiswa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            _buildModalTile(
              icon: Icons.groups_rounded,
              color: const Color(0xFF0891B2),
              bg: const Color(0xFFECFEFF),
              title: 'Kelompok Praktikum',
              subtitle: 'Pembagian tim tugas dan berkas proyek',
              onTap: () {
                Navigator.pop(ctx);
                onNavigateTab(5);
              },
            ),
            const SizedBox(height: 10),
            _buildModalTile(
              icon: Icons.auto_graph_rounded,
              color: const Color(0xFFC026D3),
              bg: const Color(0xFFFDF4FF),
              title: 'Simulasi IPK (18 SKS)',
              subtitle: 'Kalkulator proyeksi target mutu semester 1',
              onTap: () {
                Navigator.pop(ctx);
                onNavigateTab(9);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalTile({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayName = _getTodayName();
    final todayCourses = DummyData.courses.where((c) => c.hari == todayName).toList();

    final ketuaKelas = DummyData.students.firstWhere(
      (s) => s.role == 'ketua_kelas' || s.role == 'komti',
      orElse: () => DummyData.students.first,
    );
    final bendahara = DummyData.students.firstWhere(
      (s) => s.role == 'bendahara',
      orElse: () => DummyData.students.first,
    );

    final nowFormatted = _formatIndonesianDate(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Clean iOS Surface
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Ringkas
              Row(
                children: [
                  // Logo
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
                  // Bell Notifikasi
                  InkWell(
                    onTap: () => onNavigateTab(3), // Tab Pengumuman
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
              const SizedBox(height: 18),

              // 2. Kartu Utama: Kuliah Hari Ini (Fokus Jam & Ruangan)
              Container(
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
                      // Header Kartu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF5FF),
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
                                todayCourses.isNotEmpty ? 'KULIAH HARI INI' : 'HARI BEBAS KULIAH',
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
                            Text(
                              todayCourses.isNotEmpty
                                  ? '${todayCourses.length} Mata Kuliah'
                                  : 'Libur Perkuliahan',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Daftar MK Hari Ini
                      if (todayCourses.isNotEmpty) ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: todayCourses.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 24,
                            thickness: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                          itemBuilder: (context, index) {
                            final c = todayCourses[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_filled_rounded, size: 12, color: Color(0xFF4B5563)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${c.jamMulai} - ${c.jamSelesai} WITA',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.ruangan,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.nama,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        c.dosen,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                      ),
                                    ),
                                    Text(
                                      '${c.sks} SKS',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.weekend_outlined, size: 22, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hari Bebas Kuliah',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tidak ada jadwal kuliah hari ini. Waktu luang untuk istirahat atau mengulang materi.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Tombol footer ke jadwal lengkap
                      InkWell(
                        onTap: () => onNavigateTab(1), // Tab Jadwal
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Buka Jadwal Lengkap (Senin – Jumat)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. 4 Layanan Utama (Essential Grid 2x2)
              const Text(
                'Layanan Utama',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildEssentialCard(
                      title: 'Presensi 75%',
                      subtitle: '100% Aman',
                      badge: '16 Sesi',
                      badgeColor: const Color(0xFFEDE9FE),
                      badgeTextColor: AppColors.primary,
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFEDE9FE),
                      onTap: () => onNavigateTab(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEssentialCard(
                      title: 'Kas Kelas',
                      subtitle: DummyData.totalKasSaldo == 0 ? 'Rp 0' : 'Rp ${DummyData.totalKasSaldo}',
                      badge: 'Transparan',
                      badgeColor: const Color(0xFFDCFCE7),
                      badgeTextColor: const Color(0xFF15803D),
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFDCFCE7),
                      onTap: () => onNavigateTab(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildEssentialCard(
                      title: 'Teman Sekelas',
                      subtitle: '${DummyData.students.length} Mahasiswa',
                      badge: 'Angkatan 26',
                      badgeColor: const Color(0xFFEFF6FF),
                      badgeTextColor: const Color(0xFF2563EB),
                      icon: Icons.people_alt_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      onTap: () => onNavigateTab(7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEssentialCard(
                      title: 'Gudang Materi',
                      subtitle: 'Slide & Diktat',
                      badge: 'Modul',
                      badgeColor: const Color(0xFFFEF3C7),
                      badgeTextColor: const Color(0xFFD97706),
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                      onTap: () => onNavigateTab(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Pintasan Fitur Tambahan (Kelompok & IPK)
              Center(
                child: TextButton.icon(
                  onPressed: () => _showMoreFeaturesModal(context),
                  icon: const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF6B7280)),
                  label: const Text(
                    'Fitur Lainnya (Kelompok Praktikum, Simulasi IPK)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Kontak Cepat Pengurus Kelas (Ketua & Bendahara)
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
                    // Ketua Kelas
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KETUA KELAS',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
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
                    // Bendahara
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BENDAHARA',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEssentialCard({
    required String title,
    required String subtitle,
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
            const SizedBox(height: 12),
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
                    subtitle,
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
}
