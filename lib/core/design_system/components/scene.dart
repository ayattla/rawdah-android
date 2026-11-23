import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/kid_widgets.dart';
import 'package:rawdah/core/design_system/components/lantern.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/geometry/zellij.dart';

/// خلفية الشاشات: ورق نعناعي بنقش زليج خفيف في الأعلى، أو ليل لازوردي بنجوم.
class ScenePainter extends CustomPainter {
  final bool night;
  final bool plain; // تباين عالٍ: بلا نقش
  ScenePainter({this.night = false, this.plain = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = night ? RC.night : RC.sand);
    if (!plain) ZellijPainter(
      color: night ? RC.gold.withValues(alpha: 0.10) : RC.green.withValues(alpha: 0.10),
      fadeTo: night ? 1 : 0.45,
    ).paint(canvas, size);
    if (night) {
      final r = math.Random(7);
      final star = Paint()..color = const Color(0xCCFFF1C9);
      for (var i = 0; i < 36; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.6),
            r.nextDouble() * 1.6 + 0.5, star);
      }
    }
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
  final Widget child;
  final bool night;
  const ChildShell({super.key, required this.child, this.night = false});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (st.overLimit) {
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
