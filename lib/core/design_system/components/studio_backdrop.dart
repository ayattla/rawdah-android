import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/live_scene.dart';

/// خلفية استوديو البث للرئيسية: أشعة شمس تلفزيونية قديمة تدور ببطء من أعلى الشاشة،
/// وأشكال حلوى (حلقات، كبسولات، مثلثات، خطوط متعرجة) تطفو وتتمايل. بلا كواكب.
class StudioBackdrop extends StatefulWidget {
  final List<Color> sky;
  final Widget child;
  const StudioBackdrop({super.key, required this.sky, required this.child});

  @override
  State<StudioBackdrop> createState() => _StudioBackdropState();
}

class _StudioBackdropState extends State<StudioBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (A11y.reduceMotionOf(context) || A11y.highContrastOf(context) || LiveScene.inTest) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _StudioPainter(widget.sky, _c.value))),
          ),
        ),
        widget.child,
      ]);
}

class _StudioPainter extends CustomPainter {
  final List<Color> sky;
  final double t;
  _StudioPainter(this.sky, this.t);

  static final _shapes = () {
    final r = math.Random(12);
    return [for (var i = 0; i < 16; i++) (r.nextDouble(), r.nextDouble(), r.nextInt(4), r.nextInt(5), r.nextDouble())];
  }();
  static const _cols = [Color(0xFFFF5DB1), Color(0xFFFFD43B), Color(0xFF22D3EE), Color(0xFF9DFF8A), Color(0xFFFF9F1C)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(rect));
    // أشعة الاستوديو تدور حول نقطة فوق الشاشة
    final c = Offset(w / 2, -h * 0.05);
    final rays = 18;
    final light = Paint()..color = Colors.white.withValues(alpha: 0.045);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 2 / 6);
    for (var i = 0; i < rays; i += 2) {
      final a0 = i * 2 * math.pi / rays, a1 = (i + 1) * 2 * math.pi / rays;
      final far = h * 1.6;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a0) * far, math.sin(a0) * far)
          ..lineTo(math.cos(a1) * far, math.sin(a1) * far)
          ..close(),
        light,
      );
    }
    canvas.restore();
    // توهج وردي وفيروزي ناعم
    for (final (cx, cy, col) in [(0.1, 0.25, const Color(0xFFFF5DB1)), (0.95, 0.6, const Color(0xFF22D3EE))]) {
      final p = Offset(w * cx, h * cy);
      canvas.drawCircle(p, w * 0.55, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.2), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: p, radius: w * 0.55)));
    }
    // أشكال حلوى تطفو
    for (final (x, y, kind, ci, ph) in _shapes) {
      final px = w * x + math.sin(t * math.pi * 8 + ph * 6) * 10;
      final py = h * ((y - t * 0.5 + 1) % 1);
      final col = _cols[ci].withValues(alpha: 0.55);
      final stroke = Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(t * math.pi * 4 * (ph > 0.5 ? 1 : -1) + ph * 6);
      switch (kind) {
        case 0:
          canvas.drawCircle(Offset.zero, 8, stroke);
        case 1:
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -4, 20, 8), const Radius.circular(4)), Paint()..color = col);
        case 2:
          canvas.drawPath(Path()..moveTo(0, -8)..lineTo(8, 6)..lineTo(-8, 6)..close(), stroke..strokeJoin = StrokeJoin.round);
        default:
          canvas.drawPath(Path()..moveTo(-12, 0)..quadraticBezierTo(-6, -7, 0, 0)..quadraticBezierTo(6, 7, 12, 0), stroke);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StudioPainter o) => o.t != t || o.sky != sky;
}
