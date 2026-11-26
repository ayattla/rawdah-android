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
class ScenePainter extends CustomPainter {
  final bool night;
  final bool plain; // تباين عالٍ: لون واحد بلا زخرفة
  ScenePainter({this.night = false, this.plain = false});

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
              : const [Color(0xFFEFE8FF), Color(0xFFE5F3FF), Color(0xFFFFF4E2)],
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

    _planet(canvas, Offset(w * 0.88, h * 0.10), w * 0.13, const Color(0xFF8B5CF6).withValues(alpha: a), const Color(0xFFFFC23F).withValues(alpha: a + 0.06));
    _planet(canvas, Offset(w * 0.06, h * 0.62), w * 0.16, const Color(0xFFFF7A3D).withValues(alpha: a), const Color(0xFF14B8A6).withValues(alpha: a + 0.06));
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
  bool shouldRepaint(covariant ScenePainter old) => old.night != night || old.plain != plain;
}

class SceneBackground extends StatelessWidget {
  final Widget child;
  final bool night;
  const SceneBackground({super.key, required this.child, this.night = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(
          painter: ScenePainter(night: night, plain: A11y.highContrastOf(context)), child: SafeArea(child: child));
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
  const ChildShell({super.key, required this.child, this.night = false});

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
    return Scaffold(body: SceneBackground(night: night, child: NightScope(night: night, child: child)));
  }
}
