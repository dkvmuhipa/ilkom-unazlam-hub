import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Akademik', 'Dosen', 'Kelas'];
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    final data = await SupabaseRepository.getAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    }
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'Kelas';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Buat Pengumuman Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman',
                    hintText: 'Misal: Perubahan Ruang Kuliah',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ['Akademik', 'Dosen', 'Kelas']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Pengumuman',
                    hintText: 'Tuliskan informasi penting untuk seluruh mahasiswa...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await SupabaseRepository.createAnnouncement(
                  judul: titleController.text.trim(),
                  isi: contentController.text.trim(),
                  kategori: category,
                  isPinned: true,
                  authorName: 'Nur Farida (Ketua Kelas)',
                );
                _loadAnnouncements();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'Semua'
        ? _announcements
        : _announcements.where((a) {
            if (_selectedCategory == 'Akademik') return a.kategori.toLowerCase().contains('akademik') || a.kategori.toLowerCase().contains('fakultas');
            if (_selectedCategory == 'Dosen') return a.kategori.toLowerCase().contains('dosen') || a.kategori.toLowerCase().contains('jadwal');
            return a.kategori.toLowerCase().contains('kelas') || a.kategori.toLowerCase().contains('penting');
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Pengumuman',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF111827), size: 20),
            onPressed: _loadAnnouncements,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips matching Screen 9
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Announcements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada pengumuman di kategori ini.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAnnouncements,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final ann = filtered[index];
                            final isYellow = index % 2 == 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Badge
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isYellow ? const Color(0xFFFEF3C7) : const Color(0xFFF3F0FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isYellow ? Icons.campaign_rounded : Icons.description_outlined,
                                      color: isYellow ? const Color(0xFFB45309) : const Color(0xFF5B3DE8),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Announcement Body
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ann.judul,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ann.isi,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4B5563),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${ann.createdAt.day} ${_monthName(ann.createdAt.month)} ${ann.createdAt.year}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Oleh ${ann.authorName}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAnnouncementDialog,
        backgroundColor: const Color(0xFF5B3DE8),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _monthName(int month) {
    const m = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return m[month];
  }
}
