import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';
import 'widgets/announcement_card.dart';
import 'widgets/announcement_detail_sheet.dart';
import 'widgets/announcement_filter_bar.dart';
import 'widgets/announcement_form_dialog.dart';
import 'widgets/announcement_headline_card.dart';

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
      builder: (ctx) => AnnouncementDetailSheet(
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
  String _searchQuery = '';
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _initRealtime();
  }

  void _initRealtime() {
    _realtimeChannel = SupabaseRepository.subscribeToAnnouncements(() {
      if (mounted) {
        _loadAnnouncements(silent: true);
      }
    });
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_realtimeChannel);
    super.dispose();
  }

  Future<void> _loadAnnouncements({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final data = await SupabaseRepository.getAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    }
  }

  Map<String, int> _computeCategoryCounts() {
    int disematkanCount = 0;
    int akademikCount = 0;
    int dosenCount = 0;
    int kelasCount = 0;

    for (final a in _announcements) {
      if (a.isPinned) disematkanCount++;
      final lower = a.kategori.toLowerCase();
      if (lower.contains('akademik') || lower.contains('fakultas')) {
        akademikCount++;
      } else if (lower.contains('dosen') || lower.contains('jadwal')) {
        dosenCount++;
      } else {
        kelasCount++;
      }
    }

    return {
      'Semua': _announcements.length,
      'Disematkan': disematkanCount,
      'Akademik': akademikCount,
      'Dosen': dosenCount,
      'Kelas': kelasCount,
    };
  }

  List<Announcement> _getFilteredAnnouncements() {
    return _announcements.where((a) {
      // 1. Category Filter
      bool matchesCategory = true;
      if (_selectedCategory == 'Disematkan') {
        matchesCategory = a.isPinned;
      } else if (_selectedCategory == 'Akademik') {
        matchesCategory = a.kategori.toLowerCase().contains('akademik') ||
            a.kategori.toLowerCase().contains('fakultas');
      } else if (_selectedCategory == 'Dosen') {
        matchesCategory = a.kategori.toLowerCase().contains('dosen') ||
            a.kategori.toLowerCase().contains('jadwal');
      } else if (_selectedCategory == 'Kelas') {
        matchesCategory = !a.kategori.toLowerCase().contains('akademik') &&
            !a.kategori.toLowerCase().contains('fakultas') &&
            !a.kategori.toLowerCase().contains('dosen') &&
            !a.kategori.toLowerCase().contains('jadwal');
      }

      if (!matchesCategory) return false;

      // 2. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesTitle = a.judul.toLowerCase().contains(q);
        final matchesContent = a.isi.toLowerCase().contains(q);
        final matchesAuthor = a.authorName.toLowerCase().contains(q);
        final matchesCategoryName = a.kategori.toLowerCase().contains(q);
        return matchesTitle || matchesContent || matchesAuthor || matchesCategoryName;
      }

      return true;
    }).toList();
  }

  void _openDetail(Announcement ann) {
    AnnouncementsScreen.showAnnouncementDetail(
      context,
      ann,
      onChanged: _loadAnnouncements,
      canManage: widget.canPost,
    );
  }

  void _openCreateDialog() {
    AnnouncementFormDialog.show(
      context,
      onSuccess: _loadAnnouncements,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredAnnouncements();
    final categoryCounts = _computeCategoryCounts();

    // Check if we have a top featured headline when viewing 'Semua' and no search
    final isDefaultFeed = _selectedCategory == 'Semua' && _searchQuery.trim().isEmpty;
    Announcement? headlineAnnouncement;
    List<Announcement> standardFeedList = filtered;

    if (isDefaultFeed && filtered.isNotEmpty) {
      // Find the first pinned announcement, or the very first announcement
      final pinnedIndex = filtered.indexWhere((a) => a.isPinned);
      if (pinnedIndex != -1) {
        headlineAnnouncement = filtered[pinnedIndex];
        standardFeedList = List<Announcement>.from(filtered)..removeAt(pinnedIndex);
      } else {
        headlineAnnouncement = filtered.first;
        standardFeedList = filtered.sublist(1);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                ),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warta & Pengumuman',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Kabar Resmi Civitas UNAZLAM',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF334155),
              size: 22,
            ),
            tooltip: 'Segarkan',
            onPressed: () => _loadAnnouncements(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Sticky Filter & Search Bar
          AnnouncementFilterBar(
            searchQuery: _searchQuery,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onClearSearch: () => setState(() => _searchQuery = ''),
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            categoryCounts: categoryCounts,
          ),

          // Main Feed Stream
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E3A8A),
                    ),
                  )
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadAnnouncements(silent: true),
                        color: const Color(0xFF1E3A8A),
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 90),
                          children: [
                            // 1. Featured Thesis Hero (if in default overview feed)
                            if (headlineAnnouncement != null) ...[
                              AnnouncementHeadlineCard(
                                announcement: headlineAnnouncement,
                                onTap: () => _openDetail(headlineAnnouncement!),
                              ),
                            ],

                            // 2. Section Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                              child: Row(
                                children: [
                                  Text(
                                    isDefaultFeed
                                        ? 'Warta Lainnya (${standardFeedList.length})'
                                        : 'Hasil Warta (${filtered.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_searchQuery.isNotEmpty)
                                    Text(
                                      '"$_searchQuery"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 3. Announcements List
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: standardFeedList.map((ann) {
                                  return AnnouncementCard(
                                    announcement: ann,
                                    onTap: () => _openDetail(ann),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.canPost
          ? FloatingActionButton.extended(
              onPressed: _openCreateDialog,
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Buat Warta',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 2,
                ),
              ),
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.notifications_none_rounded,
                size: 40,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'Warta Tidak Ditemukan' : 'Belum Ada Pengumuman',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Tidak ada pengumuman yang cocok dengan kata kunci "$_searchQuery". Coba cari dengan kata kunci lain.'
                  : 'Belum ada pengumuman yang diterbitkan untuk kategori $_selectedCategory.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (hasSearch)
              OutlinedButton.icon(
                onPressed: () => setState(() => _searchQuery = ''),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Hapus Pencarian'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else if (widget.canPost)
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Buat Pengumuman Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
