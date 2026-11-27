import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';

/// فاصل السفر إلى عالم: كوكب بلون القسم يكبر من مكان البطاقة حتى يملأ الشاشة،
/// واسم العالم داخل لافتة كرتونية، ثم يتكشف القسم من داخل الكوكب.
/// قصير (٧٠٠ ملي ثانية)، وفي تقليل الحركة يصير تلاشيا بسيطا.
class WarpRoute<T> extends PageRouteBuilder<T> {
  /// آخر نقطة لمسها الطفل، ليبدأ الكوكب من البطاقة نفسها.
  static Offset? lastTap;

  WarpRoute({required WidgetBuilder builder, required String title, required Color color, IconData? icon, Offset? from})
      : super(
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, anim, _, child) {
            if (A11y.reduceMotionOf(context)) return FadeTransition(opacity: anim, child: child);
            if (anim.status == AnimationStatus.reverse) {
              return FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(anim), child: child));
            }
            return _Warp(anim: anim, title: title, color: color, icon: icon, from: from ?? lastTap, child: child);
          },
        );
}

class _Warp extends StatelessWidget {
  final Animation<double> anim;
  final String title;
  final Color color;
  final IconData? icon;
  final Offset? from;
  final Widget child;
  const _Warp({required this.anim, required this.title, required this.color, required this.icon, required this.from, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final origin = from ?? Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final t = anim.value;
        // ٠ → ٠٫٥٥ الكوكب يكبر ويدور، ٠٫٥٥ → ١ القسم يتكشف من داخله
        final grow = Curves.easeInOutCubic.transform((t / 0.55).clamp(0, 1));
        final reveal = Curves.easeOutCubic.transform(((t - 0.5) / 0.5).clamp(0, 1));
        final center = Offset.lerp(origin, Offset(size.width / 2, size.height / 2), grow)!;
        final planetR = 30 + grow * (size.width * 0.42);
        return Stack(children: [
          if (reveal < 1)
            Positioned.fill(
              child: CustomPaint(painter: _WarpPainter(center: center, r: planetR, color: color, spin: t, fade: 1 - reveal)),
            ),
          if (reveal > 0)
            ClipPath(clipper: _CircleClip(center, maxR * reveal), child: child),
          if (t > 0.18 && reveal < 0.9)
            Positioned(
              left: 24,
              right: 24,
              top: size.height / 2 + planetR * 0.15 + 20,
              child: Opacity(
                opacity: ((t - 0.18) / 0.15).clamp(0, 1) * (1 - reveal),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Color(0xFF2A1A66), width: 4)),
                      shadows: const [BoxShadow(color: Color(0xFF2A1A66), offset: Offset(0, 5))],
                    ),
                    child: Text(title, textAlign: TextAlign.center, style: RT.display(26, color: const Color(0xFF2A1A66))),
                  ),
                ),
              ),
            ),
          if (icon != null && reveal < 0.6)
            Positioned(
              left: center.dx - planetR * 0.35,
              top: center.dy - planetR * 0.35,
              width: planetR * 0.7,
              height: planetR * 0.7,
              child: Opacity(opacity: (grow * (1 - reveal / 0.6)).clamp(0, 1), child: FittedBox(child: Icon(icon, color: Colors.white))),
            ),
        ]);
      },
    );
  }
}

class _CircleClip extends CustomClipper<Path> {
  final Offset c;
  final double r;
  _CircleClip(this.c, this.r);
  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: c, radius: r));
  @override
  bool shouldReclip(covariant _CircleClip old) => old.r != r || old.c != c;
}

class _WarpPainter extends CustomPainter {
  final Offset center;
  final double r;
  final Color color;
  final double spin;
  final double fade;
  _WarpPainter({required this.center, required this.r, required this.color, required this.spin, required this.fade});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1A1450).withValues(alpha: 0.92 * fade));
    // خطوط سرعة النجوم
    final rnd = math.Random(3);
    final speed = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var i = 0; i < 28; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d0 = r + 20 + rnd.nextDouble() * size.width * 0.6 * (0.4 + spin);
      final p0 = center + Offset(math.cos(a), math.sin(a)) * d0;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (d0 + 18 + 40 * spin);
      speed.color = Colors.white.withValues(alpha: 0.5 * fade);
      canvas.drawLine(p0, p1, speed);
    }
    // حلقة الكوكب
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09;
    final oval = Rect.fromCenter(center: center, width: r * 2.9, height: r * 0.75);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.35 + spin * 0.6);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(oval, math.pi, math.pi, false, ring);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.35, -0.4), colors: [Color.lerp(color, Colors.white, 0.4)!, color, Color.lerp(color, Colors.black, 0.35)!])
            .createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(center, r, Paint()
      ..color = const Color(0xFF2A1A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    // فوهات كرتونية على سطح الكوكب
    for (final (dx, dy, k) in [(-0.35, 0.25, 0.18), (0.3, -0.3, 0.12), (0.38, 0.35, 0.09)]) {
      canvas.drawCircle(center + Offset(dx * r, dy * r), r * k, Paint()..color = Colors.black.withValues(alpha: 0.12));
    }
    canvas.drawArc(oval, 0, math.pi, false, ring);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WarpPainter old) => true;
}
