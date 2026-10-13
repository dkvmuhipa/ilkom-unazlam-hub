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
import 'widgets/admin_creation_modals.dart';
import 'models/admin_models.dart';

class AdminShellScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToStudentView;

  const AdminShellScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToStudentView,
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
        setState(() => _reportFuture = _loadReportSnapshot());
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
      if (mounted) {
        _showAdminMessage('Seluruh modul dan data admin berhasil disinkronkan!');
      }
    } catch (e) {
      if (mounted) {
        _showAdminMessage('Sinkronisasi selesai dengan beberapa data offline.', isError: false);
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
        'treasury': 'Rp 0',
        'assignments': '0 tugas tercatat',
        'students': '${_managedAccounts.length} akun mahasiswa',
      };
    }

    List<Map<String, dynamic>> attendance = [];
    List<Map<String, dynamic>> cash = [];
    List<dynamic> assignments = [];
    List<dynamic> students = [];

    try {
      final res = await client.from('attendance_logs').select('status');
      attendance = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {}

    try {
      final res = await client.from('treasury_transactions').select('nominal,is_pemasukan');
      cash = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {}

    try {
      final res = await client.from('assignments').select('id');
      assignments = List<dynamic>.from(res as List);
    } catch (_) {}

    try {
      final res = await client.from('students').select('nim').eq('is_aktif', true).neq('role', 'ADMIN');
      students = List<dynamic>.from(res as List);
    } catch (_) {}

    final present = attendance.where((row) => (row['status']?.toString().toLowerCase() ?? '') == 'hadir').length;
    final attendanceRate = attendance.isEmpty ? null : (present * 100 / attendance.length).round();
    final balance = cash.fold<int>(0, (sum, row) {
      final amount = (row['nominal'] as num?)?.toInt() ?? 0;
      return sum + (row['is_pemasukan'] == true ? amount : -amount);
    });
    final formattedBalance = balance.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

    return {
      'attendance': attendanceRate == null ? 'Kehadiran: Belum ada sesi' : 'Kehadiran tercatat: $attendanceRate% (${attendance.length} catatan)',
      'treasury': 'Saldo dari ${cash.length} transaksi: Rp ${balance < 0 ? '-' : ''}$formattedBalance',
      'assignments': '${assignments.length} tugas aktif tercatat',
      'students': '${students.isNotEmpty ? students.length : _managedAccounts.where((s) => s.isAktif).length} akun mahasiswa aktif',
    };
  }

  Future<void> _loadAcademicData() async {
    if (!mounted) return;
    setState(() { _isLoadingAcademicData = true; _academicLoadError = null; });
    try {
      final results = await Future.wait([
        AdminAcademicService.listClasses(),
        AdminAcademicService.listLecturers(),
        AdminAcademicService.listAcademicYears(),
        SupabaseRepository.getCourses(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = (results[0] as List<Map<String, dynamic>>).map((row) => ClassItem.fromMap(row)).toList();
        _lecturers = (results[1] as List<Map<String, dynamic>>).map((row) => LecturerItem.fromMap(row)).toList();
        _academicYears = (results[2] as List<Map<String, dynamic>>).map((row) => AcademicYearItem.fromMap(row)).toList();
        _courses = results[3] as List<Course>;
      });
    } on AdminAcademicException catch (error) {
      if (mounted) setState(() => _academicLoadError = error.message);
    } catch (error) {
      if (mounted) setState(() => _academicLoadError = 'Data akademik gagal dimuat: $error');
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
      } else if (view == 'laporan') {
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
                        selectedIndex: _navBarIndex,
                        onDestinationSelected: _handleBottomNav,
                        labelType: NavigationRailLabelType.all,
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
    return NavigationBar(
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
    );
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
  // SCREEN 3: DASHBOARD ADMIN
  // ==========================================
  Widget _buildDashboard() {
    final sourceStudents = _managedAccounts.where((s) => !s.isAdmin).toList();
    final activeStudentsCount = sourceStudents.where((s) => s.isAktif).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Clean Tech Console Bar + Right Action Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'KONSOL ADMINISTRATOR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pusat Kendali Akademik',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ilmu Komunikasi â€¢ UNAZLAM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Sinkronisasi Data Master
                  Tooltip(
                    message: 'Sinkronisasi Seluruh Data',
                    child: InkWell(
                      onTap: _isRefreshing ? null : _refreshAllAdminData,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                color: Color(0xFF334155),
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mode Mahasiswa Preview Button
                  InkWell(
                    onTap: widget.onSwitchToStudentView,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Mode Siswa',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bell Notification Icon
                  Tooltip(
                    message: 'Notifikasi Sistem',
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF334155),
                            size: 18,
                          ),
                        ),
                        Positioned(
                          right: 7,
                          top: 7,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Stat Cards in 2x2 Grid (Modern Clean SaaS)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: '${_classes.length}',
                  label: 'Kelas Aktif',
                  icon: Icons.meeting_room_outlined,
                  color: AppColors.primary,
                  badgeText: 'FISIP',
                  badgeVariant: SoftPillVariant.blue,
                  onTap: () => _navigateTo('kelas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  count: '$activeStudentsCount',
                  label: 'Mahasiswa',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.cyan,
                  badgeText: 'Aktif 100%',
                  badgeVariant: SoftPillVariant.cyan,
                  onTap: () => _navigateTo('mahasiswa'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: '${_lecturers.length}',
                  label: 'Dosen Pengajar',
                  icon: Icons.badge_outlined,
                  color: AppColors.emerald,
                  badgeText: 'Dosen FISIP',
                  badgeVariant: SoftPillVariant.emerald,
                  onTap: () => _navigateTo('dosen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  count: '${_courses.length}',
                  label: 'Mata Kuliah',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.amber,
                  badgeText: 'Ganjil 26/27',
                  badgeVariant: SoftPillVariant.amber,
                  onTap: () => _navigateTo('matakuliah'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner Integrasi FCM Push Notification (Modern Dark Console with Indigo Gradient)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF312E81)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: Color(0xFFA5B4FC),
                    size: 19,
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
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Firebase Cloud Messaging (FCM v1)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_registeredTokensCount perangkat mahasiswa siap menerima push otomatis.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _showBroadcastAnnouncementDialog,
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: const Text('Broadcast', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Section "Aksi Cepat Admin"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aksi Cepat Terintegrasi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: _showQuickExportModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ekspor Data',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.campaign_rounded,
                  label: 'Pengumuman',
                  subtitle: 'Kirim Push',
                  color: AppColors.primary,
                  onTap: _showBroadcastAnnouncementDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.post_add_rounded,
                  label: 'Tugas Baru',
                  subtitle: 'Rilis & Notif',
                  color: AppColors.cyan,
                  onTap: _showCreateAssignmentDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Mahasiswa',
                  subtitle: 'Undang Akun',
                  color: AppColors.emerald,
                  onTap: _showCreateStudentAccountDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Section "Menu Utama" (Clean Tech SaaS Grid)
          const Text(
            'Menu Utama Modul',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // 8 Grid Menu Tiles (Screen 3)
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth < 360 ? 2 : 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 96,
              children: [
                _buildMenuTile(
                  icon: Icons.meeting_room_outlined,
                  title: 'Kelas',
                  onTap: () => _navigateTo('kelas'),
                ),
                _buildMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Mahasiswa',
                  onTap: () => _navigateTo('mahasiswa'),
                ),
                _buildMenuTile(
                  icon: Icons.badge_outlined,
                  title: 'Dosen',
                  onTap: () => _navigateTo('dosen'),
                ),
                _buildMenuTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Mata Kuliah',
                  onTap: () => _navigateTo('matakuliah'),
                ),
                _buildMenuTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Tahun\nAkademik',
                  onTap: () => _navigateTo('tahun_akademik'),
                ),
                _buildMenuTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Manajemen\nAkun',
                  onTap: () => _navigateTo('manajemen_akun'),
                ),
                _buildMenuTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan',
                  onTap: () => _navigateTo('laporan'),
                ),
                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan',
                  onTap: () => _navigateTo('pengaturan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Banner Info Sistem (Clean Tech Console Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Kendali Terintegrasi',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tahun Akademik 2026/2027 Ganjil aktif â€¢ Database Supabase',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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

  Widget _buildStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badgeText,
    SoftPillVariant badgeVariant = SoftPillVariant.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.16), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ColorfulIconBox(
                  icon: icon,
                  color: color,
                  size: 38,
                  iconSize: 19,
                  radius: 11,
                ),
                if (badgeText != null)
                  SoftPillBadge(
                    label: badgeText,
                    variant: badgeVariant,
                    fontSize: 10,
                  )
                else
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: color,
                      size: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorfulIconBox(
              icon: icon,
              color: color,
              size: 32,
              iconSize: 16,
              radius: 9,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastAnnouncementDialog() {
    AdminCreationModals.showBroadcastAnnouncementDialog(
      context: context,
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final accentColor = switch (title.replaceAll('\n', ' ')) {
      'Kelas' => AppColors.primary,
      'Mahasiswa' => AppColors.cyan,
      'Dosen' => AppColors.emerald,
      'Mata Kuliah' => AppColors.amber,
      'Tahun Akademik' => AppColors.violet,
      'Manajemen Akun' => AppColors.teal,
      'Laporan' => AppColors.rose,
      _ => const Color(0xFF64748B),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorfulIconBox(
              icon: icon,
              color: accentColor,
              size: 40,
              iconSize: 20,
              radius: 11,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
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
      onRecordAudit: ({
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
      onRecordAudit: ({
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? const Color(0xFFB91C1C) : const Color(0xFF059669)));
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
        metadata: metadata,
      );
      if (_currentView == 'audit_logs' && mounted) {
        setState(() => _auditFuture = AdminAuditService.list());
      }
    }());
  }

  void _loadAuditLogs() {
    setState(() => _auditFuture = AdminAuditService.list());
  }

  Future<bool> _confirmDelete(String message) async => await showDialog<bool>(
    context: context, builder: (ctx) => AlertDialog(title: const Text('Konfirmasi hapus'), content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)), child: const Text('Hapus'))]),
  ) ?? false;

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
      onRecordAudit: ({
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
      onRecordAudit: ({
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
      onRecordAudit: ({
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
      builder: (_) => const CreateStudentAccountDialog(),
    );
    if (profile == null || !mounted) return;

    _recordAudit(
      action: 'CREATE',
      module: 'AKUN',
      description: 'Membuat akun mahasiswa ${profile.nama} (${profile.nim}) dan mengirim undangan.',
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
        description: 'Memperbarui profil mahasiswa ${updated.nama} (${updated.nim}).',
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
        title: Text(isActive ? 'Aktifkan akun kembali?' : 'Nonaktifkan akun?'),
        content: Text(
          isActive
              ? 'Akun ${account.nama} dapat masuk kembali setelah diaktifkan.'
              : 'Akun ${account.nama} tidak dapat masuk setelah dinonaktifkan. Profil dan riwayatnya tetap disimpan.',
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
        description: '${isActive ? 'Mengaktifkan' : 'Menonaktifkan'} akun ${account.nama} (${account.nim}).',
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
        description: 'Menghapus akun mahasiswa ${account.nama} (${account.nim}).',
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
      onRecordAudit: ({
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
      onRecordAudit: ({
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
      onRecordAudit: ({
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
      onRefresh: () => setState(() => _reportFuture = _loadReportSnapshot()),
      onBack: () => _navigateTo('dashboard'),
    );
  }
}

