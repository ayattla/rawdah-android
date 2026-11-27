import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/daily/domain/quests.dart';
import 'package:rawdah/features/quizzes/domain/mastery.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/science/data/science_content.dart';
import 'package:rawdah/features/tower/presentation/tower_screens.dart';

const _outline = Color(0xFF2A1A66);

/// رحلة اليوم: أربع مهام تتجدد يوميا، وصندوق نجوم عند إتمامها.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final qs = questsFor(DateTime.now(), level: c.level, hasHifz: c.hifz.isNotEmpty);
    final done = qs.where((q) => st.todayCount(q.kind) >= q.goal).length;
    final all = done == qs.length;
    final claimed = st.counter('chest_${todayKey()}') > 0;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'رحلة اليوم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF22D3EE), width: 3)),
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9F1C), size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('سلسلتك ${c.streak} يوم', style: RT.display(20, color: Colors.white)),
                    Text('ارجع كل يوم لتكبر سلسلتك وتفتح الصندوق', style: RT.body(13.5, color: Colors.white70)),
                  ]),
                ),
                Text('$done/${qs.length}', style: RT.display(26, color: const Color(0xFFFFC23F))),
              ]),
            ),
            const SizedBox(height: 14),
            for (final q in qs) _QuestRow(q: q, have: st.todayCount(q.kind)),
            const SizedBox(height: 10),
            PrimaryButton(
              label: claimed ? 'استلمت صندوق اليوم' : (all ? 'افتح صندوق اليوم (${chestStars(qs)} نجمة)' : 'أكمل المهام لتفتح الصندوق'),
              icon: claimed ? Icons.check_rounded : Icons.redeem_rounded,
              color: all && !claimed ? const Color(0xFFF59E0B) : RC.sandDark,
              onTap: all && !claimed
                  ? () async {
                      final n = chestStars(qs);
                      if (st.claimDailyChest(n)) await showReward(context, stars: n, title: 'صندوق اليوم لك!');
                    }
                  : null,
            ),
            const SizedBox(height: 18),
            const _WeeklyLeague(),
          ]),
        ),
      ]),
    );
  }
}

/// دوري الأسبوع: كل يوم يفتح فيه الطفل صندوق اليوم يضيء، وخمسة أيام تعطيه وسام الأسبوع.
class _WeeklyLeague extends StatelessWidget {
  const _WeeklyLeague();

  static const _names = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: (today.weekday - DateTime.saturday) % 7));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final lit = [for (final d in days) st.counter('chest_${todayKey(d)}') > 0];
    final n = lit.where((x) => x).length;
    final weekKey = 'week_${todayKey(start)}';
    final claimed = st.counter(weekKey) > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
      child: Column(children: [
        Text('دوري الأسبوع', style: RT.display(20)),
        Text('افتح صندوق اليوم ٥ أيام هذا الأسبوع لتربح وسام الأسبوع', textAlign: TextAlign.center, style: RT.body(13.5, color: RC.inkSoft)),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: lit[i] ? const Color(0xFFFFC23F) : (days[i] == today ? const Color(0xFFE9E3FF) : RC.sand),
                    shape: BoxShape.circle,
                    border: Border.all(color: _outline, width: 2.5),
                  ),
                  child: lit[i] ? const Icon(Icons.check_rounded, size: 20, color: _outline) : null,
                ),
                const SizedBox(height: 4),
                Text(_names[i], style: RT.body(11.5, color: RC.inkSoft)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        Text('الأوسمة: ${st.counter('medals')}', style: RT.display(16, color: const Color(0xFF8B5CF6))),
        const SizedBox(height: 8),
        PrimaryButton(
          label: claimed ? 'استلمت وسام هذا الأسبوع' : (n >= 5 ? 'استلم وسام الأسبوع (٤٠ نجمة)' : '$n من ٥ أيام'),
          icon: Icons.military_tech_rounded,
          color: n >= 5 && !claimed ? const Color(0xFF8B5CF6) : RC.sandDark,
          onTap: n >= 5 && !claimed
              ? () async {
                  st.setCounter(weekKey, 1);
                  st.setCounter('medals', st.counter('medals') + 1);
                  st.addStars(40);
                  await showReward(context, stars: 40, title: 'وسام الأسبوع لك!');
                }
              : null,
        ),
      ]),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final DailyQuest q;
  final int have;
  const _QuestRow({required this.q, required this.have});

  @override
  Widget build(BuildContext context) {
    final ok = have >= q.goal;
    final icon = switch (q.kind) {
      'correct' => Icons.quiz_rounded,
      'tower' => Icons.extension_rounded,
      'review' => Icons.autorenew_rounded,
      _ => Icons.task_alt_rounded,
    };
    void go() {
      final Widget? w = switch (q.kind) {
        'tower' => const TowerScreen(),
        'correct' => const MasteryScreen(),
        _ => null,
      };
      if (w != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Chunky(
        color: ok ? const Color(0xFFE6F7EE) : Colors.white,
        border: Border.all(color: _outline, width: 3),
        radius: 20,
        depth: 5,
        padding: const EdgeInsets.all(12),
        onTap: go,
        semanticLabel: '${q.text}، $have من ${q.goal}',
        child: Row(children: [
          KhatamBadge(icon: ok ? Icons.check_rounded : icon, color: ok ? const Color(0xFF10B981) : const Color(0xFF8B5CF6), size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.text, style: RT.display(16)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (have / q.goal).clamp(0.0, 1.0),
                  minHeight: 9,
                  color: ok ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                  backgroundColor: RC.sandDark,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Text('${have.clamp(0, q.goal)}/${q.goal}', style: RT.display(16, color: RC.inkSoft)),
        ]),
      ),
    );
  }
}

/// إتقاني: نسبة إتقان كل بنك أسئلة، وتدريب ذكي يعيد ما لم يتقن حتى يستقر.
class MasteryScreen extends StatelessWidget {
  const MasteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final general = kQuestions.where((q) => q.band <= c.ageBand).toList();
    final science = scienceQuestionsFor(c.ageBand);
    final banks = [('أسئلة الدين والثقافة', general, const Color(0xFF8B5CF6)), ('أسئلة العلوم', science, const Color(0xFF0EA5E9))];
    final all = [...general, ...science];
    final ratio = masteryRatio(all, c.mastery);
    final today = dayNumber(DateTime.now());
    final due = all.where((q) => (c.mastery[q.id]?[1] ?? 1 << 30) <= today && !isMastered(c.mastery[q.id])).length;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'إتقاني'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: SizedBox(
                width: 170,
                height: 170,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(value: ratio, strokeWidth: 14, color: const Color(0xFF10B981), backgroundColor: RC.sandDark),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${(ratio * 100).round()}٪', style: RT.display(36)),
                    Text('متقن', style: RT.body(14, color: RC.inkSoft)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Text('السؤال يعتبر متقنا إذا أجبته صح أربع مرات في أيام مختلفة',
                textAlign: TextAlign.center, style: RT.body(14, color: RC.inkSoft)),
            const SizedBox(height: 14),
            for (final (name, pool, col) in banks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _outline, width: 3)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(name, style: RT.display(16))),
                      Text('${pool.where((q) => isMastered(c.mastery[q.id])).length} من ${pool.length}', style: RT.body(14, color: RC.inkSoft)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: masteryRatio(pool, c.mastery), minHeight: 10, color: col, backgroundColor: RC.sandDark),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: due > 0 ? 'تدريب الإتقان ($due للمراجعة)' : 'تدريب الإتقان',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuizRunner(title: 'تدريب الإتقان', questions: smartPick(all, c.mastery, today, count: 8)),
              )),
            ),
          ]),
        ),
      ]),
    );
  }
}
