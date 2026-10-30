import 'package:flutter/material.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';

/// Visuel produit dessiné : sachet, boîte, pot ou objet, aux couleurs du produit.
/// Remplaçable par de vraies photos produit avant mise en production.
class ProductArt extends StatelessWidget {
  const ProductArt(this.product, {super.key, this.size = 140, this.radius = 22, this.showBg = true});
  final Product product;
  final double size;
  final double radius;
  final bool showBg;

  @override
  Widget build(BuildContext context) {
    final p = product;
    // centre de l'étiquette selon la forme
    // centre de l'étiquette blanche selon la forme (icône puis marque dessous)
    final (iconAt, brandAt) = switch (p.kind) {
      PackKind.bag => (const Alignment(0, 0.12), const Alignment(0, 0.44)),
      PackKind.can => (const Alignment(0, 0.06), const Alignment(0, 0.34)),
      PackKind.tub => (const Alignment(0, 0.14), const Alignment(0, 0.44)),
      PackKind.object => (Alignment.center, Alignment.center),
    };
    return Semantics(
      image: true,
      label: '${p.name}, ${p.brand}',
      child: Container(
        width: size,
        height: size,
        decoration: showBg ? BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(radius)) : null,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PackPainter(p.kind, p.color))),
            Align(
              alignment: iconAt,
              child: Icon(
                p.icon,
                size: size * (p.kind == PackKind.object ? 0.34 : 0.17),
                color: p.kind == PackKind.object ? LP.white : p.color,
              ),
            ),
            if (p.kind != PackKind.object && size >= 90)
              Align(
                alignment: brandAt,
                child: Text(
                  p.brand.toUpperCase(),
                  style: LPText.body(
                    size: size * 0.055,
                    w: FontWeight.w900,
                    color: p.color,
                    height: 1,
                  ).copyWith(letterSpacing: 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackPainter extends CustomPainter {
  _PackPainter(this.kind, this.color);
  final PackKind kind;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    final body = Paint()..color = color;
    final light = Paint()..color = Color.lerp(color, Colors.white, 0.25)!;
    final dark = Paint()..color = Color.lerp(color, Colors.black, 0.18)!;
    final label = Paint()..color = Colors.white;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    switch (kind) {
      case PackKind.bag:
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 90), width: u * 58, height: u * 8), shadow);
        final bag = Path()
          ..moveTo(u * 28, u * 18)
          ..lineTo(u * 72, u * 18)
          ..quadraticBezierTo(u * 78, u * 50, u * 76, u * 82)
          ..quadraticBezierTo(u * 76, u * 88, u * 70, u * 88)
          ..lineTo(u * 30, u * 88)
          ..quadraticBezierTo(u * 24, u * 88, u * 24, u * 82)
          ..quadraticBezierTo(u * 22, u * 50, u * 28, u * 18)
          ..close();
        c.drawPath(bag, body);
        // soudure crantée en haut
        final seal = Path()..moveTo(u * 27, u * 18);
        for (var i = 0; i < 9; i++) {
          seal.lineTo(u * (27 + i * 5.1 + 2.5), u * 13);
          seal.lineTo(u * (27 + (i + 1) * 5.1), u * 18);
        }
        seal.close();
        c.drawPath(seal, dark);
        c.drawRect(Rect.fromLTWH(u * 27, u * 18, u * 46, u * 5), dark);
        // reflet
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 30, u * 27, u * 4, u * 50), Radius.circular(u * 2)),
          light,
        );
        // étiquette
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 33, u * 40, u * 34, u * 36), Radius.circular(u * 8)),
          label,
        );
      case PackKind.can:
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 88), width: u * 52, height: u * 8), shadow);
        final rect = Rect.fromLTWH(u * 27, u * 26, u * 46, u * 60);
        c.drawRect(rect, body);
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 86), width: u * 46, height: u * 10), body);
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 26), width: u * 46, height: u * 10), light);
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 26), width: u * 34, height: u * 6), dark);
        c.drawRect(Rect.fromLTWH(u * 27, u * 42, u * 46, u * 30), label);
      case PackKind.tub:
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 88), width: u * 50, height: u * 8), shadow);
        // couvercle
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 28, u * 22, u * 44, u * 14), Radius.circular(u * 4)),
          dark,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 30, u * 34, u * 40, u * 52), Radius.circular(u * 6)),
          body,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(u * 33, u * 44, u * 34, u * 34), Radius.circular(u * 6)),
          label,
        );
      case PackKind.object:
        c.drawOval(Rect.fromCenter(center: Offset(u * 50, u * 84), width: u * 50, height: u * 8), shadow);
        c.drawCircle(Offset(u * 50, u * 50), u * 30, body);
        c.drawCircle(Offset(u * 40, u * 38), u * 7, light);
    }
  }

  @override
  bool shouldRepaint(covariant _PackPainter old) => old.kind != kind || old.color != color;
}
