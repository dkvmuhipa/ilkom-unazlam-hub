import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/services/supabase_service.dart';
import 'core/services/supabase_repository.dart';
import 'core/services/auth_service.dart';
import 'core/services/auth_callback_url.dart';
import 'features/dashboard/dashboard_screen.dart';
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

  String? authCallbackError;
  final tokenHash = authCallback.tokenHash;
  if (tokenHash != null && authCallback.flowType == 'recovery') {
    try {
      final client = SupabaseService.client;
      if (client == null)
        throw const AuthServiceException('Supabase belum siap.');
      await client.auth.verifyOTP(tokenHash: tokenHash, type: OtpType.recovery);
      clearAuthCallbackUrl();
    } catch (error) {
      authCallbackError = error is AuthException
          ? 'Tautan reset tidak valid atau sudah kedaluwarsa. Minta tautan baru, lalu buka di aplikasi ini.'
          : 'Verifikasi tautan reset gagal. Periksa koneksi lalu coba lagi.';
    }
  } else if (authCallback.hasCode &&
      SupabaseService.client?.auth.currentSession == null) {
    authCallbackError = 'Tautan reset lama tidak cocok dengan sesi browser ini. Atur template email Supabase ke token_hash, lalu kirim tautan baru.';
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
    final currentUser = _currentUser;

    final List<Widget> screens = [
      DashboardScreen(
        key: ValueKey('dash_${currentUser.nim}'),
        userName: currentUser.nama,
        userNim: currentUser.nim,
        onNavigateTab: _navigateToIndex,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 0: Beranda
      ScheduleScreen(
        key: ValueKey('schedule_${currentUser.nim}'),
        canManage: currentUser.isKetuaKelas || currentUser.isAdmin,
      ), // 1: Jadwal
      AssignmentsScreen(
        key: ValueKey('assignments_${currentUser.nim}'),
        canManage: currentUser.canManageAssignments,
        userNim: currentUser.nim,
      ), // 2: Tugas
      DirectoryScreen(
        key: ValueKey('directory_${currentUser.nim}'),
        canManage: currentUser.isKetuaKelas || currentUser.isAdmin,
      ), // 3: Kelas (Anggota)
      ProfileScreen(
        key: ValueKey('profile_${currentUser.nim}'),
        onNavigateTab: _navigateToIndex,
        userNim: currentUser.nim,
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
        onBack: _goBack,
      ), // 8: Kas Kelas
      GroupsScreen(onBack: _goBack), // 9: Kelompok Praktikum
      ResourcesScreen(onBack: _goBack), // 10: Gudang Materi
      NotificationScreen(
        onNavigateTab: _navigateToIndex,
        onBack: _goBack,
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
                    if (isWide)
                      NavigationRail(
                        selectedIndex: navBarIndex < 0 ? null : navBarIndex,
                        onDestinationSelected: _navigateToIndex,
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: Text('Beranda'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.calendar_month_outlined),
                            selectedIcon: Icon(Icons.calendar_month_rounded),
                            label: Text('Jadwal'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.assignment_outlined),
                            selectedIcon: Icon(Icons.assignment_rounded),
                            label: Text('Tugas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_alt_outlined),
                            selectedIcon: Icon(Icons.people_alt_rounded),
                            label: Text('Kelas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline_rounded),
                            selectedIcon: Icon(Icons.person_rounded),
                            label: Text('Profil'),
                          ),
                        ],
                      ),
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

  // Screen 12: Sidebar Menu Drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
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
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menu Pengaturan')),
                        );
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
