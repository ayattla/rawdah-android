import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/badges/badges.dart';
import 'package:rawdah/features/shop/economy.dart';
import 'package:rawdah/features/shop/shop.dart';

const _outline = Color(0xFF2A1A66);

/// كنز النجوم: كل طرق كسب النجوم في مكان واحد.
class TreasureScreen extends StatefulWidget {
  const TreasureScreen({super.key});
  @override
  State<TreasureScreen> createState() => _TreasureScreenState();
}

class _TreasureScreenState extends State<TreasureScreen> {
  bool _froze = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ok = applyStreakFreeze(AppScope.read(context), DateTime.now());
      if (ok) setState(() => _froze = true);
    });
  }

  Future<void> _got(int n, String what) async {
    if (n <= 0) return;
    Haptics.celebrate();
    await showReward(context, stars: 3, title: '+$n نجمة من $what');
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current!;
    final now = DateTime.now();
    final day = calendarDayToClaim(c, now);
    final shownDay = day < 0 ? ((c.counters['cal_day'] ?? 1) - 1) % 7 : day;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'كنز النجوم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _balance(c.balance),
            if (_froze) ...[
              const SizedBox(height: 10),
              Text('حماية السلسلة اشتغلت وحفظت سلسلتك!', textAlign: TextAlign.center, style: RT.display(16, color: const Color(0xFF0EA5E9))),
            ],
            const SizedBox(height: 16),
            _title('مكافأة كل يوم'),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i < shownDay || (day < 0 && i == shownDay)
                          ? const Color(0xFF10B981)
                          : (i == shownDay ? const Color(0xFFFFC23F) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _outline, width: 2),
                    ),
                    child: Column(children: [
                      Text('${i + 1}', style: RT.body(12)),
                      Text('${kCalendarRewards[i]}', style: RT.display(16)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Chunky(
              color: day < 0 ? RC.sandDark : const Color(0xFFF59E0B),
              onTap: day < 0 ? null : () => _got(claimCalendar(st, now), 'مكافأة اليوم'),
              child: Text(day < 0 ? 'استلمت اليوم، ارجع بكرة' : 'استلم ${kCalendarRewards[day]} نجمة', style: RT.display(18, color: Colors.white)),
            ),
            Text('لو فوت يوم يرجع التقويم من أوله', textAlign: TextAlign.center, style: RT.body(13, color: RC.inkSoft)),
            const SizedBox(height: 18),
            _title('تحديات الأسبوع الكبرى'),
            for (final w in kWeeklyChallenges) _weekly(st, c, w, now),
            const SizedBox(height: 18),
            _title('جوائز الأوسمة'),
            for (var i = 0; i < kBadgeTracks.length; i++)
              if (badgePrize(c, i) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chunky(
                    color: kBadgeTracks[i].color,
                    onTap: () => _got(claimBadge(st, i), 'وسام ${kBadgeTracks[i].title}'),
                    child: Text('وسام ${kBadgeTracks[i].title}: استلم ${badgePrize(c, i)} نجمة', style: RT.display(17, color: Colors.white)),
                  ),
                ),
            if (![for (var i = 0; i < kBadgeTracks.length; i++) badgePrize(c, i)].any((p) => p > 0))
              Text('كل وسام جديد تفوز فيه يعطيك نجوم هنا', textAlign: TextAlign.center, style: RT.body(15, color: RC.inkSoft)),
            const SizedBox(height: 18),
            Chunky(
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShopScreen())),
              child: Text('روح للمتجر واصرف نجومك', style: RT.display(19, color: Colors.white)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _balance(int b) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFFC23F), width: 3)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFC23F), size: 34),
          const SizedBox(width: 8),
          Text('رصيدك $b نجمة', style: RT.display(22, color: Colors.white)),
        ]),
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, textAlign: TextAlign.center, style: RT.display(20)),
      );

  Widget _weekly(AppState st, ChildProfile c, WeeklyChallenge w, DateTime now) {
    final n = weekCount(c, w.kind, now);
    final done = weeklyClaimed(c, w, now);
    final ready = !done && n >= w.target;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: done ? const Color(0xFFD1FAE5) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _outline, width: 3)),
      child: Row(children: [
        KhatamBadge(icon: w.icon, color: const Color(0xFF8B5CF6), size: 46),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.title, style: RT.display(16)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: (n / w.target).clamp(0, 1).toDouble(), minHeight: 9, color: const Color(0xFF8B5CF6), backgroundColor: RC.sand),
            ),
            Text('${n.clamp(0, w.target)} من ${w.target} • الجائزة ${w.reward} نجمة', style: RT.body(12.5, color: RC.inkSoft)),
          ]),
        ),
        if (ready)
          TextButton(
            onPressed: () {
              if (claimWeekly(st, w, now)) _got(w.reward, 'تحدي الأسبوع');
            },
            child: Text('استلم', style: RT.display(16, color: const Color(0xFF10B981))),
          ),
        if (done) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
      ]),
    );
  }
}
