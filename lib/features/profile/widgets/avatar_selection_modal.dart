import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/models.dart';

class AvatarSelectionModal {
  static void show(
    BuildContext context, {
    required StudentProfile student,
    required bool isDark,
    required String? currentAvatarUrl,
    required Widget Function(String? avatarUrl, String initials) avatarBuilder,
    required Future<void> Function(ImageSource source) onPickImage,
    required Future<void> Function(String url) onApplyPreset,
    required Future<void> Function() onResetDefault,
  }) {
    final parts = student.nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (student.nama.length >= 2 ? student.nama.substring(0, 2).toUpperCase() : 'M');

    final presets = [
      {
        'label': 'Mahasiswa 1',
        'url': 'https://api.dicebear.com/7.x/micah/png?seed=Alex&backgroundColor=b6e3f4',
      },
      {
        'label': 'Mahasiswi 1',
        'url': 'https://api.dicebear.com/7.x/micah/png?seed=Sarah&backgroundColor=ffd5dc',
      },
      {
        'label': 'Mahasiswa 2',
        'url': 'https://api.dicebear.com/7.x/micah/png?seed=Felix&backgroundColor=d1d4f9',
      },
      {
        'label': 'Mahasiswi 2',
        'url': 'https://api.dicebear.com/7.x/micah/png?seed=Maya&backgroundColor=ffdfbf',
      },
      {
        'label': 'Tech Avatar',
        'url': 'https://api.dicebear.com/7.x/bottts/png?seed=${student.nim}&backgroundColor=c0aede',
      },
      {
        'label': 'Mahasiswi 3',
        'url': 'https://api.dicebear.com/7.x/lorelei/png?seed=Nabila&backgroundColor=ffd5dc',
      },
      {
        'label': 'Mahasiswa 3',
        'url': 'https://api.dicebear.com/7.x/lorelei/png?seed=Dimas&backgroundColor=b6e3f4',
      },
      {
        'label': 'Fun Emoji',
        'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=${student.nim}&backgroundColor=ffe4e6',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: Color(0xFF6D28D9),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ganti Foto Profil',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sesuaikan foto identitas Anda untuk KTM Digital dan profil kelas',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),

              // Preview Foto Saat Ini
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B3B54) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF6D28D9), width: 2),
                        ),
                        child: ClipOval(
                          child: avatarBuilder(currentAvatarUrl ?? student.avatarUrl, initials),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.nama,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NIM: ${student.nim}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentAvatarUrl != null
                                ? 'Foto Kustom Terpasang ✨'
                                : 'Menggunakan Logo Almamater',
                            style: TextStyle(
                              fontSize: 11,
                              color: currentAvatarUrl != null
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Opsi 1: Kamera
              _buildAvatarActionTile(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F3FF),
                title: 'Ambil dari Kamera',
                subtitle: 'Gunakan kamera perangkat untuk mengambil swafoto',
                isDark: isDark,
                onTap: () => onPickImage(ImageSource.camera),
              ),
              const SizedBox(height: 10),

              // Opsi 2: Galeri
              _buildAvatarActionTile(
                icon: Icons.photo_library_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                title: 'Pilih dari Galeri / Berkas',
                subtitle: 'Pilih gambar dari album galeri ponsel atau perangkat Anda',
                isDark: isDark,
                onTap: () => onPickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 10),

              // Opsi 3: Tautkan URL Gambar
              _buildAvatarActionTile(
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.4) : const Color(0xFFF5F3FF),
                title: 'Tautkan URL Gambar Web',
                subtitle: 'Gunakan tautan URL gambar online langsung (HTTPS)',
                isDark: isDark,
                onTap: () => _showUrlAvatarDialog(context, isDark, onApplyPreset),
              ),
              const SizedBox(height: 10),

              // Opsi 4: Reset ke Default Logo Kampus
              if (currentAvatarUrl != null || (student.avatarUrl != null && student.avatarUrl!.isNotEmpty))
                _buildAvatarActionTile(
                  icon: Icons.restore_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBg: isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEF2F2),
                  title: 'Reset ke Logo Kampus',
                  subtitle: 'Gunakan logo resmi kampus sebagai foto identitas',
                  isDark: isDark,
                  onTap: onResetDefault,
                ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    'Pilih Avatar Mahasiswa Instan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final url = preset['url']!;
                  final isSelected = currentAvatarUrl == url || student.avatarUrl == url;

                  return InkWell(
                    onTap: () => onApplyPreset(url),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6D28D9)
                              : (isDark ? const Color(0xFF383850) : const Color(0xFFE5E7EB)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, _) => const Icon(Icons.person, size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset['label']!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : const Color(0xFF374151),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildAvatarActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF28283E) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF383850) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showUrlAvatarDialog(
    BuildContext context,
    bool isDark,
    Future<void> Function(String url) onApplyUrl,
  ) async {
    Navigator.of(context, rootNavigator: true).pop();
    final urlController = TextEditingController();
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded, color: Color(0xFF6D28D9), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Tautkan URL Foto',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tempelkan tautan URL gambar (format .jpg, .png atau tautan web HTTPS):',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'https://images.unsplash.com/...',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.image_outlined, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(
                'Batal',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
                  setDialogState(() {
                    errorText = 'Masukkan tautan URL yang valid (http/https).';
                  });
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Gunakan Foto'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && urlController.text.trim().isNotEmpty) {
      await onApplyUrl(urlController.text.trim());
    }
    urlController.dispose();
  }
}
