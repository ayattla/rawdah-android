import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// عالم العلوم: مواضيع مبسطة بالبطاقات، ثم مسابقة لكل موضوع.
class ScienceHubScreen extends StatelessWidget {
  const ScienceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final done = kScienceTopics.where((t) => c.completed.contains(t.completionId)).length;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'عالم العلوم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('أنهيت $done من ${kScienceTopics.length} مواضيع',
                textAlign: TextAlign.center, style: RT.body(15, color: RC.inkSoft)),
            const SizedBox(height: 12),
            for (final t in kScienceTopics) ...[
              BigTile(
                title: t.title,
                subtitle: t.subtitle,
                icon: t.icon,
                color: t.color,
                done: c.completed.contains(t.completionId),
                onTap: () {
                  Voice.instance.say(t.title);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScienceTopicScreen(topic: t)));
                },
              ),
              const SizedBox(height: 12),
            ],
            BigTile(
              title: 'مسابقة العلوم الكبرى',
              subtitle: '8 أسئلة من كل المواضيع',
              icon: Icons.science_rounded,
              color: RC.night,
              onTap: () {
                final qs = scienceQuestionsFor(c.ageBand)..shuffle(Random());
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizRunner(title: 'مسابقة العلوم الكبرى', questions: qs.take(8).toList())));
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

/// بطاقات الموضوع تقلب بالسحب، وفي آخرها تأمل وزر المسابقة.
class ScienceTopicScreen extends StatefulWidget {
  final ScienceTopic topic;
  const ScienceTopicScreen({super.key, required this.topic});

  @override
  State<ScienceTopicScreen> createState() => _ScienceTopicScreenState();
}

class _ScienceTopicScreenState extends State<ScienceTopicScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(i,
      duration: A11y.reduceMotionOf(context) ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final c = AppScope.of(context).current;
    final total = t.cards.length + 1;
    final qs = t.questions.where((q) => q.band <= (c?.ageBand ?? 2)).toList();
    return ChildShell(
      child: Column(children: [
        KidBar(title: t.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= _page ? t.color : RC.sandDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final card in t.cards) _CardPage(card: card, color: t.color),
              _FinishPage(topic: t, questions: qs),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(children: [
            if (_page > 0)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(RS.minTouch)),
                  onPressed: () => _go(_page - 1),
                  child: const Text('السابق', style: TextStyle(fontSize: 17)),
                ),
              ),
            if (_page > 0 && _page < total - 1) const SizedBox(width: 12),
            if (_page < total - 1)
              Expanded(
                flex: 2,
                child: PrimaryButton(label: 'التالي', icon: Icons.arrow_forward_rounded, color: t.color, onTap: () => _go(_page + 1)),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _CardPage extends StatelessWidget {
  final ScienceCard card;
  final Color color;
  const _CardPage({required this.card, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
      Container(
        height: 150,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(28)),
        child: Center(child: Icon(card.icon, size: 92, color: color)),
      ),
      const SizedBox(height: 18),
      Text(card.title, textAlign: TextAlign.center, style: RT.display(26)),
      const SizedBox(height: 10),
      Text(card.body, textAlign: TextAlign.center, style: RT.body(19, weight: FontWeight.w500)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RC.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RC.gold, width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: RC.goldDark),
            const SizedBox(width: 6),
            Text('هل تعلم؟', style: RT.display(18, color: RC.goldDark)),
          ]),
          const SizedBox(height: 6),
          Text(card.fact, style: RT.body(17)),
        ]),
      ),
      const SizedBox(height: 8),
      Align(
        child: TextButton.icon(
          onPressed: () => Voice.instance.say('${card.title}. ${card.body} هل تعلم؟ ${card.fact}'),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('اسمعها'),
        ),
      ),
    ]);
  }
}

class _FinishPage extends StatelessWidget {
  final ScienceTopic topic;
  final List<Question> questions;
  const _FinishPage({required this.topic, required this.questions});

  @override
  Widget build(BuildContext context) {
    final done = AppScope.of(context).current?.completed.contains(topic.completionId) ?? false;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Icon(Icons.auto_awesome_rounded, size: 80, color: topic.color),
      const SizedBox(height: 12),
      Text('تأمل', textAlign: TextAlign.center, style: RT.display(24)),
      const SizedBox(height: 8),
      Text(topic.reflection, textAlign: TextAlign.center, style: RT.body(19, weight: FontWeight.w500)),
      const SizedBox(height: 24),
      PrimaryButton(
        label: done ? 'أعد المسابقة' : 'اختبر نفسك',
        icon: Icons.quiz_rounded,
        color: topic.color,
        onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => QuizRunner(
            title: 'مسابقة ${topic.title}',
            questions: questions,
            completionId: topic.completionId,
          ),
        )),
      ),
    ]);
  }
}
