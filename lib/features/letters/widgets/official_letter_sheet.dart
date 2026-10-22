import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/safe_launcher.dart';
import '../../../core/services/export_service.dart';
import '../../../models/models.dart';

class OfficialLetterSheet extends StatelessWidget {
  final PermissionLetter letter;
  final VoidCallback? onDelete;

  const OfficialLetterSheet({super.key, required this.letter, this.onDelete});

  static void show(
    BuildContext context, {
    required PermissionLetter letter,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollController) =>
            OfficialLetterSheet(letter: letter, onDelete: onDelete),
      ),
    );
  }

  String get _letterNumber {
    final year = letter.createdAt.year;
    final monthRoman = _toRoman(letter.createdAt.month);
    final shortId = letter.id.replaceAll(RegExp(r'\D'), '');
    final seq = shortId.length >= 4
        ? shortId.substring(shortId.length - 4)
        : '001';
    return '$seq/ILKOM-UNAZLAM/IZN/$monthRoman/$year';
  }

  static String _toRoman(int number) {
    const roman = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    if (number >= 1 && number <= 12) return roman[number - 1];
    return 'X';
  }

  String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  String _generatePrintableHtml() {
    final studentName = _escapeHtml(letter.studentName);
    final studentNim = _escapeHtml(letter.studentNim);
    final courseName = _escapeHtml(letter.courseName);
    final lecturerName = _escapeHtml(letter.dosenName);
    final reason = _escapeHtml(letter.reason);
    final letterDate = _escapeHtml(letter.letterDate);
    final letterId = _escapeHtml(letter.id);
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Surat Permohonan Izin - $studentName</title>
  <style>
    body {
      font-family: 'Times New Roman', Times, serif;
      margin: 40px auto;
      max-width: 750px;
      line-height: 1.6;
      color: #000;
    }
    .header {
      text-align: center;
      border-bottom: 3px double #000;
      padding-bottom: 12px;
      margin-bottom: 24px;
    }
    .header h2 { margin: 0; font-size: 16pt; font-weight: bold; text-transform: uppercase; }
    .header h3 { margin: 2px 0; font-size: 13pt; font-weight: bold; }
    .header h4 { margin: 2px 0; font-size: 12pt; font-weight: normal; }
    .header p { margin: 2px 0; font-size: 9pt; font-style: italic; }
    .meta-table { width: 100%; margin-bottom: 20px; font-size: 11pt; }
    .meta-table td { vertical-align: top; padding: 2px 0; }
    .content { font-size: 11pt; text-align: justify; }
    .student-data { margin: 15px 0 15px 30px; font-size: 11pt; }
    .student-data td { padding: 2px 6px; }
    .signature-row {
      margin-top: 40px;
      display: flex;
      justify-content: space-between;
      page-break-inside: avoid;
    }
    .signature-box {
      text-align: center;
      width: 250px;
      font-size: 11pt;
    }
    .signature-box .name {
      margin-top: 60px;
      font-weight: bold;
      text-decoration: underline;
    }
    .verification-box {
      border: 1px dashed #666;
      padding: 10px;
      font-size: 9pt;
      width: 240px;
      text-align: center;
      background: #fafafa;
    }
    @media print {
      body { margin: 20mm; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h2>UNIVERSITAS ABDUL AZIS LAMADJIDO (UNAZLAM)</h2>
    <h3>FAKULTAS ILMU SOSIAL DAN ILMU POLITIK (FISIP)</h3>
    <h4>PROGRAM STUDI S1 ILMU KOMUNIKASI</h4>
    <p>Jl. Dr. Soeharso No. 36A, Besusu Barat, Palu Timur, Kota Palu, Sulawesi Tengah 94118 | info@unazlam.ac.id</p>
  </div>

  <table class="meta-table">
    <tr>
      <td width="15%">Nomor</td>
      <td width="2%">:</td>
      <td width="48%">$_letterNumber</td>
      <td width="35%" align="right">Palu, ${_escapeHtml(DateFormat('dd MMMM yyyy', 'id_ID').format(letter.createdAt))}</td>
    </tr>
    <tr>
      <td>Lampiran</td>
      <td>:</td>
      <td>-</td>
      <td></td>
    </tr>
    <tr>
      <td>Hal</td>
      <td>:</td>
      <td><strong>Permohonan Izin Perkuliahan</strong></td>
      <td></td>
    </tr>
  </table>

  <div class="content">
    <p>Kepada Yth.<br>
    <strong>Bapak/Ibu Dosen Pengampu: $lecturerName</strong><br>
    Mata Kuliah: $courseName<br>
    Program Studi S1 Ilmu Komunikasi<br>
    Universitas Abdul Azis Lamadjido<br>
    di Tempat</p>

    <p><em>Assalamu'alaikum Wr. Wb.</em></p>
    <p>Dengan hormat, saya yang bertanda tangan di bawah ini:</p>

    <table class="student-data">
      <tr><td width="140">Nama Mahasiswa</td><td>:</td><td><strong>$studentName</strong></td></tr>
      <tr><td>NIM</td><td>:</td><td>$studentNim</td></tr>
      <tr><td>Program Studi</td><td>:</td><td>S1 Ilmu Komunikasi</td></tr>
      <tr><td>Kategori Izin</td><td>:</td><td>${_escapeHtml(letter.letterType)}</td></tr>
      <tr><td>Hari / Tanggal</td><td>:</td><td>$letterDate</td></tr>
    </table>

    <p>Bermaksud memohon izin tidak dapat mengikuti perkuliahan tatap muka pada hari dan tanggal tersebut dikarenakan: <strong>$reason</strong>.</p>

    <p>Sebagai komitmen akademik, saya berjanji untuk mempelajari materi perkuliahan secara mandiri serta menyelesaikan tugas perkuliahan yang diberikan pada sesi tersebut.</p>

    <p>Demikian surat permohonan izin ini saya ajukan dengan sebenar-benarnya. Atas perhatian, kebijaksanaan, dan izin yang Bapak/Ibu Dosen berikan, saya sampaikan terima kasih.</p>
    
    <p><em>Wassalamu'alaikum Wr. Wb.</em></p>
  </div>

  <div class="signature-row">
    <div class="verification-box">
      <strong>VERIFIKASI DIGITAL KAMPUS</strong><br>
      Dokumen ini diterbitkan sah melalui Portal ILKOM UNAZLAM HUB.<br>
      ID: $letterId<br>
      Status: Tercatat & Terverifikasi
    </div>
    <div class="signature-box">
      Pemohon,<br>
      <div class="name">$studentName</div>
      NIM. $studentNim
    </div>
  </div>

</body>
</html>
''';
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final text = letter.fullContent;
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final opened = await safeLaunchUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak dapat dibuka. Gunakan tombol Salin Teks untuk mengirim surat secara manual.',
          ),
        ),
      );
    }
  }

  void _copyOfficialText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: letter.fullContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks surat resmi berhasil disalin ke clipboard! 📋'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _printOfficialDocument(BuildContext context) async {
    final html = _generatePrintableHtml();
    final opened = ExportService.printHtml(html);
    FileExportResult? exportResult;
    if (!opened) {
      final fileName =
          'Surat_Izin_${letter.studentNim}_${letter.createdAt.millisecondsSinceEpoch}.html';
      exportResult = await ExportService.exportFile(fileName, html);
      if (exportResult == FileExportResult.dismissed) return;
      if (exportResult == FileExportResult.unavailable) {
        await Clipboard.setData(ClipboardData(text: letter.fullContent));
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Dokumen dibuka pada tab cetak. Pilih Cetak atau Simpan sebagai PDF.'
              : switch (exportResult!) {
                  FileExportResult.downloaded => 'File HTML surat berhasil diunduh. Buka file lalu pilih Cetak atau Simpan sebagai PDF.',
                  FileExportResult.shared =>
                    'Pilih aplikasi untuk menyimpan atau mencetak surat.',
                  FileExportResult.dismissed => '',
                  FileExportResult.unavailable => 'Ekspor surat tidak tersedia. Isi surat disalin ke clipboard.',
                },
        ),
        backgroundColor: opened || exportResult != FileExportResult.unavailable
            ? const Color(0xFF16A34A)
            : const Color(0xFF2563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData =
        'UNAZLAM-VERIFIED|ID:${letter.id}|NIM:${letter.studentNim}|TGL:${letter.letterDate}|MK:${letter.courseName}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF15803D),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Dokumen Resmi Terverifikasi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    tooltip: 'Hapus Surat',
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Document Sheet
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KOP SURAT RESMI
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D28D9)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 26,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'UNIVERSITAS ABDUL AZIS LAMADJIDO',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'FAKULTAS ILMU SOSIAL DAN ILMU POLITIK (FISIP)',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'PROGRAM STUDI S1 ILMU KOMUNIKASI',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6D28D9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Jl. Dr. Soeharso No. 36A, Besusu Barat, Palu Timur, Kota Palu, Sulawesi Tengah 94118',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 9,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Double line border standard academic letterhead
                    Column(
                      children: [
                        Container(height: 2, color: const Color(0xFF0F172A)),
                        const SizedBox(height: 1.5),
                        Container(height: 0.8, color: const Color(0xFF0F172A)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Letter Meta Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor  : $_letterNumber',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const Text(
                              'Lamp.  : -',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Text(
                              'Perihal: Permohonan Izin Kuliah',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Palu, ${DateFormat('dd MMM yyyy', 'id_ID').format(letter.createdAt)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Recipient
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kepada Yth.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Bapak/Ibu Dosen: ${letter.dosenName}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Pengampu Mata Kuliah: ${letter.courseName}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Body Paragraphs
                    const Text(
                      "Assalamu'alaikum Wr. Wb.\n\nDengan hormat, saya yang bertanda tangan di bawah ini:",
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Student Details Table Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Nama',
                            letter.studentName,
                            isBold: true,
                          ),
                          _buildDetailRow('NIM', letter.studentNim),
                          _buildDetailRow(
                            'Program Studi',
                            'S1 Ilmu Komunikasi',
                          ),
                          _buildDetailRow('Kategori Izin', letter.letterType),
                          _buildDetailRow('Hari/Tanggal', letter.letterDate),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Bermaksud mengajukan permohonan izin untuk tidak mengikuti kegiatan perkuliahan tatap muka dikarenakan: "${letter.reason}".',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sebagai tindak lanjut, saya berkomitmen untuk tetap mempelajari materi perkuliahan secara mandiri dan mengumpulkan tugas yang diberikan pada sesi tersebut.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Demikian surat ini saya sampaikan dengan sebenar-benarnya. Atas perhatian dan izin yang diberikan, saya ucapkan terima kasih.\n\nWassalamu'alaikum Wr. Wb.",
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Signature & Verification QR Code Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Digital Verification Stamp
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              children: [
                                QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 56.0,
                                  gapless: true,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TERVERIFIKASI',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Portal ILKOM UNAZLAM',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        'Dokumen Digital Sah',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Student Sign Box
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Pemohon,',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 38),
                            Text(
                              letter.studentName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'NIM. ${letter.studentNim}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Copy
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyOfficialText(context),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Teks'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6D28D9),
                      side: const BorderSide(color: Color(0xFF6D28D9)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Download HTML / Print
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printOfficialDocument(context),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Cetak / PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send WA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareViaWhatsApp(context),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Kirim WA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
