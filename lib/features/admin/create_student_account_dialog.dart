import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/admin_account_service.dart';
import '../../core/widgets/saas_components.dart';
import '../../models/models.dart';

class CreateStudentAccountDialog extends StatefulWidget {
  const CreateStudentAccountDialog({super.key});

  @override
  State<CreateStudentAccountDialog> createState() =>
      _CreateStudentAccountDialogState();
}

class _CreateStudentAccountDialogState
    extends State<CreateStudentAccountDialog> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _initialPasswordController = TextEditingController();
  final _confirmInitialPasswordController = TextEditingController();
  final _noWaController = TextEditingController();
  final _peminatanController = TextEditingController();
  int _semester = 1;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _initialPasswordController.dispose();
    _confirmInitialPasswordController.dispose();
    _noWaController.dispose();
    _peminatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_step3Key.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await AdminAccountService.createStudentAccount(
        nama: _namaController.text,
        nim: _nimController.text,
        email: _emailController.text,
        initialPassword: _initialPasswordController.text,
        noWa: _noWaController.text,
        semester: _semester,
        peminatan: _peminatanController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        StudentProfile(
          id: _nimController.text.trim(),
          nim: _nimController.text.trim(),
          nama: _namaController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          noWa: _noWaController.text.trim(),
          peminatan: _peminatanController.text.trim(),
          semester: _semester,
          role: 'MAHASISWA',
          jabatan: 'Mahasiswa',
          isAktif: true,
        ),
      );
    } on AdminAccountServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // rounded-3xl
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: AppColors.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header with Soft Glassmorphism style
              GlassModalHeader(
                title: 'Buat Akun Mahasiswa Baru',
                subtitle: 'Lengkapi data mahasiswa dalam 3 tahap praktis.',
                icon: Icons.person_add_alt_1_rounded,
                onClose: _isSubmitting ? null : () => Navigator.of(context).pop(),
              ),

              // Multi-step Stepper Form
              Flexible(
                child: SaaSStepper(
                  isSubmitting: _isSubmitting,
                  completeLabel: 'Buat & Kirim Undangan',
                  onCancel: () => Navigator.of(context).pop(),
                  onComplete: _submit,
                  steps: [
                    // Step 1: Identitas Akademik
                    SaaSStepItem(
                      title: 'Data Diri',
                      subtitle: 'Masukkan nama lengkap, NIM, dan semester aktif mahasiswa.',
                      icon: Icons.badge_outlined,
                      validator: () => _step1Key.currentState?.validate() ?? false,
                      content: Form(
                        key: _step1Key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaaSInputField(
                              controller: _namaController,
                              label: 'Nama Lengkap',
                              hintText: 'Contoh: Ahmad Maulana',
                              prefixIcon: Icons.person_outline_rounded,
                              isRequired: true,
                              textCapitalization: TextCapitalization.words,
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'Nama lengkap wajib diisi.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            SaaSInputField(
                              controller: _nimController,
                              label: 'NIM (Nomor Induk Mahasiswa)',
                              hintText: 'Contoh: 2310114001',
                              prefixIcon: Icons.badge_outlined,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'NIM wajib diisi.';
                                }
                                if (!RegExp(r'^\d{6,20}$').hasMatch(val.trim())) {
                                  return 'Masukkan NIM 6–20 angka valid.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SEMESTER AKTIF'.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.9,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      DropdownButtonFormField<int>(
                                        initialValue: _semester,
                                        decoration: InputDecoration(
                                          prefixIcon: const Padding(
                                            padding: EdgeInsets.only(left: 14, right: 10),
                                            child: Icon(Icons.school_outlined, size: 20, color: AppColors.primaryLight),
                                          ),
                                          prefixIconConstraints: const BoxConstraints(minWidth: 44),
                                        ),
                                        items: List.generate(8, (i) => i + 1)
                                            .map((sem) => DropdownMenuItem(
                                                  value: sem,
                                                  child: Text(
                                                    'Semester $sem',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (v) {
                                                if (v != null) setState(() => _semester = v);
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SaaSInputField(
                              controller: _peminatanController,
                              label: 'Peminatan / Konsentrasi (Opsional)',
                              hintText: 'Contoh: Software Engineering, AI & Data',
                              prefixIcon: Icons.auto_stories_outlined,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Step 2: Kontak & Akses
                    SaaSStepItem(
                      title: 'Kontak',
                      subtitle: 'Alamat surel untuk pengiriman link aktivasi akun.',
                      icon: Icons.alternate_email_rounded,
                      validator: () => _step2Key.currentState?.validate() ?? false,
                      content: Form(
                        key: _step2Key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaaSInputField(
                              controller: _emailController,
                              label: 'Email Kampus / Pribadi',
                              hintText: 'mahasiswa@unazlam.ac.id',
                              prefixIcon: Icons.alternate_email_rounded,
                              isRequired: true,
                              keyboardType: TextInputType.emailAddress,
                              helperText: 'Tautan verifikasi akan otomatis dikirimkan ke email ini.',
                              validator: (val) {
                                final email = val?.trim() ?? '';
                                if (email.isEmpty) return 'Email wajib diisi.';
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                                  return 'Format email belum benar.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SaaSInputField(
                              controller: _noWaController,
                              label: 'Nomor WhatsApp (Opsional)',
                              hintText: '081234567890',
                              prefixIcon: Icons.chat_bubble_outline_rounded,
                              keyboardType: TextInputType.phone,
                              helperText: 'Digunakan untuk pengiriman notifikasi pengumuman darurat.',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Akun akan otomatis diberi hak akses peran Mahasiswa pada sistem.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                        height: 1.4,
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

                    // Step 3: Keamanan Akun
                    SaaSStepItem(
                      title: 'Keamanan',
                      subtitle: 'Tentukan kata sandi awal sementara untuk mahasiswa.',
                      icon: Icons.lock_outline_rounded,
                      validator: () => _step3Key.currentState?.validate() ?? false,
                      content: Form(
                        key: _step3Key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SaaSInputField(
                              controller: _initialPasswordController,
                              label: 'Kata Sandi Awal',
                              hintText: 'Minimal 8 karakter aman',
                              prefixIcon: Icons.lock_outline_rounded,
                              isRequired: true,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (val) {
                                if ((val ?? '').length < 8) {
                                  return 'Gunakan minimal 8 karakter.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SaaSInputField(
                              controller: _confirmInitialPasswordController,
                              label: 'Konfirmasi Kata Sandi',
                              hintText: 'Ulangi kata sandi di atas',
                              prefixIcon: Icons.lock_reset_rounded,
                              isRequired: true,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (val) {
                                if (val != _initialPasswordController.text) {
                                  return 'Kata sandi belum sama.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.amberSoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.amberBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield_outlined, color: AppColors.amberText, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sampaikan kata sandi ini kepada mahasiswa secara langsung. Mahasiswa diwajibkan memperbarui kata sandi setelah login pertama kali.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.amberText,
                                        height: 1.4,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
