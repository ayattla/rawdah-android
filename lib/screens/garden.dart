import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';

const List<int> kPalmStages = [0, 10, 30, 60, 100, 160];

int palmStage(int stars) {
  var s = 0;
  for (var i = 0; i < kPalmStages.length; i++) {
    if (stars >= kPalmStages[i]) s = i;
  }
  return s;
}

class _Badge {
  final String title;
  final IconData icon;
  final bool Function(ChildProfile c) earned;
  const _Badge(this.title, this.icon, this.earned);
}

final List<_Badge> _badges = [
  _Badge('أول قصة', Icons.auto_stories_rounded, (c) => c.completed.any((e) => e.startsWith('story_'))),
  _Badge('حافظ صغير', Icons.menu_book_rounded, (c) => c.completed.where((e) => e.startsWith('surah_')).length >= 3),
  _Badge('صاحب الأذكار', Icons.wb_twilight_rounded, (c) => c.completed.contains('adhkar')),
  _Badge('عشر إجابات', Icons.emoji_events_rounded, (c) => c.quizCorrect >= 10),
  _Badge('ثلاثة أيام', Icons.local_fire_department_rounded, (c) => c.streak >= 3),
  _Badge('فاعل الخير', Icons.favorite_rounded, (c) => c.approvedHabits >= 5),
];

class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current!;
    final stage = palmStage(c.stars);
    final next = stage < kPalmStages.length - 1 ? kPalmStages[stage + 1] : null;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'حديقتي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              height: 260,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(28)),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: PalmPainter(stage))),
                Positioned(left: 14, top: 14, child: Lantern(size: 70, glow: (c.streak / 7).clamp(0.2, 1.0).toDouble())),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              next == null ? 'نخلتك أثمرت بالكامل، ما شاء الله' : 'بقي ${next - c.stars} نجمة لتكبر نخلتك',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: RC.greenDark),
            ),
            const SizedBox(height: 18),
            const Text('عادات الخير اليوم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.ink)),
            const Text('افعلها في بيتك، ثم اضغط «فعلتها»، وسيعتمدها والداك.',
                style: TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 10),
            for (final h in kHabits)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    const Icon(Icons.eco_rounded, color: RC.green, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(h.title, style: const TextStyle(fontSize: 19, color: RC.ink))),
                    st.habitPendingToday(h.id)
                        ? const Text('بانتظار والديك', style: TextStyle(fontSize: 14, color: RC.plum))
                        : FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: RC.green, minimumSize: const Size(90, 48)),
                            onPressed: () {
                              st.markHabit(h.id);
                              Voice.instance.say('ما شاء الله، سيعتمدها والداك');
                            },
                            child: const Text('فعلتها', style: TextStyle(fontSize: 17)),
                          ),
                  ]),
                ),
              ),
            const SizedBox(height: 14),
            const Text('أوسمتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.ink)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final b in _badges)
                  Container(
                    decoration: BoxDecoration(
                      color: b.earned(c) ? RC.gold.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(b.icon, size: 40, color: b.earned(c) ? RC.coral : Colors.black26),
                      const SizedBox(height: 6),
                      Text(b.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: b.earned(c) ? RC.ink : Colors.black38)),
                    ]),
                  ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}

/// نخلة تنمو على ست مراحل حسب النجوم. نبات، لا ذا روح.
class PalmPainter extends CustomPainter {
  final int stage;
  PalmPainter(this.stage);

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()..color = RC.sandDark;
    final base = Offset(size.width / 2, size.height * 0.86);
    canvas.drawOval(Rect.fromCenter(center: base, width: size.width * 0.7, height: 34), ground);

    if (stage == 0) {
      // بذرة صغيرة
      canvas.drawOval(Rect.fromCenter(center: base.translate(0, -6), width: 22, height: 14), Paint()..color = const Color(0xFF8A5A2B));
      final sprout = Paint()
        ..color = RC.green
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(base.translate(0, -10), base.translate(0, -30), sprout);
      return;
    }

    final trunkH = size.height * (0.18 + stage * 0.1);
    final top = base.translate(0, -trunkH);
    final trunk = Paint()
      ..color = const Color(0xFF9A6B3A)
      ..strokeWidth = 10.0 + stage * 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, top, trunk);
    final ring = Paint()
      ..color = const Color(0xFF7A522B)
      ..strokeWidth = 2;
    for (var y = base.dy - 12; y > top.dy + 6; y -= 14) {
      canvas.drawLine(Offset(top.dx - 6 - stage, y), Offset(top.dx + 6 + stage, y - 4), ring);
    }

    final fronds = 3 + stage;
    final len = 30.0 + stage * 16;
    final leaf = Paint()
      ..color = RC.green
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < fronds; i++) {
      final a = math.pi + (math.pi * i / (fronds - 1));
      final end = top + Offset(math.cos(a) * len, math.sin(a) * len * 0.55 + len * 0.25);
      final ctrl = top + Offset(math.cos(a) * len * 0.5, math.sin(a) * len * 0.7 - 10);
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(p, leaf);
    }

    if (stage >= 4) {
      final date = Paint()..color = const Color(0xFFB5651D);
      final n = stage == 4 ? 4 : 8;
      for (var i = 0; i < n; i++) {
        final dx = (i % 4 - 1.5) * 9;
        final dy = 10.0 + (i ~/ 4) * 10;
        canvas.drawOval(Rect.fromCenter(center: top + Offset(dx, dy), width: 9, height: 12), date);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PalmPainter old) => old.stage != stage;
}
