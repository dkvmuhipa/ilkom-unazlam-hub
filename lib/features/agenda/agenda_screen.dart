import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ClassAgendaItem {
  final int day;
  final String month;
  final String title;
  final String course;
  final Color color;

  const ClassAgendaItem({
    required this.day,
    required this.month,
    required this.title,
    required this.course,
    required this.color,
  });
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _selectedDay = 5;

  final List<ClassAgendaItem> _agendaList = const [
    ClassAgendaItem(
      day: 5,
      month: 'Okt',
      title: 'Presentasi Kelompok 1',
      course: 'Pendidikan Kewarganegaraan',
      color: Color(0xFF5B3DE8),
    ),
    ClassAgendaItem(
      day: 8,
      month: 'Okt',
      title: 'Pengumpulan Makalah',
      course: 'Pendidikan Pancasila',
      color: Color(0xFFF59E0B),
    ),
    ClassAgendaItem(
      day: 12,
      month: 'Okt',
      title: 'Presentasi Kelompok 2',
      course: 'Dasar-Dasar Ilmu Komunikasi',
      color: Color(0xFF5B3DE8),
    ),
    ClassAgendaItem(
      day: 22,
      month: 'Okt',
      title: 'Ujian Tengah Semester (UTS)',
      course: 'Semester 1 - FISIP UNAZLAM',
      color: Color(0xFF2E094B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Agenda Kelas',
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month Navigator Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 24),
                        onPressed: () {},
                      ),
                      const Text(
                        'Oktober 2026',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Days of Week Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DayHeader('M'),
                      _DayHeader('S'),
                      _DayHeader('S'),
                      _DayHeader('R'),
                      _DayHeader('K'),
                      _DayHeader('J'),
                      _DayHeader('S'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calendar Grid (October 2026 starts on Thursday)
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Daftar Agenda Kegiatan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),

            // Agenda List
            ..._agendaList.map((agenda) => _buildAgendaTile(agenda)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // October 2026: 1 Oct is Thursday (index 4 if Sunday=0: Sun, Mon, Tue, Wed, Thu, Fri, Sat)
    // 31 days
    final eventDays = [5, 8, 12, 22];

    final cells = <Widget>[];

    // Padding for Thu start (4 empty cells: Sun, Mon, Tue, Wed)
    for (int i = 0; i < 4; i++) {
      cells.add(const SizedBox(width: 32, height: 32));
    }

    for (int day = 1; day <= 31; day++) {
      final isSelected = day == _selectedDay;
      final hasEvent = eventDays.contains(day);

      cells.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5B3DE8)
                  : (hasEvent ? const Color(0xFFFEF3C7) : Colors.transparent),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isSelected || hasEvent) ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (hasEvent ? const Color(0xFFB45309) : const Color(0xFF374151)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.start,
      children: cells,
    );
  }

  Widget _buildAgendaTile(ClassAgendaItem agenda) {
    final isSelectedDay = agenda.day == _selectedDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelectedDay ? AppColors.primary : const Color(0xFFE5E7EB),
          width: isSelectedDay ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: agenda.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  agenda.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: agenda.color,
                    height: 1.1,
                  ),
                ),
                Text(
                  agenda.month,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: agenda.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agenda.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  agenda.course,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
