import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme_notifier.dart';
import '../../models/models.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final String? userNim;
  final StudentProfile? student;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    this.onNavigateTab,
    this.userNim,
    this.student,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLeaderPanel = false;

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    String? errorText;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah kata sandi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Kata sandi baru'),
              ),
              TextField(
                controller: confirmationController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.length < 8) {
                  setDialogState(() => errorText = 'Minimal 8 karakter.');
                  return;
                }
                if (passwordController.text != confirmationController.text) {
                  setDialogState(() => errorText = 'Kata sandi belum sama.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AuthService.setPassword(passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kata sandi berhasil diubah.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kata sandi gagal diubah. Coba lagi.')),
          );
        }
      }
    }
    passwordController.dispose();
    confirmationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLeaderPanel) {
      return _buildLeaderPanelScreen();
    }
    return _buildProfileScreen();
  }

  Widget _buildProfileScreen() {
    final student = widget.student;
    if (student == null) {
      return const Scaffold(
        body: Center(
          child: Text('Profil akun tidak ditemukan. Silakan masuk kembali.'),
        ),
      );
    }

    final parts = student.nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : student.nama.substring(0, 2).toUpperCase();

    final roleBadgeText = student.isAdmin
        ? 'System Administrator'
        : (student.isKetuaKelas
              ? 'Ketua Kelas ILKOM 2026'
              : (student.isBendahara
                    ? 'Bendahara Kelas ILKOM 2026'
                    : (student.isSekretaris
                          ? 'Sekretaris Kelas ILKOM 2026'
                          : 'Mahasiswa ILKOM 2026')));



    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
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
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF111827),
              size: 22,
            ),
            onPressed: () {
              _showThemeSettingsDialog();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Prestigious Student ID Card Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B1E94),
                    Color(0xFF1E40AF),
                    Color(0xFF7A5DF5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: -10,
                    child: Icon(
                      Icons.badge_rounded,
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.white,
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Color(0xFF1E40AF),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
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
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        student.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIM: ${student.nim}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, color: Colors.white, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  roleBadgeText,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'UNAZLAM AKTIF',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF86EFAC),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Profile Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.badge_outlined, 'Nomor Induk Mahasiswa', student.nim),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailRow(Icons.school_outlined, 'Program Studi', 'S1 Ilmu Komunikasi'),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailRow(
                    Icons.account_balance_outlined,
                    'Fakultas',
                    'Ilmu Sosial dan Ilmu Politik (FISIP)',
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Status Perkuliahan', 'Semester 1 • T.A 2026/2027'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Change Password Action Card / Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _changePassword,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_rounded, color: Color(0xFF1E40AF), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ubah Kata Sandi Akun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Conditional Role & Jabatan Action Card
            if (student.isKetuaKelas || student.isAdmin)
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
                      colors: [Color(0xFF1E40AF), Color(0xFF755BF7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
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
                        child: const Icon(
                          Icons.workspace_premium_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Ketua Kelas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kelola absensi harian kelas, tugas, agenda & pengumuman',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )
            else if (student.isBendahara)
              InkWell(
                onTap: () => widget.onNavigateTab?.call(8), // Open Kas Kelas
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.3),
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
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Bendahara Kelas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kelola transaksi kas kelas & perbarui QRIS iuran',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: Color(0xFF1E40AF),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Mahasiswa Aktif',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Terdaftar resmi pada S1 Ilmu Komunikasi FISIP UNAZLAM angkatan 2026.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  const Divider(
                    height: 1,
                    indent: 60,
                    color: Color(0xFFF3F4F6),
                  ),
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
                  const Divider(
                    height: 1,
                    indent: 60,
                    color: Color(0xFFF3F4F6),
                  ),
                  ListenableBuilder(
                    listenable: ThemeScope.notifier,
                    builder: (context, _) {
                      final isDark = ThemeScope.notifier.isDarkMode;
                      return _buildMenuItem(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97706),
                        iconBg: isDark
                            ? const Color(0xFF261D4C)
                            : const Color(0xFFFEF3C7),
                        title: 'Mode Gelap (Dark Mode)',
                        subtitle: isDark
                            ? 'Aktif (OLED Dark)'
                            : 'Non-aktif (Light Mode)',
                        trailing: Switch.adaptive(
                          value: isDark,
                          activeColor: const Color(0xFF1E40AF),
                          onChanged: (_) => ThemeScope.notifier.toggleTheme(),
                        ),
                        onTap: () => ThemeScope.notifier.toggleTheme(),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 60,
                    color: Color(0xFFF3F4F6),
                  ),
                  _buildMenuItem(
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Pengaturan Tampilan',
                    subtitle: 'Pilih Light, Dark, atau Ikuti Sistem',
                    onTap: () {
                      _showThemeSettingsDialog();
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
            Icon(
              Icons.workspace_premium_outlined,
              color: Color(0xFFD97706),
              size: 20,
            ),
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
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
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
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
            onTap: onTap,
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 64, color: Color(0xFFF3F4F6)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E40AF)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
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
    Widget? trailing,
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
        onTap: onTap,
      ),
    );
  }

  void _showThemeSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.palette_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Tema Tampilan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Mode Terang (Light)'),
              subtitle: const Text(
                'Palet cerah & bersih',
                style: TextStyle(fontSize: 11),
              ),
              value: ThemeMode.light,
              groupValue: ThemeScope.notifier.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) ThemeScope.notifier.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Mode Gelap (Dark)'),
              subtitle: const Text(
                'OLED Charcoal ramah mata',
                style: TextStyle(fontSize: 11),
              ),
              value: ThemeMode.dark,
              groupValue: ThemeScope.notifier.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) ThemeScope.notifier.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Ikuti Sistem HP'),
              subtitle: const Text(
                'Otomatis sesuai setelan Android',
                style: TextStyle(fontSize: 11),
              ),
              value: ThemeMode.system,
              groupValue: ThemeScope.notifier.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) ThemeScope.notifier.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClassInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Informasi Kelas ILKOM',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
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
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
