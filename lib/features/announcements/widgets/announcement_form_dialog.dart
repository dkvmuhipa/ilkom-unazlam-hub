import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';

class AnnouncementFormDialog extends StatefulWidget {
  final Announcement? existingAnnouncement;
  final StudentProfile? currentUser;
  final VoidCallback onSuccess;

  const AnnouncementFormDialog({
    super.key,
    this.existingAnnouncement,
    this.currentUser,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    Announcement? existingAnnouncement,
    StudentProfile? currentUser,
    required VoidCallback onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AnnouncementFormDialog(
        existingAnnouncement: existingAnnouncement,
        currentUser: currentUser,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _authorNameController;
  late final TextEditingController _authorRoleController;
  late String _category;
  late bool _isPinned;
  bool _isSubmitting = false;

  final List<String> _categoryOptions = [
    'Kelas',
    'Akademik',
    'Dosen',
    'Penting',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingAnnouncement;
    final user = widget.currentUser;

    _titleController = TextEditingController(text: item?.judul ?? '');
    _contentController = TextEditingController(text: item?.isi ?? '');

    // Resolusi nama & peran penerbit yang cerdas dan dinamis
    String initialAuthorName;
    String initialAuthorRole;

    if (item != null) {
      initialAuthorName = item.authorName;
      initialAuthorRole = item.authorRole;
    } else if (user != null) {
      if (user.isAdmin) {
        initialAuthorName = 'Admin Program Studi';
        initialAuthorRole = 'Admin';
      } else if (user.isKetuaKelas) {
        initialAuthorName = '${user.nama} (Ketua Kelas)';
        initialAuthorRole = 'Ketua Kelas';
      } else if (user.isSekretaris) {
        initialAuthorName = '${user.nama} (Sekretaris)';
        initialAuthorRole = 'Sekretaris';
      } else {
        initialAuthorName = user.nama;
        initialAuthorRole = user.jabatan.isNotEmpty ? user.jabatan : 'Pengurus Kelas';
      }
    } else {
      initialAuthorName = 'Pengurus Kelas';
      initialAuthorRole = 'Pengurus';
    }

    _authorNameController = TextEditingController(text: initialAuthorName);
    _authorRoleController = TextEditingController(text: initialAuthorRole);

    _category = item?.kategori ?? 'Kelas';
    if (!_categoryOptions.contains(_category)) {
      _category = 'Kelas';
    }
    _isPinned = item?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorNameController.dispose();
    _authorRoleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final authorName = _authorNameController.text.trim().isNotEmpty
        ? _authorNameController.text.trim()
        : (widget.currentUser?.nama ?? 'Admin / Pengurus');
    final authorRole = _authorRoleController.text.trim().isNotEmpty
        ? _authorRoleController.text.trim()
        : 'Pengurus Kelas';

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul pengumuman tidak boleh kosong.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi pengumuman tidak boleh kosong.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final isEdit = widget.existingAnnouncement != null;
    bool success = false;

    if (isEdit) {
      final ann = widget.existingAnnouncement!;
      final oldJudul = ann.judul;
      final oldIsi = ann.isi;
      final oldCat = ann.kategori;
      final oldPin = ann.isPinned;
      final oldAuthorName = ann.authorName;
      final oldAuthorRole = ann.authorRole;

      ann.judul = title;
      ann.isi = content;
      ann.kategori = _category;
      ann.isPinned = _isPinned;
      ann.authorName = authorName;
      ann.authorRole = authorRole;

      success = await SupabaseRepository.updateAnnouncement(ann);
      if (!success) {
        ann.judul = oldJudul;
        ann.isi = oldIsi;
        ann.kategori = oldCat;
        ann.isPinned = oldPin;
        ann.authorName = oldAuthorName;
        ann.authorRole = oldAuthorRole;
      }
    } else {
      success = await SupabaseRepository.createAnnouncement(
        judul: title,
        isi: content,
        kategori: _category,
        isPinned: _isPinned,
        authorName: authorName,
        authorRole: authorRole,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Pengumuman berhasil diperbarui!'
                : 'Pengumuman baru berhasil diterbitkan!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan pengumuman ke database server.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAnnouncement != null;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.campaign_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Perbarui Pengumuman' : 'Buat Pengumuman Baru',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEdit
                                ? 'Sesuaikan informasi pengumuman kelas'
                                : 'Publikasikan warta penting untuk mahasiswa',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 18),

                // Judul
                const Text(
                  'Judul Pengumuman *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Misal: Perubahan Ruang Kuliah Pengantar Komunikasi',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Identitas Penerbit (Author) Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 8),
                          const Text(
                            'Identitas Penerbit Warta *',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Bisa disesuaikan',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextField(
                              controller: _authorNameController,
                              decoration: InputDecoration(
                                labelText: 'Nama Penerbit',
                                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: _authorRoleController,
                              decoration: InputDecoration(
                                labelText: 'Peran / Jabatan',
                                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick Preset Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (widget.currentUser != null)
                            _buildAuthorPresetChip(
                              label: 'Saya (${widget.currentUser!.nama.split(" ").first})',
                              name: widget.currentUser!.nama,
                              role: widget.currentUser!.jabatan.isNotEmpty
                                  ? widget.currentUser!.jabatan
                                  : (widget.currentUser!.isAdmin ? 'Admin' : 'Mahasiswa'),
                            ),
                          _buildAuthorPresetChip(
                            label: 'Admin Prodi',
                            name: 'Admin Program Studi',
                            role: 'Admin',
                          ),
                          _buildAuthorPresetChip(
                            label: 'Ketua Kelas',
                            name: widget.currentUser?.isKetuaKelas == true
                                ? '${widget.currentUser!.nama} (Ketua Kelas)'
                                : 'Ketua Kelas',
                            role: 'Ketua Kelas',
                          ),
                          _buildAuthorPresetChip(
                            label: 'Dosen Pengampu',
                            name: 'Dosen Pengampu',
                            role: 'Dosen',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori Selector
                const Text(
                  'Kategori Pengumuman *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryOptions.map((cat) {
                    final isSelected = cat == _category;
                    return InkWell(
                      onTap: () => setState(() => _category = cat),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Pinned Switch Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _isPinned ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: _isPinned ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sematkan di Atas (Warta Utama)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tampilkan sebagai headline prioritas',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPinned,
                        activeThumbColor: const Color(0xFFDC2626),
                        activeTrackColor: const Color(0xFFFECACA),
                        onChanged: (val) => setState(() => _isPinned = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Isi Pengumuman
                const Text(
                  'Isi Lengkap Pengumuman *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan detail rincian pengumuman, instruksi, lokasi, atau arahan perkuliahan...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Simpan Perubahan' : 'Terbitkan Sekarang',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorPresetChip({
    required String label,
    required String name,
    required String role,
  }) {
    final isActive = _authorNameController.text == name && _authorRoleController.text == role;
    return InkWell(
      onTap: () {
        setState(() {
          _authorNameController.text = name;
          _authorRoleController.text = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF1E40AF) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
