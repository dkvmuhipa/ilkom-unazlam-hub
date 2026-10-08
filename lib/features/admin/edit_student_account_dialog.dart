import 'package:flutter/material.dart';

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
  late final TextEditingController _namaController;
  late final TextEditingController _noWaController;
  late final TextEditingController _peminatanController;
  late final TextEditingController _kelasController;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _namaController = TextEditingController(text: account.nama);
    _noWaController = TextEditingController(text: account.noWa);
    _peminatanController = TextEditingController(text: account.peminatan);
    _kelasController = TextEditingController(text: account.kelas);
    _semester = account.semester.clamp(1, 8).toInt();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noWaController.dispose();
    _peminatanController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final account = widget.account;
    Navigator.of(context).pop(
      StudentProfile(
        id: account.id,
        nim: account.nim,
        nama: _namaController.text.trim(),
        email: account.email,
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
    return AlertDialog(
      title: const Text('Edit akun mahasiswa'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: account.nim,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'NIM',
                    helperText: 'NIM menjadi identitas login dan tidak dapat diubah di sini.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: account.email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email akun',
                    helperText: 'Email login dan pemulihan tidak diubah dari formulir ini.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi.'
                      : value.trim().length > 120
                      ? 'Nama maksimal 120 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noWaController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) > 32
                      ? 'Nomor maksimal 32 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _peminatanController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Peminatan'),
                  validator: (value) => (value?.trim().length ?? 0) > 80
                      ? 'Peminatan maksimal 80 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: List.generate(8, (index) => index + 1)
                      .map(
                        (semester) => DropdownMenuItem(
                          value: semester,
                          child: Text('Semester $semester'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _semester = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kelasController,
                  decoration: const InputDecoration(labelText: 'Kelas'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Simpan perubahan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B3DE8),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
