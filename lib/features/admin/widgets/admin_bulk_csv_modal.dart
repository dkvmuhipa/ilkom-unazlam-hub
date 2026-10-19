import 'admin_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../core/constants/app_colors.dart';
import '../../../core/services/bulk_csv_service.dart';
import '../../../core/services/csv_file_reader.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';

enum BulkImportType { students, courses }

class AdminBulkCsvModal extends StatefulWidget {
  final bool fullPage;
  final BulkImportType initialType;
  final Future<void> Function() onReload;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  })
  onRecordAudit;

  const AdminBulkCsvModal({
    super.key,
    this.fullPage = false,
    this.initialType = BulkImportType.students,
    required this.onReload,
    required this.onShowMessage,
    required this.onRecordAudit,
  });

  static Future<void> show(
    BuildContext context, {
    BulkImportType initialType = BulkImportType.students,
    required Future<void> Function() onReload,
    required void Function(String message, {bool isError}) onShowMessage,
    required void Function({
      required String action,
      required String module,
      required String description,
      Map<String, dynamic>? metadata,
    })
    onRecordAudit,
  }) {
    return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100),
        child: AdminBulkCsvModal(fullPage: true, initialType: initialType, onReload: onReload,
          onShowMessage: onShowMessage, onRecordAudit: onRecordAudit)))),
    )));
  }

  @override
  State<AdminBulkCsvModal> createState() => _AdminBulkCsvModalState();
}

class _AdminBulkCsvModalState extends State<AdminBulkCsvModal> {
  late BulkImportType _selectedType;
  final TextEditingController _textController = TextEditingController();

  bool _isProcessing = false;
  bool _isImporting = false;
  bool _updateExisting = true;
  String? _loadedFileName;

  // Parsed Data
  List<ParsedStudentRow> _parsedStudents = [];
  List<ParsedCourseRow> _parsedCourses = [];
  bool _hasValidated = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _switchType(BulkImportType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _textController.clear();
      _loadedFileName = null;
      _parsedStudents = [];
      _parsedCourses = [];
      _hasValidated = false;
    });
  }

  Future<void> _downloadTemplate() async {
    late final String fileName;
    late final String template;
    if (_selectedType == BulkImportType.students) {
      fileName = 'template_mahasiswa_unazlam.csv';
      template = BulkCsvService.getStudentCsvTemplate();
    } else {
      fileName = 'template_matakuliah_unazlam.csv';
      template = BulkCsvService.getCourseCsvTemplate();
    }
    final result = await ExportService.exportFile(fileName, template);
    if (result == FileExportResult.dismissed) return;
    if (result == FileExportResult.unavailable) {
      await Clipboard.setData(ClipboardData(text: template));
    }
    widget.onShowMessage(switch (result) {
      FileExportResult.downloaded => 'Template CSV berhasil diunduh.',
      FileExportResult.shared =>
        'Menu berbagi terbuka. Pilih aplikasi untuk menyimpan template CSV.',
      FileExportResult.dismissed => '',
      FileExportResult.unavailable =>
        'Ekspor file tidak tersedia. Template CSV disalin ke clipboard.',
    });
  }

  void _copyTemplate() {
    final template = _selectedType == BulkImportType.students
        ? BulkCsvService.getStudentCsvTemplate()
        : BulkCsvService.getCourseCsvTemplate();
    Clipboard.setData(ClipboardData(text: template));
    widget.onShowMessage('Contoh data CSV berhasil disalin ke clipboard.');
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
        _loadedFileName = 'Dari Clipboard (${data.text!.length} karakter)';
      });
      widget.onShowMessage('Data dari clipboard berhasil ditempel.');
    } else {
      widget.onShowMessage('Clipboard kosong.', isError: true);
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final content = await CsvFileReader.pickAndReadCsv();
      if (content != null && content.trim().isNotEmpty) {
        setState(() {
          _textController.text = content;
          _loadedFileName = 'File .csv Terpilih (${content.length} karakter)';
        });
        _validateAndParse();
      }
    } catch (e) {
      widget.onShowMessage('Gagal membaca file: $e', isError: true);
    }
  }

  void _validateAndParse() {
    final raw = _textController.text.trim();
    if (raw.isEmpty) {
      widget.onShowMessage(
        'Silakan upload file CSV atau tempel teks data terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_selectedType == BulkImportType.students) {
        final rows = BulkCsvService.parseStudents(raw);
        setState(() {
          _parsedStudents = rows;
          _hasValidated = true;
          _isProcessing = false;
        });
      } else {
        final rows = BulkCsvService.parseCourses(raw);
        setState(() {
          _parsedCourses = rows;
          _hasValidated = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      widget.onShowMessage('Gagal memproses data: $e', isError: true);
    }
  }

  Future<void> _executeImport() async {
    final totalValid = _selectedType == BulkImportType.students
        ? _parsedStudents.where((r) => r.isValid).length
        : _parsedCourses.where((r) => r.isValid).length;

    if (totalValid == 0) {
      widget.onShowMessage(
        'Tidak ada data valid yang dapat diimpor.',
        isError: true,
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      if (_selectedType == BulkImportType.students) {
        final res = await SupabaseRepository.bulkUpsertStudents(
          _parsedStudents,
          updateExisting: _updateExisting,
        );

        if (res['success'] == true) {
          final inserted = res['inserted'] ?? 0;
          final skipped = res['skipped'] ?? 0;
          widget.onRecordAudit(
            action: 'BULK_IMPORT',
            module: 'MAHASISWA',
            description:
                'Impor massal $inserted mahasiswa baru ($skipped dilewati).',
            metadata: {'inserted': inserted, 'skipped': skipped},
          );
          await widget.onReload();
          if (mounted) {
            Navigator.pop(context);
            widget.onShowMessage(
              'Berhasil mengimpor $inserted mahasiswa ke direktori! 🎉',
            );
          }
        } else {
          widget.onShowMessage(
            'Gagal impor: ${res['errorMessage']}',
            isError: true,
          );
        }
      } else {
        final res = await SupabaseRepository.bulkUpsertCourses(
          _parsedCourses,
          updateExisting: _updateExisting,
        );

        if (res['success'] == true) {
          final inserted = res['inserted'] ?? 0;
          final skipped = res['skipped'] ?? 0;
          widget.onRecordAudit(
            action: 'BULK_IMPORT',
            module: 'MATA_KULIAH',
            description:
                'Impor massal $inserted mata kuliah/jadwal ($skipped dilewati).',
            metadata: {'inserted': inserted, 'skipped': skipped},
          );
          await widget.onReload();
          if (mounted) {
            Navigator.pop(context);
            widget.onShowMessage(
              'Berhasil mengimpor $inserted mata kuliah & jadwal ke sistem! 🎉',
            );
          }
        } else {
          widget.onShowMessage(
            'Gagal impor: ${res['errorMessage']}',
            isError: true,
          );
        }
      }
    } catch (e) {
      widget.onShowMessage('Terjadi kesalahan impor: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 600;

    return Container(
      height: widget.fullPage ? double.infinity : media.size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Ingestion Hub',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Import massal data mahasiswa & jadwal kuliah via CSV / Excel',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Segmented Control (Mahasiswa vs Matakuliah)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeSegment(
                      title: 'Mahasiswa',
                      icon: Icons.people_alt_rounded,
                      type: BulkImportType.students,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTypeSegment(
                      title: 'Mata Kuliah & Jadwal',
                      icon: Icons.menu_book_rounded,
                      type: BulkImportType.courses,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body Content
          Expanded(
            child: _hasValidated
                ? _buildPreviewSection()
                : _buildInputSection(isCompact),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required IconData icon,
    required BulkImportType type,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => _switchType(type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isCompact) {
    final isStudent = _selectedType == BulkImportType.students;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // Upload Banner Box
        InkWell(
          onTap: _pickCsvFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loadedFileName ?? 'Pilih atau Tarik Berkas .csv ke Sini',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mendukung format CSV berkoma (,), titik koma (;), atau tab dari Excel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickCsvFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 15),
                  label: const Text('Buka Berkas Komputer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Template Download & Actions Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.table_chart_rounded,
                color: Color(0xFF16A34A),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStudent
                          ? 'Format Standar Mahasiswa'
                          : 'Format Standar Mata Kuliah',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Text(
                      isStudent
                          ? 'Kolom: NIM, Nama, Email, No WA, Kelas, Semester, Peminatan'
                          : 'Kolom: Kode MK, Nama MK, SKS, Semester, Dosen, Hari, Jam, Ruang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 13),
                label: const Text(
                  'Unduh Template',
                  style: TextStyle(fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Text Area for Copy-Paste
        AdminAdaptiveRow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Atau Salin-Tempel dari Excel / Spreadsheet:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _copyTemplate,
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: const Text(
                    'Salin Format',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF64748B),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded, size: 13),
                  label: const Text('Tempel', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _textController,
          maxLines: 7,
          style: const TextStyle(
            fontSize: 11.5,
            fontFamily: 'monospace',
            color: Color(0xFF1E293B),
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: isStudent
                ? 'NIM,Nama,Email,No WA,Kelas,Semester,Peminatan\n240101001,Ahmad Fadhil,ahmad@student.unazlam.ac.id,081234567890,Ilmu Komunikasi,1,Public Relations\n240101002,Siti Nurhaliza,siti@student.unazlam.ac.id,081298765432,Ilmu Komunikasi,1,Broadcasting'
                : 'Kode MK,Nama Mata Kuliah,SKS,Semester,Dosen Pengampu,Hari,Jam Mulai,Jam Selesai,Ruangan\nIK-101,Pengantar Ilmu Komunikasi,3,1,Dr. H. Muhammad Zainuddin M.Si,Senin,08:00,10:30,Ruang Teori A1\nIK-102,Teori Komunikasi Massa,2,1,Hj. Siti Aminah M.I.Kom,Selasa,10:00,11:40,Ruang Lab Multimedia',
            hintStyle: TextStyle(
              fontSize: 10.5,
              fontFamily: 'monospace',
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 18),

        // Validate Button
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _validateAndParse,
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.analytics_outlined, size: 18),
          label: Text(
            _isProcessing
                ? 'Memvalidasi Data...'
                : 'Proses & Validasi Skema Data',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final isStudent = _selectedType == BulkImportType.students;
    final totalRows = isStudent
        ? _parsedStudents.length
        : _parsedCourses.length;
    final validCount = isStudent
        ? _parsedStudents.where((r) => r.isValid).length
        : _parsedCourses.where((r) => r.isValid).length;
    final errorCount = totalRows - validCount;

    return Column(
      children: [
        // Stats Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildMiniStat('Total', '$totalRows', const Color(0xFF334155)),
              const VerticalDivider(width: 24, thickness: 1),
              _buildMiniStat(
                'Siap Impor',
                '$validCount',
                const Color(0xFF16A34A),
              ),
              const VerticalDivider(width: 24, thickness: 1),
              _buildMiniStat(
                'Format Salah',
                '$errorCount',
                const Color(0xFFDC2626),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _hasValidated = false),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text(
                  'Edit Input',
                  style: TextStyle(fontSize: 11.5),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // Upsert Toggle Option
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: _updateExisting,
                onChanged: (val) =>
                    setState(() => _updateExisting = val ?? true),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _updateExisting = !_updateExisting),
                  child: Text(
                    isStudent
                        ? 'Perbarui data profil jika NIM sudah terdaftar (Upsert)'
                        : 'Perbarui data mata kuliah jika Kode MK sudah terdaftar (Upsert)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Table List
        Expanded(
          child: isStudent ? _buildStudentsTable() : _buildCoursesTable(),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _hasValidated = false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: validCount == 0 || _isImporting
                      ? null
                      : _executeImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isImporting
                        ? 'Mengimpor ke Supabase...'
                        : 'Impor $validCount ${isStudent ? 'Mahasiswa' : 'Mata Kuliah'} Sekarang',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTable() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _parsedStudents.length,
      itemBuilder: (ctx, i) {
        final row = _parsedStudents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: row.isValid ? Colors.white : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: row.isValid
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  '${row.index}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: row.isValid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.isValid ? 'Valid' : 'Error',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: row.isValid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.nama.isNotEmpty ? row.nama : 'Tanpa Nama',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'NIM: ${row.nim} • ${row.kelas} • Smt ${row.semester}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (!row.isValid)
                      Text(
                        'Alasan: ${row.errors.join(", ")}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() {
                    _parsedStudents.removeAt(i);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursesTable() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _parsedCourses.length,
      itemBuilder: (ctx, i) {
        final row = _parsedCourses[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: row.isValid ? Colors.white : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: row.isValid
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  '${row.index}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: row.isValid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.isValid ? 'Valid' : 'Error',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: row.isValid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.nama.isNotEmpty ? row.nama : 'Tanpa Nama Matkul',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${row.kode} • ${row.sks} SKS • ${row.hari}, ${row.jamMulai}-${row.jamSelesai} • ${row.ruangan}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (!row.isValid)
                      Text(
                        'Alasan: ${row.errors.join(", ")}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() {
                    _parsedCourses.removeAt(i);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
