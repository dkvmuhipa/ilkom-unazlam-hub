import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/academic_grade_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

class AcademicGradesScreen extends StatefulWidget {
  final String studentNim;
  final bool canManage;
  final StudentProfile? student;
  final VoidCallback? onBack;

  const AcademicGradesScreen({
    super.key,
    required this.studentNim,
    this.canManage = false,
    this.student,
    this.onBack,
  });

  @override
  State<AcademicGradesScreen> createState() => _AcademicGradesScreenState();
}

class _AcademicGradesScreenState extends State<AcademicGradesScreen> {
  List<StudentProfile> _students = [];
  List<Course> _courses = [];
  List<StudentCourseGrade> _grades = [];
  String? _selectedNim;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedNim = widget.studentNim;
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      if (widget.canManage) {
        final results = await Future.wait<dynamic>([
          AcademicGradeService.listStudents(),
          SupabaseRepository.getCoursesStrict(),
        ]);
        final students = results[0] as List<StudentProfile>;
        final courses = results[1] as List<Course>;
        final nim = students.any((student) => student.nim == _selectedNim)
            ? _selectedNim!
            : students.isEmpty
            ? ''
            : students.first.nim;
        final grades = nim.isEmpty
            ? <StudentCourseGrade>[]
            : await AcademicGradeService.listGrades(nim);
        if (!mounted) return;
        setState(() {
          _students = students;
          _courses = courses;
          _selectedNim = nim;
          _grades = grades;
          _isLoading = false;
        });
      } else {
        final nim = widget.studentNim;
        final grades = await AcademicGradeService.listGrades(nim);
        if (!mounted) return;
        setState(() {
          _selectedNim = nim;
          _grades = grades;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Gagal memuat transkrip nilai: $error');
      if (mounted) {
        setState(() {
          _loadError = 'Transkrip nilai gagal dimuat dari server.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSelectedStudent(String nim) async {
    setState(() {
      _selectedNim = nim;
      _isLoading = true;
      _loadError = null;
    });
    try {
      final grades = await AcademicGradeService.listGrades(nim);
      if (!mounted) return;
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat nilai mahasiswa: $error');
      if (mounted) {
        setState(() {
          _loadError = 'Nilai mahasiswa gagal dimuat.';
          _isLoading = false;
        });
      }
    }
  }

  double _gradePoint(StudentCourseGrade grade) =>
      AcademicGradeService.gradePoints[grade.letterGrade] ?? 0;

  double _calculateGpa(List<StudentCourseGrade> grades) {
    final totalSks = grades.fold<int>(0, (sum, grade) => sum + grade.sks);
    if (totalSks == 0) return 0;
    final totalPoints = grades.fold<double>(
      0,
      (sum, grade) => sum + _gradePoint(grade) * grade.sks,
    );
    return totalPoints / totalSks;
  }

  int _totalSks(List<StudentCourseGrade> grades) =>
      grades.fold<int>(0, (sum, grade) => sum + grade.sks);

  Future<void> _showGradeForm() async {
    if (!widget.canManage) return;
    if (_students.isEmpty || _courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data mahasiswa atau mata kuliah belum tersedia.'),
        ),
      );
      return;
    }

    var selectedStudent = _students.firstWhere(
      (student) => student.nim == _selectedNim,
      orElse: () => _students.first,
    );
    var selectedCourse = _courses.first;
    var selectedSemester = selectedStudent.semester.clamp(1, 16).toInt();
    var letterGrade = 'A';
    final yearController = TextEditingController(
      text: '${DateTime.now().year}/${DateTime.now().year + 1}',
    );
    final scoreController = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Catat nilai akhir'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StudentProfile>(
                    initialValue: selectedStudent,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Mahasiswa'),
                    items: _students
                        .map(
                          (student) => DropdownMenuItem(
                            value: student,
                            child: Text('${student.nama} · ${student.nim}'),
                          ),
                        )
                        .toList(),
                    onChanged: (student) {
                      if (student != null) {
                        setDialogState(() {
                          selectedStudent = student;
                          selectedSemester = student.semester
                              .clamp(1, 16)
                              .toInt();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Course>(
                    initialValue: selectedCourse,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Mata kuliah'),
                    items: _courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course,
                            child: Text(
                              '${course.kode} · ${course.nama} (${course.sks} SKS)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (course) {
                      if (course != null) {
                        setDialogState(() => selectedCourse = course);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedSemester,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                          ),
                          items: List.generate(16, (index) => index + 1)
                              .map(
                                (semester) => DropdownMenuItem(
                                  value: semester,
                                  child: Text('$semester'),
                                ),
                              )
                              .toList(),
                          onChanged: (semester) {
                            if (semester != null) {
                              setDialogState(() => selectedSemester = semester);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: 'Tahun akademik',
                            hintText: '2026/2027',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: letterGrade,
                          decoration: const InputDecoration(
                            labelText: 'Nilai huruf',
                          ),
                          items: AcademicGradeService.gradePoints.keys
                              .map(
                                (grade) => DropdownMenuItem(
                                  value: grade,
                                  child: Text(
                                    '$grade · ${AcademicGradeService.gradePoints[grade]!.toStringAsFixed(1)}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (grade) {
                            if (grade != null) {
                              setDialogState(() => letterGrade = grade);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: scoreController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Nilai angka (opsional)',
                            hintText: '0–100',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'IPK dihitung dari bobot nilai huruf × SKS. Gunakan skala nilai yang berlaku di program studi.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final scoreText = scoreController.text.trim();
                      final score = scoreText.isEmpty
                          ? null
                          : double.tryParse(scoreText.replaceAll(',', '.'));
                      if (scoreText.isNotEmpty && score == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nilai angka harus berupa angka.'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await AcademicGradeService.saveGrade(
                          student: selectedStudent,
                          course: selectedCourse,
                          semester: selectedSemester,
                          academicYear: yearController.text,
                          letterGrade: letterGrade,
                          numericScore: score,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (selectedStudent.nim != _selectedNim) {
                          setState(() => _selectedNim = selectedStudent.nim);
                        }
                        await _loadSelectedStudent(selectedStudent.nim);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Nilai akhir berhasil disimpan.'),
                            ),
                          );
                        }
                      } catch (error) {
                        debugPrint('Gagal menyimpan nilai akhir: $error');
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nilai gagal disimpan. Pastikan migrasi nilai sudah diterapkan.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Menyimpan…' : 'Simpan nilai'),
            ),
          ],
        ),
      ),
    );
    yearController.dispose();
    scoreController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = _students.where((s) => s.nim == _selectedNim);
    final displayStudent = selectedStudent.isNotEmpty
        ? selectedStudent.first
        : widget.student;
    final grouped = <String, List<StudentCourseGrade>>{};
    for (final grade in _grades) {
      grouped
          .putIfAbsent('${grade.academicYear}|${grade.semester}', () => [])
          .add(grade);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('Transkrip Nilai & IPK'),
        actions: [
          IconButton(
            tooltip: 'Ekspor KHS / Transkrip',
            onPressed: () {
              final nimValue = _selectedNim ?? widget.studentNim;
              final studentToExport = displayStudent ??
                  StudentProfile(
                    id: nimValue,
                    nim: nimValue,
                    nama: 'Mahasiswa',
                    email: '',
                    noWa: '',
                    semester: 1,
                    prodi: 'Ilmu Komunikasi',
                    kelas: 'Ilmu Komunikasi',
                  );
              final gpa = _calculateGpa(_grades);
              final totalSks = _grades.fold<int>(0, (sum, g) => sum + g.sks);
              final csvContent = ExportService.exportKhsCsv(
                student: studentToExport,
                grades: _grades,
                gpa: gpa,
                totalSks: totalSks,
              );
              ExportService.showExportSheet(
                context,
                title: 'Ekspor KHS / Transkrip Nilai',
                subtitle: '${studentToExport.nama} (${studentToExport.nim}) • IPK ${gpa.toStringAsFixed(2)}',
                fileName: 'KHS_${studentToExport.nim}.csv',
                content: csvContent,
              );
            },
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showGradeForm,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Catat nilai'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 40),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (widget.canManage)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _students.any((s) => s.nim == _selectedNim)
                          ? _selectedNim
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih mahasiswa',
                        border: OutlineInputBorder(),
                      ),
                      items: _students
                          .map(
                            (student) => DropdownMenuItem(
                              value: student.nim,
                              child: Text('${student.nama} · ${student.nim}'),
                            ),
                          )
                          .toList(),
                      onChanged: (nim) {
                        if (nim != null) _loadSelectedStudent(nim);
                      },
                    ),
                  ),
                Expanded(
                  child: _selectedNim == null || _selectedNim!.isEmpty
                      ? const Center(child: Text('Belum ada mahasiswa aktif.'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                          children: [
                            _buildSummary(displayStudent),
                            const SizedBox(height: 18),
                            if (_grades.isEmpty)
                              _buildEmptyState()
                            else
                              ...grouped.entries.map(
                                (entry) =>
                                    _buildTermCard(entry.key, entry.value),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummary(StudentProfile? student) {
    final ipk = _calculateGpa(_grades);
    final sks = _totalSks(_grades);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8068F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student?.nama ?? 'Transkrip mahasiswa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'NIM ${_selectedNim ?? '-'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryValue(
                  'IPK',
                  _grades.isEmpty ? '—' : ipk.toStringAsFixed(2),
                ),
              ),
              Expanded(child: _summaryValue('Total SKS', '$sks')),
              Expanded(
                child: _summaryValue('Mata kuliah', '${_grades.length}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'IPK dihitung dari bobot nilai × SKS untuk semua nilai tercatat. Nilai ulang mengikuti kebijakan program studi.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryValue(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _buildTermCard(String key, List<StudentCourseGrade> grades) {
    final parts = key.split('|');
    final year = parts.first;
    final semester = parts.length > 1 ? parts[1] : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Semester $semester · $year',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                'IP ${_calculateGpa(grades).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...grades.map(_buildGradeRow),
        ],
      ),
    );
  }

  Widget _buildGradeRow(StudentCourseGrade grade) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grade.courseName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${grade.courseCode} · ${grade.sks} SKS${grade.numericScore == null ? '' : ' · ${grade.numericScore!.toStringAsFixed(1)}'}',
                style: const TextStyle(color: AppColors.textSub, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            grade.letterGrade,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const Column(
      children: [
        Icon(Icons.school_outlined, size: 38, color: AppColors.primary),
        SizedBox(height: 10),
        Text(
          'Nilai resmi belum tersedia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          'Nilai akhir mata kuliah akan muncul setelah dicatat oleh administrator akademik.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSub, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}
