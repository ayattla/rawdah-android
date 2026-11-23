import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/geometry/zellij.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';

/// فانوس مرسوم: رفيق الطفل في التطبيق. جماد بلا وجه ولا ملامح.
class Lantern extends StatelessWidget {
  final double size;
  final double glow; // 0..1
  const Lantern({super.key, this.size = 80, this.glow = 0.5});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(size: Size(size * 0.7, size), painter: _LanternPainter(glow.clamp(0.0, 1.0).toDouble())),
      );
}

class _LanternPainter extends CustomPainter {
  final double glow;
  _LanternPainter(this.glow);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    const brass = Color(0xFFB7791F);
    const brassDark = Color(0xFF7A4E12);
    final c = Offset(w / 2, h * 0.56);
    // الهالة
    canvas.drawCircle(
        c,
        w * (0.55 + glow * 0.45),
        Paint()
          ..color = RC.gold.withValues(alpha: 0.10 + glow * 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    // الحلقة والقبة
    canvas.drawCircle(
        Offset(w / 2, h * 0.05),
        w * 0.07,
        Paint()
          ..color = brassDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final dome = Path()
      ..moveTo(w * 0.22, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.78, h * 0.22)
      ..close();
    canvas.drawPath(dome, Paint()..color = brass);
    // الجسم: مثمّن مدبب
    final body = Path()
      ..moveTo(w * 0.22, h * 0.22)
      ..lineTo(w * 0.78, h * 0.22)
      ..lineTo(w * 0.9, h * 0.45)
      ..lineTo(w * 0.82, h * 0.78)
      ..lineTo(w * 0.18, h * 0.78)
      ..lineTo(w * 0.1, h * 0.45)
      ..close();
    canvas.drawPath(body, Paint()..color = Color.lerp(const Color(0xFFF7E7B9), const Color(0xFFFFC53D), glow)!);
    // زجاج ملوّن: نجمة في الوسط
    canvas.drawPath(khatamPath(c, w * 0.17),
        Paint()..color = Color.lerp(RC.green.withValues(alpha: 0.35), RC.coral.withValues(alpha: 0.55), glow)!);
    canvas.drawCircle(c, w * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.55 + glow * 0.45));
    final frame = Paint()
      ..color = brassDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, frame);
    canvas.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.36), frame);
    canvas.drawLine(Offset(w * 0.5, h * 0.68), Offset(w * 0.5, h * 0.78), frame);
    // القاعدة
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, h * 0.79, w * 0.52, h * 0.08), const Radius.circular(4)),
        Paint()..color = brass);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.4, h * 0.87)
          ..lineTo(w * 0.6, h * 0.87)
          ..lineTo(w * 0.5, h * 0.98)
          ..close(),
        Paint()..color = brassDark);
  }

  @override
  bool shouldRepaint(covariant _LanternPainter old) => old.glow != glow;
}
