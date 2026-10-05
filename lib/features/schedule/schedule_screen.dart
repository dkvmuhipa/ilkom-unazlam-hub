import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDay = 'Senin';
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Semua'];
  List<Course> _courses = DummyData.courses;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to today if weekday is Mon-Fri
    final now = DateTime.now();
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (now.weekday >= 1 && now.weekday <= 5) {
      _selectedDay = dayNames[now.weekday];
    }
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
    final filteredCourses = _selectedDay == 'Semua'
        ? _courses
        : _courses.where((c) => c.hari == _selectedDay).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Jadwal Kuliah',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF111827), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF111827), size: 20),
            tooltip: 'Sinkronisasi Jadwal',
            onPressed: _fetchCourses,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Hari (Pill bar matching Screen 4)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _days.map((day) {
                  final isSelected = day == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDay = day),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Timeline List matching Screen 4
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchCourses,
                    child: filteredCourses.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Tidak ada perkuliahan di hari ini.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final c = filteredCourses[index];
                              return _buildTimelineItem(c, isLast: index == filteredCourses.length - 1);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // Timeline UI matching Screen 4
  Widget _buildTimelineItem(Course c, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Time Column
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.jamMulai,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.jamSelesai,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Dot and Vertical Line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF5B3DE8),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Right Course Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Room Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        c.ruangan.isNotEmpty ? c.ruangan : 'Ruang A2',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${c.sks} SKS',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Lecturer
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          c.dosen,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                        ),
                      ),
                      if (c.dosenWa != null && c.dosenWa!.isNotEmpty)
                        InkWell(
                          onTap: () => _openWhatsAppDosen(c.dosenWa!, c.dosen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'WA Dosen',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                ),
                              ],
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
}
