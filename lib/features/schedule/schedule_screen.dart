import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/course_schedule_service.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class ScheduleScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  const ScheduleScreen({super.key, this.canManage = true, this.onBack});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDay = 'Senin';
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Semua'];
  List<Course> _courses = DummyData.courses;
  bool _isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddCourseDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final sksCtrl = TextEditingController(text: '2');
    final dosenCtrl = TextEditingController();
    final dosenWaCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: 'Ruang A2');
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '09:40');
    String selectedDay = _selectedDay == 'Semua' ? 'Senin' : _selectedDay;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Tambah Mata Kuliah', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Mata Kuliah *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dosen Pengampu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenWaCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Dosen (Opsional)',
                      hintText: '08xxxxxxxxxx',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final newCourse = Course(
                  id: 'course_${DateTime.now().millisecondsSinceEpoch}',
                  kode: codeCtrl.text.trim().isEmpty ? 'MK ILKOM' : codeCtrl.text.trim(),
                  nama: name,
                  sks: int.tryParse(sksCtrl.text.trim()) ?? 2,
                  semester: 1,
                  dosen: dosenCtrl.text.trim().isEmpty ? 'Dosen Pengampu' : dosenCtrl.text.trim(),
                  dosenWa: dosenWaCtrl.text.trim().isEmpty ? null : dosenWaCtrl.text.trim(),
                  hari: selectedDay,
                  jamMulai: startCtrl.text.trim().isEmpty ? '08:00' : startCtrl.text.trim(),
                  jamSelesai: endCtrl.text.trim().isEmpty ? '09:40' : endCtrl.text.trim(),
                  ruangan: roomCtrl.text.trim().isEmpty ? 'Ruang A2' : roomCtrl.text.trim(),
                );
                setState(() {
                  DummyData.courses.add(newCourse);
                  _courses = List.from(DummyData.courses);
                  _selectedDay = selectedDay;
                });
                SupabaseRepository.createCourse(newCourse);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mata kuliah berhasil ditambahkan ke jadwal!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
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
    String selectedDay = c.hari;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Mata Kuliah', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Mata Kuliah *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dosen Pengampu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosenWaCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Dosen (Opsional)',
                      hintText: '08xxxxxxxxxx',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final updatedCourse = Course(
                  id: c.id,
                  kode: codeCtrl.text.trim().isEmpty ? c.kode : codeCtrl.text.trim(),
                  nama: name,
                  sks: int.tryParse(sksCtrl.text.trim()) ?? c.sks,
                  semester: c.semester,
                  dosen: dosenCtrl.text.trim().isEmpty ? c.dosen : dosenCtrl.text.trim(),
                  dosenWa: dosenWaCtrl.text.trim().isEmpty ? null : dosenWaCtrl.text.trim(),
                  hari: selectedDay,
                  jamMulai: startCtrl.text.trim().isEmpty ? c.jamMulai : startCtrl.text.trim(),
                  jamSelesai: endCtrl.text.trim().isEmpty ? c.jamSelesai : endCtrl.text.trim(),
                  ruangan: roomCtrl.text.trim().isEmpty ? c.ruangan : roomCtrl.text.trim(),
                );
                setState(() {
                  final idxDummy = DummyData.courses.indexWhere((x) => x.id == c.id);
                  if (idxDummy != -1) {
                    DummyData.courses[idxDummy] = updatedCourse;
                  }
                  final idxCurrent = _courses.indexWhere((x) => x.id == c.id);
                  if (idxCurrent != -1) {
                    _courses[idxCurrent] = updatedCourse;
                  }
                  _selectedDay = selectedDay;
                });
                SupabaseRepository.updateCourse(updatedCourse);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jadwal mata kuliah berhasil diperbarui!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(Course c, {VoidCallback? onSuccess}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Mata Kuliah?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menghapus "${c.nama}" dari jadwal perkuliahan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                DummyData.courses.removeWhere((x) => x.id == c.id);
                _courses.removeWhere((x) => x.id == c.id);
              });
              SupabaseRepository.deleteCourse(c.id);
              Navigator.pop(ctx);
              onSuccess?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mata kuliah berhasil dihapus dari jadwal.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _autoSelectActiveDay(List<Course> list) {
    if (list.isEmpty) return;
    final now = DateTime.now();
    final today = CourseScheduleService.getDayName(now);
    final todayHasCourses = list.any((c) => c.hari.trim().toLowerCase() == today.toLowerCase());
    if (todayHasCourses) {
      _selectedDay = today;
    } else {
      // Jika hari ini tidak ada jadwal sama sekali, lewati ke hari aktif berikutnya!
      final nextInfo = CourseScheduleService.getNextActiveDayInfo(list, now);
      if (nextInfo != null) {
        _selectedDay = nextInfo.dayName;
      } else {
        _selectedDay = 'Senin';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _autoSelectActiveDay(_courses);
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await client.from('courses').select();
      if (response.isNotEmpty) {
        final List<Course> loaded =
            response.map<Course>((item) => Course.fromMap(item)).toList();
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
          return a.jamMulai.compareTo(b.jamMulai);
        });
        if (mounted) {
          setState(() {
            _courses = loaded;
            _autoSelectActiveDay(loaded);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching courses from Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWhatsAppDosen(String phone, String lecturerName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent('Halo Bapak/Ibu $lecturerName, saya mahasiswa dari S1 Ilmu Komunikasi UNAZLAM...');
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111018) : AppColors.background;
    final headerBg = isDark ? const Color(0xFF181622) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final pillBg = isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9);

    var filteredCourses = _selectedDay == 'Semua'
        ? _courses
        : _courses.where((c) => c.hari.trim().toLowerCase() == _selectedDay.trim().toLowerCase()).toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredCourses = filteredCourses.where((c) =>
          c.nama.toLowerCase().contains(q) ||
          c.kode.toLowerCase().contains(q) ||
          c.dosen.toLowerCase().contains(q) ||
          c.ruangan.toLowerCase().contains(q) ||
          c.hari.toLowerCase().contains(q)
      ).toList();
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddCourseDialog,
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah Jadwal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: headerBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textMain),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(
                  color: textMain,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari matkul, dosen, ruangan...',
                  hintStyle: TextStyle(
                    color: textSub,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: textSub, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                'Jadwal Kuliah',
                style: TextStyle(
                  color: textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close_rounded, color: textMain, size: 22),
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
              icon: Icon(Icons.search_rounded, color: textMain, size: 22),
              tooltip: 'Cari Jadwal',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: Icon(Icons.sync_rounded, color: textMain, size: 20),
              tooltip: 'Sinkronisasi Jadwal',
              onPressed: _fetchCourses,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Hari (Pill bar with Today indicator)
          Container(
            color: headerBg,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Builder(
                builder: (context) {
                  final now = DateTime.now();
                  const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
                  final todayName = (now.weekday >= 1 && now.weekday <= 7) ? dayNames[now.weekday] : '';

                  return Row(
                    children: _days.map((day) {
                      final isSelected = day == _selectedDay;
                      final isToday = day == todayName;
                      final count = day == 'Semua'
                          ? _courses.length
                          : _courses
                              .where((c) =>
                                  c.hari.trim().toLowerCase() ==
                                  day.toLowerCase())
                              .length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDay = day),
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF1E40AF), Color(0xFF755BF7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : pillBg,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isToday) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Text(
                                  day == 'Semua' ? 'Semua ($count)' : '$day ($count)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // Schedule Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Hasil pencarian: ${filteredCourses.length} mata kuliah'
                        : (_selectedDay == 'Semua'
                            ? 'Total ${_courses.length} mata kuliah terdaftar'
                            : '$_selectedDay • ${filteredCourses.length} mata kuliah (${filteredCourses.fold<int>(0, (sum, c) => sum + c.sks)} SKS)'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2248) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Semester 1',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchCourses,
                    child: filteredCourses.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 70),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _searchQuery.isNotEmpty
                                              ? Icons.search_off_rounded
                                              : Icons.event_available_rounded,
                                          size: 46,
                                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Tidak Ada Hasil Pencarian'
                                            : 'Tidak Ada Kuliah di Hari $_selectedDay',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Tidak ditemukan mata kuliah dengan kata kunci "$_searchQuery".'
                                            : 'Tidak ada agenda perkuliahan tatap muka terjadwal untuk hari ini. Waktunya belajar mandiri atau diskusi tugas!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: textSub,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 18),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() {
                                                _searchQuery = '';
                                                _isSearching = false;
                                              });
                                            },
                                            icon: const Icon(Icons.refresh_rounded, size: 16),
                                            label: const Text('Reset Pencarian'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1E40AF),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        )
                                      else
                                        Builder(
                                          builder: (ctx) {
                                            final nextInfo = CourseScheduleService.getNextActiveDayInfo(_courses);
                                            if (nextInfo != null && nextInfo.dayName != _selectedDay) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 18),
                                                child: ElevatedButton.icon(
                                                  onPressed: () => setState(() => _selectedDay = nextInfo.dayName),
                                                  icon: const Icon(Icons.fast_forward_rounded, size: 16),
                                                  label: Text('Lihat Jadwal ${nextInfo.dayName} (${nextInfo.courses.length} Kuliah)'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1E40AF),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final c = filteredCourses[index];
                              return _buildTimelineItem(
                                c,
                                isDark: isDark,
                                isLast: index == filteredCourses.length - 1,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getCourseAccentColor(String courseName) {
    final colors = [
      const Color(0xFF1E40AF), // Royal Purple
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFFD97706), // Amber
      const Color(0xFF7C3AED), // Violet
      const Color(0xFF2563EB), // Indigo Blue
      const Color(0xFFDC2626), // Crimson
    ];
    return colors[courseName.hashCode.abs() % colors.length];
  }

  bool _isCourseOngoing(Course c) {
    final now = DateTime.now();
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (now.weekday < 1 || now.weekday > 7 || dayNames[now.weekday] != c.hari) {
      return false;
    }
    try {
      final startParts = c.jamMulai.split(':');
      final endParts = c.jamSelesai.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMinutes = now.hour * 60 + now.minute;
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } catch (_) {
      return false;
    }
  }

  bool _isCourseFinished(Course c) {
    final now = DateTime.now();
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (now.weekday < 1 || now.weekday > 7 || dayNames[now.weekday] != c.hari) {
      return false;
    }
    try {
      final endParts = c.jamSelesai.split(':');
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMinutes = now.hour * 60 + now.minute;
      return currentMinutes > endMinutes;
    } catch (_) {
      return false;
    }
  }

  Widget _buildLecturerAvatar(String name, Color color) {
    final clean = name.replaceAll(RegExp(r'(Dr\.|M\.I\.Kom|S\.Sos|Prof\.|H\.|Hj\.)'), '').trim();
    final initials = clean.isNotEmpty
        ? clean.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'DS';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // Modern Timeline UI
  Widget _buildTimelineItem(
    Course c, {
    required bool isDark,
    required bool isLast,
  }) {
    final accentColor = _getCourseAccentColor(c.nama);
    final isOngoing = _isCourseOngoing(c);
    final isFinished = _isCourseFinished(c);

    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final pillBg = isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Time Column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.jamMulai,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isOngoing
                        ? const Color(0xFF10B981)
                        : textMain,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.jamSelesai,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Dot & Connecting Line
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF1E1C2B) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOngoing ? Colors.white : accentColor,
                    width: isOngoing ? 2 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOngoing ? const Color(0xFF10B981) : accentColor).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Right Course Card
          Expanded(
            child: InkWell(
              onTap: () => _showCourseDetailModal(c),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOngoing
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : borderColor,
                    width: isOngoing ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isOngoing ? const Color(0xFF10B981) : accentColor,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Badges Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                c.kode.isNotEmpty ? c.kode : 'ILKOM',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: pillBg,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '${c.sks} SKS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: textSub,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isOngoing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF132A20) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Berlangsung',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isFinished)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: textSub,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Course Title
                        Text(
                          c.nama,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Room badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF26223D) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 13,
                                    color: textSub,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.ruangan.isNotEmpty ? c.ruangan : 'Ruang A2',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),

                        // Lecturer & Contact
                        Row(
                          children: [
                            _buildLecturerAvatar(c.dosen, accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.dosen,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSub,
                                ),
                              ),
                            ),
                            if (c.dosenWa != null && c.dosenWa!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _openWhatsAppDosen(c.dosenWa!, c.dosen),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_rounded,
                                        size: 12,
                                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chat WA',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDetailModal(Course c) {
    // Find materials associated with this course
    final cleanCourseName = c.nama.replaceAll('*', '').trim().toLowerCase();
    final relatedResources = DummyData.resources.where((r) {
      final rName = r.courseName.replaceAll('*', '').trim().toLowerCase();
      return rName == cleanCourseName || cleanCourseName.contains(rName) || rName.contains(cleanCourseName);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final subCardBg = isDark ? const Color(0xFF181622) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE5E7EB);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c.kode.isNotEmpty ? c.kode : 'MK ILKOM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF26223D) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${c.sks} SKS • Semester ${c.semester}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textSub,
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
                          icon: Icon(Icons.edit_outlined, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF), size: 20),
                          tooltip: 'Edit Mata Kuliah',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditCourseDialog(c);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          tooltip: 'Hapus Mata Kuliah',
                          onPressed: () {
                            _confirmDeleteCourse(c, onSuccess: () => Navigator.pop(ctx));
                          },
                        ),
                      ],
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSub, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      c.nama,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Schedule Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2E2248) : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.access_time_rounded, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Waktu Perkuliahan', style: TextStyle(fontSize: 11, color: textSub)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.hari}, ${c.jamMulai} - ${c.jamSelesai} WITA',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textMain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF332A1B) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.meeting_room_outlined, color: Color(0xFFD97706), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ruang Kuliah', style: TextStyle(fontSize: 11, color: textSub)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.ruangan.isNotEmpty ? c.ruangan : "Ruang A2"} • Gedung FISIP UNAZLAM',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textMain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lecturer Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? const Color(0xFF132A20) : const Color(0xFFDCFCE7),
                            child: Icon(Icons.person_rounded, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dosen Pengampu', style: TextStyle(fontSize: 11, color: textSub)),
                                const SizedBox(height: 2),
                                Text(
                                  c.dosen,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textMain),
                                ),
                              ],
                            ),
                          ),
                          if (c.dosenWa != null && c.dosenWa!.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _openWhatsAppDosen(c.dosenWa!, c.dosen),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                              label: const Text('WA Dosen', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Materi & Dokumen Perkuliahan Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.folder_open_rounded, size: 18, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF)),
                            const SizedBox(width: 8),
                            Text(
                              'Materi & Dokumen Kuliah',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${relatedResources.length} Berkas',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (relatedResources.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: subCardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.library_books_outlined, color: textSub, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada modul khusus yang diunggah untuk mata kuliah ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: textSub),
                            ),
                          ],
                        ),
                      )
                    else
                      ...relatedResources.map((res) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: subCardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2E2248) : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.description_rounded, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF1E40AF), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.judul,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textMain),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${res.jenis} • Pertemuan Ke-${res.pertemuanKe ?? 1}',
                                      style: TextStyle(fontSize: 11, color: textSub),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final uri = Uri.parse(res.linkUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text('Buka', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
