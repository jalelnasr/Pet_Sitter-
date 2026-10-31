import 'package:flutter/material.dart';

import 'package:pet_sitter/core/theme/app_theme.dart';

/// Petite illustration d'état vide (loupe + empreinte).
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({super.key, this.size = 140});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _EmptyPainter());
}

class _EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    c.drawCircle(Offset(u * 50, u * 52), u * 44, Paint()..color = LP.accentSoft);
    final st = Paint()
      ..color = LP.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 3.2
      ..strokeCap = StrokeCap.round;
    c.drawCircle(Offset(u * 45, u * 46), u * 20, Paint()..color = LP.bg);
    c.drawCircle(Offset(u * 45, u * 46), u * 20, st);
    c.drawLine(Offset(u * 60, u * 61), Offset(u * 74, u * 75), st..strokeWidth = u * 5);
    final p = Paint()..color = LP.accent;
    c.drawOval(Rect.fromCenter(center: Offset(u * 45, u * 51), width: u * 12, height: u * 9), p);
    for (var i = -1; i <= 1; i++) {
      c.drawCircle(Offset(u * (45 + i * 6), u * (i == 0 ? 40 : 42.5)), u * 2.7, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
