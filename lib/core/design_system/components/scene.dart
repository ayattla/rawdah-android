import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/cosmos.dart';

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
    if (theme == SceneTheme.islamic || theme == SceneTheme.quran) {
      _islamicDecor(canvas, size);
      return;
    }
    if (theme == SceneTheme.play) _confetti(canvas, size);
    _planet(canvas, Offset(w * 0.92, h * 0.06), w * 0.22, theme.planet1.withValues(alpha: 0.22), theme.ring1.withValues(alpha: 0.30));
    canvas.drawCircle(Offset(w * 0.62, h * 0.035), w * 0.03, Paint()..color = theme.planet2.withValues(alpha: 0.25));
  }

  /// عالم ركن المسلم: هلال هادئ وفوانيس معلقة بخيوط ذهبية في أعلى الشاشة فقط.
  void _islamicDecor(Canvas canvas, Size size) {
    final w = size.width;
    final moon = Offset(w * 0.86, 46);
    canvas.drawCircle(moon, 24, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(moon + const Offset(10, -7), 21, Paint()..color = theme.sky.first);
    final thread = Paint()
      ..color = const Color(0xFFD4A537).withValues(alpha: 0.7)
      ..strokeWidth = 1.6;
    for (final (x, len) in [(0.1, 40.0), (0.26, 22.0), (0.62, 30.0)]) {
      final top = Offset(w * x, 0);
      final at = Offset(w * x, len);
      canvas.drawLine(top, at, thread);
      canvas.drawCircle(at + const Offset(0, 14), 22, Paint()..color = const Color(0xFFFFD56A).withValues(alpha: 0.18));
      final body = Path()
        ..moveTo(at.dx - 7, at.dy)
        ..lineTo(at.dx + 7, at.dy)
        ..lineTo(at.dx + 10, at.dy + 6)
        ..lineTo(at.dx + 10, at.dy + 20)
        ..lineTo(at.dx + 5, at.dy + 26)
        ..lineTo(at.dx - 5, at.dy + 26)
        ..lineTo(at.dx - 10, at.dy + 20)
        ..lineTo(at.dx - 10, at.dy + 6)
        ..close();
      canvas.drawPath(body, Paint()..color = const Color(0xFFF5B83D));
      canvas.drawPath(body, Paint()
        ..color = const Color(0xFF7A4B00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      canvas.drawRect(Rect.fromLTWH(at.dx - 4, at.dy + 8, 8, 11), Paint()..color = const Color(0xFFFFF7D1));
    }
  }

  /// ساحة الألعاب: قصاصات ملونة خفيفة في الأطراف.
  void _confetti(Canvas canvas, Size size) {
    final r = math.Random(9);
    const cols = [Color(0xFFFF5D8F), Color(0xFF22D3EE), Color(0xFFFFC23F), Color(0xFF8B5CF6), Color(0xFF34D399)];
    for (var i = 0; i < 26; i++) {
      final x = r.nextBool() ? r.nextDouble() * size.width * 0.18 : size.width * (0.82 + r.nextDouble() * 0.18);
      final y = r.nextDouble() * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(r.nextDouble() * 3);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2.5, 10, 5), const Radius.circular(2)), Paint()..color = cols[i % cols.length].withValues(alpha: 0.45));
      canvas.restore();
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
    return Scaffold(body: SceneBackground(night: night, theme: t, child: NightScope(night: night, child: child)));
  }
}


