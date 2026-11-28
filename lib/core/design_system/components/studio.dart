import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/chunky.dart';
import 'package:rawdah/core/design_system/geometry/tv_shapes.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';

/// استوديو المسابقات: شاشة السؤال الكبيرة وكبسولات الإجابات الملونة.
const _ink = Color(0xFF2A1A66);

class StudioQuestion extends StatelessWidget {
  final String text;
  final String? label;
  final VoidCallback? onListen;
  final Color body;
  const StudioQuestion({super.key, required this.text, this.label, this.onListen, this.body = const Color(0xFFFF9F1C)});

  @override
  Widget build(BuildContext context) {
    final hc = A11y.highContrastOf(context);
    return CustomPaint(
      painter: CandyTvPainter(variant: 3, body: body, screen: Colors.white, rim: const Color(0xFF22D3EE), flat: hc, inset: 0.13),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 30, 40, 44),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (label != null || onListen != null)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (label != null) Text(label!, style: RT.display(15, color: const Color(0xFFE07A00))),
              if (onListen != null)
                IconButton(
                  tooltip: 'استمع',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFE07A00), size: 28),
                  onPressed: onListen,
                ),
            ]),
          Text(text, textAlign: TextAlign.center, style: RT.display(24, color: _ink)),
        ]),
      ),
    );
  }
}

/// كبسولة إجابة: لون لكل خيار، وكرة حرف (أ ب ج د)، وتتحول للأخضر أو الأحمر بعد الإجابة.
class CandyAnswer extends StatelessWidget {
  final String text;
  final int index;
  final int state; // 0 عادي، 1 صحيح، 2 خطأ، 3 باهت بعد الإجابة
  final VoidCallback? onTap;
  const CandyAnswer({super.key, required this.text, required this.index, this.state = 0, this.onTap});

  static const _cols = [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)];
  static const _letters = ['أ', 'ب', 'ج', 'د', 'هـ'];

  @override
  Widget build(BuildContext context) {
    final base = switch (state) {
      1 => const Color(0xFF16A34A),
      2 => const Color(0xFFDC2626),
      _ => _cols[index % _cols.length],
    };
    final dim = state == 3;
    return AnimatedScale(
      scale: state == 1 ? 1.03 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Opacity(
        opacity: dim ? 0.55 : 1,
        child: Chunky(
          color: base,
          border: Border.all(color: _ink, width: 3.5),
          radius: 40,
          depth: 6,
          onTap: onTap,
          semanticLabel: switch (state) {
            1 => '$text، الإجابة الصحيحة',
            2 => '$text، إجابتك، خطأ',
            _ => text,
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)]),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _ink, width: 3)),
                child: state == 1
                    ? const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 28)
                    : state == 2
                        ? const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 28)
                        : Text(_letters[index % _letters.length], style: RT.display(20, color: base)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, textAlign: TextAlign.center, style: RT.display(22, color: Colors.white))),
              const SizedBox(width: 52),
            ]),
          ),
        ),
      ),
    );
  }
}

/// شاشة تلفاز كبيرة لعرض المحتوى (الحلقات والقصص): إطار مجسم بمقابض ولمبات
/// والمحتوى على شاشة داكنة بإضاءة.
class TvFrame extends StatelessWidget {
  final Widget child;
  final Color body;
  final Color screen;
  final int variant;
  const TvFrame({super.key, required this.child, this.body = const Color(0xFFFF5DB1), this.screen = const Color(0xFF2B1B7A), this.variant = 3});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: CandyTvPainter(variant: variant, body: body, screen: screen, flat: A11y.highContrastOf(context), inset: 0.12),
        child: Padding(padding: const EdgeInsets.fromLTRB(54, 44, 54, 62), child: child),
      );
}
