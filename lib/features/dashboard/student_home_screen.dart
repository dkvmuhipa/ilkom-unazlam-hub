import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_dashboard_service.dart';
import '../../core/widgets/scale_button.dart';
import '../../models/models.dart';
import '../attendance/attendance_screen.dart';
import 'widgets/home_academic_bento.dart';
import 'widgets/home_announcement_section.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/home_header_bar.dart';
import 'widgets/home_live_attendance_banner.dart';
import 'widgets/home_schedule_section.dart';
import 'widgets/home_services_grid.dart';
import 'widgets/home_shimmer_loading.dart';
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
  bool? _isKasLunas;
  int _kasNominal = 0;
  String _currentPeriodLabel = '';
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  String? _loadError;

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
  }

  @override
  void dispose() {
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

      // Hitung notifikasi yang belum dibaca
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = widget.student;

    final hadir = _attendance.where((row) => '${row['status']}'.toLowerCase() == 'hadir').length;
    final attendancePercent =
        _attendance.isEmpty ? null : (hadir * 100 / _attendance.length).round();

    final bgColor = isDark ? const Color(0xFF111018) : const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: _isLoading
              ? HomeShimmerLoading(isDark: isDark)
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. Executive Top Header (Greeting, Avatar, Notification & Search Bar)
                    FadeSlideEntrance(
                      delay: Duration.zero,
                      child: HomeHeaderBar(
                        student: student,
                        isDark: isDark,
                        unreadNotificationCount: _unreadNotificationCount,
                        onNavigateTab: widget.onNavigateTab,
                        onOpenDrawer: widget.onOpenDrawer,
                        livePulseAnimation: _livePulseAnimation,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Error Alert jika gagal fetch
                    if (_loadError != null) ...[
                      _buildLoadError(isDark),
                      const SizedBox(height: 14),
                    ],

                    // 3. Live Attendance Session Banner (1-Tap Scan QR) & Officer Shortcut
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 50),
                      child: HomeLiveAttendanceBanner(
                        student: student,
                        isDark: isDark,
                        onRefresh: _loadDashboard,
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Campus Academic Pulse Bento (Presensi, Kas, Kuliah Hari Ini, Tugas)
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 100),
                      child: HomeAcademicBento(
                        attendancePercent: attendancePercent,
                        hadirCount: hadir,
                        totalAttendance: _attendance.length,
                        isKasLunas: _isKasLunas,
                        kasNominal: _kasNominal,
                        currentPeriodLabel: _currentPeriodLabel,
                        todayCoursesCount: _todayCourses.length,
                        todayClassesFinished: _todayClassesFinished,
                        pendingAssignmentsCount: _pendingAssignments.length,
                        isDark: isDark,
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. 8 Campus Services Grid
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 150),
                      child: HomeServicesGrid(
                        student: student,
                        isDark: isDark,
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6. Hero Carousel Banner
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: HomeBannerCarousel(
                        isDark: isDark,
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 7. Spotlight Tugas Mendesak (jika ada tugas pending)
                    if (_pendingAssignments.isNotEmpty) ...[
                      FadeSlideEntrance(
                        delay: const Duration(milliseconds: 250),
                        child: UrgentAssignmentSpotlight(
                          assignment: _pendingAssignments.first,
                          pendingCount: _pendingAssignments.length,
                          isDark: isDark,
                          student: student,
                          onNavigateTab: widget.onNavigateTab,
                          onRefresh: _loadDashboard,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // 8. Jadwal Kuliah & Aktivitas Hari Ini
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 300),
                      child: HomeScheduleSection(
                        todayCourses: _todayCourses,
                        upcomingCourses: _upcomingCourses,
                        nextActiveDayName: _nextActiveDayName,
                        nextActiveDayLabel: _nextActiveDayLabel,
                        todayHasClasses: _todayHasClasses,
                        todayClassesFinished: _todayClassesFinished,
                        isDark: isDark,
                        student: student,
                        livePulseAnimation: _livePulseAnimation,
                        onRefresh: _loadDashboard,
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 9. Warta & Pengumuman Kampus Terkini
                    FadeSlideEntrance(
                      delay: const Duration(milliseconds: 350),
                      child: HomeAnnouncementSection(
                        announcement: _announcement,
                        isDark: isDark,
                        onNavigateTab: widget.onNavigateTab,
                        onRefresh: _loadDashboard,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError ?? 'Terjadi kesalahan.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: const Color(0xFFEF4444),
            onPressed: _loadDashboard,
          ),
        ],
      ),
    );
  }
}
