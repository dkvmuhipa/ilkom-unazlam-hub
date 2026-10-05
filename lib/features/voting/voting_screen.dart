import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PollOption {
  final String id;
  final String text;
  int votes;
  final List<String> votersNim;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    List<String>? votersNim,
  }) : votersNim = votersNim ?? [];
}

class ClassPoll {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime createdAt;
  final DateTime endsAt;
  bool isOpen;
  final List<PollOption> options;
  String? userVotedId;

  ClassPoll({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.createdAt,
    required this.endsAt,
    this.isOpen = true,
    required this.options,
    this.userVotedId,
  });

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.votes);
}

class VotingScreen extends StatefulWidget {
  final bool canManage;
  final String currentNim;
  final VoidCallback? onBack;

  const VotingScreen({
    super.key,
    this.canManage = false,
    this.currentNim = '260250023',
    this.onBack,
  });

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final List<ClassPoll> _polls = [
    ClassPoll(
      id: 'poll_1',
      title: '👕 Pemilihan Warna PDH / Kaos Angkatan ILKOM 2026',
      description: 'Silakan pilih warna dasar kemeja PDH angkatan kita untuk kegiatan resmi kampus.',
      author: 'Nur Farida (Ketua Kelas)',
      createdAt: DateTime(2026, 10, 1),
      endsAt: DateTime(2026, 10, 10),
      isOpen: true,
      options: [
        PollOption(id: 'opt_1', text: 'Navy Blue & Aksen Emas', votes: 14),
        PollOption(id: 'opt_2', text: 'Olive Green & Putih', votes: 8),
        PollOption(id: 'opt_3', text: 'Hitam Pekat & Abu-abu Silver', votes: 3),
      ],
      userVotedId: 'opt_1',
    ),
    ClassPoll(
      id: 'poll_2',
      title: '📅 Jadwal Pengganti Kuliah Pengantar Ilmu Komunikasi',
      description: 'Dosen meminta pengganti sesi kuliah hari Kamis yang libur nasional.',
      author: 'Nur Farida (Ketua Kelas)',
      createdAt: DateTime(2026, 10, 3),
      endsAt: DateTime(2026, 10, 7),
      isOpen: true,
      options: [
        PollOption(id: 'opt_a', text: 'Sabtu, 09:00 - 11:30 WITA (Virtual Zoom)', votes: 18),
        PollOption(id: 'opt_b', text: 'Senin Sore, 16:00 - 18:00 WITA (Tatap Muka Lab)', votes: 7),
      ],
    ),
    ClassPoll(
      id: 'poll_3',
      title: '⛺ Lokasi Makrab & Keakraban Mahasiswa',
      description: 'Voting lokasi kegiatan malam keakraban angkatan di akhir semester 1.',
      author: 'Nur Farida (Ketua Kelas)',
      createdAt: DateTime(2026, 9, 20),
      endsAt: DateTime(2026, 9, 28),
      isOpen: false,
      options: [
        PollOption(id: 'opt_x', text: 'Villa Puncak Baturaden (Terpilih)', votes: 21),
        PollOption(id: 'opt_y', text: 'Pantai Menganti Kebumen', votes: 4),
      ],
    ),
  ];

  void _showCreatePollDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.how_to_vote_rounded, color: Color(0xFF5B3DE8), size: 22),
              SizedBox(width: 8),
              Text('Buat Voting Kelas Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                      labelText: 'Judul Polling / Voting',
                      hintText: 'Misal: Pemilihan Tempat Makrab',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Keterangan Singkat',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilihan Opsi:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (int i = 0; i < optionControllers.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionControllers[i],
                              decoration: InputDecoration(
                                hintText: 'Opsi ${i + 1}',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          if (optionControllers.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                              onPressed: () => setDialogState(() => optionControllers.removeAt(i)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (optionControllers.length < 5)
                    TextButton.icon(
                      onPressed: () => setDialogState(() => optionControllers.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Opsi Lain'),
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
                final validOptions = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                if (title.isEmpty || validOptions.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul dan minimal 2 opsi wajib diisi!')),
                  );
                  return;
                }

                setState(() {
                  _polls.insert(
                    0,
                    ClassPoll(
                      id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      description: descController.text.trim(),
                      author: 'Ketua Kelas',
                      createdAt: DateTime.now(),
                      endsAt: DateTime.now().add(const Duration(days: 7)),
                      isOpen: true,
                      options: validOptions.asMap().entries.map((e) {
                        return PollOption(id: 'opt_${e.key}', text: e.value, votes: 0);
                      }).toList(),
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voting kelas berhasil diterbitkan!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terbitkan Voting'),
            ),
          ],
        ),
      ),
    );
  }

  void _castVote(ClassPoll poll, PollOption option) {
    if (!poll.isOpen) return;

    setState(() {
      if (poll.userVotedId != null) {
        // Remove previous vote
        final prevOpt = poll.options.firstWhere((o) => o.id == poll.userVotedId);
        prevOpt.votes = (prevOpt.votes - 1).clamp(0, 999);
      }
      option.votes += 1;
      poll.userVotedId = option.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Suara Anda berhasil dicatat untuk: ${option.text}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
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
          'Voting & Polling Kelas',
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
                onPressed: _showCreatePollDialog,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF5B3DE8)),
                label: const Text('Buat Voting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
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
              onPressed: _showCreatePollDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Voting Baru', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _polls.length,
        itemBuilder: (context, i) {
          final poll = _polls[i];
          final total = poll.totalVotes;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: poll.isOpen ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
              ),
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
                // Header badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: poll.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        poll.isOpen ? '🟢 AKTIF' : '⚪ SELESAI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: poll.isOpen ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total $total Suara Mahasiswa',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (widget.canManage && poll.isOpen)
                      InkWell(
                        onTap: () => setState(() => poll.isOpen = false),
                        child: const Text('Tutup', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title & Description
                Text(
                  poll.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
                if (poll.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    poll.description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
                  ),
                ],
                const SizedBox(height: 14),

                // Options List
                for (var opt in poll.options) ...[
                  Builder(
                    builder: (context) {
                      final pct = total == 0 ? 0.0 : (opt.votes / total);
                      final isSelected = poll.userVotedId == opt.id;

                      return InkWell(
                        onTap: poll.isOpen ? () => _castVote(poll, opt) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF3F0FF) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opt.text,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${opt.votes} (${(pct * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 4),
                Text(
                  'Dibuat oleh ${poll.author}',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
