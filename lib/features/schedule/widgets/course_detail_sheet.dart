import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/safe_launcher.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import 'course_reschedule_modal.dart';
import 'lecturer_reminder_modal.dart';

class CourseDetailSheet extends StatefulWidget {
  final Course course;
  final bool canManage;
  final VoidCallback? onCourseUpdated;

  const CourseDetailSheet({
    super.key,
    required this.course,
    this.canManage = false,
    this.onCourseUpdated,
  });

  static void show(
    BuildContext context,
    Course c, {
    bool canManage = false,
    VoidCallback? onCourseUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourseDetailSheet(
        course: c,
        canManage: canManage,
        onCourseUpdated: onCourseUpdated,
      ),
    );
  }

  @override
  State<CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<CourseDetailSheet> {
  late Course _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  bool get _isOnline {
    final r = _course.ruangan.toLowerCase();
    final link = _course.linkVirtual ?? '';
    return link.isNotEmpty ||
        r.contains('zoom') ||
        r.contains('online') ||
        r.contains('meet') ||
        r.contains('virtual');
  }

  bool get _isHybrid => _course.ruangan.toLowerCase().contains('hybrid');

  void _openWhatsAppDosen() {
    LecturerReminderModal.show(
      context,
      course: _course,
      senderName: 'Ketua Kelas',
    );
  }

  void _copyScheduleInfo() {
    final info =
        'JADWAL KULIAH UNAZLAM 2026\n'
        '• Mata Kuliah : ${_course.nama} (${_course.kode})\n'
        '• Beban SKS   : ${_course.sks} SKS\n'
        '• Waktu       : ${_course.hari}, ${_course.jamMulai} - ${_course.jamSelesai} WITA\n'
        '• Ruangan     : ${_course.ruangan}\n'
        '• Dosen       : ${_course.dosen}\n'
        '${_course.linkVirtual != null && _course.linkVirtual!.isNotEmpty ? "• Link Virtual: ${_course.linkVirtual}\n" : ""}'
        'Tercatat di aplikasi UNAZLAM Class Manager.';

    Clipboard.setData(ClipboardData(text: info));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Info jadwal berhasil disalin ke clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditCourseDialog(Course c) {
    final nameCtrl = TextEditingController(text: c.nama);
    final codeCtrl = TextEditingController(text: c.kode);
    final sksCtrl = TextEditingController(text: c.sks.toString());
    final dosenCtrl = TextEditingController(text: c.dosen);
    final dosenWaCtrl = TextEditingController(text: c.dosenWa ?? '');
    final roomCtrl = TextEditingController(text: c.ruangan);
    final startCtrl = TextEditingController(text: c.jamMulai);
    final endCtrl = TextEditingController(text: c.jamSelesai);
    final linkCtrl = TextEditingController(text: c.linkVirtual ?? '');
    String selectedDay = c.hari;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Edit Mata Kuliah',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 96).clamp(0.0, 380.0).toDouble(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Mata Kuliah *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Kode MK',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: sksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'SKS',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: InputDecoration(
                      labelText: 'Hari Perkuliahan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      'Senin',
                      'Selasa',
                      'Rabu',
                      'Kamis',
                      'Jumat',
                      'Sabtu',
                      'Minggu',
                    ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedDay = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startCtrl,
                          decoration: InputDecoration(
                            labelText: 'Jam Mulai',
                            hintText: '08:00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endCtrl,
                          decoration: InputDecoration(
                            labelText: 'Jam Selesai',
                            hintText: '09:40',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Ruangan',
                      hintText: 'Contoh: Ruang A2 atau Zoom Online',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkCtrl,
                    decoration: InputDecoration(
                      labelText: 'Link Kuliah Online (Opsional)',
                      hintText: 'https://zoom.us/j/...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dosen Pengampu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenWaCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Dosen (Opsional)',
                      hintText: '08xxxxxxxxxx',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final updatedCourse = Course(
                  id: c.id,
                  kode: codeCtrl.text.trim().isEmpty ? 'MK ILKOM' : codeCtrl.text.trim(),
                  nama: name,
                  sks: int.tryParse(sksCtrl.text.trim()) ?? c.sks,
                  semester: c.semester,
                  dosen: dosenCtrl.text.trim().isEmpty
                      ? 'Dosen Pengampu'
                      : dosenCtrl.text.trim(),
                  dosenWa: dosenWaCtrl.text.trim().isEmpty
                      ? null
                      : dosenWaCtrl.text.trim(),
                  hari: selectedDay,
                  jamMulai: startCtrl.text.trim().isEmpty
                      ? '08:00'
                      : startCtrl.text.trim(),
                  jamSelesai: endCtrl.text.trim().isEmpty
                      ? '09:40'
                      : endCtrl.text.trim(),
                  ruangan: roomCtrl.text.trim().isEmpty
                      ? 'Ruang A2'
                      : roomCtrl.text.trim(),
                  linkVirtual: linkCtrl.text.trim().isEmpty
                      ? null
                      : linkCtrl.text.trim(),
                );
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _course = updatedCourse);
                Navigator.pop(ctx);
                await SupabaseRepository.updateCourse(updatedCourse);
                widget.onCourseUpdated?.call();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Jadwal mata kuliah berhasil diperbarui!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(Course c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Mata Kuliah?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${c.nama}" dari jadwal perkuliahan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx); // Close dialog
              await SupabaseRepository.deleteCourse(c.id);
              widget.onCourseUpdated?.call();
              if (mounted) {
                Navigator.pop(context); // Close bottom sheet
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Mata kuliah berhasil dihapus dari jadwal.'),
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
    final c = _course;
    final isOnlineClass = _isOnline;
    final isHybridClass = _isHybrid;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.kode.isNotEmpty ? c.kode : 'MK ILKOM',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${c.sks} SKS • Semester ${c.semester}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.canManage) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF1E40AF),
                          size: 20,
                        ),
                        tooltip: 'Edit Mata Kuliah',
                        onPressed: () => _showEditCourseDialog(c),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        tooltip: 'Hapus Mata Kuliah',
                        onPressed: () => _confirmDeleteCourse(c),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    c.nama,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Banner Penyesuaian Sesi Khusus (Jika ada Override Aktif)
                  if (c.hasActiveOverride) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.isCancelledToday
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.isCancelledToday
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                c.isCancelledToday
                                    ? Icons.cancel_rounded
                                    : Icons.warning_amber_rounded,
                                size: 18,
                                color: c.isCancelledToday
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'PERUBAHAN JADWAL: ${c.override!.statusBadgeLabel}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: c.isCancelledToday
                                        ? const Color(0xFF991B1B)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (c.override!.alasan != null &&
                              c.override!.alasan!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Pesan Dosen: ${c.override!.alasan}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: c.isCancelledToday
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Tombol Aksi Penyesuaian Jadwal (Khusus Pengurus / Admin)
                  if (widget.canManage) ...[
                    ScaleButton(
                      onTap: () {
                        CourseRescheduleModal.show(
                          context,
                          c,
                          onSaved: () {
                            widget.onCourseUpdated?.call();
                            Navigator.pop(context);
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_calendar_rounded,
                              size: 17,
                              color: Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                c.hasActiveOverride
                                    ? 'Ubah Penyesuaian (${c.override!.statusBadgeLabel})'
                                    : 'Sesuaikan Sesi Ini (Reschedule / Daring / Ruang)',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Schedule Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF1E40AF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Waktu Perkuliahan',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.isCancelledToday
                                        ? '${c.hari} • KELAS DITIADAKAN'
                                        : '${c.hari}, ${c.effectiveJamMulai} - ${c.effectiveJamSelesai} WITA',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: c.isCancelledToday
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (c.hasActiveOverride &&
                                      (c.jamMulai != c.effectiveJamMulai ||
                                          c.jamSelesai !=
                                              c.effectiveJamSelesai)) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Jadwal Normal: ${c.jamMulai} - ${c.jamSelesai} WITA (Digeser)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        decoration:
                                            TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOnlineClass || c.isOnlineOverride
                                    ? const Color(0xFFEFF6FF)
                                    : (isHybridClass
                                        ? const Color(0xFFF3E8FF)
                                        : const Color(0xFFECFDF5)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isOnlineClass || c.isOnlineOverride
                                    ? Icons.videocam_rounded
                                    : (isHybridClass
                                        ? Icons.sensors_rounded
                                        : Icons.meeting_room_outlined),
                                color: isOnlineClass || c.isOnlineOverride
                                    ? const Color(0xFF2563EB)
                                    : (isHybridClass
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF059669)),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnlineClass || c.isOnlineOverride
                                        ? 'Mode Perkuliahan Virtual'
                                        : (isHybridClass
                                            ? 'Mode Perkuliahan Hybrid'
                                            : 'Ruang Perkuliahan'),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOnlineClass || c.isOnlineOverride
                                        ? 'Tatap Maya via Zoom / GMeet'
                                        : '${c.effectiveRuangan.isNotEmpty ? c.effectiveRuangan : "Ruang A2"} • Gedung FISIP',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (c.hasActiveOverride &&
                                      c.ruangan != c.effectiveRuangan &&
                                      !c.isOnlineOverride) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ruang Normal: ${c.ruangan} (Pindah)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        decoration:
                                            TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (c.effectiveLinkVirtual != null &&
                            c.effectiveLinkVirtual!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ScaleButton(
                            onTap: () => safeLaunchUrl(c.effectiveLinkVirtual!),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_call_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Masuk Kuliah Online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Lecturer Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF16A34A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dosen Pengampu',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.dosen,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (c.dosen.trim().isNotEmpty)
                          ScaleButton(
                            onTap: _openWhatsAppDosen,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'WA Dosen',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
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

                  // Quick Action: Salin Info Jadwal
                  ScaleButton(
                    onTap: _copyScheduleInfo,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Color(0xFF334155),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Salin Rincian Jadwal Ini',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Action: Pengingat & Konfirmasi ke Dosen
                  ScaleButton(
                    onTap: _openWhatsAppDosen,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_chat_unread_rounded,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Pengingat / Konfirmasi ke Dosen',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pastikan hadir tepat waktu sebelum jam mulai perkuliahan dan aktifkan presensi kehadiran kelas pada jam aktif.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
