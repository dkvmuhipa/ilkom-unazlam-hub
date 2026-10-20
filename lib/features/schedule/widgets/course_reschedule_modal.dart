import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class CourseRescheduleModal extends StatefulWidget {
  final Course course;
  final VoidCallback? onSaved;

  const CourseRescheduleModal({
    super.key,
    required this.course,
    this.onSaved,
  });

  static void show(
    BuildContext context,
    Course course, {
    VoidCallback? onSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourseRescheduleModal(
        course: course,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CourseRescheduleModal> createState() => _CourseRescheduleModalState();
}

class _CourseRescheduleModalState extends State<CourseRescheduleModal> {
  late DateTime _selectedDate;
  late String _status; // 'RESCHEDULED', 'ONLINE', 'ROOM_CHANGE', 'CANCELLED'

  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _reasonCtrl;

  bool _broadcastNotification = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    final ov = c.override;

    _selectedDate = ov?.overrideDate ?? DateTime.now();
    _status = ov?.status ?? 'RESCHEDULED';

    _startCtrl = TextEditingController(text: ov?.newJamMulai ?? c.jamMulai);
    _endCtrl = TextEditingController(text: ov?.newJamSelesai ?? c.jamSelesai);
    _roomCtrl = TextEditingController(text: ov?.newRuangan ?? c.ruangan);
    _urlCtrl = TextEditingController(text: ov?.onlineMeetingUrl ?? c.linkVirtual ?? '');
    _reasonCtrl = TextEditingController(text: ov?.alasan ?? '');
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _roomCtrl.dispose();
    _urlCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final ctrl = isStart ? _startCtrl : _endCtrl;
    TimeOfDay initial = TimeOfDay.now();
    try {
      final parts = ctrl.text.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$hourStr:$minStr');
    }
  }

  Future<void> _handleSave() async {
    final c = widget.course;
    setState(() => _isSaving = true);

    try {
      final override = CourseScheduleOverride(
        id: c.override?.id ?? '',
        courseId: c.id,
        overrideDate: _selectedDate,
        status: _status,
        originalJamMulai: c.jamMulai,
        originalJamSelesai: c.jamSelesai,
        newJamMulai: _status == 'CANCELLED' ? null : _startCtrl.text.trim(),
        newJamSelesai: _status == 'CANCELLED' ? null : _endCtrl.text.trim(),
        newRuangan: _status == 'ONLINE'
            ? 'Daring (Zoom / GMeet)'
            : (_status == 'CANCELLED' ? '-' : _roomCtrl.text.trim()),
        onlineMeetingUrl: _status == 'ONLINE' ? _urlCtrl.text.trim() : null,
        alasan: _reasonCtrl.text.trim(),
        reportedByNim: 'Pengurus Kelas',
      );

      final success = await SupabaseRepository.saveCourseOverride(override);

      if (success) {
        // Jika broadcast dicentang, buatkan pengumuman resmi terpin otomatis
        if (_broadcastNotification) {
          final formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID').format(_selectedDate);
          String statusDescription;
          switch (_status) {
            case 'ONLINE':
              statusDescription =
                  'Dialihkan menjadi perkuliahan DARING (Online) jam ${_startCtrl.text} - ${_endCtrl.text} WITA.'
                  '${_urlCtrl.text.isNotEmpty ? "\nTautan Kuliah: ${_urlCtrl.text}" : ""}';
              break;
            case 'ROOM_CHANGE':
              statusDescription =
                  'Pindah ruangan ke: ${_roomCtrl.text.trim()} (Jam: ${_startCtrl.text} - ${_endCtrl.text} WITA).';
              break;
            case 'CANCELLED':
              statusDescription = 'Perkuliahan sesi hari ini DITIADAKAN / DILIBURKAN.';
              break;
            case 'RESCHEDULED':
            default:
              statusDescription =
                  'Jam masuk perkuliahan digeser menjadi ${_startCtrl.text} - ${_endCtrl.text} WITA (Ruang: ${_roomCtrl.text.trim()}).';
              break;
          }

          final fullNote = _reasonCtrl.text.trim().isNotEmpty
              ? '\nCatatan dari Dosen: ${_reasonCtrl.text.trim()}'
              : '';

          await SupabaseRepository.createAnnouncement(
            judul: '🚨 Perubahan Jadwal: ${c.nama}',
            isi: 'Pemberitahuan perkuliahan ${c.nama} untuk $formattedDate:\n'
                '$statusDescription$fullNote\n\n'
                'Info ini telah diperbarui secara otomatis pada jadwal kelas.',
            kategori: 'Jadwal Kuliah',
            isPinned: true,
          );
        }

        if (mounted) {
          Navigator.pop(context); // Tutup modal reschedule
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perubahan sesi "${c.nama}" berhasil disimpan & dibroadcast!',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          widget.onSaved?.call();
        }
      } else {
        throw Exception('Gagal menyimpan ke server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteOverride() async {
    final c = widget.course;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Penyesuaian?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Jadwal sesi "${c.nama}" akan dikembalikan ke jam & ruangan normal semula.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Kembalikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final success = await SupabaseRepository.deleteCourseOverride(c.id, _selectedDate);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penyesuaian jadwal dibatalkan. Kembali ke jadwal normal.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onSaved?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final hasOverride = c.hasActiveOverride;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFF6D28D9),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sesuaikan Jadwal Sesi Kuliah',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${c.nama} (${c.kode})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Jadwal Master Normal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jadwal Normal: ${c.hari}, ${c.jamMulai} - ${c.jamSelesai} WITA (${c.ruangan})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Tanggal Sesi
                  const Text(
                    'Tanggal Pertemuan Kuliah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ScaleButton(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Ubah Tanggal',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Kategori Perubahan
                  const Text(
                    'Jenis Penyesuaian Jadwal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip('RESCHEDULED', '⏰ Jam Berubah', const Color(0xFF6D28D9)),
                      _buildStatusChip('ONLINE', '💻 Kuliah Daring', const Color(0xFF10B981)),
                      _buildStatusChip('ROOM_CHANGE', '📍 Pindah Ruang', const Color(0xFFF59E0B)),
                      _buildStatusChip('CANCELLED', '🚫 Ditiadakan', const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Form Input Kondisional
                  if (_status != 'CANCELLED') ...[
                    // Jam Mulai & Selesai
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jam Masuk Baru',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _pickTime(isStart: true),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _startCtrl.text,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jam Selesai Baru',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _pickTime(isStart: false),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _endCtrl.text,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ruangan (jika bukan online)
                    if (_status != 'ONLINE') ...[
                      const Text(
                        'Ruangan Kelas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _roomCtrl,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Ruang B1 atau Gedung Lab FISIP',
                          prefixIcon: const Icon(Icons.room_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tautan Online (jika online)
                    if (_status == 'ONLINE') ...[
                      const Text(
                        'Tautan Kuliah Virtual (Zoom / Google Meet)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _urlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'https://meet.google.com/... atau Zoom link',
                          prefixIcon: const Icon(Icons.videocam_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],

                  // 4. Catatan / Alasan Dosen
                  const Text(
                    'Keterangan / Alasan dari Dosen',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Dosen ada agenda dinas, kelas diundur 1 jam.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Broadcast Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirim Push Notifikasi Darurat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Buat pengumuman pinned & beri tahu seluruh mahasiswa',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _broadcastNotification,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _broadcastNotification = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Action Buttons
                  Row(
                    children: [
                      if (hasOverride) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _handleDeleteOverride,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Kembalikan Normal',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Simpan & Terapkan Perubahan',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label, Color accentColor) {
    final isSelected = _status == statusKey;
    return InkWell(
      onTap: () => setState(() => _status = statusKey),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
