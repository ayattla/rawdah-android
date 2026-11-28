import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/cosmos.dart';
import 'package:rawdah/core/design_system/components/live_scene.dart';
import 'package:rawdah/core/design_system/components/studio_backdrop.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/kid_widgets.dart';
import 'package:rawdah/core/design_system/components/lantern.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/parental/time_lock.dart';
import 'package:rawdah/core/state/app_state.dart';

/// خلفية الشاشات: «فضاء الحلوى» بروح قنوات الأطفال.
/// نهارًا: سماء لافندرية تذوب في الأزرق والكريمي، كواكب ملونة بحلقات، قصاصات ملونة،
/// وغيوم منفوخة في الأسفل، مع رواق محاريب خافت في الأعلى توقيعًا لروضة.
/// ليلًا: فضاء بنفسجي عميق بكواكب زاهية ونقاط ضوء.
/// لكل قسم سماؤه وألوان كواكبه، فيشعر الطفل أنه انتقل إلى عالم آخر.
enum SceneTheme {
  home([Color(0xFF241466), Color(0xFF2E1A84), Color(0xFF1A1150)], Color(0xFF8B5CF6), Color(0xFFFFC23F), Color(0xFFFF7A3D), Color(0xFF14B8A6)),
  quran([Color(0xFF0B2A4A), Color(0xFF0F3D5C), Color(0xFF0A2236)], Color(0xFF0F9D8A), Color(0xFFF2B544), Color(0xFF3B9BFF), Color(0xFFF2B544)),
  islamic([Color(0xFF0B2A4A), Color(0xFF0F3D5C), Color(0xFF0A2236)], Color(0xFF1F8A5B), Color(0xFFE0A21B), Color(0xFF14B8A6), Color(0xFFE0A21B)),
  learn([Color(0xFF3A0F5C), Color(0xFF55197A), Color(0xFF2A0B45)], Color(0xFFA855F7), Color(0xFFFF5D8F), Color(0xFFFFC23F), Color(0xFF8B5CF6)),
  science([Color(0xFF0B1E5C), Color(0xFF13307E), Color(0xFF0A1640)], Color(0xFF2563EB), Color(0xFF22D3EE), Color(0xFF8B5CF6), Color(0xFF22D3EE)),
  play([Color(0xFF3B0A6B), Color(0xFF2A0A5A), Color(0xFF160636)], Color(0xFFFF7A3D), Color(0xFFFFC23F), Color(0xFF3B9BFF), Color(0xFFFF5D8F));

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
  final List<Color> skyColors;
  ScenePainter({this.night = false, this.plain = false, this.theme = SceneTheme.home}) : skyColors = nightSky;

  /// ألوان سماء الليل، يغيرها الطفل من المتجر.
  static List<Color> nightSky = const [Color(0xFF1E1458), Color(0xFF261A6E), Color(0xFF1A1450)];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (plain) {
      canvas.drawRect(rect, Paint()..color = night ? RC.night : RC.sand);
      return;
    }
    final w = size.width, h = size.height;
    if (night) {
      // فضاء بنفسجي صافٍ بنقاط ضوء فقط: الكواكب في الرئيسية هي الزينة
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: skyColors,
          ).createShader(rect),
      );
      final r = math.Random(7);
      for (var i = 0; i < 70; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h), r.nextDouble() * 1.5 + 0.4,
            Paint()..color = Colors.white.withValues(alpha: 0.35 + r.nextDouble() * 0.45));
      }
      return;
    }
    // صفحات الأقسام: سماء القسم الهادئة، وكوكبه كبيرًا في الزاوية العليا كأننا نقف عنده
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.sky, stops: const [0, 0.55, 1])
            .createShader(rect),
    );
    if (theme == SceneTheme.islamic || theme == SceneTheme.quran || theme == SceneTheme.learn || theme == SceneTheme.play) return;
    _planet(canvas, Offset(w * 0.92, h * 0.06), w * 0.22, theme.planet1.withValues(alpha: 0.22), theme.ring1.withValues(alpha: 0.30));
    canvas.drawCircle(Offset(w * 0.62, h * 0.035), w * 0.03, Paint()..color = theme.planet2.withValues(alpha: 0.25));
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
  bool shouldRepaint(covariant ScenePainter old) => old.night != night || old.plain != plain || old.theme != theme || old.skyColors != skyColors;
}

class SceneBackground extends StatelessWidget {
  final Widget child;
  final bool night;
  final SceneTheme? theme;
  const SceneBackground({super.key, required this.child, this.night = false, this.theme});

  @override
  Widget build(BuildContext context) {
    final plain = A11y.highContrastOf(context);
    if (night && !plain) return CosmosBackground(sky: ScenePainter.nightSky, child: SafeArea(child: child));
    if (!night && !plain) return LiveScene(theme: theme ?? SceneTheme.active, child: SafeArea(child: child));
    return CustomPaint(painter: ScenePainter(night: night, plain: plain, theme: theme ?? SceneTheme.active), child: SafeArea(child: child));
  }
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

  /// خلفية استوديو البث (للرئيسية فقط).
  final bool studio;
  const ChildShell({super.key, required this.child, this.night = false, this.theme, this.studio = false});

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
    if (studio && !A11y.highContrastOf(context)) {
      return Scaffold(body: StudioBackdrop(sky: ScenePainter.nightSky, child: SafeArea(child: NightScope(night: true, child: child))));
    }
    return Scaffold(body: SceneBackground(night: night, theme: t, child: NightScope(night: true, child: child)));
  }
}


