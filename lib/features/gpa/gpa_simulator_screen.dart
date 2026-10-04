import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class GpaSimulatorScreen extends StatefulWidget {
  const GpaSimulatorScreen({super.key});

  @override
  State<GpaSimulatorScreen> createState() => _GpaSimulatorScreenState();
}

class _GpaSimulatorScreenState extends State<GpaSimulatorScreen> {
  // Peta nilai huruf ke bobot angka standar universitas
  final Map<String, double> _gradePoints = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  late Map<String, String> _selectedGrades;

  @override
  void initState() {
    super.initState();
    // Default target nilai A atau B+ untuk tiap MK
    _selectedGrades = {
      for (var c in DummyData.courses) c.id: 'A',
    };
    if (_selectedGrades.containsKey('c3')) _selectedGrades['c3'] = 'A-';
    if (_selectedGrades.containsKey('c5')) _selectedGrades['c5'] = 'B+';
  }

  double _calculateGpa() {
    double totalPoints = 0;
    int totalSks = 0;

    for (var c in DummyData.courses) {
      final grade = _selectedGrades[c.id] ?? 'A';
      final point = _gradePoints[grade] ?? 4.0;
      totalPoints += point * c.sks;
      totalSks += c.sks;
    }

    if (totalSks == 0) return 4.0;
    return totalPoints / totalSks;
  }

  String _getHonorsLabel(double gpa) {
    if (gpa >= 3.8) return 'Cumlaude / Sangat Memuaskan';
    if (gpa >= 3.5) return 'Sangat Memuaskan';
    if (gpa >= 3.0) return 'Memuaskan';
    if (gpa >= 2.5) return 'Cukup';
    return 'Perlu Perbaikan';
  }

  Color _getGpaColor(double gpa) {
    if (gpa >= 3.5) return AppColors.success;
    if (gpa >= 3.0) return AppColors.primary;
    if (gpa >= 2.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final gpa = _calculateGpa();
    final totalSks = DummyData.courses.fold(0, (sum, c) => sum + c.sks);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Simulasi Target Nilai & IPK'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Projection Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  const Text(
                    'Proyeksi Indeks Prestasi Semester (IPS)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    gpa.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getGpaColor(gpa).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _getHonorsLabel(gpa),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Total $totalSks SKS • Ubah target nilai di bawah untuk melihat simulasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              'Target Nilai per Mata Kuliah',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            const SizedBox(height: 10),

            ...DummyData.courses.map((c) => _buildCourseGradeTile(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGradeTile(Course c) {
    final currentGrade = _selectedGrades[c.id] ?? 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${c.sks} SKS',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nama,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
                Text(
                  '${c.kode} • ${c.dosen}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dropdown Target Huruf Mutu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: DropdownButton<String>(
              value: currentGrade,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
              items: _gradePoints.keys.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text(
                    grade,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newGrade) {
                if (newGrade != null) {
                  setState(() {
                    _selectedGrades[c.id] = newGrade;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
