import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

/// Ultra-modern, prestigious digital student card (KTM Smart Card)
/// featuring EMV gold chip, holographic glass sheen, role badge,
/// interactive tap-to-copy NIM, and dynamic photo edit trigger.
class DigitalKtmCard extends StatelessWidget {
  final StudentProfile student;
  final bool isDark;
  final String? currentAvatarUrl;
  final bool isUpdatingAvatar;
  final Widget Function(String? avatarUrl, String initials) avatarBuilder;
  final VoidCallback onChangeAvatar;
  final VoidCallback onOpenQrKtm;

  const DigitalKtmCard({
    super.key,
    required this.student,
    required this.isDark,
    required this.currentAvatarUrl,
    required this.isUpdatingAvatar,
    required this.avatarBuilder,
    required this.onChangeAvatar,
    required this.onOpenQrKtm,
  });

  void _copyNim(BuildContext context) {
    Clipboard.setData(ClipboardData(text: student.nim));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('NIM ${student.nim} berhasil disalin ke clipboard! 📋'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parts = student.nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (student.nama.length >= 2 ? student.nama.substring(0, 2).toUpperCase() : 'M');

    final roleBadgeText = student.isAdmin
        ? 'System Administrator'
        : (student.isKetuaKelas
            ? 'Ketua Kelas ILKOM 2026'
            : (student.isBendahara
                ? 'Bendahara Kelas ILKOM 2026'
                : (student.isSekretaris
                    ? 'Sekretaris Kelas ILKOM 2026'
                    : (student.jabatan.isNotEmpty && student.jabatan != 'Mahasiswa'
                        ? '${student.jabatan} ILKOM 2026'
                        : 'Mahasiswa ILKOM 2026'))));

    final roleColor = student.isAdmin
        ? const Color(0xFF6366F1)
        : (student.isKetuaKelas
            ? const Color(0xFFF59E0B)
            : (student.isBendahara ? const Color(0xFF10B981) : const Color(0xFF38BDF8)));

    return ScaleButton(
      onTap: onOpenQrKtm,
      scaleDown: 0.985,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF1E1B4B),
                  ]
                : const [
                    Color(0xFF58138A),
                    Color(0xFF6D28D9),
                    Color(0xFF312E81),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: isDark ? 0.35 : 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Watermark Big Seal Background
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Icon(
                Icons.school_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Row: University Logo, FISIP text & EMV Chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UNAZLAM PALU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'FAKULTAS ILMU SOSIAL & POLITIK',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Aktif LED Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF34D399), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF34D399), size: 7),
                            SizedBox(width: 5),
                            Text(
                              'AKTIF',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // EMV Gold Chip Icon & Wireless Contactless Sensor
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFBBF24), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 14,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF78350F), width: 0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Center(
                              child: Divider(
                                color: const Color(0xFF78350F),
                                thickness: 0.6,
                                height: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.rotate(
                        angle: 1.57,
                        child: const Icon(
                          Icons.wifi_rounded,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Avatar Center with Edit Badge
                  Center(
                    child: Column(
                      children: [
                        ScaleButton(
                          onTap: onChangeAvatar,
                          scaleDown: 0.94,
                          child: Stack(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: avatarBuilder(currentAvatarUrl ?? student.avatarUrl, initials),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6D28D9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              if (isUpdatingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Student Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          student.nama,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Interactive NIM Chip with tap to copy
                  ScaleButton(
                    onTap: () => _copyNim(context),
                    scaleDown: 0.95,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NIM: ${student.nim}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded, color: Colors.white70, size: 13),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: roleColor.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: roleColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          roleBadgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bio / Motto if set
                  if (student.bio != null && student.bio!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '“${student.bio!}”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Bottom Action Button: Buka QR KTM Digital
                  ScaleButton(
                    onTap: onOpenQrKtm,
                    scaleDown: 0.96,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF6D28D9)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tampilkan QR Code KTM Digital',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
