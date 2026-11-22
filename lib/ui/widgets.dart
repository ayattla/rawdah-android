import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/voice.dart';
import '../state/app_state.dart';

// =====================================================================
// نظام تصميم روضة: «صحن الزليج»
// بلاط هندسي، نجمة ثمانية، فوانيس المساء. بلا أي ذوات أرواح.
// =====================================================================

/// الألوان. الأسماء القديمة باقية حتى تعمل كل الشاشات بالهوية الجديدة.
class RC {
  /// فيروزي الزليج: اللون الأساسي.
  static const green = Color(0xFF0E9384);
  static const greenDark = Color(0xFF0A6C61);

  /// ورق نعناعي: خلفية الشاشات.
  static const sand = Color(0xFFEAF6F4);
  static const sandDark = Color(0xFFCDE6E1);
  static const sky = Color(0xFFD8ECFF);

  /// زعفراني: النجوم والجوائز.
  static const gold = Color(0xFFF5B82E);
  static const goldDark = Color(0xFFC98E0F);

  static const sea = Color(0xFF2D8CDB);

  /// رماني: الحماس والتنبيه.
  static const coral = Color(0xFFE8505B);

  /// بنفسجي البلاط.
  static const plum = Color(0xFF6A5AE0);

  /// لازوردي: النصوص والخلفيات الداكنة.
  static const ink = Color(0xFF1D2B64);
  static const night = Color(0xFF18204D);
  static const paper = Colors.white;
}

/// ظل البلاطة المجسّمة: نسخة أغمق من اللون نفسه.
Color shadeOf(Color c, [double amount = 0.18]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// أنماط الخط. «بلو بهيجان» للعناوين والأرقام، و«روبيك» للنص.
class RT {
  static TextStyle display(double size, {Color color = RC.ink, FontWeight weight = FontWeight.w800}) =>
      TextStyle(fontFamily: 'Baloo', fontSize: size, fontWeight: weight, color: color, height: 1.25);
  static TextStyle body(double size, {Color color = RC.ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Rubik', fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

ThemeData rawdahTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: RC.green).copyWith(
    primary: RC.green,
    onPrimary: Colors.white,
    secondary: RC.gold,
    tertiary: RC.plum,
    error: RC.coral,
    surface: Colors.white,
    onSurface: RC.ink,
  );
  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Baloo',
    colorScheme: scheme,
    scaffoldBackgroundColor: RC.sand,
    appBarTheme: AppBarTheme(
      backgroundColor: RC.sand,
      foregroundColor: RC.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: RT.display(23),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: RC.sandDark)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: RT.display(18, weight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RC.ink,
        side: const BorderSide(color: RC.sandDark, width: 2),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: RT.display(17, weight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: RC.greenDark, textStyle: RT.display(16, weight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.sandDark)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.sandDark)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.green, width: 2)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        selectedBackgroundColor: RC.ink,
        selectedForegroundColor: Colors.white,
        foregroundColor: RC.ink,
        side: const BorderSide(color: RC.sandDark),
        textStyle: RT.display(15, weight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: RC.sandDark),
      labelStyle: RT.body(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? RC.green : null),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: RT.display(22),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: RC.ink,
      contentTextStyle: RT.body(16, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: RC.green, linearTrackColor: RC.sandDark),
    dividerTheme: const DividerThemeData(color: RC.sandDark, thickness: 1),
    listTileTheme: ListTileThemeData(titleTextStyle: RT.display(18, weight: FontWeight.w700), iconColor: RC.green),
  );
}

IconData symbolIcon(String s) {
  switch (s) {
    case 'moon':
      return Icons.nightlight_round;
    case 'sun':
      return Icons.wb_sunny_rounded;
    case 'tree':
      return Icons.park_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'gem':
      return Icons.diamond_rounded;
    default:
      return Icons.star_rounded;
  }
}

// =====================================================================
// الهندسة: النجمة الثمانية (خاتم سليمان) ونقش الزليج
// =====================================================================

/// مسار النجمة الثمانية: مربعان متداخلان، نصف القطر الداخلي 0.765 من الخارجي.
Path khatamPath(Offset c, double r, {double rotation = 0}) {
  final p = Path();
  const inner = 0.765;
  for (var i = 0; i < 16; i++) {
    final a = rotation - math.pi / 2 + i * math.pi / 8;
    final rr = i.isEven ? r : r * inner;
    final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// شكل النجمة الثمانية كحدود لعناصر Flutter.
class KhatamBorder extends ShapeBorder {
  const KhatamBorder();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      khatamPath(rect.center, rect.shortestSide / 2, rotation: math.pi / 8);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}

/// نقش الزليج: شبكة نجوم ثمانية تربطها معيّنات، يخفت نحو الأسفل.
class ZellijPainter extends CustomPainter {
  final Color color;
  final double cell;
  final double fadeTo; // نسبة الارتفاع التي يختفي عندها النقش (1 = لا يخفت)
  ZellijPainter({required this.color, this.cell = 64, this.fadeTo = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (size.height / cell).ceil() + 1;
    final cols = (size.width / cell).ceil() + 1;
    for (var y = 0; y < rows; y++) {
      final cy = y * cell;
      final t = fadeTo >= 1 ? 0.0 : (cy / (size.height * fadeTo)).clamp(0.0, 1.0);
      final alpha = color.a * (1 - t);
      if (alpha <= 0.01) continue;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      for (var x = 0; x < cols; x++) {
        final c = Offset(x * cell + (y.isOdd ? cell / 2 : 0), cy);
        canvas.drawPath(khatamPath(c, cell * 0.26), paint);
        // معيّن صغير بين النجوم
        final d = c + Offset(cell / 2, 0);
        final s = cell * 0.08;
        canvas.drawPath(
            Path()
              ..moveTo(d.dx, d.dy - s)
              ..lineTo(d.dx + s, d.dy)
              ..lineTo(d.dx, d.dy + s)
              ..lineTo(d.dx - s, d.dy)
              ..close(),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZellijPainter old) => old.color != color || old.cell != cell || old.fadeTo != fadeTo;
}

/// خلفية الشاشات: ورق نعناعي بنقش زليج خفيف في الأعلى، أو ليل لازوردي بنجوم.
class ScenePainter extends CustomPainter {
  final bool night;
  ScenePainter({this.night = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = night ? RC.night : RC.sand);
    ZellijPainter(
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
  bool shouldRepaint(covariant ScenePainter old) => old.night != night;
}

class SceneBackground extends StatelessWidget {
  final Widget child;
  final bool night;
  const SceneBackground({super.key, required this.child, this.night = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: ScenePainter(night: night), child: SafeArea(child: child));
}

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
    final edge = widget.edge ?? shadeOf(widget.color);
    final drop = enabled ? (_down ? 1.0 : widget.depth) : widget.depth;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
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
            border: widget.border,
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
  const KhatamBadge({super.key, required this.icon, required this.color, this.size = 64, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: color, shape: const KhatamBorder()),
          child: Icon(icon, color: iconColor, size: size * 0.48),
        ),
      );
}

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
      child: Row(
        children: [
          if (showBack)
            RoundIcon(
              icon: Icons.arrow_back_rounded,
              color: RC.ink,
              size: 50,
              tooltip: 'رجوع',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: RT.display(25), overflow: TextOverflow.ellipsis)),
          if (trailing != null) trailing!,
          if (c != null) StarCount(stars: c.stars),
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
    return Container(
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
  const BigTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Chunky(
      color: Colors.white,
      edge: color.withValues(alpha: 0.45),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      semanticLabel: title,
      onTap: () {
        Voice.instance.say(title);
        onTap();
      },
      child: Row(children: [
        KhatamBadge(icon: icon, color: color, size: 62),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: RT.display(21)),
            if (subtitle != null) Text(subtitle!, style: RT.body(15, color: RC.ink.withValues(alpha: 0.7))),
          ]),
        ),
        if (done)
          const KhatamBadge(icon: Icons.check_rounded, color: RC.gold, size: 36, iconColor: RC.ink)
        else
          Icon(Icons.chevron_left_rounded, color: color, size: 30),
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
      child: SizedBox(
        height: 60,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 26), const SizedBox(width: 8)],
          Flexible(
            child: Text(label, style: RT.display(22, color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

/// نافذة الجائزة: ليل لازوردي، نجمة ثمانية تدور ببطء خلف فانوس مضيء.
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
    final reduce = MediaQuery.of(context).disableAnimations;
    return Material(
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
                Text('+$v', style: RT.display(34, color: Colors.white)),
              ]),
            ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'رائع', color: RC.green, onTap: () => Navigator.of(context).pop()),
        ]),
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

/// فانوس مرسوم: رفيق الطفل في التطبيق. جماد بلا وجه ولا ملامح.
class Lantern extends StatelessWidget {
  final double size;
  final double glow; // 0..1
  const Lantern({super.key, this.size = 80, this.glow = 0.5});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 0.7, size), painter: _LanternPainter(glow.clamp(0.0, 1.0).toDouble()));
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
    return Scaffold(body: SceneBackground(night: night, child: child));
  }
}
