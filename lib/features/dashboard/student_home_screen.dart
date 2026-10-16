import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/safe_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/saas_components.dart';
import '../../core/widgets/scale_button.dart';
import '../../core/services/student_dashboard_service.dart';
import '../../core/widgets/universal_search_modal.dart';
import '../../models/models.dart';
import '../attendance/attendance_screen.dart';
import '../schedule/schedule_screen.dart';
import 'models/dashboard_models.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/more_services_modal.dart';
import 'widgets/urgent_assignment_spotlight.dart';

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

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _livePulseController;
  late final Animation<double> _livePulseAnimation;

  List<Map<String, dynamic>> _attendance = [];
  List<Assignment> _pendingAssignments = [];
  Announcement? _announcement;
  List<Course> _todayCourses = [];
  List<Course> _upcomingCourses = [];
  String _nextActiveDayName = '';
  String _nextActiveDayLabel = '';
  bool _todayHasClasses = false;
  bool _todayClassesFinished = false;
  int _scheduleViewMode = 0; // 0 = Hari Ini, 1 = Mendatang
  bool? _isKasLunas;
  int _kasNominal = 0;
  String _currentPeriodLabel = '';
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  String? _loadError;
  RealtimeChannel? _overridesChannel;

  @override
  void initState() {
    super.initState();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _livePulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _livePulseController, curve: Curves.easeInOut),
    );
    _loadDashboard();
    _initRealtimeOverrides();
  }

  void _initRealtimeOverrides() {
    _overridesChannel = SupabaseRepository.subscribeToCourseOverrides(() {
      if (mounted) {
        _loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_overridesChannel);
    _livePulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      try {
        await AttendanceScreen.syncActiveSessionFromCloud();
      } catch (e) {
        debugPrint('Info: Gagal sinkronisasi sesi presensi aktif: $e');
      }
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
        _upcomingCourses = snapshot.upcomingCourses;
        _nextActiveDayName = snapshot.nextActiveDayName;
        _nextActiveDayLabel = snapshot.nextActiveDayLabel;
        _todayHasClasses = snapshot.todayHasClasses;
        _todayClassesFinished = snapshot.todayClassesFinished;
        // Jika hari ini tidak ada kuliah atau sudah selesai, lewati hari kosong & default ke jadwal mendatang!
        if (!_todayHasClasses || _todayClassesFinished) {
          _scheduleViewMode = 1;
        } else {
          _scheduleViewMode = 0;
        }
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

  Map<String, dynamic> _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return {
        'greeting': 'Selamat Pagi',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFFF59E0B),
        'subtitle': 'Semangat memulai aktivitas akademik hari ini',
      };
    }
    if (hour >= 11 && hour < 15) {
      return {
        'greeting': 'Selamat Siang',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFF59E0B),
        'subtitle': 'Tetap fokus dan terhidrasi selama perkuliahan',
      };
    }
    if (hour >= 15 && hour < 18) {
      return {
        'greeting': 'Selamat Sore',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFFF97316),
        'subtitle': 'Waktu santai atau review materi perkuliahan',
      };
    }
    return {
      'greeting': 'Selamat Malam',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF818CF8),
      'subtitle': 'Istirahat yang cukup untuk aktivitas esok hari',
    };
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
    await safeLaunchUrl(url);
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
                    FadeSlideEntrance(
                      delay: Duration.zero,
                      child: _buildGreetingHeader(context, student, isDark),
                    ),
                    const SizedBox(height: 12),

                    // 2. Gojek-style Top Bar (Search + Notif + Avatar)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 50),
                      child: _buildTopBar(context, student, isDark),
                    ),
                    const SizedBox(height: 14),

                    // 3. Error Alert jika gagal fetch
                    if (_loadError != null) ...[
                      _buildLoadError(isDark),
                      const SizedBox(height: 14),
                    ],

                    // 4. Presensi Aktif Banner (1-Tap Scan QR Langsung) & Shortcut Pengurus
                    if (AttendanceScreen.currentSession != null &&
                        !AttendanceScreen.currentSession!.isExpired) ...[
                      FadeSlideEntrance(
                        delay: const Duration(milliseconds: 100),
                        child: _buildLiveAttendanceBanner(context, student, isDark),
                      ),
                      const SizedBox(height: 14),
                    ] else if (student.canManageAttendance) ...[
                      FadeSlideEntrance(
                        delay: const Duration(milliseconds: 100),
                        child: _buildOfficerAttendancePrompt(context, student, isDark),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 5. Gojek-style "Academic Wallet" Card (Status Presensi & Kas Kelas)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 150),
                      child: _buildAcademicWalletCard(context, student, attendancePercent, hadir, isDark),
                    ),
                    const SizedBox(height: 18),

                    // 6. Gojek-style 8 App Services Grid (2 Baris x 4 Kolom)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: _buildServicesGrid(context, student, isDark),
                    ),
                    const SizedBox(height: 18),

                    // HERO CAROUSEL BANNER (OPSI A - COMPACT HERO SLIDER)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 250),
                      child: _buildHeroBannerCarousel(context, isDark),
                    ),
                    const SizedBox(height: 22),

                    // 7. WIDGET TUGAS MENDESAK & COUNTDOWN DEADLINE (Paket C)
                    if (_pendingAssignments.isNotEmpty) ...[
                      FadeSlideEntrance(
                        delay: const Duration(milliseconds: 300),
                        child: _buildUrgentAssignmentSpotlightSection(context, isDark),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // 8. Carousel "Aktivitas Hari Ini" (Jadwal Kuliah Real-Time)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 350),
                      child: _buildTodayActivitiesSection(context, isDark),
                    ),
                    const SizedBox(height: 22),

                    // 9. Banner Pengumuman Terkini
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 400),
                      child: _buildAnnouncementBanner(context, isDark),
                    ),
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
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final timeCtx = _getTimeContext();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _livePulseAnimation,
                  builder: (context, child) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: _livePulseAnimation.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: _livePulseAnimation.value * 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  timeCtx['icon'] as IconData,
                  size: 13,
                  color: timeCtx['color'] as Color,
                ),
                const SizedBox(width: 5),
                Text(
                  dateStr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: textSub,
                  ),
                ),
              ],
            ),
            ScaleButton(
              scaleDown: 0.94,
              onTap: () => widget.onNavigateTab(15), // KHS & Akademik
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Semester ${student.semester} • Ganjil',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E40AF),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${timeCtx['greeting']}, $firstName 👋',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeCtx['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSub,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. TOP BAR: COMMAND SEARCH BAR + NOTIF + AVATAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, StudentProfile student, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    return Row(
      children: [
        // Search Bar (Spotlight Command Bar) with Bouncy Touch
        Expanded(
          child: ScaleButton(
            scaleDown: 0.98,
            onTap: () => UniversalSearchModal.show(context, onNavigateTab: widget.onNavigateTab),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cari matkul, tugas, dosen, info...',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262E3D) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Ctrl K',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Tombol Notifikasi (Sleek Squircle) with Animated Pulse when Unread
        ScaleButton(
          scaleDown: 0.92,
          onTap: () => widget.onNavigateTab(11), // Notifikasi
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 8,
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
                    child: AnimatedBuilder(
                      animation: _livePulseAnimation,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBg, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: _livePulseAnimation.value * 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
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
        const SizedBox(width: 8),

        // Avatar Profil Mahasiswa dengan Online Dot Indicator
        ScaleButton(
          scaleDown: 0.92,
          onTap: () => widget.onNavigateTab(4), // Profil
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SaaSAvatar(
                name: student.nama,
                size: 46,
                radius: 14,
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. ACADEMIC WALLET CARD (COLLEGIATE PASS & QUICK ACTIONS)
  // ==========================================
  Widget _buildAcademicWalletCard(
    BuildContext context,
    StudentProfile student,
    int? attendancePercent,
    int hadirCount,
    bool isDark,
  ) {
    final isEligible = attendancePercent != null && attendancePercent >= 75;
    final cardBg = isDark ? const Color(0xFF161524) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1C2B), const Color(0xFF151422)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sisi Kiri: Status Kehadiran & Status Iuran Kas Kelas
          Expanded(
            flex: 5,
            child: ScaleButton(
              scaleDown: 0.97,
              onTap: () => widget.onNavigateTab(5), // Presensi
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
                            ? SoftPillBadge.neutral(label: 'Presensi Baru', fontSize: 9.5)
                            : (isEligible
                                ? SoftPillBadge.success(
                                    label: 'UAS Aman $attendancePercent%',
                                    fontSize: 9.5,
                                    showDot: true,
                                  )
                                : SoftPillBadge.warning(
                                    label: 'Pantau Presensi $attendancePercent%',
                                    fontSize: 9.5,
                                    showDot: true,
                                  )),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Baris 2: Nilai / Status Utama
                    Text(
                      attendancePercent == null
                          ? 'Belum Ada Presensi'
                          : '$hadirCount Hadir • $attendancePercent%',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: textMain,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Baris Progress Bar Presensi UAS
                    if (attendancePercent != null) ...[
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (attendancePercent / 100).clamp(0.0, 1.0),
                          minHeight: 4.5,
                          backgroundColor: isDark ? const Color(0xFF26223D) : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            attendancePercent >= 75
                                ? const Color(0xFF10B981)
                                : (attendancePercent >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ] else ...[
                      const SizedBox(height: 3),
                    ],

                    // Baris 3: Status Iuran Kas Pribadi (Paket 1 Real Data)
                    ScaleButton(
                      scaleDown: 0.95,
                      onTap: () => widget.onNavigateTab(8), // Buka Kas
                      child: Row(
                        children: [
                          Icon(
                            _isKasLunas == true
                                ? Icons.check_circle_rounded
                                : (_isKasLunas == false
                                    ? Icons.error_rounded
                                    : Icons.account_balance_wallet_rounded),
                            size: 13,
                            color: _isKasLunas == true
                                ? const Color(0xFF10B981)
                                : (_isKasLunas == false
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF0D9488)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isKasLunas == true
                                  ? 'Kas: Lunas'
                                  : (_isKasLunas == false
                                      ? 'Kas: ${_formatCurrency(_kasNominal)}'
                                      : (_currentPeriodLabel.isNotEmpty
                                          ? 'Iuran: $_currentPeriodLabel'
                                          : 'Cek status kas')),
                              style: TextStyle(
                                fontSize: 10.5,
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

          // Divider Tipis Elegan
          Container(
            height: 44,
            width: 1,
            color: borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // Sisi Kanan: 4 Aksi Cepat Ikonis (Presensi, Kas, KHS, Izin)
          Expanded(
            flex: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Presensi',
                    color: AppColors.cyan,
                    textColor: textMain,
                    onTap: () {
                      if (AttendanceScreen.currentSession != null &&
                          !AttendanceScreen.currentSession!.isExpired &&
                          !student.canManageAttendance) {
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
                    color: AppColors.teal,
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(8), // Kas Kelas
                  ),
                ),
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.school_rounded,
                    label: 'KHS',
                    color: AppColors.primary,
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(15), // KHS & Transkrip Nilai (Tab 15)
                  ),
                ),
                Expanded(
                  child: _buildGojekActionItem(
                    icon: Icons.description_rounded,
                    label: 'Izin',
                    color: AppColors.rose,
                    textColor: textMain,
                    onTap: () => widget.onNavigateTab(13), // Surat Izin & Dispensasi (Tab 13)
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
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Aksi Cepat $label',
      child: ScaleButton(
        scaleDown: 0.90,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorfulIconBox(
                icon: icon,
                color: color,
                size: 38,
                iconSize: 19,
                radius: 12,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D281E) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF166534) : const Color(0xFFA7F3D0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _livePulseAnimation,
              builder: (context, child) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15 * _livePulseAnimation.value + 0.05),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: _livePulseAnimation.value * 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF059669), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presensi Aktif • ${session.courseName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    attended
                        ? 'Kamu sudah terdata hadir 🎉'
                        : 'Sisa waktu ${session.remainingSeconds ~/ 60} menit',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (!attended)
              ScaleButton(
                scaleDown: 0.92,
                onTap: () {
                  AttendanceScreen.showStudentScanner(
                    context,
                    userNim: student.nim,
                    onSuccess: _loadDashboard,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Scan QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            if (student.canManageAttendance) ...[
              const SizedBox(width: 6),
              ScaleButton(
                scaleDown: 0.92,
                onTap: () {
                  AttendanceScreen.showActiveQrModal(
                    context,
                    session: session,
                    onClosed: _loadDashboard,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Buka QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4B. OFFICER ATTENDANCE PROMPT (QUICK START FOR KETUA KELAS / ADMIN)
  // ==========================================
  Widget _buildOfficerAttendancePrompt(BuildContext context, StudentProfile student, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A8A), const Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'KETUA KELAS',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Text(
                      'Sesi Presensi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Aktifkan QR Code & PIN perkuliahan hari ini',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScaleButton(
            scaleDown: 0.92,
            onTap: () => widget.onNavigateTab(5), // Presensi Tab
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF1E3A8A)),
                  SizedBox(width: 4),
                  Text(
                    'Buka Sesi',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
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
        title: 'Materi Kuliah',
        icon: Icons.menu_book_rounded,
        color: AppColors.cyan,
        bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE0F2FE),
        tabIndex: 10, // Gudang Materi & E-Book
      ),
      _ServiceItem(
        title: 'Agenda Kelas',
        icon: Icons.event_note_rounded,
        color: AppColors.emerald,
        bgColor: isDark ? const Color(0xFF152F24) : const Color(0xFFECFDF5),
        tabIndex: 6, // Agenda Kelas
      ),
      _ServiceItem(
        title: 'Kelompok',
        icon: Icons.group_work_rounded,
        color: AppColors.teal,
        bgColor: isDark ? const Color(0xFF163230) : const Color(0xFFF0FDFA),
        tabIndex: 9, // Kelompok Praktikum
      ),
      _ServiceItem(
        title: 'Voting',
        icon: Icons.how_to_vote_rounded,
        color: AppColors.violet,
        bgColor: isDark ? const Color(0xFF2B2144) : AppColors.primarySoft,
        tabIndex: 12, // Voting & Polling
      ),
      _ServiceItem(
        title: 'Pengumuman',
        icon: Icons.campaign_rounded,
        color: AppColors.rose,
        bgColor: isDark ? const Color(0xFF341E1E) : const Color(0xFFFEF2F2),
        tabIndex: 7, // Pengumuman
      ),
      _ServiceItem(
        title: 'Surat Izin',
        icon: Icons.mark_email_read_rounded,
        color: AppColors.amber,
        bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
        tabIndex: 13, // Surat Izin & Dispensasi
      ),
      _ServiceItem(
        title: 'Audit Log',
        icon: Icons.history_rounded,
        color: const Color(0xFF6366F1),
        bgColor: isDark ? const Color(0xFF232244) : const Color(0xFFEEF2FF),
        tabIndex: 14, // Audit Log Aktivitas
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.take(4).map((item) => _buildServiceIcon(context, item, isDark)).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.skip(4).take(4).map((item) => _buildServiceIcon(context, item, isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, _ServiceItem item, bool isDark) {
    return Semantics(
      button: true,
      label: 'Layanan ${item.title}',
      child: SizedBox(
        width: 74,
        child: ScaleButton(
          scaleDown: 0.90,
          onTap: () {
            if (item.isMore) {
              _showMoreServicesModal(context, isDark);
            } else {
              widget.onNavigateTab(item.tabIndex);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorfulIconBox(
                  icon: item.icon,
                  color: item.color,
                  size: 46,
                  iconSize: 22,
                  radius: 14,
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    letterSpacing: -0.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 5B. COMPACT HERO CAROUSEL BANNER (GOJEK / TOKOPEDIA STYLE)
  // ==========================================
  Widget _buildHeroBannerCarousel(BuildContext context, bool isDark) {
    return HomeBannerCarousel(
      isDark: isDark,
      onNavigateTab: widget.onNavigateTab,
    );
  }

  // ==========================================
  // 6. SPOTLIGHT TUGAS MENDESAK & DEADLINE (PAKET C)
  // ==========================================
  Widget _buildUrgentAssignmentSpotlightSection(BuildContext context, bool isDark) {
    return UrgentAssignmentSpotlight(
      assignment: _pendingAssignments.first,
      pendingCount: _pendingAssignments.length,
      isDark: isDark,
      student: widget.student,
      onNavigateTab: widget.onNavigateTab,
      onRefresh: () => _loadDashboard(),
    );
  }

  // ==========================================
  // 7. AKTIVITAS HARI INI & JADWAL MENDATANG (SMART DAY SKIP & CAROUSEL)
  // ==========================================
  Widget _buildTodayActivitiesSection(BuildContext context, bool isDark) {
    final now = DateTime.now();
    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';

    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Tentukan mode tampilan: Jika hari ini tidak ada kuliah, lewati & langsung tampilkan jadwal mendatang!
    final bool isShowingUpcoming = _scheduleViewMode == 1 || !_todayHasClasses;
    final List<Course> displayCourses = isShowingUpcoming ? _upcomingCourses : _todayCourses;
    final String currentDayLabel = isShowingUpcoming
        ? (_nextActiveDayLabel.isNotEmpty ? _nextActiveDayLabel : 'Mendatang')
        : todayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bar: Title, Badge, & Lihat Semua
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  isShowingUpcoming ? 'Jadwal Kuliah Mendatang' : 'Aktivitas Kuliah Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B3358) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    currentDayLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFA78BFA) : AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            ScaleButton(
              scaleDown: 0.92,
              onTap: () => widget.onNavigateTab(1), // Jadwal
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Subtitle / Smart Day-Skip Notification / Tab Switcher
        if (!_todayHasClasses) ...[
          // Hari ini tidak ada perkuliahan -> hari kosong dilewati secara cerdas!
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Hari ini libur • Jadwal kosong dilewati, menampilkan $_nextActiveDayLabel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_upcomingCourses.isNotEmpty) ...[
          // Hari ini ada kuliah, dan ada juga jadwal aktif hari berikutnya -> berikan switcher
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _buildSchedulePillButton(
                  title: 'Hari Ini (${_todayCourses.length})',
                  isSelected: _scheduleViewMode == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _scheduleViewMode = 0),
                ),
                const SizedBox(width: 8),
                _buildSchedulePillButton(
                  title: 'Mendatang • $_nextActiveDayName (${_upcomingCourses.length})',
                  isSelected: _scheduleViewMode == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _scheduleViewMode = 1),
                ),
              ],
            ),
          ),
        ],

        // Horizontal Carousel Jadwal Kuliah Real-Time
        SizedBox(
          height: 142,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              if (displayCourses.isEmpty)
                _buildFreeDayHorizontalCard(isDark)
              else
                ...displayCourses.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCourseHorizontalCard(
                        c,
                        isDark,
                        isUpcomingDay: isShowingUpcoming,
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePillButton({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      scaleDown: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF383254) : const Color(0xFFE2E8F0)),
            width: 0.9,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHorizontalCard(
    Course course,
    bool isDark, {
    bool isUpcomingDay = false,
  }) {
    final now = DateTime.now();
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';
    final isToday = !isUpcomingDay && (course.hari.trim().toLowerCase() == todayName.toLowerCase());

    // Hitung status waktu kelas (Sedang berlangsung vs Dimulai segera)
    bool isLiveNow = false;
    bool isUpcomingSoon = false;
    int minutesUntilStart = 0;

    if (isToday && !course.isCancelledToday) {
      try {
        final startParts = course.effectiveJamMulai.split(':');
        final endParts = course.effectiveJamSelesai.split(':');
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
    }

    final String timeBadgeLabel = course.isCancelledToday
        ? 'DITIADAKAN'
        : (isLiveNow
            ? 'BERLANGSUNG'
            : (isUpcomingSoon
                ? '$minutesUntilStart MNT LAGI'
                : (isToday
                    ? '${course.effectiveJamMulai} - ${course.effectiveJamSelesai}'
                    : '${course.hari} • ${course.effectiveJamMulai} - ${course.effectiveJamSelesai}')));

    final bool hasOverride = course.hasActiveOverride;
    final Color activeBorder = course.isCancelledToday
        ? const Color(0xFFEF4444)
        : (hasOverride
            ? const Color(0xFFF59E0B)
            : (isLiveNow
                ? const Color(0xFF10B981)
                : (isUpcomingSoon ? const Color(0xFFF59E0B) : borderColor)));

    return Semantics(
      button: true,
      label: 'Kuliah ${course.nama}, Dosen ${course.dosen}, Ruangan ${course.effectiveRuangan}',
      child: ScaleButton(
        scaleDown: 0.98,
        onTap: () {
          ScheduleScreen.showCourseDetail(
            context,
            course,
            canManage: widget.student.isKetuaKelas || widget.student.isAdmin,
            onCourseUpdated: () => _loadDashboard(),
          );
        },
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activeBorder,
              width: (isLiveNow || isUpcomingSoon || hasOverride) ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLiveNow
                    ? const Color(0xFF10B981).withValues(alpha: 0.16)
                    : (isUpcomingSoon || hasOverride
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                        : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.04)),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Waktu & Badge Live/Upcoming/Override
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: course.isCancelledToday
                          ? (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEE2E2))
                          : (isLiveNow
                              ? (isDark ? const Color(0xFF0F392B) : const Color(0xFFDCFCE7))
                              : (hasOverride || isUpcomingSoon
                                  ? (isDark ? const Color(0xFF3D2E14) : const Color(0xFFFEF3C7))
                                  : (isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE)))),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: course.isCancelledToday
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : (isLiveNow
                                ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                                : (hasOverride || isUpcomingSoon
                                    ? const Color(0xFFD97706).withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.2))),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (course.isCancelledToday) ...[
                          const Icon(Icons.cancel_rounded, size: 11, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                        ] else if (isLiveNow) ...[
                          AnimatedBuilder(
                            animation: _livePulseAnimation,
                            builder: (context, child) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: _livePulseAnimation.value),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(alpha: _livePulseAnimation.value * 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Icon(
                            hasOverride
                                ? Icons.edit_calendar_rounded
                                : (isUpcomingSoon ? Icons.access_time_rounded : Icons.schedule_rounded),
                            size: 11,
                            color: course.isCancelledToday
                                ? const Color(0xFFDC2626)
                                : (hasOverride || isUpcomingSoon
                                    ? const Color(0xFFB45309)
                                    : AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          timeBadgeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                            color: course.isCancelledToday
                                ? const Color(0xFFDC2626)
                                : (isLiveNow
                                    ? const Color(0xFF15803D)
                                    : (hasOverride || isUpcomingSoon
                                        ? const Color(0xFFB45309)
                                        : AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          course.isOnlineOverride
                              ? Icons.videocam_rounded
                              : Icons.meeting_room_outlined,
                          size: 11,
                          color: course.isOnlineOverride ? const Color(0xFF2563EB) : textSub,
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            course.isCancelledToday
                                ? 'Libur'
                                : (course.effectiveRuangan.isNotEmpty
                                    ? course.effectiveRuangan
                                    : 'Lab A'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: course.isOnlineOverride ? const Color(0xFF2563EB) : textSub,
                            ),
                          ),
                        ),
                      ],
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${course.dosen} • ${course.sks} SKS',
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
                    ScaleButton(
                      scaleDown: 0.92,
                      onTap: () => _openWhatsAppDosen(course.dosenWa!, course.dosen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFF25D366).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
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
                                fontWeight: FontWeight.w800,
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
                    ScaleButton(
                      scaleDown: 0.92,
                      onTap: () => _openVirtualClass(course.linkVirtual!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF0284C7)),
                            SizedBox(width: 4),
                            Text(
                              'Virtual Meet',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242232) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded, size: 13, color: textSub),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeDayHorizontalCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.beach_access_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hari Bebas Kuliah',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tidak ada jadwal aktif. Waktunya istirahat atau cicil tugas!',
                  style: TextStyle(fontSize: 11, color: textSub, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. BANNER PENGUMUMAN (COLLEGIATE CAMPUS MEMO)
  // ==========================================
  Widget _buildAnnouncementBanner(BuildContext context, bool isDark) {
    final item = _announcement;
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Semantics(
      button: true,
      label: 'Pengumuman Terkini: ${item?.judul ?? 'Belum ada pengumuman'}',
      child: ScaleButton(
        scaleDown: 0.98,
        onTap: () => widget.onNavigateTab(7), // Tab Pengumuman
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF381D26) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF5A222B) : const Color(0xFFFECACA),
                    width: 0.8,
                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4C222E) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item?.kategori.toUpperCase() ?? 'INFO KELAS',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Semua',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item?.judul ?? 'Belum ada pengumuman terbaru',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item?.isi ?? 'Informasi penting dari koordinator kelas atau dosen akan tampil di sini.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textSub,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    MoreServicesModal.show(
      context,
      isDark: isDark,
      student: widget.student,
      onNavigateTab: widget.onNavigateTab,
    );
  }
}

typedef _ServiceItem = ServiceItem;
