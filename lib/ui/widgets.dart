import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/voice.dart';
import '../state/app_state.dart';

class RC {
  static const green = Color(0xFF2E7D5B);
  static const greenDark = Color(0xFF1F5A41);
  static const sand = Color(0xFFF7ECD6);
  static const sandDark = Color(0xFFE8D2A6);
  static const sky = Color(0xFFCDEBF7);
  static const gold = Color(0xFFF2B544);
  static const sea = Color(0xFF2F8FB5);
  static const coral = Color(0xFFE07856);
  static const plum = Color(0xFF7A5BA6);
  static const ink = Color(0xFF213040);
  static const night = Color(0xFF1E2B4A);
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

/// خلفية مرسومة: سماء، شمس أو قمر، كثبان رملية. بلا أي ذوات أرواح.
class ScenePainter extends CustomPainter {
  final bool night;
  ScenePainter({this.night = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: night ? const [Color(0xFF15203A), Color(0xFF34477A)] : const [Color(0xFF9FD8F0), Color(0xFFEAF7FC)],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    if (night) {
      final star = Paint()..color = const Color(0xCCFFF4D0);
      final r = math.Random(7);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.55), r.nextDouble() * 1.8 + 0.6, star);
      }
      final moonC = Offset(size.width * 0.18, size.height * 0.14);
      canvas.drawCircle(moonC, 26, Paint()..color = const Color(0xFFFFF1C1));
      canvas.drawCircle(moonC + const Offset(10, -6), 23, Paint()..color = const Color(0xFF1B2744));
    } else {
      final sunC = Offset(size.width * 0.82, size.height * 0.12);
      canvas.drawCircle(sunC, 46, Paint()..color = const Color(0x33F2B544));
      canvas.drawCircle(sunC, 30, Paint()..color = RC.gold);
    }

    final dune1 = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.68, size.width * 0.62, size.height * 0.77)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.83, size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(dune1, Paint()..color = night ? const Color(0xFF3B3A55) : RC.sandDark);
    final dune2 = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.8, size.width, size.height * 0.9)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(dune2, Paint()..color = night ? const Color(0xFF4A4865) : RC.sand);
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) => old.night != night;
}

class SceneBackground extends StatelessWidget {
  final Widget child;
  final bool night;
  const SceneBackground({super.key, required this.child, this.night = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: ScenePainter(night: night), child: SafeArea(child: child));
  }
}

/// شريط علوي بزر رجوع كبير وعنوان وعدد النجوم.
class KidBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  const KidBar({super.key, required this.title, this.showBack = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          if (showBack)
            RoundIcon(
              icon: Icons.home_rounded,
              color: RC.green,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink),
                overflow: TextOverflow.ellipsis),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: RC.gold, size: 26),
        const SizedBox(width: 4),
        Text('$stars', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.ink)),
      ]),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const RoundIcon({super.key, required this.icon, required this.color, required this.onTap, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * 0.55)),
      ),
    );
  }
}

/// بطاقة كبيرة للأطفال (هدف لمس أكبر من 64).
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Voice.instance.say(title);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: RC.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: TextStyle(fontSize: 15, color: RC.ink.withValues(alpha: 0.65))),
                  ),
              ]),
            ),
            if (done) const Icon(Icons.check_circle_rounded, color: RC.green, size: 32),
          ]),
        ),
      ),
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
    return SizedBox(
      height: 64,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, fontFamily: 'Rubik'),
        ),
        onPressed: onTap,
        icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 28),
        label: Text(label),
      ),
    );
  }
}

/// نافذة المكافأة: نجوم وفانوس يضيء، بلا شخصيات.
Future<void> showReward(BuildContext context, {required int stars, String title = 'أحسنت!'}) {
  Voice.instance.say('$title حصلت على $stars نجوم');
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Lantern(size: 110, glow: 1),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.green)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, color: RC.gold, size: 36),
            Text(' +$stars', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: RC.ink)),
          ]),
          const SizedBox(height: 18),
          PrimaryButton(label: 'رائع', icon: Icons.check_rounded, onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    ),
  );
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
    final c = Offset(w / 2, h * 0.58);
    canvas.drawCircle(c, w * (0.55 + glow * 0.35),
        Paint()..color = RC.gold.withValues(alpha: 0.12 + glow * 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    final frame = Paint()..color = const Color(0xFF8A5A2B);
    canvas.drawCircle(Offset(w / 2, h * 0.06), w * 0.08, Paint()..color = const Color(0xFF8A5A2B)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.12, w * 0.4, h * 0.08), const Radius.circular(4)), frame);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.2, w * 0.72, h * 0.66), Radius.circular(w * 0.22));
    canvas.drawRRect(body, Paint()..color = Color.lerp(const Color(0xFFF6E3B0), const Color(0xFFFFD25A), glow)!);
    canvas.drawRRect(body, Paint()..color = const Color(0xFF8A5A2B)..style = PaintingStyle.stroke..strokeWidth = 3);
    final bar = Paint()..color = const Color(0x998A5A2B)..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.38, h * 0.21), Offset(w * 0.38, h * 0.85), bar);
    canvas.drawLine(Offset(w * 0.62, h * 0.21), Offset(w * 0.62, h * 0.85), bar);
    canvas.drawCircle(c, w * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.5 + glow * 0.5));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.86, w * 0.48, h * 0.07), const Radius.circular(4)), frame);
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
                const Text('انتهى وقت اليوم',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 10),
                Text('أحسنت اليوم يا ${st.current?.name ?? ''}. نرتاح الآن ونلتقي غدًا بإذن الله.',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.white70)),
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
