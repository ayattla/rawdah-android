import 'dart:math' as math;

import 'package:flutter/material.dart';


// =====================================================================
// الهندسة: النجمة الثمانية (خاتم سليمان) ونقش الزليج
// =====================================================================

/// مسار النجمة الثمانية: مربعان متداخلان، نصف القطر الداخلي 0.765 من الخارجي.
Path khatamPath(Offset c, double r, {double rotation = 0}) {
  final p = Path();
  const inner = 0.765;
  for (var i = 0; i < 16; i++) {
    final a = rotation - math.pi / 2 + i * math.pi / 8;
    final rr = i.isEven ? r : r * inner;
    final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// شكل النجمة الثمانية كحدود لعناصر Flutter.
class KhatamBorder extends ShapeBorder {
  const KhatamBorder();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      khatamPath(rect.center, rect.shortestSide / 2, rotation: math.pi / 8);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}

/// نقش الزليج: شبكة نجوم ثمانية تربطها معيّنات، يخفت نحو الأسفل.
class ZellijPainter extends CustomPainter {
  final Color color;
  final double cell;
  final double fadeTo; // نسبة الارتفاع التي يختفي عندها النقش (1 = لا يخفت)
  ZellijPainter({required this.color, this.cell = 64, this.fadeTo = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (size.height / cell).ceil() + 1;
    final cols = (size.width / cell).ceil() + 1;
    for (var y = 0; y < rows; y++) {
      final cy = y * cell;
      final t = fadeTo >= 1 ? 0.0 : (cy / (size.height * fadeTo)).clamp(0.0, 1.0);
      final alpha = color.a * (1 - t);
      if (alpha <= 0.01) continue;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      for (var x = 0; x < cols; x++) {
        final c = Offset(x * cell + (y.isOdd ? cell / 2 : 0), cy);
        canvas.drawPath(khatamPath(c, cell * 0.26), paint);
        // معيّن صغير بين النجوم
        final d = c + Offset(cell / 2, 0);
        final s = cell * 0.08;
        canvas.drawPath(
            Path()
              ..moveTo(d.dx, d.dy - s)
              ..lineTo(d.dx + s, d.dy)
              ..lineTo(d.dx, d.dy + s)
              ..lineTo(d.dx - s, d.dy)
              ..close(),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZellijPainter old) => old.color != color || old.cell != cell || old.fadeTo != fadeTo;
}
