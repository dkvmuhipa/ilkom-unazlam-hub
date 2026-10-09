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
    if (mounted)
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
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
        _loadError =
            'Data beranda gagal dimuat. Periksa koneksi lalu coba lagi.';
      });
      debugPrint('Gagal memuat data beranda mahasiswa: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final hadir = _attendance
        .where((row) => '${row['status']}'.toLowerCase() == 'hadir')
        .length;
    final attendancePercent = _attendance.isEmpty
        ? null
        : (hadir * 100 / _attendance.length).round();
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 11 => 'Selamat pagi',
      < 15 => 'Selamat siang',
      < 19 => 'Selamat sore',
      _ => 'Selamat malam',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _buildHeader(context, student, greeting),
              const SizedBox(height: 22),
              _buildWelcomeCard(student),
              if (_loadError != null) ...[
                const SizedBox(height: 14),
                _buildLoadError(),
              ],
              if (AttendanceScreen.currentSession != null &&
                  !AttendanceScreen.currentSession!.isExpired) ...[
                const SizedBox(height: 16),
                _buildAttendanceAlert(context, student),
              ],
              const SizedBox(height: 26),
              _sectionHeading(
                'Akses cepat',
                'Fitur yang paling sering dipakai',
              ),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 26),
              _buildTodayScheduleSection(),
              if (student.isKetuaKelas ||
                  student.isBendahara ||
                  student.isSekretaris) ...[
                const SizedBox(height: 26),
                _sectionHeading(
                  'Peran kelas',
                  'Akses untuk membantu kegiatan kelas',
                ),
                const SizedBox(height: 14),
                _buildOfficerCard(student),
              ],
              const SizedBox(height: 28),
              _sectionHeading(
                'Ringkasan presensi',
                'Pantau catatan kehadiranmu',
              ),
              const SizedBox(height: 14),
              _isLoading
                  ? const _DashboardLoadingCard(label: 'Memuat presensi...')
                  : _loadError != null
                  ? const _DashboardUnavailableCard()
                  : _buildAttendanceCard(attendancePercent, hadir),
              const SizedBox(height: 28),
              _sectionHeading(
                'Tugas berikutnya',
                'Jangan lewatkan tenggat pengumpulan',
              ),
              const SizedBox(height: 14),
              _isLoading
                  ? const _DashboardLoadingCard(label: 'Memuat tugas...')
                  : _loadError != null
                  ? const _DashboardUnavailableCard()
                  : _buildAssignmentCard(_nextAssignment),
              const SizedBox(height: 28),
              _sectionHeading(
                'Pengumuman terbaru',
                'Informasi terkini dari kelas',
              ),
              const SizedBox(height: 14),
              _isLoading
                  ? const _DashboardLoadingCard(label: 'Memuat pengumuman...')
                  : _loadError != null
                  ? const _DashboardUnavailableCard()
                  : _buildAnnouncementCard(context, _announcement),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFD59E)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_loadError!, style: const TextStyle(fontSize: 12.5)),
        ),
        TextButton(onPressed: _loadDashboard, child: const Text('Coba lagi')),
      ],
    ),
  );

  Widget _buildHeader(
    BuildContext context,
    StudentProfile student,
    String greeting,
  ) {
    final now = DateTime.now();
    const daysIndo = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const monthsIndo = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final todayStr = '${daysIndo[now.weekday]}, ${now.day} ${monthsIndo[now.month]} ${now.year}';

    final initials = student.nama.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Row(
      children: [
        // Avatar Inisial Mahasiswa
        InkWell(
          onTap: () => widget.onNavigateTab(4), // Profil
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3DE8), Color(0xFF8667FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                student.nama.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B3DE8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          icon: Icons.search_rounded,
          tooltip: 'Cari',
          onTap: () => UniversalSearchModal.show(
            context,
            onNavigateTab: widget.onNavigateTab,
          ),
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifikasi',
          onTap: () => widget.onNavigateTab(11),
          badge: true,
        ),
        if (widget.onOpenDrawer != null &&
            MediaQuery.sizeOf(context).width < 900) ...[
          const SizedBox(width: 8),
          _HeaderAction(
            icon: Icons.grid_view_rounded,
            tooltip: 'Semua menu',
            onTap: widget.onOpenDrawer!,
          ),
        ],
      ],
    );
  }

  Widget _buildWelcomeCard(StudentProfile student) {
    final title = student.isKetuaKelas
        ? 'Koordinator Kelas Aktif'
        : student.isBendahara
        ? 'Pengelola Keuangan Kelas'
        : student.isSekretaris
        ? 'Pencatat & Pengelola Agenda'
        : 'Portal Terpadu Mahasiswa';

    final subtitle = student.isKetuaKelas
        ? 'Siap memimpin koordinasi perkuliahan hari ini?'
        : student.isBendahara
        ? 'Transparansi kas dan iuran kelas terkontrol rapi.'
        : student.isSekretaris
        ? 'Informasi dan agenda kelas terpusat di satu portal.'
        : 'Pantau jadwal, presensi, tugas, dan nilai akademikmu.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4C2CE2),
            Color(0xFF6B4CF6),
            Color(0xFF8667FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3DE8).withValues(alpha: .28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: -20,
            child: Icon(
              Icons.school_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: .09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: .25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          student.jabatan.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SMT ${student.semester}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .88),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigateTab(10), // KHS & IPK
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5B3DE8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.school_outlined, size: 16),
                    label: const Text(
                      'KHS & Nilai',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(4), // Profil
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: .5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text(
                      'Profil Saya',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAlert(BuildContext context, StudentProfile student) {
    final session = AttendanceScreen.currentSession!;
    final attended = session.attendedNims.contains(student.nim);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5ECDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Presensi sedang dibuka',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${session.remainingSeconds ~/ 60}:${(session.remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.courseName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            'Pertemuan ${session.pertemuanKe}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  attended
                      ? 'Kehadiranmu sudah tercatat.'
                      : 'Silakan isi presensi sebelum sesi berakhir.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              if (!attended)
                FilledButton.tonalIcon(
                  onPressed: () => widget.onNavigateTab(5),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Absen'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.textSub),
      ),
    ],
  );

  Widget _buildQuickActions() => Row(
    children: [
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Presensi',
        subtitle: 'Scan QR',
        color: AppColors.primary,
        surface: AppColors.primarySoft,
        onTap: () => widget.onNavigateTab(5),
      ),
      const SizedBox(width: 10),
      _QuickAction(
        icon: Icons.assignment_rounded,
        title: 'Tugas',
        subtitle: 'Cek deadline',
        color: AppColors.secondaryDark,
        surface: AppColors.secondarySoft,
        onTap: () => widget.onNavigateTab(2),
      ),
      const SizedBox(width: 10),
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        title: 'Jadwal',
        subtitle: 'Kuliahmu',
        color: AppColors.info,
        surface: AppColors.infoSoft,
        onTap: () => widget.onNavigateTab(1),
      ),
      const SizedBox(width: 10),
      _QuickAction(
        icon: Icons.people_alt_rounded,
        title: 'Kelas',
        subtitle: 'Temanmu',
        color: AppColors.tertiaryDark,
        surface: AppColors.tertiarySoft,
        onTap: () => widget.onNavigateTab(3),
      ),
    ],
  );

  Widget _buildOfficerCard(StudentProfile student) {
    final items = <(String, IconData, int, Color, Color)>[];
    if (student.isKetuaKelas) {
      items.addAll([
        (
          'Pengumuman',
          Icons.campaign_rounded,
          7,
          AppColors.primary,
          AppColors.primarySoft,
        ),
        (
          'Agenda',
          Icons.event_note_rounded,
          6,
          AppColors.info,
          AppColors.infoSoft,
        ),
        (
          'Voting',
          Icons.how_to_vote_rounded,
          12,
          AppColors.secondaryDark,
          AppColors.secondarySoft,
        ),
        (
          'Anggota',
          Icons.groups_rounded,
          3,
          AppColors.tertiaryDark,
          AppColors.tertiarySoft,
        ),
      ]);
    } else if (student.isBendahara) {
      items.add((
        'Kas kelas',
        Icons.account_balance_wallet_rounded,
        8,
        AppColors.tertiaryDark,
        AppColors.tertiarySoft,
      ));
    } else {
      items.addAll([
        (
          'Agenda',
          Icons.event_note_rounded,
          6,
          AppColors.info,
          AppColors.infoSoft,
        ),
        (
          'Pengumuman',
          Icons.campaign_rounded,
          7,
          AppColors.primary,
          AppColors.primarySoft,
        ),
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => _OfficerAction(
                item.$1,
                item.$2,
                item.$3,
                item.$4,
                item.$5,
                widget.onNavigateTab,
                width: (constraints.maxWidth - 10) / 2,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTodayScheduleSection() {
    final now = DateTime.now();
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';
    final todayCourses = DummyData.courses.where((c) => c.hari.toLowerCase() == todayName.toLowerCase()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Kuliah Hari Ini',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  todayCourses.isEmpty
                      ? '$todayName • Tidak ada perkuliahan'
                      : '$todayName • ${todayCourses.length} mata kuliah (${todayCourses.fold<int>(0, (s, c) => s + c.sks)} SKS)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
            InkWell(
              onTap: () => widget.onNavigateTab(1), // Jadwal Kuliah
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Semua',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B3DE8),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF5B3DE8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Color(0xFF5B3DE8), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak Ada Perkuliahan Hari Ini 🎉',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Waktunya mengerjakan tugas, belajar mandiri, atau istirahat.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...todayCourses.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        c.jamMulai,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF5B3DE8)),
                      ),
                      Text(
                        c.jamSelesai,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${c.sks} SKS',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.ruangan.isNotEmpty ? c.ruangan : 'Ruang A2',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.dosen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onNavigateTab(1),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildAttendanceCard(int? percentage, int hadir) {
    final value = percentage == null ? 0.0 : percentage / 100;
    final isEligible = percentage != null && percentage >= 75;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage == null ? 0 : value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: isEligible ? const Color(0xFF10B981) : const Color(0xFF5B3DE8),
                ),
                Icon(
                  percentage == null
                      ? Icons.event_busy_rounded
                      : (isEligible ? Icons.verified_rounded : Icons.trending_up_rounded),
                  size: 20,
                  color: isEligible ? const Color(0xFF10B981) : const Color(0xFF5B3DE8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      percentage == null
                          ? 'Belum ada catatan presensi'
                          : '$percentage% Kehadiran',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (percentage != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEligible ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEligible ? 'UAS Aman' : 'Perlu Rajin',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  percentage == null
                      ? 'Riwayat kehadiranmu akan muncul setelah presensi pertama.'
                      : '$hadir hadir dari ${_attendance.length} sesi tercatat (Minimal 75% untuk UAS).',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onNavigateTab(5),
            tooltip: 'Buka presensi',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment? assignment) {
    if (assignment == null) {
      return _EmptyFeatureCard(
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
        surface: AppColors.successSoft,
        title: 'Semua Tugas Telah Tuntas! 🎉',
        subtitle: 'Tidak ada tenggat tugas yang menumpuk saat ini.',
        onTap: () => widget.onNavigateTab(2),
      );
    }
    final due = assignment.deadline;
    final days = due.difference(DateTime.now()).inDays;
    final isUrgent = days <= 1;

    return _FeatureCard(
      icon: Icons.assignment_rounded,
      color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF5B3DE8),
      surface: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFF5F3FF),
      eyebrow: days < 0
          ? 'SUDAH LEWAT TENGGAT'
          : days == 0
          ? 'TENGGAT HARI INI'
          : days == 1
          ? 'TENGGAT BESOK'
          : 'TENGGAT $days HARI LAGI',
      title: assignment.judul,
      subtitle: assignment.courseName,
      trailing:
          '${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')}',
      onTap: () => widget.onNavigateTab(2),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement? announcement,
  ) {
    return _FeatureCard(
      icon: Icons.campaign_rounded,
      color: AppColors.info,
      surface: AppColors.infoSoft,
      eyebrow: announcement?.kategori.toUpperCase() ?? 'INFO KELAS',
      title: announcement?.judul ?? 'Belum ada pengumuman baru',
      subtitle:
          announcement?.isi ??
          'Informasi penting dari kelas akan tampil di bagian ini.',
      maxLines: 2,
      trailing: null,
      onTap: () {
        if (announcement == null) {
          widget.onNavigateTab(7);
        } else {
          AnnouncementsScreen.showAnnouncementDetail(context, announcement);
        }
      },
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  final String label;
  const _DashboardLoadingCard({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _DashboardUnavailableCard extends StatelessWidget {
  const _DashboardUnavailableCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Data belum tersedia. Tekan “Coba lagi” di atas.',
            style: TextStyle(color: AppColors.textSub, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.textMain, size: 21),
              if (badge)
                Positioned(
                  right: 11,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OfficerAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final int index;
  final Color color;
  final Color surface;
  final ValueChanged<int> onNavigate;
  final double width;
  const _OfficerAction(
    this.title,
    this.icon,
    this.index,
    this.color,
    this.surface,
    this.onNavigate, {
    required this.width,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onNavigate(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color surface;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? trailing;
  final int maxLines;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.surface,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .35,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _EmptyFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color surface;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EmptyFeatureCard({
    required this.icon,
    required this.color,
    required this.surface,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
