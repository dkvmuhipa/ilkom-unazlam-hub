import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/safe_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sound_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/saas_components.dart';
import '../../core/widgets/scale_button.dart';
import '../../core/services/student_dashboard_service.dart';
import '../../core/widgets/universal_search_modal.dart';
import '../../models/models.dart';
import '../../core/services/notification_state.dart';
import '../attendance/attendance_screen.dart';
import '../schedule/schedule_screen.dart';
import '../schedule/widgets/lecturer_reminder_modal.dart';
import 'models/dashboard_models.dart';
import 'widgets/daily_briefing_broadcast_modal.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/more_services_modal.dart';
import 'widgets/urgent_assignment_spotlight.dart';
import '../profile/widgets/edit_profile_modal.dart';

class StudentHomeScreen extends StatefulWidget {
  final StudentProfile student;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback? onOpenDrawer;
  final ValueChanged<StudentProfile>? onProfileUpdated;

  const StudentHomeScreen({
    super.key,
    required this.student,
    required this.onNavigateTab,
    this.onOpenDrawer,
    this.onProfileUpdated,
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
  final PageController _coursePageController = PageController();
  int _currentCoursePage = 0;
  bool? _isKasLunas;
  int _kasNominal = 0;
  String _currentPeriodLabel = '';
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  String? _loadError;
  RealtimeChannel? _overridesChannel;
  RealtimeChannel? _coursesChannel;
  RealtimeChannel? _announcementsChannel;
  RealtimeChannel? _assignmentsChannel;
  RealtimeChannel? _studentAssignmentsChannel;

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
    _initRealtimeSubscriptions();
    NotificationState.revision.addListener(_refreshUnreadBadge);
  }

  @override
  void didUpdateWidget(covariant StudentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.nim != widget.student.nim ||
        oldWidget.student.agama != widget.student.agama) {
      _loadDashboard();
    } else if (oldWidget.student.avatarUrl != widget.student.avatarUrl ||
        oldWidget.student.nama != widget.student.nama ||
        oldWidget.student.namaPanggilan != widget.student.namaPanggilan) {
      setState(() {});
    }
  }

  void _initRealtimeSubscriptions() {
    _overridesChannel = SupabaseRepository.subscribeToCourseOverrides(() {
      if (mounted) _loadDashboard(silent: true);
    });
    _coursesChannel = SupabaseRepository.subscribeToCourses(() {
      if (mounted) _loadDashboard(silent: true);
    });
    _announcementsChannel = SupabaseRepository.subscribeToAnnouncements(() {
      if (mounted) {
        SoundService.playNotificationSound();
        debugPrint(
          '⚡ [StudentHome] Pengumuman baru terdeteksi, memuat ulang dashboard...',
        );
        _loadDashboard(silent: true);
      }
    });
    _assignmentsChannel = SupabaseRepository.subscribeToAssignments(() {
      if (mounted) {
        SoundService.playNotificationSound();
        _loadDashboard(silent: true);
      }
    });
    _studentAssignmentsChannel =
        SupabaseRepository.subscribeToStudentAssignments(() {
          if (mounted) _loadDashboard(silent: true);
        });
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_overridesChannel);
    SupabaseRepository.unsubscribeChannel(_coursesChannel);
    SupabaseRepository.unsubscribeChannel(_announcementsChannel);
    SupabaseRepository.unsubscribeChannel(_assignmentsChannel);
    SupabaseRepository.unsubscribeChannel(_studentAssignmentsChannel);
    NotificationState.revision.removeListener(_refreshUnreadBadge);
    _coursePageController.dispose();
    _livePulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshUnreadBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'notif_${widget.student.nim}_';
    final hidden = {
      ...prefs.getStringList('${prefix}read_ids') ?? <String>[],
      ...prefs.getStringList('${prefix}dismissed_ids') ?? <String>[],
    };
    var count =
        _announcement != null &&
            !hidden.contains('announcement_${_announcement!.id}')
        ? 1
        : 0;
    count += _pendingAssignments
        .where(
          (item) =>
              item.deadline.difference(DateTime.now()).inHours <= 72 &&
              !hidden.contains('assignment_${item.id}'),
        )
        .length;
    if (mounted) setState(() => _unreadNotificationCount = count);
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      try {
        final freshStudent = await AuthService.fetchStudentByNim(widget.student.nim);
        if (freshStudent != null && mounted) {
          widget.student.avatarUrl = freshStudent.avatarUrl;
          widget.student.nama = freshStudent.nama;
          widget.student.email = freshStudent.email;
          widget.student.noWa = freshStudent.noWa;
          widget.student.bio = freshStudent.bio;
          widget.student.namaPanggilan = freshStudent.namaPanggilan;
        }
      } catch (e) {
        debugPrint('Info: Gagal refresh profil mahasiswa di beranda: $e');
      }
      try {
        await AttendanceScreen.syncActiveSessionFromCloud();
      } catch (e) {
        debugPrint('Info: Gagal sinkronisasi sesi presensi aktif: $e');
      }
      final snapshot = await StudentDashboardService.load(
        widget.student.nim,
        studentAgama: widget.student.agama,
      );
      if (!mounted) return;

      // Ambil id notifikasi yang sudah dibaca / di-dismiss oleh mahasiswa
      final prefs = await SharedPreferences.getInstance();
      final storageKeyPrefix = 'notif_${widget.student.nim}_';
      final readIds = (prefs.getStringList('${storageKeyPrefix}read_ids') ?? [])
          .toSet();
      final dismissedIds =
          (prefs.getStringList('${storageKeyPrefix}dismissed_ids') ?? [])
              .toSet();

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

      if (!mounted) return;
      setState(() {
        _loadError = null;
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
        _loadError =
            'Data beranda gagal dimuat. Periksa koneksi lalu coba lagi.';
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

  void _openLecturerReminder(Course course) {
    LecturerReminderModal.show(
      context,
      course: course,
      senderName: widget.student.nama,
    );
  }

  Future<void> _openVirtualClass(String url) async {
    await safeLaunchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = widget.student;

    final hadir = _attendance
        .where((row) => '${row['status']}'.toLowerCase() == 'hadir')
        .length;
    final attendancePercent = _attendance.isEmpty
        ? null
        : (hadir * 100 / _attendance.length).round();

    final bgColor = isDark ? const Color(0xFF111018) : const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadDashboard(silent: true),
          child: _isLoading
              ? _buildShimmerLoading(context, isDark)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      children: [
                        // 1. Top Bar Bersih & Terpadu (Avatar + Halo + Search + Notif)
                        FadeSlideEntrance(
                          delay: Duration.zero,
                          child: _buildUnifiedTopBar(context, student, isDark),
                        ),
                        const SizedBox(height: 14),

                        // 2. Banner Presensi Aktif (Hanya muncul jika ada sesi QR berlangsung)
                        if (AttendanceScreen.currentSession != null &&
                            !AttendanceScreen.currentSession!.isExpired) ...[
                          FadeSlideEntrance(
                            delay: const Duration(milliseconds: 50),
                            child: _buildDynamicPriorityCard(
                              context,
                              student,
                              isDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 3. Ringkasan Akademik & Jadwal Kuliah Terpadu
                        FadeSlideEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: _buildUnifiedAcademicScheduleCard(
                            context,
                            student,
                            attendancePercent,
                            hadir,
                            isDark,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 5. Grid 8 Layanan Akademik Minimalis
                        FadeSlideEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: _buildServicesGrid(context, student, isDark),
                        ),
                        const SizedBox(height: 18),

                        // 6. Hero Banner Carousel
                        FadeSlideEntrance(
                          delay: const Duration(milliseconds: 250),
                          child: _buildHeroBannerCarousel(),
                        ),
                        const SizedBox(height: 18),

                        // 7. Error Alert jika gagal fetch
                        if (_loadError != null) ...[
                          _buildLoadError(isDark),
                          const SizedBox(height: 14),
                        ],

                        // 8. WIDGET TUGAS MENDESAK & COUNTDOWN DEADLINE (Paket C)
                        if (_pendingAssignments.isNotEmpty) ...[
                          FadeSlideEntrance(
                            delay: const Duration(milliseconds: 300),
                            child: _buildUrgentAssignmentSpotlightSection(
                              context,
                              isDark,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 9. Banner Pengumuman Terkini
                        FadeSlideEntrance(
                          delay: const Duration(milliseconds: 350),
                          child: _buildAnnouncementBanner(context, isDark),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP BAR BERSIH & TERPADU (MINIMALIST SWISS STYLE)
  // ==========================================
  Widget _buildUnifiedTopBar(
    BuildContext context,
    StudentProfile student,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1A1829) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final displayName = student.greetingName;
    final timeCtx = _getTimeContext();
    final greeting = timeCtx['greeting'] ?? 'Halo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Profil Mahasiswa dengan Status Online
          ScaleButton(
            scaleDown: 0.92,
            onTap: () => widget.onNavigateTab(4), // Profil
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SaaSAvatar(
                  name: student.nama,
                  avatarUrl: student.avatarUrl,
                  size: 42,
                  radius: 13,
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
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
          const SizedBox(width: 10),

          // Identitas Mahasiswa & Salam (Ketuk untuk sesuaikan nama sapaan)
          Expanded(
            child: ScaleButton(
              scaleDown: 0.98,
              onTap: () {
                EditProfileModal.showGreetingNamePicker(
                  context,
                  student: student,
                  isDark: isDark,
                  onSaved: (newName) {
                    if (mounted) {
                      setState(() {
                        student.namaPanggilan = newName;
                      });
                    }
                    widget.onProfileUpdated?.call(student);
                  },
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 210;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$greeting 👋',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSub,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: textMain,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: textSub.withValues(alpha: 0.65),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          'S1 Ilmu Komunikasi • Smt ${student.semester}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }

                  // Tampilan luas (tablet / desktop)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$greeting, $displayName 👋',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: textSub.withValues(alpha: 0.65),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'S1 Ilmu Komunikasi • Smt ${student.semester}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action 1: Search Button
          ScaleButton(
            scaleDown: 0.92,
            onTap: () => UniversalSearchModal.show(
              context,
              onNavigateTab: widget.onNavigateTab,
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262438) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 19,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Action 2: Notifications Bell Button
          ScaleButton(
            scaleDown: 0.92,
            onTap: () => widget.onNavigateTab(7), // Pengumuman / Notif
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262438) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _unreadNotificationCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 19,
                    color: _unreadNotificationCount > 0
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
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
  // 2. DYNAMIC PRIORITY CARD (NOW & NEXT - KONSEP 1)
  // ==========================================
  Widget _buildDynamicPriorityCard(
    BuildContext context,
    StudentProfile student,
    bool isDark,
  ) {
    final session = AttendanceScreen.currentSession;
    final bool hasLiveSession = session != null && !session.isExpired;

    // KASUS 1: Sesi Presensi Sedang Berlangsung (Prioritas Tertinggi)
    if (hasLiveSession) {
      final attended = session.attendedNims.contains(student.nim);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9)
                  .withValues(alpha: isDark ? 0.4 : 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _livePulseAnimation,
                        builder: (context, child) => Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34D399).withValues(
                                  alpha:
                                      0.4 * _livePulseAnimation.value + 0.3,
                                ),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Sesi Sedang Berlangsung',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Sisa ${session.remainingSeconds ~/ 60} mnt',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.courseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Presensi kelas perkuliahan aktif sekarang',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    attended
                        ? 'Kamu sudah terdata hadir 🎉'
                        : 'Presensi belum dicatat',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: attended
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFDE68A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded,
                              size: 15, color: Color(0xFF1E1035)),
                          SizedBox(width: 5),
                          Text(
                            'Scan QR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E1035),
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Kelola QR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }


  // ==========================================
  // 3. RINGKASAN AKADEMIK & JADWAL KULIAH TERPADU
  // ==========================================
  Widget _buildUnifiedAcademicScheduleCard(
    BuildContext context,
    StudentProfile student,
    int? attendancePercent,
    int hadirCount,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 120) {
          return const SizedBox.shrink();
        }

        final isEligible = attendancePercent != null && attendancePercent >= 75;
        final cardBg = isDark ? const Color(0xFF141224) : Colors.white;
        final borderColor = isDark
            ? const Color(0xFF2C2844)
            : const Color(0xFFE2E8F0);
        final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
        final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        final now = DateTime.now();
        const dayNames = [
          '',
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu',
        ];
        final todayName = (now.weekday >= 1 && now.weekday <= 7)
            ? dayNames[now.weekday]
            : '';

        // Tentukan mode tampilan: Jika hari ini tidak ada kuliah, lewati & langsung tampilkan jadwal mendatang!
        final bool isShowingUpcoming = _scheduleViewMode == 1 || !_todayHasClasses;
        final List<Course> displayCourses = isShowingUpcoming
            ? _upcomingCourses
            : _todayCourses;
        final String currentDayLabel = isShowingUpcoming
            ? (_nextActiveDayLabel.isNotEmpty ? _nextActiveDayLabel : 'Mendatang')
            : todayName;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF161427), const Color(0xFF110F20)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A)
                    .withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Terpadu: Judul 'Ringkasan Akademik', Label Hari, Badge UAS, & Tombol Semua Jadwal
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ringkasan Akademik',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF26223D)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3B3358)
                                    : const Color(0xFFE2E8F0),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              currentDayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFA78BFA)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: attendancePercent == null
                        ? SoftPillBadge.neutral(
                            label: 'Presensi Baru',
                            fontSize: 9.0,
                          )
                        : (isEligible
                            ? SoftPillBadge.success(
                                label: 'UAS Aman $attendancePercent%',
                                fontSize: 9.0,
                                showDot: true,
                              )
                            : SoftPillBadge.warning(
                                label: 'Pantau Presensi $attendancePercent%',
                                fontSize: 9.0,
                                showDot: true,
                              )),
                  ),
                  const SizedBox(width: 6),
                  ScaleButton(
                    scaleDown: 0.92,
                    onTap: () => widget.onNavigateTab(1), // Buka Tab Jadwal
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Divider Tipis Elegan
              Container(
                height: 1,
                color: borderColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),

              // Body Row: Status Kehadiran/Kas (Kiri) & 4 Studio Controls (Kanan)
              Row(
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
                            // Persentase & Status Sesi
                            Row(
                              children: [
                                Text(
                                  attendancePercent == null
                                      ? '0%'
                                      : '$attendancePercent%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    attendancePercent == null
                                        ? 'Belum Ada Sesi'
                                        : '$hadirCount Sesi Hadir',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSub,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Progress Bar Presensi UAS
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: attendancePercent == null
                                    ? 0.0
                                    : (attendancePercent / 100).clamp(0.0, 1.0),
                                minHeight: 4.5,
                                backgroundColor: isDark
                                    ? const Color(0xFF26223D)
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (attendancePercent ?? 0) >= 75
                                      ? const Color(0xFF10B981)
                                      : ((attendancePercent ?? 0) >= 60
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Status Iuran Kas Kelas (Real Data)
                            ScaleButton(
                              scaleDown: 0.95,
                              onTap: () => widget.onNavigateTab(8), // Buka Kas
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1A34)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2E274A)
                                        : const Color(0xFFE2E8F0),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isKasLunas == true
                                          ? Icons.verified_rounded
                                          : (_isKasLunas == false
                                              ? Icons.error_rounded
                                              : Icons.account_balance_wallet_rounded),
                                      size: 11.5,
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
                                            ? 'Kas: Lunas ✨'
                                            : (_isKasLunas == false
                                                ? 'Kas: ${_formatCurrency(_kasNominal)}'
                                                : (_currentPeriodLabel.isNotEmpty
                                                    ? 'Iuran: $_currentPeriodLabel'
                                                    : 'Cek status kas')),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: _isKasLunas == true
                                              ? (isDark
                                                  ? const Color(0xFF4ADE80)
                                                  : const Color(0xFF059669))
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Divider Vertikal Elegan
                  Container(
                    height: 54,
                    width: 1,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),

                  // Sisi Kanan: 4 Aksi Cepat Studio Deck (Presensi, Kas, KHS, Izin)
                  Expanded(
                    flex: 7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildGojekActionItem(
                            icon: Icons.qr_code_scanner_rounded,
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
                            icon: Icons.analytics_rounded,
                            label: 'KHS',
                            color: AppColors.primary,
                            textColor: textMain,
                            onTap: () => widget.onNavigateTab(
                              15,
                            ), // KHS & Transkrip Nilai (Tab 15)
                          ),
                        ),
                        Expanded(
                          child: _buildGojekActionItem(
                            icon: Icons.assignment_turned_in_rounded,
                            label: 'Izin',
                            color: AppColors.rose,
                            textColor: textMain,
                            onTap: () => widget.onNavigateTab(
                              13,
                            ), // Surat Izin & Dispensasi (Tab 13)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Divider Pemisah Elegan antara Ringkasan dan Jadwal
              const SizedBox(height: 10),
              Container(
                height: 1,
                color: borderColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),

              // Subtitle / Smart Day-Skip Notification / Tab Switcher
              if (!_todayHasClasses) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Hari ini libur • Jadwal kosong dilewati, menampilkan $_nextActiveDayLabel',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (_upcomingCourses.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _buildSchedulePillButton(
                        title: 'Hari Ini (${_todayCourses.length})',
                        isSelected: _scheduleViewMode == 0,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _scheduleViewMode = 0;
                            _currentCoursePage = 0;
                          });
                          if (_coursePageController.hasClients) {
                            _coursePageController.jumpToPage(0);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildSchedulePillButton(
                        title:
                            'Mendatang • $_nextActiveDayName (${_upcomingCourses.length})',
                        isSelected: _scheduleViewMode == 1,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _scheduleViewMode = 1;
                            _currentCoursePage = 0;
                          });
                          if (_coursePageController.hasClients) {
                            _coursePageController.jumpToPage(0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Course Horizontal Slider / Single Card / Free Day Card (Pas di dalam kartu, tidak keluar tepi)
              SizedBox(
                height: (142 * MediaQuery.textScalerOf(context).scale(1.0)).clamp(142.0, 185.0),
                child: displayCourses.isEmpty
                    ? _buildFreeDayHorizontalCard(isDark, isFullWidth: true)
                    : (displayCourses.length == 1
                        ? _buildCourseHorizontalCard(
                            displayCourses.single,
                            isDark,
                            isUpcomingDay: isShowingUpcoming,
                            isFullWidth: true,
                          )
                        : PageView.builder(
                            controller: _coursePageController,
                            itemCount: displayCourses.length,
                            onPageChanged: (idx) {
                              setState(() => _currentCoursePage = idx);
                            },
                            itemBuilder: (context, index) {
                              return _buildCourseHorizontalCard(
                                displayCourses[index],
                                isDark,
                                isUpcomingDay: isShowingUpcoming,
                                isFullWidth: true,
                              );
                            },
                          )),
              ),
              if (displayCourses.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Kuliah ${(_currentCoursePage + 1).clamp(1, displayCourses.length)} dari ${displayCourses.length} • Geser untuk lainnya',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(displayCourses.length, (i) {
                        final isSelected = i == _currentCoursePage;
                        return ScaleButton(
                          scaleDown: 0.9,
                          onTap: () {
                            if (_coursePageController.hasClients) {
                              _coursePageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: isSelected ? 16 : 6,
                            height: 5.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? const Color(0xFF383254)
                                      : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              _buildAcademicUrgencyRadarFooter(
                context,
                student,
                displayCourses,
                isShowingUpcoming,
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcademicUrgencyRadarFooter(
    BuildContext context,
    StudentProfile student,
    List<Course> displayCourses,
    bool isShowingUpcoming,
    bool isDark,
  ) {
    final overrideCount = displayCourses.where((c) => c.hasActiveOverride).length;
    final now = DateTime.now();
    final urgentTaskCount = _pendingAssignments
        .where((a) => a.deadline.difference(now).inHours <= 72 && a.deadline.isAfter(now.subtract(const Duration(hours: 2))))
        .length;

    final bool hasUrgency = overrideCount > 0 || urgentTaskCount > 0;
    final List<String> alerts = [];
    if (overrideCount > 0) {
      alerts.add('$overrideCount Perubahan Ruang/Jam');
    }
    if (urgentTaskCount > 0) {
      alerts.add('$urgentTaskCount Tugas ≤ H-3');
    }

    final String radarLabel = alerts.isNotEmpty
        ? alerts.join(' • ')
        : 'Rangkuman jadwal & tugas siap dibagikan ke kelas';

    final Color accentColor = overrideCount > 0
        ? const Color(0xFFF59E0B)
        : (urgentTaskCount > 0 ? const Color(0xFF10B981) : AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1930) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUrgency
              ? accentColor.withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF2E294A) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasUrgency ? Icons.radar_rounded : Icons.campaign_rounded,
            size: 15,
            color: accentColor,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              radarLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ScaleButton(
            scaleDown: 0.94,
            onTap: () {
              DailyBriefingBroadcastModal.show(
                context,
                student: student,
                todayCourses: _todayCourses,
                upcomingCourses: _upcomingCourses,
                nextActiveDayName: _nextActiveDayName,
                nextActiveDayLabel: _nextActiveDayLabel,
                pendingAssignments: _pendingAssignments,
                latestAnnouncement: _announcement,
                initialMode: isShowingUpcoming ? 1 : 0,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send_rounded, size: 11, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Share Info',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
                size: 34,
                iconSize: 17,
                radius: 10,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(
    BuildContext context,
    StudentProfile student,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF141224) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2C2746)
        : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final services = [
      _ServiceItem(
        title: 'Materi',
        subtitle: 'Slide & Modul',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF06B6D4), // Cyan
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
        glowColor: const Color(0xFF06B6D4),
        bgColor: isDark ? const Color(0xFF0E2533) : const Color(0xFFE0F7FA),
        tabIndex: 10, // Gudang Materi & E-Book
      ),
      _ServiceItem(
        title: 'Agenda',
        subtitle: 'Jadwal Kuliah',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF10B981), // Emerald
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
        glowColor: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF0C2B20) : const Color(0xFFE8F5E9),
        tabIndex: 6, // Agenda Kelas
      ),
      _ServiceItem(
        title: 'Kelompok',
        subtitle: 'Praktikum',
        icon: Icons.group_work_rounded,
        color: const Color(0xFF14B8A6), // Teal
        gradientColors: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
        glowColor: const Color(0xFF14B8A6),
        bgColor: isDark ? const Color(0xFF0C2B29) : const Color(0xFFE0F2F1),
        tabIndex: 9, // Kelompok Praktikum
      ),
      _ServiceItem(
        title: 'Voting',
        subtitle: 'Suara Kelas',
        icon: Icons.how_to_vote_rounded,
        color: const Color(0xFF8B5CF6), // Violet
        gradientColors: const [Color(0xFFA855F7), Color(0xFF7C3AED)],
        glowColor: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF231538) : const Color(0xFFF3E8FF),
        tabIndex: 12, // Voting & Polling
      ),
      _ServiceItem(
        title: 'Warta',
        subtitle: 'Pengumuman',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFF43F5E), // Rose
        gradientColors: const [Color(0xFFFB7185), Color(0xFFE11D48)],
        glowColor: const Color(0xFFF43F5E),
        bgColor: isDark ? const Color(0xFF2C131D) : const Color(0xFFFFE4E6),
        tabIndex: 7, // Pengumuman
        showBadge: _unreadNotificationCount > 0,
      ),
      _ServiceItem(
        title: 'Surat Izin',
        subtitle: 'Dispensasi',
        icon: Icons.mark_email_read_rounded,
        color: const Color(0xFFF59E0B), // Amber
        gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
        glowColor: const Color(0xFFF59E0B),
        bgColor: isDark ? const Color(0xFF2B2010) : const Color(0xFFFEF3C7),
        tabIndex: 13, // Surat Izin & Dispensasi
      ),
      _ServiceItem(
        title: 'Audit Log',
        subtitle: 'Rekam Jejak',
        icon: Icons.history_rounded,
        color: const Color(0xFF6366F1), // Indigo
        gradientColors: const [Color(0xFF818CF8), Color(0xFF4F46E5)],
        glowColor: const Color(0xFF6366F1),
        bgColor: isDark ? const Color(0xFF181838) : const Color(0xFFE0E7FF),
        tabIndex: 14, // Audit Log Aktivitas
      ),
      _ServiceItem(
        title: 'Lainnya',
        subtitle: 'Katalog 12+',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF64748B), // Slate
        gradientColors: const [Color(0xFF94A3B8), Color(0xFF475569)],
        glowColor: const Color(0xFF64748B),
        bgColor: isDark ? const Color(0xFF1B1B28) : const Color(0xFFF1F5F9),
        isMore: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9)
                .withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Console Dock (Minimalist & Clean)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Layanan Akademik',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Akses cepat modul perkuliahan',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: textSub,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ScaleButton(
                  scaleDown: 0.94,
                  onTap: () => _showMoreServicesModal(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1B38)
                          : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Semua',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFA5B4FC)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 8 Layanan dalam Grid Bersih Tanpa Sekat
          Row(
            children: services
                .take(4)
                .map((item) => Expanded(
                      child: _buildServiceIcon(
                        context,
                        item,
                        isDark,
                        textMain,
                        textSub,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: services
                .skip(4)
                .take(4)
                .map((item) => Expanded(
                      child: _buildServiceIcon(
                        context,
                        item,
                        isDark,
                        textMain,
                        textSub,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(
    BuildContext context,
    _ServiceItem item,
    bool isDark,
    Color textMain,
    Color textSub,
  ) {
    return Semantics(
      button: true,
      label: 'Layanan ',
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
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Modern Apple/Fintech Rounded Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.bgColor.withValues(alpha: isDark ? 0.35 : 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.color.withValues(alpha: isDark ? 0.25 : 0.15),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 22,
                      ),
                    ),
                  ),
                  if (item.showBadge)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF141224) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Title (Clean, crisp typography)
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================
  // 5B. COMPACT HERO CAROUSEL BANNER (GOJEK / TOKOPEDIA STYLE)
  // ==========================================
  Widget _buildHeroBannerCarousel() {
    final hadir = _attendance
        .where((row) => '${row['status']}'.toLowerCase() == 'hadir')
        .length;
    final attendancePercent = _attendance.isEmpty
        ? null
        : (hadir * 100 / _attendance.length).round();

    return HomeBannerCarousel(
      includeScheduleSlide: false,
      todayCourses: _todayCourses,
      upcomingCourses: _upcomingCourses,
      upcomingDayLabel: _nextActiveDayLabel,
      nextAssignment: _pendingAssignments.isEmpty
          ? null
          : _pendingAssignments.first,
      latestAnnouncement: _announcement,
      hasLoadError: _loadError != null,
      onNavigateTab: widget.onNavigateTab,
      isKasLunas: _isKasLunas,
      kasNominal: _kasNominal,
      currentPeriodLabel: _currentPeriodLabel,
      attendancePercent: attendancePercent,
    );
  }

  // ==========================================
  // 6. SPOTLIGHT TUGAS MENDESAK & DEADLINE (PAKET C)
  // ==========================================
  Widget _buildUrgentAssignmentSpotlightSection(
    BuildContext context,
    bool isDark,
  ) {
    return UrgentAssignmentSpotlight(
      assignment: _pendingAssignments.first,
      pendingCount: _pendingAssignments.length,
      isDark: isDark,
      student: widget.student,
      onNavigateTab: widget.onNavigateTab,
      onRefresh: () => _loadDashboard(),
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
    bool isFullWidth = false,
  }) {
    final now = DateTime.now();
    final cardBg = isDark ? const Color(0xFF1A1829) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    const dayNames = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final todayName = (now.weekday >= 1 && now.weekday <= 7)
        ? dayNames[now.weekday]
        : '';
    final isToday =
        !isUpcomingDay &&
        (course.hari.trim().toLowerCase() == todayName.toLowerCase());

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
                    : (isUpcomingSoon
                          ? const Color(0xFFF59E0B)
                          : borderColor)));

    return Semantics(
      button: true,
      label:
          'Kuliah ${course.nama}, Dosen ${course.dosen}, Ruangan ${course.effectiveRuangan}',
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
          width: isFullWidth ? double.infinity : 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
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
                          : const Color(0xFF0F172A)
                                .withValues(alpha: isDark ? 0.25 : 0.04)),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: course.isCancelledToday
                          ? (isDark
                                ? const Color(0xFF3B1E1E)
                                : const Color(0xFFFEE2E2))
                          : (isLiveNow
                                ? (isDark
                                      ? const Color(0xFF0F392B)
                                      : const Color(0xFFDCFCE7))
                                : (hasOverride || isUpcomingSoon
                                      ? (isDark
                                            ? const Color(0xFF3D2E14)
                                            : const Color(0xFFFEF3C7))
                                      : (isDark
                                            ? const Color(0xFF2B2144)
                                            : const Color(0xFFEDE9FE)))),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: course.isCancelledToday
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : (isLiveNow
                                  ? const Color(0xFF16A34A)
                                        .withValues(alpha: 0.3)
                                  : (hasOverride || isUpcomingSoon
                                        ? const Color(0xFFD97706)
                                              .withValues(alpha: 0.3)
                                        : AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ))),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (course.isCancelledToday) ...[
                          const Icon(
                            Icons.cancel_rounded,
                            size: 11,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                        ] else if (isLiveNow) ...[
                          AnimatedBuilder(
                            animation: _livePulseAnimation,
                            builder: (context, child) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF16A34A,
                                ).withValues(alpha: _livePulseAnimation.value),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(
                                      alpha: _livePulseAnimation.value * 0.5,
                                    ),
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
                                : (isUpcomingSoon
                                      ? Icons.access_time_rounded
                                      : Icons.schedule_rounded),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF242232)
                          : const Color(0xFFF1F5F9),
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
                          color: course.isOnlineOverride
                              ? const Color(0xFF2563EB)
                              : textSub,
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
                              color: course.isOnlineOverride
                                  ? const Color(0xFF2563EB)
                                  : textSub,
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (course.dosen.trim().isNotEmpty) ...[
                            ScaleButton(
                              scaleDown: 0.92,
                              onTap: () => _openLecturerReminder(course),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366)
                                      .withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFF25D366)
                                        .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 12,
                                      color: Color(0xFF16A34A),
                                    ),
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
                          if (course.linkVirtual != null &&
                              course.linkVirtual!.trim().isNotEmpty) ...[
                            ScaleButton(
                              scaleDown: 0.92,
                              onTap: () =>
                                  _openVirtualClass(course.linkVirtual!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 12,
                                      color: Color(0xFF0284C7),
                                    ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF242232)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeDayHorizontalCard(bool isDark, {bool isFullWidth = false}) {
    final cardBg = isDark ? const Color(0xFF1A1829) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: isFullWidth ? double.infinity : 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2144) : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hari Bebas Kuliah',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.0,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada jadwal aktif. Waktunya istirahat atau cicil tugas!',
                  style: TextStyle(fontSize: 10.5, color: textSub, height: 1.2),
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
    final cardBg = isDark ? const Color(0xFF1A1829) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFE2E8F0);
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
                color: const Color(0xFF0F172A)
                    .withValues(alpha: isDark ? 0.25 : 0.04),
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
                  color: isDark
                      ? const Color(0xFF381D26)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF5A222B)
                        : const Color(0xFFFECACA),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF4C222E)
                                : const Color(0xFFFEE2E2),
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
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
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
    final shimmerBase = isDark
        ? const Color(0xFF222030)
        : const Color(0xFFE2E8F0);

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
            _buildShimmerBox(
              width: 60,
              height: 26,
              radius: 10,
              color: shimmerBase,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search Bar Skeleton
        _buildShimmerBox(
          width: double.infinity,
          height: 46,
          radius: 28,
          color: shimmerBase,
        ),
        const SizedBox(height: 14),

        // Academic Wallet Skeleton
        _buildShimmerBox(
          width: double.infinity,
          height: 76,
          radius: 20,
          color: shimmerBase,
        ),
        const SizedBox(height: 18),

        // 8 Services Grid Skeleton
        _buildShimmerBox(
          width: double.infinity,
          height: 160,
          radius: 22,
          color: shimmerBase,
        ),
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
              _buildShimmerBox(
                width: 250,
                height: 134,
                radius: 18,
                color: shimmerBase,
              ),
              const SizedBox(width: 12),
              _buildShimmerBox(
                width: 250,
                height: 134,
                radius: 18,
                color: shimmerBase,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Announcement Banner Skeleton
        _buildShimmerBox(
          width: double.infinity,
          height: 80,
          radius: 20,
          color: shimmerBase,
        ),
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
