import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/admin_common_widgets.dart';

class AdminAuditLogView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>>? auditFuture;
  final VoidCallback onRefresh;
  final VoidCallback onBack;

  const AdminAuditLogView({
    super.key,
    required this.auditFuture,
    required this.onRefresh,
    required this.onBack,
  });

  @override
  State<AdminAuditLogView> createState() => _AdminAuditLogViewState();
}

class _AdminAuditLogViewState extends State<AdminAuditLogView> {
  String _actionFilter = 'Semua';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final actions = ['Semua', 'CREATE', 'UPDATE', 'DELETE', 'EXPORT'];
    return Column(children: [
      AdminAppBar(
        title: 'Log Aktivitas Admin',
        showSearch: false,
        onSearch: widget.onRefresh,
        onBack: widget.onBack,
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.auditFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 10),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final rows = snapshot.data ?? [];
            final filtered = rows.where((row) {
              final action = row['action_type']?.toString().toUpperCase() ?? '';
              final matchesAction = _actionFilter == 'Semua' || action == _actionFilter;
              final query = _searchQuery.trim().toLowerCase();
              final text = '${row['user_name'] ?? ''} ${row['user_identifier'] ?? ''} ${row['target_module'] ?? ''} ${row['description'] ?? ''}'.toLowerCase();
              return matchesAction && (query.isEmpty || text.contains(query));
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              children: [
                AdminSearchBox(
                  hintText: 'Cari admin, modul, atau aktivitas...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: actions.map((action) {
                      final selected = _actionFilter == action;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(action),
                          selected: selected,
                          onSelected: (_) => setState(() => _actionFilter = action),
                          selectedColor: const Color(0xFFEDE9FE),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 44),
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 10),
                        Text(
                          rows.isEmpty ? 'Belum ada aktivitas tercatat.' : 'Tidak ada aktivitas yang cocok dengan pencarian.',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(_buildAuditLogTile),
                if (rows.length >= 200)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Menampilkan 200 aktivitas terbaru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildAuditLogTile(Map<String, dynamic> row) {
    final action = row['action_type']?.toString().toUpperCase() ?? 'UPDATE';
    final color = switch (action) {
      'CREATE' => const Color(0xFF059669),
      'DELETE' => const Color(0xFFDC2626),
      'EXPORT' => const Color(0xFF0284C7),
      _ => const Color(0xFF7C3AED),
    };
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    final dateLabel = createdAt == null ? 'Waktu tidak tersedia' : _formatAuditDate(createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            switch (action) {
              'CREATE' => Icons.add_rounded,
              'DELETE' => Icons.delete_outline_rounded,
              'EXPORT' => Icons.download_rounded,
              _ => Icons.edit_outlined
            },
            color: color,
            size: 19,
          ),
        ),
        title: Text(
          row['description']?.toString() ?? 'Aktivitas admin',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${row['user_name'] ?? 'Admin'} • ${row['user_identifier'] ?? '-'}\n${row['target_module'] ?? 'LAINNYA'} • $dateLabel',
            style: const TextStyle(height: 1.45, fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            action,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ),
        onTap: () => _showAuditDetails(row),
      ),
    );
  }

  String _formatAuditDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  void _showAuditDetails(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Aktivitas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(row['description']?.toString() ?? '-'),
              const SizedBox(height: 12),
              Text('Admin: ${row['user_name'] ?? '-'} (${row['user_identifier'] ?? '-'})'),
              Text('Modul: ${row['target_module'] ?? '-'}'),
              Text('Tindakan: ${row['action_type'] ?? '-'}'),
              if (metadata != null) ...[
                const SizedBox(height: 12),
                const Text('Metadata', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(metadata),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
