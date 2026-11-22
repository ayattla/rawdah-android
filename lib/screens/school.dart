import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/quran_data.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/quran_text.dart';
import '../ui/widgets.dart';

class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current!;
    final lessons = kLessons.where((l) => l.minBand <= c.ageBand).toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'المدرسة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const _Section('القرآن الكريم'),
            for (final s in kSurahs.where((s) => s.number != 105))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BigTile(
                  title: 'سورة ${s.name}',
                  subtitle: '${s.ayat.length} آيات',
                  icon: Icons.menu_book_rounded,
                  color: RC.green,
                  done: c.completed.contains('surah_${s.number}'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SurahScreen(surah: s))),
                ),
              ),
            const _Section('دروسي'),
            for (final l in lessons)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BigTile(
                  title: l.title,
                  subtitle: l.subtitle,
                  icon: l.id == 'lesson_saudi' ? Icons.flag_rounded : Icons.lightbulb_rounded,
                  color: RC.sea,
                  done: c.completed.contains(l.id),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
                ),
              ),
            const _Section('أذكاري'),
            BigTile(
              title: 'أذكار اليوم',
              subtitle: 'ماذا أقول؟ ومتى؟',
              icon: Icons.wb_twilight_rounded,
              color: RC.plum,
              done: c.completed.contains('adhkar'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdhkarScreen())),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.greenDark)),
      );
}

/// صفحة السورة: قراءة كاملة، أو وضع «أختبر حفظي» الذي يُخفي الآيات ويكشفها واحدة واحدة.
class SurahScreen extends StatefulWidget {
  final Surah surah;
  const SurahScreen({super.key, required this.surah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  bool _memorize = false;
  int _shown = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final visible = _memorize ? s.ayat.take(_shown).toList() : s.ayat;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'سورة ${s.name}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('أقرأ'), icon: Icon(Icons.chrome_reader_mode_rounded)),
              ButtonSegment(value: true, label: Text('أختبر حفظي'), icon: Icon(Icons.visibility_off_rounded)),
            ],
            selected: {_memorize},
            onSelectionChanged: (v) => setState(() {
              _memorize = v.first;
              _shown = 0;
            }),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (s.number != 1 && s.number != 9)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(kSurahs.first.ayat.first,
                    textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24)),
              ),
            if (visible.isNotEmpty) QuranText(ayat: visible, fontSize: 28),
            if (_memorize && _shown < s.ayat.length)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(children: [
                  Text('اقرأ الآية ${_shown + 1} من حفظك، ثم اكشفها لتتأكد',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: RC.ink)),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'اكشف الآية',
                    icon: Icons.visibility_rounded,
                    color: RC.sea,
                    onTap: () => setState(() => _shown++),
                  ),
                ]),
              ),
            const SizedBox(height: 14),
            const Text('التلاوة بصوت قارئ مرخّص تُضاف في التحديث القادم بإذن الله.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 14),
            if (!_memorize || _shown >= s.ayat.length)
              PrimaryButton(
                label: 'قرأتها',
                icon: Icons.check_rounded,
                onTap: () async {
                  final first = AppScope.read(context).complete('surah_${s.number}', stars: 4);
                  if (first) await showReward(context, stars: 4, title: 'بارك الله فيك');
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ]),
        ),
      ]),
    );
  }
}

class LessonScreen extends StatelessWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        KidBar(title: lesson.title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (var i = 0; i < lesson.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Voice.instance.say('${lesson.items[i].title}. ${lesson.items[i].detail}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: RC.sea,
                          child: Text('${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(lesson.items[i].title,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.ink)),
                            if (lesson.items[i].detail.isNotEmpty)
                              Text(lesson.items[i].detail, style: const TextStyle(fontSize: 17, color: Colors.black54)),
                          ]),
                        ),
                        const Icon(Icons.volume_up_rounded, color: RC.sea),
                      ]),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text('المصدر: ${lesson.source}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'تعلمت الدرس',
              icon: Icons.check_rounded,
              onTap: () async {
                final first = AppScope.read(context).complete(lesson.id, stars: 3);
                if (first) await showReward(context, stars: 3);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'أذكار اليوم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final d in kAdhkar)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Voice.instance.say('${d.occasion} نقول: ${d.text}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.wb_twilight_rounded, color: RC.plum),
                          const SizedBox(width: 8),
                          Text(d.occasion, style: const TextStyle(fontSize: 18, color: RC.plum, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          const Icon(Icons.volume_up_rounded, color: RC.sea),
                        ]),
                        const SizedBox(height: 8),
                        Text(d.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink)),
                        const SizedBox(height: 6),
                        Text(d.source, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ]),
                    ),
                  ),
                ),
              ),
            PrimaryButton(
              label: 'حفظت الأذكار',
              icon: Icons.check_rounded,
              onTap: () async {
                final first = AppScope.read(context).complete('adhkar', stars: 3);
                if (first) await showReward(context, stars: 3);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
