import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';

class ClassAgendaItem {
  final String id;
  final DateTime date;
  String title;
  String course;
  Color color;

  ClassAgendaItem({
    required this.id,
    required this.date,
    required this.title,
    required this.course,
    required this.color,
  });

  int get day => date.day;
  String get month => _monthAbbreviation(date.month);
}

String _monthAbbreviation(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return months[month];
}

class AgendaScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;
  const AgendaScreen({super.key, this.canManage = true, this.onBack});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;
  bool _isLoading = true;
  String? _loadError;

  final List<ClassAgendaItem> _agendaList = [];

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final rows = await SupabaseRepository.getAgendaItems();
      final items = rows.map(_agendaFromRow).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() {
        _agendaList
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  ClassAgendaItem _agendaFromRow(Map<String, dynamic> row) {
    final rawMonth = row['month']?.toString() ?? '';
    final parsedDate = _parseAgendaDate(
      (row['day'] as num?)?.toInt() ?? 1,
      rawMonth,
    );
    return ClassAgendaItem(
      id: row['id'].toString(),
      date: parsedDate,
      title: row['title']?.toString() ?? 'Agenda kelas',
      course: row['course']?.toString() ?? 'Kegiatan Kelas',
      color: Color((row['color_value'] as num?)?.toInt() ?? 0xFF5B3DE8),
    );
  }

  DateTime _parseAgendaDate(int day, String storedMonth) {
    final normalized = storedMonth.trim().toLowerCase();
    final isoMonth = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(normalized);
    var year = _visibleMonth.year;
    var month = _monthNumber(normalized);
    if (isoMonth != null) {
      year = int.parse(isoMonth.group(1)!);
      month = int.parse(isoMonth.group(2)!);
    }
    if (month < 1 || month > 12) month = _visibleMonth.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay).toInt());
  }

  String _storedMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static int _monthNumber(String value) {
    const months = {
      'jan': 1,
      'januari': 1,
      'january': 1,
      'feb': 2,
      'februari': 2,
      'february': 2,
      'mar': 3,
      'maret': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'mei': 5,
      'jun': 6,
      'juni': 6,
      'june': 6,
      'jul': 7,
      'juli': 7,
      'july': 7,
      'agu': 8,
      'agustus': 8,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'okt': 10,
      'oktober': 10,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'des': 12,
      'desember': 12,
      'dec': 12,
      'december': 12,
    };
    final token = value.split(RegExp(r'\s+')).first;
    return months[token] ?? 0;
  }

  List<ClassAgendaItem> get _visibleAgenda =>
      _agendaList
          .where(
            (item) =>
                item.date.year == _visibleMonth.year &&
                item.date.month == _visibleMonth.month,
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
      _selectedDay = 1;
    });
  }

  void _showAddAgendaDialog() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    DateTime pickedDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      _selectedDay.clamp(
        1,
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day,
      ),
    );
    Color selectedColor = const Color(0xFF5B3DE8);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                color: Color(0xFF5B3DE8),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Tambah Agenda Baru',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan / Mata Kuliah',
                      hintText: 'Misal: Ruang Lab TV / Dosen Pengampu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime(2100, 12, 31),
                      );
                      if (picked != null) {
                        setDialogState(() => pickedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Agenda',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${pickedDate.day} ${_monthAbbreviation(pickedDate.month)} ${pickedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Warna Tema:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        [
                          const Color(0xFF5B3DE8),
                          const Color(0xFFF59E0B),
                          const Color(0xFF10B981),
                          const Color(0xFFEF4444),
                          const Color(0xFF0284C7),
                        ].map((col) {
                          final isSelected = selectedColor == col;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = col),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
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
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newId =
                          'ag_${DateTime.now().millisecondsSinceEpoch}';
                      final courseText = courseController.text.trim().isNotEmpty
                          ? courseController.text.trim()
                          : 'Kegiatan Kelas';
                      final newItem = ClassAgendaItem(
                        id: newId,
                        date: pickedDate,
                        title: title,
                        course: courseText,
                        color: selectedColor,
                      );
                      setDialogState(() => isSaving = true);
                      final saved = await SupabaseRepository.createAgendaItem(
                        id: newId,
                        day: pickedDate.day,
                        month: _storedMonth(pickedDate),
                        title: title,
                        course: courseText,
                        colorValue: selectedColor.toARGB32(),
                      );
                      if (!saved) {
                        if (ctx.mounted) setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Agenda gagal disimpan. Periksa koneksi dan izin akun.',
                              ),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                        return;
                      }
                      if (!mounted) return;
                      setState(() {
                        _agendaList.add(newItem);
                        _agendaList.sort((a, b) => a.date.compareTo(b.date));
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Agenda',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan / Mata Kuliah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Warna Tema:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        [
                          const Color(0xFF5B3DE8),
                          const Color(0xFFF59E0B),
                          const Color(0xFF10B981),
                          const Color(0xFFEF4444),
                          const Color(0xFF0284C7),
                        ].map((col) {
                          final isSelected = selectedColor == col;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = col),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
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
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      setDialogState(() => isSaving = true);
                      final course = courseController.text.trim().isEmpty
                          ? 'Kegiatan Kelas'
                          : courseController.text.trim();
                      final saved = await SupabaseRepository.updateAgendaItem(
                        id: agenda.id,
                        title: title,
                        course: course,
                        colorValue: selectedColor.toARGB32(),
                      );
                      if (!saved) {
                        if (ctx.mounted) setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perubahan agenda gagal disimpan.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                        return;
                      }
                      if (!mounted) return;
                      setState(() {
                        agenda.title = title;
                        agenda.course = course;
                        agenda.color = selectedColor;
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
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

  void _confirmDeleteAgenda(ClassAgendaItem agenda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Agenda?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text('Hapus agenda "${agenda.title}"?'),
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
              final deleted = await SupabaseRepository.deleteAgendaItem(
                agenda.id,
              );
              if (!deleted) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Agenda gagal dihapus. Periksa koneksi dan izin akun.',
                      ),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
                return;
              }
              if (!mounted) return;
              setState(() {
                _agendaList.removeWhere((x) => x.id == agenda.id);
              });
              if (ctx.mounted) Navigator.pop(ctx);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddAgendaDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Tambah Agenda',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF111827),
                ),
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
            tooltip: 'Muat ulang agenda',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF111827),
              size: 22,
            ),
            onPressed: _isLoading ? null : _loadAgenda,
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
                        tooltip: 'Bulan sebelumnya',
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        '${_monthAbbreviation(_visibleMonth.month)} ${_visibleMonth.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 24),
                        tooltip: 'Bulan berikutnya',
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Days of Week Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DayHeader('Min'),
                      _DayHeader('Sen'),
                      _DayHeader('Sel'),
                      _DayHeader('Rab'),
                      _DayHeader('Kam'),
                      _DayHeader('Jum'),
                      _DayHeader('Sab'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calendar grid follows the currently selected month.
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
            if (_loadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Agenda gagal dimuat: $_loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadAgenda,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_visibleAgenda.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        size: 32,
                        color: Color(0xFF5B3DE8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Belum Ada Agenda ${_monthAbbreviation(_visibleMonth.month)} ${_visibleMonth.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Agenda ujian, presentasi, atau kegiatan kelas yang ditambahkan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._visibleAgenda.map((agenda) => _buildAgendaTile(agenda)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final firstWeekdayOffset =
        DateTime(_visibleMonth.year, _visibleMonth.month).weekday % 7;
    final eventDays = _visibleAgenda.map((item) => item.day).toSet();

    final cells = <Widget>[];

    for (int i = 0; i < firstWeekdayOffset; i++) {
      cells.add(const SizedBox(width: 34, height: 34));
    }

    for (int day = 1; day <= daysInMonth; day++) {
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
                  fontWeight: (isSelected || hasEvent)
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (hasEvent
                            ? const Color(0xFFB45309)
                            : const Color(0xFF374151)),
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
    final isSelectedDay =
        agenda.day == _selectedDay &&
        agenda.date.month == _visibleMonth.month &&
        agenda.date.year == _visibleMonth.year;

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
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF5B3DE8),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Edit Agenda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
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
      width: 34,
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
