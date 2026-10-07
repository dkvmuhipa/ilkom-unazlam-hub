import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/admin_account_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';
import 'create_student_account_dialog.dart';

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
  String? _accountLoadError;

  // Local state for dynamic data
  late List<ClassItem> _classes;
  late List<AcademicYearItem> _academicYears;
  late List<Course> _courses;
  late List<LecturerItem> _lecturers;

  @override
  void initState() {
    super.initState();
    _classes = [
      ClassItem(nama: 'Ilmu Komunikasi', semester: 1, jumlahMahasiswa: 25),
      ClassItem(nama: 'Ilmu Komunikasi', semester: 3, jumlahMahasiswa: 28),
      ClassItem(nama: 'Ilmu Komunikasi', semester: 5, jumlahMahasiswa: 24),
      ClassItem(nama: 'Ilmu Komunikasi', semester: 7, jumlahMahasiswa: 22),
    ];
    _academicYears = [
      AcademicYearItem(tahun: '2026/2027', isAktif: true),
      AcademicYearItem(tahun: '2025/2026', isAktif: false),
      AcademicYearItem(tahun: '2024/2025', isAktif: false),
      AcademicYearItem(tahun: '2023/2024', isAktif: false),
    ];
    _courses = List.from(DummyData.courses);
    _lecturers = [
      LecturerItem(id: 'lec_1', nama: 'Bapak Muh Fadly, S.Ag., M.Ag.', mataKuliah: 'Pendidikan Agama Islam', email: 'fadly@unazlam.ac.id'),
      LecturerItem(id: 'lec_2', nama: 'Bapak Jefri, S.Pd., M.Hum.', mataKuliah: 'Pendidikan Agama Kristen', email: 'jefri@unazlam.ac.id'),
      LecturerItem(id: 'lec_3', nama: 'Bapak Meldi Wijaya, M.Pd.', mataKuliah: 'Ilmu Kealaman Dasar', email: 'meldi@unazlam.ac.id'),
      LecturerItem(id: 'lec_4', nama: 'Ibu Ade Ayu Agustina, M.I.Kom.', mataKuliah: 'Dasar-Dasar Ilmu Komunikasi', email: 'adeayu@unazlam.ac.id'),
      LecturerItem(id: 'lec_5', nama: 'Bapak Dr. H. M. Yusuf, M.Si.', mataKuliah: 'Pendidikan Pancasila', email: 'yusuf@unazlam.ac.id'),
      LecturerItem(id: 'lec_6', nama: 'Bapak Drs. H. Ahmad, M.Pd.', mataKuliah: 'Pendidikan Kewarganegaraan', email: 'ahmad@unazlam.ac.id'),
      LecturerItem(id: 'lec_7', nama: 'Ibu Siti Rahmawati, M.I.Kom.', mataKuliah: 'Pengantar Ilmu Komunikasi', email: 'siti@unazlam.ac.id'),
      LecturerItem(id: 'lec_8', nama: 'Bapak Hendra Saputra, M.Si.', mataKuliah: 'Etika Komunikasi', email: 'hendra@unazlam.ac.id'),
    ];
  }

  void _navigateTo(String view, {StudentProfile? student}) {
    setState(() {
      _currentView = view;
      if (student != null) _selectedStudent = student;

      // Sync bottom navigation index
      if (view == 'dashboard') {
        _navBarIndex = 0;
      } else if (view == 'kelas' || view == 'mahasiswa' || view == 'tambah_kelas' || view == 'detail_mahasiswa') {
        _navBarIndex = 1;
      } else if (view == 'dosen' || view == 'matakuliah' || view == 'tahun_akademik') {
        _navBarIndex = 2;
      } else if (view == 'laporan') {
        _navBarIndex = 3;
      } else if (view == 'pengaturan' || view == 'role_permission' || view == 'manajemen_akun') {
        _navBarIndex = 4;
      }
    });
    if (view == 'manajemen_akun') unawaited(_loadManagedAccounts());
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: PopScope(
          canPop: _currentView == 'dashboard',
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _currentView != 'dashboard') {
              _navigateTo('dashboard');
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            body: SafeArea(
              child: _buildCurrentView(),
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _navBarIndex,
        onTap: _handleBottomNav,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5B3DE8),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded, size: 22),
            activeIcon: Icon(Icons.dashboard_rounded, size: 22),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined, size: 22),
            activeIcon: Icon(Icons.folder_rounded, size: 22),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined, size: 22),
            activeIcon: Icon(Icons.school_rounded, size: 22),
            label: 'Akademik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_rounded, size: 22),
            activeIcon: Icon(Icons.insert_chart_rounded, size: 22),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 22),
            activeIcon: Icon(Icons.person_rounded, size: 22),
            label: 'Profil',
          ),
        ],
      ),
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
      default:
        return _buildDashboard();
    }
  }

  // ==========================================
  // SCREEN 3: DASHBOARD ADMIN
  // ==========================================
  Widget _buildDashboard() {
    final activeStudentsCount = DummyData.students.where((s) => s.role != 'ADMIN').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Greeting + Notification Bell + Mode Mahasiswa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Ilmu Komunikasi • UNAZLAM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Mode Mahasiswa Preview Button
                  InkWell(
                    onTap: widget.onSwitchToStudentView,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF5B3DE8)),
                          SizedBox(width: 4),
                          Text(
                            'Siswa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B3DE8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bell Notification Icon
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF5B3DE8), size: 22),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Stat Cards in 2x2 Grid (Screen 3)
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
              const SizedBox(width: 14),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: '${_lecturers.length}',
                  label: 'Dosen',
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => _navigateTo('dosen'),
                ),
              ),
              const SizedBox(width: 14),
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
          const SizedBox(height: 26),

          // Section "Menu Utama" (Screen 3)
          const Text(
            'Menu Utama',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          // 8 Grid Menu Tiles (Screen 3)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
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
          const SizedBox(height: 24),

          // Banner Info Sistem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3DE8), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Kendali Administrator',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tahun Akademik 2026/2027 Ganjil aktif.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9D5FF), width: 0.8),
            ),
            child: Icon(icon, color: const Color(0xFF5B3DE8), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
              height: 1.15,
            ),
          ),
        ],
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
              _buildSearchBox(hintText: 'Cari nama kelas...'),
              const SizedBox(height: 14),

              // Button "+ Tambah Kelas" (Screen 4)
              ElevatedButton(
                onPressed: () => _navigateTo('tambah_kelas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('+ Tambah Kelas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(height: 16),

              // Class List
              ..._classes.map((cls) {
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.groups_rounded, color: Color(0xFF5B3DE8), size: 22),
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
                              'Semester ${cls.semester} • ${cls.jumlahMahasiswa} Mahasiswa',
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
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Aksi $val untuk kelas ${cls.nama}')),
                          );
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'detail', child: Text('Detail Kelas')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Data')),
                          const PopupMenuItem(value: 'hapus', child: Text('Hapus Kelas', style: TextStyle(color: Colors.red))),
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
                _buildFormField(controller: namaController, hintText: 'Contoh: Ilmu Komunikasi'),
                const SizedBox(height: 14),

                _buildFormLabel('Program Studi'),
                _buildDropdownField<String>(
                  value: selectedProdi,
                  items: const ['Ilmu Komunikasi', 'Ilmu Pemerintahan', 'Hubungan Internasional'],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedProdi = val);
                  },
                ),
                const SizedBox(height: 14),

                _buildFormLabel('Semester'),
                _buildDropdownField<String>(
                  value: selectedSemester,
                  items: const ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'],
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
                _buildFormField(controller: kapasitasController, hintText: 'Contoh: 30', keyboardType: TextInputType.number),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: () {
                    final semNum = int.tryParse(selectedSemester.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                    final kap = int.tryParse(kapasitasController.text) ?? 25;
                    setState(() {
                      _classes.add(ClassItem(
                        nama: namaController.text.trim().isEmpty ? 'Ilmu Komunikasi' : namaController.text.trim(),
                        semester: semNum,
                        jumlahMahasiswa: kap,
                      ));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kelas baru berhasil ditambahkan!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    _navigateTo('kelas');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
  String _studentSearchQuery = '';

  Widget _buildDataMahasiswa() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').where((s) {
      if (_studentFilter == 'Aktif') return s.isAktif;
      if (_studentFilter == 'Nonaktif') return !s.isAktif;
      return true;
    }).where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.nama.toLowerCase().contains(q) || s.nim.contains(q);
    }).toList();

    return Column(
      children: [
        _buildAppBar('Data Mahasiswa', onSearch: () {}),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Search Bar
                    _buildSearchBox(
                      hintText: 'Cari nama atau NIM...',
                      onChanged: (val) => setState(() => _studentSearchQuery = val),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF4B5563),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final initials = _getInitials(s.nama);
                    final color = _getAvatarColor(i);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: InkWell(
                        onTap: () => _navigateTo('detail_mahasiswa', student: s),
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
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
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
                              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                              onSelected: (val) {
                                if (val == 'detail') {
                                  _navigateTo('detail_mahasiswa', student: s);
                                } else if (val == 'toggle') {
                                  setState(() => s.isAktif = !s.isAktif);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Akun ${s.nama} diubah jadi ${s.isAktif ? "Aktif" : "Nonaktif"}')),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'detail', child: Text('Lihat Detail')),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(s.isAktif ? 'Nonaktifkan' : 'Aktifkan Akun'),
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
                child: ElevatedButton(
                  onPressed: _showTambahMahasiswaDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('+ Tambah Mahasiswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTambahMahasiswaDialog() {
    final namaCtrl = TextEditingController();
    final nimCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Mahasiswa Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(controller: namaCtrl, hintText: 'Nama Lengkap'),
            const SizedBox(height: 10),
            _buildFormField(controller: nimCtrl, hintText: 'NIM (9 Digit)', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (namaCtrl.text.isNotEmpty && nimCtrl.text.isNotEmpty) {
                setState(() {
                  DummyData.students.add(StudentProfile(
                    id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                    nama: namaCtrl.text.trim(),
                    nim: nimCtrl.text.trim(),
                    email: '${nimCtrl.text.trim()}@unazlam.ac.id',
                    noWa: '+62 821-xxxx-xxxx',
                    peminatan: 'Public Relations',
                    prodi: 'Ilmu Komunikasi',
                    semester: 1,
                    kelas: 'Ilmu Komunikasi',
                    role: 'MAHASISWA',
                    jabatan: 'Mahasiswa',
                    isAktif: true,
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mahasiswa berhasil ditambahkan!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
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
        _buildAppBar('Detail Mahasiswa', onBack: () => _navigateTo('mahasiswa')),
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
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
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
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.isAktif ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: s.isAktif ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        s.isAktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.isAktif ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                  children: ['Informasi', 'Kelas', 'Riwayat'].asMap().entries.map((e) {
                    final isSel = _detailTab == e.key;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _detailTab = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSel ? const Color(0xFF5B3DE8) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            e.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                      _buildDetailRow(Icons.person_outline, 'Nama Lengkap', s.nama),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.school_outlined, 'Program Studi', s.prodi),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.account_balance_outlined, 'Fakultas', 'Ilmu Sosial dan Ilmu Politik (FISIP)'),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.format_list_numbered, 'Semester', '${s.semester} (Satu)'),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.meeting_room_outlined, 'Kelas', s.kelas),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.badge_outlined, 'Jabatan Organisasi', s.jabatan),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.email_outlined, 'Email', s.email),
                      const Divider(height: 18),
                      _buildDetailRow(Icons.phone_outlined, 'No. HP', s.noWa.isEmpty ? '-' : s.noWa),
                    ],
                  ),
                ),
              ] else if (_detailTab == 1) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kelas yang Diikuti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      SizedBox(height: 10),
                      Text('• ILKOM Semester 1 (Pagi) - Angkatan 2026', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      SizedBox(height: 4),
                      Text('• Beban SKS: 20 SKS Paket Semester 1', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Aktivitas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      SizedBox(height: 10),
                      Text('• Terdaftar pada KRS Semester 1 Ganjil 2026', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      SizedBox(height: 4),
                      Text('• Presensi Kehadiran: 90% (Tertib)', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Form edit profil untuk ${s.nama} dibuka')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B3DE8),
                        side: const BorderSide(color: Color(0xFF5B3DE8)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => s.isAktif = !s.isAktif);
                        SupabaseRepository.toggleStudentStatus(s.nim, s.isAktif);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Status mahasiswa ${s.nama} diubah!')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(s.isAktif ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(fontWeight: FontWeight.w700)),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
      return d.nama.toLowerCase().contains(q) || d.mataKuliah.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildAppBar('Data Dosen', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('+ Tambah Dosen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(height: 16),

              ...filtered.map((d) {
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 22),
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
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Aksi $val untuk dosen ${d.nama}')),
                          );
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'detail', child: Text('Detail Dosen')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Data')),
                          const PopupMenuItem(value: 'hapus', child: Text('Hapus Dosen', style: TextStyle(color: Colors.red))),
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

  void _showTambahDosenDialog() {
    final namaCtrl = TextEditingController();
    final matkulCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Dosen Pengampu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(controller: namaCtrl, hintText: 'Nama Lengkap & Gelar'),
            const SizedBox(height: 10),
            _buildFormField(controller: matkulCtrl, hintText: 'Mata Kuliah Diampu'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (namaCtrl.text.isNotEmpty && matkulCtrl.text.isNotEmpty) {
                setState(() {
                  _lecturers.add(LecturerItem(
                    id: 'lec_${DateTime.now().millisecondsSinceEpoch}',
                    nama: namaCtrl.text.trim(),
                    mataKuliah: matkulCtrl.text.trim(),
                    email: '${namaCtrl.text.trim().toLowerCase().replaceAll(' ', '.')}@unazlam.ac.id',
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dosen berhasil ditambahkan!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 9: MATA KULIAH
  // ==========================================
  String _matkulSearchQuery = '';

  Widget _buildMataKuliah() {
    final filtered = _courses.where((c) {
      if (_matkulSearchQuery.isEmpty) return true;
      final q = _matkulSearchQuery.toLowerCase();
      return c.nama.toLowerCase().contains(q) || c.kode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildAppBar('Mata Kuliah', onSearch: () {}),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('+ Tambah Mata Kuliah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(height: 16),

              ...filtered.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final color = _getCourseColor(i);

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.description_outlined, color: color, size: 22),
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
                              '${c.kode} • Semester 1',
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
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Aksi $val untuk ${c.nama}')),
                          );
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'detail', child: Text('Detail Mata Kuliah')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Data')),
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

  void _showTambahMataKuliahDialog() {
    final namaCtrl = TextEditingController();
    final kodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Mata Kuliah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(controller: namaCtrl, hintText: 'Nama Mata Kuliah'),
            const SizedBox(height: 10),
            _buildFormField(controller: kodeCtrl, hintText: 'Kode Matkul (Contoh: IK-107)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (namaCtrl.text.isNotEmpty && kodeCtrl.text.isNotEmpty) {
                setState(() {
                  _courses.add(Course(
                    id: 'crs_${DateTime.now().millisecondsSinceEpoch}',
                    nama: namaCtrl.text.trim(),
                    kode: kodeCtrl.text.trim(),
                    dosen: 'Dosen Pengampu',
                    sks: 2,
                    semester: 1,
                    hari: 'Senin',
                    jamMulai: '08:00',
                    jamSelesai: '09:40',
                    ruangan: 'R. Teori 2',
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mata kuliah berhasil ditambahkan!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
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
              ElevatedButton(
                onPressed: _showTambahTahunAkademikDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('+ Tambah Tahun Akademik', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(height: 16),

              ..._academicYears.map((ta) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                        onSelected: (val) {
                          if (val == 'aktif') {
                            setState(() {
                              for (var item in _academicYears) {
                                item.isAktif = false;
                              }
                              ta.isAktif = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tahun Akademik ${ta.tahun} dijadikan aktif')),
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'aktif', child: Text('Jadikan Tahun Aktif')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
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

  void _showTambahTahunAkademikDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Tahun Akademik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: _buildFormField(controller: ctrl, hintText: 'Contoh: 2027/2028'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  _academicYears.insert(0, AcademicYearItem(tahun: ctrl.text.trim(), isAktif: false));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tahun akademik berhasil ditambahkan!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
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

    setState(() => _accountFilter = 'Mahasiswa');
    await _loadManagedAccounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undangan akun dikirim ke ${profile.email}.'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF4B5563),
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
          if (isAdmin)
            _accountStatusBadge(account.isAktif)
          else
            Switch(
              value: account.isAktif,
              activeThumbColor: const Color(0xFF10B981),
              onChanged: (value) async {
                setState(() => account.isAktif = value);
                final saved = await SupabaseRepository.toggleStudentStatus(
                  account.nim,
                  value,
                );
                if (!saved && mounted) {
                  setState(() => account.isAktif = !value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status akun gagal diperbarui di Supabase.'),
                    ),
                  );
                }
              },
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
                icon: Icons.cloud_download_outlined,
                title: 'Backup Data',
                onTap: () {
                  _showBackupDialog();
                },
              ),
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan notifikasi push aktif')),
                  );
                },
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
          leading: Icon(icon, color: color == const Color(0xFFEF4444) ? color : const Color(0xFF5B3DE8), size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showAppProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profil Aplikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Aplikasi: ILKOM UNAZLAM Hub', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(height: 6),
            Text('Target: Mahasiswa & Pengurus Kelas', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
            SizedBox(height: 4),
            Text('Semester: 1 (Ganjil 2026/2027)', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
            SizedBox(height: 4),
            Text('Versi: 2.4.0 (RBAC Production Ready)', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
            child: const Text('Tutup'),
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
        title: const Text('Backup & Arsip Data', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Seluruh data kelas, profil 25 mahasiswa, 8 dosen, dan transaksi kas dapat dicadangkan secara lokal atau disinkronkan ke Supabase.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup data JSON berhasil diekspor!'), backgroundColor: Color(0xFF10B981)),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Ekspor JSON'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
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
        title: const Text('Tentang ILKOM Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Aplikasi Pengelolaan Kelas Terpadu Ilmu Komunikasi Universitas Al-Azhar Menggala (UNAZLAM).\n\n"Satu Kelas, Banyak Cerita, Lebih Banyak Karya."',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF4B5563)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3DE8), foregroundColor: Colors.white),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EXTRA: ROLE & PERMISSION MATRIX
  // ==========================================
  Widget _buildRolePermission() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();

    return Column(
      children: [
        _buildAppBar('Role & Permission', showSearch: false, onBack: () => _navigateTo('pengaturan')),
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
                    Icon(Icons.info_outline, color: Color(0xFF5B3DE8), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Role Sistem adalah MAHASISWA. Atur Jabatan Struktural untuk memberikan wewenang operasional kelas.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF5B3DE8), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...students.map((s) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nama,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('NIM ${s.nim}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: s.jabatan,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                        items: const [
                          DropdownMenuItem(value: 'Ketua Kelas', child: Text('Ketua Kelas')),
                          DropdownMenuItem(value: 'Wakil Ketua', child: Text('Wakil Ketua')),
                          DropdownMenuItem(value: 'Bendahara', child: Text('Bendahara')),
                          DropdownMenuItem(value: 'Sekretaris', child: Text('Sekretaris')),
                          DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => s.jabatan = val);
                            SupabaseRepository.updateStudentJabatan(s.nim, val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Jabatan ${s.nama} diubah menjadi $val')),
                            );
                          }
                        },
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
        _buildAppBar('Laporan & Rekapitulasi', showSearch: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              _buildReportCard(
                title: 'Rekap Presensi Seluruh Kelas',
                subtitle: 'Tingkat kehadiran rata-rata: 92%',
                icon: Icons.checklist_rounded,
                color: const Color(0xFF10B981),
              ),
              _buildReportCard(
                title: 'Laporan Keuangan Kas Kelas',
                subtitle: 'Total saldo: Rp 3.250.000',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF5B3DE8),
              ),
              _buildReportCard(
                title: 'Distribusi Tugas Mahasiswa',
                subtitle: '6 tugas aktif terdistribusi',
                icon: Icons.assignment_outlined,
                color: const Color(0xFFF59E0B),
              ),
              _buildReportCard(
                title: 'Inventaris & Perlengkapan Kelas',
                subtitle: 'Proyektor, kabel HDMI, spidol siap',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF0284C7),
              ),
            ],
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF111827))),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const Icon(Icons.file_download_outlined, color: Color(0xFF9CA3AF), size: 22),
        ],
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
            onPressed: onBack ?? () => _navigateTo('dashboard'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          if (showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF111827)),
              onPressed: onSearch ?? () {},
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBox({required String hintText, ValueChanged<String>? onChanged}) {
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
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
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
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w600),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text('$item'))).toList(),
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
  final String nama;
  final int semester;
  final int jumlahMahasiswa;

  ClassItem({
    required this.nama,
    required this.semester,
    required this.jumlahMahasiswa,
  });
}

class AcademicYearItem {
  final String tahun;
  bool isAktif;

  AcademicYearItem({
    required this.tahun,
    required this.isAktif,
  });
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
}
