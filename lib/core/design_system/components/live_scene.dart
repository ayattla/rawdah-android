import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/scene.dart';

/// خلفية حية لكل عالم: نفس سماء القسم، وفوقها زينة تتحرك ببطء حسب العالم:
/// فوانيس تتمايل لركن المسلم والقرآن، حروف وأرقام تطفو للتعلم،
/// ذرات وكواكب صغيرة تدور للعلوم، قصاصات تتساقط للعب، وفقاعات ترتفع للباقي.
class LiveScene extends StatefulWidget {
  final SceneTheme theme;
  final Widget child;
  const LiveScene({super.key, required this.theme, required this.child});

  static final bool inTest = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<LiveScene> createState() => _LiveSceneState();
}

class _LiveSceneState extends State<LiveScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 16));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = A11y.reduceMotionOf(context) || LiveScene.inTest;
    if (still) {
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
        Positioned.fill(child: CustomPaint(painter: ScenePainter(theme: widget.theme))),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: _DecorPainter(widget.theme, _c.value)),
            ),
          ),
        ),
        widget.child,
      ]);
}

class _DecorPainter extends CustomPainter {
  final SceneTheme theme;
  final double t;
  _DecorPainter(this.theme, this.t);

  static const _ink = Color(0xFF2A1A66);

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case SceneTheme.islamic || SceneTheme.quran:
        _lanterns(canvas, size);
      case SceneTheme.learn:
        _letters(canvas, size);
      case SceneTheme.science:
        _atoms(canvas, size);
      case SceneTheme.play:
        _confetti(canvas, size);
      case SceneTheme.home:
        _bubbles(canvas, size);
    }
  }

  void _lanterns(Canvas canvas, Size size) {
    final w = size.width;
    final moon = Offset(w * 0.86, 44);
    canvas.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(moon + const Offset(9, -6), 19, Paint()..color = theme.sky.first);
    for (final (x, len, ph) in [(0.08, 38.0, 0.0), (0.24, 20.0, 1.7), (0.64, 28.0, 3.1)]) {
      final sway = math.sin(t * math.pi * 4 + ph) * 0.12;
      canvas.save();
      canvas.translate(w * x, 0);
      canvas.rotate(sway);
      canvas.drawLine(Offset.zero, Offset(0, len), Paint()
        ..color = const Color(0xFFD4A537)
        ..strokeWidth = 1.6);
      canvas.drawCircle(Offset(0, len + 14), 24, Paint()..color = const Color(0xFFFFD56A).withValues(alpha: 0.16 + 0.08 * math.sin(t * 20 + ph)));
      final b = Path()
        ..moveTo(-7, len)
        ..lineTo(7, len)
        ..lineTo(10, len + 6)
        ..lineTo(10, len + 20)
        ..lineTo(5, len + 26)
        ..lineTo(-5, len + 26)
        ..lineTo(-10, len + 20)
        ..lineTo(-10, len + 6)
        ..close();
      canvas.drawPath(b, Paint()..color = const Color(0xFFF5B83D));
      canvas.drawPath(b, Paint()
        ..color = const Color(0xFF7A4B00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      canvas.drawRect(Rect.fromLTWH(-4, len + 8, 8, 11), Paint()..color = const Color(0xFFFFF7D1));
      canvas.restore();
    }
  }

  void _letters(Canvas canvas, Size size) {
    const glyphs = ['أ', 'ب', '١', 'ت', '٢', 'ج', '٣', 'د', 'هـ', '٥'];
    const cols = [Color(0xFFA855F7), Color(0xFFFF5D8F), Color(0xFFFFB020), Color(0xFF3B82F6), Color(0xFF10B981)];
    for (var i = 0; i < glyphs.length; i++) {
      final x = (i.isEven ? 0.04 : 0.86) + (i % 3) * 0.03;
      final y = 1 - ((t + i / glyphs.length) % 1);
      final tp = TextPainter(
        text: TextSpan(text: glyphs[i], style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w800, fontSize: 26 + (i % 3) * 6.0, color: cols[i % cols.length].withValues(alpha: 0.28))),
        textDirection: TextDirection.rtl,
      )..layout();
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(math.sin(t * 6.28 + i) * 0.25);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  void _atoms(Canvas canvas, Size size) {
    for (final (cx, cy, r, ph) in [(0.88, 0.08, 34.0, 0.0), (0.1, 0.5, 26.0, 2.0), (0.9, 0.82, 22.0, 4.0)]) {
      final c = Offset(size.width * cx, size.height * cy);
      for (var k = 0; k < 3; k++) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(k * math.pi / 3);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 0.8), Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
        final a = t * math.pi * 4 * (k + 1) + ph;
        canvas.drawCircle(Offset(math.cos(a) * r * 1.2, math.sin(a) * r * 0.4), 4, Paint()..color = const Color(0xFF22D3EE).withValues(alpha: 0.6));
        canvas.restore();
      }
      canvas.drawCircle(c, 6, Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.5));
    }
  }

  void _confetti(Canvas canvas, Size size) {
    final r = math.Random(5);
    const cols = [Color(0xFFFF5D8F), Color(0xFF22D3EE), Color(0xFFFFC23F), Color(0xFF8B5CF6), Color(0xFF34D399)];
    for (var i = 0; i < 22; i++) {
      final edge = r.nextBool();
      final x = edge ? r.nextDouble() * 0.16 : 0.84 + r.nextDouble() * 0.16;
      final y = (r.nextDouble() + t * (0.6 + r.nextDouble() * 0.6)) % 1;
      canvas.save();
      canvas.translate(size.width * x + math.sin(t * 12 + i) * 6, size.height * y);
      canvas.rotate(t * 10 * (i.isEven ? 1 : -1) + i);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2.5, 10, 5), const Radius.circular(2)), Paint()..color = cols[i % cols.length].withValues(alpha: 0.5));
      canvas.restore();
    }
  }

  void _bubbles(Canvas canvas, Size size) {
    final r = math.Random(8);
    for (var i = 0; i < 12; i++) {
      final x = r.nextDouble();
      if (x > 0.2 && x < 0.8) continue;
      final y = 1 - ((r.nextDouble() + t * (0.5 + r.nextDouble() * 0.5)) % 1);
      final rad = 6 + r.nextDouble() * 12;
      final p = Offset(size.width * x + math.sin(t * 8 + i) * 8, size.height * y);
      canvas.drawCircle(p, rad, Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      canvas.drawCircle(p - Offset(rad * 0.35, rad * 0.35), rad * 0.2, Paint()..color = Colors.white.withValues(alpha: 0.7));
    }
    // خط حلزوني مرح في الزاوية
    final path = Path()..moveTo(size.width * 0.02, size.height * 0.3);
    for (var k = 1; k <= 6; k++) {
      path.quadraticBezierTo(size.width * (0.02 + k * 0.025), size.height * (0.3 + (k.isEven ? 0.02 : -0.02)) + math.sin(t * 6.28) * 3,
          size.width * (0.02 + k * 0.03), size.height * 0.3);
    }
    canvas.drawPath(path, Paint()
      ..color = _ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _DecorPainter o) => o.t != t || o.theme != theme;
}
