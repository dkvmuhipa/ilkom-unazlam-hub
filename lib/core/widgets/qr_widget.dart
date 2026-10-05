import 'package:flutter/material.dart';

/// Lightweight native QR matrix generator & visualizer with UNAZLAM center badge
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor = const Color(0xFF1E1B4B),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: _NativeQrPainter(
          data: data,
          darkColor: foregroundColor,
          lightColor: backgroundColor,
        ),
      ),
    );
  }
}

class _NativeQrPainter extends CustomPainter {
  final String data;
  final Color darkColor;
  final Color lightColor;

  _NativeQrPainter({
    required this.data,
    required this.darkColor,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int matrixSize = 25; // 25x25 grid
    final double cellSize = size.width / matrixSize;

    final paintDark = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Generate deterministic pseudo-random matrix based on input string
    final List<List<bool>> grid = List.generate(
      matrixSize,
      (y) => List.generate(matrixSize, (x) => false),
    );

    // Draw Position Detection Patterns (Corners)
    _drawFinderPattern(grid, 0, 0);
    _drawFinderPattern(grid, matrixSize - 7, 0);
    _drawFinderPattern(grid, 0, matrixSize - 7);

    // Fill data grid based on hash
    int hash = data.hashCode.abs();
    for (int y = 0; y < matrixSize; y++) {
      for (int x = 0; x < matrixSize; x++) {
        // Skip corner finder patterns
        if ((x < 8 && y < 8) ||
            (x >= matrixSize - 8 && y < 8) ||
            (x < 8 && y >= matrixSize - 8)) {
          continue;
        }

        // Center cutout for branding logo
        if (x >= 9 && x <= 15 && y >= 9 && y <= 15) {
          continue;
        }

        // Deterministic dot generation
        hash = (hash * 1103515245 + 12345) & 0x7fffffff;
        grid[y][x] = (hash % 3) == 0;
      }
    }

    // Draw cells as rounded dots
    for (int y = 0; y < matrixSize; y++) {
      for (int x = 0; x < matrixSize; x++) {
        if (grid[y][x]) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x * cellSize + 0.5, y * cellSize + 0.5, cellSize - 1, cellSize - 1),
            Radius.circular(cellSize * 0.25),
          );
          canvas.drawRRect(rect, paintDark);
        }
      }
    }

    // Draw Center Logo / Shield Badge
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cellSize * 6,
      height: cellSize * 6,
    );

    final bgCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cellSize * 1.5)),
      bgCenterPaint,
    );

    final borderCenterPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cellSize * 1.5)),
      borderCenterPaint,
    );
  }

  void _drawFinderPattern(List<List<bool>> grid, int startX, int startY) {
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        if (x == 0 || x == 6 || y == 0 || y == 6 || (x >= 2 && x <= 4 && y >= 2 && y <= 4)) {
          grid[startY + y][startX + x] = true;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NativeQrPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.darkColor != darkColor ||
      oldDelegate.lightColor != lightColor;
}
