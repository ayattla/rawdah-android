import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/parents/domain/goals.dart';
import 'package:rawdah/features/quizzes/domain/mastery.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// تقرير الأسبوع وهدف ولي الأمر في بطاقة الطفل بلوحة الوالدين.
class WeeklyReportCard extends StatelessWidget {
  final ChildProfile child;
  const WeeklyReportCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final week = weekActivity(child, DateTime.now());
    final totals = week.fold<(int, int, int)>((0, 0, 0), (a, d) => (a.$1 + d.$2, a.$2 + d.$3, a.$3 + d.$4));
    final maxV = max(1, week.map((d) => d.$2 + d.$3 + d.$4).fold<int>(0, max));
    final pool = [...kQuestions.where((q) => q.band <= child.ageBand), ...scienceQuestionsFor(child.ageBand)];
    final mastered = (masteryRatio(pool, child.mastery) * 100).round();
    const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: RC.sand, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('تقرير الأسبوع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RC.ink)),
        const SizedBox(height: 4),
        Text('إجابات صحيحة ${totals.$1} • ألغاز ${totals.$2} • أنشطة ${totals.$3} • إتقان $mastered٪ • سلسلة ${child.streak}',
            style: const TextStyle(fontSize: 14, color: RC.inkSoft)),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final d in week)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: 64 * (d.$2 + d.$3 + d.$4) / maxV + 2,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 4),
                  Text(days[(DateTime.parse(d.$1).weekday + 1) % 7], style: const TextStyle(fontSize: 12, color: RC.inkSoft)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        _GoalSection(child: child),
      ]),
    );
  }
}

class _GoalSection extends StatelessWidget {
  final ChildProfile child;
  const _GoalSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final g = goalOf(child);
    if (g == null) {
      return OutlinedButton.icon(
        onPressed: () => _pick(context, st),
        icon: const Icon(Icons.flag_rounded),
        label: const Text('حدد هدفا للطفل بمكافأة'),
      );
    }
    final p = g.progress(child);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('الهدف: ${g.text} (المكافأة ${g.reward} نجمة)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RC.ink)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: p / g.target, minHeight: 10, color: const Color(0xFF10B981), backgroundColor: Colors.white),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: Text(g.done(child) ? 'حققه! ينتظر الطفل استلام المكافأة' : '$p من ${g.target}', style: const TextStyle(fontSize: 13.5, color: RC.inkSoft))),
        TextButton(
          onPressed: () {
            clearGoal(child);
            st.updateChild(child);
          },
          child: const Text('إلغاء الهدف'),
        ),
      ]),
    ]);
  }

  Future<void> _pick(BuildContext context, AppState st) async {
    var kind = kGoalKinds.first;
    var target = kind.targets.first;
    var reward = 20;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('هدف للطفل', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in kGoalKinds)
                ChoiceChip(
                  label: Text(k.label),
                  selected: k == kind,
                  onSelected: (_) => set(() {
                    kind = k;
                    target = k.targets.first;
                  }),
                ),
            ]),
            const SizedBox(height: 10),
            const Text('العدد'),
            Wrap(spacing: 8, children: [
              for (final t in kind.targets) ChoiceChip(label: Text('$t'), selected: t == target, onSelected: (_) => set(() => target = t)),
            ]),
            const SizedBox(height: 10),
            const Text('المكافأة بالنجوم'),
            Wrap(spacing: 8, children: [
              for (final r in [10, 20, 40]) ChoiceChip(label: Text('$r'), selected: r == reward, onSelected: (_) => set(() => reward = r)),
            ]),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                setGoal(child, kind, target, reward);
                st.updateChild(child);
                Navigator.of(ctx).pop();
              },
              child: const Text('احفظ الهدف'),
            ),
          ]),
        ),
      ),
    );
  }
}

/// بطاقة الهدف عند الطفل (في رحلة اليوم): التقدم وزر استلام المكافأة.
class ChildGoalCard extends StatelessWidget {
  const ChildGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    final g = c == null ? null : goalOf(c);
    if (c == null || g == null) return const SizedBox.shrink();
    final p = g.progress(c);
    const outline = Color(0xFF2A1A66);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(22), border: Border.all(color: outline, width: 3)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.flag_rounded, color: Color(0xFFF59E0B), size: 30),
          const SizedBox(width: 8),
          Expanded(child: Text('هدف من أهلك: ${g.text}', style: RT.display(17))),
          Text('$p/${g.target}', style: RT.display(17, color: RC.inkSoft)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: p / g.target, minHeight: 10, color: const Color(0xFFF59E0B), backgroundColor: Colors.white),
        ),
        if (g.done(c)) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'استلم مكافأة أهلك (${g.reward} نجمة)',
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () async {
              final r = g.reward;
              st.addStars(r);
              clearGoal(c);
              st.updateChild(c);
              await showReward(context, stars: r, title: 'حققت هدف أهلك!');
            },
          ),
        ],
      ]),
    );
  }
}
