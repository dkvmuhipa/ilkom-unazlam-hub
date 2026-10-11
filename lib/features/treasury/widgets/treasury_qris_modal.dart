import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/safe_launcher.dart';
import '../../../models/models.dart';

class TreasuryQrisModal extends StatelessWidget {
  final List<StudentProfile> students;

  const TreasuryQrisModal({
    super.key,
    required this.students,
  });

  static void show(BuildContext context, {required List<StudentProfile> students}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TreasuryQrisModal(students: students),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rekeningNomor = '123-00-1098273-1';
    const bankName = 'Bank Mandiri / QRIS Kas Kelas';
    const atasNama = 'BENDAHARA ILKOM UNAZLAM 2026';
    const nominalIuran = 'Rp 20.000 / Bulan';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF1E40AF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran Kas & QRIS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pindai QRIS atau transfer rekening resmi kelas',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Visual QR Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF86EFAC), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'QRIS RESMI KAS KELAS ILKOM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Visual Container
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 110,
                          color: Color(0xFF1E1B4B),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'UNAZLAM PAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E40AF),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    atasNama,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Iuran Wajib: $nominalIuran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Detail Rekening & Salin Nomor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          rekeningNomor,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: rekeningNomor));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nomor rekening berhasil disalin!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: Color(0xFF475569)),
                          SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Petunjuk Pembayaran Singkat
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Setelah transfer atau scan QRIS, simpan bukti transfer dan konfirmasi ke Bendahara Kelas melalui tombol di bawah untuk diverifikasi.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Konfirmasi WA
            ElevatedButton.icon(
              onPressed: () {
                final message = Uri.encodeComponent(
                  'Halo Bendahara, saya ingin konfirmasi pembayaran kas kelas ILKOM UNAZLAM sebesar $nominalIuran. Berikut saya lampirkan bukti transfernya. Terima kasih!',
                );
                String bendaharaPhone = '';
                for (final s in students) {
                  if (s.role.toUpperCase() == 'BENDAHARA' && s.noWa.isNotEmpty) {
                    bendaharaPhone = s.noWa;
                    break;
                  }
                }
                if (bendaharaPhone.isEmpty && students.isNotEmpty) {
                  bendaharaPhone = students.first.noWa;
                }
                final rawPhone = bendaharaPhone.replaceAll(RegExp(r'\D'), '');
                final phone = rawPhone.startsWith('0') ? '62${rawPhone.substring(1)}' : rawPhone;
                final url = phone.isNotEmpty
                    ? 'https://wa.me/$phone?text=$message'
                    : 'https://wa.me/?text=$message';
                safeLaunchUrl(url);
              },
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text(
                'Konfirmasi Pembayaran via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
