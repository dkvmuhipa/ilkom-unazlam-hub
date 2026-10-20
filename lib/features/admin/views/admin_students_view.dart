import '../widgets/admin_detail_page.dart';
import 'package:flutter/material.dart';


import '../../../core/constants/app_colors.dart';
import '../widgets/admin_student_summary.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../widgets/admin_bulk_csv_modal.dart';
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
  final Future<void> Function(StudentProfile account, bool isActive)
  onSetActive;
  final Future<void> Function(StudentProfile account) onDeleteAccount;
  final VoidCallback onCreateAccount;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  })?
  onRecordAudit;

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
    this.onRecordAudit,
  });

  @override
  State<AdminStudentsView> createState() => _AdminStudentsViewState();
}

class _AdminStudentsViewState extends State<AdminStudentsView> {
  String _studentFilter = 'Aktif';
  String _studentSearchQuery = '';


  void _openBulkImport() {
    AdminBulkCsvModal.show(
      context,
      initialType: BulkImportType.students,
      onReload: widget.onReload,
      onShowMessage: widget.onShowMessage,
      onRecordAudit:
          widget.onRecordAudit ??
          ({
            required action,
            required module,
            required description,
            metadata,
          }) {},
    );
  }

  Widget _accountStatusBadge(bool isActive) => isActive
      ? SoftPillBadge.success(label: 'Aktif', showDot: true)
      : SoftPillBadge.danger(label: 'Nonaktif', showDot: true);

  Widget _buildDetailView() {
    final student = widget.selectedStudent ?? widget.managedAccounts.firstOrNull;
    if (student == null) return const Center(child: Text('Pilih mahasiswa untuk melihat detail.'));
    return AdminDetailPage(
      pageLabel: 'Detail Mahasiswa', title: student.nama,
      subtitle: 'NIM ${student.nim} • ${student.isAktif ? 'Aktif' : 'Nonaktif'}',
      icon: Icons.school_outlined, onBack: widget.onBack,
      onEdit: () async { await widget.onEditAccount(student); if (mounted) setState(() {}); },
      actions: [
        AdminDetailAction(student.isAktif ? 'Nonaktifkan akun' : 'Aktifkan akun', Icons.manage_accounts_outlined,
          () async { await widget.onSetActive(student, !student.isAktif); if (mounted) setState(() {}); }),
        AdminDetailAction('Hapus akun', Icons.delete_outline, () => widget.onDeleteAccount(student)),
      ],
      tabs: [
        AdminDetailTab('Profil', AdminDetailSection(title: 'Identitas dan kontak', children: [
          AdminDetailFields({'Nama lengkap': student.nama, 'NIM': student.nim, 'Email': student.email,
            'WhatsApp': student.noWa, 'Jabatan': student.jabatan, 'Peminatan': student.peminatan}),
        ])),
        AdminDetailTab('Akademik', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AdminDetailSection(title: 'Informasi akademik', children: [
            AdminDetailFields({'Program studi': student.prodi, 'Semester': '${student.semester}', 'Kelas': student.kelas}),
          ]),
          const SizedBox(height: 28),
          AdminDetailSection(title: 'Mata kuliah semester ${student.semester}', children: [
            for (final course in widget.courses.where((course) => course.semester == student.semester))
              ListTile(contentPadding: EdgeInsets.zero, title: Text(course.nama),
                subtitle: Text('${course.kode} • ${course.sks} SKS\n${course.dosen}')),
            if (!widget.courses.any((course) => course.semester == student.semester)) const Text('Belum ada mata kuliah untuk semester ini.'),
          ]),
        ])),
        AdminDetailTab('Presensi & KHS', AdminStudentSummary(key: ValueKey(student.nim), student: student, onShowMessage: widget.onShowMessage)),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isDetailMode) {
      return _buildDetailView();
    }

    final sourceStudents = widget.managedAccounts
        .where((s) => !s.isAdmin)
        .toList();

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
          showSearch: false,
        ),
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
                    AdminSearchBox(
                      hintText: 'Cari nama atau NIM...',
                      onChanged: (val) =>
                          setState(() => _studentSearchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    AdminAdaptiveRow(
                      children: [
                        ...['Semua', 'Aktif', 'Nonaktif'].map((f) {
                          final isSel = _studentFilter == f;
                          final count = switch (f) {
                            'Aktif' => sourceStudents.where((s) => s.isAktif).length,
                            'Nonaktif' => sourceStudents.where((s) => !s.isAktif).length,
                            _ => sourceStudents.length,
                          };
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AdminFilterChip(
                              label: f,
                              isSelected: isSel,
                              count: count,
                              onTap: () => setState(() => _studentFilter = f),
                            ),
                          );
                        }),
                        const Spacer(),
                        ScaleButton(
                          onTap: _openBulkImport,
                          scaleDown: 0.95,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Import CSV',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
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
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: EmptyStateWidget(
                            icon: Icons.school_outlined,
                            title: _studentSearchQuery.isEmpty
                                ? 'Belum Ada Mahasiswa'
                                : 'Mahasiswa Tidak Ditemukan',
                            subtitle: _studentSearchQuery.isEmpty
                                ? 'Belum ada data mahasiswa terdaftar di Supabase.'
                                : 'Tidak ada mahasiswa yang cocok dengan filter atau kata kunci pencarian.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        itemCount: students.length,
                        itemBuilder: (ctx, i) {
                          final s = students[i];
                          final rowBg = i.isEven
                              ? Colors.white
                              : const Color(0xFFF8FAFC);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: rowBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => widget.onNavigate(
                                'detail_mahasiswa',
                                student: s,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: AdminAdaptiveRow(
                                  children: [
                                    SaaSAvatar(
                                      name: s.nama,
                                      size: 42,
                                      radius: 12,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AdminAdaptiveRow(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  s.nama,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (s.jabatan != 'Mahasiswa') ...[
                                                const SizedBox(width: 6),
                                                SoftPillBadge.warning(
                                                  label: s.jabatan,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'NIM ${s.nim} • Sem ${s.semester} • ${s.peminatan.isNotEmpty ? s.peminatan : (s.kelas.isNotEmpty ? s.kelas : "Ilmu Komunikasi")}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
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
                                        color: Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onSelected: (val) async {
                                        if (val == 'detail') {
                                          widget.onNavigate(
                                            'detail_mahasiswa',
                                            student: s,
                                          );
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
                                            s.isAktif
                                                ? 'Nonaktifkan'
                                                : 'Aktifkan Akun',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Hapus Mahasiswa',
                                            style: TextStyle(
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
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
                      '+ Tambah Akun',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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
}
