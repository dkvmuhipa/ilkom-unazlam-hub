import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({super.key});

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  String _selectedFilter = 'Semua';

  String _formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showAddTransactionModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isPemasukan = true;
    String kategori = 'Kas Bulanan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat Transaksi Kas Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPemasukan ? AppColors.successSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isPemasukan ? AppColors.success : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 16, color: isPemasukan ? AppColors.success : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: isPemasukan ? AppColors.success : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isPemasukan ? AppColors.errorSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: !isPemasukan ? AppColors.error : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 16, color: !isPemasukan ? AppColors.error : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: !isPemasukan ? AppColors.error : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Misal: Iuran Kas Bulan Maret atau Beli Baterai',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Nominal (Rp)',
                  hintText: 'Contoh: 150000',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
                  if (titleController.text.trim().isEmpty || amount <= 0) return;

                  setState(() {
                    DummyData.treasuryTransactions.insert(
                      0,
                      TreasuryTransaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        judul: titleController.text.trim(),
                        nominal: amount,
                        isPemasukan: isPemasukan,
                        kategori: kategori,
                        tanggal: DateTime.now(),
                        pencatat: 'Alya Nabilah (Bendahara)',
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi kas berhasil dicatat!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = DummyData.treasuryTransactions.where((t) {
      if (_selectedFilter == 'Pemasukan') return t.isPemasukan;
      if (_selectedFilter == 'Pengeluaran') return !t.isPemasukan;
      return true;
    }).toList();

    final totalSaldo = DummyData.totalKasSaldo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kas & Keuangan Kelas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionModal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Catat Kas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Saldo Card (Modern Royal Violet)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Saldo Kas Kelas',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Transparan',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(totalSaldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, size: 16, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dikelola oleh Bendahara Kelas (Alya Nabilah) untuk keperluan akademik & praktikum.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Tabs
            Row(
              children: ['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFilter = filter),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // List Transaksi
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F2F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Catatan Transaksi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Semua pemasukan kas kelas dan pengeluaran operasional akan dicatat secara transparan di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ...transactions.map((t) => _buildTransactionCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TreasuryTransaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.isPemasukan ? AppColors.successSoft : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.isPemasukan ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 20,
              color: t.isPemasukan ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.judul,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd MMM yyyy').format(t.tanggal)} • ${t.pencatat}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${t.isPemasukan ? "+" : "-"}${_formatRupiah(t.nominal)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.isPemasukan ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
