import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/games/presentation/games_hub_screen.dart';
import 'package:rawdah/features/islamic/presentation/islamic_screens.dart';
import 'package:rawdah/features/learn/presentation/words_numbers_screens.dart';
import 'package:rawdah/features/planets/data/planets_content.dart';
import 'package:rawdah/features/science/data/science_content.dart';
import 'package:rawdah/features/science/presentation/science_screens.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';
import 'package:rawdah/features/workshop/workshop_screens.dart';

/// وجهة كوكب: اسمه ووصفه وأيقونته ولونه والشاشة التي يفتحها.
class PlanetDest {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final SceneTheme theme;
  const PlanetDest(this.title, this.hint, this.icon, this.color, this.builder, this.theme);
}

final kPlanets = <PlanetDest>[
  PlanetDest('كوكب أبجد', 'حروف وأرقام وحساب', Icons.abc_rounded, const Color(0xFFA855F7), (_) => const LearnHubScreen(), SceneTheme.learn),
  PlanetDest('كوكب تاريخ', 'الأنبياء والصحابة', Icons.history_edu_rounded, const Color(0xFFFF9F1C),
      (_) => TopicHubScreen(title: 'كوكب تاريخ', topics: kTarikhTopics, extras: [
            HubExtra('بيت القصص', 'قصص نتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen()),
            HubExtra('السيرة النبوية', 'محطات من حياة النبي ﷺ', Icons.route_rounded, const Color(0xFF1F5E4A), (_) => const SeerahScreen()),
          ]),
      SceneTheme.islamic),
  PlanetDest('كوكب مغامرات', 'ألعاب تعليمية', Icons.explore_rounded, const Color(0xFFFF5D5D), (_) => const GamesHubScreen(), SceneTheme.play),
  PlanetDest('كوكب رياضة', 'تمارين وصحة', Icons.sports_soccer_rounded, const Color(0xFF22C55E), (_) => const SportsScreen(), SceneTheme.play),
  PlanetDest('كوكب معرفة', 'علماء واختراعات', Icons.lightbulb_rounded, const Color(0xFF3B82F6),
      (_) => TopicHubScreen(title: 'كوكب معرفة', topics: kMaarifaTopics, extras: [
            HubExtra('عالم العلوم', 'الفضاء والماء وبلادي', Icons.science_rounded, RC.night, (_) => const ScienceHubScreen()),
            HubExtra('ورشة المخترع', 'كهرباء وآلات وأفكار', Icons.construction_rounded, const Color(0xFF0F766E), (_) => const WorkshopScreen()),
          ]),
      SceneTheme.science),
  PlanetDest('كوكب زمردة', 'درر المسلمة', Icons.diamond_rounded, const Color(0xFF10B981),
      (_) => const TopicHubScreen(title: 'كوكب زمردة', topics: kZumurrudaTopics), SceneTheme.islamic),
  PlanetDest('كوكب بون بون', 'أشكال وألوان للصغار', Icons.bubble_chart_rounded, const Color(0xFFFF5D8F), (_) => const BonBonScreen(), SceneTheme.learn),
];

/// قسم كواكب المعرفة: فضاء صاف وكواكب على مدار.
class PlanetsScreen extends StatelessWidget {
  const PlanetsScreen({super.key});

  Future<void> _open(BuildContext context, PlanetDest p) async {
    Voice.instance.say(p.title);
    final back = SceneTheme.active;
    SceneTheme.active = p.theme;
    await Navigator.of(context).push(WarpRoute<void>(builder: p.builder, title: p.title, color: p.color, icon: p.icon));
    SceneTheme.active = back;
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      night: true,
      child: Column(children: [
        const KidBar(title: 'كواكب المعرفة'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: _PlanetMap(places: kPlanets, onOpen: (p) => _open(context, p)),
          ),
        ),
      ]),
    );
  }
}

/// خريطة الكواكب: كل قسم كوكب بلونه على مدار منقط متعرج، يطفو برفق ويقفز عند لمسه.
class _PlanetMap extends StatefulWidget {
  final List<PlanetDest> places;
  final void Function(PlanetDest) onOpen;
  const _PlanetMap({required this.places, required this.onOpen});

  @override
  State<_PlanetMap> createState() => _PlanetMapState();
}

class _PlanetMapState extends State<_PlanetMap> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  static const _rowH = 175.0;

  /// ألوان كواكب زاهية تضيء على الفضاء الداكن (ألوان الأقسام الداكنة تختفي عليه).
  static const _vivid = [
    Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFFF5D5D), Color(0xFFA855F7), Color(0xFF3B82F6), Color(0xFF84CC16),
    Color(0xFFFF9F1C), Color(0xFFFF5D8F), Color(0xFF22D3EE), Color(0xFFFFC23F), Color(0xFF8B5CF6),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (A11y.reduceMotionOf(context)) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.places.length;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final rowH = _rowH * scale;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      // مواضع الكواكب: يمين ثم يسار بالتناوب مع انحراف بسيط حتى لا يبدو جامدًا
      final centers = [
        for (var i = 0; i < n; i++)
          Offset(w * (i.isEven ? 0.30 : 0.70) + (i % 3 - 1) * 10, rowH * i + rowH * 0.42),
      ];
      return SizedBox(
        height: rowH * n + 10,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _OrbitPathPainter(centers))),
          for (var i = 0; i < n; i++)
            Positioned(
              left: centers[i].dx - 80,
              top: centers[i].dy - 80,
              width: 160,
              child: AnimatedBuilder(
                animation: _t,
                builder: (_, child) {
                  final ph = _t.value * 2 * math.pi + i * 0.9;
                  return Transform.translate(offset: Offset(0, math.sin(ph) * 4), child: child);
                },
                child: _PlanetButton(
                  index: i,
                  place: widget.places[i],
                  color: _vivid[i % _vivid.length],
                  size: i == 0 ? 92 : 80,
                  ringed: i % 2 == 0,
                  spin: _t,
                  onTap: () => widget.onOpen(widget.places[i]),
                ),
              ),
            ),
        ]),
      );
    });
  }
}

class _OrbitPathPainter extends CustomPainter {
  final List<Offset> pts;
  _OrbitPathPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final midY = (a.dy + b.dy) / 2;
      p.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    canvas.drawPath(p, Paint()
      ..color = const Color(0xFF7C6BFF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round);
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 18) {
        final a = m.getTangentForOffset(d)!.position, b = m.getTangentForOffset(d + 4)?.position ?? a;
        canvas.drawLine(a, b, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPathPainter old) => old.pts.length != pts.length || old.pts.first != pts.first;
}

/// كوكب القسم: كرة ملونة بحد غامق ولمعة، وحلقة تدور ببطء، والأيقونة في وسطه، والاسم تحته.
class _PlanetButton extends StatefulWidget {
  final int index;
  final PlanetDest place;
  final Color color;
  final double size;
  final bool ringed;
  final Animation<double> spin;
  final VoidCallback onTap;
  const _PlanetButton({required this.index, required this.place, required this.color, required this.size, required this.ringed, required this.spin, required this.onTap});

  @override
  State<_PlanetButton> createState() => _PlanetButtonState();
}

class _PlanetButtonState extends State<_PlanetButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final s = widget.size;
    return Semantics(
      button: true,
      label: '${p.title}، ${p.hint}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (d) {
          WarpRoute.lastTap = d.globalPosition;
          setState(() => _down = true);
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          Haptics.tap();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.88 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: s * 1.5,
              height: s * 1.3,
              child: AnimatedBuilder(
                animation: widget.spin,
                builder: (_, __) => CustomPaint(
                  painter: _PlanetBodyPainter(widget.color, widget.ringed, widget.spin.value, widget.index),
                  child: Align(alignment: const Alignment(0, 0.24), child: Icon(p.icon, color: Colors.white, size: s * 0.40)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // لافتة الاسم تغطي المدار خلفها فلا يتداخل الخط مع النص
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A1A66), width: 3),
                boxShadow: const [BoxShadow(color: Color(0xFF2A1A66), offset: Offset(0, 3))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(p.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RT.display(16, color: const Color(0xFF2A1A66))),
                Text(p.hint,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RT.body(12, color: const Color(0xFF5B4BA8))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlanetBodyPainter extends CustomPainter {
  final Color color;
  final bool ringed;
  final double t;
  final int index;
  _PlanetBodyPainter(this.color, this.ringed, this.t, this.index);

  static const _ink = Color(0xFF2A1A66);

  /// مبان كرتونية صغيرة فوق كل كوكب: أبراج حروف، أعمدة، أعلام، مرصد، بلورات، ملاعب، حلوى.
  void _buildings(Canvas canvas, Offset top, double r) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    void box(Rect b, Color col) {
      final rr = RRect.fromRectAndRadius(b, Radius.circular(b.width * 0.25));
      canvas.drawRRect(rr, Paint()..color = col);
      canvas.drawRRect(rr, ink);
    }

    final u = r * 0.22;
    switch (index % 7) {
      case 0: // أبراج ملونة
        box(Rect.fromLTWH(top.dx - u * 1.6, top.dy - u * 1.4, u * 0.9, u * 1.6), const Color(0xFFFF4FA8));
        box(Rect.fromLTWH(top.dx - u * 0.45, top.dy - u * 2.0, u * 0.9, u * 2.2), const Color(0xFF3A8BFF));
        box(Rect.fromLTWH(top.dx + u * 0.7, top.dy - u * 1.2, u * 0.9, u * 1.4), const Color(0xFF34C759));
      case 1: // أعمدة
        final roof = Path()
          ..moveTo(top.dx - u * 1.6, top.dy - u * 1.6)
          ..lineTo(top.dx, top.dy - u * 2.3)
          ..lineTo(top.dx + u * 1.6, top.dy - u * 1.6)
          ..close();
        for (final dx in [-1.2, -0.25, 0.7]) {
          box(Rect.fromLTWH(top.dx + dx * u, top.dy - u * 1.6, u * 0.5, u * 1.8), Colors.white);
        }
        canvas.drawPath(roof, Paint()..color = const Color(0xFFFFD43B));
        canvas.drawPath(roof, ink);
      case 2: // أعلام
        for (final (dx, col) in [(-0.6, const Color(0xFFFF4FA8)), (0.6, const Color(0xFFFFD43B))]) {
          final x = top.dx + dx * u;
          canvas.drawLine(Offset(x, top.dy + u * 0.2), Offset(x, top.dy - u * 2), ink);
          final f = Path()
            ..moveTo(x, top.dy - u * 2)
            ..lineTo(x + u * 1.1, top.dy - u * 1.65)
            ..lineTo(x, top.dy - u * 1.3)
            ..close();
          canvas.drawPath(f, Paint()..color = col);
          canvas.drawPath(f, ink);
        }
      case 3: // ملعب: كرة على عمود
        canvas.drawLine(Offset(top.dx, top.dy + u * 0.2), Offset(top.dx, top.dy - u * 1.2), ink);
        canvas.drawCircle(Offset(top.dx, top.dy - u * 1.6), u * 0.6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(top.dx, top.dy - u * 1.6), u * 0.6, ink);
      case 4: // مرصد
        final dome = Path()
          ..moveTo(top.dx - u, top.dy + u * 0.2)
          ..lineTo(top.dx - u, top.dy - u * 0.6)
          ..arcToPoint(Offset(top.dx + u, top.dy - u * 0.6), radius: Radius.circular(u))
          ..lineTo(top.dx + u, top.dy + u * 0.2)
          ..close();
        canvas.drawPath(dome, Paint()..color = Colors.white);
        canvas.drawPath(dome, ink);
        canvas.drawLine(Offset(top.dx + u * 0.2, top.dy - u * 1.2), Offset(top.dx + u * 1.4, top.dy - u * 2.1), ink..strokeWidth = 5);
        ink.strokeWidth = 2.2;
      case 5: // بلورات زمرد
        for (final (dx, hgt) in [(-0.8, 1.4), (0.0, 2.0), (0.8, 1.2)]) {
          final x = top.dx + dx * u;
          final g = Path()
            ..moveTo(x - u * 0.38, top.dy + u * 0.2)
            ..lineTo(x - u * 0.38, top.dy - u * hgt * 0.7)
            ..lineTo(x, top.dy - u * hgt)
            ..lineTo(x + u * 0.38, top.dy - u * hgt * 0.7)
            ..lineTo(x + u * 0.38, top.dy + u * 0.2)
            ..close();
          canvas.drawPath(g, Paint()..color = const Color(0xFF6EE7B7));
          canvas.drawPath(g, ink);
        }
      default: // حلوى مستديرة على عود
        for (final (dx, col) in [(-0.7, const Color(0xFFFFD43B)), (0.7, const Color(0xFF22D3EE))]) {
          final x = top.dx + dx * u;
          canvas.drawLine(Offset(x, top.dy + u * 0.2), Offset(x, top.dy - u), ink);
          canvas.drawCircle(Offset(x, top.dy - u * 1.4), u * 0.55, Paint()..color = col);
          canvas.drawCircle(Offset(x, top.dy - u * 1.4), u * 0.55, ink);
        }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero) + Offset(0, size.height * 0.12);
    final r = size.height / 1.3 / 2 * 0.92;
    _buildings(canvas, c - Offset(0, r * 0.92), r);
    final hsl = HSLColor.fromColor(color);
    final dark = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
    final light = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final ringColor = HSLColor.fromColor(color).withHue((hsl.hue + 40) % 360).withSaturation(0.9).withLightness(0.62).toColor();
    final tilt = -0.32 + math.sin(t * 2 * math.pi) * 0.06;
    final oval = Rect.fromCenter(center: c, width: r * 3.1, height: r * 0.8);
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    void rotated(void Function() draw) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      canvas.translate(-c.dx, -c.dy);
      draw();
      canvas.restore();
    }

    if (ringed) rotated(() => canvas.drawArc(oval, math.pi, math.pi, false, ring));
    canvas.drawCircle(c + Offset(0, r * 0.08), r, Paint()..color = dark);
    canvas.drawCircle(c, r, Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.5), colors: [light, color, dark]).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r, Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);
    // قمر صغير يدور حول الكوكب
    final ma = t * 2 * math.pi + index;
    final mp = c + Offset(math.cos(ma) * r * 1.35, math.sin(ma) * r * 0.45);
    if (math.sin(ma) > -0.2) {
      canvas.drawCircle(mp, r * 0.14, Paint()..color = const Color(0xFFE9E4FF));
      canvas.drawCircle(mp, r * 0.14, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    // فوهتان صغيرتان ولمعة
    canvas.drawCircle(c + Offset(r * 0.42, r * 0.38), r * 0.13, Paint()..color = dark.withValues(alpha: 0.35));
    canvas.drawCircle(c + Offset(-r * 0.5, r * 0.45), r * 0.08, Paint()..color = dark.withValues(alpha: 0.3));
    canvas.drawCircle(c + Offset(-r * 0.4, -r * 0.42), r * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.45));
    if (ringed) {
      rotated(() {
        canvas.drawArc(oval, 0, math.pi, false, ring);
        canvas.drawArc(oval, 0, math.pi, false, Paint()
          ..color = dark.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
      });
    }
  }

  @override
  bool shouldRepaint(covariant _PlanetBodyPainter old) => old.t != t || old.color != color || old.index != index;
}


/// بطاقة إضافية في مركز الكوكب (شاشة موجودة).
class HubExtra {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const HubExtra(this.title, this.subtitle, this.icon, this.color, this.builder);
}

/// مركز كوكب: مواضيع بطاقات ومسابقة، وروابط لأقسام قريبة.
class TopicHubScreen extends StatelessWidget {
  final String title;
  final List<ScienceTopic> topics;
  final List<HubExtra> extras;
  const TopicHubScreen({super.key, required this.title, required this.topics, this.extras = const []});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return ChildShell(
      child: Column(children: [
        KidBar(title: title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final t in topics) ...[
              BigTile(
                title: t.title,
                subtitle: t.subtitle,
                icon: t.icon,
                color: t.color,
                done: c.completed.contains(t.completionId),
                onTap: () => open(ScienceTopicScreen(topic: t)),
              ),
              const SizedBox(height: 12),
            ],
            for (final e in extras) ...[
              BigTile(title: e.title, subtitle: e.subtitle, icon: e.icon, color: e.color, onTap: () => open(e.builder(context))),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// كوكب رياضة: مواضيع الرياضة، وجلسة تمارين بعداد وقت.
class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'كوكب رياضة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BigTile(
              title: 'تمارين اليوم',
              subtitle: '${exercisesFor(c.ageBand).length} تمارين قصيرة مع عداد',
              icon: Icons.timer_rounded,
              color: const Color(0xFFEA580C),
              done: c.completed.contains('exercise_${todayKey()}'),
              onTap: () => open(ExerciseScreen(exercises: exercisesFor(c.ageBand))),
            ),
            const SizedBox(height: 12),
            for (final t in kRiyadaTopics) ...[
              BigTile(
                title: t.title,
                subtitle: t.subtitle,
                icon: t.icon,
                color: t.color,
                done: c.completed.contains(t.completionId),
                onTap: () => open(ScienceTopicScreen(topic: t)),
              ),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// جلسة تمارين: اسم التمرين وطريقته وحلقة عد تنازلي، ثم التالي تلقائيا.
class ExerciseScreen extends StatefulWidget {
  final List<Exercise> exercises;
  const ExerciseScreen({super.key, required this.exercises});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _i = 0;
  int _left = 0;
  bool _running = false;
  Timer? _timer;

  Exercise get _e => widget.exercises[_i];

  @override
  void initState() {
    super.initState();
    _left = _e.seconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    Voice.instance.say(_e.name);
    Haptics.tap();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!mounted) return;
    if (_left > 1) {
      setState(() => _left--);
      if (_left <= 3) Haptics.tap();
      return;
    }
    _timer?.cancel();
    Haptics.success();
    if (_i + 1 >= widget.exercises.length) {
      setState(() => _running = false);
      AppScope.read(context).complete('exercise_${todayKey()}', stars: 3);
      await showReward(context, stars: 3, title: 'بطل! أنهيت تمارين اليوم');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _left = _e.seconds;
      _running = false;
    });
    Voice.instance.say('التالي: ${_e.name}');
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    final total = e.seconds;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'تمرين ${_i + 1} من ${widget.exercises.length}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _left / total,
                      strokeWidth: 14,
                      color: const Color(0xFFEA580C),
                      backgroundColor: RC.sandDark,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e.icon, size: 54, color: const Color(0xFFEA580C)),
                    Text('$_left', style: RT.display(48)),
                    Text('ثانية', style: RT.body(14, color: RC.inkSoft)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Text(e.name, textAlign: TextAlign.center, style: RT.display(26)),
            const SizedBox(height: 8),
            Text(e.how, textAlign: TextAlign.center, style: RT.body(18)),
            const SizedBox(height: 22),
            PrimaryButton(
              label: _running ? 'إيقاف مؤقت' : (_left == total ? 'ابدأ' : 'كمل'),
              icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFFEA580C),
              onTap: _toggle,
            ),
            const SizedBox(height: 10),
            Text('إذا تعبت ارتح واشرب ماء', textAlign: TextAlign.center, style: RT.body(14, color: RC.inkSoft)),
          ]),
        ),
      ]),
    );
  }
}

/// كوكب بون بون: «المس الشكل كذا» بين أربعة أشكال ملونة.
class BonBonScreen extends StatefulWidget {
  final math.Random? random;
  const BonBonScreen({super.key, this.random});

  @override
  State<BonBonScreen> createState() => _BonBonScreenState();
}

class _BonBonScreenState extends State<BonBonScreen> {
  late final math.Random _r = widget.random ?? math.Random();
  static const _rounds = 6;
  int _i = 0, _right = 0;
  bool _missed = false;
  int? _wrong;
  late List<ShapeItem> _opts;
  late ShapeItem _target;

  @override
  void initState() {
    super.initState();
    _make();
  }

  void _make() {
    _opts = ([...kShapes]..shuffle(_r)).take(4).toList();
    _target = _opts[_r.nextInt(4)];
    _missed = false;
    _wrong = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say('المس ال${_target.name}'));
  }

  Future<void> _tap(int k) async {
    if (_opts[k] != _target) {
      Haptics.error();
      setState(() {
        _wrong = k;
        _missed = true;
      });
      return;
    }
    if (!_missed) _right++;
    Haptics.success();
    Voice.instance.say('أحسنت، ${_target.name} ${_target.colorName}');
    if (_i + 1 >= _rounds) {
      final stars = _right >= _rounds ? 3 : (_right >= _rounds - 2 ? 2 : 1);
      AppScope.read(context).complete('bonbon_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'عرفت الأشكال كلها!');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _make();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'كوكب بون بون ${_i + 1} / $_rounds'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('المس ال${_target.name}', textAlign: TextAlign.center, style: RT.display(28)),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(18),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              for (var k = 0; k < _opts.length; k++)
                Chunky(
                  key: ValueKey('shape_${_i}_$k'),
                  color: _wrong == k ? const Color(0xFFFDE2E0) : Colors.white,
                  border: Border.all(color: const Color(0xFF2A1A66), width: 3),
                  radius: 26,
                  depth: 6,
                  onTap: () => _tap(k),
                  semanticLabel: _opts[k].name,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: CustomPaint(painter: _ShapePainter(_opts[k])),
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Voice.instance.say('المس ال${_target.name}'),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('اسمع'),
        ),
        const SizedBox(height: 10),
      ]),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeItem s;
  _ShapePainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final fill = Paint()..color = s.color;
    final edge = Paint()
      ..color = const Color(0xFF2A1A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    Path path;
    switch (s.sides) {
      case 0:
        path = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case 4:
        path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCircle(center: c, radius: r * 0.9), const Radius.circular(10)));
      case 3:
        path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r * 0.8)
          ..lineTo(c.dx - r, c.dy + r * 0.8)
          ..close();
      case -4:
        path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 2, height: r * 1.2), const Radius.circular(10)));
      case -2:
        path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.75, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.75, c.dy)
          ..close();
      default:
        path = Path()
          ..moveTo(c.dx, c.dy + r * 0.85)
          ..cubicTo(c.dx - r * 1.3, c.dy - r * 0.1, c.dx - r * 0.5, c.dy - r * 1.0, c.dx, c.dy - r * 0.35)
          ..cubicTo(c.dx + r * 0.5, c.dy - r * 1.0, c.dx + r * 1.3, c.dy - r * 0.1, c.dx, c.dy + r * 0.85)
          ..close();
    }
    canvas.drawPath(path.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF2A1A66).withValues(alpha: 0.25));
    canvas.drawPath(path, fill);
    canvas.drawPath(path, edge);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.s != s;
}
