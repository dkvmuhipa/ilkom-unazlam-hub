import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/safe_launcher.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class ProfileContactSection extends StatelessWidget {
  final StudentProfile student;
  final bool isDark;
  final VoidCallback onEditContact;

  const ProfileContactSection({
    super.key,
    required this.student,
    required this.isDark,
    required this.onEditContact,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('$label "$text" berhasil disalin! 📋'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    String phone,
    String name,
  ) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo $name, saya ingin berkomunikasi mengenai perkuliahan ILKOM UNAZLAM.',
    );
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final opened = await safeLaunchUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak dapat dibuka. Periksa nomor dan aplikasi Anda.',
          ),
        ),
      );
    }
  }

  Future<void> _openInstagram(String handle) async {
    final cleanHandle = handle.replaceAll('@', '').trim();
    if (cleanHandle.isEmpty) return;
    final url = 'https://instagram.com/$cleanHandle';
    await safeLaunchUrl(url);
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    final url = 'mailto:$cleanEmail';
    final opened = await safeLaunchUrl(url);
    if (!opened && context.mounted) {
      _copyToClipboard(context, cleanEmail, 'Email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E2E3E)
        : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark
        ? const Color(0xFF2A2A3C)
        : const Color(0xFFF3F4F6);

    final hasEmail = student.email.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.contact_mail_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Kontak & Komunikasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ScaleButton(
                onTap: onEditContact,
                scaleDown: 0.94,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF059669),
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ubah Kontak',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
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
          _buildRow(
            icon: Icons.alternate_email_rounded,
            iconColor: const Color(0xFF2563EB),
            label: 'Email Mahasiswa',
            value: hasEmail ? student.email.trim() : 'Belum diatur',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            actionIcon: Icons.email_outlined,
            actionTooltip: 'Kirim Email',
            onAction: hasEmail
                ? () => _openEmail(context, student.email.trim())
                : null,
            onTap: hasEmail
                ? () => _copyToClipboard(context, student.email.trim(), 'Email')
                : null,
          ),
          Divider(height: 22, color: dividerColor),

          // WhatsApp
          _buildRow(
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF10B981),
            label: 'Nomor WhatsApp',
            value: student.noWa.isNotEmpty ? student.noWa : 'Belum diatur',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            actionIcon: Icons.chat_rounded,
            actionTooltip: 'Chat WhatsApp',
            onAction: student.noWa.isNotEmpty
                ? () => _openWhatsApp(context, student.noWa, student.nama)
                : null,
            onTap: student.noWa.isNotEmpty
                ? () => _copyToClipboard(context, student.noWa, 'Nomor WA')
                : null,
          ),

          // Instagram jika ada
          if (student.instagram != null && student.instagram!.isNotEmpty) ...[
            Divider(height: 22, color: dividerColor),
            _buildRow(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFE11D48),
              label: 'Instagram',
              value: student.instagram!.startsWith('@')
                  ? student.instagram!
                  : '@${student.instagram!}',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              actionIcon: Icons.open_in_new_rounded,
              actionTooltip: 'Buka Instagram',
              onAction: () => _openInstagram(student.instagram!),
              onTap: () => _openInstagram(student.instagram!),
            ),
          ],

          // LinkedIn jika ada
          if (student.linkedin != null && student.linkedin!.isNotEmpty) ...[
            Divider(height: 22, color: dividerColor),
            _buildRow(
              icon: Icons.work_outline_rounded,
              iconColor: const Color(0xFF0284C7),
              label: 'LinkedIn Profile',
              value: student.linkedin!,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              actionIcon: Icons.open_in_new_rounded,
              actionTooltip: 'Buka LinkedIn',
              onAction: () => safeLaunchUrl(student.linkedin!),
              onTap: () =>
                  _copyToClipboard(context, student.linkedin!, 'LinkedIn'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    IconData? actionIcon,
    String? actionTooltip,
    VoidCallback? onAction,
    VoidCallback? onTap,
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
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onAction != null && actionIcon != null)
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
}
