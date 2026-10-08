import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 2),
              Text(
                student.nama.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                'NIM ${student.nim}  ·  Semester ${student.semester}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSub),
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
        ? 'Siap memimpin kegiatan kelas?'
        : student.isBendahara
        ? 'Kelola kas kelas dengan tertib.'
        : student.isSekretaris
        ? 'Agenda dan informasi kelas ada di sini.'
        : 'Semua kebutuhan kuliah dalam satu tempat.';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8068F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -22,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 116,
              color: Colors.white.withValues(alpha: .09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  student.jabatan.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .45,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${student.prodi}  ·  UNAZLAM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .84),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: () => widget.onNavigateTab(4),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: const Text(
                  'Lihat profil',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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

  Widget _buildAttendanceCard(int? percentage, int hadir) {
    final value = percentage == null ? 0.0 : percentage / 100;
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
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
                Icon(
                  percentage == null
                      ? Icons.event_busy_rounded
                      : Icons.done_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  percentage == null
                      ? 'Belum ada catatan presensi'
                      : '$percentage% kehadiran',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  percentage == null
                      ? 'Riwayatmu akan muncul setelah presensi pertama.'
                      : '$hadir hadir dari ${_attendance.length} sesi tercatat.',
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
        title: 'Kamu sudah menyusul semua tugas',
        subtitle: 'Tugas baru dari dosen akan muncul di sini.',
        onTap: () => widget.onNavigateTab(2),
      );
    }
    final due = assignment.deadline;
    final days = due.difference(DateTime.now()).inDays;
    return _FeatureCard(
      icon: Icons.assignment_rounded,
      color: AppColors.secondaryDark,
      surface: AppColors.secondarySoft,
      eyebrow: days < 0
          ? 'SUDAH LEWAT TENGGAT'
          : days == 0
          ? 'TENGGAT HARI INI'
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
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
