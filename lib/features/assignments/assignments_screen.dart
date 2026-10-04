import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String _selectedTab = 'Semua';

  Future<void> _launchSubmit(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _cycleStatus(Assignment assignment) {
    setState(() {
      if (assignment.status == 'belum') {
        assignment.status = 'sedang_dikerjakan';
      } else if (assignment.status == 'sedang_dikerjakan') {
        assignment.status = 'selesai';
      } else {
        assignment.status = 'belum';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status diubah: ${_statusLabel(assignment.status)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum':
        return 'Belum Mulai';
      case 'sedang_dikerjakan':
        return 'Sedang Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Assignment> filteredList = DummyData.assignments;
    if (_selectedTab == 'Belum Selesai') {
      filteredList = DummyData.assignments.where((a) => a.status != 'selesai').toList();
    } else if (_selectedTab == 'Selesai') {
      filteredList = DummyData.assignments.where((a) => a.status == 'selesai').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tugas & Praktikum'),
      ),
      body: Column(
        children: [
          // Filter Tabs (Clean Segmented Pills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: ['Semua', 'Belum Selesai', 'Selesai'].map((tab) {
                  final isSelected = tab == _selectedTab;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = tab),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List Tugas
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text('Tidak ada tugas di kategori ini.', style: TextStyle(color: AppColors.textSub)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final a = filteredList[index];
                      return _buildMinimalAssignmentItem(a);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAssignmentItem(Assignment a) {
    final diff = a.deadline.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final isDone = a.status == 'selesai';
    final isWorking = a.status == 'sedang_dikerjakan';

    Color statusColor = AppColors.textLight;
    Color statusBg = const Color(0xFFF3F2F5);
    if (isDone) {
      statusColor = AppColors.success;
      statusBg = AppColors.successSoft;
    } else if (isWorking) {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningSoft;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.kategori == 'Proyek Praktikum' ? AppColors.primarySoft : AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.kategori,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: a.kategori == 'Proyek Praktikum' ? AppColors.primary : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.courseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSub),
                ),
              ),
              // Status Pill Toggle
              InkWell(
                onTap: () => _cycleStatus(a),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(a.status),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.judul,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDone ? AppColors.textLight : AppColors.textMain,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.deskripsi,
            style: const TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(a.deadline),
                style: const TextStyle(fontSize: 11, color: AppColors.textSub),
              ),
              const Spacer(),
              Text(
                daysLeft <= 0 ? 'Hari ini' : '$daysLeft hari lagi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: daysLeft <= 2 ? AppColors.error : AppColors.textSub,
                ),
              ),
            ],
          ),
          if (a.linkPengumpulan != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _launchSubmit(a.linkPengumpulan!),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Buka Link Drive / Pengumpulan',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
