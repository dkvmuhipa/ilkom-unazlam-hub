import 'package:flutter/material.dart';

import '../../core/services/admin_account_service.dart';
import '../../models/models.dart';

class CreateStudentAccountDialog extends StatefulWidget {
  const CreateStudentAccountDialog({super.key});

  @override
  State<CreateStudentAccountDialog> createState() =>
      _CreateStudentAccountDialogState();
}

class _CreateStudentAccountDialogState
    extends State<CreateStudentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _noWaController = TextEditingController();
  final _peminatanController = TextEditingController();
  int _semester = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _noWaController.dispose();
    _peminatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await AdminAccountService.createStudentAccount(
        nama: _namaController.text,
        nim: _nimController.text,
        email: _emailController.text,
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
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Buat akun mahasiswa',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Undangan aktivasi akan dikirim ke email mahasiswa. Akun mendapat peran Mahasiswa.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _namaController,
                  label: 'Nama lengkap',
                  validator: (value) => _required(value, 'Nama'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _nimController,
                  label: 'NIM',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final requiredError = _required(value, 'NIM');
                    if (requiredError != null) return requiredError;
                    if (!RegExp(r'^\d{6,20}$').hasMatch(value!.trim())) {
                      return 'Masukkan NIM berupa 6–20 angka.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _emailController,
                  label: 'Email mahasiswa',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email wajib diisi.';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email)) {
                      return 'Format email belum benar.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _noWaController,
                  label: 'Nomor WhatsApp (opsional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _semester,
                  decoration: _inputDecoration('Semester'),
                  items: List.generate(8, (index) => index + 1)
                      .map((semester) => DropdownMenuItem(
                            value: semester,
                            child: Text('Semester $semester'),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _semester = value);
                        },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _peminatanController,
                  label: 'Peminatan (opsional)',
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.mail_outline_rounded, size: 18),
          label: Text(_isSubmitting ? 'Mengirim…' : 'Buat & kirim undangan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B3DE8),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      );

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label wajib diisi.' : null;
}
