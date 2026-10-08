import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../models/models.dart';

class InviteAcceptScreen extends StatefulWidget {
  final String flowType;
  final ValueChanged<StudentProfile> onSuccess;
  final String? initialError;

  const InviteAcceptScreen({
    super.key,
    required this.flowType,
    required this.onSuccess,
    this.initialError,
  });

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = 'Gunakan kata sandi minimal 8 karakter.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Konfirmasi kata sandi belum sama.');
      return;
    }
    if (!AuthService.hasActiveSession) {
      setState(
        () => _error = 'Sesi undangan tidak ditemukan. Tautan mungkin sudah kedaluwarsa. Minta administrator mengirim tautan baru.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.setPassword(password);
      final profile = await AuthService.restoreSession();
      if (profile == null) {
        throw const AuthServiceException(
          'Kata sandi tersimpan, tetapi profil akun belum dapat dimuat. Silakan masuk kembali atau hubungi administrator.',
        );
      }
      if (!mounted) return;
      widget.onSuccess(profile);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AuthServiceException ? error.message : 'Kata sandi belum dapat disimpan. Periksa koneksi lalu coba kembali.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInvite = widget.flowType == 'invite';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF5B3DE8),
                        size: 46,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isInvite
                            ? 'Aktifkan akun mahasiswa'
                            : 'Atur ulang kata sandi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isInvite
                            ? 'Buat kata sandi untuk menyelesaikan undangan dan masuk ke portal ILKOM UNAZLAM.'
                            : 'Buat kata sandi baru untuk akun portal ILKOM UNAZLAM.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _passwordField(
                        controller: _passwordController,
                        label: 'Kata sandi baru',
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        controller: _confirmController,
                        label: 'Ulangi kata sandi',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B3DE8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                              : const Text(
                                  'Simpan dan lanjutkan',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}
