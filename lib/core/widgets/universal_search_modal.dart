import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class UniversalSearchModal extends StatefulWidget {
  final Function(int) onNavigateTab;

  const UniversalSearchModal({super.key, required this.onNavigateTab});

  static void show(BuildContext context, {required Function(int) onNavigateTab}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalSearchModal(onNavigateTab: onNavigateTab),
    );
  }

  @override
  State<UniversalSearchModal> createState() => _UniversalSearchModalState();
}

class _UniversalSearchModalState extends State<UniversalSearchModal> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final q = _query.toLowerCase().trim();

    // 1. Filter Courses
    final matchedCourses = q.isEmpty
        ? <Course>[]
        : DummyData.courses
            .where((c) =>
                c.nama.toLowerCase().contains(q) ||
                c.dosen.toLowerCase().contains(q) ||
                c.hari.toLowerCase().contains(q))
            .toList();

    // 2. Filter Resources
    final matchedResources = q.isEmpty
        ? <ResourceItem>[]
        : DummyData.resources
            .where((r) =>
                r.judul.toLowerCase().contains(q) ||
                r.courseName.toLowerCase().contains(q) ||
                r.jenis.toLowerCase().contains(q))
            .toList();

    // 3. Filter Assignments
    final matchedAssignments = q.isEmpty
        ? <Assignment>[]
        : DummyData.assignments
            .where((a) =>
                a.judul.toLowerCase().contains(q) ||
                a.courseName.toLowerCase().contains(q))
            .toList();

    // 4. Filter Students
    final matchedStudents = q.isEmpty
        ? <StudentProfile>[]
        : DummyData.students
            .where((s) =>
                s.nama.toLowerCase().contains(q) ||
                s.nim.toLowerCase().contains(q) ||
                s.jabatan.toLowerCase().contains(q))
            .toList();

    final totalResults = matchedCourses.length +
        matchedResources.length +
        matchedAssignments.length +
        matchedStudents.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181428) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF382F57) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Search header input
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              style: TextStyle(
                color: isDark ? const Color(0xFFF3F4F6) : AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Cari matkul, materi, tugas, atau mahasiswa...',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF261D4C) : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF382F57) : const Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF382F57) : const Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Results list or prompt
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.manage_search_rounded,
                              size: 48,
                              color: isDark ? const Color(0xFF382F57) : const Color(0xFFD1D5DB)),
                          const SizedBox(height: 12),
                          Text(
                            'Pencarian Universal Cepat',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ketik kata kunci untuk menemukan Jadwal Kuliah, E-Book/PPT, Tugas, atau Profil Mahasiswa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : totalResults == 0
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 44,
                                  color: isDark ? const Color(0xFF382F57) : const Color(0xFFD1D5DB)),
                              const SizedBox(height: 10),
                              Text(
                                'Tidak Ditemukan',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tidak ada data yang cocok dengan kata kunci "$_query"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          // 1. Mata Kuliah Section
                          if (matchedCourses.isNotEmpty) ...[
                            _buildSectionHeader('MATA KULIAH & JADWAL (${matchedCourses.length})', Icons.calendar_today_outlined, isDark),
                            ...matchedCourses.map((c) => _buildResultTile(
                                  title: c.nama,
                                  subtitle: '${c.hari} • ${c.jamMulai}-${c.jamSelesai} • ${c.dosen}',
                                  badge: '${c.sks} SKS',
                                  badgeColor: AppColors.primary,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onNavigateTab(1); // Jadwal
                                  },
                                )),
                            const SizedBox(height: 12),
                          ],

                          // 2. Modul & Gudang Materi
                          if (matchedResources.isNotEmpty) ...[
                            _buildSectionHeader('GUDANG MATERI & E-BOOK (${matchedResources.length})', Icons.menu_book_outlined, isDark),
                            ...matchedResources.map((r) => _buildResultTile(
                                  title: r.judul,
                                  subtitle: '${r.courseName} • Pertemuan ${r.pertemuanKe ?? 1}',
                                  badge: r.jenis,
                                  badgeColor: const Color(0xFF0284C7),
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onNavigateTab(6); // Materi
                                  },
                                )),
                            const SizedBox(height: 12),
                          ],

                          // 3. Tugas Kuliah
                          if (matchedAssignments.isNotEmpty) ...[
                            _buildSectionHeader('TUGAS KULIAH (${matchedAssignments.length})', Icons.assignment_outlined, isDark),
                            ...matchedAssignments.map((a) => _buildResultTile(
                                  title: a.judul,
                                  subtitle: '${a.courseName} • Deadline: ${a.deadline.day}/${a.deadline.month}/${a.deadline.year}',
                                  badge: a.kategori,
                                  badgeColor: const Color(0xFFD97706),
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onNavigateTab(2); // Tugas
                                  },
                                )),
                            const SizedBox(height: 12),
                          ],

                          // 4. Mahasiswa
                          if (matchedStudents.isNotEmpty) ...[
                            _buildSectionHeader('DIREKTORI MAHASISWA (${matchedStudents.length})', Icons.people_outline_rounded, isDark),
                            ...matchedStudents.map((s) => _buildResultTile(
                                  title: s.nama,
                                  subtitle: 'NIM: ${s.nim} • ${s.prodi}',
                                  badge: s.jabatan,
                                  badgeColor: const Color(0xFF059669),
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onNavigateTab(4); // Direktori
                                  },
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D4C) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF382F57) : const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF3F4F6) : AppColors.textMain,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF9CA3AF) : AppColors.textSub,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            badge,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
          ),
        ),
      ),
    );
  }
}
