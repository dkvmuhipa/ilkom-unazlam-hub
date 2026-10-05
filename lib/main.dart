import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/assignments/assignments_screen.dart';
import 'features/announcements/announcements_screen.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/resources/resources_screen.dart';
import 'features/directory/directory_screen.dart';
import 'features/treasury/treasury_screen.dart';
import 'features/gpa/gpa_simulator_screen.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SupabaseService.initialize();
  runApp(const UnazlamClassApp());
}

class UnazlamClassApp extends StatelessWidget {
  const UnazlamClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ILKOM UNAZLAM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainResponsiveShell(),
    );
  }
}

class MainResponsiveShell extends StatefulWidget {
  const MainResponsiveShell({super.key});

  @override
  State<MainResponsiveShell> createState() => _MainResponsiveShellState();
}

class _MainResponsiveShellState extends State<MainResponsiveShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: _navigateToIndex), // 0: Beranda
      const ScheduleScreen(), // 1: Jadwal
      const AssignmentsScreen(), // 2: Tugas
      const AnnouncementsScreen(), // 3: Pengumuman
      const AttendanceScreen(), // 4: Presensi 75%
      const GroupsScreen(), // 5: Kelompok
      const ResourcesScreen(), // 6: Materi
      const DirectoryScreen(), // 7: Teman
      const TreasuryScreen(), // 8: Kas Kelas
      const GpaSimulatorScreen(), // 9: Simulasi IPK
    ];

    final isTopLevel = _currentIndex <= 3;
    final navBarIndex = isTopLevel ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F8),
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
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E094B).withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda', navBarIndex),
                        _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_today_outlined, 'Jadwal', navBarIndex),
                        _buildNavItem(2, Icons.task_alt_rounded, Icons.task_alt_outlined, 'Tugas', navBarIndex),
                        _buildNavItem(3, Icons.notifications_rounded, Icons.notifications_none_rounded, 'Pengumuman', navBarIndex),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: _currentIndex > 3
                  ? FloatingActionButton.small(
                      onPressed: () => _navigateToIndex(0),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSub,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSub,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
