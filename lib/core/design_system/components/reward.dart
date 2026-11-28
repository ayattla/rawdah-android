import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rawdah/core/design_system/components/haptics.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/kid_widgets.dart';
import 'package:rawdah/core/design_system/components/lantern.dart';
import 'package:rawdah/core/design_system/geometry/tv_shapes.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/services/voice.dart';

Future<void> showReward(BuildContext context, {required int stars, String title = 'أحسنت!'}) {
  Voice.instance.say(stars > 0 ? '$title حصلت على $stars نجوم' : title);
  if (stars > 0) {
    Haptics.celebrate();
  } else {
    Haptics.success();
  }
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final t = Curves.easeOutBack.transform(anim.value);
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.7 + 0.3 * t,
          child: Center(child: _RewardCard(stars: stars, title: title)),
        ),
      );
    },
  );
}

class _RewardCard extends StatefulWidget {
  final int stars;
  final String title;
  const _RewardCard({required this.stars, required this.title});

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    _rain.dispose();
    super.dispose();
  }

  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  Widget build(BuildContext context) {
    final reduce = A11y.reduceMotionOf(context);
    final hc = A11y.highContrastOf(context);
    return Semantics(
      liveRegion: true,
      label: widget.stars > 0 ? '${widget.title}، حصلت على ${widget.stars} نجوم' : widget.title,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 340,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            // أشعة احتفال تدور خلف التلفاز
            if (!hc)
              Positioned(
                top: -40,
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (_, __) => Transform.rotate(
                    angle: reduce ? 0 : _spin.value * 2 * math.pi,
                    child: CustomPaint(size: const Size(340, 340), painter: _RaysPainter()),
                  ),
                ),
              ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 300,
                height: 250,
                child: CustomPaint(
                  painter: CandyTvPainter(variant: 2, body: const Color(0xFFFF5DB1), screen: const Color(0xFF2B1B7A), rim: const Color(0xFFFFD43B), flat: hc),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 44),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Lantern(size: 92, glow: 1),
                      if (widget.stars > 0)
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: widget.stars),
                          duration: Duration(milliseconds: reduce ? 1 : 700),
                          builder: (_, v, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.star_rounded, color: RC.gold, size: 34),
                            const SizedBox(width: 4),
                            Text('+$v', textDirection: TextDirection.ltr, style: RT.display(30, color: Colors.white)),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // لافتة العنوان تنط
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: 0.5 + 0.5 * v, child: Transform.rotate(angle: (1 - v) * 0.2, child: child)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                  decoration: const ShapeDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE680), Color(0xFFFFC23F)]),
                    shape: StadiumBorder(side: BorderSide(color: Color(0xFF2A1A66), width: 3.5)),
                    shadows: [BoxShadow(color: Color(0xFF2A1A66), offset: Offset(0, 5))],
                  ),
                  child: Text(widget.title, textAlign: TextAlign.center, style: RT.display(24, color: const Color(0xFF2A1A66))),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(width: 220, child: PrimaryButton(label: 'رائع', color: RC.green, onTap: () => Navigator.of(context).pop())),
            ]),
            // قصاصات تمطر مرة واحدة
            if (!reduce && !hc)
              Positioned(
                top: -60,
                left: -20,
                right: -20,
                height: 420,
                child: IgnorePointer(
                  child: AnimatedBuilder(animation: _rain, builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_rain.value))),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n, a1 = a0 + math.pi / n;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a0) * size.width / 2, c.dy + math.sin(a0) * size.width / 2)
          ..lineTo(c.dx + math.cos(a1) * size.width / 2, c.dy + math.sin(a1) * size.width / 2)
          ..close(),
        Paint()..color = (i.isEven ? const Color(0xFFFFD43B) : const Color(0xFFFF8FC8)).withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  static const _cols = [Color(0xFFFF5DB1), Color(0xFFFFD43B), Color(0xFF22D3EE), Color(0xFF9DFF8A), Color(0xFFFF9F1C), Color(0xFFA78BFA)];

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final r = math.Random(4);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * size.width;
      final delay = r.nextDouble() * 0.35;
      final k = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k == 0) continue;
      final y = -10 + k * size.height * (0.7 + r.nextDouble() * 0.4);
      canvas.save();
      canvas.translate(x + math.sin(k * 10 + i) * 14, y);
      canvas.rotate(k * 12 * (i.isEven ? 1 : -1));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2.5, 10, 5), const Radius.circular(2)), Paint()..color = _cols[i % _cols.length].withValues(alpha: 1 - k * 0.8));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}

