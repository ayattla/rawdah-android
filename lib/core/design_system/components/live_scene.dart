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
  final _scroll = ValueNotifier<double>(0);
  // اختلاف بسيط بين الزيارات: تبدأ الزينة من طور مختلف كل مرة
  final double _phase = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;

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
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ScenePainter(theme: widget.theme))),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_c, _scroll]),
              builder: (_, __) => CustomPaint(painter: _DecorPainter(widget.theme, (_c.value + _phase) % 1, _scroll.value)),
            ),
          ),
        ),
        // الزينة تتحرك أبطأ من المحتوى عند التمرير فتعطي عمقا
        NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical) _scroll.value = n.metrics.pixels;
            return false;
          },
          child: widget.child,
        ),
      ]);
}

class _DecorPainter extends CustomPainter {
  final SceneTheme theme;
  final double t;
  final double scroll;
  _DecorPainter(this.theme, this.t, this.scroll);

  static final _dots = () {
    final r = math.Random(31);
    return [for (var i = 0; i < 46; i++) (r.nextDouble(), r.nextDouble(), r.nextDouble())];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    // نقاط ضوء تتلألأ في كل العوالم
    for (final (x, y, ph) in _dots) {
      final tw = 0.5 + 0.5 * math.sin((t * 8 + ph * 6.28) * math.pi);
      canvas.drawCircle(Offset(x * size.width, y * size.height), 0.6 + ph * 1.3, Paint()..color = Colors.white.withValues(alpha: 0.15 + 0.5 * tw));
    }
    canvas.save();
    canvas.translate(0, -(scroll * 0.18) % size.height);
    // طبقة ثانية لتغطية الإزاحة عند التمرير
    for (final dy in [0.0, size.height]) {
      canvas.save();
      canvas.translate(0, dy);
      _layer(canvas, size);
      canvas.restore();
    }
    canvas.restore();
    // عناصر ثابتة في أعلى الشاشة لا تتحرك مع التمرير
    if (theme == SceneTheme.islamic || theme == SceneTheme.quran) _lanterns(canvas, size);
    if (theme == SceneTheme.quiz || theme == SceneTheme.play) _beams(canvas, size);
    if (theme == SceneTheme.quiz) _curtains(canvas, size);
    if (theme == SceneTheme.garden) _clouds(canvas, size);
  }

  void _layer(Canvas canvas, Size size) {
    switch (theme) {
      case SceneTheme.islamic || SceneTheme.quran:
        _lattice(canvas, size);
      case SceneTheme.learn:
        _letters(canvas, size);
      case SceneTheme.science:
        _atoms(canvas, size);
      case SceneTheme.play || SceneTheme.quiz:
        _confetti(canvas, size);
      case SceneTheme.home:
        _bubbles(canvas, size);
      case SceneTheme.stories:
        _books(canvas, size);
      case SceneTheme.school:
        _chalk(canvas, size);
      case SceneTheme.workshop:
        _gears(canvas, size);
      case SceneTheme.garden:
        _leaves(canvas, size);
      case SceneTheme.journey:
        _trail(canvas, size);
    }
  }

  // ---------- ركن المسلم: شبكة دوائر متداخلة هادئة جدا (زخرفة هندسية) ----------
  void _lattice(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD4A537).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const r = 26.0;
    for (var y = 0.0; y < size.height + r; y += r * 1.5) {
      for (var x = ((y / (r * 1.5)).round().isOdd ? r : 0.0); x < size.width + r; x += r * 2) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  // ---------- القصص: كتب مفتوحة تطفو وتقلب صفحاتها ----------
  void _books(Canvas canvas, Size size) {
    const cols = [Color(0xFFFF9F1C), Color(0xFFFF5D8F), Color(0xFF22D3EE), Color(0xFFFFD43B)];
    for (var i = 0; i < 6; i++) {
      final x = i.isEven ? 0.08 + (i % 3) * 0.02 : 0.9 - (i % 3) * 0.02;
      final y = (i / 6 + t * 0.35) % 1;
      final c = Offset(size.width * x, size.height * (1 - y));
      final flap = math.sin(t * math.pi * 10 + i) * 0.5 + 0.5;
      final col = cols[i % cols.length].withValues(alpha: 0.45);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.sin(t * 6 + i) * 0.2);
      final left = Path()..moveTo(0, 4)..lineTo(-16, -2)..lineTo(-16, -18)..lineTo(0, -12)..close();
      final right = Path()..moveTo(0, 4)..lineTo(16, -2)..lineTo(16, -18)..lineTo(0, -12)..close();
      canvas.drawPath(left, Paint()..color = col);
      canvas.drawPath(right, Paint()..color = col);
      // صفحة تنقلب
      canvas.drawPath(Path()..moveTo(0, 4)..lineTo(16 - 32 * flap, -4)..lineTo(16 - 32 * flap, -20)..lineTo(0, -12)..close(), Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.restore();
    }
    // باب خيالي مقوس في الزاوية
    final door = Path()
      ..moveTo(size.width * 0.86, size.height)
      ..lineTo(size.width * 0.86, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.93, size.height * 0.84, size.width, size.height * 0.9);
    canvas.drawPath(door, Paint()
      ..color = const Color(0xFFFFD43B).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  // ---------- المدرسة: سبورة بخطوط طباشير وأدوات تطفو ----------
  void _chalk(Canvas canvas, Size size) {
    const glyphs = ['أ', '٢', 'ب', '+', '٥', 'ت', '=', '٣'];
    for (var i = 0; i < glyphs.length; i++) {
      final x = i.isEven ? 0.05 : 0.9;
      final y = (i / glyphs.length + t * 0.25) % 1;
      final tp = TextPainter(
        text: TextSpan(text: glyphs[i], style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w800, fontSize: 30, color: Colors.white.withValues(alpha: 0.16))),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(size.width * x - tp.width / 2, size.height * y));
    }
    // قلم رصاص ومسطرة يدوران ببطء
    for (final (x, y, ph) in [(0.12, 0.42, 0.0), (0.88, 0.7, 2.0)]) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(t * math.pi * 2 + ph);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -4, 36, 8), const Radius.circular(3)), Paint()..color = const Color(0xFFFFD43B).withValues(alpha: 0.4));
      canvas.drawPath(Path()..moveTo(14, -4)..lineTo(24, 0)..lineTo(14, 4)..close(), Paint()..color = const Color(0xFFFFE8C2).withValues(alpha: 0.4));
      canvas.restore();
    }
    final g = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 18, g);
    canvas.drawPath(Path()..moveTo(size.width * 0.06, size.height * 0.9)..lineTo(size.width * 0.12, size.height * 0.8)..lineTo(size.width * 0.18, size.height * 0.9)..close(), g);
  }

  // ---------- ورشة المخترع: تروس تدور وأنبوب فيه فقاعات ولمبات ----------
  void _gear(Canvas canvas, Offset c, double r, double a, Color col) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(a);
    final teeth = 10;
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final ang = i * math.pi / teeth;
      final rr = i.isEven ? r : r * 0.8;
      final p = Offset(math.cos(ang) * rr, math.sin(ang) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = col);
    canvas.drawCircle(Offset.zero, r * 0.3, Paint()..color = theme.sky[1]);
    canvas.restore();
  }

  void _gears(Canvas canvas, Size size) {
    final a = t * math.pi * 2;
    _gear(canvas, Offset(size.width * 0.05, size.height * 0.3), 34, a, const Color(0xFF22D3EE).withValues(alpha: 0.22));
    _gear(canvas, Offset(size.width * 0.05 + 52, size.height * 0.3 + 26), 22, -a * 1.5, const Color(0xFFFFB020).withValues(alpha: 0.25));
    _gear(canvas, Offset(size.width * 0.95, size.height * 0.72), 40, -a * 0.8, const Color(0xFF94A3B8).withValues(alpha: 0.2));
    // أنبوب على الحافة وفقاعات تجري فيه
    final pipeX = size.width - 10.0;
    canvas.drawLine(Offset(pipeX, 0), Offset(pipeX, size.height), Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.18)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round);
    for (var i = 0; i < 6; i++) {
      final y = ((i / 6) - t) % 1 * size.height;
      canvas.drawCircle(Offset(pipeX, y), 3.5, Paint()..color = const Color(0xFF9FF3FF).withValues(alpha: 0.6));
    }
    // لمبات تومض
    for (var i = 0; i < 3; i++) {
      final on = math.sin(t * math.pi * 12 + i * 2) > 0.3;
      canvas.drawCircle(Offset(size.width * 0.04, size.height * (0.55 + i * 0.05)), 5, Paint()..color = [const Color(0xFFFF4D6D), const Color(0xFFFFD43B), const Color(0xFF34D399)][i].withValues(alpha: on ? 0.8 : 0.2));
    }
  }

  // ---------- الحديقة: أوراق تتطاير وزهور تتمايل على الحافة ----------
  void _leaves(Canvas canvas, Size size) {
    for (var i = 0; i < 9; i++) {
      final x = (i * 0.37 + t * 0.4) % 1;
      if (x > 0.18 && x < 0.82) continue;
      final y = (i / 9 + t * 0.5) % 1;
      canvas.save();
      canvas.translate(size.width * x + math.sin(t * 10 + i) * 10, size.height * y);
      canvas.rotate(t * 8 + i);
      canvas.drawPath(Path()..moveTo(0, -8)..quadraticBezierTo(8, 0, 0, 8)..quadraticBezierTo(-8, 0, 0, -8), Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.4));
      canvas.restore();
    }
    for (var i = 0; i < 5; i++) {
      final base = Offset(size.width * (i.isEven ? 0.04 + i * 0.015 : 0.96 - i * 0.015), size.height * (0.82 + (i % 3) * 0.05));
      final sway = math.sin(t * math.pi * 6 + i) * 6;
      final head = base + Offset(sway, -30);
      canvas.drawLine(base, head, Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.5)
        ..strokeWidth = 2.5);
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5 + t * 2;
        canvas.drawCircle(head + Offset(math.cos(a) * 6, math.sin(a) * 6), 4.5, Paint()..color = [const Color(0xFFFF8FC8), const Color(0xFFFFD43B), const Color(0xFF7FD6FF)][i % 3].withValues(alpha: 0.6));
      }
      canvas.drawCircle(head, 3.5, Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.8));
    }
  }

  void _clouds(Canvas canvas, Size size) {
    for (final (y, sp, s) in [(0.05, 1.0, 1.0), (0.12, 0.6, 0.7)]) {
      final x = ((t * sp) % 1) * (size.width + 160) - 80;
      final c = Offset(x, size.height * y);
      final p = Paint()..color = Colors.white.withValues(alpha: 0.12);
      for (final (dx, dy, r) in [(-20.0, 4.0, 16.0), (0.0, -4.0, 20.0), (22.0, 4.0, 15.0)]) {
        canvas.drawCircle(c + Offset(dx * s, dy * s), r * s, p);
      }
    }
  }

  // ---------- الرحلات: مسار منقط ولافتات وأعلام ----------
  void _trail(Canvas canvas, Size size) {
    final path = Path()..moveTo(size.width * 0.03, 0);
    for (var k = 1; k <= 8; k++) {
      path.quadraticBezierTo(size.width * (k.isEven ? 0.02 : 0.12), size.height * (k - 0.5) / 8, size.width * 0.06, size.height * k / 8);
    }
    final dash = Paint()
      ..color = const Color(0xFFFFD43B).withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (var d = (t * 40) % 16; d < m.length; d += 16) {
        final a = m.getTangentForOffset(d)!.position, b = m.getTangentForOffset(d + 6)?.position ?? a;
        canvas.drawLine(a, b, dash);
      }
    }
    for (final (x, y, col) in [(0.92, 0.25, const Color(0xFFFF5D8F)), (0.9, 0.6, const Color(0xFF34D399)), (0.93, 0.9, const Color(0xFF22D3EE))]) {
      final base = Offset(size.width * x, size.height * y);
      final wave = math.sin(t * math.pi * 8 + y * 10) * 3;
      canvas.drawLine(base, base - const Offset(0, 30), Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2);
      canvas.drawPath(Path()..moveTo(base.dx, base.dy - 30)..lineTo(base.dx - 16, base.dy - 25 + wave)..lineTo(base.dx, base.dy - 20)..close(), Paint()..color = col.withValues(alpha: 0.45));
    }
  }

  // ---------- المسابقات: ستارة مسرح في الزاويتين ----------
  void _curtains(Canvas canvas, Size size) {
    final sway = math.sin(t * math.pi * 4) * 4;
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : size.width;
      final dir = left ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x0, 0)
        ..lineTo(x0 + dir * 46, 0)
        ..quadraticBezierTo(x0 + dir * (20 + sway), 60, x0 + dir * 10, 140)
        ..lineTo(x0, 150)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFE11D48).withValues(alpha: 0.55));
    }
    // حافة مكشكشة أعلى المسرح
    final scallop = Paint()..color = const Color(0xFFFFB020).withValues(alpha: 0.5);
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawArc(Rect.fromLTWH(x, -12, 24, 24), 0, math.pi, true, scallop);
    }
  }

  void _lanterns(Canvas canvas, Size size) {
    final w = size.width;
    final moon = Offset(w * 0.8, 104);
    canvas.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(moon + const Offset(9, -6), 19, Paint()..color = theme.sky.first);
    for (final (x, len, ph) in [(0.06, 96.0, 0.0), (0.2, 80.0, 1.7), (0.94, 88.0, 3.1)]) {
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
        text: TextSpan(text: glyphs[i], style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w800, fontSize: 26 + (i % 3) * 6.0, color: cols[i % cols.length].withValues(alpha: 0.45))),
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
          ..color = const Color(0xFF7FD6FF).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
        final a = t * math.pi * 4 * (k + 1) + ph;
        canvas.drawCircle(Offset(math.cos(a) * r * 1.2, math.sin(a) * r * 0.4), 4, Paint()..color = const Color(0xFF22D3EE).withValues(alpha: 0.6));
        canvas.restore();
      }
      canvas.drawCircle(c, 6, Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.5));
    }
  }

  /// أضواء مسرح المسابقات تتأرجح ببطء.
  void _beams(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (final (x, ph) in [(0.12, 0.0), (0.88, 2.0)]) {
      final sway = math.sin(t * math.pi * 4 + ph) * w * 0.12;
      final top = Offset(w * x, 0);
      final path = Path()
        ..moveTo(top.dx - 14, 0)
        ..lineTo(top.dx + 14, 0)
        ..lineTo(top.dx + sway + w * 0.2, h * 0.6)
        ..lineTo(top.dx + sway - w * 0.2, h * 0.6)
        ..close();
      canvas.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFF3B0).withValues(alpha: 0.28), const Color(0xFFFFF3B0).withValues(alpha: 0)]).createShader(Rect.fromLTWH(0, 0, w, h * 0.6)));
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
        ..color = const Color(0xFFB9A8FF).withValues(alpha: 0.35)
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
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _DecorPainter o) => o.t != t || o.theme != theme || o.scroll != scroll;
}
