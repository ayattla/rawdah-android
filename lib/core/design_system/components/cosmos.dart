import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';

/// مجرة حية بطبقات: تدرج عميق، سدم ناعمة، نجوم بثلاثة أحجام تتلألأ،
/// كواكب بعيدة بحلقات، ومذنب يمر كل فترة. ساكنة تماما في وضع تقليل الحركة.
class CosmosBackground extends StatefulWidget {
  final List<Color> sky;
  final Widget child;
  const CosmosBackground({super.key, required this.sky, required this.child});

  @override
  State<CosmosBackground> createState() => _CosmosBackgroundState();
}

class _CosmosBackgroundState extends State<CosmosBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = A11y.reduceMotionOf(context) || A11y.highContrastOf(context) || _inTest;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  // الاختبارات تنتظر سكون الشاشة، فالحركة الدائمة تتوقف فيها
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: CosmosPainter(widget.sky, _c.value)),
            ),
          ),
        ),
        widget.child,
      ]);
}

class CosmosPainter extends CustomPainter {
  final List<Color> sky;
  final double t; // 0..1
  CosmosPainter(this.sky, this.t);

  static final _stars = () {
    final r = math.Random(21);
    return [for (var i = 0; i < 110; i++) (r.nextDouble(), r.nextDouble(), r.nextInt(3), r.nextDouble())];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(rect));

    // سدم ناعمة تنجرف ببطء
    final drift = math.sin(t * math.pi * 2) * 12;
    for (final (cx, cy, rad, col) in [
      (0.15, 0.18, 0.55, const Color(0xFFFF5DB1)),
      (0.9, 0.45, 0.6, const Color(0xFF22D3EE)),
      (0.3, 0.85, 0.5, const Color(0xFF8B5CF6)),
    ]) {
      final c = Offset(w * cx + drift, h * cy - drift / 2);
      final r = w * rad;
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.22), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // نجوم تتلألأ: كل نجمة لها طورها
    for (final (x, y, s, ph) in _stars) {
      final tw = 0.55 + 0.45 * math.sin((t * 6 + ph * 6.28) * math.pi);
      final rad = [0.7, 1.2, 1.9][s];
      final p = Offset(x * w, y * h);
      canvas.drawCircle(p, rad, Paint()..color = Colors.white.withValues(alpha: (0.25 + 0.6 * tw).clamp(0, 1)));
      if (s == 2 && tw > 0.8) {
        final glow = Paint()
          ..color = Colors.white.withValues(alpha: 0.35 * tw)
          ..strokeWidth = 1;
        canvas.drawLine(p - const Offset(4, 0), p + const Offset(4, 0), glow);
        canvas.drawLine(p - const Offset(0, 4), p + const Offset(0, 4), glow);
      }
    }

    // كوكبان بعيدان يدوران ببطء على مدارات صغيرة
    _planet(canvas, Offset(w * 0.86 + math.cos(t * 6.28) * 4, h * 0.11 + math.sin(t * 6.28) * 3), w * 0.07, const Color(0xFFFF8A3D), const Color(0xFFFFC23F), t);
    _planet(canvas, Offset(w * 0.08 + math.sin(t * 6.28) * 3, h * 0.55), w * 0.045, const Color(0xFF34D399), const Color(0xFF22D3EE), -t);

    // مذنب يمر في الربع الأخير من الدورة
    if (t > 0.72 && t < 0.86) {
      final k = (t - 0.72) / 0.14;
      final head = Offset(w * (1.1 - 1.3 * k), h * (0.05 + 0.25 * k));
      final tail = head + Offset(w * 0.22, -h * 0.05);
      canvas.drawLine(
        head,
        tail,
        Paint()
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromPoints(head, tail))
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(head, 2.6, Paint()..color = Colors.white);
    }
  }

  void _planet(Canvas canvas, Offset c, double r, Color body, Color ring, double t) {
    final oval = Rect.fromCenter(center: c, width: r * 3, height: r * 0.8);
    final ringPaint = Paint()
      ..color = ring.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.35 + math.sin(t * 6.28) * 0.05);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(oval, math.pi, math.pi, false, ringPaint);
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: [Color.lerp(body, Colors.white, 0.35)!, body, Color.lerp(body, Colors.black, 0.3)!]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawArc(oval, 0, math.pi, false, ringPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CosmosPainter old) => old.t != t || old.sky != sky;
}
