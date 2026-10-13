import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/models.dart';

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
    ) onSaved,
  }) {
    final waController = TextEditingController(text: student.noWa);
    final emailController = TextEditingController(text: student.email);
    final igController = TextEditingController(text: student.instagram ?? '');
    final linkedinController = TextEditingController(text: student.linkedin ?? '');

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
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF1E40AF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Data Profil',
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
                    'Perbarui kontak dan peminatan konsentrasi studi Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp
                  Text(
                    'Nomor WhatsApp Aktif',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: waController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  Text(
                    'Alamat Email',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF3B82F6)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Peminatan Dropdown
                  Text(
                    'Konsentrasi / Peminatan',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeminatan,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF28283E) : Colors.white,
                        items: peminatanOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
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

                  // Instagram
                  Text(
                    'Instagram (Opsional)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: igController,
                    decoration: InputDecoration(
                      hintText: '@username',
                      prefixIcon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFFEC4899)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // LinkedIn
                  Text(
                    'LinkedIn URL / Handle (Opsional)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: linkedinController,
                    decoration: InputDecoration(
                      hintText: 'linkedin.com/in/username',
                      prefixIcon: const Icon(Icons.work_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final cleanWa = waController.text.trim();
                              final cleanEmail = emailController.text.trim();
                              final cleanIg = igController.text.trim();
                              final cleanLinkedin = linkedinController.text.trim();

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
                                );

                                onSaved(
                                  cleanWa,
                                  selectedPeminatan,
                                  cleanEmail,
                                  cleanIg.isNotEmpty ? cleanIg : null,
                                  cleanLinkedin.isNotEmpty ? cleanLinkedin : null,
                                );

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
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(isSaving ? 'Menyimpan...' : 'Simpan Perubahan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(modalCtx),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
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
}
