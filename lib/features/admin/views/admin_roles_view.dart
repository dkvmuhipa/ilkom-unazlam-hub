import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminRolesView extends StatefulWidget {
  final List<StudentProfile> managedAccounts;
  final StudentProfile? selectedStudent;
  final VoidCallback onBack;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  }) onRecordAudit;

  const AdminRolesView({
    super.key,
    required this.managedAccounts,
    required this.selectedStudent,
    required this.onBack,
    required this.onRecordAudit,
  });

  @override
  State<AdminRolesView> createState() => _AdminRolesViewState();
}

class _AdminRolesViewState extends State<AdminRolesView> {
  String _roleFilter = 'Semua';
  String _roleSearchQuery = '';

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sourceStudents = widget.managedAccounts.where((s) => !s.isAdmin).toList();

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
        AdminAppBar(
          title: 'Role & Permission',
          showSearch: false,
          onBack: widget.onBack,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Role Sistem adalah MAHASISWA. Atur Jabatan Struktural untuk memberikan wewenang operasional kelas (Presensi, Pengumuman, Agenda, Kas).',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Box
              AdminSearchBox(
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
                    child: AdminAdaptiveRow(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            _getInitials(s.nama),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
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
                              color: AppColors.primary,
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
                                if (!context.mounted) return;
                                if (ok) {
                                  setState(() {
                                    s.jabatan = val;
                                    final idx = widget.managedAccounts.indexWhere((m) => m.nim == s.nim);
                                    if (idx >= 0) widget.managedAccounts[idx].jabatan = val;
                                    if (widget.selectedStudent?.nim == s.nim) widget.selectedStudent?.jabatan = val;
                                  });
                                  widget.onRecordAudit(
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
}
