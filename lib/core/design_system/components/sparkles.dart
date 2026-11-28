import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/live_scene.dart';

/// لمسة مرحة: كل ضغطة في التطبيق تطلق رشة صغيرة من الدوائر والقصاصات الملونة
/// تتطاير وتختفي خلال نصف ثانية، فوق كل شيء ولا تمنع اللمس.
class TapSparkles extends StatefulWidget {
  final Widget child;
  const TapSparkles({super.key, required this.child});

  @override
  State<TapSparkles> createState() => _TapSparklesState();
}

class _TapSparklesState extends State<TapSparkles> with SingleTickerProviderStateMixin {
  final _bursts = <(Offset, Duration)>[];
  late final Ticker _ticker;
  Duration _now = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      _now = d;
      _bursts.removeWhere((b) => d - b.$2 > const Duration(milliseconds: 550));
      if (_bursts.isEmpty) _ticker.stop();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _add(Offset p) {
    if (A11y.reduceMotionOf(context) || LiveScene.inTest) return;
    if (!_ticker.isActive) {
      _now = Duration.zero;
      _ticker.start();
    }
    _bursts.add((p, _now));
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _add(e.localPosition),
        child: Stack(children: [
          widget.child,
          if (_bursts.isNotEmpty)
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BurstPainter(List.of(_bursts), _now)))),
        ]),
      );
}

class _BurstPainter extends CustomPainter {
  final List<(Offset, Duration)> bursts;
  final Duration now;
  _BurstPainter(this.bursts, this.now);

  static const _cols = [Color(0xFFFF5DB1), Color(0xFFFFD43B), Color(0xFF22D3EE), Color(0xFF9DFF8A), Color(0xFFFF9F1C)];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (p, t0) in bursts) {
      final k = ((now - t0).inMilliseconds / 550).clamp(0.0, 1.0);
      final e = Curves.easeOutCubic.transform(k);
      for (var i = 0; i < 9; i++) {
        final a = i * 2 * math.pi / 9 + p.dx * 0.01;
        final d = 10 + 34 * e;
        final c = p + Offset(math.cos(a) * d, math.sin(a) * d + 18 * k * k);
        final paint = Paint()..color = _cols[i % _cols.length].withValues(alpha: 1 - k);
        if (i.isEven) {
          canvas.drawCircle(c, 4 * (1 - k * 0.6), paint);
        } else {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(a + k * 4);
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(2)), paint);
          canvas.restore();
        }
      }
      canvas.drawCircle(p, 16 * e, Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * (1 - k))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => true;
}
