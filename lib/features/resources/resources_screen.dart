import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  const ResourcesScreen({super.key, this.canManage = true, this.onBack});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _selectedType = 'Semua';
  final List<String> _types = ['Semua', 'Slide PPT', 'E-Book', 'Jurnal Ilmiah', 'Bank Soal'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddResourceDialog() {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    final pertController = TextEditingController(text: '1');
    String selectedCourse = DummyData.courses.first.nama;
    String selectedJenis = 'Slide PPT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.post_add_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Tambah Materi Kuliah', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: DummyData.courses
                        .map((c) => DropdownMenuItem(
                              value: c.nama,
                              child: Text(c.nama, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourse = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Dokumen / Materi',
                      hintText: 'Misal: PPT Pertemuan 1 - Konsep Dasar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedJenis,
                          decoration: InputDecoration(
                            labelText: 'Jenis Materi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Slide PPT', 'E-Book', 'Jurnal Ilmiah', 'Bank Soal']
                              .map((j) => DropdownMenuItem(value: j, child: Text(j, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedJenis = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pertController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pertemuan Ke-',
                            hintText: '1',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Tautan Google Drive / Unduhan',
                      hintText: 'https://drive.google.com/...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                final judul = titleController.text.trim();
                final link = linkController.text.trim();
                if (judul.isEmpty) return;

                final pert = int.tryParse(pertController.text.trim()) ?? 1;

                setState(() {
                  DummyData.resources.insert(
                    0,
                    ResourceItem(
                      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
                      courseName: selectedCourse,
                      pertemuanKe: pert,
                      judul: judul,
                      jenis: selectedJenis,
                      linkUrl: link.isNotEmpty ? link : 'https://drive.google.com',
                    ),
                  );
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi kuliah baru berhasil ditambahkan! 📚'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan Materi'),
            ),
          ],
        ),
      ),
    );
  }

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
    final filtered = DummyData.resources.where((r) {
      if (_selectedType != 'Semua' && r.jenis != _selectedType) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return r.judul.toLowerCase().contains(q) ||
            r.courseName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Gudang Materi & E-Book',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (widget.canManage)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                tooltip: 'Tambah Materi',
                onPressed: _showAddResourceDialog,
              ),
            ),
        ],
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddResourceDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('Tambah Materi', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari modul, PPT, atau jurnal kuliah...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
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
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6B7280)),
            tooltip: 'Salin Tautan',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.linkUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan materi disalin ke clipboard! 📋'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_outward_rounded, size: 18, color: AppColors.primary),
            tooltip: 'Buka Dokumen',
            onPressed: () => _openResource(item.linkUrl),
          ),
          if (widget.canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
              tooltip: 'Hapus Materi',
              onPressed: () {
                setState(() {
                  DummyData.resources.removeWhere((r) => r.id == item.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Materi telah dihapus.'), duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
    );
  }
}
