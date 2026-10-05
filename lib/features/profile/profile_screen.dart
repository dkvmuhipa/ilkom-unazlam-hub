import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLeaderPanel = false;

  @override
  Widget build(BuildContext context) {
    if (_showLeaderPanel) {
      return _buildLeaderPanelScreen();
    }
    return _buildProfileScreen();
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF111827), size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan aplikasi'), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Profile Picture with Camera Badge
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary,
                          child: const Center(
                            child: Text(
                              'NF',
                              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name with Pencil Edit
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Nur Farida',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '👑 Ketua Kelas ILKOM 2026',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow('NIM', '260250023'),
                  const Divider(height: 22, color: Color(0xFFF3F4F6)),
                  _buildDetailRow('Program Studi', 'Ilmu Komunikasi'),
                  const Divider(height: 22, color: Color(0xFFF3F4F6)),
                  _buildDetailRow('Fakultas', 'Ilmu Sosial dan Ilmu Politik (FISIP)'),
                  const Divider(height: 22, color: Color(0xFFF3F4F6)),
                  _buildDetailRow('Semester', '1 (Satu) - T.A 2026/2027'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Special Class Leader Panel Entry Card
            InkWell(
              onTap: () {
                setState(() {
                  _showLeaderPanel = true;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B3DE8), Color(0xFF755BF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B3DE8).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel Pengurus Kelas',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Akses kelola absensi, tugas, pengumuman & kas',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu Items List (Informasi Kelas, Rekap Absensi Saya, Pengaturan Akun)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Informasi Kelas',
                    subtitle: 'Ruang A2, Kampus FISIP UNAZLAM',
                    onTap: () {
                      _showClassInfoDialog();
                    },
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
                  _buildMenuItem(
                    icon: Icons.fact_check_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Rekap Absensi Saya',
                    subtitle: '90% Kehadiran Aman',
                    onTap: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(5); // Attendance Screen
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
                  _buildMenuItem(
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'Pengaturan Akun',
                    subtitle: 'Ganti kata sandi & notifikasi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menu Pengaturan Akun')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // Screen 11: Panel Ketua Kelas (Matching the mockup!)
  Widget _buildLeaderPanelScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () {
            setState(() {
              _showLeaderPanel = false;
            });
          },
        ),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Ketua Kelas',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda memiliki hak akses sebagai Ketua Kelas ILKOM UNAZLAM 2026.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Action items matching Screen 11
          _buildLeaderMenuCard([
            _buildLeaderActionTile(
              icon: Icons.people_outline_rounded,
              title: 'Data Mahasiswa',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(3); // Kelas Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.how_to_reg_outlined,
              title: 'Kelola Absensi',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(5); // Absensi Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.campaign_outlined,
              title: 'Buat Pengumuman',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(7); // Pengumuman Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.assignment_outlined,
              title: 'Kelola Tugas',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Tugas Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.calendar_month_outlined,
              title: 'Kelola Agenda',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(6); // Agenda Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.query_stats_rounded,
              title: 'Rekap Kehadiran',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(5); // Absensi Tab
                }
              },
            ),
            _buildLeaderActionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Kas Kelas',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(8); // Kas Tab
                }
              },
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLeaderMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLeaderActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
            onTap: onTap,
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 64, color: Color(0xFFF3F4F6)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
        onTap: onTap,
      ),
    );
  }

  void _showClassInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Informasi Kelas ILKOM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Program Studi: S1 Ilmu Komunikasi'),
            SizedBox(height: 6),
            Text('• Fakultas: Ilmu Sosial dan Ilmu Politik (FISIP)'),
            SizedBox(height: 6),
            Text('• Universitas: Universitas Abdul Azis Lamadjido (UNAZLAM)'),
            SizedBox(height: 6),
            Text('• Angkatan: 2026 (Semester 1)'),
            SizedBox(height: 6),
            Text('• Total Mahasiswa: 23 Orang'),
            SizedBox(height: 6),
            Text('• Ruang Kelas Utama: Ruang A2'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
