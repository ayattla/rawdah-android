import 'package:flutter/material.dart';

/// أشكال شاشات التلفاز الكرتونية المستوحاة من فواصل القنوات القديمة.
/// كل شكل منحنيات منفوخة غير متماثلة، تُرسم داخل أي مستطيل.
const _shapes = <List<double>>[
  // ٠ بيضاوي منفوخ مائل
  [6, 18, 14, 0, 150, -4, 162, 14, 174, 40, 170, 110, 158, 126, 140, 140, 26, 142, 10, 126, -4, 104, -2, 40, 6, 18],
  // ١ مربع منفوخ
  [10, 10, 40, -2, 120, 4, 140, 12, 150, 40, 150, 100, 140, 118, 110, 128, 30, 126, 8, 116, 0, 86, 0, 40, 10, 10],
  // ٢ شاشة مستديرة
  [84, 2, 140, 2, 168, 30, 166, 70, 164, 116, 132, 138, 82, 136, 34, 136, 2, 112, 4, 68, 6, 26, 36, 2, 84, 2],
  // ٣ عريض للشاشات الكبيرة
  [30, 118, 40, 96, 120, 100, 200, 102, 280, 98, 352, 94, 360, 120, 372, 160, 368, 220, 356, 252, 340, 278, 250, 274, 190, 276, 110, 280, 40, 284, 28, 250, 16, 210, 20, 150, 30, 118],
];

Path tvShape(int variant, Rect r) {
  final p = _shapes[variant % _shapes.length];
  var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
  for (var i = 0; i < p.length; i += 2) {
    minX = p[i] < minX ? p[i] : minX;
    maxX = p[i] > maxX ? p[i] : maxX;
    minY = p[i + 1] < minY ? p[i + 1] : minY;
    maxY = p[i + 1] > maxY ? p[i + 1] : maxY;
  }
  Offset at(int i) => Offset(r.left + (p[i] - minX) / (maxX - minX) * r.width, r.top + (p[i + 1] - minY) / (maxY - minY) * r.height);
  final path = Path()..moveTo(at(0).dx, at(0).dy);
  for (var i = 2; i + 5 < p.length + 0; i += 6) {
    final a = at(i), b = at(i + 2), c = at(i + 4);
    path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
  }
  return path..close();
}

const _ink = Color(0xFF2A1A66);

/// إطار تلفاز بلاستيكي: ظل صلب، جسم بتدرج، لمعة، حافة ملونة حول الشاشة، وبراغي.
class CandyTvPainter extends CustomPainter {
  final int variant;
  final Color body;
  final Color screen;
  final Color? rim;
  final bool flat;
  final bool pressed;
  final double inset; // سماكة الإطار
  CandyTvPainter({required this.variant, required this.body, required this.screen, this.rim, this.flat = false, this.pressed = false, this.inset = 0.15});

  static Color rimFor(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withHue((h.hue + 150) % 360).withSaturation(0.9).withLightness(0.62).toColor();
  }

  Rect screenRect(Size s) => Rect.fromLTWH(s.width * inset * 0.75, s.height * inset * 0.85, s.width * (1 - inset * 1.5), s.height * (1 - inset * 1.7)).shift(Offset(0, -s.height * 0.01));

  @override
  void paint(Canvas canvas, Size size) {
    final outer = tvShape(variant, Offset.zero & Size(size.width, size.height - 6));
    final scr = tvShape(variant, screenRect(Size(size.width, size.height - 6)));
    final bh = HSLColor.fromColor(body);
    final rimC = rim ?? rimFor(body);
    if (!flat && pressed) {
      canvas.drawPath(outer, Paint()
        ..color = body.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    }
    if (!flat) canvas.drawPath(outer.shift(Offset(0, pressed ? 3 : 6)), Paint()..color = _ink);
    final ob = outer.getBounds();
    canvas.drawPath(
      outer,
      flat
          ? (Paint()..color = body)
          : (Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
              bh.withLightness((bh.lightness + 0.16).clamp(0.0, 0.95)).toColor(),
              body,
              bh.withLightness((bh.lightness - 0.12).clamp(0.0, 1.0)).toColor(),
            ]).createShader(ob)),
    );
    canvas.drawPath(outer, Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);
    final sb = scr.getBounds();
    final sh = HSLColor.fromColor(screen);
    canvas.drawPath(
      scr,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          sh.withLightness((sh.lightness + 0.12).clamp(0.0, 1.0)).toColor(),
          sh.withLightness((sh.lightness - 0.14).clamp(0.0, 1.0)).toColor(),
        ]).createShader(sb),
    );
    if (!flat) {
      canvas.drawPath(scr, Paint()
        ..color = rimC
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8);
    }
    canvas.drawPath(scr, Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    if (flat) return;
    canvas.save();
    canvas.clipPath(scr);
    canvas.drawPath(
      Path()
        ..moveTo(sb.left, sb.top)
        ..lineTo(sb.left + sb.width * 0.5, sb.top)
        ..lineTo(sb.left + sb.width * 0.22, sb.bottom)
        ..lineTo(sb.left, sb.bottom)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.09),
    );
    canvas.restore();
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ob.left + ob.width * 0.12, ob.top + 4, ob.width * 0.38, 5), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.restore();
    for (final (p, c) in [
      (Offset(ob.left + ob.width * 0.07, ob.top + ob.height * 0.12), rimC),
      (Offset(ob.right - ob.width * 0.07, ob.top + ob.height * 0.12), const Color(0xFF22D3EE)),
      (Offset(ob.right - ob.width * 0.1, ob.bottom - ob.height * 0.1), const Color(0xFFFF5D8F)),
    ]) {
      canvas.drawCircle(p, 4.5, Paint()..color = c);
      canvas.drawCircle(p, 4.5, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8);
      canvas.drawCircle(p - const Offset(1.4, 1.4), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.85));
    }
  }

  @override
  bool shouldRepaint(covariant CandyTvPainter o) =>
      o.variant != variant || o.body != body || o.screen != screen || o.rim != rim || o.flat != flat || o.pressed != pressed;
}
