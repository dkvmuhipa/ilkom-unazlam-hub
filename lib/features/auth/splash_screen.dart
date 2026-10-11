import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Content: Logo & Tagline (Screen 1)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo UNAZLAM
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFEFF6FF),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF1E40AF),
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Branding Text
                const Text(
                  'ILMU KOMUNIKASI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E40AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'UNAZLAM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF59E0B),
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline matching Screen 1
                const Text(
                  'Satu Kelas, Banyak Cerita.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Lebih Banyak Karya.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Organic Wave Shapes (Purple & Yellow matching Screen 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: CustomPaint(
              painter: _SplashWavesPainter(),
              size: const Size(double.infinity, 220),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw overlapping organic ribbons (Screen 1)
class _SplashWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Golden Yellow wave
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    final yellowPath = Path();
    yellowPath.moveTo(0, size.height * 0.45);
    yellowPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.70,
      size.width * 0.85,
      size.height,
    );
    yellowPath.lineTo(0, size.height);
    yellowPath.close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 2. Royal Purple front curved ribbon
    final purplePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E40AF), Color(0xFF755BF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final purplePath = Path();
    purplePath.moveTo(size.width * 0.35, size.height);
    purplePath.cubicTo(
      size.width * 0.45,
      size.height * 0.35,
      size.width * 0.85,
      size.height * 0.20,
      size.width,
      size.height * 0.50,
    );
    purplePath.lineTo(size.width, size.height);
    purplePath.close();
    canvas.drawPath(purplePath, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
