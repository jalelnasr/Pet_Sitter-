import 'package:flutter/material.dart';

import 'package:pet_sitter/core/theme/app_theme.dart';

/// Formes noires géantes du guide de bienvenue (empreinte, maison, bulle).
enum BigShape { paw, house, bubble }

class BigShapePainter extends CustomPainter {
  BigShapePainter(this.shape, {this.color = LP.primary, this.cutout = LP.mintBg});
  final BigShape shape;
  final Color color;
  final Color cutout;

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    final ink = Paint()..color = color;
    final hole = Paint()..color = cutout;
    switch (shape) {
      case BigShape.paw:
        // coussinet principal
        final pad = Path()
          ..moveTo(u * 50, u * 44)
          ..cubicTo(u * 70, u * 44, u * 86, u * 62, u * 84, u * 78)
          ..cubicTo(u * 82, u * 92, u * 66, u * 90, u * 50, u * 88)
          ..cubicTo(u * 34, u * 90, u * 18, u * 92, u * 16, u * 78)
          ..cubicTo(u * 14, u * 62, u * 30, u * 44, u * 50, u * 44)
          ..close();
        c.drawPath(pad, ink);
        void toe(double x, double y, double w, double h, double rot) {
          c.save();
          c.translate(u * x, u * y);
          c.rotate(rot);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: u * w, height: u * h), ink);
          c.restore();
        }

        toe(14, 38, 17, 23, -0.45);
        toe(35, 18, 18, 25, -0.15);
        toe(64, 18, 18, 25, 0.15);
        toe(86, 38, 17, 23, 0.45);
      case BigShape.house:
        final r = u * 7;
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(u * 12, u * 44, u * 76, u * 50), Radius.circular(r));
        c.drawRRect(body, ink);
        final roof = Path()
          ..moveTo(u * 50, u * 6)
          ..quadraticBezierTo(u * 54, u * 6, u * 57, u * 9)
          ..lineTo(u * 95, u * 44)
          ..quadraticBezierTo(u * 100, u * 52, u * 90, u * 52)
          ..lineTo(u * 10, u * 52)
          ..quadraticBezierTo(u * 0, u * 52, u * 5, u * 44)
          ..lineTo(u * 43, u * 9)
          ..quadraticBezierTo(u * 46, u * 6, u * 50, u * 6)
          ..close();
        c.drawPath(roof, ink);
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 70, u * 14, u * 10, u * 22), Radius.circular(u * 2)),
          ink,
        );
        // porte en arche (découpe)
        final door = RRect.fromRectAndCorners(
          Rect.fromLTWH(u * 24, u * 62, u * 20, u * 32),
          topLeft: Radius.circular(u * 10),
          topRight: Radius.circular(u * 10),
        );
        c.drawRRect(door, hole);
        // fenêtre ronde
        c.drawCircle(Offset(u * 50, u * 34), u * 6, hole);
      case BigShape.bubble:
        final b = Path()
          ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(u * 4, u * 8, u * 86, u * 64), Radius.circular(u * 32)));
        final tail = Path()
          ..moveTo(u * 20, u * 60)
          ..quadraticBezierTo(u * 16, u * 84, u * 4, u * 92)
          ..quadraticBezierTo(u * 30, u * 92, u * 44, u * 68)
          ..close();
        c.drawPath(Path.combine(PathOperation.union, b, tail), ink);
        // cœur en découpe
        final hx = u * 47, hy = u * 40, hr = u * 13;
        final heart = Path()
          ..moveTo(hx, hy + hr * 0.95)
          ..cubicTo(hx - hr * 1.7, hy - hr * 0.1, hx - hr * 0.95, hy - hr * 1.45, hx, hy - hr * 0.5)
          ..cubicTo(hx + hr * 0.95, hy - hr * 1.45, hx + hr * 1.7, hy - hr * 0.1, hx, hy + hr * 0.95)
          ..close();
        c.drawPath(heart, hole);
        // trois points de saisie
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(u * (80 + i * 7), u * 92), u * 2.4, ink);
        }
    }
  }

  @override
  bool shouldRepaint(covariant BigShapePainter old) => old.shape != shape || old.color != color || old.cutout != cutout;
}

/// Trait de fond qui se dessine (progress 0 → 1).
class SquigglePainter extends CustomPainter {
  SquigglePainter(this.progress, {this.color = const Color(0xFF9CD4C8)});
  final double progress;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(-w * 0.1, h * 0.18)
      ..cubicTo(w * 0.3, h * 0.02, w * 0.55, h * 0.4, w * 0.35, h * 0.52)
      ..cubicTo(w * 0.15, h * 0.64, w * 0.45, h * 0.86, w * 0.75, h * 0.7)
      ..cubicTo(w * 0.95, h * 0.6, w * 1.05, h * 0.75, w * 1.1, h * 0.86);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * progress.clamp(0, 1)), p);
    }
  }

  @override
  bool shouldRepaint(covariant SquigglePainter old) => old.progress != progress;
}

/// Flèche fine dessinée à la main (carrousel d'accueil).
class ThinArrow extends StatelessWidget {
  const ThinArrow({super.key, this.width = 30, this.color = LP.muted});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, 12), painter: _ArrowPainter(color));
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawLine(Offset(s.width, s.height / 2), Offset(s.width - 6, s.height / 2 - 5), p);
    c.drawLine(Offset(s.width, s.height / 2), Offset(s.width - 6, s.height / 2 + 5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bord supérieur en dôme du panneau sombre (profil).
class DomeClipper extends CustomClipper<Path> {
  const DomeClipper({this.rise = 64});
  final double rise;

  @override
  Path getClip(Size s) {
    final r = s.width * 0.62;
    return Path()
      ..moveTo(0, rise + 26)
      ..quadraticBezierTo(0, rise, 26, rise)
      ..lineTo(s.width / 2 - r * 0.55, rise)
      ..arcToPoint(Offset(s.width / 2 + r * 0.55, rise), radius: Radius.circular(r * 0.8), clockwise: true)
      ..lineTo(s.width - 26, rise)
      ..quadraticBezierTo(s.width, rise, s.width, rise + 26)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant DomeClipper old) => old.rise != rise;
}
