import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/saas_components.dart';
import '../../models/models.dart';

class LoginScreen extends StatefulWidget {
  final Function(StudentProfile profile) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _nimController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan NIM atau email akun Anda.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan password akun Anda.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.signIn(
        identifier: identifier,
        password: password,
      );
      if (!mounted) return;
      widget.onLoginSuccess(profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AuthServiceException ? error.message : 'NIM/email atau kata sandi salah, atau koneksi ke layanan login gagal.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _nimController.text.contains('@') ? _nimController.text.trim() : '',
    );
    final email = await showGlassModal<String>(
      context: context,
      maxWidth: 480,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassModalHeader(
            title: 'Lupa Kata Sandi?',
            subtitle:
                'Masukkan email akun yang terdaftar untuk menerima tautan pemulihan.',
            icon: Icons.lock_reset_rounded,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SaaSInputField(
                  label: 'Email Pemulihan',
                  controller: emailController,
                  hintText: 'nama@student.unazlam.ac.id',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tautan untuk membuat kata sandi baru akan dikirim ke email tersebut. NIM mahasiswa hanya digunakan untuk login harian.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSub,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSub,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, emailController.text.trim()),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'Kirim Tautan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Schedule dispose after dialog route pop animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailController.dispose();
    });

    if (email == null || email.isEmpty || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.requestPasswordReset(
        email: email,
        redirectTo: Uri.base.origin,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jika email terdaftar, tautan reset telah dikirim. Periksa kotak masuk dan folder spam.',
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AuthServiceException
                ? error.message
                : 'Tautan reset gagal dikirim. Periksa koneksi dan konfigurasi URL Auth Supabase.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickFillAndLogin(String identifier, String defaultPassword) {
    _nimController.text = identifier;
    _passwordController.text = defaultPassword;
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SaaSCard(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Clean Brand Header
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.primaryBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Typography: Bold tegas & tracking-tight
                    Text(
                      'ILMU KOMUNIKASI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'UNAZLAM HUB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                        letterSpacing: 3.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Masuk ke Akun Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Portal Manajemen Akademik & Kelas FISIP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Input NIM / Email dengan SaaSInputField
                    SaaSInputField(
                      label: 'NIM atau Email Akun',
                      controller: _nimController,
                      hintText: 'admin atau NIM mahasiswa',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),

                    // Input Password
                    SaaSInputField(
                      label: 'Kata Sandi',
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lupa Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lupa kata sandi?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Masuk Royal Navy Blue rounded-2xl
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Divider & Uji Coba Cepat (Role & Jabatan)
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.borderMedium)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'AKSES CEPAT PENGUJIAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.borderMedium)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Chips Akses Cepat dengan SoftPillBadge
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _quickFillAndLogin('admin', '123456'),
                          borderRadius: BorderRadius.circular(999),
                          child: SoftPillBadge.danger(
                            label: 'Admin Sistem',
                            icon: Icons.admin_panel_settings_rounded,
                          ),
                        ),
                        InkWell(
                          onTap: () => _quickFillAndLogin('260250023', '123456'),
                          borderRadius: BorderRadius.circular(999),
                          child: SoftPillBadge.warning(
                            label: 'Ketua Kelas',
                            icon: Icons.person_rounded,
                          ),
                        ),
                        InkWell(
                          onTap: () => _quickFillAndLogin('260250020', '123456'),
                          borderRadius: BorderRadius.circular(999),
                          child: SoftPillBadge.success(
                            label: 'Bendahara',
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        InkWell(
                          onTap: () => _quickFillAndLogin('260250008', '123456'),
                          borderRadius: BorderRadius.circular(999),
                          child: SoftPillBadge.info(
                            label: 'Sekretaris',
                            icon: Icons.assignment_turned_in_rounded,
                          ),
                        ),
                        InkWell(
                          onTap: () => _quickFillAndLogin('260250001', '123456'),
                          borderRadius: BorderRadius.circular(999),
                          child: SoftPillBadge.neutral(
                            label: 'Mahasiswa',
                            icon: Icons.school_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Pilih peran di atas untuk langsung masuk atau gunakan NIM akun Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
