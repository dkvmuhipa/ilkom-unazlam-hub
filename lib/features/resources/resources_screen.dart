import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _selectedType = 'Semua';
  final List<String> _types = ['Semua', 'Slide PPT', 'E-Book', 'Jurnal Ilmiah', 'Bank Soal'];

  Future<void> _openResource(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Slide PPT':
        return Icons.slideshow_outlined;
      case 'E-Book':
        return Icons.menu_book_outlined;
      case 'Jurnal Ilmiah':
        return Icons.article_outlined;
      case 'Bank Soal':
        return Icons.quiz_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == 'Semua'
        ? DummyData.resources
        : DummyData.resources.where((r) => r.jenis == _selectedType).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gudang Materi'),
      ),
      body: Column(
        children: [
          // Filter Jenis File (Clean Pills)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = type == _selectedType;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
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

          // List File
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book_outlined, size: 32, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Berkas Materi',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Slide PPT, diktat e-book, atau jurnal perkuliahan dari dosen akan dihimpun di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildMinimalResourceCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalResourceCard(ResourceItem item) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconForType(item.jenis), color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.pertemuanKe != null
                      ? '${item.courseName} • Pertemuan ${item.pertemuanKe}'
                      : item.courseName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_outward_rounded, size: 18, color: AppColors.primary),
            tooltip: 'Buka Dokumen',
            onPressed: () => _openResource(item.linkUrl),
          ),
        ],
      ),
    );
  }
}
