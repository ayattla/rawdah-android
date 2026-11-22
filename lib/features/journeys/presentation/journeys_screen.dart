import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/journeys/data/journeys_data.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/widgets.dart';
import 'package:rawdah/features/games/presentation/games_hub_screen.dart';
import 'package:rawdah/features/games/presentation/more_games_screen.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/school/presentation/school_screen.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';

/// المحطات المتاحة لفئة الطفل العمرية.
List<Station> stationsFor(Journey j, int band) => j.stations.where((s) {
      if (s.type == 'story') {
        final st = kStories.where((x) => x.id == s.ref);
        return st.isNotEmpty && st.first.minBand <= band;
      }
      if (s.type == 'lesson') {
        final l = kLessons.where((x) => x.id == s.ref);
        return l.isNotEmpty && l.first.minBand <= band;
      }
      return true;
    }).toList();

class JourneysScreen extends StatelessWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'رحلاتي'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kJourneys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final j = kJourneys[i];
              final st = stationsFor(j, c.ageBand);
              final done = st.where((s) => c.completed.contains(s.doneId(j.id))).length;
              final ratio = st.isEmpty ? 0.0 : done / st.length;
              return Chunky(
                color: Colors.white,
                edge: j.color.withValues(alpha: 0.45),
                border: Border.all(color: j.color.withValues(alpha: 0.3), width: 2),
                padding: const EdgeInsets.all(14),
                semanticLabel: j.title,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JourneyMap(journey: j))),
                child: Row(children: [
                  KhatamBadge(
                    icon: ratio >= 1 ? Icons.workspace_premium_rounded : j.icon,
                    color: ratio >= 1 ? RC.gold : j.color,
                    iconColor: ratio >= 1 ? RC.ink : Colors.white,
                    size: 66,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(j.title, style: RT.display(21))),
                        Text('$done من ${st.length}', style: RT.display(15, color: j.color, weight: FontWeight.w700)),
                      ]),
                      Text(j.subtitle, style: RT.body(15, color: RC.ink.withValues(alpha: 0.7))),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          color: j.color,
                          backgroundColor: j.color.withValues(alpha: 0.14),
                        ),
                      ),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class JourneyMap extends StatelessWidget {
  final Journey journey;
  const JourneyMap({super.key, required this.journey});

  Widget? _screenFor(Station s, int band) {
    switch (s.type) {
      case 'story':
        return StoryReader(story: kStories.firstWhere((x) => x.id == s.ref));
      case 'lesson':
        return LessonScreen(lesson: kLessons.firstWhere((x) => x.id == s.ref));
      case 'surah':
        final n = int.tryParse(s.ref) ?? 1;
        return SurahScreen(surah: kSurahs.firstWhere((x) => x.number == n, orElse: () => kSurahs.first));
      case 'adhkar':
        return const AdhkarScreen();
      case 'game':
        switch (s.ref) {
          case 'game_wudu':
            return const WuduOrderGame();
          case 'game_match':
            return const MatchGame();
          case 'game_mosque':
            return const MosqueBuilderGame();
          case 'game_memory':
            return const MemoryGame();
        }
        return null;
      case 'quiz':
        var qs = s.qids.map(questionById).whereType<Question>().where((q) => q.band <= band).toList();
        if (qs.length < 3) qs = s.qids.map(questionById).whereType<Question>().toList();
        return QuizRunner(title: s.title, questions: qs, completionId: s.doneId(journey.id));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final st = stationsFor(journey, c.ageBand);
    final doneFlags = st.map((s) => c.completed.contains(s.doneId(journey.id))).toList();
    final firstOpen = doneFlags.indexOf(false); // -1 = الرحلة مكتملة
    final allDone = firstOpen == -1;
    return ChildShell(
      child: Column(children: [
        KidBar(title: journey.title),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            itemCount: st.length + 1,
            itemBuilder: (context, i) {
              if (i == st.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: allDone
                      ? PrimaryButton(
                          label: 'شهادة الإتمام',
                          icon: Icons.workspace_premium_rounded,
                          color: RC.gold,
                          onTap: () {
                            // مكافأة إتمام الرحلة مرة واحدة
                            AppScope.read(context).complete('journey_${journey.id}', stars: 20);
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => CertificateScreen(journey: journey)));
                          },
                        )
                      : Center(
                          child: Text('أكمل المحطات لتنال شهادة الرحلة',
                              style: TextStyle(fontSize: 16, color: RC.ink.withValues(alpha: 0.7))),
                        ),
                );
              }
              final s = st[i];
              final done = doneFlags[i];
              final open = done || i == firstOpen;
              final alignRight = i.isEven;
              final current = i == firstOpen;
              return Column(children: [
                if (i > 0)
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: done || open ? journey.color : RC.sandDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Align(
                  alignment: alignRight ? const Alignment(0.45, 0) : const Alignment(-0.45, 0),
                  child: Semantics(
                    button: true,
                    label: s.title,
                    child: GestureDetector(
                      onTap: () {
                        if (!open) {
                          Voice.instance.say('أكمل المحطة السابقة أولًا');
                          return;
                        }
                        final screen = _screenFor(s, c.ageBand);
                        if (screen != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
                      },
                      child: Column(children: [
                        SizedBox(
                          width: 104,
                          height: 104,
                          child: Stack(alignment: Alignment.center, children: [
                            if (current)
                              KhatamBadge(
                                  icon: Icons.circle,
                                  color: journey.color.withValues(alpha: 0.22),
                                  iconColor: Colors.transparent,
                                  size: 104),
                            KhatamBadge(
                              icon: done ? Icons.check_rounded : (open ? _iconFor(s.type) : Icons.lock_rounded),
                              color: done ? RC.gold : (open ? journey.color : const Color(0xFFAFC9C3)),
                              iconColor: done ? RC.ink : (open ? Colors.white : Colors.white),
                              size: current ? 84 : 72,
                            ),
                          ]),
                        ),
                        SizedBox(
                          width: 160,
                          child: Text(s.title,
                              textAlign: TextAlign.center,
                              style: RT.display(16,
                                  weight: FontWeight.w700, color: open ? RC.ink : RC.ink.withValues(alpha: 0.6))),
                        ),
                        if (current)
                          Text('ابدأ من هنا', style: RT.body(14, color: journey.color, weight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'story':
        return Icons.auto_stories_rounded;
      case 'lesson':
        return Icons.lightbulb_rounded;
      case 'surah':
        return Icons.menu_book_rounded;
      case 'adhkar':
        return Icons.wb_twilight_rounded;
      case 'game':
        return Icons.extension_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

/// شهادة إتمام الرحلة: تصميم مزخرف بلا ذوات أرواح، يصوّرها الوالد من الشاشة.
class CertificateScreen extends StatelessWidget {
  final Journey journey;
  const CertificateScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: RC.sand,
      appBar: AppBar(backgroundColor: RC.sand, title: const Text('شهادة إتمام')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9B865), width: 6),
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: journey.color, width: 2),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const Lantern(size: 90, glow: 1),
                  const Text('شهادة إتمام', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: RC.greenDark)),
                  const Text('تُمنح هذه الشهادة إلى', style: TextStyle(fontSize: 18, color: RC.ink)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(symbolIcon(c.symbol), color: RC.gold, size: 34),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(c.name,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.coral)),
                    ),
                  ]),
                  Text('لإتمامه ${journey.title} بنجاح',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: RC.ink)),
                  Icon(journey.icon, color: journey.color, size: 48),
                  Text('${now.day}/${now.month}/${now.year}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const Text('تطبيق روضة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RC.green)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
