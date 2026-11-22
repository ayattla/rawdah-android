import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'competition.dart';
import 'family_quiz.dart';
import 'games_hub.dart';
import 'garden.dart';
import 'journeys.dart';
import 'quizzes.dart';
import 'ramadan.dart';
import 'school.dart';
import 'stories.dart';

class _Place {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _Place(this.title, this.hint, this.icon, this.color, this.builder);
}

class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  static final List<_Place> _places = [
    _Place('رحلاتي', 'محطات تصل بك إلى الشهادة', Icons.route_rounded, RC.plum, (_) => const JourneysScreen()),
    _Place('بيت القصص', 'قصص نسمعها ونتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen()),
    _Place('المدرسة', 'قرآن وأذكار ودروس', Icons.school_rounded, RC.sea, (_) => const SchoolScreen()),
    _Place('ساحة الألعاب', 'نلعب ونتعلم', Icons.extension_rounded, RC.plum, (_) => const GamesHubScreen()),
    _Place('المسابقات', 'أجب واجمع النجوم', Icons.emoji_events_rounded, RC.gold, (_) => const QuizHubScreen()),
    _Place('حديقتي', 'نخلتي وعادات الخير', Icons.park_rounded, RC.green, (_) => const GardenScreen()),
    _Place('ميدان المنافسة', 'نافس واصعد الهرم', Icons.leaderboard_rounded, RC.coral, (_) => const CompetitionScreen()),
    _Place('رمضان', 'فانوس لكل يوم وكأس رمضان', Icons.nightlight_round, RC.night, (_) => const RamadanScreen()),
    _Place('مجلس العائلة', 'مسابقة مع أهلي', Icons.chair_rounded, RC.greenDark, (_) => const FamilyQuizScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const Scaffold(body: SizedBox());
    final glow = (c.streak / 7).clamp(0.2, 1.0).toDouble();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) st.leaveChild();
      },
      child: ChildShell(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIcon(
                  icon: Icons.swap_horiz_rounded,
                  color: RC.plum,
                  size: 48,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Icon(symbolIcon(c.symbol), color: RC.gold, size: 34),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('أهلًا ${c.name}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: RC.plum, borderRadius: BorderRadius.circular(30)),
                  child: Text('مستوى ${c.level}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                StarCount(stars: c.stars),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Lantern(size: 76, glow: glow),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(c.streak > 1 ? 'فانوسك يضيء ${c.streak} أيام متتالية' : 'تعال كل يوم ليزداد فانوسك نورًا',
                      style: const TextStyle(fontSize: 16, color: RC.ink)),
                ),
              ]),
            ),
              if (c.onlineEnabled && c.circleCode.isNotEmpty) _CircleChip(child: c),
              const _HadithCard(),
              const _MissionsCard(),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: _places.length,
                (context, i) {
                    final p = _places[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      elevation: 4,
                      shadowColor: p.color.withValues(alpha: 0.35),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          Voice.instance.say(p.title);
                          Navigator.of(context).push(MaterialPageRoute(builder: p.builder));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(color: p.color.withValues(alpha: 0.16), shape: BoxShape.circle),
                              child: Icon(p.icon, color: p.color, size: 50),
                            ),
                            const SizedBox(height: 10),
                            Text(p.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: RC.ink)),
                            Text(p.hint,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: RC.ink.withValues(alpha: 0.6))),
                          ]),
                        ),
                      ),
                    );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MissionsCard extends StatelessWidget {
  const _MissionsCard();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    c.rollDay();
    final claimed = c.completed.contains('missions_${todayKey()}');
    final items = [
      ('أجب 5 إجابات صحيحة', c.correctToday >= 5, '${c.correctToday > 5 ? 5 : c.correctToday}/5'),
      ('أكمل قصة أو درسًا أو سورة', c.learnToday >= 1, c.learnToday >= 1 ? '1/1' : '0/1'),
      ('العب لعبة واحدة', c.gamesToday >= 1, c.gamesToday >= 1 ? '1/1' : '0/1'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flag_rounded, color: RC.coral),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('مهام اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RC.ink)),
          ),
          if (claimed)
            const Text('أنجزتها اليوم', style: TextStyle(color: RC.green, fontWeight: FontWeight.w700))
          else if (st.missionsDone)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: RC.gold),
              onPressed: () {
                if (st.claimMissions()) showReward(context, stars: 10, title: 'أنجزت مهام اليوم');
              },
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('استلم الجائزة'),
            )
          else
            const Text('جائزة: 10 نجوم', style: TextStyle(color: Colors.black54)),
        ]),
        const SizedBox(height: 6),
        for (final m in items)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Icon(m.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: m.$2 ? RC.green : Colors.black26, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(m.$1, style: const TextStyle(fontSize: 15, color: RC.ink))),
              Text(m.$3, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ]),
          ),
      ]),
    );
  }
}

class _CircleChip extends StatelessWidget {
  final ChildProfile child;
  const _CircleChip({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Material(
          color: RC.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompetitionScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.groups_2_outlined, color: RC.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('حلقتي: ${child.circleName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: RC.greenDark)),
                ),
                Text('${child.circlePoints + child.pendingPoints} نقطة',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RC.coral)),
              ]),
            ),
          ),
        ),
      );
}

class _HadithCard extends StatelessWidget {
  const _HadithCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
    final h = kDailyHadith[day % kDailyHadith.length];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: RC.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RC.sandDark),
      ),
      child: Row(children: [
        const Icon(Icons.menu_book_rounded, color: RC.greenDark),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('حديث اليوم', style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text('قال رسول الله ﷺ: ${h.$1}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: RC.ink, height: 1.4)),
            Text(h.$2, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded, color: RC.sea),
          onPressed: () => Voice.instance.say('قال رسول الله صلى الله عليه وسلم: ${h.$1.replaceAll('«', '').replaceAll('»', '')}'),
        ),
      ]),
    );
  }
}
