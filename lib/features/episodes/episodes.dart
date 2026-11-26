import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';
import 'package:rawdah/features/islamic/data/islamic_content.dart';
import 'package:rawdah/features/planets/data/planets_content.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// حلقة من مسلسل روضة: بطاقة معلومة أو قصة، وسؤال قصير بعدها.
class Episode {
  final String season;
  final String title;
  final String body;
  final String fact;
  final IconData icon;
  final Color color;
  final Question question;
  const Episode(this.season, this.title, this.body, this.fact, this.icon, this.color, this.question);
}

/// المواسم تُبنى من محتوى التطبيق نفسه: حلقة واحدة تنفتح كل يوم، فيبقى عند الطفل جديد يوميا.
List<Episode> buildEpisodes() {
  final out = <Episode>[];
  void fromTopic(String season, ScienceTopic t) {
    for (var i = 0; i < t.cards.length; i++) {
      final c = t.cards[i];
      out.add(Episode(season, c.title, c.body, c.fact, c.icon, t.color, t.questions[i % t.questions.length]));
    }
  }

  fromTopic('الموسم الأول: قصص الأنبياء', kTarikhTopics[0]);
  for (var i = 0; i < kSeerah.length; i++) {
    final e = kSeerah[i];
    out.add(Episode('الموسم الثاني: السيرة النبوية', e.title, e.body, e.when, Icons.route_rounded, const Color(0xFF1F5E4A),
        kSeerahQuestions[i % kSeerahQuestions.length]));
  }
  fromTopic('الموسم الثالث: الصحابة', kTarikhTopics[1]);
  fromTopic('الموسم الرابع: علماء المسلمين', kMaarifaTopics[0]);
  fromTopic('الموسم الخامس: اختراعات', kMaarifaTopics[1]);
  for (final t in kScienceTopics) {
    fromTopic('الموسم السادس: عالم العلوم', t);
  }
  return out;
}

final List<Episode> kEpisodes = buildEpisodes();

/// هل الحلقة التالية متاحة اليوم؟ حلقة واحدة في اليوم.
bool nextEpisodeOpen(int done, int lastDay, int today) => done < kEpisodes.length && lastDay < today;

class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (st.current == null) return const SizedBox.shrink();
    final done = st.counter('ep_done');
    final today = dayNumber(DateTime.now());
    final open = nextEpisodeOpen(done, st.counter('ep_last_day'), today);
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'حلقة اليوم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A66),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFF5D8F), width: 3),
              ),
              child: Column(children: [
                Text('شاهدت $done من ${kEpisodes.length} حلقة', style: RT.display(20, color: Colors.white)),
                Text(open ? 'حلقة جديدة تنتظرك اليوم' : 'ارجع بكرة لحلقة جديدة', style: RT.body(14, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < kEpisodes.length && i <= done; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BigTile(
                  title: 'الحلقة ${i + 1}: ${kEpisodes[i].title}',
                  subtitle: kEpisodes[i].season,
                  icon: i < done ? kEpisodes[i].icon : (open ? Icons.play_arrow_rounded : Icons.lock_clock_rounded),
                  color: i < done ? kEpisodes[i].color : (open ? const Color(0xFFFF5D8F) : RC.inkSoft),
                  done: i < done,
                  onTap: i < done || open
                      ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EpisodeScreen(index: i, isNew: i == done)))
                      : () => Voice.instance.say('ارجع بكرة لحلقة جديدة'),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class EpisodeScreen extends StatelessWidget {
  final int index;
  final bool isNew;
  const EpisodeScreen({super.key, required this.index, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final e = kEpisodes[index];
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'الحلقة ${index + 1}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(e.season, textAlign: TextAlign.center, style: RT.body(14, color: RC.inkSoft)),
            const SizedBox(height: 10),
            Center(child: KhatamBadge(icon: e.icon, color: e.color, size: 110)),
            const SizedBox(height: 14),
            Text(e.title, textAlign: TextAlign.center, style: RT.display(26)),
            const SizedBox(height: 10),
            Text(e.body, textAlign: TextAlign.center, style: RT.body(19, weight: FontWeight.w500)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2A1A66), width: 3),
              ),
              child: Text(e.fact, textAlign: TextAlign.center, style: RT.body(16)),
            ),
            TextButton.icon(
              onPressed: () => Voice.instance.say('${e.title}. ${e.body}'),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('اسمع الحلقة'),
            ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: isNew ? 'سؤال الحلقة' : 'أعد سؤال الحلقة',
              icon: Icons.quiz_rounded,
              color: e.color,
              onTap: () async {
                final st = AppScope.read(context);
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuizRunner(title: 'سؤال الحلقة', questions: [e.question], completionId: 'episode_$index'),
                ));
                if (isNew && st.current != null && st.counter('ep_done') == index) {
                  st.setCounter('ep_last_day', dayNumber(DateTime.now()));
                  st.setCounter('ep_done', index + 1);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
