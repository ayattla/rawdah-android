import 'dart:math' as math;

import 'package:flutter/material.dart';


// =====================================================================
// الهندسة: المحراب ونقش الرواق
// =====================================================================

/// مسار المحراب: قوس مدبب فوق جسم مستطيل بزوايا سفلية لينة، داخل دائرة نصف قطرها [r].
/// صار المحراب توقيع روضة البصري بدل النجمة الثمانية: يكرر قوس الرأس في الصفحة الرئيسية،
/// ويحيل إلى المسجد بلا رسم كائنات. [rotation] باقٍ للتوافق ولا أثر له.
Path khatamPath(Offset c, double r, {double rotation = 0}) {
  final w = r * 1.62, h = r * 2;
  final left = c.dx - w / 2, right = c.dx + w / 2;
  final top = c.dy - h / 2, bottom = c.dy + h / 2;
  final spring = top + w * 0.58; // بداية انحناء القوس
  final k = w * 0.16;
  final rise = spring - top;
  return Path()
    ..moveTo(left, spring)
    ..lineTo(left, bottom - k)
    ..quadraticBezierTo(left, bottom, left + k, bottom)
    ..lineTo(right - k, bottom)
    ..quadraticBezierTo(right, bottom, right, bottom - k)
    ..lineTo(right, spring)
    ..cubicTo(right, spring - rise * 0.6, c.dx + w * 0.16, top + rise * 0.14, c.dx, top)
    ..cubicTo(c.dx - w * 0.16, top + rise * 0.14, left, spring - rise * 0.6, left, spring)
    ..close();
}

/// شكل المحراب كحدود لعناصر Flutter.
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

/// نقش الخلفية: رواق من محاريب صغيرة متناوبة تربطها معيّنات، يخفت نحو الأسفل.
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
