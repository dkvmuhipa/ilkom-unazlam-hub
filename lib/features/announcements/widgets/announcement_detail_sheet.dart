import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/supabase_repository.dart';
import '../../../core/services/safe_launcher.dart';
import '../../../models/models.dart';
import 'announcement_form_dialog.dart';
import 'announcement_helper.dart';

class AnnouncementDetailSheet extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onChanged;
  final bool canManage;
  final StudentProfile? currentUser;

  const AnnouncementDetailSheet({
    super.key,
    required this.announcement,
    this.onChanged,
    this.canManage = false,
    this.currentUser,
  });

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final formattedDate = AnnouncementHelper.formatFullDate(
      announcement.createdAt,
    );
    final text =
        '📢 *PENGUMUMAN ILKOM UNAZLAM*\n\n'
        '*${announcement.judul}*\n\n'
        '${announcement.isi}\n\n'
        '🗓️ _Diposting: ${formattedDate}_\n'
        '👤 _Oleh: ${announcement.authorName} (${announcement.authorRole})_';

    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final opened = await safeLaunchUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak dapat dibuka. Salin teks pengumuman lalu kirim secara manual.',
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Pengumuman?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengumuman "${announcement.judul}"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final saved = await SupabaseRepository.deleteAnnouncement(
                announcement.id,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!saved) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus pengumuman dari server.'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
                return;
              }
              if (nav.mounted) nav.pop();
              onChanged?.call();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Pengumuman telah berhasil dihapus.'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = AnnouncementHelper.getCategoryStyle(announcement.kategori);
    final fullDate = AnnouncementHelper.formatFullDate(announcement.createdAt);
    final readTime = AnnouncementHelper.estimateReadingTime(announcement.isi);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category & Pinned Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: style.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: style.borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 12, color: style.primaryColor),
                          const SizedBox(width: 5),
                          Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: style.primaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (announcement.isPinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 12,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Disematkan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Management Actions & Close Button
                Row(
                  children: [
                    if (canManage) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                        tooltip: 'Edit Pengumuman',
                        onPressed: () {
                          AnnouncementFormDialog.show(
                            context,
                            existingAnnouncement: announcement,
                            currentUser: currentUser,
                            onSuccess: () {
                              Navigator.pop(context);
                              onChanged?.call();
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        tooltip: 'Hapus Pengumuman',
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Reading Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    announcement.judul,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Author Byline Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: style.backgroundColor,
                          child: Text(
                            announcement.authorName.isNotEmpty
                                ? announcement.authorName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: style.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.authorName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${announcement.authorRole} • $readTime',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Timestamp Row
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fullDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Full Announcement Article Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SelectableText(
                      announcement.isi,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.65,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons: Copy & WhatsApp
                  Row(
                    children: [
                      // Copy Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${announcement.judul}\n\n${announcement.isi}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Teks pengumuman berhasil disalin ke clipboard!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text(
                            'Salin Teks',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // WhatsApp Share Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareToWhatsApp(context),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text(
                            'Bagikan WA',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
