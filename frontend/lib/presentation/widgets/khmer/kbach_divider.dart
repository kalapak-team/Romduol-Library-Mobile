import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Khmer ornamental (Kbach) divider widget
class KbachDivider extends StatelessWidget {
  final double width;
  final Color color;

  const KbachDivider({
    super.key,
    this.width = double.infinity,
    this.color = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 20,
      child: CustomPaint(painter: _KbachPainter(color)),
    );
  }
}

class _KbachPainter extends CustomPainter {
  final Color color;
  _KbachPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cy = size.height / 2;
    final segments = (size.width / 20).floor();

    for (int i = 0; i < segments; i++) {
      final x = i * (size.width / segments);
      final segW = size.width / segments;
      final cx = x + segW / 2;

      // Simple lotus petal motif
      final path = Path()
        ..moveTo(x, cy)
        ..cubicTo(x + segW * 0.25, cy - 5, cx - segW * 0.1, cy - 7, cx, cy - 5)
        ..cubicTo(
          cx + segW * 0.1,
          cy - 7,
          x + segW * 0.75,
          cy - 5,
          x + segW,
          cy,
        );

      canvas.drawPath(path, paint);
    }

    // Center line
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      paint..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_KbachPainter old) => old.color != color;
}
