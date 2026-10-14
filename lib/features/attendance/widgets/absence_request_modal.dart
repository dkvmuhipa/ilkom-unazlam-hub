import 'package:flutter/material.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../attendance_screen.dart';

class AbsenceRequestModal {
  static ActiveAttendanceSession? get currentSession => AttendanceScreen.currentSession;
  static set currentSession(ActiveAttendanceSession? s) => AttendanceScreen.currentSession = s;

  static void show(
    BuildContext context, {
    required String userNim,
    List<Course> courses = const [],
    String? preselectedCourse,
    int? preselectedPertemuan,
    VoidCallback? onSuccess,
  }) {
    final reasonController = TextEditingController();
    final liveSession = currentSession;
    String selectedCourse = preselectedCourse ??
        ((liveSession != null && !liveSession.isExpired)
            ? liveSession.courseName
            : (courses.isNotEmpty ? courses.first.nama : 'Mata Kuliah'));
    int selectedPertemuan = preselectedPertemuan ??
        ((liveSession != null && !liveSession.isExpired) ? liveSession.pertemuanKe : 1);
    String selectedStatus = 'Izin'; // 'Izin' or 'Sakit'
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: selectedStatus == 'Izin' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selectedStatus == 'Izin' ? Icons.assignment_late_rounded : Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengajuan Izin / Sakit Kuliah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Laporkan ketidakhadiran resmi ke sistem akademik kelas',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Selector (Izin vs Sakit)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = 'Izin'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedStatus == 'Izin'
                                ? (isDark ? const Color(0xFF713F12) : const Color(0xFFFEF3C7))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == 'Izin' ? const Color(0xFFF59E0B) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.watch_later_outlined,
                                size: 16,
                                color: selectedStatus == 'Izin' ? const Color(0xFFD97706) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Izin',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedStatus == 'Izin' ? const Color(0xFFD97706) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = 'Sakit'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedStatus == 'Sakit'
                                ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == 'Sakit' ? const Color(0xFF3B82F6) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.healing_rounded,
                                size: 16,
                                color: selectedStatus == 'Sakit' ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sakit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedStatus == 'Sakit' ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
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

                // Row: Mata Kuliah & Pertemuan
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCourse,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Mata Kuliah',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: courses.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: selectedCourse,
                                  child: Text(selectedCourse, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ]
                            : courses.map((c) => DropdownMenuItem(
                                value: c.nama,
                                child: Text(c.nama, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCourse = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedPertemuan,
                        decoration: InputDecoration(
                          labelText: 'Pertemuan',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: List.generate(16, (i) => i + 1).map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('Ke-$p', style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPertemuan = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Alasan Textfield
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alasan / Keterangan Lengkap',
                    hintText: selectedStatus == 'Izin'
                        ? 'Contoh: Menghadiri kegiatan dinas kampus / keperluan keluarga mendesak...'
                        : 'Contoh: Mengalami demam dan disarankan istirahat oleh dokter...',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintStyle: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Notice Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data izin/sakit akan tercatat resmi dalam sistem rekapitulasi kehadiran dan dapat diverifikasi oleh Ketua Kelas atau Dosen.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harap tuliskan alasan ketidakhadiran Anda!'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            await SupabaseRepository.logAttendance(
                              courseId: selectedCourse,
                              studentNim: userNim,
                              pertemuanKe: selectedPertemuan,
                              status: selectedStatus,
                              catatan: reason,
                            );

                            final current = currentSession;
                            if (current != null && current.courseName == selectedCourse && current.pertemuanKe == selectedPertemuan) {
                              current.attendedNims.add(userNim);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            onSuccess?.call();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Pengajuan $selectedStatus untuk "$selectedCourse" berhasil dicatat! 📄'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: selectedStatus == 'Izin' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengirim pengajuan: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan $selectedStatus',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStatus == 'Izin' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      reasonController.dispose();
    });
  }
}
