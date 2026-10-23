import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/saas_components.dart';
import '../../models/models.dart';
import '../../core/services/safe_launcher.dart';

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
          GroupTaskProgress(title: 'Riset Topik & Studi Literatur'),
          GroupTaskProgress(title: 'Penyusunan Makalah / Laporan'),
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
  final String userClass;
  final VoidCallback? onBack;

  const GroupsScreen({super.key, required this.userClass, this.canManage = false, this.onBack});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<EnhancedGroupItem> _groups = [];
  List<Course> _courses = [];
  List<StudentProfile> _students = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseRepository.getStudentGroups(),
        SupabaseRepository.getCourses(),
        SupabaseRepository.getClassDirectory(),
      ]);
      if (!mounted) return;
      final directoryStudents = results[2] as List<StudentProfile>;
      final studentByNim = {
        for (final s in directoryStudents) s.nim: s,
      };
      final groups = (results[0] as List<Map<String, dynamic>>).map((row) {
        final memberRows = (row['members'] as List? ?? const []).cast<Map>();
        final taskRows = (row['tasks'] as List? ?? const []).cast<Map>();
        return EnhancedGroupItem(
          id: row['id'].toString(),
          namaKelompok: row['group_name']?.toString() ?? 'Kelompok',
          courseName: row['course_name']?.toString() ?? '',
          assignmentTitle: row['assignment_title']?.toString() ?? '',
          linkGDrive: row['drive_url']?.toString(),
          members: memberRows.map((m) {
            final nim = m['nim']?.toString() ?? '';
            final matched = studentByNim[nim];
            if (matched != null) return matched;
            return StudentProfile(
              id: nim,
              nim: nim,
              nama: m['nama']?.toString() ?? (nim.isNotEmpty ? nim : 'Mahasiswa'),
              email: '',
              noWa: '',
            );
          }).toList(),
          tasks: taskRows.map((t) => GroupTaskProgress(title: t['title']?.toString() ?? '', isCompleted: t['is_completed'] == true)).toList(),
        );
      }).toList();
      final crs = results[1] as List<Course>;
      final stds = widget.canManage
          ? directoryStudents.where((s) => s.role != 'ADMIN' && s.kelas == widget.userClass).toList()
          : <StudentProfile>[];
      setState(() {
        _students = stds;
        _courses = crs;
        _groups = groups;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Data kelompok belum tersedia. Pastikan migrasi Supabase kelompok sudah diterapkan.';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kelompok belum dapat dimuat: $e')));
      }
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final assignmentController = TextEditingController();
    final linkController = TextEditingController(text: 'https://drive.google.com');
    String selectedCourse = _courses.isNotEmpty ? _courses.first.nama : 'Pendidikan Kewarganegaraan';
    final nonAdminStudents = _students;
    List<StudentProfile> selectedMembers = nonAdminStudents.take(4).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.groups_rounded, color: Color(0xFF6D28D9), size: 22),
              SizedBox(width: 8),
              Text('Bentuk Kelompok Tugas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 96).clamp(0.0, 420.0).toDouble(),
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
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Folder Google Drive / Dokumen',
                      hintText: 'https://drive.google.com/...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final title = const Text(
                        'Pilih Anggota (${4} Rekomendasi):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      );
                      final shuffleButton = TextButton(
                        onPressed: () {
                          final shuffled = List<StudentProfile>.from(nonAdminStudents)..shuffle();
                          setDialogState(() {
                            selectedMembers = shuffled.take(4).toList();
                          });
                        },
                        child: const Text('Acak Anggota', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                      );
                      if (constraints.maxWidth < 340) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, Align(alignment: Alignment.centerRight, child: shuffleButton)]);
                      }
                      return Row(children: [Expanded(child: title), shuffleButton]);
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: nonAdminStudents.length,
                      itemBuilder: (context, idx) {
                        final student = nonAdminStudents[idx];
                        final isPicked = selectedMembers.any((m) => m.id == student.id);
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(student.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: Text('NIM: ${student.nim}', style: const TextStyle(fontSize: 10)),
                          value: isPicked,
                          activeColor: const Color(0xFF6D28D9),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedMembers.add(student);
                              } else {
                                selectedMembers.removeWhere((m) => m.id == student.id);
                              }
                            });
                          },
                        );
                      },
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
              onPressed: () async {
                final name = nameController.text.trim();
                final assignment = assignmentController.text.trim();
                final driveLink = linkController.text.trim();
                if (name.isEmpty || assignment.isEmpty) return;
                if (selectedMembers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu anggota.')));
                  return;
                }
                try {
                  await SupabaseRepository.createStudentGroup(
                    name: name,
                    courseName: selectedCourse,
                    assignmentTitle: assignment,
                    driveUrl: driveLink.isEmpty ? null : driveLink,
                    memberNims: selectedMembers.map((s) => s.nim).toSet().toList(),
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  await _loadData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelompok berhasil dibentuk.'), backgroundColor: Color(0xFF10B981)));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membentuk kelompok: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
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

  void _shareAllGroupsToWhatsApp() {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada kelompok untuk dibagikan.')),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('*🤝 DAFTAR PEMBAGIAN KELOMPOK TUGAS*');
    buffer.writeln('*PRODI ILMU KOMUNIKASI UNAZLAM*');
    buffer.writeln('────────────────────────────');
    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      final pct = (g.progress * 100).toInt();
      buffer.writeln('\n*${i + 1}. ${g.namaKelompok}* ($pct% Selesai)');
      buffer.writeln('📚 MK: ${g.courseName}');
      buffer.writeln('📝 Tugas: ${g.assignmentTitle}');
      if (g.members.isNotEmpty) {
        buffer.writeln('👥 Anggota:');
        for (final m in g.members) {
          final pem = (m.peminatan.isNotEmpty && m.peminatan != '-')
              ? ' [${m.peminatan}]'
              : '';
          buffer.writeln('   • ${m.nama}$pem');
        }
      }
      if (g.linkGDrive != null && g.linkGDrive!.trim().isNotEmpty) {
        buffer.writeln('🔗 Folder: ${g.linkGDrive}');
      }
    }
    buffer.writeln('\n────────────────────────────');
    buffer.writeln('_Dibagikan dari ILKOM UNAZLAM Hub_');

    final text = buffer.toString();
    Clipboard.setData(ClipboardData(text: text));
    final encoded = Uri.encodeComponent(text);
    safeLaunchUrl('https://wa.me/?text=$encoded');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rekap kelompok disalin & membuka WhatsApp!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showSmartGroupGeneratorDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data mahasiswa kelas belum tersedia.')),
      );
      return;
    }
    final assignmentCtrl = TextEditingController(text: 'Tugas Kelompok Terpadu');
    String selectedCourse = _courses.isNotEmpty
        ? _courses.first.nama
        : 'Dasar-Dasar Ilmu Komunikasi';
    int groupCount = (_students.length / 4).ceil().clamp(2, 10);
    String mode = 'balanced'; // 'balanced' | 'random'
    bool isGenerating = false;

    List<List<StudentProfile>> buildPreviewGroups() {
      final pool = List<StudentProfile>.from(_students);
      if (mode == 'random') {
        pool.shuffle();
      } else {
        // Urutkan berdasarkan peminatan agar terdistribusi merata (round-robin)
        pool.sort((a, b) => a.peminatan.compareTo(b.peminatan));
      }
      final buckets = List.generate(groupCount, (_) => <StudentProfile>[]);
      for (int i = 0; i < pool.length; i++) {
        buckets[i % groupCount].add(pool[i]);
      }
      return buckets;
    }

    List<List<StudentProfile>> previewBuckets = buildPreviewGroups();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6D28D9), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Group Generator',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 80).clamp(0.0, 440.0).toDouble(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagi seluruh mahasiswa kelas secara otomatis & adil hanya dalam 1 klik.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.nama,
                            child: Text(
                              c.nama,
                              style: const TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourse = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: assignmentCtrl,
                    decoration: InputDecoration(
                      labelText: 'Judul Proyek / Tugas Kelompok',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: groupCount,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Tim',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(9, (idx) => idx + 2)
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n Kelompok'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                groupCount = val;
                                previewBuckets = buildPreviewGroups();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: mode,
                          decoration: InputDecoration(
                            labelText: 'Metode Bagi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'balanced',
                              child: Text('Seimbang Peminatan', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'random',
                              child: Text('Acak Murni', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                mode = val;
                                previewBuckets = buildPreviewGroups();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pratinjau ($groupCount Tim • ${_students.length} Mahasiswa):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            previewBuckets = buildPreviewGroups();
                          });
                        },
                        icon: const Icon(Icons.casino_rounded, size: 15),
                        label: const Text('Kocok Ulang', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.builder(
                      itemCount: previewBuckets.length,
                      itemBuilder: (context, idx) {
                        final members = previewBuckets[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelompok ${idx + 1} (${members.length} orang)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6D28D9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                members.map((m) => m.nama).join(', '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: isGenerating
                  ? null
                  : () async {
                      final title = assignmentCtrl.text.trim().isEmpty
                          ? 'Tugas Kelompok'
                          : assignmentCtrl.text.trim();
                      setDialogState(() => isGenerating = true);
                      try {
                        for (int i = 0; i < previewBuckets.length; i++) {
                          final bucket = previewBuckets[i];
                          if (bucket.isEmpty) continue;
                          await SupabaseRepository.createStudentGroup(
                            name: 'Kelompok ${i + 1}',
                            courseName: selectedCourse,
                            assignmentTitle: title,
                            driveUrl: null,
                            memberNims: bucket.map((s) => s.nim).toList(),
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$groupCount kelompok berhasil dibuat otomatis!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isGenerating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membuat kelompok otomatis: $e')),
                          );
                        }
                      }
                    },
              icon: isGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: Text(isGenerating ? 'Menyimpan...' : 'Simpan Semua Tim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Tugas Kelompok & Tim',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_groups.isNotEmpty)
            IconButton(
              onPressed: _shareAllGroupsToWhatsApp,
              icon: const Icon(Icons.share_rounded, color: Color(0xFF10B981), size: 20),
              tooltip: 'Bagikan Daftar Kelompok ke WhatsApp',
            ),
          if (widget.canManage)
            IconButton(
              onPressed: _showSmartGroupGeneratorDialog,
              icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6D28D9), size: 21),
              tooltip: 'Smart Group Generator (Bagi Kelompok Otomatis)',
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? EmptyStateWidget(
                  icon: Icons.cloud_off_rounded,
                  title: 'Kelompok Belum Dapat Dimuat',
                  subtitle: _loadError!,
                  actionLabel: 'Coba Lagi',
                  onAction: _loadData,
                )
          : _groups.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.groups_rounded,
                  title: widget.canManage ? 'Belum Ada Kelompok Tugas' : 'Anda Belum Tergabung',
                  subtitle: widget.canManage
                      ? 'Bentuk kelompok tugas agar anggota dapat melihat progresnya.'
                      : 'Kelompok akan tampil setelah pengurus mendaftarkan NIM Anda sebagai anggota.',
                  actionLabel: widget.canManage ? 'Tambah Kelompok' : null,
                  onAction: widget.canManage ? _showCreateGroupDialog : null,
                )
              : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _groups.length + (widget.canManage ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _groups.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Manual'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showSmartGroupGeneratorDialog,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Bagi Kelompok Otomatis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6D28D9),
                      side: const BorderSide(color: Color(0xFF6D28D9)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
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
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF6D28D9), size: 22),
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
                    if (widget.canManage)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
                        tooltip: 'Hapus Kelompok',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await SupabaseRepository.deleteStudentGroup(group.id);
                            if (!mounted) return;
                            setState(() => _groups.removeWhere((g) => g.id == group.id));
                            messenger.showSnackBar(const SnackBar(content: Text('Kelompok telah dihapus.'), duration: Duration(seconds: 1)));
                          } catch (e) {
                            if (mounted) messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus kelompok: $e')));
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress Tugas Tim:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                    Text('$doneTasks/$totalTasks Selesai (${(pct * 100).toInt()}%)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9))),
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
                      pct == 1.0 ? const Color(0xFF10B981) : const Color(0xFF6D28D9),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tasks Checklist
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Checklist Sub-Tugas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    if (widget.canManage)
                      InkWell(
                        onTap: () {
                          final taskController = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Tambah Sub-Tugas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              content: TextField(
                                controller: taskController,
                                decoration: InputDecoration(
                                  hintText: 'Misal: Analisis data survei',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                ElevatedButton(
                                  onPressed: () async {
                                    final t = taskController.text.trim();
                                    if (t.isNotEmpty) {
                                      group.tasks.add(GroupTaskProgress(title: t, isCompleted: false));
                                      await _persistTasks(group);
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), foregroundColor: Colors.white),
                                  child: const Text('Tambah'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('+ Tambah Sub-Tugas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var task in group.tasks) ...[
                  InkWell(
                    onTap: () async {
                      setState(() => task.isCompleted = !task.isCompleted);
                      await _persistTasks(group);
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
                          SaaSAvatar(
                            name: m.nama,
                            avatarUrl: m.avatarUrl,
                            size: 20,
                            fontSize: 9,
                            radius: 10,
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
                      onPressed: () => safeLaunchUrl(group.linkGDrive!),
                      icon: const Icon(Icons.folder_shared_outlined, size: 16),
                      label: const Text('Buka Folder Google Drive Tugas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6D28D9),
                        side: const BorderSide(color: Color(0xFF6D28D9)),
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

  Future<void> _persistTasks(EnhancedGroupItem group) async {
    try {
      await SupabaseRepository.updateStudentGroupTasks(
        groupId: group.id,
        tasks: group.tasks.map((t) => {'title': t.title, 'is_completed': t.isCompleted}).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan checklist: $e')));
      await _loadData();
    }
  }
}
