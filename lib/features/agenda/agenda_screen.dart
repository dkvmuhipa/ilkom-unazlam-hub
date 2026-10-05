import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';

class ClassAgendaItem {
  final String id;
  int day;
  String month;
  String title;
  String course;
  Color color;

  ClassAgendaItem({
    required this.id,
    required this.day,
    required this.month,
    required this.title,
    required this.course,
    required this.color,
  });
}

class AgendaScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  const AgendaScreen({super.key, this.canManage = true, this.onBack});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _selectedDay = 5;

  final List<ClassAgendaItem> _agendaList = [
    ClassAgendaItem(
      id: 'ag_1',
      day: 5,
      month: 'Okt',
      title: 'Presentasi Kelompok 1',
      course: 'Pendidikan Kewarganegaraan',
      color: const Color(0xFF5B3DE8),
    ),
    ClassAgendaItem(
      id: 'ag_2',
      day: 8,
      month: 'Okt',
      title: 'Pengumpulan Makalah',
      course: 'Pendidikan Pancasila',
      color: const Color(0xFFF59E0B),
    ),
    ClassAgendaItem(
      id: 'ag_3',
      day: 12,
      month: 'Okt',
      title: 'Presentasi Kelompok 2',
      course: 'Dasar-Dasar Ilmu Komunikasi',
      color: const Color(0xFF5B3DE8),
    ),
    ClassAgendaItem(
      id: 'ag_4',
      day: 22,
      month: 'Okt',
      title: 'Ujian Tengah Semester (UTS)',
      course: 'Semester 1 - FISIP UNAZLAM',
      color: const Color(0xFF2E094B),
    ),
  ];

  void _showAddAgendaDialog() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    DateTime pickedDate = DateTime(2026, 10, _selectedDay);
    Color selectedColor = const Color(0xFF5B3DE8);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.event_available_rounded, color: Color(0xFF5B3DE8), size: 22),
              SizedBox(width: 8),
              Text('Tambah Agenda Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Agenda',
                      hintText: 'Misal: Diskusi Kelompok, Seminar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan / Mata Kuliah',
                      hintText: 'Misal: Ruang Lab TV / Dosen Pengampu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime(2026, 1, 1),
                        lastDate: DateTime(2027, 12, 31),
                      );
                      if (picked != null) {
                        setDialogState(() => pickedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Agenda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '${pickedDate.day} ${_monthName(pickedDate.month)} ${pickedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Warna Tema:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Color(0xFF5B3DE8),
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      const Color(0xFFEF4444),
                      const Color(0xFF0284C7),
                    ].map((col) {
                      final isSelected = selectedColor == col;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = col),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
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
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final newId = 'ag_${DateTime.now().millisecondsSinceEpoch}';
                final courseText = courseController.text.trim().isNotEmpty ? courseController.text.trim() : 'Kegiatan Kelas';
                final newItem = ClassAgendaItem(
                  id: newId,
                  day: pickedDate.day,
                  month: _monthName(pickedDate.month),
                  title: title,
                  course: courseText,
                  color: selectedColor,
                );
                setState(() {
                  _agendaList.add(newItem);
                });
                SupabaseRepository.createAgendaItem(
                  id: newId,
                  day: pickedDate.day,
                  month: _monthName(pickedDate.month),
                  title: title,
                  course: courseText,
                  colorValue: selectedColor.toARGB32(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agenda berhasil ditambahkan!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan Agenda'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAgendaDialog(ClassAgendaItem agenda) {
    final titleController = TextEditingController(text: agenda.title);
    final courseController = TextEditingController(text: agenda.course);
    Color selectedColor = agenda.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Agenda', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Agenda',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan / Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Warna Tema:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Color(0xFF5B3DE8),
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      const Color(0xFFEF4444),
                      const Color(0xFF0284C7),
                    ].map((col) {
                      final isSelected = selectedColor == col;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = col),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
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
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                setState(() {
                  agenda.title = title;
                  agenda.course = courseController.text.trim();
                  agenda.color = selectedColor;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agenda berhasil diperbarui!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
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

  void _confirmDeleteAgenda(ClassAgendaItem agenda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Agenda?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Hapus agenda "${agenda.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _agendaList.removeWhere((x) => x.id == agenda.id);
              });
              SupabaseRepository.deleteAgendaItem(agenda.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agenda berhasil dihapus.'),
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

  String _monthName(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddAgendaDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah Agenda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : null,
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
          if (widget.canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF9CA3AF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditAgendaDialog(agenda);
                } else if (val == 'delete') {
                  _confirmDeleteAgenda(agenda);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFF5B3DE8)),
                      SizedBox(width: 8),
                      Text('Edit Agenda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
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
