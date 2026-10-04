import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  void _showLogModal(CourseAttendance item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catat Absensi Pertemuan',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 2),
              Text(
                item.courseName,
                style: const TextStyle(fontSize: 11, color: AppColors.textSub),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusButton('Hadir', AppColors.success, Icons.check_circle_outline),
                  _buildStatusButton('Izin', AppColors.warning, Icons.info_outline),
                  _buildStatusButton('Sakit', AppColors.info, Icons.medical_services_outlined),
                  _buildStatusButton('Alpa', AppColors.error, Icons.cancel_outlined),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String label, Color color, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presensi dicatat: $label'), duration: const Duration(seconds: 1)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pelacak Kehadiran (75%)'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimalist Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketentuan 75% Perkuliahan',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Maksimal 4 kali ketidakhadiran dari total 16 pertemuan per semester.',
                          style: TextStyle(color: AppColors.textSub, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Mata Kuliah Semester Ini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 10),

            ...DummyData.attendanceRecords.map((item) => _buildMinimalAttendanceCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalAttendanceCard(CourseAttendance item) {
    final persentase = item.persentase;
    final isDanger = item.isDangerZone;

    Color badgeColor = AppColors.success;
    Color badgeBg = AppColors.successSoft;
    if (isDanger) {
      badgeColor = AppColors.error;
      badgeBg = AppColors.errorSoft;
    } else if (item.alpa > 0) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningSoft;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${persentase.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Clean Minimalist Progress Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.sesiBerjalan / item.totalSesi,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F2F6),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDanger ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pertemuan ${item.sesiBerjalan}/${item.totalSesi}',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
              Text(
                'Hadir ${item.hadir} • Izin ${item.izin} • Alpa ${item.alpa}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                size: 14,
                color: isDanger ? AppColors.error : AppColors.textSub,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isDanger
                      ? 'Sisa jatah alpa tinggal ${item.sisaAlpaAman}x lagi!'
                      : 'Toleransi alpa: sisa ${item.sisaAlpaAman}x sesi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDanger ? AppColors.error : AppColors.textSub,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showLogModal(item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Catat',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
