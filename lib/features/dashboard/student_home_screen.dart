import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/student_dashboard_service.dart';
import '../../core/widgets/universal_search_modal.dart';
import '../../models/models.dart';
import '../attendance/attendance_screen.dart';
import '../announcements/announcements_screen.dart';

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

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Map<String, dynamic>> _attendance = [];
  Assignment? _nextAssignment;
  Announcement? _announcement;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final snapshot = await StudentDashboardService.load(widget.student.nim);
      if (!mounted) return;
      setState(() {
        _attendance = snapshot.attendance;
        _nextAssignment = snapshot.nextAssignment;
        _announcement = snapshot.latestAnnouncement;
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
    final student = widget.student;
    final hadir = _attendance.where((row) => '${row['status']}'.toLowerCase() == 'hadir').length;
    final attendancePercent = _attendance.isEmpty ? null : (hadir * 100 / _attendance.length).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5B3DE8),
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Gojek-style Top Bar (Search + Notif + Avatar)
              _buildTopBar(context, student),
              const SizedBox(height: 14),

              // 2. Gojek-style "Academic Wallet" Card (Info Mahasiswa & Aksi Instan Cepat)
              _buildAcademicWalletCard(context, student, attendancePercent, hadir),
              const SizedBox(height: 18),

              // 3. Error Alert jika gagal fetch
              if (_loadError != null) ...[
                _buildLoadError(),
                const SizedBox(height: 14),
              ],

              // 4. Presensi Aktif Banner (Jika ada sesi yang sedang berlangsung)
              if (AttendanceScreen.currentSession != null && !AttendanceScreen.currentSession!.isExpired) ...[
                _buildLiveAttendanceBanner(context, student),
                const SizedBox(height: 16),
              ],

              // 5. Gojek-style 8 App Services Grid (2 Baris x 4 Kolom)
              _buildServicesGrid(context, student),
              const SizedBox(height: 22),

              // 6. Carousel "Aktivitas Hari Ini" (Jadwal Kuliah & Tugas Mendesak)
              _buildTodayActivitiesSection(context),
              const SizedBox(height: 22),

              // 7. Banner Pengumuman Terkini (Gojek Promo / News Card Style)
              _buildAnnouncementBanner(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP BAR: SEARCH BAR + NOTIF + AVATAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, StudentProfile student) {
    final initials = student.nama.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Row(
      children: [
        // Search Bar (Gojek Style rounded pill)
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            elevation: 0,
            child: InkWell(
              onTap: () => UniversalSearchModal.show(context, onNavigateTab: widget.onNavigateTab),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 21),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari matkul, tugas, dosen...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tombol Notifikasi
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          child: InkWell(
            onTap: () => widget.onNavigateTab(11), // Notifikasi
            borderRadius: BorderRadius.circular(23),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 22),
                  Positioned(
                    right: 10,
                    top: 10,
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
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Avatar Profil Mahasiswa
        InkWell(
          onTap: () => widget.onNavigateTab(4), // Profil
          borderRadius: BorderRadius.circular(23),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3DE8), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. ACADEMIC WALLET CARD (ALA GOPAY CARD)
  // ==========================================
  Widget _buildAcademicWalletCard(
    BuildContext context,
    StudentProfile student,
    int? attendancePercent,
    int hadirCount,
  ) {
    final isEligible = attendancePercent != null && attendancePercent >= 75;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3DE8).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sisi Kiri: Status Kehadiran / Akademik
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () => widget.onNavigateTab(5), // Presensi
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SMT ${student.semester}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B3DE8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEligible ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEligible ? 'UAS Aman' : 'Pantau',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isEligible ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      attendancePercent == null ? '100% Kehadiran' : '$attendancePercent% Kehadiran',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hadirCount hadir • Klik detail',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider Tipis
          Container(
            height: 44,
            width: 1,
            color: const Color(0xFFF1F5F9),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // Sisi Kanan: 4 Aksi Cepat Ikonis (Gojek Style: Bayar, Top Up, Eksplor)
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGojekActionItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Absen',
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                  onTap: () => widget.onNavigateTab(5), // Presensi
                ),
                _buildGojekActionItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Kas',
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFCCFBF1),
                  onTap: () => widget.onNavigateTab(8), // Kas Kelas
                ),
                _buildGojekActionItem(
                  icon: Icons.school_rounded,
                  label: 'KHS',
                  color: const Color(0xFF5B3DE8),
                  bgColor: const Color(0xFFEDE9FE),
                  onTap: () => widget.onNavigateTab(10), // KHS Nilai
                ),
                _buildGojekActionItem(
                  icon: Icons.checklist_rounded,
                  label: 'Tugas',
                  color: const Color(0xFFE11D48),
                  bgColor: const Color(0xFFFFE4E6),
                  onTap: () => widget.onNavigateTab(2), // Tugas
                ),
              ],
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
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. 8 SERVICES GRID (ALA MENU GOJEK)
  // ==========================================
  Widget _buildServicesGrid(BuildContext context, StudentProfile student) {
    final services = [
      _ServiceItem(
        title: 'Jadwal',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        tabIndex: 1,
      ),
      _ServiceItem(
        title: 'Tugas',
        icon: Icons.assignment_rounded,
        color: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
        tabIndex: 2,
      ),
      _ServiceItem(
        title: 'Presensi',
        icon: Icons.co_present_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        tabIndex: 5,
      ),
      _ServiceItem(
        title: 'Kas Kelas',
        icon: Icons.payments_rounded,
        color: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDFA),
        tabIndex: 8,
      ),
      _ServiceItem(
        title: 'Nilai KHS',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        tabIndex: 10,
      ),
      _ServiceItem(
        title: 'Pengumuman',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        tabIndex: 7,
      ),
      _ServiceItem(
        title: 'Teman Kelas',
        icon: Icons.groups_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        tabIndex: 3,
      ),
      _ServiceItem(
        title: 'Lainnya',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF475569),
        bgColor: const Color(0xFFF1F5F9),
        isMore: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.take(4).map((item) => _buildServiceIcon(context, item)).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: services.skip(4).take(4).map((item) => _buildServiceIcon(context, item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, _ServiceItem item) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: () {
          if (item.isMore) {
            _showMoreServicesModal(context);
          } else {
            widget.onNavigateTab(item.tabIndex);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. AKTIVITAS HARI INI (HORIZONTAL CAROUSEL)
  // ==========================================
  Widget _buildTodayActivitiesSection(BuildContext context) {
    final now = DateTime.now();
    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';
    final todayCourses = DummyData.courses.where((c) => c.hari.toLowerCase() == todayName.toLowerCase()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Aktivitas Kuliah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    todayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => widget.onNavigateTab(1), // Jadwal
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B3DE8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Carousel (Hemat Tempat & Elegan)
        SizedBox(
          height: 122,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              // Kartu Tugas Mendesak (Jika ada)
              if (_nextAssignment != null) ...[
                _buildUrgentAssignmentHorizontalCard(context, _nextAssignment!),
                const SizedBox(width: 12),
              ],

              // Kartu Jadwal Kuliah Hari Ini
              if (todayCourses.isEmpty)
                _buildFreeDayHorizontalCard()
              else
                ...todayCourses.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCourseHorizontalCard(c),
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHorizontalCard(Course course) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${course.jamMulai} - ${course.jamSelesai}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B3DE8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  course.ruangan.isNotEmpty ? course.ruangan : 'Lab A',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${course.dosen} • ${course.sks} SKS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAssignmentHorizontalCard(BuildContext context, Assignment assignment) {
    final due = assignment.deadline;
    final days = due.difference(DateTime.now()).inDays;
    final isUrgent = days <= 1;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  days < 0
                      ? 'LEWAT TENGGAT'
                      : days == 0
                      ? 'TENGGAT HARI INI'
                      : days == 1
                      ? 'TENGGAT BESOK'
                      : '$days HARI LAGI',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () => widget.onNavigateTab(2),
                child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.judul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                assignment.courseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeDayHorizontalCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFEDE9FE),
            child: Icon(Icons.beach_access_rounded, color: Color(0xFF5B3DE8), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tidak Ada Kuliah 🎉',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Istirahat atau kerjakan tugas.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. BANNER PENGUMUMAN (ALA BANNER GOJEK)
  // ==========================================
  Widget _buildAnnouncementBanner(BuildContext context) {
    final item = _announcement;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item?.kategori.toUpperCase() ?? 'INFO KELAS',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => widget.onNavigateTab(7),
                      child: const Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B3DE8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item?.judul ?? 'Belum ada pengumuman terbaru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item?.isi ?? 'Informasi penting dari koordinator kelas akan muncul di sini.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.3,
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
  // 6. LIVE ATTENDANCE BANNER
  // ==========================================
  Widget _buildLiveAttendanceBanner(BuildContext context, StudentProfile student) {
    final session = AttendanceScreen.currentSession!;
    final attended = session.attendedNims.contains(student.nim);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Aktif • ${session.courseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                Text(
                  attended ? 'Kamu sudah presensi' : 'Sisa waktu ${session.remainingSeconds ~/ 60} menit',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
          if (!attended)
            FilledButton(
              onPressed: () => widget.onNavigateTab(5),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Scan QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadError() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFD59E)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB45309), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_loadError!, style: const TextStyle(fontSize: 11.5)),
        ),
        TextButton(onPressed: _loadDashboard, child: const Text('Coba lagi', style: TextStyle(fontSize: 11.5))),
      ],
    ),
  );

  // ==========================================
  // MODAL MENU LENGKAP ("LAINNYA")
  // ==========================================
  void _showMoreServicesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Semua Menu Portal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                _buildModalMenuItem(
                  icon: Icons.event_note_rounded,
                  label: 'Agenda',
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigateTab(6);
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.how_to_vote_rounded,
                  label: 'Voting',
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigateTab(12);
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.folder_shared_rounded,
                  label: 'Arsip Dokumen',
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFCCFBF1),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigateTab(9);
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil Saya',
                  color: const Color(0xFF5B3DE8),
                  bgColor: const Color(0xFFEDE9FE),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavigateTab(4);
                  },
                ),
                if (widget.student.isKetuaKelas)
                  _buildModalMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Panel Komti',
                    color: const Color(0xFFEA580C),
                    bgColor: const Color(0xFFFFF7ED),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(7);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int tabIndex;
  final bool isMore;

  _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.tabIndex = 0,
    this.isMore = false,
  });
}
