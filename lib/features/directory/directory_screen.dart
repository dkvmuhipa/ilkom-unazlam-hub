import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

class DirectoryScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  const DirectoryScreen({super.key, this.canManage = false, this.onBack});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Pengurus', 'Mahasiswa'
  List<StudentProfile> _students = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await SupabaseRepository.getClassDirectory();
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;
    final internationalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo $name, saya teman sekelas dari S1 Ilmu Komputer UNAZLAM...',
    );
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isOfficer(String jabatan) {
    final j = jabatan.toLowerCase();
    return j.contains('ketua') || j.contains('bendahara') || j.contains('sekretaris');
  }

  Color _getAvatarBg(int index, String jabatan) {
    final j = jabatan.toLowerCase();
    if (j.contains('ketua')) return const Color(0xFFFEF3C7);
    if (j.contains('bendahara')) return const Color(0xFFDCFCE7);
    if (j.contains('sekretaris')) return const Color(0xFFEDE9FE);

    // Palet warna modern & elegan senada UNAZLAM
    const colors = [
      Color(0xFFEEF2FF), // Indigo tint
      Color(0xFFF0FDF4), // Emerald tint
      Color(0xFFF5F3FF), // Purple tint
      Color(0xFFF0F9FF), // Sky tint
      Color(0xFFF8FAFC), // Slate tint
    ];
    return colors[index % colors.length];
  }

  Color _getAvatarTextColor(int index, String jabatan) {
    final j = jabatan.toLowerCase();
    if (j.contains('ketua')) return const Color(0xFFB45309);
    if (j.contains('bendahara')) return const Color(0xFF16A34A);
    if (j.contains('sekretaris')) return const Color(0xFF7C3AED);

    const colors = [
      Color(0xFF4F46E5), // Indigo
      Color(0xFF059669), // Emerald
      Color(0xFF7C3AED), // Purple
      Color(0xFF0284C7), // Sky
      Color(0xFF475569), // Slate
    ];
    return colors[index % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'M';
  }

  @override
  Widget build(BuildContext context) {
    final nonAdminStudents = _students.where((s) => s.role != 'ADMIN').toList();

    final filtered = nonAdminStudents.where((s) {
      final matchesSearch = s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nim.contains(_searchQuery);
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Pengurus') {
        return _isOfficer(s.jabatan);
      } else if (_selectedFilter == 'Mahasiswa') {
        return !_isOfficer(s.jabatan);
      }
      return true;
    }).toList();

    final officerCount = nonAdminStudents.where((s) => _isOfficer(s.jabatan)).length;
    final regularCount = nonAdminStudents.length - officerCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Direktori Mahasiswa',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF5B3DE8)),
                const SizedBox(width: 5),
                Text(
                  '${nonAdminStudents.length} Mahasiswa',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B3DE8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar + Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NIM mahasiswa...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip('Semua', nonAdminStudents.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pengurus', officerCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Mahasiswa', regularCount),
                  ],
                ),
              ],
            ),
          ),

          // Divider Tipis
          Container(height: 1, color: const Color(0xFFE2E8F0)),

          // Student List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B3DE8)),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ditemukan "$_searchQuery"'
                                  : 'Belum ada data mahasiswa',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Coba gunakan kata kunci nama atau NIM yang lain.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          final initials = _getInitials(s.nama);
                          final avatarBg = _getAvatarBg(index, s.jabatan);
                          final avatarTextColor = _getAvatarTextColor(index, s.jabatan);
                          final isOfficer = _isOfficer(s.jabatan);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOfficer
                                    ? const Color(0xFFC7D2FE)
                                    : const Color(0xFFE2E8F0),
                              ),
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
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => _showStudentDetailModal(s, initials, avatarBg, avatarTextColor),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Avatar Inisial
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: avatarBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isOfficer ? avatarTextColor.withValues(alpha: 0.4) : Colors.transparent,
                                            width: 1.5,
                                          ),
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
                                      const SizedBox(width: 12),

                                      // Info Mahasiswa
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.nama,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            // Subtitle: Jika pengurus -> Badge Chip Pengurus; Jika mahasiswa biasa -> Satu warna seragam netral
                                            if (isOfficer)
                                              _buildOfficerBadge(s.jabatan)
                                            else
                                              const Text(
                                                'Mahasiswa ILKOM 2026',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B), // SERAGAM SATU WARNA
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Aksi WhatsApp Cepat (Jika nomor tersedia)
                                      if (s.noWa.isNotEmpty) ...[
                                        IconButton(
                                          onPressed: () => _openWhatsApp(s.noWa, s.nama),
                                          icon: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 19,
                                            color: Color(0xFF10B981),
                                          ),
                                          tooltip: 'WhatsApp ${s.nama.split(' ').first}',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                        const SizedBox(width: 4),
                                      ],

                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerBadge(String jabatan) {
    final j = jabatan.toLowerCase();
    Color bg = const Color(0xFFEDE9FE);
    Color textColor = const Color(0xFF7C3AED);

    if (j.contains('ketua')) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
    } else if (j.contains('bendahara')) {
      bg = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
    } else if (j.contains('sekretaris')) {
      bg = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF7C3AED);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$jabatan • Pengurus',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailModal(
    StudentProfile s,
    String initials,
    Color avatarBg,
    Color avatarTextColor,
  ) {
    final isOfficer = _isOfficer(s.jabatan);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar Besar
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOfficer ? avatarTextColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: avatarTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nama Mahasiswa
            Text(
              s.nama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle / Badge
            if (isOfficer)
              _buildOfficerBadge(s.jabatan)
            else
              const Text(
                'Mahasiswa ILKOM 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            const SizedBox(height: 18),

            // Detail Cards (NIM & Kontak)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF5B3DE8)),
                      const SizedBox(width: 10),
                      const Text(
                        'NIM',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      SelectableText(
                        s.nim,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (s.noWa.isNotEmpty) ...[
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        const Text(
                          'WhatsApp',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        SelectableText(
                          s.noWa,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Hubungi via WhatsApp
            if (s.noWa.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openWhatsApp(s.noWa, s.nama);
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Chat via WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            // Tombol Kelola Anggota (Bagi yang berwenang)
            if (widget.canManage) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showManageMemberDialog(s);
                  },
                  icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                  label: const Text(
                    'Kelola Jabatan & Info Anggota',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B3DE8),
                    side: const BorderSide(color: Color(0xFF5B3DE8)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showManageMemberDialog(StudentProfile s) {
    String selectedJabatan = s.jabatan;
    final phoneController = TextEditingController(text: s.noWa);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Kelola Anggota: ${s.nama.split(' ').first}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIM: ${s.nim}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedJabatan,
                decoration: InputDecoration(
                  labelText: 'Jabatan Pengurus',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'Ketua Kelas', child: Text('Ketua Kelas')),
                  DropdownMenuItem(value: 'Wakil Ketua', child: Text('Wakil Ketua')),
                  DropdownMenuItem(value: 'Bendahara', child: Text('Bendahara')),
                  DropdownMenuItem(value: 'Sekretaris', child: Text('Sekretaris')),
                  DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedJabatan = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  hintText: '0812xxxxxxxx',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  s.jabatan = selectedJabatan;
                });
                await SupabaseRepository.updateStudentJabatan(
                  s.nim,
                  selectedJabatan,
                );
                await _loadStudents();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data ${s.nama} berhasil diperbarui!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
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
}
