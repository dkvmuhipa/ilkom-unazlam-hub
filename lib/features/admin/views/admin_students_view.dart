import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminStudentsView extends StatefulWidget {
  final bool isDetailMode;
  final StudentProfile? selectedStudent;
  final List<StudentProfile> managedAccounts;
  final List<Course> courses;
  final VoidCallback onBack;
  final void Function(String view, {StudentProfile? student}) onNavigate;
  final Future<void> Function() onReload;
  final void Function(String message, {bool isError}) onShowMessage;
  final Future<void> Function(StudentProfile account) onEditAccount;
  final Future<void> Function(StudentProfile account, bool isActive) onSetActive;
  final Future<void> Function(StudentProfile account) onDeleteAccount;
  final VoidCallback onCreateAccount;

  const AdminStudentsView({
    super.key,
    this.isDetailMode = false,
    this.selectedStudent,
    required this.managedAccounts,
    required this.courses,
    required this.onBack,
    required this.onNavigate,
    required this.onReload,
    required this.onShowMessage,
    required this.onEditAccount,
    required this.onSetActive,
    required this.onDeleteAccount,
    required this.onCreateAccount,
  });

  @override
  State<AdminStudentsView> createState() => _AdminStudentsViewState();
}

class _AdminStudentsViewState extends State<AdminStudentsView> {
  String _studentFilter = 'Aktif';
  String _studentSearchQuery = '';
  int _detailTab = 0;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  Widget _accountStatusBadge(bool isActive) => isActive
      ? SoftPillBadge.success(label: 'Aktif', showDot: true)
      : SoftPillBadge.danger(label: 'Nonaktif', showDot: true);

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

  Widget _buildDetailView() {
    final s = widget.selectedStudent ?? (widget.managedAccounts.isNotEmpty ? widget.managedAccounts.first : null);
    if (s == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tidak ada data mahasiswa.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: widget.onBack, child: const Text('Kembali')),
          ],
        ),
      );
    }
    final initials = _getInitials(s.nama);

    return Column(
      children: [
        AdminAppBar(
          title: 'Detail Mahasiswa',
          onBack: widget.onBack,
          onSearch: () {},
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.isAktif ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: s.isAktif ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                        ),
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
                                    color: isSel ? AppColors.primary : Colors.transparent,
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
                                  color: isSel ? AppColors.primary : const Color(0xFF6B7280),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.class_outlined, color: AppColors.primary, size: 20),
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
                              '${widget.courses.length} MK Terdaftar',
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
                      ...widget.courses.map((course) {
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
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary),
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
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }),
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
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.onEditAccount(s);
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
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
                        await widget.onSetActive(s, !s.isAktif);
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

  @override
  Widget build(BuildContext context) {
    if (widget.isDetailMode) {
      return _buildDetailView();
    }

    final sourceStudents = widget.managedAccounts.where((s) => !s.isAdmin).toList();

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
        AdminAppBar(
          title: 'Data Mahasiswa',
          onBack: widget.onBack,
          onSearch: () {},
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    AdminSearchBox(
                      hintText: 'Cari nama atau NIM...',
                      onChanged: (val) => setState(() => _studentSearchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Semua', 'Aktif', 'Nonaktif'].map((f) {
                        final isSel = _studentFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _studentFilter = f),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? AppColors.primary : AppColors.borderMedium,
                                ),
                              ),
                              child: Text(
                                f,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
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
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: EmptyStateWidget(
                            icon: Icons.school_outlined,
                            title: _studentSearchQuery.isEmpty ? 'Belum Ada Mahasiswa' : 'Mahasiswa Tidak Ditemukan',
                            subtitle: _studentSearchQuery.isEmpty
                                ? 'Belum ada data mahasiswa terdaftar di Supabase.'
                                : 'Tidak ada mahasiswa yang cocok dengan filter atau kata kunci pencarian.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        itemCount: students.length,
                        itemBuilder: (ctx, i) {
                    final s = students[i];
                    final rowBg = i.isEven ? Colors.white : const Color(0xFFF8FAFC);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: rowBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: InkWell(
                        onTap: () => widget.onNavigate('detail_mahasiswa', student: s),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            SaaSAvatar(name: s.nama, size: 42, radius: 12),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          s.nama,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textMain,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.jabatan != 'Mahasiswa') ...[
                                        const SizedBox(width: 8),
                                        SoftPillBadge.warning(label: s.jabatan),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'NIM ${s.nim} • Semester ${s.semester} • ${s.peminatan.isNotEmpty ? s.peminatan : "Ilmu Komunikasi"}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _accountStatusBadge(s.isAktif),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  widget.onNavigate('detail_mahasiswa', student: s);
                                } else if (val == 'edit') {
                                  await widget.onEditAccount(s);
                                  if (mounted) setState(() {});
                                } else if (val == 'toggle') {
                                  await widget.onSetActive(s, !s.isAktif);
                                  if (mounted) setState(() {});
                                } else if (val == 'delete') {
                                  await widget.onDeleteAccount(s);
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
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Hapus Mahasiswa',
                                    style: TextStyle(color: Color(0xFFDC2626)),
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  onPressed: widget.onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  label: const Text(
                    '+ Tambah & Undang Mahasiswa',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
