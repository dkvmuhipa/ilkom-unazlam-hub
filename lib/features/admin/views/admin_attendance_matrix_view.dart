import '../widgets/admin_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';
import '../widgets/admin_common_widgets.dart';

/// Tampilan Matriks Presensi 16 Pertemuan & Kelayakan Ujian (BAP)
/// Menyediakan grid interaktif P1 - P16 per mata kuliah, kalkulasi ambang batas kehadiran 75%,
/// override status presensi manual oleh admin, serta ekspor dokumen Berita Acara Perkuliahan resmi.
class AdminAttendanceMatrixView extends StatefulWidget {
  final List<Course> courses;
  final List<ClassItem> classes;
  final String academicYear;
  final List<StudentProfile> managedAccounts;
  final VoidCallback onBack;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic> metadata,
  }) onRecordAudit;

  const AdminAttendanceMatrixView({
    super.key,
    required this.courses,
    required this.classes,
    this.academicYear = 'Belum ditetapkan',
    required this.managedAccounts,
    required this.onBack,
    required this.onShowMessage,
    required this.onRecordAudit,
  });

  @override
  State<AdminAttendanceMatrixView> createState() => _AdminAttendanceMatrixViewState();
}

class _AdminAttendanceMatrixViewState extends State<AdminAttendanceMatrixView> {
  Course? _selectedCourse;
  String _selectedKelas = 'Semua Kelas';
  double _thresholdPercent = 75.0;
  int _maxMeetingsHeld = 16;
  bool _isLoading = false;

  // matrixData: nim -> { pertemuanKe -> status }
  final Map<String, Map<int, String>> _matrixData = {};
  final Map<String, Map<int, String?>> _notesData = {};

  @override
  void initState() {
    super.initState();
    if (widget.courses.isNotEmpty) {
      _selectedCourse = widget.courses.first;
      _loadAttendanceMatrix();
    }
  }

  Future<void> _loadAttendanceMatrix() async {
    if (_selectedCourse == null) return;
    setState(() => _isLoading = true);

    try {
      final logs = await SupabaseRepository.getAttendanceLogsForCourse(
        courseId: _selectedCourse!.id,
      );

      _matrixData.clear();
      _notesData.clear();

      int highestMeeting = 0;

      for (final log in logs) {
        final nim = (log['student_nim'] ?? '').toString();
        final p = (log['pertemuan_ke'] as num?)?.toInt() ?? 1;
        final status = (log['status'] ?? '').toString().toLowerCase();
        final catatan = log['catatan']?.toString();

        if (p > highestMeeting) highestMeeting = p;

        _matrixData.putIfAbsent(nim, () => {})[p] = status;
        if (catatan != null && catatan.isNotEmpty) {
          _notesData.putIfAbsent(nim, () => {})[p] = catatan;
        }
      }

      if (mounted) {
        setState(() {
          _maxMeetingsHeld = highestMeeting > 0 ? highestMeeting : 16;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onShowMessage('Gagal memuat matriks kehadiran: $e', isError: true);
      }
    }
  }

  List<StudentProfile> get _filteredStudents {
    var list = widget.managedAccounts.where((s) => s.isAktif && s.role != 'ADMIN').toList();
    if (_selectedKelas != 'Semua Kelas') {
      list = list.where((s) => s.kelas.trim().toLowerCase() == _selectedKelas.trim().toLowerCase()).toList();
    }
    list.sort((a, b) => a.nim.compareTo(b.nim));
    return list;
  }

  void _showChangeStatusDialog({
    required StudentProfile student,
    required int pertemuanKe,
    required String currentStatus,
    String? currentNote,
  }) {
    String selectedStatus = currentStatus.isEmpty ? 'hadir' : currentStatus;
    final noteCtrl = TextEditingController(text: currentNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AdminSpaciousModal(
          title: 'Presensi Pertemuan Ke-$pertemuanKe',
          subtitle: '${student.nama} • NIM ${student.nim}',
          icon: Icons.edit_calendar_rounded,
          iconColor: AppColors.primary,
          maxWidth: 520,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS KEHADIRAN MAHASISWA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChoiceChip('hadir', 'Hadir', const Color(0xFF10B981), selectedStatus, (val) {
                    setDialogState(() => selectedStatus = val);
                  }),
                  _buildStatusChoiceChip('izin', 'Izin', const Color(0xFFF59E0B), selectedStatus, (val) {
                    setDialogState(() => selectedStatus = val);
                  }),
                  _buildStatusChoiceChip('sakit', 'Sakit', const Color(0xFF2563EB), selectedStatus, (val) {
                    setDialogState(() => selectedStatus = val);
                  }),
                  _buildStatusChoiceChip('alpa', 'Alfa', const Color(0xFFEF4444), selectedStatus, (val) {
                    setDialogState(() => selectedStatus = val);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'CATATAN / ALASAN / BUKTI SURAT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Izin kegiatan lomba fakultas / surat sakit terlampir',
                  hintStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pilihan Cepat Catatan:',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Hadir tepat waktu',
                  'Surat dokter diserahkan',
                  'Izin kegiatan kampus',
                  'Dispensasi akademik',
                  'Tanpa keterangan',
                ].map((preset) {
                  return ActionChip(
                    label: Text(preset, style: const TextStyle(fontSize: 10.5)),
                    onPressed: () {
                      noteCtrl.text = preset;
                      setDialogState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            if (currentStatus.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await SupabaseRepository.removeAttendanceLog(
                    courseId: _selectedCourse!.id,
                    studentNim: student.nim,
                    pertemuanKe: pertemuanKe,
                  );
                  if (ok) {
                    widget.onRecordAudit(
                      action: 'DELETE',
                      module: 'PRESENSI',
                      description: 'Menghapus presensi ${student.nama} pada P$pertemuanKe',
                    );
                    widget.onShowMessage('Catatan presensi P$pertemuanKe dihapus.');
                    await _loadAttendanceMatrix();
                  }
                },
                child: const Text('Hapus Catatan', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await SupabaseRepository.upsertAttendanceLog(
                  courseId: _selectedCourse!.id,
                  studentNim: student.nim,
                  pertemuanKe: pertemuanKe,
                  status: selectedStatus,
                  catatan: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
                if (ok) {
                  widget.onRecordAudit(
                    action: 'UPDATE',
                    module: 'PRESENSI',
                    description: 'Mengubah presensi ${student.nama} pada P$pertemuanKe menjadi $selectedStatus',
                  );
                  widget.onShowMessage('Status presensi P$pertemuanKe berhasil diperbarui.');
                  await _loadAttendanceMatrix();
                } else {
                  widget.onShowMessage('Gagal memperbarui status presensi.', isError: true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChoiceChip(
    String value,
    String label,
    Color color,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSel = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: isSel ? color : const Color(0xFF475569),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSel ? color : const Color(0xFFCBD5E1)),
      ),
      onSelected: (val) {
        if (val) onSelected(value);
      },
    );
  }

  void _exportMatrixCsv() {
    if (_selectedCourse == null) return;
    final csv = ExportService.exportAttendanceMatrixCsv(
      courseName: _selectedCourse!.nama,
      dosenName: _selectedCourse!.dosen,
      semester: '${_selectedCourse!.semester}',
      tahunAkademik: widget.academicYear,
      students: _filteredStudents,
      matrixData: _matrixData,
      totalMeetingsHeld: _maxMeetingsHeld,
      thresholdPercent: _thresholdPercent,
    );

    ExportService.showExportSheet(
      context,
      title: 'Matriks Presensi 16 Pertemuan (BAP)',
      fileName: 'bap_matriks_presensi_${_selectedCourse!.kode.toLowerCase()}.csv',
      content: csv,
      subtitle: '${_selectedCourse!.nama} • Syarat Kelayakan $_thresholdPercent%',
    );
  }

  void _showBapOfficialDocumentModal() {
    if (_selectedCourse == null) return;

    final students = _filteredStudents;
    int eligibleCount = 0;
    int blockedCount = 0;

    for (final s in students) {
      final row = _matrixData[s.nim] ?? {};
      int hadir = 0;
      for (int p = 1; p <= 16; p++) {
        if ((row[p] ?? '').toLowerCase() == 'hadir') hadir++;
      }
      final percent = ((hadir / _maxMeetingsHeld) * 100).round();
      if (percent >= _thresholdPercent) {
        eligibleCount++;
      } else {
        blockedCount++;
      }
    }

    final bapText = StringBuffer();
    bapText.writeln('BERITA ACARA PERKULIAHAN & REKAP KELAYAKAN UJIAN AKHIR SEMESTER');
    bapText.writeln('UNIVERSITAS ABDUL AZIS LAMADJIDO (UNAZLAM)');
    bapText.writeln('Fakultas Ilmu Sosial dan Ilmu Politik • Program Studi Ilmu Komunikasi');
    bapText.writeln('--------------------------------------------------------------------------------');
    bapText.writeln('Mata Kuliah     : ${_selectedCourse!.nama} (${_selectedCourse!.kode}) - ${_selectedCourse!.sks} SKS');
    bapText.writeln('Dosen Pengampu  : ${_selectedCourse!.dosen}');
    bapText.writeln('Hari / Waktu    : ${_selectedCourse!.hari}, ${_selectedCourse!.jamMulai} - ${_selectedCourse!.jamSelesai} WITA');
    bapText.writeln('Ruangan         : ${_selectedCourse!.ruangan}');
    bapText.writeln('Semester / T.A. : Semester ${_selectedCourse!.semester} / ${widget.academicYear}');
    bapText.writeln('Sesi Terlaksana : $_maxMeetingsHeld dari 16 Pertemuan');
    bapText.writeln('Ambang Batas    : Minimal $_thresholdPercent% Kehadiran');
    bapText.writeln('Rekapitulasi    : $eligibleCount Mahasiswa Layak UAS | $blockedCount Mahasiswa Dicekal UAS');
    bapText.writeln('--------------------------------------------------------------------------------\n');

    bapText.writeln('DAFTAR MAHASISWA & STATUS KELAYAKAN UAS:');
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final row = _matrixData[s.nim] ?? {};
      int hadir = 0;
      for (int p = 1; p <= 16; p++) {
        if ((row[p] ?? '').toLowerCase() == 'hadir') hadir++;
      }
      final pct = ((hadir / _maxMeetingsHeld) * 100).round();
      final status = pct >= _thresholdPercent ? '[MEMENUHI SYARAT]' : '[DICEKAL (<$_thresholdPercent%)]';
      bapText.writeln('${(i + 1).toString().padRight(3)} ${s.nim.padRight(12)} ${s.nama.padRight(28)} Hadir: $hadir/$_maxMeetingsHeld ($pct%) -> $status');
    }

    bapText.writeln('\n--------------------------------------------------------------------------------');
    bapText.writeln('Tanggal ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    bapText.writeln('Dosen Pengampu,                            Ketua Program Studi,\n\n\n');
    bapText.writeln('(${_selectedCourse!.dosen})             (Ketua Program Studi)');

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Berita Acara Perkuliahan', title: _selectedCourse!.nama,
      subtitle: '${_selectedCourse!.kode} • ${widget.academicYear}', icon: Icons.description_outlined,
      actions: [
        AdminDetailAction('Salin dokumen', Icons.copy_outlined, () async {
          await Clipboard.setData(ClipboardData(text: bapText.toString()));
          if (detailContext.mounted) ScaffoldMessenger.of(detailContext).showSnackBar(const SnackBar(content: Text('Dokumen disalin.')));
        }),
        AdminDetailAction('Ekspor matriks CSV', Icons.download_outlined, () { Navigator.pop(detailContext); _exportMatrixCsv(); }),
      ],
      tabs: [AdminDetailTab('Dokumen', AdminDetailSection(title: 'Berita acara', children: [
        SelectableText(bapText.toString(), style: const TextStyle(fontSize: 14, height: 1.8)),
      ]))],
    )));
  }
  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    // Hitung ringkasan statistik
    int totalHadirAll = 0;
    int eligibleStudentsCount = 0;
    int blockedStudentsCount = 0;

    for (final s in students) {
      final row = _matrixData[s.nim] ?? {};
      int sHadir = 0;
      for (int p = 1; p <= 16; p++) {
        if ((row[p] ?? '').toLowerCase() == 'hadir') sHadir++;
      }
      totalHadirAll += sHadir;
      final percent = ((sHadir / _maxMeetingsHeld) * 100).round();
      if (percent >= _thresholdPercent) {
        eligibleStudentsCount++;
      } else {
        blockedStudentsCount++;
      }
    }

    final avgAttendancePercent = students.isEmpty
        ? 0
        : ((totalHadirAll / (students.length * _maxMeetingsHeld)) * 100).round().clamp(0, 100);

    return Column(
      children: [
        AdminAppBar(
          title: 'Matriks Presensi (BAP & Kelayakan UAS)',
          showSearch: false,
          onBack: widget.onBack,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  children: [
                    // 1. Filter Panel
                    _buildFilterCard(),
                    const SizedBox(height: 14),

                    // 2. Summary Metric Cards
                    _buildMetricsRow(
                      totalStudents: students.length,
                      avgPercent: avgAttendancePercent,
                      eligibleCount: eligibleStudentsCount,
                      blockedCount: blockedStudentsCount,
                    ),
                    const SizedBox(height: 16),

                    // 3. Matrix Table Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table Header Bar with Actions
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: AdminAdaptiveRow(breakpoint: 1200,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(spacing: 8, runSpacing: 8,
                                      children: [
                                        const Text(
                                          'Tabel Matriks Pertemuan (P1 - P16)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySoft,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Min. $_thresholdPercent%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Ketuk sel presensi untuk mengubah kehadiran mahasiswa secara manual.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.file_copy_outlined, size: 13),
                                  label: const Text('BAP Resmi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  onPressed: _showBapOfficialDocumentModal,
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('Ekspor CSV', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                                  onPressed: _exportMatrixCsv,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // Interactive Matrix Horizontal Scroll
                          if (students.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('Tidak ada mahasiswa aktif pada kelas ini.'),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columnSpacing: 10,
                                horizontalMargin: 16,
                                columns: [
                                  const DataColumn(label: Text('No', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  const DataColumn(label: Text('NIM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  const DataColumn(label: Text('Mahasiswa', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  const DataColumn(label: Text('Kelas', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  for (int p = 1; p <= 16; p++)
                                    DataColumn(
                                      label: Center(
                                        child: Text(
                                          p == 8 ? 'P8\n(UTS)' : (p == 16 ? 'P16\n(UAS)' : 'P$p'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: (p == 8 || p == 16) ? AppColors.primary : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const DataColumn(label: Text('Hadir', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  const DataColumn(label: Text('%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                  const DataColumn(label: Text('Kelayakan UAS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                                ],
                                rows: [
                                  for (int i = 0; i < students.length; i++)
                                    _buildDataRow(i + 1, students[i]),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ],
    );
  }

  // Filter Card
  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAdaptiveRow(breakpoint: 900,
            children: [
              // 1. Pilih Mata Kuliah
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mata Kuliah:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<Course>(
                      initialValue: _selectedCourse,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: widget.courses.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.nama} (${c.kode} • ${c.sks} SKS)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCourse = val);
                          _loadAttendanceMatrix();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 2. Pilih Kelas
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter Kelas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKelas, isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['Semua Kelas', ...widget.classes.map((c) => c.nama)].map((k) {
                        return DropdownMenuItem(
                          value: k,
                          child: Text(k, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedKelas = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3. Ambang Batas Kehadiran
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batas UAS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      initialValue: _thresholdPercent, isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 70.0, child: Text('70%')),
                        DropdownMenuItem(value: 75.0, child: Text('75%')),
                        DropdownMenuItem(value: 80.0, child: Text('80%')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _thresholdPercent = val);
                      },
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

  // Summary Metrics Row
  Widget _buildMetricsRow({
    required int totalStudents,
    required int avgPercent,
    required int eligibleCount,
    required int blockedCount,
  }) {
    return AdminAdaptiveRow(breakpoint: 900,
      children: [
        _buildMetricTile(
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF3B82F6),
          title: 'Total Mahasiswa',
          value: '$totalStudents Org',
        ),
        const SizedBox(width: 10),
        _buildMetricTile(
          icon: Icons.pie_chart_rounded,
          color: const Color(0xFF8B5CF6),
          title: 'Rata-rata Kelas',
          value: '$avgPercent%',
        ),
        const SizedBox(width: 10),
        _buildMetricTile(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          title: 'Layak Ikut UAS',
          value: '$eligibleCount Org',
        ),
        const SizedBox(width: 10),
        _buildMetricTile(
          icon: Icons.warning_rounded,
          color: const Color(0xFFEF4444),
          title: 'Terancam Dicekal',
          value: '$blockedCount Org',
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DataRow Generator
  DataRow _buildDataRow(int no, StudentProfile s) {
    final rowAttendance = _matrixData[s.nim] ?? {};
    final rowNotes = _notesData[s.nim] ?? {};

    int hadirCount = 0;
    for (int p = 1; p <= 16; p++) {
      if ((rowAttendance[p] ?? '').toLowerCase() == 'hadir') hadirCount++;
    }

    final activeMeetings = _maxMeetingsHeld > 0 ? _maxMeetingsHeld : 16;
    final percent = ((hadirCount / activeMeetings) * 100).round();
    final isEligible = percent >= _thresholdPercent;

    return DataRow(
      cells: [
        DataCell(Text('$no', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
        DataCell(Text(s.nim, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  s.nama.isNotEmpty ? s.nama[0].toUpperCase() : 'M',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.nama,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
        DataCell(Text(s.kelas, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
        for (int p = 1; p <= 16; p++)
          DataCell(
            _buildMeetingCell(
              student: s,
              pertemuanKe: p,
              status: rowAttendance[p] ?? '',
              note: rowNotes[p],
            ),
          ),
        DataCell(
          Center(
            child: Text(
              '$hadirCount/$activeMeetings',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              '$percent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isEligible ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isEligible ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isEligible ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
            ),
            child: Text(
              isEligible ? 'LAYAK UAS' : 'DICEKAL',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isEligible ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Interactive Meeting Cell
  Widget _buildMeetingCell({
    required StudentProfile student,
    required int pertemuanKe,
    required String status,
    String? note,
  }) {
    Color bg;
    Color fg;
    String letter;

    switch (status.toLowerCase()) {
      case 'hadir':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        letter = 'H';
        break;
      case 'izin':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        letter = 'I';
        break;
      case 'sakit':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF2563EB);
        letter = 'S';
        break;
      case 'alpa':
      case 'alfa':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        letter = 'A';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF94A3B8);
        letter = '-';
        break;
    }

    return InkWell(
      onTap: () => _showChangeStatusDialog(
        student: student,
        pertemuanKe: pertemuanKe,
        currentStatus: status,
        currentNote: note,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Tooltip(
        message: 'P$pertemuanKe: ${status.isEmpty ? "Belum ada catatan" : status.toUpperCase()}${note != null ? " ($note)" : ""}',
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
