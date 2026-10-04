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

  @override
  Widget build(BuildContext context) {
    final filtered = DummyData.students.where((s) {
      return s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nim.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teman Sekelas'),
      ),
      body: Column(
        children: [
          // Search Input (Clean Minimalist)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NIM mahasiswa...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textLight),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSub),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
          ),

          // Total Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Mahasiswa Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length} Mahasiswa',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List Teman
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Tidak ada mahasiswa ditemukan.', style: TextStyle(color: AppColors.textSub)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return _buildMinimalStudentCard(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStudentCard(StudentProfile student) {
    final isKetua = student.role == 'ketua_kelas' || student.role == 'komti';
    final isBendahara = student.role == 'bendahara';

    Color avatarBg = AppColors.primarySoft;
    Color avatarText = AppColors.primary;
    if (isKetua) {
      avatarBg = AppColors.secondarySoft;
      avatarText = const Color(0xFFB45309);
    } else if (isBendahara) {
      avatarBg = const Color(0xFFDCFCE7);
      avatarText = const Color(0xFF15803D);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isKetua
              ? AppColors.secondary.withValues(alpha: 0.3)
              : isBendahara
                  ? const Color(0xFF86EFAC)
                  : AppColors.border,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarBg,
            child: Text(
              student.nama.isNotEmpty ? student.nama[0] : '?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: avatarText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (isKetua) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'KETUA KELAS',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ),
                    ] else if (isBendahara) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          'BENDAHARA',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'NIM: ${student.nim} • S1 Ilmu Komunikasi',
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openWhatsApp(student.noWa, student.nama),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }
}
