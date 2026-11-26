import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/components/a11y.dart';
import 'package:rawdah/core/design_system/components/chunky.dart';
import 'package:rawdah/core/design_system/components/scene.dart';
import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';

// =====================================================================
// عناصر الطفل
// =====================================================================

/// الشريط العلوي: زر رجوع بلاطي، العنوان، والنجوم.
class KidBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  const KidBar({super.key, required this.title, this.showBack = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      // العنوان في منتصف الشريط تماما: عمودان جانبيان بعرض واحد يوازنان الرجوع والنجوم
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: showBack
                  ? RoundIcon(
                      icon: Icons.arrow_back_rounded,
                      color: NightScope.of(context) ? RC.green : RC.ink,
                      size: 50,
                      tooltip: 'رجوع',
                      onTap: () => Navigator.of(context).maybePop(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // العنوان على ملصق أبيض بحد سميك وظل صلب، كلافتات برامج الأطفال
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: const StadiumBorder(side: BorderSide(color: Color(0xFF4C2A99), width: 3)),
                  shadows: const [BoxShadow(color: Color(0xFF4C2A99), offset: Offset(0, 4))],
                ),
                child: Text(title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: RT.display(20, color: RC.ink),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 104),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
              if (trailing != null) trailing!,
              if (c != null) StarCount(stars: c.stars),
            ]),
          ),
        ],
      ),
    );
  }
}

class StarCount extends StatelessWidget {
  final int stars;
  const StarCount({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'نجومك: $stars',
      excludeSemantics: true,
      child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: RC.gold, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: RC.goldDark, size: 24),
        const SizedBox(width: 3),
        Text('$stars', style: RT.display(19, color: RC.ink)),
      ]),
    ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;
  const RoundIcon({super.key, required this.icon, required this.color, required this.onTap, this.size = 56, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Chunky(
      color: color,
      radius: size * 0.34,
      depth: 4,
      onTap: onTap,
      semanticLabel: tooltip,
      child: SizedBox(width: size, height: size - 4, child: Icon(icon, color: Colors.white, size: size * 0.5)),
    );
  }
}

/// بلاطة كبيرة للأطفال: شارة نجمة ملوّنة وعنوان واضح، تنخفض عند اللمس.
class BigTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool done;
  final String? badge;
  const BigTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.done = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hc = A11y.highContrastOf(context);
    return Chunky(
      color: Colors.white,
      edge: color,
      border: Border.all(color: hc ? color : color.withValues(alpha: 0.45), width: 3),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      semanticLabel: [title, if (subtitle != null) subtitle!, if (done) 'مكتمل'].join('، '),
      onTap: () {
        Voice.instance.say(title);
        onTap();
      },
      // النص في منتصف البطاقة: الشارة وعلامة الإنجاز في عمودين بعرض واحد
      child: Row(children: [
        KhatamBadge(icon: icon, color: color, size: 62, label: badge),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(title, textAlign: TextAlign.center, style: RT.display(21)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, textAlign: TextAlign.center, style: RT.body(15, color: hc ? RC.ink : RC.inkSoft)),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: done
                ? const KhatamBadge(icon: Icons.check_rounded, color: RC.gold, size: 36, iconColor: RC.ink)
                : Icon(Icons.chevron_left_rounded, color: color, size: 30),
          ),
        ),
      ]),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, required this.onTap, this.color = RC.green, this.icon});

  @override
  Widget build(BuildContext context) {
    return Chunky(
      color: color,
      radius: 20,
      depth: 6,
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        // ارتفاع أدنى لا ثابت: يكبر مع تكبير الخط دون قص
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 26), const SizedBox(width: 8)],
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center, style: RT.display(22, color: Colors.white), maxLines: 2),
          ),
        ]),
        ),
      ),
    );
  }
}

/// نافذة الجائزة: ليل لازوردي، نجمة ثمانية تدور ببطء خلف فانوس مضيء.
