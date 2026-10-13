import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

class LettersScreen extends StatefulWidget {
  final String studentName;
  final String studentNim;
  final VoidCallback? onBack;

  const LettersScreen({
    super.key,
    this.studentName = 'Nur Farida',
    this.studentNim = '260250023',
    this.onBack,
  });

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedType = 'Izin Sakit';
  late final TextEditingController _dosenController;
  late final TextEditingController _courseController;
  final _alasanController = TextEditingController(
    text: 'Kondisi kesehatan sedang menurun (demam) dan memerlukan istirahat',
  );
  final _tanggalController = TextEditingController(text: 'Rabu, 7 Oktober 2026');

  List<PermissionLetter> _savedLetters = [];
  List<Course> _courses = [];
  bool _isLoadingArchive = false;
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _courseController = TextEditingController(text: 'Pendidikan Pancasila');
    _dosenController = TextEditingController(text: 'Drs. H. M. Rusli, M.Si');

    _loadInitialData();
    _setupRealtime();
  }

  Future<void> _loadInitialData() async {
    _loadArchive();
    try {
      final crs = await SupabaseRepository.getCourses();
      if (mounted && crs.isNotEmpty) {
        setState(() {
          _courses = crs;
          _courseController.text = crs.first.nama;
          _dosenController.text = crs.first.dosen;
        });
      }
    } catch (_) {}
  }

  void _setupRealtime() {
    SupabaseRepository.subscribeToPermissionLetters(() {
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
      final list = await SupabaseRepository.getPermissionLetters(studentNim: widget.studentNim);
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
    _realtimeSub?.cancel();
    super.dispose();
  }

  String _generateLetterContent() {
    return '''
HAL: PERMOHONAN IZIN TIDAK MENGIKUTI PERKULIAHAN

Kepada Yth.
Bapak/Ibu Dosen Pengampu: ${_dosenController.text.trim()}
Mata Kuliah: ${_courseController.text.trim()}
Program Studi S1 Ilmu Komunikasi
Universitas Nahdlatul Ulama Al Ghazali (UNAZLAM)

Assalamu'alaikum Wr. Wb.

Dengan hormat,
Saya yang bertanda tangan di bawah ini:
Nama        : ${widget.studentName}
NIM         : ${widget.studentNim}
Program Studi: S1 Ilmu Komunikasi (Semester 1)
Kelas       : Reguler 2026

Bermaksud mengajukan permohonan izin untuk tidak dapat mengikuti kegiatan perkuliahan pada:
Hari/Tanggal: ${_tanggalController.text.trim()}
Alasan      : ${_alasanController.text.trim()}

Sebagai tindak lanjut, saya berkomitmen untuk tetap mempelajari materi perkuliahan serta menyelesaikan tugas mandiri yang diberikan pada pertemuan tersebut.

Demikian surat permohonan izin ini saya sampaikan dengan sebenar-benarnya. Atas perhatian, kebijaksanaan, dan izin yang Bapak/Ibu Dosen berikan, saya ucapkan terima kasih.

Wassalamu'alaikum Wr. Wb.

Cilacap, ${_tanggalController.text.trim()}
Hormat saya,


${widget.studentName}
(NIM: ${widget.studentNim})
''';
  }

  Future<PermissionLetter> _persistCurrentLetter() async {
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
    return saved ?? newLetter;
  }

  Future<void> _shareToWhatsApp() async {
    await _persistCurrentLetter();

    final text = _generateLetterContent();
    String? dosenWa;
    try {
      final course = _courses.firstWhere(
        (c) => c.nama.trim().toLowerCase() == _courseController.text.trim().toLowerCase(),
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat izin telah tersimpan ke arsip dan diteruskan ke WhatsApp! 📨'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await _persistCurrentLetter();
    Clipboard.setData(ClipboardData(text: _generateLetterContent()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teks surat izin tersimpan di arsip dan disalin ke clipboard! 📋'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _deleteLetter(PermissionLetter letter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Arsip Surat?'),
        content: Text('Hapus surat izin untuk mata kuliah "${letter.courseName}" tanggal ${letter.letterDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter.courseName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          '${letter.letterType} • Dosen: ${letter.dosenName}',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteLetter(letter);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                    tooltip: 'Hapus Surat',
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SelectableText(
                  letter.fullContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: letter.fullContent));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Surat disalin ke clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Teks'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(letter.fullContent)}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Kirim ke WA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
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
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
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
        children: [
          _buildFormTab(),
          _buildArchiveTab(),
        ],
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.description_outlined, color: Color(0xFF1E40AF), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buat surat permohonan izin kuliah resmi berformat akademik dan langsung simpan ke arsip atau kirim ke Dosen Pengampu.',
                    style: TextStyle(color: Color(0xFF4C1D95), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Letter Type Selector
          const Text('Jenis Permohonan Surat:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: ['Izin Sakit', 'Keperluan Mendesak', 'Dispensasi'].map((type) {
              final isSel = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
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
                  selectedColor: const Color(0xFF1E40AF),
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF374151),
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
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
                    value: _courses.any((c) => c.nama == _courseController.text)
                        ? _courseController.text
                        : _courses.first.nama,
                    decoration: InputDecoration(
                      labelText: 'Pilih Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: _courses.map((c) {
                      return DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final course = _courses.firstWhere((c) => c.nama == val, orElse: () => _courses.first);
                        setState(() {
                          _courseController.text = course.nama;
                          _dosenController.text = course.dosen;
                        });
                      }
                    },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dosenController,
                  decoration: InputDecoration(
                    labelText: 'Nama Dosen Pengampu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalController,
                  decoration: InputDecoration(
                    labelText: 'Hari & Tanggal Izin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alasanController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Detail Alasan Izin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preview Box
          const Text('Pratinjau Surat Resmi:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 8),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Simpan & Salin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E40AF),
                    side: const BorderSide(color: Color(0xFF1E40AF)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareToWhatsApp,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Kirim ke WA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Icon(Icons.mark_email_unread_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'Belum Ada Arsip Surat',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text(
                letter.courseName,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '${letter.letterType} • ${letter.letterDate}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Dosen: ${letter.dosenName}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF6B7280)),
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
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showLetterDetail(letter),
            ),
          );
        },
      ),
    );
  }
}
