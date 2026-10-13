import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class ChangePasswordDialog {
  static Future<void> show(
    BuildContext context, {
    required String? userNim,
  }) async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    bool obscurePass = true;
    bool obscureConfirm = true;
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF1E40AF), size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ubah Kata Sandi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan kata sandi baru untuk akun Anda. Sandi ini akan langsung disinkronkan ke Supabase Auth.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmationController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Ulangi Kata Sandi Baru',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38384E) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  final p1 = passwordController.text;
                  final p2 = confirmationController.text;
                  if (p1.length < 6) {
                    setDialogState(() => errorText = 'Kata sandi minimal 6 karakter.');
                    return;
                  }
                  if (p1 != p2) {
                    setDialogState(() => errorText = 'Konfirmasi kata sandi tidak cocok.');
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Simpan & Sinkronkan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService.setPassword(
          passwordController.text,
          userNim: userNim,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Kata sandi berhasil diperbarui dan disinkronkan ke Supabase Auth! 🎉'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is AuthServiceException ? e.message : 'Kata sandi gagal diubah. Coba lagi.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
    passwordController.dispose();
    confirmationController.dispose();
  }
}
