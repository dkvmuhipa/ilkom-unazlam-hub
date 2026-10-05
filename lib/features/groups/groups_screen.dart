import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupTaskProgress {
  final String title;
  bool isCompleted;

  GroupTaskProgress({required this.title, this.isCompleted = false});
}

class EnhancedGroupItem {
  final String id;
  String namaKelompok;
  String courseName;
  String assignmentTitle;
  String? linkGDrive;
  List<StudentProfile> members;
  List<GroupTaskProgress> tasks;

  EnhancedGroupItem({
    required this.id,
    required this.namaKelompok,
    required this.courseName,
    required this.assignmentTitle,
    this.linkGDrive,
    required this.members,
    List<GroupTaskProgress>? tasks,
  }) : tasks = tasks ?? [
          GroupTaskProgress(title: 'Riset Topik & Studi Literatur', isCompleted: true),
          GroupTaskProgress(title: 'Penyusunan Makalah / Laporan', isCompleted: true),
          GroupTaskProgress(title: 'Pembuatan Slide Presentasi', isCompleted: false),
          GroupTaskProgress(title: 'Review Akhir & Pengumpulan', isCompleted: false),
        ];

  double get progress {
    if (tasks.isEmpty) return 0.0;
    return tasks.where((t) => t.isCompleted).length / tasks.length;
  }
}

class GroupsScreen extends StatefulWidget {
  final bool canManage;

  const GroupsScreen({super.key, this.canManage = true});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late List<EnhancedGroupItem> _groups;

  @override
  void initState() {
    super.initState();
    _initGroups();
  }

  void _initGroups() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();
    _groups = [
      EnhancedGroupItem(
        id: 'grp_1',
        namaKelompok: 'Kelompok 1 - The Communicators',
        courseName: 'Pendidikan Kewarganegaraan',
        assignmentTitle: 'Makalah Analisis HAM & Demokrasi',
        linkGDrive: 'https://drive.google.com',
        members: students.take(4).toList(),
        tasks: [
          GroupTaskProgress(title: 'Riset Topik & Studi Literatur', isCompleted: true),
          GroupTaskProgress(title: 'Penyusunan Bab 1 & 2', isCompleted: true),
          GroupTaskProgress(title: 'Pembuatan Slide Canva', isCompleted: true),
          GroupTaskProgress(title: 'Simulasi Presentasi Tim', isCompleted: false),
        ],
      ),
      EnhancedGroupItem(
        id: 'grp_2',
        namaKelompok: 'Kelompok 2 - Public Relations Squad',
        courseName: 'Dasar-Dasar Ilmu Komunikasi',
        assignmentTitle: 'Analisis Studi Kasus Komunikasi Massa',
        linkGDrive: 'https://drive.google.com',
        members: students.skip(4).take(4).toList(),
        tasks: [
          GroupTaskProgress(title: 'Penentuan Kasus Komunikasi', isCompleted: true),
          GroupTaskProgress(title: 'Wawancara Narasumber', isCompleted: false),
          GroupTaskProgress(title: 'Penyusunan Laporan Proyek', isCompleted: false),
        ],
      ),
      EnhancedGroupItem(
        id: 'grp_3',
        namaKelompok: 'Kelompok 3 - Media Research Lab',
        courseName: 'Pengantar Jurnalistik',
        assignmentTitle: 'Produksi Buletin Kampus Edisi 1',
        linkGDrive: 'https://drive.google.com',
        members: students.skip(8).take(4).toList(),
        tasks: [
          GroupTaskProgress(title: 'Liputan Berita Kampus', isCompleted: true),
          GroupTaskProgress(title: 'Editing Artikel & Tata Letak', isCompleted: false),
          GroupTaskProgress(title: 'Proofreading & Cetak Mockup', isCompleted: false),
        ],
      ),
    ];
  }

  Future<void> _openDrive(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final assignmentController = TextEditingController();
    String selectedCourse = DummyData.courses.first.nama;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.groups_rounded, color: Color(0xFF5B3DE8), size: 22),
              SizedBox(width: 8),
              Text('Bentuk Kelompok Tugas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kelompok',
                      hintText: 'Misal: Kelompok 4 - Jurnalis Muda',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourse = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: assignmentController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas / Proyek',
                      hintText: 'Misal: Laporan Observasi Lapangan',
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
                final name = nameController.text.trim();
                final assignment = assignmentController.text.trim();
                if (name.isEmpty || assignment.isEmpty) return;

                final randomMembers = DummyData.students.where((s) => s.role != 'ADMIN').toList()..shuffle();

                setState(() {
                  _groups.insert(
                    0,
                    EnhancedGroupItem(
                      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
                      namaKelompok: name,
                      courseName: selectedCourse,
                      assignmentTitle: assignment,
                      linkGDrive: 'https://drive.google.com',
                      members: randomMembers.take(4).toList(),
                    ),
                  );
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kelompok tugas baru berhasil dibentuk!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bentuk Tim'),
            ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Tugas Kelompok & Tim',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (widget.canManage)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _showCreateGroupDialog,
                icon: const Icon(Icons.group_add_rounded, size: 18, color: Color(0xFF5B3DE8)),
                label: const Text('Tambah Tim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showCreateGroupDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tambah Kelompok', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _groups.length,
        itemBuilder: (context, i) {
          final group = _groups[i];
          final doneTasks = group.tasks.where((t) => t.isCompleted).length;
          final totalTasks = group.tasks.length;
          final pct = group.progress;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF5B3DE8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.namaKelompok,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${group.courseName} • ${group.assignmentTitle}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress Tugas Tim:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                    Text('$doneTasks/$totalTasks Selesai (${(pct * 100).toInt()}%)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct == 1.0 ? const Color(0xFF10B981) : const Color(0xFF5B3DE8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tasks Checklist
                const Text('Checklist Sub-Tugas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                for (var task in group.tasks) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        task.isCompleted = !task.isCompleted;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: task.isCompleted ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: task.isCompleted ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Members List
                const Text('Anggota Tim:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: group.members.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.12),
                            child: Text(m.nama[0], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8))),
                          ),
                          const SizedBox(width: 6),
                          Text(m.nama.split(' ').first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (group.linkGDrive != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openDrive(group.linkGDrive!),
                      icon: const Icon(Icons.folder_shared_outlined, size: 16),
                      label: const Text('Buka Folder Google Drive Tugas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B3DE8),
                        side: const BorderSide(color: Color(0xFF5B3DE8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
