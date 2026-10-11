import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/saas_components.dart';
import '../../core/services/student_dashboard_service.dart';
import '../../core/widgets/universal_search_modal.dart';
import '../../models/models.dart';
import '../attendance/attendance_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final StudentProfile student;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback? onOpenDrawer;

  const StudentHomeScreen({
    super.key,
    required this.student,
    required this.onNavigateTab,
    this.onOpenDrawer,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Map<String, dynamic>> _attendance = [];
  List<Assignment> _pendingAssignments = [];
  Announcement? _announcement;
  List<Course> _todayCourses = [];
  bool? _isKasLunas;
  int _kasNominal = 0;
  String _currentPeriodLabel = '';
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final snapshot = await StudentDashboardService.load(widget.student.nim);
      if (!mounted) return;

      // Ambil id notifikasi yang sudah dibaca / di-dismiss oleh mahasiswa
      final prefs = await SharedPreferences.getInstance();
      final storageKeyPrefix = 'notif_${widget.student.nim}_';
      final readIds = (prefs.getStringList('${storageKeyPrefix}read_ids') ?? []).toSet();
      final dismissedIds = (prefs.getStringList('${storageKeyPrefix}dismissed_ids') ?? []).toSet();

      // Hitung notifikasi yang benar-benar belum dibaca
      int notifCount = 0;
      if (snapshot.latestAnnouncement != null) {
        final annId = 'announcement_${snapshot.latestAnnouncement!.id}';
        if (!readIds.contains(annId) && !dismissedIds.contains(annId)) {
          notifCount++;
        }
      }
      for (final a in snapshot.pendingAssignments) {
        final diff = a.deadline.difference(DateTime.now()).inHours;
        if (diff <= 72) {
          final assignId = 'assignment_${a.id}';
          if (!readIds.contains(assignId) && !dismissedIds.contains(assignId)) {
            notifCount++;
          }
        }
      }

      setState(() {
        _attendance = snapshot.attendance;
        _pendingAssignments = snapshot.pendingAssignments;
        _announcement = snapshot.latestAnnouncement;
        _todayCourses = snapshot.todayCourses;
        _isKasLunas = snapshot.isKasLunas;
        _kasNominal = snapshot.kasNominal;
        _currentPeriodLabel = snapshot.currentPeriodLabel;
        _unreadNotificationCount = notifCount;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Data beranda gagal dimuat. Periksa koneksi lalu coba lagi.';
      });
      debugPrint('Gagal memuat data beranda mahasiswa: $error');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi â˜€ï¸';
    if (hour >= 11 && hour < 15) return 'Selamat Siang ðŸŒ¤ï¸';
    if (hour >= 15 && hour < 18) return 'Selamat Sore ðŸŒ‡';
    return 'Selamat Malam ðŸŒ™';
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _openWhatsAppDosen(String phone, String lecturerName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone =
        cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo Bapak/Ibu $lecturerName, saya ${widget.student.nama} (NIM: ${widget.student.nim}) dari S1 Ilmu Komunikasi UNAZLAM...',
    );
    final uri = Uri.parse('https://wa.me/$internationalPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openVirtualClass(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = widget.student;

    final hadir = _attendance.where((row) => '${row['status']}'.toLowerCase() == 'hadir').length;
    final attendancePercent = _attendance.isEmpty ? null : (hadir * 100 / _attendance.length).round();

    final bgColor = isDark ? const Color(0xFF111018) : const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: _isLoading
              ? _buildShimmerLoading(context, isDark)
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. Header Ucapan & Konteks Waktu
                    _buildGreetingHeader(context, student, isDark),
                    const SizedBox(height: 12),

                    // 2. Gojek-style Top Bar (Search + Notif + Avatar)
                    _buildTopBar(context, student, isDark),
                    const SizedBox(height: 14),

                    // 3. Error Alert jika gagal fetch
                    if (_loadError != null) ...[
                      _buildLoadError(isDark),
                      const SizedBox(height: 14),
                    ],

                    // 4. Presensi Aktif Banner (1-Tap Scan QR Langsung)
                    if (AttendanceScreen.currentSession != null &&
                        !AttendanceScreen.currentSession!.isExpired) ...[
                      _buildLiveAttendanceBanner(context, student, isDark),
                      const SizedBox(height: 14),
                    ],

                    // 5. Gojek-style "Academic Wallet" Card (Status Presensi & Kas Kelas)
                    _buildAcademicWalletCard(context, student, attendancePercent, hadir, isDark),
                    const SizedBox(height: 18),

                    // 6. Gojek-style 8 App Services Grid (2 Baris x 4 Kolom)
                    _buildServicesGrid(context, student, isDark),
                    const SizedBox(height: 22),

                    // 7. WIDGET TUGAS MENDESAK & COUNTDOWN DEADLINE (Paket C)
                    if (_pendingAssignments.isNotEmpty) ...[
                      _buildUrgentAssignmentSpotlightSection(context, isDark),
                      const SizedBox(height: 22),
                    ],

                    // 8. Carousel "Aktivitas Hari Ini" (Jadwal Kuliah Real-Time)
                    _buildTodayActivitiesSection(context, isDark),
                    const SizedBox(height: 22),

                    // 9. Banner Pengumuman Terkini
                    _buildAnnouncementBanner(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. GREETING & CONTEXT HEADER
  // ==========================================
  Widget _buildGreetingHeader(BuildContext context, StudentProfile student, bool isDark) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final firstName = student.nama.trim().split(' ').first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, $firstName ðŸ‘‹',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'Semester ${student.semester}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. TOP BAR: COMMAND SEARCH BAR + NOTIF + AVATAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, StudentProfile student, bool isDark) {
    final initials = student.nama
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    return Row(
      children: [
        // Search Bar (Linear / Raycast Style crisp command bar)
        Expanded(
          child: Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            child: InkWell(
              onTap: () => UniversalSearchModal.show(context, onNavigateTab: widget.onNavigateTab),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari matkul, tugas, dosen...',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262E3D) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        'âŒ˜K',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Tombol Notifikasi (Sleek Squircle)
        Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => widget.onNavigateTab(11), // Notifikasi
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _unreadNotificationCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _unreadNotificationCount > 0
                        ? AppColors.primary
                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                    size: 20,
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBg, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Avatar Profil Mahasiswa (Sleek High-Contrast Squircle)
        InkWell(
          onTap: () => widget.onNavigateTab(4), // Profil
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF0F172A),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. ACADEMIC WALLET CARD (ALA GOPAY CARD)
  // ==========================================
  Widget _buildAcademicWalletCard(
    BuildContext context,
    StudentProfile student,
    int? attendancePercent,
    int hadirCount,
    bool isDark,
  ) {
    final isEligible = attendancePercent != null && attendancePercent >= 75;
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sisi Kiri: Status Kehadiran & Status Iuran Kas Kelas
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () => widget.onNavigateTab(5), // Presensi
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Baris 1: Status Presensi UAS & Kehadiran
                    Row(
                      children: [
                        attendancePercent == null
                            ? SoftPillBadge.neutral(label: 'Presensi Baru', fontSize: 10)
                            : (isEligible
                                ? SoftPillBadge.success(
                                    label: 'UAS Aman $attendancePercent%',
                                    fontSize: 10,
                                    showDot: true,
                                  )
                                : SoftPillBadge.warning(
                                    label: 'Pantau Presensi $attendancePercent%',
                                    fontSize: 10,
                                    showDot: true,
                                  )),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Baris 2: Nilai / Status Utama
                    Text(
                      attendancePercent == null
                          ? 'Belum Ada Presensi'
                          : '$hadirCount Hadir â€¢ $attendancePercent%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: textMain,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Baris 3: Status Iuran Kas Pribadi (Paket 1 Real Data)
                    InkWell(
                      onTap: () => widget.onNavigateTab(8), // Buka Kas
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Icon(
                            _isKasLunas == true
                                ? Icons.check_circle_rounded
                                : (_isKasLunas == false
                                    ? Icons.error_rounded
                                    : Icons.account_balance_wallet_rounded),
                            size: 12,
                            color: _isKasLunas == true
                                ? const Color(0xFF10B981)
                                : (_isKasLunas == false
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF0D9488)),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _isKasLunas == true
                                  ? 'Kas: Lunas'
                                  : (_isKasLunas == false
                                      ? 'Kas: ${_formatCurrency(_kasNominal)}'
                                      : (_currentPeriodLabel.isNotEmpty
                                          ? 'Iuran: $_currentPeriodLabel'
                                          : 'Cek status iuran kas')),
                              style: TextStyle(
                                fontSize: 10,
                                color: _isKasLunas == true
                                    ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669))
                                    : (_isKasLunas == false
                                        ? const Color(0xFFEF4444)
                                        : textSub),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider Tipis
          Container(
            height: 42,
            width: 1,
            color: borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // Sisi Kanan: 4 Aksi Cepat Ikonis (Absen, Kas, KHS, Tugas)
          Expanded(
            flex: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Absen',
                    color: const Color(0xFF0284C7),
                    bgColor: isDark ? const Color(0xFF1E2E42) : const Color(0xFFE0F2FE),
                    textColor: textMain,
                    onTap: () {
                      if (AttendanceScreen.currentSession != null &&
                          !AttendanceScreen.currentSession!.isExpired) {
                        AttendanceScreen.showStudentScanner(
                          context,
                          userNim: student.nim,
                          onSuccess: _loadDashboard,
                        );
                      } else {
                        widget.onNavigateTab(5); // Presensi
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Kas',
                    color: const Color(0xFF0D9488),
                    bgColor: isDark ? const Color(0xFF1A3533) : const Color(0xFFCCFBF1),
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(8), // Kas Kelas
                  ),
                ),
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.school_rounded,
                    label: 'KHS',
                    color: AppColors.primary,
                    bgColor: isDark ? const Color(0xFF262244) : const Color(0xFFEDE9FE),
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(15), // KHS & Transkrip Nilai (Tab 15)
                  ),
                ),
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.checklist_rounded,
                    label: 'Tugas',
                    color: const Color(0xFFE11D48),
                    bgColor: isDark ? const Color(0xFF381D26) : const Color(0xFFFFE4E6),
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(2), // Tugas
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGojekActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. LIVE ATTENDANCE BANNER (1-TAP SCANNER)
  // ==========================================
  Widget _buildLiveAttendanceBanner(BuildContext context, StudentProfile student, bool isDark) {
    final session = AttendanceScreen.currentSession!;
    final attended = session.attendedNims.contains(student.nim);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A20) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E523A) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Aktif â€¢ ${session.courseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  attended
                      ? 'Kamu sudah terdata hadir ðŸŽ‰'
                      : 'Sisa waktu ${session.remainingSeconds ~/ 60} menit',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!attended)
            FilledButton.icon(
              onPressed: () {
                // 1-Tap Langsung Luncurkan Scanner Kamera Presensi di Beranda!
                AttendanceScreen.showStudentScanner(
                  context,
                  userNim: student.nim,
                  onSuccess: _loadDashboard,
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
              label: const Text('Scan QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. 8 SERVICES GRID (ALA MENU GOJEK)
  // ==========================================
  Widget _buildServicesGrid(BuildContext context, StudentProfile student, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    final services = [
      _ServiceItem(
        title: 'Jadwal',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        tabIndex: 1,
      ),
      _ServiceItem(
        title: 'Materi Kuliah',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0284C7),
        bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE0F2FE),
        tabIndex: 10, // Gudang Materi & E-Book
      ),
      _ServiceItem(
        title: 'Agenda Kelas',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF059669),
        bgColor: isDark ? const Color(0xFF152F24) : const Color(0xFFECFDF5),
        tabIndex: 6, // Agenda Kelas
      ),
      _ServiceItem(
        title: 'Kelompok',
        icon: Icons.group_work_rounded,
        color: const Color(0xFF0D9488),
        bgColor: isDark ? const Color(0xFF163230) : const Color(0xFFF0FDFA),
        tabIndex: 9, // Kelompok Praktikum
      ),
      _ServiceItem(
        title: 'Voting',
        icon: Icons.how_to_vote_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF2B2144) : AppColors.primarySoft,
        tabIndex: 12, // Voting & Polling
      ),
      _ServiceItem(
        title: 'Pengumuman',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFDC2626),
        bgColor: isDark ? const Color(0xFF341E1E) : const Color(0xFFFEF2F2),
        tabIndex: 7, // Pengumuman
      ),
      _ServiceItem(
        title: 'Teman Kelas',
        icon: Icons.groups_rounded,
        color: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
        tabIndex: 3, // Direktori Kelas
      ),
      _ServiceItem(
        title: 'Lainnya',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF64748B),
        bgColor: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
        isMore: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.take(4).map((item) => _buildServiceIcon(context, item, isDark)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.skip(4).take(4).map((item) => _buildServiceIcon(context, item, isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, _ServiceItem item, bool isDark) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: () {
          if (item.isMore) {
            _showMoreServicesModal(context, isDark);
          } else {
            widget.onNavigateTab(item.tabIndex);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.color.withValues(alpha: 0.16), width: 0.8),
                ),
                child: Icon(item.icon, color: item.color, size: 21),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. SPOTLIGHT TUGAS MENDESAK & DEADLINE (PAKET C)
  // ==========================================
  Widget _buildUrgentAssignmentSpotlightSection(BuildContext context, bool isDark) {
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    // Ambil tugas dengan deadline paling dekat
    final assignment = _pendingAssignments.first;
    final now = DateTime.now();
    final due = assignment.deadline;
    final diff = due.difference(now);
    final inDays = diff.inDays;
    final inHours = diff.inHours;

    final bool isOverdue = diff.isNegative;
    final bool isUrgent = inHours <= 24; // H-1 atau hari H
    final bool isWarning = inDays <= 3; // H-3

    Color accentColor = const Color(0xFF0284C7); // Biru (Normal)
    Color badgeBg = isDark ? const Color(0xFF1E2E42) : const Color(0xFFE0F2FE);
    String statusLabel = '${inDays + 1} hari lagi';

    if (isOverdue) {
      accentColor = const Color(0xFFEF4444); // Merah
      badgeBg = isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2);
      statusLabel = 'Lewat Tenggat';
    } else if (isUrgent) {
      accentColor = const Color(0xFFEF4444); // Merah mencolok
      badgeBg = isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2);
      final hoursRemaining = inHours.clamp(0, 24);
      statusLabel = hoursRemaining <= 0 ? 'Hari ini' : '$hoursRemaining jam lagi';
    } else if (isWarning) {
      accentColor = const Color(0xFFF59E0B); // Kuning/Oranye
      badgeBg = isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB);
      statusLabel = '$inDays hari lagi';
    }

    final formattedDeadline = DateFormat('EEE, d MMM yyyy â€¢ HH:mm', 'id_ID').format(due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tugas Mendesak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26223D) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_pendingAssignments.length} Tugas Aktif',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => widget.onNavigateTab(2), // Ke Tab Tugas
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Spotlight Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isOverdue || isUrgent) ? accentColor.withValues(alpha: 0.5) : borderColor,
              width: (isOverdue || isUrgent) ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOverdue || isUrgent)
                    ? accentColor.withValues(alpha: isDark ? 0.12 : 0.06)
                    : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris 1: Mata kuliah & Badge Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            assignment.kategori.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: textSub,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            assignment.courseName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue ? Icons.error_rounded : Icons.timer_outlined,
                          size: 13,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Baris 2: Judul Tugas
              Text(
                assignment.judul,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: textMain,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Baris 3: Deadline & Tombol Aksi Kumpul
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: textSub),
                      const SizedBox(width: 5),
                      Text(
                        formattedDeadline,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => widget.onNavigateTab(2), // Buka Tugas
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kumpul',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. AKTIVITAS HARI INI (HORIZONTAL CAROUSEL)
  // ==========================================
  Widget _buildTodayActivitiesSection(BuildContext context, bool isDark) {
    final now = DateTime.now();
    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';

    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Aktivitas Kuliah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    todayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFA78BFA) : textSub,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => widget.onNavigateTab(1), // Jadwal
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Carousel Jadwal Kuliah Hari Ini
        SizedBox(
          height: 134,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              // Kartu Jadwal Kuliah Real-Time dari Supabase
              if (_todayCourses.isEmpty)
                _buildFreeDayHorizontalCard(isDark)
              else
                ..._todayCourses.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCourseHorizontalCard(c, isDark),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHorizontalCard(Course course, bool isDark) {
    final now = DateTime.now();
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Hitung status waktu kelas (Sedang berlangsung vs Dimulai segera)
    bool isLiveNow = false;
    bool isUpcomingSoon = false;
    int minutesUntilStart = 0;

    try {
      final startParts = course.jamMulai.split(':');
      final endParts = course.jamSelesai.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startDt = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        final endDt = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        if (now.isAfter(startDt) && now.isBefore(endDt)) {
          isLiveNow = true;
        } else if (now.isBefore(startDt)) {
          final diff = startDt.difference(now).inMinutes;
          if (diff >= 0 && diff <= 60) {
            isUpcomingSoon = true;
            minutesUntilStart = diff;
          }
        }
      }
    } catch (_) {}

    return Container(
      width: 265,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLiveNow
              ? const Color(0xFF10B981)
              : (isUpcomingSoon ? const Color(0xFFF59E0B) : borderColor),
          width: (isLiveNow || isUpcomingSoon) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLiveNow
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Waktu & Badge Live/Upcoming
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLiveNow
                      ? const Color(0xFFDCFCE7)
                      : (isUpcomingSoon
                          ? const Color(0xFFFEF3C7)
                          : (isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE))),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLiveNow) ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      isLiveNow
                          ? 'BERLANGSUNG'
                          : (isUpcomingSoon
                              ? '$minutesUntilStart MNT LAGI'
                              : '${course.jamMulai} - ${course.jamSelesai}'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isLiveNow
                            ? const Color(0xFF15803D)
                            : (isUpcomingSoon
                                ? const Color(0xFFB45309)
                                : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  course.ruangan.isNotEmpty ? course.ruangan : 'Lab A',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textSub,
                  ),
                ),
              ),
            ],
          ),

          // Detail Kuliah
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${course.dosen} â€¢ ${course.sks} SKS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: textSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Aksi Cepat Bawah: WA Dosen 1-Tap & Virtual Link
          Row(
            children: [
              if (course.dosenWa != null && course.dosenWa!.trim().isNotEmpty) ...[
                InkWell(
                  onTap: () => _openWhatsAppDosen(course.dosenWa!, course.dosen),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'WA Dosen',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (course.linkVirtual != null && course.linkVirtual!.trim().isNotEmpty) ...[
                InkWell(
                  onTap: () => _openVirtualClass(course.linkVirtual!),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'Zoom/Meet',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: () => widget.onNavigateTab(1), // Jadwal
                child: Icon(Icons.arrow_forward_rounded, size: 15, color: textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildFreeDayHorizontalCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE),
            child: const Icon(Icons.beach_access_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tidak Ada Kuliah ðŸŽ‰',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Istirahat atau kerjakan tugas.',
                  style: TextStyle(fontSize: 11, color: textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. BANNER PENGUMUMAN (CLEAN TECH MINIMAL)
  // ==========================================
  Widget _buildAnnouncementBanner(BuildContext context, bool isDark) {
    final item = _announcement;
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4C222E) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item?.kategori.toUpperCase() ?? 'INFO KELAS',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => widget.onNavigateTab(7),
                      child: const Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item?.judul ?? 'Belum ada pengumuman terbaru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item?.isi ?? 'Informasi penting dari koordinator kelas akan muncul di sini.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSub,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(bool isDark) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF332014) : const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF54341F) : const Color(0xFFFFD59E),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFB45309), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _loadError!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                ),
              ),
            ),
            TextButton(
              onPressed: _loadDashboard,
              child: const Text('Coba lagi', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      );

  // ==========================================
  // 8. SHIMMER SKELETON LOADING (PAKET 3)
  // ==========================================
  Widget _buildShimmerLoading(BuildContext context, bool isDark) {
    final shimmerBase = isDark ? const Color(0xFF222030) : const Color(0xFFE2E8F0);

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Greeting Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 160, height: 20, color: shimmerBase),
                const SizedBox(height: 6),
                _buildShimmerBox(width: 110, height: 14, color: shimmerBase),
              ],
            ),
            _buildShimmerBox(width: 60, height: 26, radius: 10, color: shimmerBase),
          ],
        ),
        const SizedBox(height: 14),

        // Search Bar Skeleton
        _buildShimmerBox(width: double.infinity, height: 46, radius: 28, color: shimmerBase),
        const SizedBox(height: 14),

        // Academic Wallet Skeleton
        _buildShimmerBox(width: double.infinity, height: 76, radius: 20, color: shimmerBase),
        const SizedBox(height: 18),

        // 8 Services Grid Skeleton
        _buildShimmerBox(width: double.infinity, height: 160, radius: 22, color: shimmerBase),
        const SizedBox(height: 22),

        // Activities Title Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShimmerBox(width: 140, height: 18, color: shimmerBase),
            _buildShimmerBox(width: 70, height: 14, color: shimmerBase),
          ],
        ),
        const SizedBox(height: 12),

        // Activities Carousel Skeleton
        SizedBox(
          height: 134,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildShimmerBox(width: 250, height: 134, radius: 18, color: shimmerBase),
              const SizedBox(width: 12),
              _buildShimmerBox(width: 250, height: 134, radius: 18, color: shimmerBase),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Announcement Banner Skeleton
        _buildShimmerBox(width: double.infinity, height: 80, radius: 20, color: shimmerBase),
      ],
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double radius = 8,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ==========================================
  // MODAL MENU LENGKAP ("LAINNYA")
  // ==========================================
  void _showMoreServicesModal(BuildContext context, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Semua Menu Portal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textMain,
              ),
            ),
            const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  _buildModalMenuItem(
                    icon: Icons.description_rounded,
                    label: 'Surat Izin',
                    color: const Color(0xFF0284C7),
                    bgColor: isDark ? const Color(0xFF1E2E42) : const Color(0xFFE0F2FE),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(13); // Surat & Dispensasi
                    },
                  ),
                  _buildModalMenuItem(
                    icon: Icons.history_rounded,
                    label: 'Audit Log',
                    color: const Color(0xFF64748B),
                    bgColor: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(14); // Audit Log
                    },
                  ),
                  _buildModalMenuItem(
                    icon: Icons.payments_rounded,
                    label: 'Kas Kelas',
                    color: const Color(0xFF0D9488),
                    bgColor: isDark ? const Color(0xFF163230) : const Color(0xFFF0FDFA),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(8); // Kas
                    },
                  ),
                  _buildModalMenuItem(
                    icon: Icons.co_present_rounded,
                    label: 'Presensi',
                    color: const Color(0xFF10B981),
                    bgColor: isDark ? const Color(0xFF152F24) : const Color(0xFFECFDF5),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(5); // Presensi
                    },
                  ),
                  _buildModalMenuItem(
                    icon: Icons.school_rounded,
                    label: 'KHS Nilai',
                    color: const Color(0xFF7C3AED),
                    bgColor: isDark ? const Color(0xFF2B2144) : AppColors.primarySoft,
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(15); // KHS
                    },
                  ),
                  _buildModalMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil Saya',
                    color: AppColors.primary,
                    bgColor: isDark ? const Color(0xFF262244) : const Color(0xFFEDE9FE),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(4); // Profil
                    },
                  ),
                  if (widget.student.isKetuaKelas || widget.student.isAdmin)
                    _buildModalMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Panel Komti',
                      color: const Color(0xFFEA580C),
                      bgColor: isDark ? const Color(0xFF381D26) : const Color(0xFFFFF7ED),
                      textColor: textMain,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onNavigateTab(7); // Pengumuman / Admin
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int tabIndex;
  final bool isMore;

  _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.tabIndex = 0,
    this.isMore = false,
  });
}
