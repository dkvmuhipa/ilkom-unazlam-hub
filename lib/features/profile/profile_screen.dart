import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/avatar_picker.dart';
import '../../core/widgets/scale_button.dart';
import '../../models/models.dart';
import 'widgets/avatar_selection_modal.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/class_info_dialog.dart';
import 'widgets/digital_ktm_card.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/ktm_card_modal.dart';
import 'widgets/profile_academic_section.dart';
import 'widgets/profile_contact_section.dart';
import 'widgets/profile_quick_stats.dart';
import 'widgets/theme_settings_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final String? userNim;
  final StudentProfile? student;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final ValueChanged<StudentProfile>? onProfileUpdated;

  const ProfileScreen({
    super.key,
    this.onNavigateTab,
    this.userNim,
    this.student,
    this.onBack,
    this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLeaderPanel = false;
  String? _currentAvatarUrl;
  bool _isUpdatingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfileDetails();
  }

  Future<void> _loadSavedProfileDetails() async {
    final student = widget.student;
    if (student == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      AuthService.applyCustomProfileOverrides(student, prefs);
      final savedAvatar = prefs.getString('custom_avatar_${student.nim}');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        _currentAvatarUrl = savedAvatar;
        student.avatarUrl = savedAvatar;
      } else if (student.avatarUrl != null && student.avatarUrl!.isNotEmpty) {
        _currentAvatarUrl = student.avatarUrl;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Widget _buildAvatarImage(String? avatarUrl, String initials) {
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      final url = avatarUrl.trim();
      // 1. Data Base64 (Format data:image/...;base64,xxx atau base64 mentah)
      if (url.startsWith('data:image') || (!url.startsWith('http') && !url.startsWith('assets') && url.length > 100)) {
        try {
          final commaIndex = url.indexOf(',');
          final base64String = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initials),
          );
        } catch (_) {
          return _buildFallbackAvatar(initials);
        }
      }

      // 2. Network Image (http / https)
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initials),
        );
      }

      // 3. Asset Image
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initials),
        );
      }
    }

    // Default Logo / Inisial
    return _buildFallbackAvatar(initials);
  }

  Widget _buildFallbackAvatar(String initials) {
    return Image.asset(
      'assets/images/logo.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarImage(StudentProfile student, ImageSource source) async {
    Navigator.of(context, rootNavigator: true).pop(); // Tutup bottom sheet
    setState(() => _isUpdatingAvatar = true);

    try {
      Uint8List? bytes;

      // Pada Flutter Web, gunakan langsung HTML file picker jika memilih galeri
      // atau jika plugin method channel image_picker belum terdaftar
      if (kIsWeb) {
        try {
          final picker = ImagePicker();
          final picked = await picker.pickImage(
            source: source,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 85,
          );
          if (picked != null) {
            bytes = await picked.readAsBytes();
          }
        } catch (_) {
          // Fallback instan menggunakan native HTML file input browser
          bytes = await pickImageBytesWeb();
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (picked != null) {
          bytes = await picked.readAsBytes();
        }
      }

      if (bytes != null) {
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        await AuthService.updateAvatar(
          nim: student.nim,
          avatarUrl: base64String,
        );

        if (mounted) {
          setState(() {
            _currentAvatarUrl = base64String;
            student.avatarUrl = base64String;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Foto profil berhasil diperbarui! 🎉'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  Future<void> _applyAvatarPreset(StudentProfile student, String url) async {
    Navigator.of(context, rootNavigator: true).pop(); // Tutup bottom sheet
    setState(() => _isUpdatingAvatar = true);

    try {
      await AuthService.updateAvatar(
        nim: student.nim,
        avatarUrl: url,
      );

      if (mounted) {
        setState(() {
          _currentAvatarUrl = url;
          student.avatarUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Avatar profil berhasil diterapkan! ✨'),
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
            content: Text('Gagal menerapkan avatar: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  Future<void> _resetToDefaultAvatar(StudentProfile student) async {
    Navigator.of(context, rootNavigator: true).pop(); // Tutup bottom sheet
    setState(() => _isUpdatingAvatar = true);

    try {
      await AuthService.updateAvatar(
        nim: student.nim,
        avatarUrl: null,
      );

      if (mounted) {
        setState(() {
          _currentAvatarUrl = null;
          student.avatarUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.restore_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Foto profil dikembalikan ke logo kampus resmi.'),
              ],
            ),
            backgroundColor: const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mereset foto: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  void _showChangeAvatarModal(BuildContext context, StudentProfile student, bool isDark) {
    AvatarSelectionModal.show(
      context,
      student: student,
      isDark: isDark,
      currentAvatarUrl: _currentAvatarUrl,
      avatarBuilder: (url, initials) => _buildAvatarImage(url, initials),
      onPickImage: (source) => _pickAvatarImage(student, source),
      onApplyPreset: (url) => _applyAvatarPreset(student, url),
      onResetDefault: () => _resetToDefaultAvatar(student),
    );
  }

  void _showEditProfileModal(BuildContext context, StudentProfile student, bool isDark) {
    EditProfileModal.show(
      context,
      student: student,
      isDark: isDark,
      onSaved: (cleanWa, selectedPeminatan, cleanEmail, cleanIg, cleanLinkedin, cleanBio) {
        if (mounted) {
          setState(() {
            student.noWa = cleanWa;
            student.peminatan = selectedPeminatan;
            student.email = cleanEmail;
            student.instagram = cleanIg;
            student.linkedin = cleanLinkedin;
            student.bio = cleanBio;
          });
        }
        widget.onProfileUpdated?.call(student);
      },
    );
  }

  void _showQrKtmModal(BuildContext context, StudentProfile student, bool isDark) {
    KtmCardModal.show(
      context,
      student: student,
      isDark: isDark,
      currentAvatarUrl: _currentAvatarUrl,
      avatarBuilder: (url, initials) => _buildAvatarImage(url, initials),
    );
  }

  Future<void> _changePassword() async {
    final activeNim = widget.student?.nim ?? widget.userNim;
    await ChangePasswordDialog.show(context, userNim: activeNim);
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
            icon: Icon(Icons.refresh_rounded, color: textPrimary, size: 20),
            tooltip: 'Segarkan Profil',
            onPressed: () => _loadSavedProfileDetails(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSavedProfileDetails();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // 1. Prestigious Smart KTM Card with EMV chip, role badge & animated glow
            FadeSlideEntrance(
              delay: Duration.zero,
              child: DigitalKtmCard(
                student: student,
                isDark: isDark,
                currentAvatarUrl: _currentAvatarUrl,
                isUpdatingAvatar: _isUpdatingAvatar,
                avatarBuilder: (url, initials) => _buildAvatarImage(url, initials),
                onChangeAvatar: () => _showChangeAvatarModal(context, student, isDark),
                onOpenQrKtm: () => _showQrKtmModal(context, student, isDark),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Academic Overview Capsules (Semester, SKS, Room, Attendance)
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 60),
              child: ProfileQuickStats(
                isDark: isDark,
                onOpenAttendance: () => widget.onNavigateTab?.call(5),
                onOpenSchedule: () => widget.onNavigateTab?.call(1),
                onOpenClassInfo: _showClassInfoDialog,
              ),
            ),
            const SizedBox(height: 18),

            // 3. Official Academic Biodata Section (NIM, Prodi, Fakultas, Peminatan, Motto)
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 120),
              child: ProfileAcademicSection(
                student: student,
                isDark: isDark,
                onEditPeminatan: () => _showEditProfileModal(context, student, isDark),
              ),
            ),
            const SizedBox(height: 18),

            // 4. Official Contact & Social Media Section (Email, WA, IG, LinkedIn)
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 180),
              child: ProfileContactSection(
                student: student,
                isDark: isDark,
                onEditContact: () => _showEditProfileModal(context, student, isDark),
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // CONDITIONAL ROLE ACTIONS (PANEL PENGURUS)
            // ==========================================
            if (student.isKetuaKelas || student.isAdmin) ...[
              ScaleButton(
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
              ),
              const SizedBox(height: 18),
            ] else if (student.isBendahara) ...[
              ScaleButton(
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
              ),
              const SizedBox(height: 18),
            ],

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
                    subtitle: 'Ganti kata sandi login akun Anda',
                    onTap: _changePassword,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
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
            ScaleButton(
              onTap: _confirmLogout,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF5A1E1E) : const Color(0xFFFECACA),
                  ),
                ),
                child: const Row(
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
            const SizedBox(height: 28),
          ],
        ),
      ),
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
    ThemeSettingsDialog.show(context);
  }

  void _showClassInfoDialog() {
    ClassInfoDialog.show(context);
  }
}
