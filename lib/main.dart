import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal lokal Indonesia
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Gagal inisialisasi locale id_ID: $e');
  }

  // Inisialisasi Supabase
  await SupabaseService.initialize();

  runApp(const ClassManagerApp());
}

class ClassManagerApp extends StatefulWidget {
  const ClassManagerApp({super.key});

  @override
  State<ClassManagerApp> createState() => _ClassManagerAppState();
}

class _ClassManagerAppState extends State<ClassManagerApp> {
  bool _showSplash = true;
  bool _isLoggedIn = false;
  String _userNim = '';
  String _userName = '';

  void _onSplashFinish() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  void _onLoginSuccess(String nim, String name) {
    setState(() {
      _userNim = nim;
      _userName = name;
      _isLoggedIn = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
      _userNim = '';
      _userName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ILKOM UNAZLAM Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _showSplash
          ? SplashScreen(onFinish: _onSplashFinish)
          : (!_isLoggedIn
              ? LoginScreen(onLoginSuccess: _onLoginSuccess)
              : MainResponsiveShell(
                  userNim: _userNim,
                  userName: _userName,
                  onLogout: _onLogout,
                )),
    );
  }
}

class MainResponsiveShell extends StatefulWidget {
  final String? userNim;
  final String? userName;
  final VoidCallback? onLogout;

  const MainResponsiveShell({
    super.key,
    this.userNim,
    this.userName,
    this.onLogout,
  });

  @override
  State<MainResponsiveShell> createState() => _MainResponsiveShellState();
}

class _MainResponsiveShellState extends State<MainResponsiveShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
    final List<Widget> screens = [
      DashboardScreen(
        userName: widget.userName,
        onNavigateTab: _navigateToIndex,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 0: Beranda
      const ScheduleScreen(), // 1: Jadwal
      const AssignmentsScreen(), // 2: Tugas
      const DirectoryScreen(), // 3: Kelas (Anggota)
      ProfileScreen(onNavigateTab: _navigateToIndex), // 4: Profil Saya
      const AttendanceScreen(), // 5: Absensi Saya
      const AgendaScreen(), // 6: Agenda Kelas
      const AnnouncementsScreen(), // 7: Pengumuman
      const TreasuryScreen(), // 8: Kas Kelas
      const GroupsScreen(), // 9: Kelompok Praktikum
      const ResourcesScreen(), // 10: Gudang Materi
    ];

    final isTopLevel = _currentIndex <= 4;
    final navBarIndex = isTopLevel ? _currentIndex : -1;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F1F8),
      // Sidebar Drawer matching Screen 12 in the design mockup
      drawer: _buildDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              // 5-Tab Bottom Navigation Bar matching Screen 3-7 in mockup
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda', navBarIndex),
                        _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Jadwal', navBarIndex),
                        _buildNavItem(2, Icons.assignment_rounded, Icons.assignment_outlined, 'Tugas', navBarIndex),
                        _buildNavItem(3, Icons.people_alt_rounded, Icons.people_alt_outlined, 'Kelas', navBarIndex),
                        _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil', navBarIndex),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: _currentIndex > 4
                  ? FloatingActionButton.extended(
                      onPressed: () => _navigateToIndex(0),
                      backgroundColor: const Color(0xFF5B3DE8),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Kembali ke Beranda',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, int currentNavIndex) {
    final isSelected = currentNavIndex == index;

    return InkWell(
      onTap: () => _navigateToIndex(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 24,
              color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
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
                          errorBuilder: (context, error, stackTrace) => const Icon(
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
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Drawer Nav Items matching Screen 12
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _buildDrawerTile(Icons.home_outlined, 'Beranda', 0),
                  _buildDrawerTile(Icons.calendar_month_outlined, 'Jadwal', 1),
                  _buildDrawerTile(Icons.assignment_outlined, 'Tugas', 2),
                  _buildDrawerTile(Icons.people_alt_outlined, 'Kelas', 3),
                  _buildDrawerTile(Icons.campaign_outlined, 'Pengumuman', 7),
                  _buildDrawerTile(Icons.event_note_outlined, 'Agenda', 6),
                  _buildDrawerTile(Icons.person_outline_rounded, 'Profil', 4),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDrawerTile(Icons.fact_check_outlined, 'Absensi Saya', 5),
                  _buildDrawerTile(Icons.account_balance_wallet_outlined, 'Kas Kelas', 8),
                  _buildDrawerTile(Icons.group_work_outlined, 'Kelompok Praktikum', 9),
                  _buildDrawerTile(Icons.folder_open_rounded, 'Gudang Materi', 10),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      leading: const Icon(Icons.settings_outlined, color: Color(0xFF6B7280), size: 20),
                      title: const Text('Pengaturan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                      title: const Text('Keluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onLogout != null) {
                          widget.onLogout!();
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
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
            color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF374151),
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
