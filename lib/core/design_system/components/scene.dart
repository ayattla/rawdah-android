import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/kid_widgets.dart';
import 'package:rawdah/core/design_system/components/lantern.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/parental/time_lock.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/geometry/zellij.dart';

/// خلفية الشاشات: «فضاء الحلوى» بروح قنوات الأطفال.
/// نهارًا: سماء لافندرية تذوب في الأزرق والكريمي، كواكب ملونة بحلقات، قصاصات ملونة،
/// وغيوم منفوخة في الأسفل، مع رواق محاريب خافت في الأعلى توقيعًا لروضة.
/// ليلًا: فضاء بنفسجي عميق بكواكب زاهية ونقاط ضوء.
/// لكل قسم سماؤه وألوان كواكبه، فيشعر الطفل أنه انتقل إلى عالم آخر.
enum SceneTheme {
  home([Color(0xFFEFE8FF), Color(0xFFE5F3FF), Color(0xFFFFF4E2)], Color(0xFF8B5CF6), Color(0xFFFFC23F), Color(0xFFFF7A3D), Color(0xFF14B8A6)),
  quran([Color(0xFFDDF5EE), Color(0xFFE8F4FF), Color(0xFFFFF6E3)], Color(0xFF0F9D8A), Color(0xFFF2B544), Color(0xFF3B9BFF), Color(0xFFF2B544)),
  islamic([Color(0xFFE3F5E9), Color(0xFFF1FAEC), Color(0xFFFFF5E0)], Color(0xFF1F8A5B), Color(0xFFE0A21B), Color(0xFF14B8A6), Color(0xFFE0A21B)),
  learn([Color(0xFFF0E6FF), Color(0xFFFFE8F2), Color(0xFFFFF4E2)], Color(0xFFA855F7), Color(0xFFFF5D8F), Color(0xFFFFC23F), Color(0xFF8B5CF6)),
  science([Color(0xFFDDEEFF), Color(0xFFE2FAFF), Color(0xFFEDE7FF)], Color(0xFF2563EB), Color(0xFF22D3EE), Color(0xFF8B5CF6), Color(0xFF22D3EE)),
  play([Color(0xFFFFEBD9), Color(0xFFFFF7D1), Color(0xFFE6F6FF)], Color(0xFFFF7A3D), Color(0xFFFFC23F), Color(0xFF3B9BFF), Color(0xFFFF5D8F));

  final List<Color> sky;
  final Color planet1, ring1, planet2, ring2;
  const SceneTheme(this.sky, this.planet1, this.ring1, this.planet2, this.ring2);

  /// قسم الشاشات المفتوحة حاليًا: تضبطه الرئيسية عند فتح قسم، فترث شاشاته الداخلية سماءه.
  static SceneTheme active = SceneTheme.home;
}

class ScenePainter extends CustomPainter {
  final bool night;
  final bool plain; // تباين عالٍ: لون واحد بلا زخرفة
  final SceneTheme theme;
  ScenePainter({this.night = false, this.plain = false, this.theme = SceneTheme.home});

  static const _candy = [Color(0xFFFF5D8F), Color(0xFFFFC23F), Color(0xFF14B8A6), Color(0xFF8B5CF6), Color(0xFF3B9BFF), Color(0xFFFF7A3D)];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (plain) {
      canvas.drawRect(rect, Paint()..color = night ? RC.night : RC.sand);
      return;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF1A1145), Color(0xFF2A1A66), Color(0xFF1B2459)]
              : theme.sky,
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    final w = size.width, h = size.height;
    final a = night ? 0.55 : 0.22;

    // مدار منقط كبير يعبر الشاشة
    final orbit = Paint()
      ..color = (night ? Colors.white : const Color(0xFF8B5CF6)).withValues(alpha: night ? 0.12 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final oval = Rect.fromCenter(center: Offset(w * 0.55, h * 0.32), width: w * 1.5, height: h * 0.34);
    for (var t = 0.0; t < 2 * math.pi; t += 0.09) {
      canvas.drawArc(oval, t, 0.045, false, orbit);
    }

    _planet(canvas, Offset(w * 0.88, h * 0.10), w * 0.13, theme.planet1.withValues(alpha: a), theme.ring1.withValues(alpha: a + 0.06));
    _planet(canvas, Offset(w * 0.06, h * 0.62), w * 0.16, theme.planet2.withValues(alpha: a), theme.ring2.withValues(alpha: a + 0.06));
    canvas.drawCircle(Offset(w * 0.18, h * 0.22), w * 0.045, Paint()..color = const Color(0xFF14B8A6).withValues(alpha: a));
    canvas.drawCircle(Offset(w * 0.80, h * 0.78), w * 0.06, Paint()..color = const Color(0xFFFF5D8F).withValues(alpha: a * 0.8));

    // قصاصات ملونة: دوائر صغيرة وكبسولات مائلة
    final r = math.Random(night ? 11 : 5);
    for (var i = 0; i < 42; i++) {
      final c = _candy[i % _candy.length].withValues(alpha: night ? 0.55 : 0.30);
      final p = Offset(r.nextDouble() * w, r.nextDouble() * h);
      if (i % 3 == 0) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(r.nextDouble() * math.pi);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 14, height: 5), const Radius.circular(3)), Paint()..color = c);
        canvas.restore();
      } else {
        canvas.drawCircle(p, r.nextDouble() * 2.6 + 1.6, Paint()..color = c);
      }
    }

    if (!night) {
      // رواق محاريب خافت في الأعلى: توقيع روضة
      ZellijPainter(color: const Color(0xFF8B5CF6).withValues(alpha: 0.06), fadeTo: 0.3).paint(canvas, size);
      // غيوم منفوخة في الأسفل
      final cloud = Paint()..color = Colors.white.withValues(alpha: 0.75);
      for (var i = -1; i < 6; i++) {
        final cx = i * w / 4.2 + (i.isEven ? 0 : w * 0.05);
        final base = h + 10;
        canvas.drawCircle(Offset(cx, base - 30), w * 0.11, cloud);
        canvas.drawCircle(Offset(cx + w * 0.10, base - 52), w * 0.12, cloud);
        canvas.drawCircle(Offset(cx + w * 0.20, base - 26), w * 0.10, cloud);
      }
    }
  }

  void _planet(Canvas canvas, Offset c, double r, Color body, Color ring) {
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    final oval = Rect.fromCenter(center: c, width: r * 3.0, height: r * 0.9);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.4);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(oval, math.pi, math.pi, false, ringPaint);
    canvas.drawCircle(c, r, Paint()..color = body);
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.35), r * 0.28, Paint()..color = Colors.white.withValues(alpha: 0.18));
    canvas.drawArc(oval, 0, math.pi, false, ringPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) => old.night != night || old.plain != plain || old.theme != theme;
}

class SceneBackground extends StatelessWidget {
  final Widget child;
  final bool night;
  final SceneTheme? theme;
  const SceneBackground({super.key, required this.child, this.night = false, this.theme});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(
          painter: ScenePainter(night: night, plain: A11y.highContrastOf(context), theme: theme ?? SceneTheme.active), child: SafeArea(child: child));
}


/// يخبر العناصر داخل الشاشة أن الخلفية ليلية (لتصبح النصوص فاتحة).
class NightScope extends InheritedWidget {
  final bool night;
  const NightScope({super.key, required this.night, required super.child});
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<NightScope>()?.night ?? false;
  @override
  bool updateShouldNotify(NightScope old) => old.night != night;
}

/// يغلّف شاشات الطفل: عند انتهاء الوقت اليومي تظهر شاشة الاستراحة.
class ChildShell extends StatelessWidget {
  /// شاشة القفل تُسجَّل من ميزة الوالدين في main (حتى لا يعتمد نظام التصميم على الميزات).
  static Widget Function(BuildContext context, LockReason reason)? lockScreenBuilder;

  final Widget child;
  final bool night;
  final SceneTheme? theme;
  const ChildShell({super.key, required this.child, this.night = false, this.theme});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final reason = st.lockReason;
    if (reason != LockReason.none && lockScreenBuilder != null) return lockScreenBuilder!(context, reason);
    if (reason != LockReason.none) {
      return Scaffold(
        body: SceneBackground(
          night: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Lantern(size: 130, glow: 0.15),
                const SizedBox(height: 20),
                Text('انتهى وقت اليوم', style: RT.display(32, color: Colors.white)),
                const SizedBox(height: 10),
                Text('أحسنت اليوم يا ${st.current?.name ?? ''}. نرتاح الآن ونلتقي غدًا بإذن الله.',
                    textAlign: TextAlign.center, style: RT.body(20, color: Colors.white70)),
                const SizedBox(height: 26),
                PrimaryButton(
                  label: 'تبديل الطفل',
                  icon: Icons.swap_horiz_rounded,
                  color: RC.plum,
                  onTap: () {
                    st.leaveChild();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ]),
            ),
          ),
        ),
      );
    }
    final t = theme ?? SceneTheme.active;
    if (night || A11y.highContrastOf(context)) {
      return Scaffold(body: SceneBackground(night: night, theme: t, child: NightScope(night: night, child: child)));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1145),
      body: CandyScreen(theme: t, child: NightScope(night: false, child: child)),
    );
  }
}


/// «شاشة التلفاز» الكرتونية: فضاء بنفسجي في الخارج، وإطار حلوى متموج بحد ملون سميك
/// وزرين وهوائي، وداخله سماء القسم الفاتحة حيث يُقرأ المحتوى بوضوح.
class CandyScreen extends StatelessWidget {
  final SceneTheme theme;
  final Widget child;
  const CandyScreen({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpacePainter(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: LayoutBuilder(builder: (context, box) {
            final rect = Offset.zero & Size(box.maxWidth, box.maxHeight);
            final frame = wobblyFramePath(rect.deflate(5));
            final inner = wobblyFramePath(rect.deflate(14), radius: 26, amp: 2.4);
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _FramePainter(frame, theme)))),
              Positioned.fill(
                child: ClipPath(
                  clipper: _PathClipper(inner),
                  child: CustomPaint(painter: ScenePainter(theme: theme), child: child),
                ),
              ),
              // هوائي وزران يطفوان: لمسة التلفاز الكرتوني
              const PositionedDirectional(top: -8, start: 54, child: _Bobber(child: _Knob(color: Color(0xFFFF5D8F), size: 16))),
              const PositionedDirectional(bottom: -6, end: 34, child: _Bobber(delay: 0.5, child: _Knob(color: Color(0xFFFFC23F), size: 18))),
              const PositionedDirectional(bottom: -4, end: 58, child: _Bobber(delay: 0.25, child: _Knob(color: Color(0xFF22D3EE), size: 12))),
            ]);
          }),
        ),
      ),
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  final Path path;
  _PathClipper(this.path);
  @override
  Path getClip(Size size) => path;
  @override
  bool shouldReclip(covariant _PathClipper old) => old.path != path;
}

/// الإطار: حد كرتوني غامق، شريط حلوى متدرج الألوان، ولمعة بيضاء.
class _FramePainter extends CustomPainter {
  final Path frame;
  final SceneTheme theme;
  _FramePainter(this.frame, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final b = frame.getBounds();
    canvas.drawPath(frame.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF0E0A2E));
    canvas.drawPath(
      frame,
      Paint()
        ..shader = SweepGradient(
          colors: [theme.ring1, const Color(0xFFFF5D8F), theme.planet1, const Color(0xFF22D3EE), theme.planet2, theme.ring1],
        ).createShader(b),
    );
    canvas.drawPath(
      frame,
      Paint()
        ..color = const Color(0xFF2A1A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // لمعة على الحافة العلوية
    final gloss = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(b.left + 46, b.top + 6), Offset(b.left + b.width * 0.42, b.top + 5), gloss);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.frame != frame || old.theme != theme;
}

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241466), Color(0xFF1A1145), Color(0xFF2B1B7A)],
        ).createShader(rect),
    );
    final r = math.Random(3);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), r.nextDouble() * 1.4 + 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.5 + r.nextDouble() * 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Knob extends StatelessWidget {
  final Color color;
  final double size;
  const _Knob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(-0.4, -0.4), colors: [Colors.white.withValues(alpha: 0.9), color]),
          border: Border.all(color: const Color(0xFF2A1A66), width: 2),
        ),
      );
}

/// يرفع عنصرًا صغيرًا وينزله برفق بلا توقف (يتوقف مع «تقليل الحركة»).
class _Bobber extends StatefulWidget {
  final Widget child;
  final double delay;
  const _Bobber({required this.child, this.delay = 0});
  @override
  State<_Bobber> createState() => _BobberState();
}

class _BobberState extends State<_Bobber> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (A11y.reduceMotionOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.value = widget.delay;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(0, -3 * Curves.easeInOut.transform(_c.value)), child: child),
        child: widget.child,
      );
}
