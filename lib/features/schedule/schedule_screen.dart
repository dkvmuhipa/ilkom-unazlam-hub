import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/course_schedule_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/scale_button.dart';
import '../../models/models.dart';
import 'widgets/course_detail_sheet.dart';
import 'widgets/course_timeline_card.dart';
import 'widgets/schedule_day_selector.dart';
import 'widgets/schedule_hero_spotlight.dart';

class ScheduleScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  final StudentProfile? student;

  const ScheduleScreen({
    super.key,
    this.canManage = true,
    this.onBack,
    this.student,
  });

  static void showCourseDetail(
    BuildContext context,
    Course c, {
    bool canManage = false,
    VoidCallback? onCourseUpdated,
  }) {
    CourseDetailSheet.show(
      context,
      c,
      canManage: canManage,
      onCourseUpdated: onCourseUpdated,
    );
  }

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDay = 'Senin';
  final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Semua',
  ];
  List<Course> _courses = [];
  String _selectedReligionFilter = 'Sesuai Agama';
  bool _isLoading = false;
  String? _loadError;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  RealtimeChannel? _coursesChannel;
  RealtimeChannel? _overridesChannel;

  @override
  void initState() {
    super.initState();
    _autoSelectActiveDay(_courses);
    _fetchCourses();
    _initRealtime();
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_coursesChannel);
    SupabaseRepository.unsubscribeChannel(_overridesChannel);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initRealtime() {
    _coursesChannel = SupabaseRepository.subscribeToCourses(() {
      if (mounted) {
        _fetchCourses(silent: true);
      }
    });
    _overridesChannel = SupabaseRepository.subscribeToCourseOverrides(() {
      if (mounted) {
        _fetchCourses(silent: true);
      }
    });
  }

  void _autoSelectActiveDay(List<Course> list) {
    if (list.isEmpty) return;
    final now = DateTime.now();
    final today = CourseScheduleService.getDayName(now);
    final todayHasCourses = list.any(
      (c) => c.hari.trim().toLowerCase() == today.toLowerCase(),
    );
    if (todayHasCourses) {
      _selectedDay = today;
    } else {
      final nextInfo = CourseScheduleService.getNextActiveDayInfo(list, now);
      if (nextInfo != null) {
        _selectedDay = nextInfo.dayName;
      } else {
        _selectedDay = 'Senin';
      }
    }
  }

  Future<void> _fetchCourses({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final loaded = await SupabaseRepository.getCoursesWithOverridesStrict();
      final dayOrder = {
        'Senin': 1,
        'Selasa': 2,
        'Rabu': 3,
        'Kamis': 4,
        'Jumat': 5,
        'Sabtu': 6,
        'Minggu': 7,
      };
      loaded.sort((a, b) {
        final da = dayOrder[a.hari] ?? 99;
        final db = dayOrder[b.hari] ?? 99;
        if (da != db) return da.compareTo(db);
        return a.effectiveJamMulai.compareTo(b.effectiveJamMulai);
      });
      if (!mounted) return;
      setState(() {
        _courses = loaded;
        _loadError = null;
        if (_courses.isNotEmpty && _selectedDay == 'Senin') {
          _autoSelectActiveDay(loaded);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _loadError =
              'Jadwal gagal diperbarui. Data terakhir tetap ditampilkan.',
        );
      }
      debugPrint('Error fetching courses from Supabase: $e');
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _showAddCourseDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final sksCtrl = TextEditingController(text: '2');
    final dosenCtrl = TextEditingController();
    final dosenWaCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: 'Ruang A2');
    final linkCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '09:40');
    String selectedDay = _selectedDay == 'Semua' ? 'Senin' : _selectedDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Tambah Jadwal Kuliah',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 96)
                  .clamp(0.0, 380.0)
                  .toDouble(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Mata Kuliah *',
                      hintText: 'Contoh: Teori Komunikasi',
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
                            hintText: 'ILKOM-101',
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
                    items:
                        [
                              'Senin',
                              'Selasa',
                              'Rabu',
                              'Kamis',
                              'Jumat',
                              'Sabtu',
                              'Minggu',
                            ]
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
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
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final newCourse = Course(
                  id: 'course_${DateTime.now().millisecondsSinceEpoch}',
                  kode: codeCtrl.text.trim().isEmpty
                      ? 'MK ILKOM'
                      : codeCtrl.text.trim(),
                  nama: name,
                  sks: int.tryParse(sksCtrl.text.trim()) ?? 2,
                  semester: 1,
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
                setState(() {
                  _courses.add(newCourse);
                  _selectedDay = selectedDay;
                });
                Navigator.pop(ctx);
                await SupabaseRepository.createCourse(newCourse);
                await _fetchCourses(silent: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mata kuliah berhasil ditambahkan ke jadwal!',
                      ),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
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

  void _showCourseDetailModal(Course c) {
    CourseDetailSheet.show(
      context,
      c,
      canManage: widget.canManage,
      onCourseUpdated: () => _fetchCourses(silent: true),
    );
  }

  void _showExportOptionsSheet() {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data jadwal untuk diekspor.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  color: Color(0xFF6D28D9),
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Ekspor & Bagikan Jadwal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sinkronkan jadwal semester ini ke kalender HP atau bagikan teks jadwal ke grup WhatsApp.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Option 1: Calendar (.ics)
            _buildExportOptionTile(
              icon: Icons.edit_calendar_rounded,
              color: const Color(0xFF6D28D9),
              title: 'Ekspor ke Kalender Ponsel (.ics)',
              subtitle: 'Google Calendar, Apple Calendar, Outlook (Otomatis mingguan)',
              onTap: () async {
                Navigator.pop(ctx);
                final ics = ExportService.exportScheduleIcs(courses: _courses);
                final exportResult = await ExportService.exportFile(
                  'Jadwal_Kuliah_ILKOM_UNAZLAM.ics',
                  ics,
                );
                if (exportResult == FileExportResult.dismissed) return;
                if (exportResult == FileExportResult.unavailable) {
                  await Clipboard.setData(ClipboardData(text: ics));
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(switch (exportResult) {
                      FileExportResult.downloaded => 'File kalender (.ics) berhasil diunduh. Buka untuk menyinkronkan ke kalender.',
                      FileExportResult.shared =>
                        'Pilih aplikasi kalender untuk membuka file .ics.',
                      FileExportResult.dismissed => '',
                      FileExportResult.unavailable => 'Ekspor file tidak tersedia. Data kalender disalin ke clipboard.',
                    }),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Option 2: Excel / Spreadsheet (.csv)
            _buildExportOptionTile(
              icon: Icons.table_view_rounded,
              color: const Color(0xFF059669),
              title: 'Unduh Format Spreadsheet (.csv)',
              subtitle: 'Kompatibel dengan Microsoft Excel dan Google Sheets',
              onTap: () {
                Navigator.pop(ctx);
                final csv = ExportService.exportScheduleCsv(courses: _courses);
                ExportService.showExportSheet(
                  context,
                  title: 'Ekspor Jadwal Kuliah',
                  fileName: 'Jadwal_Kuliah_ILKOM.csv',
                  content: csv,
                  subtitle:
                      'Format CSV tabel rapi perkuliahan semester berjalan',
                );
              },
            ),
            const SizedBox(height: 10),

            // Option 3: WhatsApp Text Format
            _buildExportOptionTile(
              icon: Icons.chat_rounded,
              color: const Color(0xFF16A34A),
              title: 'Salin Teks Format WhatsApp',
              subtitle: 'Teks rapi berformat tebal & jam untuk disebarkan di grup kelas',
              onTap: () {
                Navigator.pop(ctx);
                final waText = ExportService.exportScheduleWhatsappText(
                  courses: _courses,
                );
                Clipboard.setData(ClipboardData(text: waText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Jadwal berhasil disalin ke clipboard! Siap dipaste ke grup WhatsApp.',
                    ),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 220,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 160,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: Container(
                  height: 38,
                  margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            3,
            (index) => Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
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

  void _showReligionFilterSheet(String studentAgama) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final options = [
          {
            'key': 'Sesuai Agama',
            'label': 'Sesuai Agama ($studentAgama)',
            'desc': 'Menampilkan mata kuliah agama sesuai profil Anda (Rekomendasi)',
            'icon': Icons.verified_user_rounded,
          },
          {
            'key': 'Semua Agama',
            'label': 'Semua Agama',
            'desc': 'Menampilkan seluruh opsi mata kuliah agama paralel',
            'icon': Icons.public_rounded,
          },
          {
            'key': 'Islam',
            'label': 'Pendidikan Agama Islam',
            'desc': 'Kode: 3 PK 101A • Ruang A1',
            'icon': Icons.mosque_rounded,
          },
          {
            'key': 'Kristen',
            'label': 'Pendidikan Agama Kristen',
            'desc': 'Kode: 3 PK 101B • Ruang B1',
            'icon': Icons.church_rounded,
          },
          {
            'key': 'Katolik',
            'label': 'Pendidikan Agama Katolik',
            'desc': 'Mata kuliah Pendidikan Agama Katolik',
            'icon': Icons.church_rounded,
          },
          {
            'key': 'Hindu',
            'label': 'Pendidikan Agama Hindu',
            'desc': 'Mata kuliah Pendidikan Agama Hindu',
            'icon': Icons.temple_hindu_rounded,
          },
          {
            'key': 'Buddha',
            'label': 'Pendidikan Agama Buddha',
            'desc': 'Mata kuliah Pendidikan Agama Buddha',
            'icon': Icons.temple_buddhist_rounded,
          },
          {
            'key': 'Konghucu',
            'label': 'Pendidikan Agama Konghucu',
            'desc': 'Mata kuliah Pendidikan Agama Konghucu',
            'icon': Icons.account_balance_rounded,
          },
        ];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF6D28D9), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Mata Kuliah Agama',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Pilih tampilan mata kuliah agama pada jadwal',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final key = opt['key'] as String;
                final label = opt['label'] as String;
                final desc = opt['desc'] as String;
                final icon = opt['icon'] as IconData;
                final isSelected = _selectedReligionFilter == key;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedReligionFilter = key);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6D28D9).withValues(alpha: 0.08)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 1.5),
                                Text(
                                  desc,
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Color(0xFF6D28D9),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReligionFilterPill(String studentAgama) {
    final String activeLabel = _selectedReligionFilter == 'Sesuai Agama'
        ? 'Sesuai Agama ($studentAgama)'
        : (_selectedReligionFilter == 'Semua Agama'
            ? 'Semua Pilihan Agama'
            : 'Agama: $_selectedReligionFilter');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 13,
              color: Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MATA KULIAH AGAMA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  activeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D28D9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ScaleButton(
            onTap: () => _showReligionFilterSheet(studentAgama),
            scaleDown: 0.94,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 12, color: Color(0xFF475569)),
                  SizedBox(width: 4),
                  Text(
                    'Ubah',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentAgama = widget.student?.effectiveAgama ?? 'Islam';
    final hasReligionCourses = _courses.any(CourseScheduleService.isReligionCourse);

    List<Course> religionFilteredCourses = _courses;
    if (_selectedReligionFilter == 'Sesuai Agama') {
      religionFilteredCourses = CourseScheduleService.filterCoursesByReligion(
        _courses,
        studentAgama,
      );
    } else if (_selectedReligionFilter != 'Semua Agama') {
      religionFilteredCourses = CourseScheduleService.filterCoursesByReligion(
        _courses,
        _selectedReligionFilter,
      );
    }

    var filteredCourses = _selectedDay == 'Semua'
        ? religionFilteredCourses
        : religionFilteredCourses
              .where(
                (c) =>
                    c.hari.trim().toLowerCase() ==
                    _selectedDay.trim().toLowerCase(),
              )
              .toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredCourses = filteredCourses.where((c) {
        return c.nama.toLowerCase().contains(q) ||
            c.kode.toLowerCase().contains(q) ||
            c.dosen.toLowerCase().contains(q) ||
            c.ruangan.toLowerCase().contains(q) ||
            c.hari.toLowerCase().contains(q);
      }).toList();
    }

    final totalSks = filteredCourses.fold<int>(0, (sum, c) => sum + c.sks);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.canManage
          ? ScaleButton(
              onTap: _showAddCourseDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58138A), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Tambah Jadwal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                ),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari matkul, dosen, ruangan...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6D28D9),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Jadwal Kuliah & Ruang'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              tooltip: 'Tutup Pencarian',
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              tooltip: 'Cari Jadwal',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(
                Icons.ios_share_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              tooltip: 'Ekspor & Bagikan Jadwal',
              onPressed: _showExportOptionsSheet,
            ),
            IconButton(
              icon: const Icon(
                Icons.sync_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              tooltip: 'Sinkronisasi Jadwal',
              onPressed: () => _fetchCourses(),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildScheduleSkeleton()
          : RefreshIndicator(
              onRefresh: () => _fetchCourses(silent: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadError != null)
                      MaterialBanner(
                        content: Text(_loadError!),
                        actions: [
                          TextButton(
                            onPressed: () => _fetchCourses(),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    // Spotlight Hero Card (Ongoing Live / Upcoming Countdown)
                    if (_courses.isNotEmpty && _searchQuery.isEmpty) ...[
                      ScheduleHeroSpotlight(
                        allCourses: religionFilteredCourses,
                        onCourseTap: _showCourseDetailModal,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Horizontal Day Selector
                    ScheduleDaySelector(
                      selectedDay: _selectedDay,
                      days: _days,
                      allCourses: religionFilteredCourses,
                      onDaySelected: (day) =>
                          setState(() => _selectedDay = day),
                    ),
                    const SizedBox(height: 14),

                    // Filter Agama Pill (jika terdapat mata kuliah agama)
                    if (hasReligionCourses && _searchQuery.isEmpty) ...[
                      _buildReligionFilterPill(studentAgama),
                      const SizedBox(height: 12),
                    ],

                    // Day Summary Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 15,
                            color: Color(0xFF6D28D9),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Hasil pencarian: ${filteredCourses.length} mata kuliah'
                                  : (_selectedDay == 'Semua'
                                        ? 'Total ${filteredCourses.length} mata kuliah terdaftar ($totalSks SKS)'
                                        : '$_selectedDay • ${filteredCourses.length} mata kuliah ($totalSks SKS)'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Semester 1',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Timeline Course List
                    if (filteredCourses.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5F3FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                size: 36,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak Ditemukan Jadwal'
                                  : 'Tidak Ada Kuliah di Hari $_selectedDay',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada mata kuliah yang cocok dengan kata kunci "$_searchQuery".'
                                  : 'Tidak ada jadwal perkuliahan terjadwal untuk hari ini. Waktunya belajar mandiri atau diskusi tugas!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (ctx) {
                                final nextInfo =
                                    CourseScheduleService.getNextActiveDayInfo(
                                      _courses,
                                    );
                                if (nextInfo != null &&
                                    nextInfo.dayName != _selectedDay &&
                                    _searchQuery.isEmpty) {
                                  return ScaleButton(
                                    onTap: () => setState(
                                      () => _selectedDay = nextInfo.dayName,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6D28D9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.fast_forward_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Lihat Jadwal ${nextInfo.dayName} (${nextInfo.courses.length} Kuliah)',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          final c = filteredCourses[index];
                          return FadeSlideEntrance(
                            delay: Duration(milliseconds: index * 40),
                            child: CourseTimelineCard(
                              course: c,
                              isLast: index == filteredCourses.length - 1,
                              onTap: () => _showCourseDetailModal(c),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
