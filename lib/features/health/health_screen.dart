import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/health/health_domain.dart';

const _outline = Color(0xFF2A1A66);

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final key = 'water_${todayKey()}';
    final cups = st.counter(key);
    return ChildShell(
      theme: SceneTheme.garden,
      child: Column(children: [
        const KidBar(title: 'صحتي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _box(
              const Color(0xFF10B981),
              Column(children: [
                Text('نصيحة اليوم', style: RT.display(19, color: Colors.white)),
                const SizedBox(height: 6),
                Text(tipOfDay(DateTime.now()), textAlign: TextAlign.center, style: RT.body(17, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 14),
            _box(
              const Color(0xFF0EA5E9),
              Column(children: [
                Text('كاسات الماء اليوم: $cups من $kWaterGoal', style: RT.display(19, color: Colors.white)),
                const SizedBox(height: 10),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  for (var k = 0; k < kWaterGoal; k++)
                    GestureDetector(
                      onTap: k == cups
                          ? () {
                              Haptics.tap();
                              st.setCounter(key, cups + 1);
                              if (cups + 1 == kWaterGoal) {
                                st.bump('activity');
                                Haptics.celebrate();
                              }
                            }
                          : null,
                      child: Icon(k < cups ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                          size: 44, color: k < cups ? Colors.white : Colors.white54),
                    ),
                ]),
                Text(cups >= kWaterGoal ? 'أحسنت! وصلت هدف الماء اليوم' : 'اضغط على الكاس كل ما شربت', style: RT.body(14, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            Chunky(
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlateGameScreen())),
              child: Text('لعبة الطبق الصحي', style: RT.display(20, color: Colors.white)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _box(Color c, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
        child: child,
      );
}

class PlateGameScreen extends StatefulWidget {
  const PlateGameScreen({super.key});
  @override
  State<PlateGameScreen> createState() => _PlateGameScreenState();
}

class _PlateGameScreenState extends State<PlateGameScreen> {
  late final List<(String, FoodKind)> _round = plateRound(Random());
  int _i = 0, _right = 0;
  bool? _last;

  Future<void> _pick(FoodKind k) async {
    final ok = _round[_i].$2 == k;
    ok ? Haptics.success() : Haptics.error();
    setState(() {
      _last = ok;
      if (ok) _right++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_i + 1 >= _round.length) {
      final st = AppScope.read(context);
      final stars = _right >= 7 ? 3 : (_right >= 5 ? 2 : 1);
      st.complete('plate_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'عرفت $_right من ${_round.length}');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _last = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = _round[_i];
    return ChildShell(
      theme: SceneTheme.garden,
      child: Column(children: [
        const KidBar(title: 'الطبق الصحي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Text('${_i + 1} من ${_round.length}', textAlign: TextAlign.center, style: RT.body(15, color: RC.onDarkSoft)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 34),
              decoration: BoxDecoration(
                color: _last == null ? Colors.white : (_last! ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
                shape: BoxShape.circle,
                border: Border.all(color: _outline, width: 4),
              ),
              child: Text(f.$1, textAlign: TextAlign.center, style: RT.display(30)),
            ),
            const SizedBox(height: 22),
            Text('متى ناكله؟', textAlign: TextAlign.center, style: RT.display(20)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Chunky(
                  color: const Color(0xFF10B981),
                  onTap: _last == null ? () => _pick(FoodKind.daily) : null,
                  child: Text('كل يوم', style: RT.display(19, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Chunky(
                  color: const Color(0xFFEF4444),
                  onTap: _last == null ? () => _pick(FoodKind.sometimes) : null,
                  child: Text('أحيانا وقليل', style: RT.display(19, color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
