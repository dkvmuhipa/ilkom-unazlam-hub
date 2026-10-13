import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/avatar_picker.dart';
import '../../core/services/safe_launcher.dart';
import '../../core/theme/theme_notifier.dart';
import '../../models/models.dart';
import 'widgets/avatar_selection_modal.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/class_info_dialog.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/ktm_card_modal.dart';
import 'widgets/theme_settings_dialog.dart';

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
  String? _currentAvatarUrl;
  bool _isUpdatingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    final student = widget.student;
    if (student == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_avatar_${student.nim}');
      if (saved != null && saved.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentAvatarUrl = saved;
            student.avatarUrl = saved;
          });
        }
      } else if (student.avatarUrl != null && student.avatarUrl!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentAvatarUrl = student.avatarUrl;
          });
        }
      }
    } catch (_) {}
  }

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
            Text('$label berhasil disalin ke papan klip! ðŸ“‹'),
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
                  Text('Foto profil berhasil diperbarui! ðŸŽ‰'),
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
                Text('Avatar profil berhasil diterapkan! âœ¨'),
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
      onSaved: (cleanWa, selectedPeminatan, cleanEmail, cleanIg, cleanLinkedin) {
        if (mounted) {
          setState(() {
            student.noWa = cleanWa;
            student.peminatan = selectedPeminatan;
            student.email = cleanEmail;
            student.instagram = cleanIg;
            student.linkedin = cleanLinkedin;
          });
        }
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

                      // Avatar Foto Profil Interaktif (Dapat Diganti)
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showChangeAvatarModal(context, student, isDark),
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
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _buildAvatarImage(_currentAvatarUrl ?? student.avatarUrl, initials),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E40AF),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  if (_isUpdatingAvatar)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.45),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showChangeAvatarModal(context, student, isDark),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ganti Foto Profil',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
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
                      subtitle: 'Buka Rekap âž”',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      InkWell(
                        onTap: () => _showEditProfileModal(context, student, isDark),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, color: Color(0xFF1E40AF), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Peminatan',
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
                    'Aktif â€¢ Angkatan 2026 FISIP UNAZLAM',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      InkWell(
                        onTap: () => _showEditProfileModal(context, student, isDark),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, color: Color(0xFF059669), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Ubah',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
                    value: (student.email.isNotEmpty &&
                            !student.email.endsWith('@student.unazlam.ac.id') &&
                            !student.email.endsWith('@students.unazlam.ac.id'))
                        ? student.email
                        : 'Belum diatur',
                    actionIcon: Icons.email_outlined,
                    actionTooltip: 'Kirim Email',
                    onAction: (student.email.isNotEmpty &&
                            !student.email.endsWith('@student.unazlam.ac.id') &&
                            !student.email.endsWith('@students.unazlam.ac.id'))
                        ? () => _openEmail(student.email)
                        : null,
                    onTap: (student.email.isNotEmpty &&
                            !student.email.endsWith('@student.unazlam.ac.id') &&
                            !student.email.endsWith('@students.unazlam.ac.id'))
                        ? () => _copyToClipboard(student.email, 'Email')
                        : null,
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
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Ganti Foto Profil',
                    subtitle: 'Kamera, galeri, tautan URL atau avatar digital',
                    onTap: () => _showChangeAvatarModal(context, student, isDark),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
                  _buildMenuItem(
                    icon: Icons.edit_note_rounded,
                    iconColor: const Color(0xFF0D9488),
                    iconBg: const Color(0xFFCCFBF1),
                    title: 'Ubah Data Kontak & Peminatan',
                    subtitle: 'Nomor WhatsApp, Peminatan, Instagram & LinkedIn',
                    onTap: () => _showEditProfileModal(context, student, isDark),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Divider(height: 1, indent: 60, color: dividerColor),
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
    ThemeSettingsDialog.show(context);
  }

  void _showClassInfoDialog() {
    ClassInfoDialog.show(context);
  }
}
