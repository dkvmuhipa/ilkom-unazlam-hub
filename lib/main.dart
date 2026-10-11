import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/services/supabase_service.dart';
import 'core/services/supabase_repository.dart';
import 'core/services/auth_service.dart';
import 'core/services/auth_callback_url.dart';
import 'core/services/fcm_service.dart';
import 'features/dashboard/student_home_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/assignments/assignments_screen.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/announcements/announcements_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/resources/resources_screen.dart';
import 'features/directory/directory_screen.dart';
import 'features/treasury/treasury_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/invite_accept_screen.dart';
import 'features/notifications/notification_screen.dart';
import 'features/voting/voting_screen.dart';
import 'features/letters/letters_screen.dart';
import 'features/audit/audit_log_screen.dart';
import 'features/gpa/academic_grades_screen.dart';

import 'features/admin/admin_shell_screen.dart';
import 'core/services/dummy_data.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase invitation links return to the site with the auth type in the URL
  // fragment. Capture it before Supabase consumes the callback URL.
  final authCallback = _getInitialAuthCallback();

  // Inisialisasi format tanggal lokal Indonesia
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Gagal inisialisasi locale id_ID: $e');
  }

  // Inisialisasi Supabase
  await SupabaseService.initialize();

  // Inisialisasi Firebase Cloud Messaging (FCM)
  await FcmService.initialize();

  String? authCallbackError;
  final tokenHash = authCallback.tokenHash;
  final client = SupabaseService.client;

  if (client != null &&
      tokenHash != null &&
      (authCallback.flowType == 'recovery' ||
          authCallback.flowType == 'invite')) {
    try {
      await client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: authCallback.flowType == 'invite'
            ? OtpType.invite
            : OtpType.recovery,
      );
      clearAuthCallbackUrl();
    } catch (error) {
      authCallbackError = error is AuthException
          ? 'Tautan tidak valid atau sudah kedaluwarsa. Minta tautan baru, lalu buka di aplikasi ini.'
          : 'Verifikasi tautan gagal. Periksa koneksi lalu coba lagi.';
    }
  } else if (client != null && authCallback.hasCode) {
    // If the link came from default Supabase PKCE flow (?code=...)
    try {
      if (client.auth.currentSession == null) {
        await client.auth.getSessionFromUrl(Uri.base);
      }
      clearAuthCallbackUrl();
    } catch (error) {
      if (client.auth.currentSession == null) {
        authCallbackError =
            'Tautan pemulihan tidak dapat diverifikasi di sesi browser ini. Silakan kirim ulang tautan reset password baru dari menu login.';
      }
    }
  }

  runApp(
    ClassManagerApp(
      initialAuthFlow: authCallback.flowType,
      initialAuthError: authCallbackError,
    ),
  );
}

_InitialAuthCallback _getInitialAuthCallback() {
  try {
    final uri = Uri.base;
    final fragment = Uri.splitQueryString(uri.fragment);
    final type = uri.queryParameters['type'] ?? fragment['type'];
    final tokenHash =
        uri.queryParameters['token_hash'] ?? fragment['token_hash'];
    final hasCode = uri.queryParameters.containsKey('code');
    final flowType = type == 'invite' || type == 'recovery'
        ? type
        : (tokenHash != null || hasCode ? 'recovery' : null);
    return _InitialAuthCallback(
      flowType: flowType,
      tokenHash: tokenHash,
      hasCode: hasCode,
    );
  } catch (_) {
    return const _InitialAuthCallback();
  }
}

class _InitialAuthCallback {
  final String? flowType;
  final String? tokenHash;
  final bool hasCode;

  const _InitialAuthCallback({
    this.flowType,
    this.tokenHash,
    this.hasCode = false,
  });
}

class ClassManagerApp extends StatefulWidget {
  final String? initialAuthFlow;
  final String? initialAuthError;

  const ClassManagerApp({
    super.key,
    this.initialAuthFlow,
    this.initialAuthError,
  });

  @override
  State<ClassManagerApp> createState() => _ClassManagerAppState();
}

class _ClassManagerAppState extends State<ClassManagerApp> {
  bool _showSplash = true;
  bool _isLoggedIn = false;
  String _userNim = '';
  String _userName = '';
  bool _isAdminMode = false;
  late bool _isAuthSetupFlow;
  late String? _authSetupFlowType;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _isAuthSetupFlow = widget.initialAuthFlow != null;
    _authSetupFlowType = widget.initialAuthFlow;
    if (!_isAuthSetupFlow) _restoreAuthSession();
    _authStateSubscription = SupabaseService.client?.auth.onAuthStateChange
        .listen((state) {
          if (state.event != AuthChangeEvent.passwordRecovery || !mounted)
            return;
          setState(() {
            _authSetupFlowType = 'recovery';
            _isAuthSetupFlow = true;
            _showSplash = false;
          });
        });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _onAuthSetupComplete(StudentProfile profile) {
    DummyData.students.removeWhere((student) => student.nim == profile.nim);
    DummyData.students.add(profile);
    setState(() {
      _authSetupFlowType = null;
      _isAuthSetupFlow = false;
      _showSplash = false;
      _isLoggedIn = true;
      _userNim = profile.nim;
      _userName = profile.nama;
      _isAdminMode = profile.isAdmin;
    });
  }

  Future<void> _restoreAuthSession() async {
    if (SupabaseService.client == null) return;
    final profile = await AuthService.restoreSession();
    if (profile != null && mounted) {
      DummyData.students.removeWhere((student) => student.nim == profile.nim);
      DummyData.students.add(profile);
      setState(() {
        _isLoggedIn = true;
        _userNim = profile.nim;
        _userName = profile.nama;
        _isAdminMode = profile.isAdmin;
      });
      unawaited(FcmService.syncDeviceToken(profile.nim));
    }
  }

  void _onSplashFinish() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  void _onLoginSuccess(StudentProfile profile) {
    DummyData.students.removeWhere((student) => student.nim == profile.nim);
    DummyData.students.add(profile);
    setState(() {
      _userNim = profile.nim;
      _userName = profile.nama;
      _isLoggedIn = true;
      _isAdminMode = profile.isAdmin;
    });
    unawaited(FcmService.syncDeviceToken(profile.nim));
  }

  Future<void> _onLogout() async {
    setState(() {
      _isLoggedIn = false;
      _userNim = '';
      _userName = '';
      _isAdminMode = false;
    });
    if (SupabaseService.client != null) {
      try {
        await AuthService.signOut();
      } catch (error) {
        debugPrint('Logout Supabase gagal: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeScope.notifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'ILKOM UNAZLAM Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeScope.notifier.themeMode,
          home: _isAuthSetupFlow
              ? InviteAcceptScreen(
                  flowType: _authSetupFlowType!,
                  initialError: widget.initialAuthError,
                  onSuccess: _onAuthSetupComplete,
                )
              : _showSplash
              ? SplashScreen(onFinish: _onSplashFinish)
              : (!_isLoggedIn
                    ? LoginScreen(onLoginSuccess: _onLoginSuccess)
                    : (_isAdminMode
                          ? AdminShellScreen(
                              onLogout: _onLogout,
                              onSwitchToStudentView: () =>
                                  setState(() => _isAdminMode = false),
                            )
                          : MainResponsiveShell(
                              userNim: _userNim,
                              userName: _userName,
                              isAdminUser: DummyData.students.any(
                                (student) =>
                                    student.nim == _userNim && student.isAdmin,
                              ),
                              onSwitchToAdminView: () =>
                                  setState(() => _isAdminMode = true),
                              onLogout: _onLogout,
                            ))),
        );
      },
    );
  }
}

class MainResponsiveShell extends StatefulWidget {
  final String? userNim;
  final String? userName;
  final bool isAdminUser;
  final VoidCallback? onSwitchToAdminView;
  final VoidCallback? onLogout;

  const MainResponsiveShell({
    super.key,
    this.userNim,
    this.userName,
    this.isAdminUser = false,
    this.onSwitchToAdminView,
    this.onLogout,
  });

  @override
  State<MainResponsiveShell> createState() => _MainResponsiveShellState();
}

class _MainResponsiveShellState extends State<MainResponsiveShell> {
  int _currentIndex = 0;
  final List<int> _navigationHistory = [0];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _activeNim;

  @override
  void initState() {
    super.initState();
    _activeNim = widget.userNim ?? '260250023';
    SupabaseRepository.syncAllFromCloud().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _navigateToIndex(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _navigationHistory.remove(index);
      _navigationHistory.add(index);
      _currentIndex = index;
    });
  }

  void _goBack() {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _currentIndex = _navigationHistory.last;
      });
    } else if (_currentIndex != 0) {
      setState(() {
        _navigationHistory.clear();
        _navigationHistory.add(0);
        _currentIndex = 0;
      });
    }
  }

  StudentProfile get _currentUser => DummyData.students.firstWhere(
    (student) => student.nim == _activeNim,
    orElse: () => DummyData.students.first,
  );

  @override
  Widget build(BuildContext context) {
    // Screen mappings:
    // 0: Beranda
    // 1: Jadwal
    // 2: Tugas
    // 3: Kelas (Anggota)
    // 4: Profil (Profil Saya & Ketua Kelas)
    // 5: Absensi Saya
    // 6: Agenda Kelas
    // 7: Pengumuman
    // 8: Kas Kelas
    // 9: Kelompok
    // 10: Materi
    // 11: Pusat Notifikasi
    // 12: Voting & Polling
    // 13: Surat Izin & Dispensasi
    // 14: Audit Log Aktivitas
    // 15: Transkrip Nilai & IPK
    final currentUser = _currentUser;

    final List<Widget> screens = [
      StudentHomeScreen(
        key: ValueKey('dash_${currentUser.nim}'),
        student: currentUser,
        onNavigateTab: _navigateToIndex,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 0: Beranda
      ScheduleScreen(
        key: ValueKey('schedule_${currentUser.nim}'),
        canManage: currentUser.isKetuaKelas || currentUser.isAdmin,
        onBack: _goBack,
      ), // 1: Jadwal
      AssignmentsScreen(
        key: ValueKey('assignments_${currentUser.nim}'),
        canManage: currentUser.canManageAssignments,
        userNim: currentUser.nim,
        onBack: _goBack,
      ), // 2: Tugas
      DirectoryScreen(
        key: ValueKey('directory_${currentUser.nim}'),
        canManage: currentUser.isKetuaKelas || currentUser.isAdmin,
        onBack: _goBack,
      ), // 3: Kelas (Anggota)
      ProfileScreen(
        key: ValueKey('profile_${currentUser.nim}'),
        onNavigateTab: _navigateToIndex,
        userNim: currentUser.nim,
        student: currentUser,
        onBack: _goBack,
      ), // 4: Profil Saya
      AttendanceScreen(
        key: ValueKey('attendance_${currentUser.nim}'),
        canManageClassAttendance: currentUser.canManageAttendance,
        userNim: currentUser.nim,
        onBack: _goBack,
      ), // 5: Absensi Saya
      AgendaScreen(
        key: ValueKey('agenda_${currentUser.nim}'),
        canManage: currentUser.canManageAgenda,
        onBack: _goBack,
      ), // 6: Agenda Kelas
      AnnouncementsScreen(
        key: ValueKey('announcements_${currentUser.nim}'),
        canPost: currentUser.canPostAnnouncement,
        onBack: _goBack,
      ), // 7: Pengumuman
      TreasuryScreen(
        key: ValueKey('treasury_${currentUser.nim}'),
        canManage: currentUser.canManageTreasury,
        userNim: currentUser.nim,
        userName: currentUser.nama,
        onBack: _goBack,
      ), // 8: Kas Kelas
      GroupsScreen(onBack: _goBack), // 9: Kelompok Praktikum
      ResourcesScreen(
        canManage:
            currentUser.isAdmin ||
            currentUser.isKetuaKelas ||
            currentUser.isSekretaris,
        onBack: _goBack,
      ), // 10: Gudang Materi
      NotificationScreen(
        onNavigateTab: _navigateToIndex,
        onBack: _goBack,
        studentNim: currentUser.nim,
      ), // 11: Pusat Notifikasi
      VotingScreen(
        canManage: currentUser.isKetuaKelas || currentUser.isAdmin,
        onBack: _goBack,
      ), // 12: Voting & Polling
      LettersScreen(
        studentName: currentUser.nama,
        studentNim: currentUser.nim,
        onBack: _goBack,
      ), // 13: Surat Izin & Dispensasi
      AuditLogScreen(onBack: _goBack), // 14: Audit Log Aktivitas
      AcademicGradesScreen(
        key: ValueKey('grades_${currentUser.nim}'),
        studentNim: currentUser.nim,
        canManage: currentUser.isAdmin,
        student: currentUser,
        onBack: _goBack,
      ), // 15: Transkrip Nilai & IPK
    ];

    final isTopLevel = _currentIndex <= 4;
    final navBarIndex = isTopLevel ? _currentIndex : -1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final screen = AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('tab_$_currentIndex'),
            child: screens[_currentIndex],
          ),
        );

        return PopScope(
          canPop: _currentIndex == 0 && _navigationHistory.length <= 1,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _goBack();
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            drawer: isWide ? null : _buildDrawer(),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1240 : 580),
                child: Row(
                  children: [
                    if (isWide) _buildDesktopSidebar(currentUser),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 900 : 580,
                          ),
                          child: screen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: !isWide && isTopLevel
                ? NavigationBar(
                    selectedIndex: navBarIndex,
                    onDestinationSelected: _navigateToIndex,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Beranda',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: 'Jadwal',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment_rounded),
                        label: 'Tugas',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_alt_outlined),
                        selectedIcon: Icon(Icons.people_alt_rounded),
                        label: 'Kelas',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'Profil',
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(StudentProfile student) {
    final theme = Theme.of(context);
    return Container(
      width: 238,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ILKOM HUB',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: .55,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ruang kuliahmu',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white,
                  child: Text(
                    student.nama.isEmpty ? '?' : student.nama[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.jabatan} · ${student.semester} semester',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                _sidebarLabel('MENU UTAMA'),
                _sidebarTile(
                  Icons.home_rounded,
                  'Beranda',
                  0,
                  const Color(0xFF5B3DE8),
                ),
                _sidebarTile(
                  Icons.calendar_month_rounded,
                  'Jadwal kuliah',
                  1,
                  const Color(0xFF3989D8),
                ),
                _sidebarTile(
                  Icons.assignment_rounded,
                  'Tugas',
                  2,
                  const Color(0xFFCA7900),
                ),
                _sidebarTile(
                  Icons.people_alt_rounded,
                  'Teman sekelas',
                  3,
                  const Color(0xFF087477),
                ),
                _sidebarTile(
                  Icons.person_rounded,
                  'Profil saya',
                  4,
                  const Color(0xFFE96C78),
                ),
                const SizedBox(height: 17),
                _sidebarLabel('LAYANAN KELAS'),
                _sidebarTile(
                  Icons.fact_check_rounded,
                  'Presensi',
                  5,
                  const Color(0xFF0B966B),
                ),
                _sidebarTile(
                  Icons.event_note_rounded,
                  'Agenda',
                  6,
                  const Color(0xFF3989D8),
                ),
                _sidebarTile(
                  Icons.campaign_rounded,
                  'Pengumuman',
                  7,
                  const Color(0xFF5B3DE8),
                ),
                _sidebarTile(
                  Icons.account_balance_wallet_rounded,
                  'Kas kelas',
                  8,
                  const Color(0xFF087477),
                ),
                _sidebarTile(
                  Icons.group_work_rounded,
                  'Kelompok',
                  9,
                  const Color(0xFFE96C78),
                ),
                _sidebarTile(
                  Icons.folder_open_rounded,
                  'Materi kuliah',
                  10,
                  const Color(0xFF3989D8),
                ),
                _sidebarTile(
                  Icons.notifications_rounded,
                  'Notifikasi',
                  11,
                  const Color(0xFFCA7900),
                ),
                _sidebarTile(
                  Icons.how_to_vote_rounded,
                  'Voting',
                  12,
                  const Color(0xFF087477),
                ),
                _sidebarTile(
                  Icons.description_rounded,
                  'Surat & dispensasi',
                  13,
                  const Color(0xFF5B3DE8),
                ),
                _sidebarTile(
                  Icons.history_rounded,
                  'Aktivitas kelas',
                  14,
                  const Color(0xFF3989D8),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          if (widget.isAdminUser && widget.onSwitchToAdminView != null)
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Panel administrator',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onTap: widget.onSwitchToAdminView,
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Keluar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sidebarLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: .7,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _sidebarTile(IconData icon, String label, int index, Color accent) {
    final selected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _navigateToIndex(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.primary : accent,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textMain,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Screen 12: Sidebar Menu Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Logo and Close X
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          height: 38,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.school_rounded,
                                color: Color(0xFF5B3DE8),
                                size: 32,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ILMU KOMUNIKASI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5B3DE8),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'UNAZLAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B7280),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Current User Info Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                    backgroundColor: const Color(0xFF5B3DE8)
                        .withValues(alpha: 0.12),
                    child: Text(
                      _currentUser.nama.isNotEmpty
                          ? _currentUser.nama[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B3DE8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isAdminUser
                              ? 'Administrator Sistem'
                              : '${_currentUser.jabatan} • ILKOM 2026',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: widget.isAdminUser
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF5B3DE8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Nav Items matching Screen 12
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                children: [
                  if (widget.isAdminUser) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                          title: const Text(
                            'Panel Administrator',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          subtitle: const Text(
                            'Buka kendali sistem & master data',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSwitchToAdminView?.call();
                          },
                        ),
                      ),
                    ),
                  ],
                  _buildDrawerTile(Icons.home_outlined, 'Beranda', 0),
                  _buildDrawerTile(Icons.calendar_month_outlined, 'Jadwal', 1),
                  _buildDrawerTile(Icons.assignment_outlined, 'Tugas', 2),
                  _buildDrawerTile(Icons.school_outlined, 'Nilai & IPK', 15),
                  _buildDrawerTile(Icons.people_alt_outlined, 'Kelas', 3),
                  _buildDrawerTile(Icons.campaign_outlined, 'Pengumuman', 7),
                  _buildDrawerTile(Icons.event_note_outlined, 'Agenda', 6),
                  _buildDrawerTile(Icons.person_outline_rounded, 'Profil', 4),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDrawerTile(
                    Icons.fact_check_outlined,
                    'Absensi Saya',
                    5,
                  ),
                  _buildDrawerTile(
                    Icons.account_balance_wallet_outlined,
                    'Kas Kelas',
                    8,
                  ),
                  _buildDrawerTile(
                    Icons.group_work_outlined,
                    'Kelompok Praktikum',
                    9,
                  ),
                  _buildDrawerTile(
                    Icons.folder_open_rounded,
                    'Gudang Materi',
                    10,
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDrawerTile(
                    Icons.notifications_outlined,
                    'Pusat Notifikasi',
                    11,
                  ),
                  _buildDrawerTile(
                    Icons.how_to_vote_outlined,
                    'Voting & Polling',
                    12,
                  ),
                  _buildDrawerTile(
                    Icons.description_outlined,
                    'Surat & Dispensasi',
                    13,
                  ),
                  _buildDrawerTile(
                    Icons.history_toggle_off_rounded,
                    'Audit Log Kelas',
                    14,
                  ),
                ],
              ),
            ),

            // Bottom Actions (Pengaturan, Keluar)
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      title: const Text(
                        'Ganti tema',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      subtitle: const Text(
                        'Beralih antara mode terang dan gelap',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSub,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ThemeScope.notifier.toggleTheme();
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      title: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onLogout?.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int targetIndex) {
    final isSelected = _currentIndex == targetIndex;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF5B3DE8)
                : const Color(0xFF374151),
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFF3F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          _navigateToIndex(targetIndex);
        },
      ),
    );
  }
}
