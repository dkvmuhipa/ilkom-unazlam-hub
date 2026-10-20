import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/admin_audit_service.dart';
import '../../core/widgets/empty_state_widget.dart';

class AuditLogItem {
  final String id;
  final String actor;
  final String role;
  final String action;
  final String details;
  final DateTime timestamp;
  final String module;
  final Map<String, dynamic> metadata;

  const AuditLogItem({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.module,
    this.metadata = const {},
  });

  factory AuditLogItem.fromMap(Map<String, dynamic> map) {
    final rawModule = (map['target_module']?.toString() ?? 'SISTEM').toUpperCase();
    final actionType = (map['action_type']?.toString() ?? 'ACTIVITY').toUpperCase();
    final rawActor = map['user_name']?.toString() ?? '';
    final rawIdentifier = map['user_identifier']?.toString() ?? '';
    final createdAtStr = map['created_at']?.toString() ?? '';

    // Format nama aktor dan peran
    String actorName = rawActor.isNotEmpty ? rawActor : rawIdentifier;
    if (actorName.isEmpty) actorName = 'Sistem';

    String roleLabel = 'Pengguna';
    if (actorName.toLowerCase().contains('admin') || rawIdentifier.toLowerCase() == 'admin' || rawIdentifier == '16110376') {
      roleLabel = 'Administrator';
    } else if (rawActor.toLowerCase().contains('farida')) {
      roleLabel = 'Ketua Kelas';
    } else if (rawActor.toLowerCase().contains('alya')) {
      roleLabel = 'Bendahara';
    } else if (rawActor.toLowerCase().contains('stefani')) {
      roleLabel = 'Sekretaris';
    }

    // Format nama modul ramah
    String friendlyModule = 'Lainnya';
    if (rawModule.contains('PENGUMUMAN')) {
      friendlyModule = 'Pengumuman';
    } else if (rawModule.contains('AKUN')) {
      friendlyModule = 'Akun';
    } else if (rawModule.contains('TUGAS') || rawModule.contains('ASSIGNMENT')) {
      friendlyModule = 'Tugas';
    } else if (rawModule.contains('PRESENSI') || rawModule.contains('ATTENDANCE')) {
      friendlyModule = 'Presensi';
    } else if (rawModule.contains('KAS') || rawModule.contains('TREASURY')) {
      friendlyModule = 'Kas';
    } else if (rawModule.contains('MATA_KULIAH') || rawModule.contains('COURSE') || rawModule.contains('JADWAL')) {
      friendlyModule = 'Mata Kuliah';
    } else if (rawModule.contains('NILAI') || rawModule.contains('GRADE')) {
      friendlyModule = 'Nilai';
    } else if (rawModule.contains('SURAT') || rawModule.contains('IZIN')) {
      friendlyModule = 'Surat Izin';
    } else {
      friendlyModule = rawModule.replaceAll('_', ' ');
    }

    // Format judul aksi ramah
    String friendlyAction = 'Aktivitas $friendlyModule';
    if (actionType == 'CREATE') {
      friendlyAction = 'Penerbitan / Pembuatan Baru';
    } else if (actionType == 'UPDATE') {
      friendlyAction = 'Pembaruan Data';
    } else if (actionType == 'DELETE') {
      friendlyAction = 'Penghapusan Data';
    } else if (actionType == 'PUBLISH') {
      friendlyAction = 'Publikasi Resmi';
    } else if (actionType == 'INIT') {
      friendlyAction = 'Inisialisasi Sistem';
    } else if (actionType == 'EXPORT') {
      friendlyAction = 'Ekspor Laporan';
    }

    DateTime parsedDate = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    return AuditLogItem(
      id: map['id']?.toString() ?? '',
      actor: actorName,
      role: roleLabel,
      action: friendlyAction,
      details: map['description']?.toString() ?? 'Tidak ada rincian keterangan.',
      timestamp: parsedDate,
      module: friendlyModule,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }
}

class AuditLogScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AuditLogScreen({super.key, this.onBack});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedModule = 'Semua';
  String _searchQuery = '';
  late Future<List<AuditLogItem>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchRealAuditLogs();
  }

  Future<List<AuditLogItem>> _fetchRealAuditLogs() async {
    final rawLogs = await AdminAuditService.list(limit: 250);
    return rawLogs.map(AuditLogItem.fromMap).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _logsFuture = _fetchRealAuditLogs();
    });
  }

  Color _getModuleColor(String mod) {
    switch (mod) {
      case 'Kas':
        return const Color(0xFF10B981);
      case 'Presensi':
        return const Color(0xFF0284C7);
      case 'Pengumuman':
        return const Color(0xFFF59E0B);
      case 'Tugas':
        return const Color(0xFF8B5CF6);
      case 'Akun':
        return const Color(0xFFEC4899);
      case 'Mata Kuliah':
        return const Color(0xFF6366F1);
      case 'Nilai':
        return const Color(0xFF14B8A6);
      case 'Surat Izin':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF4B5563);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  void _showLogDetail(AuditLogItem log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getModuleColor(log.module).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.module.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _getModuleColor(log.module),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(log.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              log.action,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              log.details,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Text(
                  'Dilakukan oleh: ',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                Text(
                  '${log.actor} (${log.role})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
            if (log.id.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  const Text('ID Log: ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  Expanded(
                    child: Text(
                      log.id,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (log.metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Data Metadata Tambahan:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  log.metadata.toString(),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF374151)),
                ),
              ),
            ],
          ],
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
        title: Text(
          'Audit Log Aktivitas Kelas',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4B5563)),
            tooltip: 'Segarkan Log',
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<AuditLogItem>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Memuat log aktivitas real-time...', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat log aktivitas',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allLogs = snapshot.data ?? [];

          // Hitung daftar modul unik dari data real
          final availableModules = <String>{'Semua'};
          for (final log in allLogs) {
            availableModules.add(log.module);
          }

          final filtered = allLogs.where((l) {
            final matchesModule = _selectedModule == 'Semua' || l.module == _selectedModule;
            final query = _searchQuery.trim().toLowerCase();
            final matchesSearch = query.isEmpty ||
                l.actor.toLowerCase().contains(query) ||
                l.details.toLowerCase().contains(query) ||
                l.action.toLowerCase().contains(query) ||
                l.module.toLowerCase().contains(query);
            return matchesModule && matchesSearch;
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // Search Bar Box
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Cari aktivitas, admin, atau modul...',
                        hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),

                // Filter Chips Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableModules.map((m) {
                        final isSel = _selectedModule == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedModule = m),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF6D28D9) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Log List View
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            EmptyStateWidget(
                              icon: Icons.history_rounded,
                              title: 'Belum Ada Log Aktivitas',
                              subtitle: 'Aktivitas akademik dan administrasi kelas akan tercatat di sini secara real-time.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final log = filtered[i];
                            final modColor = _getModuleColor(log.module);

                            return InkWell(
                              onTap: () => _showLogDetail(log),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: modColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        log.module,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: modColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  log.action,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatTimestamp(log.timestamp),
                                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            log.details,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Oleh: ${log.actor} (${log.role})',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
