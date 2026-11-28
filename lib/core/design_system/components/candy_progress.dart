import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';

/// شريط تقدم حلوى: إطار غامق، تعبئة بخطوط مائلة ولمعة، ونفس معاملات LinearProgressIndicator.
class CandyProgress extends StatelessWidget {
  final double? value;
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;
  final String? semanticsLabel;
  const CandyProgress({super.key, this.value, this.minHeight = 10, this.color, this.backgroundColor, this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0).clamp(0.0, 1.0);
    final c = color ?? const Color(0xFF34D399);
    final hc = A11y.highContrastOf(context);
    final h = minHeight + 4;
    return Semantics(
      label: semanticsLabel,
      value: '${(v * 100).round()}٪',
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFFE9E4FF),
          borderRadius: BorderRadius.circular(h),
          border: Border.all(color: const Color(0xFF2A1A66), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(h),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: CustomPaint(painter: hc ? null : _StripePainter(c), child: hc ? ColoredBox(color: c) : null),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  _StripePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(size.height)), Paint()..color = color);
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(size.height)));
    for (var x = -size.height; x < size.width + size.height; x += size.height * 1.4) {
      canvas.drawPath(Path()..moveTo(x, size.height)..lineTo(x + size.height * 0.6, size.height)..lineTo(x + size.height * 1.3, 0)..lineTo(x + size.height * 0.7, 0)..close(), stripe);
    }
    canvas.drawRect(Rect.fromLTWH(0, 1, size.width, size.height * 0.3), Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter o) => o.color != color;
}
