import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';

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

class _LettersScreenState extends State<LettersScreen> {
  String _selectedType = 'Izin Sakit';
  final _dosenController = TextEditingController(text: 'Drs. H. Ahmad Fauzi, M.Si.');
  final _courseController = TextEditingController(text: 'Pendidikan Pancasila');
  final _alasanController = TextEditingController(text: 'Kondisi kesehatan sedang menurun (demam) dan memerlukan istirahat');
  final _tanggalController = TextEditingController(text: 'Senin, 5 Oktober 2026');

  @override
  void dispose() {
    _dosenController.dispose();
    _courseController.dispose();
    _alasanController.dispose();
    _tanggalController.dispose();
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

  Future<void> _shareToWhatsApp() async {
    final text = _generateLetterContent();
    String? dosenWa;
    try {
      final course = DummyData.courses.firstWhere(
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
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generateLetterContent()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks surat izin resmi berhasil disalin ke clipboard! 📋'),
        backgroundColor: Color(0xFF10B981),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.description_outlined, color: Color(0xFF5B3DE8), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Buat surat permohonan izin kuliah resmi berformat akademik dan langsung kirim ke Dosen Pengampu.',
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
                    selectedColor: const Color(0xFF5B3DE8),
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
                  DropdownButtonFormField<String>(
                    initialValue: DummyData.courses.first.nama,
                    decoration: InputDecoration(
                      labelText: 'Pilih Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: DummyData.courses.map((c) {
                      return DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final course = DummyData.courses.firstWhere((c) => c.nama == val);
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
                    label: const Text('Salin Teks'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B3DE8),
                      side: const BorderSide(color: Color(0xFF5B3DE8)),
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
      ),
    );
  }
}
