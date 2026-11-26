import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/haptics.dart';
import 'package:rawdah/core/design_system/geometry/zellij.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';

// =====================================================================
// اللمس: كل ما يُضغط ينخفض كبلاطة حقيقية
// =====================================================================

/// سطح مجسّم: لون وحافة سفلية أغمق، ينخفض عند الضغط مع اهتزاز خفيف.
class Chunky extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color? edge;
  final double radius;
  final double depth;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Border? border;
  final String? semanticLabel;
  const Chunky({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.edge,
    this.radius = 22,
    this.depth = 5,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.border,
    this.semanticLabel,
  });

  @override
  State<Chunky> createState() => _ChunkyState();
}

class _ChunkyState extends State<Chunky> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final hc = A11y.highContrastOf(context);
    final edge = hc ? RC.ink : (widget.edge ?? shadeOf(widget.color));
    final drop = enabled ? (_down ? 1.0 : widget.depth) : widget.depth;
    // في التباين العالي تأخذ البلاطات البيضاء حدًا لازورديًا واضحًا
    final border = hc && widget.color == Colors.white ? Border.all(color: RC.ink, width: 2) : widget.border;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      // إذا وُصف الزر بنص كامل لا يقرأ قارئ الشاشة أجزاءه مرة ثانية
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: enabled
            ? () {
                Haptics.tap();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          margin: EdgeInsets.only(top: widget.depth - drop, bottom: drop),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: enabled ? widget.color : Color.lerp(widget.color, Colors.grey.shade300, 0.6),
            borderRadius: BorderRadius.circular(widget.radius),
            border: border,
            boxShadow: [BoxShadow(color: enabled ? edge : Colors.grey.shade400, offset: Offset(0, drop))],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// شارة النجمة الثمانية بأيقونة في وسطها.
class KhatamBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Color iconColor;

  /// نص بدل الأيقونة (رقم السورة مثلًا).
  final String? label;
  const KhatamBadge(
      {super.key, required this.icon, required this.color, this.size = 64, this.iconColor = Colors.white, this.label});

  @override
  Widget build(BuildContext context) {
    final flat = A11y.highContrastOf(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BadgePainter(color, flat),
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.06),
            child: Center(
              child: label != null
                  ? Text(label!, style: RT.display(size * 0.34, color: iconColor))
                  : Icon(icon,
                      color: iconColor,
                      size: size * 0.44,
                      shadows: flat ? null : [Shadow(color: Colors.black.withValues(alpha: 0.18), offset: Offset(0, size * 0.03))]),
            ),
          ),
        ),
      ),
    );
  }
}

/// أيقونة كحلوى منفوخة: حد كرتوني غامق، ظل صلب، تدرج لامع، ولمعة بيضاء مائلة.
class _BadgePainter extends CustomPainter {
  final Color color;
  final bool flat;
  _BadgePainter(this.color, this.flat);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.86;
    final c = size.center(Offset(0, -size.height * 0.03));
    final body = blobPath(c, r, seed: color.toARGB32());
    if (flat) {
      canvas.drawPath(body, Paint()..color = color);
      return;
    }
    final hsl = HSLColor.fromColor(color);
    final dark = hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
    final light = hsl.withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
    canvas.drawPath(body.shift(Offset(0, size.height * 0.07)), Paint()..color = dark);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.35, -0.45), radius: 1.1, colors: [light, color, color])
            .createShader(body.getBounds()),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045,
    );
    // لمعة مائلة أعلى الشكل
    canvas.save();
    canvas.translate(c.dx - r * 0.38, c.dy - r * 0.5);
    canvas.rotate(-0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.2), Radius.circular(r)),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) => old.color != color || old.flat != flat;
}
