import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/saas_components.dart';
import '../../models/models.dart';

class EditStudentAccountDialog extends StatefulWidget {
  final StudentProfile account;

  const EditStudentAccountDialog({super.key, required this.account});

  @override
  State<EditStudentAccountDialog> createState() =>
      _EditStudentAccountDialogState();
}

class _EditStudentAccountDialogState extends State<EditStudentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _namaController;
  late final TextEditingController _noWaController;
  late final TextEditingController _peminatanController;
  late final TextEditingController _kelasController;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    final initialEmail = account.email.contains('@student.unazlam.ac.id') ? '' : account.email;
    _emailController = TextEditingController(text: initialEmail);
    _namaController = TextEditingController(text: account.nama);
    _noWaController = TextEditingController(text: account.noWa);
    _peminatanController = TextEditingController(text: account.peminatan);
    _kelasController = TextEditingController(text: account.kelas);
    _semester = account.semester.clamp(1, 8).toInt();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _namaController.dispose();
    _noWaController.dispose();
    _peminatanController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final account = widget.account;
    final rawEmail = _emailController.text.trim().toLowerCase();
    Navigator.of(context).pop(
      StudentProfile(
        id: account.id,
        nim: account.nim,
        nama: _namaController.text.trim(),
        email: rawEmail,
        noWa: _noWaController.text.trim(),
        peminatan: _peminatanController.text.trim(),
        prodi: account.prodi,
        semester: _semester,
        kelas: _kelasController.text.trim(),
        role: account.role,
        jabatan: account.jabatan,
        isAktif: account.isAktif,
        instagram: account.instagram,
        linkedin: account.linkedin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
              GlassModalHeader(
                title: 'Edit Profil Mahasiswa',
                subtitle: 'Perbarui data akademik dan kontak ${account.nama}',
                icon: Icons.edit_note_rounded,
                onClose: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NIM (Read Only)
                        SaaSInputField(
                          label: 'NIM Mahasiswa',
                          controller: TextEditingController(text: account.nim),
                          prefixIcon: Icons.badge_outlined,
                          enabled: false,
                          helperText: 'NIM menjadi identitas login permanen.',
                        ),
                        const SizedBox(height: 16),
                        // Email Akun (Editable by Admin)
                        SaaSInputField(
                          label: 'Email Akun Mahasiswa',
                          controller: _emailController,
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'nama@gmail.com',
                          helperText: 'Email pribadi aktif untuk aktivasi & pemulihan akun.',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null; // Boleh kosong jika mahasiswa belum aktivasi
                            }
                            final clean = value.trim().toLowerCase();
                            if (clean.endsWith('@student.unazlam.ac.id') || clean.contains('unazlam.ac.id')) {
                              return 'Domain @student.unazlam.ac.id belum tersedia. Gunakan email pribadi (Gmail/dll).';
                            }
                            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                            if (!emailRegex.hasMatch(clean)) {
                              return 'Format email tidak valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Nama Lengkap
                        SaaSInputField(
                          label: 'Nama Lengkap',
                          controller: _namaController,
                          prefixIcon: Icons.person_outline_rounded,
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Nama wajib diisi.'
                              : value.trim().length > 120
                                  ? 'Nama maksimal 120 karakter.'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        // Nomor WhatsApp
                        SaaSInputField(
                          label: 'Nomor WhatsApp',
                          controller: _noWaController,
                          prefixIcon: Icons.chat_bubble_outline_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (value) => (value?.trim().length ?? 0) > 32
                              ? 'Nomor maksimal 32 karakter.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Peminatan
                        SaaSInputField(
                          label: 'Peminatan',
                          controller: _peminatanController,
                          prefixIcon: Icons.auto_stories_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => (value?.trim().length ?? 0) > 80
                              ? 'Peminatan maksimal 80 karakter.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Semester Dropdown
                        Column(
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
                              items: List.generate(8, (index) => index + 1)
                                  .map(
                                    (semester) => DropdownMenuItem(
                                      value: semester,
                                      child: Text(
                                        'Semester $semester',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _semester = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Kelas
                        SaaSInputField(
                          label: 'Kelas',
                          controller: _kelasController,
                          prefixIcon: Icons.class_outlined,
                          isRequired: true,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Kelas wajib diisi.'
                              : value.trim().length > 80
                                  ? 'Kelas maksimal 80 karakter.'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Simpan Perubahan'),
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
