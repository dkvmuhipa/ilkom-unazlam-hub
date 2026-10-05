import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

class AnnouncementsScreen extends StatefulWidget {
  final bool canPost;
  final VoidCallback? onBack;

  const AnnouncementsScreen({
    super.key,
    this.canPost = true,
    this.onBack,
  });

  static void showAnnouncementDetail(
    BuildContext context,
    Announcement announcement, {
    VoidCallback? onChanged,
    bool canManage = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementDetailSheet(
        announcement: announcement,
        onChanged: onChanged,
        canManage: canManage,
      ),
    );
  }

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
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
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

                            return InkWell(
                              onTap: () => AnnouncementsScreen.showAnnouncementDetail(
                                context,
                                ann,
                                onChanged: _loadAnnouncements,
                                canManage: widget.canPost,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4B5563),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Text(
                                                '${ann.createdAt.day} ${_monthName(ann.createdAt.month)} ${ann.createdAt.year}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9CA3AF),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Oleh ${ann.authorName}',
                                                  textAlign: TextAlign.end,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.canPost
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              tooltip: 'Buat Pengumuman',
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  String _monthName(int month) {
    const m = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return m[month];
  }
}

class _AnnouncementDetailSheet extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onChanged;
  final bool canManage;

  const _AnnouncementDetailSheet({
    required this.announcement,
    this.onChanged,
    this.canManage = false,
  });

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: announcement.judul);
    final contentController = TextEditingController(text: announcement.isi);
    String category = announcement.kategori;
    bool isPinned = announcement.isPinned;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Pengumuman', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Pengumuman'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: ['Akademik', 'Dosen', 'Kelas'].contains(category) ? category : 'Kelas',
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ['Akademik', 'Dosen', 'Kelas']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Sematkan di atas (Penting)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: isPinned,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPinned = val ?? false),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Isi Pengumuman'),
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
              onPressed: () {
                final judul = titleController.text.trim();
                final isi = contentController.text.trim();
                if (judul.isEmpty) return;

                announcement.judul = judul;
                announcement.isi = isi;
                announcement.kategori = category;
                announcement.isPinned = isPinned;
                SupabaseRepository.updateAnnouncement(announcement);

                Navigator.pop(ctx);
                Navigator.pop(context);
                onChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengumuman berhasil diperbarui!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengumuman?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Hapus pengumuman "${announcement.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              nav.pop();
              await SupabaseRepository.deleteAnnouncement(announcement.id);
              onChanged?.call();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Pengumuman berhasil dihapus.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final text = '📢 *PENGUMUMAN ILKOM UNAZLAM*\n\n*${announcement.judul}*\n\n${announcement.isi}\n\n_Diposting oleh: ${announcement.authorName} (${announcement.authorRole})_';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _categoryColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('penting')) return const Color(0xFFEF4444);
    if (lower.contains('akademik')) return const Color(0xFF0284C7);
    if (lower.contains('dosen')) return const Color(0xFF8B5CF6);
    return const Color(0xFFF59E0B);
  }

  Color _categoryBg(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('penting')) return const Color(0xFFFEE2E2);
    if (lower.contains('akademik')) return const Color(0xFFE0F2FE);
    if (lower.contains('dosen')) return const Color(0xFFEDE9FE);
    return const Color(0xFFFEF3C7);
  }

  String _monthName(int month) {
    const m = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return m[month];
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(announcement.kategori);
    final catBg = _categoryBg(announcement.kategori);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        announcement.kategori,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                    ),
                    if (announcement.isPinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Disematkan',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (canManage) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF5B3DE8), size: 20),
                        tooltip: 'Edit Pengumuman',
                        onPressed: () => _showEditDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        tooltip: 'Hapus Pengumuman',
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    announcement.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author info card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.15),
                          child: Text(
                            announcement.authorName.isNotEmpty ? announcement.authorName[0] : 'U',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.authorName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${announcement.authorRole} • ${announcement.createdAt.day} ${_monthName(announcement.createdAt.month)} ${announcement.createdAt.year}, ${announcement.createdAt.hour.toString().padLeft(2, '0')}:${announcement.createdAt.minute.toString().padLeft(2, '0')} WITA',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Announcement Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: SelectableText(
                      announcement.isi,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF374151),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Copy Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${announcement.judul}\n\n${announcement.isi}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Teks pengumuman berhasil disalin!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Salin Isi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share to WA
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareToWhatsApp(context),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Bagikan WA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
