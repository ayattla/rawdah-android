import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/kid_widgets.dart';
import 'package:rawdah/core/design_system/components/lantern.dart';
import 'package:rawdah/core/design_system/geometry/zellij.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/services/voice.dart';

Future<void> showReward(BuildContext context, {required int stars, String title = 'أحسنت!'}) {
  Voice.instance.say(stars > 0 ? '$title حصلت على $stars نجوم' : title);
  HapticFeedback.mediumImpact();
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

class _RewardCardState extends State<_RewardCard> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = A11y.reduceMotionOf(context);
    return Semantics(
      liveRegion: true,
      label: widget.stars > 0 ? '${widget.title}، حصلت على ${widget.stars} نجوم' : widget.title,
      child: Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          color: RC.night,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: RC.gold, width: 3),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 170,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) => Transform.rotate(
                  angle: reduce ? 0 : _spin.value * 2 * math.pi,
                  child: CustomPaint(size: const Size(170, 170), painter: _RosettePainter()),
                ),
              ),
              const Lantern(size: 112, glow: 1),
            ]),
          ),
          Text(widget.title, textAlign: TextAlign.center, style: RT.display(30, color: RC.gold)),
          if (widget.stars > 0)
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: widget.stars),
              duration: Duration(milliseconds: reduce ? 1 : 700),
              builder: (_, v, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: RC.gold, size: 38),
                const SizedBox(width: 4),
                Text('+$v', textDirection: TextDirection.ltr, style: RT.display(34, color: Colors.white)),
              ]),
            ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'رائع', color: RC.green, onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    ),
    );
  }
}

class _RosettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawPath(khatamPath(c, r), Paint()..color = RC.gold.withValues(alpha: 0.16));
    canvas.drawPath(khatamPath(c, r * 0.78, rotation: math.pi / 8), Paint()..color = RC.gold.withValues(alpha: 0.18));
    canvas.drawPath(
        khatamPath(c, r * 0.98),
        Paint()
          ..color = RC.gold.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
