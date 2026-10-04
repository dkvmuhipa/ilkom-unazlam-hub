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
  String _selectedPeminatan = 'Semua';
  final List<String> _peminatanList = [
    'Semua',
    'Broadcasting',
    'Public Relations',
    'Jurnalistik',
    'Advertising',
  ];

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
      final matchesQuery = s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nim.contains(_searchQuery) ||
          s.peminatan.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPeminatan = _selectedPeminatan == 'Semua' || s.peminatan == _selectedPeminatan;
      return matchesQuery && matchesPeminatan;
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama, NIM, atau peminatan...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textLight),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSub),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
          ),

          // Filter Peminatan (Pill Chips)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _peminatanList.length,
              itemBuilder: (context, index) {
                final pem = _peminatanList[index];
                final isSelected = pem == _selectedPeminatan;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPeminatan = pem),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        pem,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
    final isKomti = student.role == 'komti';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isKomti ? AppColors.secondarySoft : AppColors.primarySoft,
            child: Text(
              student.nama.isNotEmpty ? student.nama[0] : '?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isKomti ? const Color(0xFFB45309) : AppColors.primary,
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
                    if (isKomti) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'KOMTI',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.nim} • ${student.peminatan}',
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
