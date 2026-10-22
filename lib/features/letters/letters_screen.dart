import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/safe_launcher.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';
import 'widgets/official_letter_sheet.dart';

class LettersScreen extends StatefulWidget {
  final StudentProfile? student;
  final String studentName;
  final String studentNim;
  final VoidCallback? onBack;

  const LettersScreen({
    super.key,
    this.student,
    this.studentName = 'Mahasiswa ILKOM',
    this.studentNim = '',
    this.onBack,
  });

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedType = 'Izin Sakit';
  late final TextEditingController _dosenController;
  late final TextEditingController _courseController;
  final _alasanController = TextEditingController();
  final _tanggalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _courseLoadError;

  List<PermissionLetter> _savedLetters = [];
  List<Course> _courses = [];
  bool _isLoadingArchive = false;
  RealtimeChannel? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _courseController = TextEditingController();
    _dosenController = TextEditingController();
    _tanggalController.text = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);
    for (final controller in [
      _courseController,
      _dosenController,
      _tanggalController,
      _alasanController,
    ]) {
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _loadInitialData();
    _setupRealtime();
  }

  Future<void> _loadInitialData() async {
    _loadArchive();
    try {
      final crs = await SupabaseRepository.getCoursesStrict();
      if (mounted && crs.isNotEmpty) {
        setState(() {
          _courseLoadError = null;
          _courses = crs;
          _courseController.text = crs.first.nama;
          _dosenController.text = crs.first.dosen;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _courseLoadError = 'Daftar mata kuliah gagal dimuat. Coba lagi atau lengkapi nama mata kuliah dan dosen.',
        );
      }
    }
  }

  void _setupRealtime() {
    _realtimeSub = SupabaseRepository.subscribeToPermissionLetters(() {
      if (mounted) {
        _loadArchive(silent: true);
      }
    });
  }

  Future<void> _loadArchive({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingArchive = true);
    }
    try {
      final list = await SupabaseRepository.getPermissionLetters(
        studentNim: widget.studentNim,
      );
      if (mounted) {
        setState(() {
          _savedLetters = list;
          _isLoadingArchive = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingArchive = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dosenController.dispose();
    _courseController.dispose();
    _alasanController.dispose();
    _tanggalController.dispose();
    SupabaseRepository.unsubscribeChannel(_realtimeSub);
    super.dispose();
  }

  String _generateLetterContent() {
    return '''
HAL: PERMOHONAN IZIN TIDAK MENGIKUTI PERKULIAHAN

Kepada Yth.
Bapak/Ibu Dosen Pengampu: ${_dosenController.text.trim()}
Mata Kuliah: ${_courseController.text.trim()}
Program Studi S1 Ilmu Komunikasi
Universitas Abdul Azis Lamadjido (UNAZLAM)

Assalamu'alaikum Wr. Wb.

Dengan hormat,
Saya yang bertanda tangan di bawah ini:
Nama        : ${widget.studentName}
NIM         : ${widget.studentNim}
Program Studi: ${widget.student?.prodi ?? 'Ilmu Komunikasi'} (Semester ${widget.student?.semester ?? '-'})
Kelas       : ${widget.student?.kelas ?? '-'}

Bermaksud mengajukan permohonan izin untuk tidak dapat mengikuti kegiatan perkuliahan pada:
Hari/Tanggal: ${_tanggalController.text.trim()}
Alasan      : ${_alasanController.text.trim()}

Sebagai tindak lanjut, saya berkomitmen untuk tetap mempelajari materi perkuliahan serta menyelesaikan tugas mandiri yang diberikan pada pertemuan tersebut.

Demikian surat permohonan izin ini saya sampaikan dengan sebenar-benarnya. Atas perhatian, kebijaksanaan, dan izin yang Bapak/Ibu Dosen berikan, saya ucapkan terima kasih.

Wassalamu'alaikum Wr. Wb.

Palu, ${_tanggalController.text.trim()}
Hormat saya,


${widget.studentName}
(NIM: ${widget.studentNim})
''';
  }

  bool _validateLetter() {
    if ([
      _courseController,
      _dosenController,
      _tanggalController,
      _alasanController,
    ].any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi mata kuliah, dosen, tanggal, dan alasan izin.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickLetterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && mounted) {
      _selectedDate = picked;
      _tanggalController.text = DateFormat(
        'EEEE, d MMMM yyyy',
        'id_ID',
      ).format(picked);
    }
  }

  Future<PermissionLetter?> _persistCurrentLetter() async {
    if (_saving || !_validateLetter()) return null;
    _saving = true;
    try {
      final newLetter = PermissionLetter(
        id: 'letter_${DateTime.now().millisecondsSinceEpoch}',
        studentNim: widget.studentNim,
        studentName: widget.studentName,
        letterType: _selectedType,
        dosenName: _dosenController.text.trim(),
        courseName: _courseController.text.trim(),
        reason: _alasanController.text.trim(),
        letterDate: _tanggalController.text.trim(),
        fullContent: _generateLetterContent(),
        createdAt: DateTime.now(),
      );
      final saved = await SupabaseRepository.createPermissionLetter(newLetter);
      await _loadArchive(silent: true);
      if (saved == null) throw StateError('Surat gagal disimpan.');
      return saved;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surat gagal disimpan. Silakan coba lagi.'),
          ),
        );
      }
      return null;
    } finally {
      _saving = false;
    }
  }

  Future<void> _shareToWhatsApp() async {
    final saved = await _persistCurrentLetter();
    if (saved == null || !mounted) return;

    final text = saved.fullContent;
    String? dosenWa;
    try {
      final course = _courses.firstWhere(
        (c) =>
            c.nama.trim().toLowerCase() ==
            saved.courseName.trim().toLowerCase(),
      );
      if (course.dosenWa != null && course.dosenWa!.trim().isNotEmpty) {
        String clean = course.dosenWa!.replaceAll(RegExp(r'\D'), '');
        if (clean.startsWith('0')) {
          clean = '62${clean.substring(1)}';
        }
        dosenWa = clean;
      }
    } catch (_) {}

    final url = (dosenWa != null && dosenWa.isNotEmpty)
        ? 'https://wa.me/$dosenWa?text=${Uri.encodeComponent(text)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final opened = await safeLaunchUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened ? 'Surat tersimpan. Lanjutkan pengiriman di WhatsApp.' : 'Surat tersimpan, tetapi WhatsApp gagal dibuka. Coba salin teks surat.',
          ),
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    final saved = await _persistCurrentLetter();
    if (saved == null || !mounted) return;
    var copied = false;
    try {
      await Clipboard.setData(ClipboardData(text: saved.fullContent));
      copied = true;
    } catch (_) {
      copied = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied ? 'Surat tersimpan di arsip dan teks berhasil disalin.' : 'Surat tersimpan, tetapi teks gagal disalin. Silakan coba lagi.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteLetter(PermissionLetter letter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Arsip Surat?'),
        content: Text(
          'Hapus surat izin untuk mata kuliah "${letter.courseName}" tanggal ${letter.letterDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SupabaseRepository.deletePermissionLetter(letter.id);
    await _loadArchive(silent: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arsip surat izin berhasil dihapus.'),
          backgroundColor: Color(0xFF374151),
        ),
      );
    }
  }

  void _showLetterDetail(PermissionLetter letter) {
    OfficialLetterSheet.show(
      context,
      letter: letter,
      onDelete: () => _deleteLetter(letter),
    );
  }

  void _previewOfficialLetter() {
    if (!_validateLetter()) return;
    final previewLetter = PermissionLetter(
      id: 'letter_${DateTime.now().millisecondsSinceEpoch}',
      studentNim: widget.studentNim,
      studentName: widget.studentName,
      letterType: _selectedType,
      dosenName: _dosenController.text.trim(),
      courseName: _courseController.text.trim(),
      reason: _alasanController.text.trim(),
      letterDate: _tanggalController.text.trim(),
      fullContent: _generateLetterContent(),
      createdAt: DateTime.now(),
    );
    OfficialLetterSheet.show(context, letter: previewLetter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF111827),
                ),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Formulir & Surat Izin',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Buat Surat Izin'),
            Tab(text: 'Arsip Surat (${_savedLetters.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildArchiveTab()],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Color(0xFF6D28D9),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buat surat permohonan izin kuliah resmi berformat akademik dan langsung simpan ke arsip atau kirim ke Dosen Pengampu.',
                    style: TextStyle(
                      color: Color(0xFF4C1D95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Letter Type Selector
          const Text(
            'Jenis Permohonan Surat:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Izin Sakit', 'Keperluan Mendesak', 'Dispensasi'].map((
              type,
            ) {
              final isSel = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSel,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedType = type;
                      if (type == 'Izin Sakit') {
                        _alasanController.text = 'Kondisi kesehatan sedang menurun (sakit) dan memerlukan istirahat';
                      } else if (type == 'Keperluan Mendesak') {
                        _alasanController.text = 'Terdapat urusan keluarga yang sangat mendesak dan tidak dapat ditinggalkan';
                      } else {
                        _alasanController.text = 'Mengikuti kegiatan resmi perwakilan kampus / organisasi mahasiswa';
                      }
                    });
                  }
                },
                selectedColor: const Color(0xFF6D28D9),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF374151),
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Form Inputs Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_courses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue:
                        _courses.any((c) => c.nama == _courseController.text)
                        ? _courseController.text
                        : _courses.first.nama,
                    decoration: InputDecoration(
                      labelText: 'Pilih Mata Kuliah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    items: _courses.map((c) {
                      return DropdownMenuItem(
                        value: c.nama,
                        child: Text(
                          c.nama,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final course = _courses.firstWhere(
                          (c) => c.nama == val,
                          orElse: () => _courses.first,
                        );
                        setState(() {
                          _courseController.text = course.nama;
                          _dosenController.text = course.dosen;
                        });
                      }
                    },
                  ),
                const SizedBox(height: 12),
                if (_courseLoadError != null)
                  MaterialBanner(
                    content: Text(_courseLoadError!),
                    actions: [
                      TextButton(
                        onPressed: _loadInitialData,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                TextField(
                  controller: _dosenController,
                  decoration: InputDecoration(
                    labelText: 'Nama Dosen Pengampu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalController,
                  readOnly: true,
                  onTap: _pickLetterDate,
                  decoration: InputDecoration(
                    labelText: 'Hari & Tanggal Izin',
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alasanController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Detail Alasan Izin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preview Box
          // Preview Box Header with Official Sheet button
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Pratinjau Surat Resmi:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: _previewOfficialLetter,
                icon: const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF6D28D9),
                ),
                label: const Text(
                  'Format Ber-Kop & QR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SelectableText(
              _generateLetterContent(),
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF1F2937),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _previewOfficialLetter,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Dokumen Resmi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF94A3B8)),
                  minimumSize: const Size.fromHeight(46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Simpan & Salin'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6D28D9),
                  side: const BorderSide(color: Color(0xFF6D28D9)),
                  minimumSize: const Size.fromHeight(46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _shareToWhatsApp,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Kirim WA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab() {
    if (_isLoadingArchive) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedLetters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              const Text(
                'Belum Ada Arsip Surat',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Surat izin yang Anda buat dan bagikan akan otomatis tersimpan di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Surat Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadArchive(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _savedLetters.length,
        itemBuilder: (ctx, i) {
          final letter = _savedLetters[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                letter.courseName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '${letter.letterType} • ${letter.letterDate}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Dosen: ${letter.dosenName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                onSelected: (val) {
                  if (val == 'view') {
                    _showLetterDetail(letter);
                  } else if (val == 'delete') {
                    _deleteLetter(letter);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Lihat & Bagikan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showLetterDetail(letter),
              ),
            ),
          );
        },
      ),
    );
  }
}
