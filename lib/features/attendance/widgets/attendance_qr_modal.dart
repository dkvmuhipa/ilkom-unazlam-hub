import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/qr_widget.dart';
import '../../../core/widgets/scale_button.dart';
import '../models/attendance_models.dart';
import '../services/dynamic_attendance_service.dart';
import 'attendance_projector_view.dart';

/// Ultra-modern modal presenting the active attendance session's QR code,
/// dynamic rolling token & PIN, anti-cheat rotation timer, live countdown,
/// projector mode toggle, and attended roster count.
class AttendanceQrModal {
  static void show(
    BuildContext context, {
    required ActiveAttendanceSession active,
    VoidCallback? onClosed,
  }) {
    if (active.isExpired) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttendanceQrModalContent(
        active: active,
        onClosed: onClosed,
      ),
    );
  }
}

class _AttendanceQrModalContent extends StatefulWidget {
  final ActiveAttendanceSession active;
  final VoidCallback? onClosed;

  const _AttendanceQrModalContent({
    required this.active,
    this.onClosed,
  });

  @override
  State<_AttendanceQrModalContent> createState() => _AttendanceQrModalContentState();
}

class _AttendanceQrModalContentState extends State<_AttendanceQrModalContent> {
  Timer? _ticker;
  bool _isDynamicMode = true;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.active.isExpired) {
        _ticker?.cancel();
        Navigator.maybePop(context);
        widget.onClosed?.call();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _copy(String label, String val) {
    Clipboard.setData(ClipboardData(text: val));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label "$val" berhasil disalin!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openProjectorMode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceProjectorView(
          active: widget.active,
          initialDynamicMode: _isDynamicMode,
          onClosed: widget.onClosed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secsLeft = active.remainingSeconds;
    final isUrgent = secsLeft < 180;

    final totalDuration = active.expiresAt.difference(active.startTime).inSeconds;
    final durationSanitized = totalDuration > 0 ? totalDuration : 900;
    final progress = (secsLeft / durationSanitized).clamp(0.0, 1.0);

    // Hitung dynamic rolling data jika mode anti-kecurangan aktif
    final dynamicInfo = _isDynamicMode
        ? DynamicAttendanceService.generate(active)
        : null;

    final effectiveQrData = _isDynamicMode ? dynamicInfo!.qrPayload : active.token;
    final effectivePin = _isDynamicMode ? dynamicInfo!.dynamicPin : active.pinCode;
    final effectiveToken = _isDynamicMode ? dynamicInfo!.dynamicToken : active.token;

    final windowSecs = dynamicInfo?.secondsRemaining ?? 30;
    final windowProgress = dynamicInfo?.progress ?? 1.0;

    final Color timerColor = windowSecs > 10
        ? const Color(0xFF10B981)
        : (windowSecs > 4 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pertemuan ${active.pertemuanKe} • QR Sesi Presensi Aktif',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol Mode Layar Lebar Proyektor
              ScaleButton(
                scaleDown: 0.92,
                onTap: () => _openProjectorMode(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cast_connected_rounded, size: 14, color: Color(0xFF6D28D9)),
                      SizedBox(width: 5),
                      Text(
                        'Layar Lebar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Anti-Fraud Mode Switch Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isDynamicMode
                  ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isDark ? const Color(0xFF252538) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDynamicMode
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isDynamicMode ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                  size: 18,
                  color: _isDynamicMode ? const Color(0xFF059669) : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isDynamicMode ? 'Mode Anti-Kecurangan Aktif' : 'Mode Statis (Standar)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isDynamicMode
                              ? const Color(0xFF059669)
                              : (isDark ? Colors.white : Colors.grey.shade800),
                        ),
                      ),
                      Text(
                        _isDynamicMode
                            ? 'QR & PIN berputar tiap 30s (Anti-Screenshot)'
                            : 'QR & PIN tetap sama selama sesi 15 menit',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isDynamicMode,
                  onChanged: (val) {
                    setState(() => _isDynamicMode = val);
                  },
                  activeThumbColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // QR Box with Dynamic Rotation Ring indicator
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isDynamicMode
                        ? timerColor.withValues(alpha: 0.6)
                        : (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                    width: _isDynamicMode ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    if (_isDynamicMode)
                      BoxShadow(
                        color: timerColor.withValues(alpha: 0.2),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: QrCodeWidget(
                  data: effectiveQrData,
                  size: 200,
                ),
              ),
            ],
          ),

          // Dynamic 30s Countdown Bar
          if (_isDynamicMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      value: windowProgress,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Penyegaran kode dalam $windowSecs detik',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Token & PIN Copyable Chips
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  onTap: () => _copy('Token', effectiveToken),
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252538) : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.vpn_key_rounded, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDynamicMode ? 'TOKEN DINAMIS' : 'TOKEN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              effectiveToken,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScaleButton(
                  onTap: () => _copy('PIN', effectivePin),
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252538) : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pin_rounded, size: 15, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDynamicMode ? 'PIN DINAMIS' : 'PIN CEPAT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              effectivePin,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Attendance Status and Countdown Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF6D28D9)),
                    const SizedBox(width: 6),
                    Text(
                      '${active.attendedNims.length} Mahasiswa Hadir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.2,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa Sesi: ${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _isDynamicMode
                ? 'QR Code & PIN berputar otomatis tiap 30 detik. Mencegah mahasiswa memfoto untuk rekan yang titip absen.'
                : 'Sorotkan ke layar proyektor kelas atau bagikan PIN 4 digit kepada rekan mahasiswa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
