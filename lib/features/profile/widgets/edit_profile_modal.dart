import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

/// Ultra-modern bottom sheet allowing students to update their profile data:
/// WhatsApp number, Email, Study Concentration (Peminatan), Instagram, LinkedIn, and Motto/Bio.
class EditProfileModal {
  static void show(
    BuildContext context, {
    required StudentProfile student,
    required bool isDark,
    required void Function(
      String noWa,
      String peminatan,
      String email,
      String? instagram,
      String? linkedin,
      String? bio,
    ) onSaved,
  }) {
    final waController = TextEditingController(text: student.noWa);
    final emailController = TextEditingController(text: student.email);
    final igController = TextEditingController(text: student.instagram ?? '');
    final linkedinController = TextEditingController(text: student.linkedin ?? '');
    final bioController = TextEditingController(text: student.bio ?? '');

    final peminatanOptions = [
      'Public Relations',
      'Jurnalistik',
      'Advertising',
      'Broadcasting',
    ];

    String selectedPeminatan = peminatanOptions.contains(student.peminatan)
        ? student.peminatan
        : peminatanOptions.first;

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
          final inputFill = isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC);
          final inputBorder = isDark ? const Color(0xFF38384E) : const Color(0xFFE2E8F0);
          final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
          final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Data & Kontak Mahasiswa',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Perbarui kontak, peminatan, dan motto akademik Anda',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. Konsentrasi / Peminatan Dropdown
                  _buildFieldLabel('Konsentrasi / Peminatan Studi', textPrimary),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: inputBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeminatan,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E40AF)),
                        items: peminatanOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF1E40AF)),
                                const SizedBox(width: 8),
                                Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedPeminatan = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. WhatsApp
                  _buildFieldLabel('Nomor WhatsApp Aktif', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: waController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Email Mahasiswa
                  _buildFieldLabel('Alamat Email Pribadi / Mahasiswa', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Motto / Bio Singkat Mahasiswa
                  _buildFieldLabel('Motto / Bio Akademik Singkat', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bioController,
                    maxLength: 80,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Semangat berproses di dunia komunikasi digital ✨',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.format_quote_rounded, size: 18, color: Color(0xFF8B5CF6)),
                      filled: true,
                      fillColor: inputFill,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Instagram
                  _buildFieldLabel('Username Instagram', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: igController,
                    decoration: InputDecoration(
                      hintText: '@username_kamu',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFFE11D48)),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. LinkedIn
                  _buildFieldLabel('Tautan Profil LinkedIn (Opsional)', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: linkedinController,
                    decoration: InputDecoration(
                      hintText: 'https://linkedin.com/in/username',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.work_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Simpan Button with ScaleButton
                  ScaleButton(
                    onTap: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final cleanWa = waController.text.trim();
                            final cleanEmail = emailController.text.trim();
                            var cleanIg = igController.text.trim();
                            if (cleanIg.startsWith('@')) cleanIg = cleanIg.substring(1).trim();
                            final cleanLinkedin = linkedinController.text.trim();
                            final cleanBio = bioController.text.trim();

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(modalCtx);

                            try {
                              await AuthService.updateProfileDetails(
                                nim: student.nim,
                                noWa: cleanWa,
                                peminatan: selectedPeminatan,
                                email: cleanEmail,
                                instagram: cleanIg,
                                linkedin: cleanLinkedin,
                                bio: cleanBio,
                              );

                              onSaved(
                                cleanWa,
                                selectedPeminatan,
                                cleanEmail,
                                cleanIg.isNotEmpty ? cleanIg : null,
                                cleanLinkedin.isNotEmpty ? cleanLinkedin : null,
                                cleanBio.isNotEmpty ? cleanBio : null,
                              );

                              HapticFeedback.heavyImpact();
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Data profil berhasil diperbarui! 🎉'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan profil: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                    scaleDown: 0.96,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Simpan Perubahan Profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(modalCtx),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
