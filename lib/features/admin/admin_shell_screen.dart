import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/dummy_data.dart';
import '../../core/services/export_service.dart';
import '../../core/services/admin_account_service.dart';
import '../../core/services/admin_academic_service.dart';
import '../../core/services/admin_audit_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import 'create_student_account_dialog.dart';
import 'edit_student_account_dialog.dart';

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
  String? _updatingAccountNim;
  Future<List<Map<String, dynamic>>>? _auditFuture;
  String _auditActionFilter = 'Semua';
  String _auditSearchQuery = '';

  // Local state for dynamic data
  late List<ClassItem> _classes;
  late List<AcademicYearItem> _academicYears;
  late List<Course> _courses;
  late List<LecturerItem> _lecturers;

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
        'students': '${DummyData.students.length} akun mahasiswa',
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
                if (!didPop && _currentView != 'dashboard')
                  _navigateTo('dashboard');
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
    final sourceStudents = _managedAccounts.isNotEmpty
        ? _managedAccounts.where((s) => !s.isAdmin).toList()
        : DummyData.students.where((s) => s.role != 'ADMIN').toList();
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
                              color: Color(0xFF5B3DE8),
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
                      'Ilmu Komunikasi • UNAZLAM',
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
                                  color: Color(0xFF5B3DE8),
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
                            color: Color(0xFF5B3DE8),
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

          // 4 Stat Cards in 2x2 Grid (Clean Tech SaaS)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: '${_classes.length}',
                  label: 'Kelas Aktif',
                  icon: Icons.meeting_room_outlined,
                  color: const Color(0xFF5B3DE8),
                  onTap: () => _navigateTo('kelas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  count: '$activeStudentsCount',
                  label: 'Mahasiswa',
                  icon: Icons.people_outline_rounded,
                  color: const Color(0xFF0284C7),
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
                  color: const Color(0xFF10B981),
                  onTap: () => _navigateTo('dosen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  count: '${_courses.length}',
                  label: 'Mata Kuliah',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => _navigateTo('matakuliah'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner Integrasi FCM Push Notification (High-Contrast Slate Console)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: Color(0xFF818CF8),
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
                          const Text(
                            'Firebase Cloud Messaging (FCM v1)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_registeredTokensCount perangkat mahasiswa siap menerima push otomatis.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showBroadcastAnnouncementDialog,
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: const Text('Broadcast', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      Icon(Icons.download_rounded, size: 13, color: Color(0xFF5B3DE8)),
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
                  color: const Color(0xFF5B3DE8),
                  onTap: _showBroadcastAnnouncementDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.post_add_rounded,
                  label: 'Tugas Baru',
                  subtitle: 'Rilis & Notif',
                  color: const Color(0xFF0284C7),
                  onTap: _showCreateAssignmentDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Mahasiswa',
                  subtitle: 'Undang Akun',
                  color: const Color(0xFF10B981),
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
              physics: const NeverScrollableScrollPhysics>,
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
                    color: Color(0xFF5B3DE8),
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
                        'Tahun Akademik 2026/2027 Ganjil aktif • Database Supabase',
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: Color(0xFF94A3B8),
                  size: 15,
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
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: color, size: 16),
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
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
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'Penting';
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Color(0xFF5B3DE8), size: 24),
              SizedBox(width: 10),
              Text('Broadcast Pengumuman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormLabel('Judul Pengumuman'),
                _buildFormField(controller: titleCtrl, hintText: 'Contoh: Perubahan Jadwal Kuliah & Ujian'),
                const SizedBox(height: 12),
                _buildFormLabel('Kategori'),
                _buildDropdownField<String>(
                  value: category,
                  items: const ['Penting', 'Akademik', 'Info Fakultas', 'Jadwal Kuliah', 'Tugas'],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                _buildFormLabel('Isi Pengumuman'),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan informasi akademik resmi untuk mahasiswa...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sematkan di Atas (Pin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  value: isPinned,
                  onChanged: (v) => setDialogState(() => isPinned = v),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Color(0xFF5B3DE8), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesan ini akan otomatis disebarkan melalui Notifikasi Push FCM ke HP seluruh mahasiswa.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF5B3DE8), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Terbitkan & Push'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8)),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
                  _showAdminMessage('Judul dan isi pengumuman harus diisi.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final ok = await SupabaseRepository.createAnnouncement(
                  judul: titleCtrl.text.trim(),
                  isi: bodyCtrl.text.trim(),
                  kategori: category,
                  isPinned: isPinned,
                  authorName: 'Admin Akademik',
                );
                if (ok) {
                  _recordAudit(
                    action: 'CREATE',
                    module: 'PENGUMUMAN',
                    description: 'Menerbitkan pengumuman "${titleCtrl.text.trim()}" dan mengirim broadcast push.',
                  );
                  _showAdminMessage('Pengumuman resmi diterbitkan & broadcast push dikirimkan!');
                  await _refreshAllAdminData();
                } else {
                  _showAdminMessage('Pengumuman gagal diterbitkan.', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedCourseId = _courses.isNotEmpty ? _courses.first.id : '';
    String selectedCourseName = _courses.isNotEmpty ? _courses.first.nama : 'Perkuliahan Umum';
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    String category = 'Individu';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.post_add_rounded, color: Color(0xFF0EA5E9), size: 24),
              SizedBox(width: 10),
              Text('Rilis Tugas Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormLabel('Judul Tugas'),
                _buildFormField(controller: titleCtrl, hintText: 'Contoh: Analisis Kasus Komunikasi Massa'),
                const SizedBox(height: 12),
                _buildFormLabel('Mata Kuliah'),
                if (_courses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedCourseId.isNotEmpty ? selectedCourseId : _courses.first.id,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCourseId = val;
                          selectedCourseName = _courses.firstWhere((c) => c.id == val, orElse: () => _courses.first).nama;
                        });
                      }
                    },
                  )
                else
                  _buildFormField(controller: TextEditingController(text: 'Belum ada mata kuliah terdaftar'), hintText: ''),
                const SizedBox(height: 12),
                _buildFormLabel('Deskripsi & Petunjuk'),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Rincian tugas, format pengumpulan, bobot penilaian...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFormLabel('Link / Tautan Pengumpulan (Opsional)'),
                _buildFormField(controller: linkCtrl, hintText: 'https://forms.gle/... atau Classroom'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tenggat Waktu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: Text('${deadline.day}/${deadline.month}/${deadline.year} 23:59'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            deadline = DateTime(picked.year, picked.month, picked.day, 23, 59);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton.icon(
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: const Text('Rilis Tugas & Notif'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  _showAdminMessage('Judul tugas harus diisi.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final ok = await SupabaseRepository.createAssignment(
                  courseId: selectedCourseId,
                  courseName: selectedCourseName,
                  judul: titleCtrl.text.trim(),
                  deskripsi: descCtrl.text.trim(),
                  kategori: category,
                  deadline: deadline,
                  linkPengumpulan: linkCtrl.text.trim().isNotEmpty ? linkCtrl.text.trim() : null,
                );
                if (ok) {
                  _recordAudit(
                    action: 'CREATE',
                    module: 'TUGAS',
                    description: 'Merilis tugas "${titleCtrl.text.trim()}" untuk $selectedCourseName.',
                  );
                  _showAdminMessage('Tugas baru berhasil dirilis & notifikasi push dikirimkan!');
                  await _refreshAllAdminData();
                } else {
                  _showAdminMessage('Gagal merilis tugas.', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ekspor Rekapitulasi Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Pilih laporan yang ingin diunduh dalam format berkas CSV/Excel:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981)),
              title: const Text('Rekapitulasi Presensi Perkuliahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Riwayat kehadiran, izin, sakit per mahasiswa', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _navigateTo('laporan');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF5B3DE8)),
              title: const Text('Laporan Kas & Keuangan Kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Seluruh arus kas masuk, pengeluaran & saldo', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _navigateTo('laporan');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.people_alt_rounded, color: Color(0xFF0EA5E9)),
              title: const Text('Data Seluruh Akun Mahasiswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('NIM, nama lengkap, kontak & status aktif', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _navigateTo('manajemen_akun');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final accentColor = switch (title.replaceAll('\n', ' ')) {
      'Kelas' => const Color(0xFF5B3DE8),
      'Mahasiswa' => const Color(0xFF0284C7),
      'Dosen' => const Color(0xFF10B981),
      'Mata Kuliah' => const Color(0xFFF59E0B),
      'Tahun Akademik' => const Color(0xFF8B5CF6),
      'Manajemen Akun' => const Color(0xFF0D9488),
      'Laporan' => const Color(0xFFE11D48),
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.16),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: accentColor, size: 20),
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
    return Column(
      children: [
        _buildAppBar('Data Kelas', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Search Field
              _buildSearchBox(hintText: 'Cari nama kelas...', onChanged: (value) => setState(() => _classSearchQuery = value)),
              if (_academicLoadError != null) _academicErrorBanner(),
              if (_isLoadingAcademicData) const LinearProgressIndicator(),
              const SizedBox(height: 14),

              // Button "+ Tambah Kelas" (Screen 4)
              ElevatedButton(
                onPressed: () => _navigateTo('tambah_kelas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Tambah Kelas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // Class List
              ..._classes.where((cls) => '${cls.nama} ${cls.prodi} ${cls.academicYear}'.toLowerCase().contains(_classSearchQuery.toLowerCase())).map((cls) {
                final studentCount = (_managedAccounts.isNotEmpty ? _managedAccounts : DummyData.students)
                    .where((s) => !s.isAdmin && (s.kelas.toLowerCase() == cls.nama.toLowerCase() || s.semester == cls.semester))
                    .length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showClassDetail(cls),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F0FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF5B3DE8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cls.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear} • $studentCount mahasiswa',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _showClassDetail(cls);
                                } else if (val == 'hapus' && cls.id != null) {
                                  if (await _confirmDelete('Hapus kelas ${cls.nama}?')) {
                                    try {
                                      await AdminAcademicService.deleteClass(cls.id!);
                                      _recordAudit(action: 'DELETE', module: 'KELAS', description: 'Menghapus kelas ${cls.nama}, semester ${cls.semester}.', metadata: {'class_id': cls.id});
                                      await _loadAcademicData();
                                    }
                                    catch (error) { _showAdminMessage(error.toString(), isError: true); }
                                  }
                                } else if (val == 'edit') {
                                  _showClassDialog(existing: cls);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Kelas'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus Kelas',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showClassDetail(ClassItem cls) {
    final classStudents = (_managedAccounts.isNotEmpty ? _managedAccounts : DummyData.students)
        .where((s) => !s.isAdmin && (s.kelas.toLowerCase() == cls.nama.toLowerCase() || s.semester == cls.semester))
        .toList();
    final classCourses = (_courses.isNotEmpty ? _courses : DummyData.courses);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFF5B3DE8), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.nama,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                      Text(
                        '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kapasitas', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text('${cls.kapasitas} Kursi', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mahasiswa Aktif', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text('${classStudents.length} Mahasiswa', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mata Kuliah', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text('${classCourses.length} MK', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final csv = ExportService.exportAttendanceCsv(cls.nama);
                      ExportService.showExportSheet(
                        context,
                        title: 'Presensi ${cls.nama}',
                        fileName: 'presensi_${cls.nama.replaceAll(' ', '_')}.csv',
                        content: csv,
                        subtitle: 'Daftar Presensi Kelas',
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Ekspor Presensi', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showClassDialog(existing: cls);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Kelas', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3DE8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Mahasiswa Terdaftar (${classStudents.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            if (classStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada mahasiswa yang terdaftar di kelas ini.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              )
            else
              ...classStudents.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF3F0FF),
                      child: Text(
                        _getInitials(s.nama),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF111827))),
                          Text('NIM ${s.nim} • ${s.jabatan}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateTo('detail_mahasiswa', student: s);
                      },
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 5: TAMBAH KELAS
  // ==========================================
  Widget _buildTambahKelas() {
    final namaController = TextEditingController(text: 'Ilmu Komunikasi');
    final kapasitasController = TextEditingController(text: '30');
    String selectedProdi = 'Ilmu Komunikasi';
    String selectedSemester = 'Semester 1';
    String selectedTA = '2026/2027';

    return StatefulBuilder(
      builder: (ctx, setFormState) => Column(
        children: [
          _buildAppBar('Tambah Kelas', showSearch: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildFormLabel('Nama Kelas'),
                _buildFormField(
                  controller: namaController,
                  hintText: 'Contoh: Ilmu Komunikasi',
                ),
                const SizedBox(height: 14),

                _buildFormLabel('Program Studi'),
                _buildDropdownField<String>(
                  value: selectedProdi,
                  items: const [
                    'Ilmu Komunikasi',
                    'Ilmu Pemerintahan',
                    'Hubungan Internasional',
                  ],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedProdi = val);
                  },
                ),
                const SizedBox(height: 14),

                _buildFormLabel('Semester'),
                _buildDropdownField<String>(
                  value: selectedSemester,
                  items: const [
                    'Semester 1',
                    'Semester 2',
                    'Semester 3',
                    'Semester 4',
                    'Semester 5',
                    'Semester 6',
                    'Semester 7',
                    'Semester 8',
                  ],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedSemester = val);
                  },
                ),
                const SizedBox(height: 14),

                _buildFormLabel('Tahun Akademik'),
                _buildDropdownField<String>(
                  value: selectedTA,
                  items: const ['2026/2027', '2025/2026', '2024/2025'],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedTA = val);
                  },
                ),
                const SizedBox(height: 14),

                _buildFormLabel('Kapasitas Mahasiswa'),
                _buildFormField(
                  controller: kapasitasController,
                  hintText: 'Contoh: 30',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: () {
                    final semNum =
                        int.tryParse(
                          selectedSemester.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        1;
                    final name = namaController.text.trim();
                    final kap = int.tryParse(kapasitasController.text);
                    if (name.isEmpty || kap == null || kap < 1) { _showAdminMessage('Nama kelas dan kapasitas harus diisi dengan benar.', isError: true); return; }
                    _saveClass(id: null, name: name, prodi: selectedProdi, semester: semNum, year: selectedTA, capacity: kap);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 6: DATA MAHASISWA
  // ==========================================
  String _studentFilter = 'Aktif';
  String _classSearchQuery = '';

  Widget _academicErrorBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
    child: Text(_academicLoadError!, style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12)),
  );

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

  Future<void> _saveClass({String? id, required String name, required String prodi, required int semester, required String year, required int capacity}) async {
    try {
      await AdminAcademicService.saveClass(id: id, nama: name, prodi: prodi, semester: semester, academicYear: year, capacity: capacity);
      _recordAudit(
        action: id == null ? 'CREATE' : 'UPDATE',
        module: 'KELAS',
        description: '${id == null ? 'Menambahkan' : 'Memperbarui'} kelas $name, semester $semester ($year).',
        metadata: {'program_studi': prodi, 'semester': semester, 'tahun_akademik': year, 'kapasitas': capacity},
      );
      await _loadAcademicData();
      if (mounted) _navigateTo('kelas');
      _showAdminMessage(id == null ? 'Kelas berhasil disimpan ke Supabase.' : 'Perubahan kelas berhasil disimpan.');
    } catch (error) { _showAdminMessage(error.toString(), isError: true); }
  }

  Future<void> _showClassDialog({ClassItem? existing}) async {
    final name = TextEditingController(text: existing?.nama ?? '');
    final capacity = TextEditingController(text: '${existing?.kapasitas ?? 30}');
    final prodis = ['Ilmu Komunikasi', 'Ilmu Pemerintahan', 'Hubungan Internasional'];
    final years = _academicYears.map((year) => year.tahun).toList();
    if (existing != null && !years.contains(existing.academicYear)) years.insert(0, existing.academicYear);
    if (years.isEmpty) years.add('2026/2027');
    var prodi = existing?.prodi ?? prodis.first;
    var semester = existing?.semester ?? 1;
    var year = existing?.academicYear ?? years.first;
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: Text(existing == null ? 'Tambah kelas' : 'Edit kelas'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama kelas')),
        DropdownButtonFormField<String>(value: prodi, decoration: const InputDecoration(labelText: 'Program studi'), items: prodis.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setDialog(() => prodi = v); }),
        DropdownButtonFormField<int>(value: semester, decoration: const InputDecoration(labelText: 'Semester'), items: List.generate(8, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('Semester $v'))).toList(), onChanged: (v) { if (v != null) setDialog(() => semester = v); }),
        DropdownButtonFormField<String>(value: year, decoration: const InputDecoration(labelText: 'Tahun akademik'), items: years.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setDialog(() => year = v); }),
        TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kapasitas mahasiswa')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan'))])));
    if (result == true) {
      final cap = int.tryParse(capacity.text);
      if (name.text.trim().isEmpty || cap == null || cap < 1) { _showAdminMessage('Lengkapi nama dan kapasitas kelas.', isError: true); return; }
      await _saveClass(id: existing?.id, name: name.text.trim(), prodi: prodi, semester: semester, year: year, capacity: cap);
    }
  }
  String _studentSearchQuery = '';

  Widget _buildDataMahasiswa() {
    final sourceStudents = _managedAccounts.isNotEmpty
        ? _managedAccounts.where((s) => !s.isAdmin).toList()
        : DummyData.students.where((s) => s.role != 'ADMIN').toList();

    final students = sourceStudents
        .where((s) {
          if (_studentFilter == 'Aktif') return s.isAktif;
          if (_studentFilter == 'Nonaktif') return !s.isAktif;
          return true;
        })
        .where((s) {
          if (_studentSearchQuery.isEmpty) return true;
          final q = _studentSearchQuery.toLowerCase();
          return s.nama.toLowerCase().contains(q) || s.nim.contains(q);
        })
        .toList();

    return Column(
      children: [
        _buildAppBar('Data Mahasiswa', onSearch: () {}),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    _buildSearchBox(
                      hintText: 'Cari nama atau NIM...',
                      onChanged: (val) =>
                          setState(() => _studentSearchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips: Semua, Aktif, Nonaktif
                    Row(
                      children: ['Semua', 'Aktif', 'Nonaktif'].map((f) {
                        final isSel = _studentFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _studentFilter = f),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF5B3DE8)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSel
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final initials = _getInitials(s.nama);
                    final color = _getAvatarColor(i);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _navigateTo('detail_mahasiswa', student: s),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.nama,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.jabatan != 'Mahasiswa')
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            s.jabatan,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'NIM ${s.nim} • Semester ${s.semester}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _navigateTo('detail_mahasiswa', student: s);
                                } else if (val == 'edit') {
                                  await _editManagedAccount(s);
                                  if (mounted) setState(() {});
                                } else if (val == 'toggle') {
                                  await _setManagedAccountActive(s, !s.isAktif);
                                  if (mounted) setState(() {});
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Lihat Detail'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Profil'),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    s.isAktif ? 'Nonaktifkan' : 'Aktifkan Akun',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Button "+ Tambah Mahasiswa" (Screen 6)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  onPressed: _showCreateStudentAccountDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  label: const Text(
                    '+ Tambah & Undang Mahasiswa',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
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
  // SCREEN 7: DETAIL MAHASISWA
  // ==========================================
  int _detailTab = 0;

  Widget _buildDetailMahasiswa() {
    final s = _selectedStudent ?? DummyData.students.first;
    final initials = _getInitials(s.nama);

    return Column(
      children: [
        _buildAppBar(
          'Detail Mahasiswa',
          onBack: () => _navigateTo('mahasiswa'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              // Header Card with Avatar + Name + NIM + Badge Aktif
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.15),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.nama,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIM ${s.nim}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.isAktif
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: s.isAktif
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        s.isAktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.isAktif
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3 Tabs: Informasi, Kelas, Riwayat
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: ['Informasi', 'Kelas', 'Riwayat']
                      .asMap()
                      .entries
                      .map((e) {
                        final isSel = _detailTab == e.key;
                        return Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _detailTab = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSel
                                        ? const Color(0xFF5B3DE8)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSel
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSel
                                      ? const Color(0xFF5B3DE8)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              if (_detailTab == 0) ...[
                // Detail Items (Screen 7)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.person_outline,
                        'Nama Lengkap',
                        s.nama,
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.school_outlined,
                        'Program Studi',
                        s.prodi,
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.account_balance_outlined,
                        'Fakultas',
                        'Ilmu Sosial dan Ilmu Politik (FISIP)',
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.format_list_numbered,
                        'Semester',
                        '${s.semester} (Satu)',
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.meeting_room_outlined,
                        'Kelas',
                        s.kelas,
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.badge_outlined,
                        'Jabatan Organisasi',
                        s.jabatan,
                      ),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.email_outlined, 'Email', s.email),
                      const Divider(height: 18),
                      _buildDetailRow(
                        Icons.phone_outlined,
                        'No. HP',
                        s.noWa.isEmpty ? '-' : s.noWa,
                      ),
                    ],
                  ),
                ),
              ] else if (_detailTab == 1) ...[
                // Tab Kelas & Mata Kuliah Mahasiswa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.class_outlined, color: Color(0xFF5B3DE8), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.kelas,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)),
                                ),
                                Text(
                                  '${s.prodi} • Semester ${s.semester}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '${_courses.isNotEmpty ? _courses.length : DummyData.courses.length} MK Terdaftar',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Daftar Mata Kuliah Semester Ini:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 10),
                      ...(_courses.isNotEmpty ? _courses : DummyData.courses).map((course) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  course.kode,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.nama,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1F2937)),
                                    ),
                                    Text(
                                      '${course.dosen} • ${course.sks} SKS',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${course.sks} SKS',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ] else ...[
                // Tab Riwayat & KHS Mahasiswa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Kehadiran & Akademik',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tingkat Kehadiran', style: TextStyle(fontSize: 10.5, color: Color(0xFF065F46))),
                                  SizedBox(height: 4),
                                  Text('92%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                                  Text('Kategori: Sangat Baik', style: TextStyle(fontSize: 9.5, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Iuran Kas Kelas', style: TextStyle(fontSize: 10.5, color: Color(0xFF166534))),
                                  SizedBox(height: 4),
                                  Text('Lunas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                                  Text('Bulan Oktober 2026', style: TextStyle(fontSize: 9.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aksi Rekap Mahasiswa:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final csv = ExportService.exportPersonalAttendanceCsv(
                            studentNim: s.nim,
                            studentName: s.nama,
                            history: [],
                          );
                          ExportService.showExportSheet(
                            context,
                            title: 'Presensi ${s.nama}',
                            fileName: 'presensi_${s.nim}.csv',
                            content: csv,
                            subtitle: 'Rekap Presensi Individual',
                          );
                        },
                        icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
                        label: const Text('Ekspor Rekap Presensi Mahasiswa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B3DE8),
                          side: const BorderSide(color: Color(0xFF5B3DE8)),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          final dummyGrades = [
                            StudentCourseGrade(id: '1', studentNim: s.nim, courseId: 'c1', courseCode: 'IK101', courseName: 'Pengantar Ilmu Komunikasi', sks: 3, semester: 1, academicYear: '2026/2027', letterGrade: 'A', numericScore: 88, updatedAt: now),
                            StudentCourseGrade(id: '2', studentNim: s.nim, courseId: 'c2', courseCode: 'IK102', courseName: 'Teori Komunikasi', sks: 3, semester: 1, academicYear: '2026/2027', letterGrade: 'A-', numericScore: 82, updatedAt: now),
                            StudentCourseGrade(id: '3', studentNim: s.nim, courseId: 'c3', courseCode: 'IK103', courseName: 'Komunikasi Antarpribadi', sks: 3, semester: 1, academicYear: '2026/2027', letterGrade: 'B+', numericScore: 78, updatedAt: now),
                            StudentCourseGrade(id: '4', studentNim: s.nim, courseId: 'c4', courseCode: 'IK104', courseName: 'Dasar-Dasar Jurnalistik', sks: 3, semester: 1, academicYear: '2026/2027', letterGrade: 'A', numericScore: 90, updatedAt: now),
                          ];
                          final csv = ExportService.exportKhsCsv(
                            student: s,
                            grades: dummyGrades,
                            gpa: 3.75,
                            totalSks: 12,
                          );
                          ExportService.showExportSheet(
                            context,
                            title: 'KHS ${s.nama}',
                            fileName: 'khs_${s.nim}.csv',
                            content: csv,
                            subtitle: 'Kartu Hasil Studi (KHS)',
                          );
                        },
                        icon: const Icon(Icons.school_outlined, size: 16),
                        label: const Text('Ekspor Kartu Hasil Studi (KHS)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Bottom Actions: Edit & Nonaktifkan (Screen 7)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _editManagedAccount(s);
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B3DE8),
                        side: const BorderSide(color: Color(0xFF5B3DE8)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _setManagedAccountActive(s, !s.isAktif);
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: s.isAktif ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        side: BorderSide(color: s.isAktif ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.isAktif ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            s.isAktif ? 'Nonaktifkan' : 'Aktifkan Akun',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 8: DATA DOSEN
  // ==========================================
  String _dosenSearchQuery = '';

  Widget _buildDataDosen() {
    final filtered = _lecturers.where((d) {
      if (_dosenSearchQuery.isEmpty) return true;
      final q = _dosenSearchQuery.toLowerCase();
      return d.nama.toLowerCase().contains(q) ||
          d.mataKuliah.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildAppBar('Data Dosen', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (_academicLoadError != null) _academicErrorBanner(),
              if (_isLoadingAcademicData) const LinearProgressIndicator(),
              _buildSearchBox(
                hintText: 'Cari nama dosen...',
                onChanged: (val) => setState(() => _dosenSearchQuery = val),
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: _showTambahDosenDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Tambah Dosen',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              ...filtered.map((d) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showLecturerDetail(d),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF0284C7),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.mataKuliah,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _showLecturerDetail(d);
                                } else if (val == 'hapus' && await _confirmDelete('Hapus data dosen ${d.nama}?')) {
                                  try {
                                    await AdminAcademicService.deleteLecturer(d.id);
                                    _recordAudit(action: 'DELETE', module: 'DOSEN', description: 'Menghapus data dosen ${d.nama}.', metadata: {'lecturer_id': d.id});
                                    await _loadAcademicData();
                                  }
                                  catch (error) { _showAdminMessage(error.toString(), isError: true); }
                                } else if (val == 'edit') {
                                  _showLecturerDialog(existing: d);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Dosen'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus Dosen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showLecturerDetail(LecturerItem d) {
    final taughtCourses = (_courses.isNotEmpty ? _courses : DummyData.courses).where((c) {
      return c.dosen.toLowerCase().contains(d.nama.toLowerCase()) ||
          d.mataKuliah.toLowerCase().contains(c.nama.toLowerCase());
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nama,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                      Text(
                        d.email.isNotEmpty ? d.email : 'Email belum diatur',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mata Kuliah Utama Diampu:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(d.mataKuliah, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                ],
              ),
            ),
            if (taughtCourses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Mata Kuliah Terkait dalam Jadwal:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              ...taughtCourses.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${c.kode} - ${c.nama} (${c.sks} SKS)', style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showLecturerDialog(existing: d);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B3DE8),
                      side: const BorderSide(color: Color(0xFF5B3DE8)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (await _confirmDelete('Hapus data dosen ${d.nama}?')) {
                        try {
                          await AdminAcademicService.deleteLecturer(d.id);
                          _recordAudit(action: 'DELETE', module: 'DOSEN', description: 'Menghapus dosen ${d.nama}.', metadata: {'lecturer_id': d.id});
                          await _loadAcademicData();
                          _showAdminMessage('Data dosen berhasil dihapus.');
                        } catch (error) {
                          _showAdminMessage(error.toString(), isError: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus Dosen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTambahDosenDialog() {
    _showLecturerDialog();
  }

  Future<void> _showLecturerDialog({LecturerItem? existing}) async {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final matkulCtrl = TextEditingController(text: existing?.mataKuliah ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Dosen Pengampu' : 'Edit Dosen Pengampu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(
              controller: namaCtrl,
              hintText: 'Nama Lengkap & Gelar',
            ),
            const SizedBox(height: 10),
            _buildFormField(
              controller: matkulCtrl,
              hintText: 'Mata Kuliah Diampu',
            ),
            const SizedBox(height: 10),
            _buildFormField(controller: emailCtrl, hintText: 'Email dosen (opsional)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true) {
      if (namaCtrl.text.trim().isEmpty || matkulCtrl.text.trim().isEmpty) { _showAdminMessage('Nama dan mata kuliah wajib diisi.', isError: true); return; }
      try {
        await AdminAcademicService.saveLecturer(id: existing?.id, nama: namaCtrl.text.trim(), email: emailCtrl.text.trim(), course: matkulCtrl.text.trim());
        _recordAudit(action: existing == null ? 'CREATE' : 'UPDATE', module: 'DOSEN', description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} data dosen ${namaCtrl.text.trim()}.', metadata: {'mata_kuliah': matkulCtrl.text.trim()});
        await _loadAcademicData();
        _showAdminMessage('Data dosen tersimpan.');
      }
      catch (error) { _showAdminMessage(error.toString(), isError: true); }
    }
  }

  // ==========================================
  // SCREEN 9: MATA KULIAH
  // ==========================================
  String _matkulSearchQuery = '';

  Widget _buildMataKuliah() {
    final filtered = _courses.where((c) {
      if (_matkulSearchQuery.isEmpty) return true;
      final q = _matkulSearchQuery.toLowerCase();
      return c.nama.toLowerCase().contains(q) ||
          c.kode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildAppBar('Mata Kuliah', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (_academicLoadError != null) _academicErrorBanner(),
              if (_isLoadingAcademicData) const LinearProgressIndicator(),
              _buildSearchBox(
                hintText: 'Cari mata kuliah...',
                onChanged: (val) => setState(() => _matkulSearchQuery = val),
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: _showTambahMataKuliahDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Tambah Mata Kuliah',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              ...filtered.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final color = _getCourseColor(i);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCourseDetail(c),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.kode} • ${c.sks} SKS • ${c.dosen}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _showCourseDetail(c);
                                } else if (val == 'hapus' && await _confirmDelete('Hapus mata kuliah ${c.nama}?')) {
                                  final ok = await SupabaseRepository.deleteCourse(c.id);
                                  if (ok) {
                                    _recordAudit(action: 'DELETE', module: 'MATA_KULIAH', description: 'Menghapus mata kuliah ${c.nama} (${c.kode}).', metadata: {'course_id': c.id});
                                    await _loadAcademicData();
                                    _showAdminMessage('Mata kuliah dihapus.');
                                  }
                                  else { _showAdminMessage('Mata kuliah gagal dihapus.', isError: true); }
                                } else if (val == 'edit') {
                                  _showTambahMataKuliahDialog(existing: c);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Mata Kuliah'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showCourseDetail(Course c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF5B3DE8), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nama,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                      Text(
                        '${c.kode} • ${c.sks} SKS • Semester 1',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      const Text('Dosen Pengampu:', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                      const Spacer(),
                      Expanded(
                        child: Text(c.dosen, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      const Text('Jadwal:', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                      const Spacer(),
                      Text('${c.hari}, ${c.jamMulai} - ${c.jamSelesai}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      const Text('Ruangan:', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                      const Spacer(),
                      Text(c.ruangan, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final csv = ExportService.exportAttendanceCsv(c.nama);
                      ExportService.showExportSheet(
                        context,
                        title: 'Presensi ${c.nama}',
                        fileName: 'presensi_${c.kode}.csv',
                        content: csv,
                        subtitle: 'Rekap Presensi Mata Kuliah',
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Ekspor Presensi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showTambahMataKuliahDialog(existing: c);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Matkul'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3DE8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTambahMataKuliahDialog({Course? existing}) {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final kodeCtrl = TextEditingController(text: existing?.kode ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(controller: namaCtrl, hintText: 'Nama Mata Kuliah'),
            const SizedBox(height: 10),
            _buildFormField(
              controller: kodeCtrl,
              hintText: 'Kode Matkul (Contoh: IK-107)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty || kodeCtrl.text.trim().isEmpty) return;
              final course = Course(id: existing?.id ?? '', nama: namaCtrl.text.trim(), kode: kodeCtrl.text.trim(), dosen: existing?.dosen ?? 'Belum ditentukan', sks: existing?.sks ?? 2, semester: existing?.semester ?? 1, hari: existing?.hari ?? 'Senin', jamMulai: existing?.jamMulai ?? '08:00', jamSelesai: existing?.jamSelesai ?? '09:40', ruangan: existing?.ruangan ?? 'Belum ditentukan');
              final ok = existing == null ? await SupabaseRepository.createCourse(course) : await SupabaseRepository.updateCourse(course);
              if (!ctx.mounted) return;
              if (ok) {
                _recordAudit(action: existing == null ? 'CREATE' : 'UPDATE', module: 'MATA_KULIAH', description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} mata kuliah ${course.nama} (${course.kode}).', metadata: {'course_id': course.id});
                Navigator.pop(ctx);
                await _loadAcademicData();
                _showAdminMessage('Mata kuliah berhasil disimpan.');
              }
              else { _showAdminMessage('Gagal menyimpan. Pastikan sesi admin aktif dan migrasi Supabase sudah diterapkan.', isError: true); }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 10: TAHUN AKADEMIK
  // ==========================================
  Widget _buildTahunAkademik() {
    return Column(
      children: [
        _buildAppBar('Tahun Akademik', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (_academicLoadError != null) _academicErrorBanner(),
              if (_isLoadingAcademicData) const LinearProgressIndicator(),
              ElevatedButton(
                onPressed: _showTambahTahunAkademikDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Tambah Tahun Akademik',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              ..._academicYears.map((ta) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ta.tahun,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      if (ta.isAktif)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onSelected: (val) async {
                          if (val == 'aktif' && ta.id != null) {
                            try {
                              await AdminAcademicService.setActiveAcademicYear(ta.id!);
                              _recordAudit(action: 'UPDATE', module: 'TAHUN_AKADEMIK', description: 'Menetapkan ${ta.tahun} sebagai tahun akademik aktif.', metadata: {'academic_year_id': ta.id});
                              await _loadAcademicData();
                              _showAdminMessage('${ta.tahun} ditetapkan sebagai tahun aktif.');
                            }
                            catch (error) { _showAdminMessage(error.toString(), isError: true); }
                          } else if (val == 'hapus' && ta.id != null && await _confirmDelete('Hapus tahun akademik ${ta.tahun}?')) {
                            try {
                              await AdminAcademicService.deleteAcademicYear(ta.id!);
                              _recordAudit(action: 'DELETE', module: 'TAHUN_AKADEMIK', description: 'Menghapus tahun akademik ${ta.tahun}.', metadata: {'academic_year_id': ta.id});
                              await _loadAcademicData();
                            }
                            catch (error) { _showAdminMessage(error.toString(), isError: true); }
                          } else if (val == 'edit') {
                            _showTambahTahunAkademikDialog(existing: ta);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'aktif',
                            child: Text('Jadikan Tahun Aktif'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(value: 'hapus', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showTambahTahunAkademikDialog({AcademicYearItem? existing}) {
    final ctrl = TextEditingController(text: existing?.tahun ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Tahun Akademik' : 'Edit Tahun Akademik',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: _buildFormField(
          controller: ctrl,
          hintText: 'Contoh: 2027/2028',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final year = ctrl.text.trim();
              if (!RegExp(r'^\d{4}/\d{4}$').hasMatch(year)) { _showAdminMessage('Format tahun harus seperti 2026/2027.', isError: true); return; }
              try {
                await AdminAcademicService.saveAcademicYear(id: existing?.id, year: year);
                _recordAudit(action: existing == null ? 'CREATE' : 'UPDATE', module: 'TAHUN_AKADEMIK', description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} tahun akademik $year.');
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await _loadAcademicData();
                _showAdminMessage('Tahun akademik tersimpan.');
              }
              catch (error) { _showAdminMessage(error.toString(), isError: true); }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 11: MANAJEMEN AKUN
  // ==========================================
  String _accountFilter = 'Admin';

  Future<void> _showCreateStudentAccountDialog() async {
    final profile = await showDialog<StudentProfile>(
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

    setState(() => _accountFilter = 'Mahasiswa');
    await _loadManagedAccounts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undangan akun dikirim ke ${profile.email}.'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  Future<void> _editManagedAccount(StudentProfile account) async {
    final updated = await showDialog<StudentProfile>(
      context: context,
      builder: (_) => EditStudentAccountDialog(account: account),
    );
    if (updated == null || !mounted) return;

    setState(() => _updatingAccountNim = account.nim);
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
    } finally {
      if (mounted) setState(() => _updatingAccountNim = null);
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
      _updatingAccountNim = account.nim;
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
    } finally {
      if (mounted) setState(() => _updatingAccountNim = null);
    }
  }

  Widget _buildManajemenAkun() {
    final admins = _managedAccounts.where((account) => account.isAdmin);
    final students = _managedAccounts.where((account) => !account.isAdmin);

    return Column(
      children: [
        _buildAppBar('Manajemen Akun', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateStudentAccountDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                  label: const Text('Buat akun mahasiswa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter Pills: Semua, Admin, Mahasiswa (Screen 11)
              Row(
                children: ['Semua', 'Admin', 'Mahasiswa'].map((f) {
                  final isSel = _accountFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _accountFilter = f),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF5B3DE8)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              if (_isLoadingAccounts)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_accountLoadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _accountLoadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                )
              else ...[
                if (_accountFilter == 'Admin' || _accountFilter == 'Semua')
                  ...admins.map(_buildManagedAccountTile),
                if (_accountFilter == 'Mahasiswa' || _accountFilter == 'Semua')
                  ...students.map(_buildManagedAccountTile),
                if (_managedAccounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada akun di Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagedAccountTile(StudentProfile account) {
    final isAdmin = account.isAdmin;
    final accent = isAdmin ? const Color(0xFF5B3DE8) : const Color(0xFF0284C7);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.1),
            child: Text(
              _getInitials(account.nama),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.nama,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${account.email}\nNIM: ${account.nim} • ${account.jabatan}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          _accountStatusBadge(account.isAktif),
          PopupMenuButton<String>(
            tooltip: 'Kelola akun',
            enabled: _updatingAccountNim != account.nim,
            onSelected: (action) {
              if (action == 'edit') {
                _editManagedAccount(account);
              } else {
                _setManagedAccountActive(account, action == 'activate');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit data'),
                  ],
                ),
              ),
              if (!isAdmin)
                PopupMenuItem(
                  value: account.isAktif ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        account.isAktif
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                        size: 18,
                        color: account.isAktif
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        account.isAktif ? 'Nonaktifkan akun' : 'Aktifkan akun',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountStatusBadge(bool isActive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
      ),
    ),
    child: Text(
      isActive ? 'Aktif' : 'Nonaktif',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isActive ? const Color(0xFF059669) : const Color(0xFFB91C1C),
      ),
    ),
  );

  // ==========================================
  // SCREEN 12: PENGATURAN SISTEM
  // ==========================================
  Widget _buildPengaturanSistem() {
    return Column(
      children: [
        _buildAppBar('Pengaturan Sistem', showSearch: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              _buildSettingCard(
                icon: Icons.app_shortcut_outlined,
                title: 'Profil Aplikasi',
                onTap: () {
                  _showAppProfileDialog();
                },
              ),
              _buildSettingCard(
                icon: Icons.shield_outlined,
                title: 'Role & Permission',
                onTap: () => _navigateTo('role_permission'),
              ),
              _buildSettingCard(
                icon: Icons.history_rounded,
                title: 'Log Aktivitas Admin',
                onTap: () => _navigateTo('audit_logs'),
              ),
              _buildSettingCard(
                icon: Icons.cloud_download_outlined,
                title: 'Backup Data',
                onTap: () {
                  _showBackupDialog();
                },
              ),
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                onTap: _showNotificationSettingsDialog,
              ),
              _buildSettingCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () {
                  _showAboutDialog();
                },
              ),
              _buildSettingCard(
                icon: Icons.logout_rounded,
                title: 'Keluar',
                color: const Color(0xFFEF4444),
                onTap: widget.onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogScreen() {
    final actions = ['Semua', 'CREATE', 'UPDATE', 'DELETE', 'EXPORT'];
    return Column(children: [
      _buildAppBar('Log Aktivitas Admin', showSearch: false, onSearch: _loadAuditLogs, onBack: () => _navigateTo('pengaturan')),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _auditFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 10),
            Text(snapshot.error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _loadAuditLogs, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
          ])));

          final rows = snapshot.data ?? [];
          final filtered = rows.where((row) {
            final action = row['action_type']?.toString().toUpperCase() ?? '';
            final matchesAction = _auditActionFilter == 'Semua' || action == _auditActionFilter;
            final query = _auditSearchQuery.trim().toLowerCase();
            final text = '${row['user_name'] ?? ''} ${row['user_identifier'] ?? ''} ${row['target_module'] ?? ''} ${row['description'] ?? ''}'.toLowerCase();
            return matchesAction && (query.isEmpty || text.contains(query));
          }).toList();

          return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 20), children: [
            _buildSearchBox(hintText: 'Cari admin, modul, atau aktivitas...', onChanged: (value) => setState(() => _auditSearchQuery = value)),
            const SizedBox(height: 12),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: actions.map((action) {
              final selected = _auditActionFilter == action;
              return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(action), selected: selected, onSelected: (_) => setState(() => _auditActionFilter = action), selectedColor: const Color(0xFFEDE9FE)));
            }).toList())),
            const SizedBox(height: 14),
            if (filtered.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 44), child: Column(children: [
              const Icon(Icons.history_toggle_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 10),
              Text(rows.isEmpty ? 'Belum ada aktivitas tercatat.' : 'Tidak ada aktivitas yang cocok dengan pencarian.', style: const TextStyle(color: Color(0xFF6B7280))),
            ]))
            else ...filtered.map(_buildAuditLogTile),
            if (rows.length >= 200) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Menampilkan 200 aktivitas terbaru.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 11))),
          ]);
        },
      )),
    ]);
  }

  Widget _buildAuditLogTile(Map<String, dynamic> row) {
    final action = row['action_type']?.toString().toUpperCase() ?? 'UPDATE';
    final color = switch (action) {
      'CREATE' => const Color(0xFF059669),
      'DELETE' => const Color(0xFFDC2626),
      'EXPORT' => const Color(0xFF0284C7),
      _ => const Color(0xFF7C3AED),
    };
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    final dateLabel = createdAt == null ? 'Waktu tidak tersedia' : _formatAuditDate(createdAt);
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(switch (action) { 'CREATE' => Icons.add_rounded, 'DELETE' => Icons.delete_outline_rounded, 'EXPORT' => Icons.download_rounded, _ => Icons.edit_outlined }, color: color, size: 19)),
        title: Text(row['description']?.toString() ?? 'Aktivitas admin', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('${row['user_name'] ?? 'Admin'} • ${row['user_identifier'] ?? '-'}\n${row['target_module'] ?? 'LAINNYA'} • $dateLabel', style: const TextStyle(height: 1.45, fontSize: 11, color: Color(0xFF6B7280)))),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(action, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800))),
        onTap: () => _showAuditDetails(row),
      ));
  }

  String _formatAuditDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  void _showAuditDetails(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Detail Aktivitas'),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(row['description']?.toString() ?? '-'),
        const SizedBox(height: 12),
        Text('Admin: ${row['user_name'] ?? '-'} (${row['user_identifier'] ?? '-'})'),
        Text('Modul: ${row['target_module'] ?? '-'}'),
        Text('Tindakan: ${row['action_type'] ?? '-'}'),
        if (metadata != null) ...[const SizedBox(height: 12), const Text('Metadata', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), SelectableText(const JsonEncoder.withIndent('  ').convert(metadata), style: const TextStyle(fontFamily: 'monospace', fontSize: 11))],
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ));
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF111827),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: color == const Color(0xFFEF4444)
                ? color
                : const Color(0xFF5B3DE8),
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Color(0xFF5B3DE8), size: 22),
            SizedBox(width: 10),
            Text('Pengaturan Notifikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.token_rounded, color: Color(0xFF5B3DE8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_registeredTokensCount token FCM aktif terdaftar dari instalasi mahasiswa.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Status Layanan:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Firebase Cloud Messaging (FCM v1) Terintegrasi\n• Supabase Database Webhook & Edge Function Aktif\n• Notifikasi otomatis terkirim saat rilis tugas atau pengumuman baru.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF4B5563)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showBroadcastAnnouncementDialog();
            },
            icon: const Icon(Icons.campaign_outlined, size: 16),
            label: const Text('Kirim Pengumuman'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppProfileDialog() {
    final activeYear = _academicYears.firstWhere(
      (y) => y.isAktif,
      orElse: () => AcademicYearItem(tahun: '2026/2027', isAktif: true),
    ).tahun;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Profil Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ILKOM UNAZLAM Hub',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Platform Manajemen Kelas & Akademik Terpadu',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
            ),
            const Divider(height: 20),
            _buildProfileInfoRow('Target Pengguna', 'Mahasiswa & Pengurus Kelas'),
            _buildProfileInfoRow('Tahun Akademik', activeYear),
            _buildProfileInfoRow('Kelas Terdaftar', '${_classes.length} Kelas'),
            _buildProfileInfoRow('Dosen Pengampu', '${_lecturers.length} Dosen'),
            _buildProfileInfoRow('Mata Kuliah', '${_courses.length} MK'),
            _buildProfileInfoRow('Basis Data', SupabaseService.client != null ? 'Supabase Connected 🟢' : 'Offline / Standalone 🟡'),
            _buildProfileInfoRow('Versi Rilis', 'v2.5.0 Production'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11.5, color: Color(0xFF111827), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Backup & Arsip Data',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: const Text(
          'Unduh salinan data yang tersimpan di Supabase: akun mahasiswa, mata kuliah, tugas, pengumuman, transaksi kas, kelas, dosen, dan tahun akademik.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final client = SupabaseService.client;
                if (client == null) throw Exception('Supabase belum terhubung.');
                final tables = ['students', 'courses', 'assignments', 'announcements', 'treasury_transactions', 'academic_classes', 'lecturers', 'academic_years'];
                final backup = <String, dynamic>{'exported_at': DateTime.now().toUtc().toIso8601String(), 'format_version': 1};
                for (final table in tables) {
                  backup[table] = await client.from(table).select();
                }
                final payload = const JsonEncoder.withIndent('  ').convert(backup);
                ExportService.downloadFile('ilkom_hub_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json', payload);
                _recordAudit(action: 'EXPORT', module: 'BACKUP', description: 'Mengekspor backup JSON data aplikasi.', metadata: {'tabel': tables});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showAdminMessage('Backup JSON dibuat dari data Supabase.');
              } catch (error) {
                _showAdminMessage('Backup gagal: $error', isError: true);
              }
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Ekspor JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tentang ILKOM Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: const Text(
          'Aplikasi Pengelolaan Kelas Terpadu Ilmu Komunikasi Universitas Al-Azhar Menggala (UNAZLAM).\n\n"Satu Kelas, Banyak Cerita, Lebih Banyak Karya."',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: Color(0xFF4B5563),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EXTRA: ROLE & PERMISSION MATRIX
  // ==========================================
  String _roleFilter = 'Semua';
  String _roleSearchQuery = '';

  Widget _buildRolePermission() {
    final sourceStudents = _managedAccounts.isNotEmpty
        ? _managedAccounts.where((s) => !s.isAdmin).toList()
        : DummyData.students.where((s) => s.role != 'ADMIN').toList();

    final filtered = sourceStudents.where((s) {
      if (_roleFilter != 'Semua' && s.jabatan != _roleFilter) return false;
      if (_roleSearchQuery.isNotEmpty) {
        final q = _roleSearchQuery.toLowerCase();
        return s.nama.toLowerCase().contains(q) || s.nim.contains(q);
      }
      return true;
    }).toList();

    final roleFilters = ['Semua', 'Ketua Kelas', 'Wakil Ketua', 'Bendahara', 'Sekretaris', 'Mahasiswa'];

    return Column(
      children: [
        _buildAppBar(
          'Role & Permission',
          showSearch: false,
          onBack: () => _navigateTo('pengaturan'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF5B3DE8),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Role Sistem adalah MAHASISWA. Atur Jabatan Struktural untuk memberikan wewenang operasional kelas (Presensi, Pengumuman, Agenda, Kas).',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5B3DE8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Box
              _buildSearchBox(
                hintText: 'Cari nama atau NIM mahasiswa...',
                onChanged: (val) => setState(() => _roleSearchQuery = val),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: roleFilters.map((f) {
                    final isSel = _roleFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSel,
                        selectedColor: const Color(0xFFEDE9FE),
                        onSelected: (_) => setState(() => _roleFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'Tidak ada mahasiswa yang cocok dengan filter.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                    ),
                  ),
                )
              else
                ...filtered.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF3F0FF),
                          child: Text(
                            _getInitials(s.nama),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B3DE8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.nama,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'NIM ${s.nim} • Semester ${s.semester}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: DropdownButton<String>(
                            value: s.jabatan,
                            underline: const SizedBox(),
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B3DE8),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Ketua Kelas',
                                child: Text('Ketua Kelas'),
                              ),
                              DropdownMenuItem(
                                value: 'Wakil Ketua',
                                child: Text('Wakil Ketua'),
                              ),
                              DropdownMenuItem(
                                value: 'Bendahara',
                                child: Text('Bendahara'),
                              ),
                              DropdownMenuItem(
                                value: 'Sekretaris',
                                child: Text('Sekretaris'),
                              ),
                              DropdownMenuItem(
                                value: 'Mahasiswa',
                                child: Text('Mahasiswa'),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val != null && val != s.jabatan) {
                                final previous = s.jabatan;
                                final ok = await SupabaseRepository.updateStudentJabatan(s.nim, val);
                                if (!mounted) return;
                                if (ok) {
                                  setState(() {
                                    s.jabatan = val;
                                    final idx = _managedAccounts.indexWhere((m) => m.nim == s.nim);
                                    if (idx >= 0) _managedAccounts[idx].jabatan = val;
                                    if (_selectedStudent?.nim == s.nim) _selectedStudent?.jabatan = val;
                                  });
                                  _recordAudit(
                                    action: 'UPDATE',
                                    module: 'ROLE',
                                    description: 'Mengubah jabatan ${s.nama} (${s.nim}) dari $previous menjadi $val.',
                                    metadata: {'nim': s.nim, 'from': previous, 'to': val},
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Jabatan ${s.nama} berhasil diubah menjadi $val.'),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gagal menyimpan jabatan. Coba lagi.'),
                                      backgroundColor: Color(0xFFB91C1C),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // EXTRA: LAPORAN ADMIN
  // ==========================================
  Widget _buildLaporan() {
    return Column(
      children: [
        _buildAppBar('Laporan & Rekapitulasi', showSearch: false, onSearch: () => setState(() => _reportFuture = _loadReportSnapshot())),
        Expanded(
          child: FutureBuilder<Map<String, String>>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 36),
                  const SizedBox(height: 10),
                  Text('Laporan gagal dimuat: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: () => setState(() => _reportFuture = _loadReportSnapshot()), icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
                ])));
              }
              final report = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF5B3DE8), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ketuk laporan untuk melihat pratinjau data dan mengekspor berkas dalam format CSV / Excel.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF5B3DE8), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildReportCard(
                    title: 'Rekap Presensi Seluruh Kelas',
                    subtitle: report['attendance']!,
                    icon: Icons.checklist_rounded,
                    color: const Color(0xFF10B981),
                    onDownload: () {
                      final csv = ExportService.exportAttendanceCsv('Semua Mata Kuliah');
                      ExportService.showExportSheet(
                        context,
                        title: 'Rekap Presensi Mahasiswa',
                        fileName: 'rekap_presensi_semua_kelas.csv',
                        content: csv,
                        subtitle: 'Daftar Presensi Seluruh Kelas',
                      );
                    },
                  ),
                  _buildReportCard(
                    title: 'Laporan Keuangan Kas Kelas',
                    subtitle: report['treasury']!,
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF5B3DE8),
                    onDownload: () async {
                      List<TreasuryTransaction> txs = DummyData.treasuryTransactions;
                      try {
                        final live = await SupabaseRepository.getTreasuryTransactions();
                        if (live.isNotEmpty) txs = live;
                      } catch (_) {}
                      if (!mounted) return;
                      final csv = ExportService.exportTreasuryCsv(transactions: txs);
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Laporan Kas Kelas',
                          fileName: 'laporan_kas_kelas_${DateTime.now().year}.csv',
                          content: csv,
                          subtitle: 'Rekap Transaksi & Saldo Kas Kelas',
                        );
                      }
                    },
                  ),
                  _buildReportCard(
                    title: 'Distribusi Tugas Mahasiswa',
                    subtitle: report['assignments']!,
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFFF59E0B),
                    onDownload: () async {
                      List<Assignment> asgs = DummyData.assignments;
                      try {
                        final live = await SupabaseRepository.getAssignments();
                        if (live.isNotEmpty) asgs = live;
                      } catch (_) {}
                      if (!mounted) return;
                      final csv = ExportService.exportAssignmentsCsv(assignments: asgs);
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Distribusi Tugas Kuliah',
                          fileName: 'rekap_distribusi_tugas.csv',
                          content: csv,
                          subtitle: 'Daftar Tugas dan Tenggat Pengumpulan',
                        );
                      }
                    },
                  ),
                  _buildReportCard(
                    title: 'Akun Mahasiswa Aktif',
                    subtitle: report['students']!,
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0284C7),
                    onDownload: () {
                      final students = _managedAccounts.isNotEmpty ? _managedAccounts : DummyData.students;
                      final csv = ExportService.exportStudentsCsv(students: students);
                      ExportService.showExportSheet(
                        context,
                        title: 'Daftar Akun Mahasiswa Terdaftar',
                        fileName: 'data_mahasiswa_aktif.csv',
                        content: csv,
                        subtitle: 'Master Data Profil Mahasiswa',
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onDownload,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDownload,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'CSV',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
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
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildAppBar(
    String title, {
    bool showSearch = true,
    VoidCallback? onSearch,
    VoidCallback? onBack,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: onBack ?? () => _navigateTo('dashboard'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 20),
              onPressed: onSearch ?? () {},
            ),
          if (!showSearch && onSearch != null)
            IconButton(
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A), size: 20),
              onPressed: onSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBox({
    required String hintText,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(value: item, child: Text('$item')),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFFF59E0B), // Yellow/Orange (NF)
      Color(0xFF0284C7), // Blue (AR)
      Color(0xFF8B5CF6), // Purple (AN)
      Color(0xFF1E3A8A), // Dark blue (MR)
      Color(0xFFEC4899), // Pink (SN)
      Color(0xFFD97706), // Orange (DH)
    ];
    return colors[index % colors.length];
  }

  Color _getCourseColor(int index) {
    const colors = [
      Color(0xFFF59E0B), // Pancasila (Yellow)
      Color(0xFF10B981), // Kewarganegaraan (Green)
      Color(0xFF8B5CF6), // Agama Islam (Purple)
      Color(0xFFEC4899), // Agama Kristen (Pink)
      Color(0xFF0284C7), // Ilmu Kealaman Dasar (Blue)
      Color(0xFF6366F1), // Dasar Ilmu Komunikasi (Indigo)
    ];
    return colors[index % colors.length];
  }
}

// Local helper classes
class ClassItem {
  final String? id;
  final String nama;
  final String prodi;
  final int semester;
  final int jumlahMahasiswa;
  final String academicYear;
  final int kapasitas;

  ClassItem({
    this.id,
    required this.nama,
    this.prodi = 'Ilmu Komunikasi',
    required this.semester,
    required this.jumlahMahasiswa,
    this.academicYear = '2026/2027',
    this.kapasitas = 30,
  });
  factory ClassItem.fromMap(Map<String, dynamic> map) => ClassItem(
    id: map['id']?.toString(), nama: map['nama']?.toString() ?? '',
    prodi: map['prodi']?.toString() ?? 'Ilmu Komunikasi',
    semester: (map['semester'] as num?)?.toInt() ?? 1, jumlahMahasiswa: 0,
    academicYear: map['academic_year']?.toString() ?? '', kapasitas: (map['kapasitas'] as num?)?.toInt() ?? 30,
  );
}

class AcademicYearItem {
  final String? id;
  final String tahun;
  bool isAktif;

  AcademicYearItem({this.id, required this.tahun, required this.isAktif});
  factory AcademicYearItem.fromMap(Map<String, dynamic> map) => AcademicYearItem(
    id: map['id']?.toString(), tahun: map['tahun']?.toString() ?? '', isAktif: map['is_aktif'] == true,
  );
}

class LecturerItem {
  final String id;
  final String nama;
  final String mataKuliah;
  final String email;

  LecturerItem({
    required this.id,
    required this.nama,
    required this.mataKuliah,
    required this.email,
  });
  factory LecturerItem.fromMap(Map<String, dynamic> map) => LecturerItem(
    id: map['id']?.toString() ?? '', nama: map['nama']?.toString() ?? '',
    mataKuliah: map['mata_kuliah']?.toString() ?? '', email: map['email']?.toString() ?? '',
  );
}
