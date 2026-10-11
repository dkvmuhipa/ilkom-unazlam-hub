import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';

class TreasuryTransactionModal extends StatefulWidget {
  final TreasuryTransaction? transaction;
  final String? userName;
  final Function(TreasuryTransaction tx) onSaved;
  final Function(String id)? onDeleted;

  const TreasuryTransactionModal({
    super.key,
    this.transaction,
    this.userName,
    required this.onSaved,
    this.onDeleted,
  });

  static void show(
    BuildContext context, {
    TreasuryTransaction? transaction,
    String? userName,
    required Function(TreasuryTransaction tx) onSaved,
    Function(String id)? onDeleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TreasuryTransactionModal(
        transaction: transaction,
        userName: userName,
        onSaved: onSaved,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<TreasuryTransactionModal> createState() => _TreasuryTransactionModalState();
}

class _TreasuryTransactionModalState extends State<TreasuryTransactionModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late bool _isPemasukan;
  late String _kategori;
  bool _isSaving = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _titleController = TextEditingController(text: t?.judul ?? '');
    _amountController = TextEditingController(
      text: t != null ? t.nominal.toString() : '',
    );
    _isPemasukan = t?.isPemasukan ?? true;
    _kategori = t?.kategori ?? 'Iuran Kelas';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = int.tryParse(
          _amountController.text.replaceAll(RegExp(r'\D'), ''),
        ) ??
        0;
    if (_titleController.text.trim().isEmpty || amount <= 0) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    if (_isEditMode) {
      final existing = widget.transaction!;
      final updated = existing.copyWith(
        judul: _titleController.text.trim(),
        nominal: amount,
        isPemasukan: _isPemasukan,
        kategori: _kategori,
      );

      final success = await SupabaseRepository.updateTreasuryTransaction(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (!success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Transaksi gagal diperbarui.')),
        );
        return;
      }

      widget.onSaved(updated);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaksi kas berhasil diperbarui!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      final newTx = TreasuryTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        judul: _titleController.text.trim(),
        nominal: amount,
        isPemasukan: _isPemasukan,
        kategori: _kategori,
        tanggal: DateTime.now(),
        pencatat: widget.userName ?? 'Pengurus Kelas',
      );

      final saved = await SupabaseRepository.createTreasuryTransaction(newTx);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (!saved) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Transaksi gagal disimpan. Periksa koneksi dan izin bendahara.',
            ),
          ),
        );
        return;
      }

      widget.onSaved(newTx);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaksi kas berhasil dicatat!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _confirmDelete() {
    final t = widget.transaction;
    if (t == null || widget.onDeleted == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('Yakin ingin menghapus transaksi "${t.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final deleted = await SupabaseRepository.deleteTreasuryTransaction(t.id);
              if (!ctx.mounted) return;
              if (!deleted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Transaksi gagal dihapus.')),
                );
                return;
              }

              widget.onDeleted!(t.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Transaksi berhasil dihapus.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Edit Transaksi Kas Kelas' : 'Catat Transaksi Kas Kelas',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isPemasukan = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isPemasukan ? AppColors.successSoft : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isPemasukan ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: _isPemasukan ? AppColors.success : AppColors.textSub,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isPemasukan ? FontWeight.w700 : FontWeight.w500,
                            color: _isPemasukan ? AppColors.success : AppColors.textSub,
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
                  onTap: () => setState(() => _isPemasukan = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isPemasukan ? AppColors.errorSoft : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isPemasukan ? AppColors.error : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: !_isPemasukan ? AppColors.error : AppColors.textSub,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isPemasukan ? FontWeight.w700 : FontWeight.w500,
                            color: !_isPemasukan ? AppColors.error : AppColors.textSub,
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
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Misal: Iuran Kas Bulan Maret atau Beli Spidol',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Nominal (Rp)',
              hintText: 'Contoh: 150000',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kategori,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              'Iuran Kelas',
              'Operasional',
              'Perlengkapan',
              'Iuran Praktikum',
              'Sosial',
              'Lainnya',
            ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _kategori = val);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan Transaksi'),
          ),
          if (_isEditMode && widget.onDeleted != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                label: const Text(
                  'Hapus Transaksi',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
