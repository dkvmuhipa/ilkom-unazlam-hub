import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _searchQuery = '';

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent('Halo $name, saya teman sekelas dari S1 Ilmu Komunikasi UNAZLAM...');
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getAvatarBg(int index, String jabatan) {
    if (jabatan == 'Ketua Kelas') return const Color(0xFFFEF3C7);
    if (jabatan.contains('Bendahara')) return const Color(0xFFDCFCE7);
    if (jabatan == 'Sekretaris') return const Color(0xFFEDE9FE);
    final colors = [
      const Color(0xFFF3F0FF),
      const Color(0xFFE0F2FE),
      const Color(0xFFFEE2E2),
      const Color(0xFFECFDF5),
      const Color(0xFFFFFBEB),
      const Color(0xFFFCE7F3),
    ];
    return colors[index % colors.length];
  }

  Color _getAvatarTextColor(int index, String jabatan) {
    if (jabatan == 'Ketua Kelas') return const Color(0xFFB45309);
    if (jabatan.contains('Bendahara')) return const Color(0xFF16A34A);
    if (jabatan == 'Sekretaris') return const Color(0xFF6D28D9);
    final colors = [
      const Color(0xFF5B3DE8),
      const Color(0xFF0284C7),
      const Color(0xFFDC2626),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
    ];
    return colors[index % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatRole(String jabatan) {
    if (jabatan != 'Mahasiswa') return '$jabatan • Pengurus';
    return 'Mahasiswa ILKOM 2026';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = DummyData.students.where((s) {
      if (s.role == 'ADMIN') return false;
      return s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nim.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Anggota Kelas',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar matching Screen 7
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NIM...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Student List matching Screen 7
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final s = filtered[index];
                final initials = _getInitials(s.nama);
                final avatarBg = _getAvatarBg(index, s.jabatan);
                final avatarTextColor = _getAvatarTextColor(index, s.jabatan);
                final roleLabel = _formatRole(s.jabatan);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: avatarBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: avatarTextColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        s.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: s.role != 'mahasiswa' ? FontWeight.w700 : FontWeight.w500,
                          color: s.role != 'mahasiswa' ? avatarTextColor : const Color(0xFF6B7280),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      onTap: () {
                        _showStudentDetailModal(s, initials, avatarBg, avatarTextColor, roleLabel);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailModal(StudentProfile s, String initials, Color avatarBg, Color avatarTextColor, String roleLabel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: avatarTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.nama,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                'NIM: ${s.nim} • $roleLabel',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              if (s.noWa.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(s.noWa, s.nama),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Hubungi via WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
