import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/competition/presentation/competition_screen.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';

/// رحلة رمضان: فانوس لكل يوم يضيء بعمل صالح، ومسابقة رمضان، وكأس رمضان أون لاين.
class RamadanScreen extends StatelessWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final active = Online.ramadanActive;
    final day = Online.ramadanDay;
    final lit = [for (var d = 1; d <= 30; d++) c.completed.contains('rdeed_$d')];
    final todayDone = active && lit[day - 1];
    return ChildShell(
      night: true,
      child: Column(children: [
        const KidBar(title: 'رمضان'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                Text(
                  active ? 'اليوم $day من رمضان' : 'يبدأ رمضان بعد ${Online.daysToRamadan} يومًا تقريبًا',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.greenDark),
                ),
                const SizedBox(height: 4),
                Text('أضأت ${lit.where((e) => e).length} فانوسًا من 30',
                    style: const TextStyle(fontSize: 17, color: RC.ink)),
              ]),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 6,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.7,
              children: [
                for (var d = 1; d <= 30; d++)
                  Column(children: [
                    Expanded(child: Lantern(size: 52, glow: lit[d - 1] ? 1 : 0.05)),
                    Text('$d',
                        style: TextStyle(
                            color: d == day ? RC.gold : Colors.white70,
                            fontWeight: d == day ? FontWeight.w700 : FontWeight.w400)),
                  ]),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('عمل اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.ink)),
                const SizedBox(height: 6),
                Text(active ? kRamadanDeeds[day - 1] : 'تظهر أعمال رمضان اليومية عند دخول الشهر',
                    style: const TextStyle(fontSize: 19, color: RC.ink)),
                const SizedBox(height: 10),
                if (active)
                  todayDone
                      ? const Text('أضأت فانوس اليوم، تقبّل الله منك',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: RC.green, fontWeight: FontWeight.w700))
                      : PrimaryButton(
                          label: 'فعلته، أضئ الفانوس',
                          icon: Icons.light_mode_rounded,
                          color: RC.gold,
                          onTap: () async {
                            if (st.complete('rdeed_$day', stars: 5)) {
                              await showReward(context, stars: 5, title: 'أضأت فانوس اليوم');
                            }
                          },
                        ),
              ]),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'مسابقة رمضان',
              subtitle: 'أسئلة عن الصيام وليلة القدر',
              icon: Icons.nightlight_round,
              color: RC.plum,
              onTap: () {
                final qs = kQuestions.where((q) => q.id.startsWith('qr') && q.band <= c.ageBand).toList()..shuffle();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizRunner(title: 'مسابقة رمضان', questions: qs.take(5).toList())));
              },
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'كأس رمضان',
              subtitle: active
                  ? (c.onlineEnabled ? 'ترتيب الكأس في فئتك' : 'اطلب من والديك تفعيل المنافسة')
                  : 'تبدأ الكأس مع أول يوم من رمضان',
              icon: Icons.emoji_events_rounded,
              color: RC.gold,
              onTap: () {
                if (!active || !c.onlineEnabled) {
                  Voice.instance.say(active ? 'اطلب من والديك تفعيل المنافسة' : 'تبدأ الكأس مع رمضان');
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChildShell(
                    child: Column(children: [
                      const KidBar(title: 'كأس رمضان'),
                      Expanded(
                        child: RankBoard(
                          loader: () => Online.instance.cupBoard(c.ageBand),
                          meId: Online.instance.uid == null ? '' : Online.instance.playerId(c),
                        ),
                      ),
                    ]),
                  ),
                ));
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
