import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/constants/app_colors.dart';
import '../../core/widgets/saas_components.dart';
import '../../core/services/admin_account_service.dart';
import '../../core/services/admin_academic_service.dart';
import '../../core/services/admin_audit_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import 'create_student_account_dialog.dart';
import 'edit_student_account_dialog.dart';
import 'views/admin_audit_log_view.dart';
import 'views/admin_reports_view.dart';
import 'views/admin_roles_view.dart';
import 'views/admin_academic_year_view.dart';
import 'views/admin_lecturers_view.dart';
import 'views/admin_courses_view.dart';
import 'views/admin_account_management_view.dart';
import 'views/admin_system_settings_view.dart';
import 'views/admin_classes_view.dart';
import 'views/admin_students_view.dart';
import 'views/admin_attendance_matrix_view.dart';
import 'widgets/admin_bulk_csv_modal.dart';
import 'widgets/admin_creation_modals.dart';
import 'widgets/admin_common_widgets.dart';
import 'models/admin_models.dart';

class _AdminServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AdminServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class AdminShellScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToStudentView;
  final String currentNim;
  final String currentName;

  const AdminShellScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToStudentView,
    this.currentNim = '16110376',
    this.currentName = 'Admin Program Studi',
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  // Navigation stack / view state
  String _currentView = 'dashboard';
  StudentProfile? _selectedStudent;
  int _navBarIndex = 0;
  List<StudentProfile> _managedAccounts = [];
  bool _isLoadingAccounts = false;
  bool _isLoadingAcademicData = false;
  String? _academicLoadError;
  Future<Map<String, String>>? _reportFuture;
  String? _accountLoadError;
  Future<List<Map<String, dynamic>>>? _auditFuture;

  // Local state for dynamic data
  late List<ClassItem> _classes;
  late List<AcademicYearItem> _academicYears;
  late List<Course> _courses;
  late List<LecturerItem> _lecturers;

  // Realtime subscription channels
  RealtimeChannel? _classesChannel;
  RealtimeChannel? _lecturersChannel;
  RealtimeChannel? _academicYearsChannel;
  RealtimeChannel? _coursesChannel;
  RealtimeChannel? _studentsChannel;
  RealtimeChannel? _auditLogsChannel;

  int _registeredTokensCount = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _classes = [];
    _academicYears = [];
    _courses = [];
    _lecturers = [];
    _reportFuture = _loadReportSnapshot();
    unawaited(_loadAcademicData());
    unawaited(_loadManagedAccounts());
    unawaited(_loadPushTokensCount());
    _initAdminRealtime();
  }

  void _initAdminRealtime() {
    _classesChannel = SupabaseRepository.subscribeToAcademicClasses(() {
      if (mounted) unawaited(_loadAcademicData());
    });
    _lecturersChannel = SupabaseRepository.subscribeToLecturers(() {
      if (mounted) unawaited(_loadAcademicData());
    });
    _academicYearsChannel = SupabaseRepository.subscribeToAcademicYears(() {
      if (mounted) unawaited(_loadAcademicData());
    });
    _coursesChannel = SupabaseRepository.subscribeToCourses(() {
      if (mounted) unawaited(_loadAcademicData());
    });
    _studentsChannel = SupabaseRepository.subscribeToStudents(() {
      if (mounted) {
        unawaited(_loadManagedAccounts());
        setState(() {
          _reportFuture = _loadReportSnapshot();
        });
      }
    });
    _auditLogsChannel = SupabaseRepository.subscribeToAuditLogs(() {
      if (mounted && _currentView == 'audit_logs') {
        _loadAuditLogs();
      }
    });
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_classesChannel);
    SupabaseRepository.unsubscribeChannel(_lecturersChannel);
    SupabaseRepository.unsubscribeChannel(_academicYearsChannel);
    SupabaseRepository.unsubscribeChannel(_coursesChannel);
    SupabaseRepository.unsubscribeChannel(_studentsChannel);
    SupabaseRepository.unsubscribeChannel(_auditLogsChannel);
    super.dispose();
  }

  Future<void> _loadPushTokensCount() async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client.from('user_push_tokens').select('id');
        if (mounted) {
          setState(() {
            _registeredTokensCount = (res as List).length;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshAllAdminData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _reportFuture = _loadReportSnapshot();
    });
    try {
      await Future.wait([
        _loadAcademicData(),
        _loadManagedAccounts(),
        _loadPushTokensCount(),
      ]);
      if (_academicLoadError != null || _accountLoadError != null) {
        throw StateError(_academicLoadError ?? _accountLoadError!);
      }
      if (mounted) {
        _showAdminMessage(
          'Seluruh modul dan data admin berhasil disinkronkan!',
        );
      }
    } catch (e) {
      if (mounted) {
        _showAdminMessage(
          'Sebagian data gagal disinkronkan. Periksa koneksi dan coba lagi.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<Map<String, String>> _loadReportSnapshot() async {
    final client = SupabaseService.client;
    if (client == null) {
      return {
        'attendance': 'Belum terhubung ke Supabase',
        'treasury': 'Belum terhubung ke Supabase',
        'assignments': 'Belum terhubung ke Supabase',
        'students': 'Belum terhubung ke Supabase',
      };
    }

    List<Map<String, dynamic>> attendance = [];
    List<Map<String, dynamic>> cash = [];
    List<dynamic> assignments = [];
    List<dynamic> students = [];
    final failed = <String>{};

    try {
      final res = await client.from('attendance_logs').select('status');
      attendance = List<Map<String, dynamic>>.from(res as List);
    } catch (_) { failed.add('attendance'); }

    try {
      final res = await client
          .from('treasury_transactions')
          .select('nominal,is_pemasukan');
      cash = List<Map<String, dynamic>>.from(res as List);
    } catch (_) { failed.add('treasury'); }

    try {
      final res = await client.from('assignments').select('id');
      assignments = List<dynamic>.from(res as List);
    } catch (_) { failed.add('assignments'); }

    try {
      final res = await client
          .from('students')
          .select('nim')
          .eq('is_aktif', true)
          .neq('role', 'ADMIN');
      students = List<dynamic>.from(res as List);
    } catch (_) { failed.add('students'); }

    final present = attendance
        .where(
          (row) => (row['status']?.toString().toLowerCase() ?? '') == 'hadir',
        )
        .length;
    final attendanceRate = attendance.isEmpty
        ? null
        : (present * 100 / attendance.length).round();
    final balance = cash.fold<int>(0, (sum, row) {
      final amount = (row['nominal'] as num?)?.toInt() ?? 0;
      return sum + (row['is_pemasukan'] == true ? amount : -amount);
    });
    final formattedBalance = balance.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return {
      'attendance': failed.contains('attendance') ? 'Kehadiran gagal dimuat' : attendanceRate == null
          ? 'Kehadiran: Belum ada sesi'
          : 'Kehadiran tercatat: $attendanceRate% (${attendance.length} catatan)',
      'treasury': failed.contains('treasury') ? 'Saldo kas gagal dimuat' :
          'Saldo dari ${cash.length} transaksi: Rp ${balance < 0 ? '-' : ''}$formattedBalance',
      'assignments': failed.contains('assignments') ? 'Data tugas gagal dimuat' : '${assignments.length} tugas tercatat',
      'students': failed.contains('students') ? 'Data mahasiswa gagal dimuat' : '${students.length} akun mahasiswa aktif',
    };
  }

  Future<void> _loadAcademicData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAcademicData = true;
      _academicLoadError = null;
    });
    try {
      final results = await Future.wait([
        AdminAcademicService.listClasses(),
        AdminAcademicService.listLecturers(),
        AdminAcademicService.listAcademicYears(),
        SupabaseRepository.getCourses(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = (results[0] as List<Map<String, dynamic>>)
            .map((row) => ClassItem.fromMap(row))
            .toList();
        _lecturers = (results[1] as List<Map<String, dynamic>>)
            .map((row) => LecturerItem.fromMap(row))
            .toList();
        _academicYears = (results[2] as List<Map<String, dynamic>>)
            .map((row) => AcademicYearItem.fromMap(row))
            .toList();
        _courses = results[3] as List<Course>;
      });
    } on AdminAcademicException catch (error) {
      if (mounted) setState(() => _academicLoadError = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _academicLoadError = 'Data akademik gagal dimuat: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAcademicData = false);
    }
  }

  void _navigateTo(String view, {StudentProfile? student}) {
    setState(() {
      _currentView = view;
      if (student != null) _selectedStudent = student;

      // Sync bottom navigation index
      if (view == 'dashboard') {
        _navBarIndex = 0;
      } else if (view == 'kelas' ||
          view == 'mahasiswa' ||
          view == 'tambah_kelas' ||
          view == 'detail_mahasiswa') {
        _navBarIndex = 1;
      } else if (view == 'dosen' ||
          view == 'matakuliah' ||
          view == 'tahun_akademik') {
        _navBarIndex = 2;
      } else if (view == 'laporan' || view == 'matriks_presensi') {
        _navBarIndex = 3;
      } else if (view == 'pengaturan' ||
          view == 'role_permission' ||
          view == 'manajemen_akun' ||
          view == 'audit_logs') {
        _navBarIndex = 4;
      }
    });
    if (view == 'manajemen_akun') unawaited(_loadManagedAccounts());
    if (view == 'audit_logs') _loadAuditLogs();
  }

  Future<void> _loadManagedAccounts() async {
    setState(() {
      _isLoadingAccounts = true;
      _accountLoadError = null;
    });
    try {
      final accounts = await AdminAccountService.listStudentAccounts();
      if (!mounted) return;
      setState(() => _managedAccounts = accounts);
    } on AdminAccountServiceException catch (error) {
      if (!mounted) return;
      setState(() => _accountLoadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  void _handleBottomNav(int index) {
    setState(() {
      _navBarIndex = index;
      switch (index) {
        case 0:
          _currentView = 'dashboard';
          break;
        case 1:
          _currentView = 'kelas';
          break;
        case 2:
          _currentView = 'matakuliah';
          break;
        case 3:
          _currentView = 'laporan';
          break;
        case 4:
          _currentView = 'pengaturan';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 1240 : 580),
            child: PopScope(
              canPop: _currentView == 'dashboard',
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _currentView != 'dashboard') {
                  _navigateTo('dashboard');
                }
              },
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Row(
                  children: [
                    if (isWide)
                      NavigationRail(
                        backgroundColor: Colors.white,
                        indicatorColor: AppColors.primaryContainer,
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.primary,
                          size: 22,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        selectedIndex: _navBarIndex,
                        onDestinationSelected: _handleBottomNav,
                        labelType: NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 20),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF58138A), Color(0xFF6D28D9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard_rounded),
                            label: Text('Beranda'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.folder_outlined),
                            selectedIcon: Icon(Icons.folder_rounded),
                            label: Text('Data'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.school_outlined),
                            selectedIcon: Icon(Icons.school_rounded),
                            label: Text('Akademik'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.insert_chart_outlined_rounded),
                            selectedIcon: Icon(Icons.insert_chart_rounded),
                            label: Text('Laporan'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline_rounded),
                            selectedIcon: Icon(Icons.person_rounded),
                            label: Text('Pengaturan'),
                          ),
                        ],
                      ),
                    Expanded(child: SafeArea(child: _buildCurrentView())),
                  ],
                ),
                bottomNavigationBar: isWide ? null : _buildBottomNav(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        selectedIndex: _navBarIndex,
        onDestinationSelected: _handleBottomNav,
        destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder_rounded),
          label: 'Data',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school_rounded),
          label: 'Akademik',
        ),
        NavigationDestination(
          icon: Icon(Icons.insert_chart_outlined_rounded),
          selectedIcon: Icon(Icons.insert_chart_rounded),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Pengaturan',
        ),
      ],
    ),);
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'dashboard':
        return _buildDashboard();
      case 'kelas':
        return _buildDataKelas();
      case 'tambah_kelas':
        return _buildTambahKelas();
      case 'mahasiswa':
        return _buildDataMahasiswa();
      case 'detail_mahasiswa':
        return _buildDetailMahasiswa();
      case 'dosen':
        return _buildDataDosen();
      case 'matakuliah':
        return _buildMataKuliah();
      case 'tahun_akademik':
        return _buildTahunAkademik();
      case 'manajemen_akun':
        return _buildManajemenAkun();
      case 'laporan':
        return _buildLaporan();
      case 'matriks_presensi':
        return _buildMatriksPresensi();
      case 'pengaturan':
        return _buildPengaturanSistem();
      case 'role_permission':
        return _buildRolePermission();
      case 'audit_logs':
        return _buildAuditLogScreen();
      default:
        return _buildDashboard();
    }
  }

  // ==========================================
  // SCREEN 3: DASHBOARD ADMIN (UNIFIED WITH STUDENT UI)
  // ==========================================
  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceStudents = _managedAccounts.where((s) => !s.isAdmin).toList();
    final activeStudentsCount = sourceStudents.where((s) => s.isAktif).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP BAR TERPADU (Mirrors Student UI Top Bar)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 50),
            child: _buildAdminTopBar(isDark),
          ),
          const SizedBox(height: 14),

          // 2. HERO DECK EKSEKUTIF (Mirrors Student UI Academic Schedule Card)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 120),
            child: _buildExecutiveHeroDeck(context, isDark, activeStudentsCount),
          ),
          const SizedBox(height: 16),

          // 3. DIREKTORI 8 MODUL LAYANAN (Mirrors Student UI Services Grid)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 200),
            child: _buildAdminServicesGrid(context, isDark),
          ),
          const SizedBox(height: 16),

          // 4. SPOTLIGHT SIARAN & AKSI CEPAT (Mirrors Student UI Spotlight & Action Hub)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 280),
            child: _buildAdminSpotlightSection(context, isDark),
          ),
        ],
      ),
    );
  }

  // 1. TOP BAR BERSIH & TERPADU (MINIMALIST SWISS STYLE - SEPERTI MAHASISWA)
  Widget _buildAdminTopBar(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A1829) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final hour = DateTime.now().hour;
    final greeting = (hour >= 4 && hour < 11)
        ? 'Selamat Pagi'
        : (hour >= 11 && hour < 15)
            ? 'Selamat Siang'
            : (hour >= 15 && hour < 18)
                ? 'Selamat Sore'
                : 'Selamat Malam';

    final adminFirstName = widget.currentName.trim().split(' ').first;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          return Row(
            children: [
              // Avatar Admin dengan Status Online
              ScaleButton(
                scaleDown: 0.92,
                onTap: () => _navigateTo('pengaturan'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SaaSAvatar(
                      name: widget.currentName,
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

              // Identitas Admin & Salam
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$greeting, $adminFirstName 👋',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Panel Administrator • FISIP Ilkom',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action 1: Mode Siswa
              ScaleButton(
                scaleDown: 0.92,
                onTap: widget.onSwitchToStudentView,
                child: Container(
                  height: 38,
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 9 : 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262438) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Siswa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Action 2: Refresh Sinkronisasi Data Master
              ScaleButton(
                scaleDown: 0.92,
                onTap: _isRefreshing ? null : _refreshAllAdminData,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262438) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.sync_rounded,
                            size: 19,
                            color: AppColors.primary,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Action 3: Notifikasi / Audit Log Bell
              ScaleButton(
                scaleDown: 0.92,
                onTap: () {
                  setState(() {
                    _currentView = 'audit_logs';
                    _selectedStudent = null;
                    _loadAuditLogs();
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262438) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 19,
                        color: textSub,
                      ),
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
          );
        },
      ),
    );
  }

  // 2. HERO DECK EKSEKUTIF (Mirrors Student UI Academic Schedule Card)
  Widget _buildExecutiveHeroDeck(
    BuildContext context,
    bool isDark,
    int activeStudentsCount,
  ) {
    final cardBg = isDark ? const Color(0xFF141224) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E2B42)
        : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final activeYear = _academicYears.any((y) => y.isAktif)
        ? _academicYears.firstWhere((y) => y.isAktif).tahun
        : '2026/2027';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ringkasan Eksekutif, Chip TA, Status FCM
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
                        'Ringkasan Eksekutif',
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
                          'TA $activeYear',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: SoftPillBadge.success(
                  label: 'FCM Online',
                  showDot: true,
                  fontSize: 9.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Divider Tipis
          Container(
            height: 1,
            color: borderColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),

          // 4 Stat Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;

              final stat1 = _buildExecutiveStatPill(
                title: 'Kelas Aktif',
                value: '${_classes.length}',
                delta: 'FISIP',
                icon: Icons.meeting_room_outlined,
                color: AppColors.primary,
                bgColor: isDark ? const Color(0xFF201636) : const Color(0xFFF5F3FF),
                onTap: () => _navigateTo('kelas'),
                isDark: isDark,
              );
              final stat2 = _buildExecutiveStatPill(
                title: 'Mahasiswa',
                value: '$activeStudentsCount',
                delta: 'Aktif',
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF0284C7),
                bgColor: isDark ? const Color(0xFF0E2538) : const Color(0xFFF0F9FF),
                onTap: () => _navigateTo('mahasiswa'),
                isDark: isDark,
              );
              final stat3 = _buildExecutiveStatPill(
                title: 'Dosen Pengajar',
                value: '${_lecturers.length}',
                delta: 'FISIP',
                icon: Icons.badge_outlined,
                color: const Color(0xFF059669),
                bgColor: isDark ? const Color(0xFF0E2B20) : const Color(0xFFECFDF5),
                onTap: () => _navigateTo('dosen'),
                isDark: isDark,
              );
              final stat4 = _buildExecutiveStatPill(
                title: 'Mata Kuliah',
                value: '${_courses.length}',
                delta: 'Ganjil',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFD97706),
                bgColor: isDark ? const Color(0xFF2D2210) : const Color(0xFFFEF3C7),
                onTap: () => _navigateTo('matakuliah'),
                isDark: isDark,
              );

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: stat1),
                      const SizedBox(width: 8),
                      Expanded(child: stat2),
                      const SizedBox(width: 8),
                      Expanded(child: stat3),
                      const SizedBox(width: 8),
                      Expanded(child: stat4),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: stat1),
                        const SizedBox(width: 8),
                        Expanded(child: stat2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: stat3),
                        const SizedBox(width: 8),
                        Expanded(child: stat4),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Bottom Telemetry Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B38) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2B42) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  size: 13,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'FCM Terhubung ($_registeredTokensCount Perangkat) • BAP Presensi 16 Sesi',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                ScaleButton(
                  scaleDown: 0.94,
                  onTap: () {
                    setState(() {
                      _currentView = 'audit_logs';
                      _selectedStudent = null;
                      _loadAuditLogs();
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Log Audit',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveStatPill({
    required String title,
    required String value,
    required String delta,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleButton(
      scaleDown: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 0.9,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 17),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      delta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. DIREKTORI 8 MODUL LAYANAN (Mirrors Student UI Services Grid 1:1)
  Widget _buildAdminServicesGrid(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF141224) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2C2746)
        : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final services = [
      _AdminServiceItem(
        title: 'Kelas',
        subtitle: 'Daftar & Ruang',
        icon: Icons.meeting_room_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF24153E) : const Color(0xFFEDE9FE),
        onTap: () => _navigateTo('kelas'),
      ),
      _AdminServiceItem(
        title: 'Mahasiswa',
        subtitle: 'Data & Akun',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0284C7),
        bgColor: isDark ? const Color(0xFF0C2438) : const Color(0xFFE0F2FE),
        onTap: () => _navigateTo('mahasiswa'),
      ),
      _AdminServiceItem(
        title: 'Dosen',
        subtitle: 'Pengajar FISIP',
        icon: Icons.badge_rounded,
        color: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF0C2B20) : const Color(0xFFE8F5E9),
        onTap: () => _navigateTo('dosen'),
      ),
      _AdminServiceItem(
        title: 'Mata Kuliah',
        subtitle: 'Kurikulum SKS',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: isDark ? const Color(0xFF2B2010) : const Color(0xFFFEF3C7),
        onTap: () => _navigateTo('matakuliah'),
      ),
      _AdminServiceItem(
        title: 'T. Akademik',
        subtitle: 'Periode Aktif',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFF43F5E),
        bgColor: isDark ? const Color(0xFF2C131D) : const Color(0xFFFFE4E6),
        onTap: () => _navigateTo('tahun_akademik'),
      ),
      _AdminServiceItem(
        title: 'Akun & Role',
        subtitle: 'Hak Akses',
        icon: Icons.manage_accounts_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF231538) : const Color(0xFFF3E8FF),
        onTap: () => _navigateTo('manajemen_akun'),
      ),
      _AdminServiceItem(
        title: 'Laporan & BAP',
        subtitle: 'Rekapitulasi',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF14B8A6),
        bgColor: isDark ? const Color(0xFF0C2B29) : const Color(0xFFE0F2F1),
        onTap: () => _navigateTo('laporan'),
      ),
      _AdminServiceItem(
        title: 'Pengaturan',
        subtitle: 'Sistem & Kuota',
        icon: Icons.settings_rounded,
        color: const Color(0xFF64748B),
        bgColor: isDark ? const Color(0xFF1B1B28) : const Color(0xFFF1F5F9),
        onTap: () => _navigateTo('pengaturan'),
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
            color: const Color(0xFF6D28D9).withValues(alpha: isDark ? 0.20 : 0.04),
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
                              'Direktori Modul Admin',
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
                              'Akses cepat pengelolaan data & sistem',
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
                  onTap: () => _navigateTo('pengaturan'),
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

          // 8 Layanan dalam Grid Bersih Tanpa Sekat (4 x 2)
          Row(
            children: services
                .take(4)
                .map((item) => Expanded(
                      child: _buildAdminServiceIcon(
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
                      child: _buildAdminServiceIcon(
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

  Widget _buildAdminServiceIcon(
    BuildContext context,
    _AdminServiceItem item,
    bool isDark,
    Color textMain,
    Color textSub,
  ) {
    return Semantics(
      button: true,
      label: 'Modul ${item.title}',
      child: ScaleButton(
        scaleDown: 0.90,
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Modern Rounded Icon Box
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
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. SPOTLIGHT SIARAN & AKSI CEPAT (Mirrors Student UI Spotlight & Action Hub)
  Widget _buildAdminSpotlightSection(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF141224) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2C2746)
        : const Color(0xFFCBD5E1);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spotlight Card: Siaran Pengumuman Kampus & FCM Push
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF58138A), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9)
                    .withValues(alpha: isDark ? 0.35 : 0.22),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'PUSAT SIARAN & BROADCAST',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                    ),
                    child: const Text(
                      'FCM Push Instant',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Siarkan Pengumuman ke Mahasiswa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kirimkan notifikasi darurat, jadwal kuliah, atau pengumuman akademik langsung ke perangkat mahasiswa.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ScaleButton(
                    scaleDown: 0.94,
                    onTap: _showBroadcastAnnouncementDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, size: 14, color: Color(0xFF58138A)),
                            SizedBox(width: 6),
                            Text(
                              'Kirim Pengumuman',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF58138A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ScaleButton(
                    scaleDown: 0.94,
                    onTap: () => _navigateTo('matriks_presensi'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'Matriks BAP',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
        const SizedBox(height: 16),

        // Secondary Action Pods: Rilis Tugas, Tambah Akun, dan Alat Terintegrasi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aksi Cepat & Utilitas',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Operasional Harian Kampus',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textSub,
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
              const SizedBox(height: 10),
              Container(height: 1, color: borderColor.withValues(alpha: 0.6)),
              const SizedBox(height: 10),

              // Two Quick Action Cards (Responsive Layout)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrowSub = constraints.maxWidth < 420;
                  final subCard1 = _buildQuickActionSubCard(
                    icon: Icons.post_add_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: isDark ? const Color(0xFF0E2538) : const Color(0xFFF0F9FF),
                    title: 'Rilis Tugas Baru',
                    subtitle: 'Penugasan kuliah',
                    onTap: _showCreateAssignmentDialog,
                    isDark: isDark,
                  );
                  final subCard2 = _buildQuickActionSubCard(
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFF6366F1),
                    bgColor: isDark ? const Color(0xFF1E1E3F) : const Color(0xFFEEF2FF),
                    title: 'Tambah Akun',
                    subtitle: 'Mahasiswa baru',
                    onTap: _showCreateStudentAccountDialog,
                    isDark: isDark,
                  );

                  if (isNarrowSub) {
                    return Column(
                      children: [
                        subCard1,
                        const SizedBox(height: 8),
                        subCard2,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: subCard1),
                      const SizedBox(width: 8),
                      Expanded(child: subCard2),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),

              // Utility tool chips (WA Gateway, CSV Impor, Ekspor)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStudentStyleToolChip(
                    icon: Icons.phone_android_rounded,
                    label: 'WA Gateway',
                    onTap: _showWahaGatewayDialog,
                    isDark: isDark,
                  ),
                  _buildStudentStyleToolChip(
                    icon: Icons.file_upload_outlined,
                    label: 'Impor CSV',
                    onTap: () => _showBulkCsvModal(),
                    isDark: isDark,
                  ),
                  _buildStudentStyleToolChip(
                    icon: Icons.download_rounded,
                    label: 'Ekspor Data',
                    onTap: _showQuickExportModal,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionSubCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleButton(
      scaleDown: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
    );
  }

  Widget _buildStudentStyleToolChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleButton(
      scaleDown: 0.94,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark ? const Color(0xFFA5B4FC) : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWahaGatewayDialog() {
    AdminCreationModals.showWahaGatewayDialog(
      context: context,
      onShowMessage: _showAdminMessage,
    );
  }

  void _showBroadcastAnnouncementDialog() {
    AdminCreationModals.showBroadcastAnnouncementDialog(
      context: context,
      classes: _classes,
      onRefresh: _refreshAllAdminData,
      onShowMessage: _showAdminMessage,
      onRecordAudit: _recordAudit,
    );
  }

  void _showCreateAssignmentDialog() {
    AdminCreationModals.showCreateAssignmentDialog(
      context: context,
      courses: _courses,
      onRefresh: _refreshAllAdminData,
      onShowMessage: _showAdminMessage,
      onRecordAudit: _recordAudit,
    );
  }

  void _showQuickExportModal() {
    AdminCreationModals.showQuickExportModal(
      context: context,
      onNavigate: _navigateTo,
    );
  }

  void _showBulkCsvModal({
    BulkImportType initialType = BulkImportType.students,
  }) {
    AdminBulkCsvModal.show(
      context,
      initialType: initialType,
      onReload: _refreshAllAdminData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
    );
  }


  // ==========================================
  // SCREEN 4: DATA KELAS
  // ==========================================
  Widget _buildDataKelas() {
    return AdminClassesView(
      isAddMode: false,
      classes: _classes,
      academicYears: _academicYears,
      courses: _courses,
      managedAccounts: _managedAccounts,
      isLoading: _isLoadingAcademicData,
      loadError: _academicLoadError,
      onBack: () => _navigateTo('dashboard'),
      onNavigate: _navigateTo,
      onReload: _loadAcademicData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
    );
  }

  // ==========================================
  // SCREEN 5: TAMBAH KELAS
  // ==========================================
  Widget _buildTambahKelas() {
    return AdminClassesView(
      isAddMode: true,
      classes: _classes,
      academicYears: _academicYears,
      courses: _courses,
      managedAccounts: _managedAccounts,
      isLoading: _isLoadingAcademicData,
      loadError: _academicLoadError,
      onBack: () => _navigateTo('kelas'),
      onNavigate: _navigateTo,
      onReload: _loadAcademicData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
    );
  }

  // ==========================================
  // SCREEN 6: DATA MAHASISWA
  // ==========================================

  void _showAdminMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB91C1C)
            : const Color(0xFF059669),
      ),
    );
  }

  void _recordAudit({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) {
    unawaited(() async {
      await AdminAuditService.record(
        action: action,
        module: module,
        description: description,
        userIdentifier: widget.currentNim.isNotEmpty ? widget.currentNim : '16110376',
        userName: widget.currentName.isNotEmpty ? widget.currentName : 'Admin Program Studi',
        metadata: metadata,
      );
      if (_currentView == 'audit_logs' && mounted) {
        setState(() {
          _auditFuture = AdminAuditService.list();
        });
      }
    }());
  }

  void _loadAuditLogs() {
    setState(() {
      _auditFuture = AdminAuditService.list();
    });
  }

  Future<bool> _confirmDelete(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Hapus',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;

  // ==========================================
  // SCREEN 6: DATA MAHASISWA
  // ==========================================
  Widget _buildDataMahasiswa() {
    return AdminStudentsView(
      isDetailMode: false,
      selectedStudent: _selectedStudent,
      managedAccounts: _managedAccounts,
      courses: _courses,
      onBack: () => _navigateTo('dashboard'),
      onNavigate: _navigateTo,
      onReload: _loadManagedAccounts,
      onShowMessage: _showAdminMessage,
      onEditAccount: _editManagedAccount,
      onSetActive: _setManagedAccountActive,
      onDeleteAccount: _deleteStudentAccount,
      onCreateAccount: _showCreateStudentAccountDialog,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
    );
  }

  // ==========================================
  // SCREEN 7: DETAIL MAHASISWA
  // ==========================================
  Widget _buildDetailMahasiswa() {
    return AdminStudentsView(
      isDetailMode: true,
      selectedStudent: _selectedStudent,
      managedAccounts: _managedAccounts,
      courses: _courses,
      onBack: () => _navigateTo('mahasiswa'),
      onNavigate: _navigateTo,
      onReload: _loadManagedAccounts,
      onShowMessage: _showAdminMessage,
      onEditAccount: _editManagedAccount,
      onSetActive: _setManagedAccountActive,
      onDeleteAccount: _deleteStudentAccount,
      onCreateAccount: _showCreateStudentAccountDialog,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
    );
  }

  // ==========================================
  // SCREEN 8: DATA DOSEN
  // ==========================================
  Widget _buildDataDosen() {
    return AdminLecturersView(
      lecturers: _lecturers,
      courses: _courses,
      isLoading: _isLoadingAcademicData,
      loadError: _academicLoadError,
      onBack: () => _navigateTo('dashboard'),
      onReload: _loadAcademicData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
    );
  }

  // ==========================================
  // SCREEN 9: MATA KULIAH
  // ==========================================
  Widget _buildMataKuliah() {
    return AdminCoursesView(
      courses: _courses,
      isLoading: _isLoadingAcademicData,
      loadError: _academicLoadError,
      onBack: () => _navigateTo('dashboard'),
      onReload: _loadAcademicData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
    );
  }

  // ==========================================
  // SCREEN 10: TAHUN AKADEMIK
  // ==========================================
  Widget _buildTahunAkademik() {
    return AdminAcademicYearView(
      academicYears: _academicYears,
      isLoading: _isLoadingAcademicData,
      loadError: _academicLoadError,
      onBack: () => _navigateTo('dashboard'),
      onReload: _loadAcademicData,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
    );
  }

  // ==========================================
  // SHARED ACCOUNT ACTIONS
  // ==========================================
  Future<void> _showCreateStudentAccountDialog() async {
    final profile = await showGlassModal<StudentProfile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateStudentAccountDialog(classes: _classes),
    );
    if (profile == null || !mounted) return;

    _recordAudit(
      action: 'CREATE',
      module: 'AKUN',
      description:
          'Membuat akun mahasiswa ${profile.nama} (${profile.nim}) dan mengirim undangan.',
      metadata: {'nim': profile.nim},
    );

    await _loadManagedAccounts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undangan akun dikirim ke ${profile.email}.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _editManagedAccount(StudentProfile account) async {
    final updated = await showGlassModal<StudentProfile>(
      context: context,
      builder: (_) => EditStudentAccountDialog(account: account),
    );
    if (updated == null || !mounted) return;

    try {
      await AdminAccountService.updateStudentAccount(updated);
      _recordAudit(
        action: 'UPDATE',
        module: 'AKUN',
        description:
            'Memperbarui profil mahasiswa ${updated.nama} (${updated.nim}).',
        metadata: {'nim': updated.nim},
      );
      if (!mounted) return;
      setState(() {
        final index = _managedAccounts.indexWhere(
          (item) => item.nim == account.nim,
        );
        if (index >= 0) _managedAccounts[index] = updated;
        if (_selectedStudent?.nim == updated.nim) _selectedStudent = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data akun berhasil diperbarui.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } on AdminAccountServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _setManagedAccountActive(
    StudentProfile account,
    bool isActive,
  ) async {
    if (account.isAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          isActive ? 'Aktifkan akun kembali?' : 'Nonaktifkan akun?',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          isActive
              ? 'Akun ${account.nama} dapat masuk kembali setelah diaktifkan.'
              : 'Akun ${account.nama} tidak dapat masuk setelah dinonaktifkan. Profil dan riwayatnya tetap disimpan.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: isActive
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final previousValue = account.isAktif;
    setState(() {
      account.isAktif = isActive;
    });
    try {
      await AdminAccountService.setStudentActive(account.nim, isActive);
      _recordAudit(
        action: 'UPDATE',
        module: 'AKUN',
        description:
            '${isActive ? 'Mengaktifkan' : 'Menonaktifkan'} akun ${account.nama} (${account.nim}).',
        metadata: {'nim': account.nim, 'is_aktif': isActive},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Akun diaktifkan.' : 'Akun dinonaktifkan.'),
          backgroundColor: isActive
              ? const Color(0xFF059669)
              : const Color(0xFF4B5563),
        ),
      );
    } on AdminAccountServiceException catch (error) {
      if (!mounted) return;
      setState(() => account.isAktif = previousValue);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteStudentAccount(StudentProfile account) async {
    if (account.isAdmin) return;
    final confirmed = await _confirmDelete(
      'Hapus akun mahasiswa ${account.nama} (NIM: ${account.nim}) secara permanen? Data ini akan dihapus dari sistem.',
    );
    if (!confirmed || !mounted) return;

    try {
      await AdminAccountService.deleteStudentAccount(account.nim);
      _recordAudit(
        action: 'DELETE',
        module: 'AKUN',
        description:
            'Menghapus akun mahasiswa ${account.nama} (${account.nim}).',
        metadata: {'nim': account.nim, 'nama': account.nama},
      );
      if (!mounted) return;
      setState(() {
        _managedAccounts.removeWhere((item) => item.nim == account.nim);
        if (_selectedStudent?.nim == account.nim) _selectedStudent = null;
      });
      _showAdminMessage('Akun ${account.nama} berhasil dihapus.');
    } catch (e) {
      _showAdminMessage('Gagal menghapus akun: $e', isError: true);
    }
  }

  // ==========================================
  // SCREEN 11: MANAJEMEN AKUN
  // ==========================================
  Widget _buildManajemenAkun() {
    return AdminAccountManagementView(
      managedAccounts: _managedAccounts,
      isLoading: _isLoadingAccounts,
      loadError: _accountLoadError,
      onBack: () => _navigateTo('dashboard'),
      onReload: _loadManagedAccounts,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
      onConfirmDelete: _confirmDelete,
      onSelectedStudentChanged: (updated) {
        setState(() {
          if (updated == null) {
            _selectedStudent = null;
          } else {
            _selectedStudent = updated;
          }
        });
      },
    );
  }

  // ==========================================
  // SCREEN 12: PENGATURAN SISTEM
  // ==========================================
  Widget _buildPengaturanSistem() {
    return AdminSystemSettingsView(
      onBack: () => _navigateTo('dashboard'),
      onLogout: widget.onLogout,
      onNavigate: _navigateTo,
      onBroadcastAnnouncement: _showBroadcastAnnouncementDialog,
      registeredTokensCount: _registeredTokensCount,
      academicYears: _academicYears,
      classes: _classes,
      lecturers: _lecturers,
      courses: _courses,
      onShowMessage: _showAdminMessage,
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
    );
  }

  Widget _buildAuditLogScreen() {
    return AdminAuditLogView(
      auditFuture: _auditFuture,
      onRefresh: _loadAuditLogs,
      onBack: () => _navigateTo('pengaturan'),
    );
  }

  // ==========================================
  // EXTRA: ROLE & PERMISSION MATRIX
  Widget _buildRolePermission() {
    return AdminRolesView(
      managedAccounts: _managedAccounts,
      selectedStudent: _selectedStudent,
      onBack: () => _navigateTo('pengaturan'),
      onRecordAudit:
          ({
            required String action,
            required String module,
            required String description,
            Map<String, dynamic>? metadata,
          }) {
            _recordAudit(
              action: action,
              module: module,
              description: description,
              metadata: metadata ?? {},
            );
          },
    );
  }

  // ==========================================
  // EXTRA: LAPORAN ADMIN
  // ==========================================
  Widget _buildLaporan() {
    return AdminReportsView(
      reportFuture: _reportFuture,
      managedAccounts: _managedAccounts,
      onRefresh: () {
        setState(() {
          _reportFuture = _loadReportSnapshot();
        });
      },
      onBack: () => _navigateTo('dashboard'),
      onNavigate: _navigateTo,
    );
  }

  // ==========================================
  // EXTRA: MATRIKS PRESENSI & BAP
  // ==========================================
  Widget _buildMatriksPresensi() {
    return AdminAttendanceMatrixView(
      academicYear: _academicYears.where((year) => year.isAktif).firstOrNull?.tahun ?? 'Belum ditetapkan',
      courses: _courses,
      classes: _classes,
      managedAccounts: _managedAccounts,
      onBack: () => _navigateTo('laporan'),
      onShowMessage: _showAdminMessage,
      onRecordAudit: _recordAudit,
    );
  }
}
