import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/safe_launcher.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

/// Modal "Academic Urgency Radar & 1-Klik Share Briefing Kelas"
/// Memungkinkan Komti, Pengurus Kelas, maupun Mahasiswa menyusun dan membagikan
/// rangkuman jadwal hari ini/mendatang (termasuk perubahan ruang/jam/daring),
/// pengingat tugas mendesak, dan pengumuman penting ke grup WhatsApp dalam 1 klik.
class DailyBriefingBroadcastModal {
  static void show(
    BuildContext context, {
    required StudentProfile student,
    required List<Course> todayCourses,
    required List<Course> upcomingCourses,
    required String nextActiveDayName,
    required String nextActiveDayLabel,
    required List<Assignment> pendingAssignments,
    Announcement? latestAnnouncement,
    int initialMode = 0, // 0 = Hari Ini, 1 = Mendatang
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DailyBriefingSheetContent(
        student: student,
        todayCourses: todayCourses,
        upcomingCourses: upcomingCourses,
        nextActiveDayName: nextActiveDayName,
        nextActiveDayLabel: nextActiveDayLabel,
        pendingAssignments: pendingAssignments,
        latestAnnouncement: latestAnnouncement,
        initialMode: todayCourses.isEmpty ? 1 : initialMode,
      ),
    );
  }

  /// Menghasilkan teks briefing kelas berformat WhatsApp yang rapi dan siap kirim
  static String buildBriefingText({
    required StudentProfile student,
    required List<Course> courses,
    required String dayHeaderLabel,
    required List<Assignment> assignments,
    Announcement? announcement,
    bool includeSchedule = true,
    bool includeAssignments = true,
    bool includeAnnouncement = true,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    buffer.writeln('📋 *BRIEFING AKADEMIK ILKOM UNAZLAM*');
    buffer.writeln('🗓️ _Update: ${dateStr}_');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (includeSchedule) {
      buffer.writeln('');
      buffer.writeln('🎓 *JADWAL KULIAH (${dayHeaderLabel.toUpperCase()})*');
      if (courses.isEmpty) {
        buffer.writeln('• _Tidak ada jadwal perkuliahan aktif._');
      } else {
        for (int i = 0; i < courses.length; i++) {
          final c = courses[i];
          buffer.writeln('${i + 1}. *${c.nama}* (${c.sks} SKS)');
          if (c.isCancelledToday) {
            buffer.writeln('   ⛔ *STATUS: KELAS DITIADAKAN / ASINKRON*');
            if (c.override?.alasan != null && c.override!.alasan!.trim().isNotEmpty) {
              buffer.writeln('   📝 Catatan: _${c.override!.alasan!.trim()}_');
            }
          } else {
            final jam = '${c.effectiveJamMulai} - ${c.effectiveJamSelesai} WITA';
            final ruang = c.isOnlineOverride
                ? '🌐 Daring / Online'
                : '📍 Ruang ${c.effectiveRuangan}';
            buffer.writeln('   ⏰ $jam | $ruang');
            buffer.writeln('   👨‍🏫 Dosen: ${c.dosen}');
            if (c.hasActiveOverride) {
              buffer.writeln('   ⚡ *Info Perubahan: ${c.override!.statusBadgeLabel}*');
              if (c.override?.alasan != null && c.override!.alasan!.trim().isNotEmpty) {
                buffer.writeln('   💬 Ket: _${c.override!.alasan!.trim()}_');
              }
              if (c.effectiveLinkVirtual != null && c.effectiveLinkVirtual!.trim().isNotEmpty) {
                buffer.writeln('   🔗 Link: ${c.effectiveLinkVirtual!.trim()}');
              }
            }
          }
        }
      }
    }

    if (includeAssignments) {
      final urgentList = assignments
          .where((a) => a.deadline.isAfter(now.subtract(const Duration(hours: 2))))
          .take(4)
          .toList();
      if (urgentList.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('⏳ *PENGINGAT TUGAS & DEADLINE*');
        for (final a in urgentList) {
          final diffHours = a.deadline.difference(now).inHours;
          final deadlineFmt = DateFormat('dd MMM, HH:mm', 'id_ID').format(a.deadline);
          final urgencyTag = diffHours <= 24
              ? '🔴 SEGERA'
              : (diffHours <= 72 ? '🟡 H-${(diffHours / 24).ceil()}' : '🟢 Aktif');
          buffer.writeln('• [$urgencyTag] *${a.judul}* (${a.courseName})');
          buffer.writeln('   ⏰ Tenggat: $deadlineFmt WITA');
        }
      }
    }

    if (includeAnnouncement && announcement != null) {
      buffer.writeln('');
      buffer.writeln('📢 *INFO PENTING: ${announcement.judul.toUpperCase()}*');
      final cleanIsi = announcement.isi.trim();
      final snippet = cleanIsi.length > 180 ? '${cleanIsi.substring(0, 180)}...' : cleanIsi;
      buffer.writeln(snippet);
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Dikirim via ILKOM UNAZLAM Hub oleh ${student.nama} (${student.jabatan})_');

    return buffer.toString().trim();
  }
}

class _DailyBriefingSheetContent extends StatefulWidget {
  final StudentProfile student;
  final List<Course> todayCourses;
  final List<Course> upcomingCourses;
  final String nextActiveDayName;
  final String nextActiveDayLabel;
  final List<Assignment> pendingAssignments;
  final Announcement? latestAnnouncement;
  final int initialMode;

  const _DailyBriefingSheetContent({
    required this.student,
    required this.todayCourses,
    required this.upcomingCourses,
    required this.nextActiveDayName,
    required this.nextActiveDayLabel,
    required this.pendingAssignments,
    this.latestAnnouncement,
    required this.initialMode,
  });

  @override
  State<_DailyBriefingSheetContent> createState() => _DailyBriefingSheetContentState();
}

class _DailyBriefingSheetContentState extends State<_DailyBriefingSheetContent> {
  late int _dayMode; // 0 = Hari Ini, 1 = Mendatang
  bool _includeSchedule = true;
  bool _includeAssignments = true;
  bool _includeAnnouncement = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _dayMode = widget.initialMode;
    _includeAnnouncement = widget.latestAnnouncement != null;
  }

  List<Course> get _selectedCourses =>
      _dayMode == 0 ? widget.todayCourses : widget.upcomingCourses;

  String get _selectedDayLabel {
    if (_dayMode == 0) {
      const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final w = DateTime.now().weekday;
      return 'Hari Ini • ${(w >= 1 && w <= 7) ? dayNames[w] : ''}';
    }
    return widget.nextActiveDayLabel.isNotEmpty
        ? widget.nextActiveDayLabel
        : (widget.nextActiveDayName.isNotEmpty ? widget.nextActiveDayName : 'Jadwal Mendatang');
  }

  String get _generatedText => DailyBriefingBroadcastModal.buildBriefingText(
        student: widget.student,
        courses: _selectedCourses,
        dayHeaderLabel: _selectedDayLabel,
        assignments: widget.pendingAssignments,
        announcement: widget.latestAnnouncement,
        includeSchedule: _includeSchedule,
        includeAssignments: _includeAssignments,
        includeAnnouncement: _includeAnnouncement,
      );

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedText));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Teks Briefing Akademik berhasil disalin! Siap ditempel ke Grup WA.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareToWhatsApp() async {
    HapticFeedback.mediumImpact();
    final encoded = Uri.encodeComponent(_generatedText);
    await safeLaunchUrl('https://wa.me/?text=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1829) : Colors.white;
    final surfaceBg = isDark ? const Color(0xFF242136) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF332F4C) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : const Color(0xFF64748B);

    final overrideCount = _selectedCourses.where((c) => c.hasActiveOverride).length;
    final urgentTaskCount = widget.pendingAssignments
        .where((a) => a.deadline.difference(DateTime.now()).inHours <= 72)
        .length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar Akademik & Share Info Kelas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siapkan rangkuman jadwal, perubahan ruang, & deadline 1 klik',
                        style: TextStyle(fontSize: 11.5, color: textSub),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSub, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Ringkasan Radar Indikator Cepat
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatBadge(
                  icon: Icons.menu_book_rounded,
                  label: '${_selectedCourses.length} Mata Kuliah',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                if (overrideCount > 0)
                  _buildStatBadge(
                    icon: Icons.bolt_rounded,
                    label: '$overrideCount Perubahan Jadwal/Ruang',
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                _buildStatBadge(
                  icon: Icons.assignment_late_rounded,
                  label: urgentTaskCount > 0
                      ? '$urgentTaskCount Tugas Mendesak (≤ H-3)'
                      : '${widget.pendingAssignments.length} Tugas Aktif',
                  color: urgentTaskCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pilihan Hari (Hari Ini vs Mendatang)
            Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    label: 'Jadwal Hari Ini (${widget.todayCourses.length})',
                    selected: _dayMode == 0,
                    isDark: isDark,
                    onTap: () => setState(() => _dayMode = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeTab(
                    label: 'Mendatang (${widget.upcomingCourses.length})',
                    selected: _dayMode == 1,
                    isDark: isDark,
                    onTap: () => setState(() => _dayMode = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Filter Komponen Pesan
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Jadwal & Ruangan'),
                  selected: _includeSchedule,
                  onSelected: (v) => setState(() => _includeSchedule = v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _includeSchedule ? AppColors.primary : textSub,
                  ),
                ),
                FilterChip(
                  label: const Text('Tugas & Deadline'),
                  selected: _includeAssignments,
                  onSelected: (v) => setState(() => _includeAssignments = v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _includeAssignments ? AppColors.primary : textSub,
                  ),
                ),
                if (widget.latestAnnouncement != null)
                  FilterChip(
                    label: const Text('Info Penting'),
                    selected: _includeAnnouncement,
                    onSelected: (v) => setState(() => _includeAnnouncement = v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _includeAnnouncement ? AppColors.primary : textSub,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Kotak Pratinjau Pesan WhatsApp
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 230),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _generatedText,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontFamily: 'monospace',
                    color: textMain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Aksi (Salin & Kirim ke WhatsApp)
            Row(
              children: [
                Expanded(
                  child: ScaleButton(
                    onTap: _copyToClipboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: surfaceBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: 17,
                            color: _copied ? const Color(0xFF10B981) : textMain,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              _copied ? 'Tersalin!' : 'Salin Teks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _copied ? const Color(0xFF10B981) : textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ScaleButton(
                    onTap: _shareToWhatsApp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 17, color: Colors.white),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Bagikan ke Grup WA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      scaleDown: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? const Color(0xFF242136) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
