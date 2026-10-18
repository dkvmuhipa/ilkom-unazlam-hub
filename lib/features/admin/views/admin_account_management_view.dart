import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_account_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../create_student_account_dialog.dart';
import '../edit_student_account_dialog.dart';
import '../widgets/admin_common_widgets.dart';

class AdminAccountManagementView extends StatefulWidget {
  final List<StudentProfile> managedAccounts;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onBack;
  final Future<void> Function() onReload;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  }) onRecordAudit;
  final Future<bool> Function(String prompt) onConfirmDelete;
  final void Function(StudentProfile? updatedStudent)? onSelectedStudentChanged;

  const AdminAccountManagementView({
    super.key,
    required this.managedAccounts,
    required this.isLoading,
    required this.loadError,
    required this.onBack,
    required this.onReload,
    required this.onShowMessage,
    required this.onRecordAudit,
    required this.onConfirmDelete,
    this.onSelectedStudentChanged,
  });

  @override
  State<AdminAccountManagementView> createState() => _AdminAccountManagementViewState();
}

class _AdminAccountManagementViewState extends State<AdminAccountManagementView> {
  String _accountFilter = 'Admin';
  String? _updatingAccountNim;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  Future<void> _showCreateStudentAccountDialog() async {
    final profile = await showGlassModal<StudentProfile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateStudentAccountDialog(),
    );
    if (profile == null || !mounted) return;

    widget.onRecordAudit(
      action: 'CREATE',
      module: 'AKUN',
      description: 'Membuat akun mahasiswa ${profile.nama} (${profile.nim}) dan mengirim undangan.',
      metadata: {'nim': profile.nim},
    );

    setState(() => _accountFilter = 'Mahasiswa');
    await widget.onReload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undangan akun dikirim ke ${profile.email}.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _editManagedAccount(StudentProfile account) async {
    final updated = await showGlassModal<StudentProfile>(
      context: context,
      builder: (_) => EditStudentAccountDialog(account: account),
    );
    if (updated == null || !mounted) return;

    setState(() => _updatingAccountNim = account.nim);
    try {
      await AdminAccountService.updateStudentAccount(updated);
      widget.onRecordAudit(
        action: 'UPDATE',
        module: 'AKUN',
        description: 'Memperbarui profil mahasiswa ${updated.nama} (${updated.nim}).',
        metadata: {'nim': updated.nim},
      );
      if (!mounted) return;
      widget.onSelectedStudentChanged?.call(updated);
      await widget.onReload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data akun berhasil diperbarui.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } on AdminAccountServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingAccountNim = null);
    }
  }

  Future<void> _setManagedAccountActive(StudentProfile account, bool isActive) async {
    if (account.isAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isActive ? 'Aktifkan akun kembali?' : 'Nonaktifkan akun?'),
        content: Text(
          isActive
              ? 'Akun ${account.nama} dapat masuk kembali setelah diaktifkan.'
              : 'Akun ${account.nama} tidak dapat masuk setelah dinonaktifkan. Profil dan riwayatnya tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: isActive
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final previousValue = account.isAktif;
    setState(() {
      _updatingAccountNim = account.nim;
      account.isAktif = isActive;
    });
    try {
      await AdminAccountService.setStudentActive(account.nim, isActive);
      widget.onRecordAudit(
        action: 'UPDATE',
        module: 'AKUN',
        description: '${isActive ? 'Mengaktifkan' : 'Menonaktifkan'} akun ${account.nama} (${account.nim}).',
        metadata: {'nim': account.nim, 'is_aktif': isActive},
      );
      if (!mounted) return;
      await widget.onReload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Akun diaktifkan.' : 'Akun dinonaktifkan.'),
          backgroundColor: isActive
              ? const Color(0xFF059669)
              : const Color(0xFF4B5563),
        ),
      );
    } on AdminAccountServiceException catch (error) {
      if (!mounted) return;
      setState(() => account.isAktif = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _updatingAccountNim = null);
    }
  }

  Future<void> _deleteStudentAccount(StudentProfile account) async {
    if (account.isAdmin) return;
    final confirmed = await widget.onConfirmDelete(
      'Hapus akun mahasiswa ${account.nama} (NIM: ${account.nim}) secara permanen? Data ini akan dihapus dari sistem.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _updatingAccountNim = account.nim);
    try {
      await AdminAccountService.deleteStudentAccount(account.nim);
      widget.onRecordAudit(
        action: 'DELETE',
        module: 'AKUN',
        description: 'Menghapus akun mahasiswa ${account.nama} (${account.nim}).',
        metadata: {'nim': account.nim, 'nama': account.nama},
      );
      if (!mounted) return;
      widget.onSelectedStudentChanged?.call(null);
      await widget.onReload();
      widget.onShowMessage('Akun ${account.nama} berhasil dihapus.');
    } catch (e) {
      widget.onShowMessage('Gagal menghapus akun: $e', isError: true);
    } finally {
      if (mounted) setState(() => _updatingAccountNim = null);
    }
  }

  Widget _buildManagedAccountTile(StudentProfile account) {
    final isAdmin = account.isAdmin;
    final accent = isAdmin ? AppColors.primary : const Color(0xFF0284C7);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.1),
            child: Text(
              _getInitials(account.nama),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.nama,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (account.email.trim().isNotEmpty && !account.email.contains('@student.unazlam.ac.id'))
                      ? account.email.trim()
                      : 'Email belum ditautkan (Login via NIM)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (account.email.trim().isNotEmpty && !account.email.contains('@student.unazlam.ac.id'))
                        ? FontWeight.w500
                        : FontWeight.w600,
                    color: (account.email.trim().isNotEmpty && !account.email.contains('@student.unazlam.ac.id'))
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD97706),
                  ),
                ),
                Text(
                  'NIM: ${account.nim} • ${account.jabatan}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          account.isAktif
              ? SoftPillBadge.success(label: 'Aktif', showDot: true)
              : SoftPillBadge.danger(label: 'Nonaktif', showDot: true),
          PopupMenuButton<String>(
            tooltip: 'Kelola akun',
            enabled: _updatingAccountNim != account.nim,
            onSelected: (action) {
              if (action == 'edit') {
                _editManagedAccount(account);
              } else if (action == 'delete') {
                _deleteStudentAccount(account);
              } else {
                _setManagedAccountActive(account, action == 'activate');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit data'),
                  ],
                ),
              ),
              if (!isAdmin) ...[
                PopupMenuItem(
                  value: account.isAktif ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        account.isAktif
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                        size: 18,
                        color: account.isAktif
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      SizedBox(width: 10),
                      Text(
                        account.isAktif ? 'Nonaktifkan akun' : 'Aktifkan akun',
                      ),
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
                      SizedBox(width: 10),
                      Text(
                        'Hapus akun',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admins = widget.managedAccounts.where((account) => account.isAdmin);
    final students = widget.managedAccounts.where((account) => !account.isAdmin);

    return Column(
      children: [
        AdminAppBar(
          title: 'Manajemen Akun',
          onBack: widget.onBack,
          showSearch: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateStudentAccountDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                  label: const Text('Buat akun mahasiswa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ['Semua', 'Admin', 'Mahasiswa'].map((f) {
                  final isSel = _accountFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _accountFilter = f),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (widget.isLoading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (widget.loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    widget.loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                )
              else ...[
                () {
                  final displayedAccounts = _accountFilter == 'Admin'
                      ? admins.toList()
                      : _accountFilter == 'Mahasiswa'
                          ? students.toList()
                          : widget.managedAccounts;

                  if (displayedAccounts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateWidget(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Tidak Ada Akun',
                        subtitle: _accountFilter == 'Admin'
                            ? 'Belum ada akun dengan hak akses admin.'
                            : _accountFilter == 'Mahasiswa'
                                ? 'Belum ada akun mahasiswa terdaftar.'
                                : 'Belum ada akun yang tersimpan di Supabase.',
                      ),
                    );
                  }

                  return Column(
                    children: displayedAccounts.map(_buildManagedAccountTile).toList(),
                  );
                }(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
