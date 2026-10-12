import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/safe_launcher.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/widgets/qr_widget.dart';
import '../../models/models.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final String? userNim;
  final StudentProfile? student;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key,
    this.onNavigateTab,
    this.userNim,
    this.student,
    this.onBack,
    this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLeaderPanel = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label berhasil disalin ke papan klip! 📋'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo $name, saya ingin berkomunikasi mengenai perkuliahan ILKOM UNAZLAM...',
    );
    final url = 'https://wa.me/$internationalPhone?text=$message';
    await safeLaunchUrl(url);
  }

  Future<void> _openInstagram(String handle) async {
    final cleanHandle = handle.replaceAll('@', '').trim();
    if (cleanHandle.isEmpty) return;
    final url = 'https://instagram.com/$cleanHandle';
    await safeLaunchUrl(url);
  }

  Future<void> _openEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    final url = 'mailto:$cleanEmail';
    final opened = await safeLaunchUrl(url);
    if (!opened && mounted) {
      _copyToClipboard(cleanEmail, 'Email');
    }
  }

  void _showQrKtmModal(BuildContext context, StudentProfile student, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFF1E40AF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'KTM Digital Resmi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Universitas Abdul Azis Lamadjido • FISIP 2026',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),

            // Official QR Code
            QrCodeWidget(
              data: 'UNAZLAM:${student.nim}:${student.nama}:ILKOM2026',
              size: 210,
              foregroundColor: const Color(0xFF1E1B4B),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28283E) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    student.nama,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIM: ${student.nim} • S1 Ilmu Komunikasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E40AF),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 15),
                const SizedBox(width: 6),
                Text(
                  'Kartu Tanda Mahasiswa Digital Aktif & Terverifikasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Tutup Kartu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    bool obscurePass = true;
    bool obscureConfirm = true;
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Color(0xFF1E40AF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ubah Kata Sandi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kata sandi baru akan otomatis didaftarkan ke Supabase Auth cloud agar Anda dapat masuk dari perangkat mana saja.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePass,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      hintText: 'Minimal 6 karakter',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmationController,
                    obscureText: obscureConfirm,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: 'Ulangi Kata Sandi Baru',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  final p1 = passwordController.text;
                  final p2 = confirmationController.text;
                  if (p1.length < 6) {
                    setDialogState(() => errorText = 'Kata sandi minimal 6 karakter.');
                    return;
                  }
                  if (p1 != p2) {
                    setDialogState(() => errorText = 'Konfirmasi kata sandi tidak cocok.');
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Simpan & Sinkronkan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final activeNim = widget.student?.nim ?? widget.userNim;
        await AuthService.setPassword(
          passwordController.text,
          userNim: activeNim,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Kata sandi berhasil diperbarui dan disinkronkan ke Supabase Auth! 🎉'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is AuthServiceException ? e.message : 'Kata sandi gagal diubah. Coba lagi.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
    passwordController.dispose();
    confirmationController.dispose();
  }

  void _confirmLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text(
              'Keluar dari Akun?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Anda akan keluar dari sesi akun ${widget.student?.nama ?? 'mahasiswa'}. Anda dapat masuk kembali kapan saja menggunakan NIM dan kata sandi Anda.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                await AuthService.signOut();
              }
            },
            child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final parts = student.nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (student.nama.length >= 2 ? student.nama.substring(0, 2).toUpperCase() : 'M');

    final roleBadgeText = student.isAdmin
        ? 'System Administrator'
        : (student.isKetuaKelas
            ? 'Ketua Kelas ILKOM 2026'
            : (student.isBendahara
                ? 'Bendahara Kelas ILKOM 2026'
                : (student.isSekretaris
                    ? 'Sekretaris Kelas ILKOM 2026'
                    : (student.jabatan.isNotEmpty && student.jabatan != 'Mahasiswa'
                        ? '${student.jabatan} ILKOM 2026'
                        : 'Mahasiswa ILKOM 2026'))));

    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111018) : AppColors.background,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: const Color(0xFF1E40AF),
              size: 22,
            ),
            tooltip: 'KTM Digital QR',
            onPressed: () => _showQrKtmModal(context, student, isDark),
          ),
          IconButton(
            icon: Icon(
              Icons.palette_outlined,
              color: textPrimary,
              size: 22,
            ),
            tooltip: 'Tema Tampilan',
            onPressed: _showThemeSettingsDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ==========================================
            // PRESTIGIOUS DIGITAL STUDENT CARD (KTM DIGITAL)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF1E3A8A),
                          Color(0xFF2E1065),
                          Color(0xFF1E1B4B),
                        ]
                      : const [
                          Color(0xFF1E3A8A),
                          Color(0xFF2563EB),
                          Color(0xFF4F46E5),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    top: -25,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: -8,
                    child: Icon(
                      Icons.badge_rounded,
                      size: 96,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Kartu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UNAZLAM PALU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'FAKULTAS ILMU SOSIAL & POLITIK',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF34D399), width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Color(0xFF34D399), size: 7),
                                SizedBox(width: 4),
                                Text(
                                  'AKTIF',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Avatar Foto Profil
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
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
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nama Mahasiswa
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
                      const SizedBox(height: 5),

                      // Chip NIM Interaktif (Tap untuk Salin)
                      InkWell(
                        onTap: () => _copyToClipboard(student.nim, 'NIM'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NIM: ${student.nim}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.copy_rounded, color: Colors.white70, size: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chip Role
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              roleBadgeText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Aksi Kartu: Tampilkan QR KTM & Salin NIM
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showQrKtmModal(context, student, isDark),
                              icon: const Icon(Icons.qr_code_rounded, size: 16),
                              label: const Text('QR Code KTM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E40AF),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToClipboard(student.nim, 'NIM'),
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              label: const Text('Salin NIM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

            // ==========================================
            // RINGKASAN AKADEMIK CEPAT (QUICK STATS)
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Semester 1',
                    subtitle: 'Ganjil 2026/2027',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.meeting_room_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Ruang A2',
                    subtitle: 'FISIP Reguler',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onNavigateTab?.call(5), // Absensi Tab
                    borderRadius: BorderRadius.circular(16),
                    child: _buildQuickStatCard(
                      icon: Icons.fact_check_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFFF5F3FF),
                      title: 'Presensi',
                      subtitle: 'Buka Rekap ➔',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ==========================================
            // BIODATA & DATA AKADEMIK RESMI
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_outlined, color: Color(0xFF1E40AF), size: 17),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Data Akademik Resmi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.badge_outlined, 'Nomor Induk Mahasiswa', student.nim, textPrimary, textSecondary),
                  Divider(height: 24, color: dividerColor),
                  _buildDetailRow(Icons.menu_book_rounded, 'Program Studi', 'S1 Ilmu Komunikasi', textPrimary, textSecondary),
                  Divider(height: 24, color: dividerColor),
                  _buildDetailRow(
                    Icons.account_balance_outlined,
                    'Fakultas',
                    'Ilmu Sosial dan Ilmu Politik (FISIP)',
                    textPrimary,
                    textSecondary,
                  ),
                  Divider(height: 24, color: dividerColor),
                  _buildDetailRow(
                    Icons.stars_outlined,
                    'Peminatan / Konsentrasi',
                    student.peminatan.isNotEmpty ? student.peminatan : 'Ilmu Komunikasi Terapan',
                    textPrimary,
                    textSecondary,
                  ),
                  Divider(height: 24, color: dividerColor),
                  _buildDetailRow(
                    Icons.school_rounded,
                    'Status Terdaftar',
                    'Aktif • Angkatan 2026 FISIP UNAZLAM',
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // KONTAK RESMI & KOMUNIKASI
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.contact_mail_outlined, color: Color(0xFF10B981), size: 17),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kontak & Komunikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildActionContactRow(
                    icon: Icons.alternate_email_rounded,
                    iconColor: const Color(0xFF2563EB),
                    label: 'Email Mahasiswa',
                    value: student.email.isNotEmpty ? student.email : '${student.nim}@student.unazlam.ac.id',
                    actionIcon: Icons.email_outlined,
                    actionTooltip: 'Kirim Email',
                    onAction: () => _openEmail(student.email.isNotEmpty ? student.email : '${student.nim}@student.unazlam.ac.id'),
                    onTap: () => _copyToClipboard(student.email.isNotEmpty ? student.email : '${student.nim}@student.unazlam.ac.id', 'Email'),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 24, color: dividerColor),

                  // WhatsApp
                  _buildActionContactRow(
                    icon: Icons.phone_android_rounded,
                    iconColor: const Color(0xFF10B981),
                    label: 'Nomor WhatsApp',
                    value: student.noWa.isNotEmpty ? student.noWa : 'Belum diatur',
                    actionIcon: Icons.chat_rounded,
                    actionTooltip: 'Chat WhatsApp',
                    onAction: student.noWa.isNotEmpty ? () => _openWhatsApp(student.noWa, student.nama) : null,
                    onTap: student.noWa.isNotEmpty ? () => _copyToClipboard(student.noWa, 'Nomor WA') : null,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  // Instagram jika ada
                  if (student.instagram != null && student.instagram!.isNotEmpty) ...[
                    Divider(height: 24, color: dividerColor),
                    _buildActionContactRow(
                      icon: Icons.camera_alt_outlined,
                      iconColor: const Color(0xFFE11D48),
                      label: 'Instagram',
                      value: student.instagram!,
                      actionIcon: Icons.open_in_new_rounded,
                      actionTooltip: 'Buka Instagram',
                      onAction: () => _openInstagram(student.instagram!),
                      onTap: () => _openInstagram(student.instagram!),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // CONDITIONAL ROLE ACTIONS (PANEL PENGURUS)
            // ==========================================
            if (student.isKetuaKelas || student.isAdmin)
              InkWell(
                onTap: () => setState(() => _showLeaderPanel = true),
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
                        blurRadius: 14,
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
                              'Kelola absensi kelas, buat pengumuman, tugas & agenda',
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
                        blurRadius: 14,
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
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E7FF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Mahasiswa Aktif',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Terdaftar resmi pada S1 Ilmu Komunikasi FISIP UNAZLAM angkatan 2026.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ==========================================
            // PENGATURAN AKUN & PREFERENSI SISTEM
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.lock_reset_rounded,
                    iconColor: const Color(0xFF1E40AF),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Ubah Kata Sandi Akun',
                    subtitle: 'Ganti password login akun Anda',
                    onTap: _changePassword,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Informasi Kelas ILKOM',
                    subtitle: 'Ruang A2, Kampus FISIP UNAZLAM',
                    onTap: _showClassInfoDialog,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
                  _buildMenuItem(
                    icon: Icons.fact_check_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Rekap Absensi Saya',
                    subtitle: 'Periksa catatan presensi & persentase',
                    onTap: () => widget.onNavigateTab?.call(5),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
                  ListenableBuilder(
                    listenable: ThemeScope.notifier,
                    builder: (context, _) {
                      final isDarkTheme = ThemeScope.notifier.isDarkMode;
                      return _buildMenuItem(
                        icon: isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconColor: isDarkTheme ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        iconBg: isDarkTheme ? const Color(0xFF261D4C) : const Color(0xFFFEF3C7),
                        title: 'Mode Gelap (Dark Mode)',
                        subtitle: isDarkTheme ? 'Aktif (OLED Charcoal)' : 'Non-aktif (Light Mode)',
                        trailing: Switch.adaptive(
                          value: isDarkTheme,
                          activeTrackColor: const Color(0xFF1E40AF),
                          onChanged: (_) => ThemeScope.notifier.toggleTheme(),
                        ),
                        onTap: () => ThemeScope.notifier.toggleTheme(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      );
                    },
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
                  _buildMenuItem(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'Pengaturan Tema Tampilan',
                    subtitle: 'Pilih Terang, Gelap, atau Ikuti Sistem HP',
                    onTap: _showThemeSettingsDialog,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // TOMBOL KELUAR DARI AKUN (LOGOUT)
            // ==========================================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF5A1E1E) : const Color(0xFFFECACA),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _confirmLogout,
                  borderRadius: BorderRadius.circular(18),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
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
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionContactRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required IconData actionIcon,
    required String actionTooltip,
    VoidCallback? onAction,
    VoidCallback? onTap,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              icon: Icon(actionIcon, size: 18, color: iconColor),
              tooltip: actionTooltip,
              onPressed: onAction,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
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
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textSecondary.withValues(alpha: 0.5),
            ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // SCREEN: PANEL KETUA KELAS
  // ==========================================
  Widget _buildLeaderPanelScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111018) : AppColors.background,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => setState(() => _showLeaderPanel = false),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: Color(0xFFD97706),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Panel Ketua Kelas',
              style: TextStyle(
                color: textPrimary,
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
              color: isDark ? const Color(0xFF38230A) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda memiliki hak akses sebagai Ketua Kelas ILKOM UNAZLAM 2026. Gunakan pintasan di bawah untuk mengelola kelas secara efisien.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildLeaderMenuCard([
            _buildLeaderActionTile(
              icon: Icons.how_to_reg_outlined,
              title: 'Kelola & Buka Sesi Presensi',
              subtitle: 'Buat token QR & PIN presensi kelas',
              onTap: () => widget.onNavigateTab?.call(5),
              isDark: isDark,
            ),
            _buildLeaderActionTile(
              icon: Icons.campaign_outlined,
              title: 'Buat Pengumuman Kelas',
              subtitle: 'Kirim info resmi untuk seluruh mahasiswa',
              onTap: () => widget.onNavigateTab?.call(7),
              isDark: isDark,
            ),
            _buildLeaderActionTile(
              icon: Icons.assignment_outlined,
              title: 'Kelola Tugas Kuliah',
              subtitle: 'Tambah tugas & pantau pengumpulan',
              onTap: () => widget.onNavigateTab?.call(2),
              isDark: isDark,
            ),
            _buildLeaderActionTile(
              icon: Icons.people_outline_rounded,
              title: 'Data & Direktori Mahasiswa',
              subtitle: 'Lihat daftar 23 anggota kelas',
              onTap: () => widget.onNavigateTab?.call(3),
              isDark: isDark,
            ),
            _buildLeaderActionTile(
              icon: Icons.calendar_month_outlined,
              title: 'Kelola Agenda Perkuliahan',
              subtitle: 'Atur jadwal ujian & kegiatan kelas',
              onTap: () => widget.onNavigateTab?.call(6),
              isDark: isDark,
            ),
            _buildLeaderActionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Kas & Keuangan Kelas',
              subtitle: 'Pantau saldo dan iuran bendahara',
              onTap: () => widget.onNavigateTab?.call(8),
              isLast: true,
              isDark: isDark,
            ),
          ], cardBg, borderColor),
        ],
      ),
    );
  }

  Widget _buildLeaderMenuCard(List<Widget> children, Color cardBg, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLeaderActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
    required bool isDark,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E40AF), size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
            onTap: onTap,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6),
          ),
      ],
    );
  }

  void _showThemeSettingsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentMode = ThemeScope.notifier.themeMode;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                const Icon(Icons.palette_outlined, color: Color(0xFF1E40AF), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Tema Tampilan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOptionTile(
                  title: 'Mode Terang (Light)',
                  subtitle: 'Palet cerah bersih untuk siang hari',
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFD97706),
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.light);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  title: 'Mode Gelap (Dark)',
                  subtitle: 'OLED Charcoal ramah mata',
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.dark);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  title: 'Ikuti Sistem HP',
                  subtitle: 'Otomatis mengikuti setelan perangkat',
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF10B981),
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.system);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E40AF).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E40AF) : (isDark ? const Color(0xFF38384E) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1E40AF), size: 18),
          ],
        ),
      ),
    );
  }

  void _showClassInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF1E40AF), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Informasi Kelas ILKOM',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfoRow('Program Studi', 'S1 Ilmu Komunikasi', isDark),
            _buildClassInfoRow('Fakultas', 'Ilmu Sosial dan Ilmu Politik (FISIP)', isDark),
            _buildClassInfoRow('Universitas', 'Universitas Abdul Azis Lamadjido (UNAZLAM)', isDark),
            _buildClassInfoRow('Angkatan', '2026 (Semester 1 Reguler)', isDark),
            _buildClassInfoRow('Total Mahasiswa', '23 Orang Mahasiswa Aktif', isDark),
            _buildClassInfoRow('Ruang Utama', 'Ruang A2 FISIP UNAZLAM Palu', isDark),
            _buildClassInfoRow('Ketua Kelas', 'Nur Farida (260250023)', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
