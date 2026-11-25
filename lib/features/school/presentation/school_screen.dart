import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/quran_text.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/recitation/presentation/recitation_controller.dart';
import 'package:rawdah/features/recitation/presentation/recitation_panel.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';

class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final lessons = kLessons.where((l) => l.minBand <= c.ageBand).toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'المدرسة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (st.hifzDue().isNotEmpty) ...[
              const _Section('مراجعة اليوم'),
              for (final e in st.hifzDue())
                if (surahByNumber(e.surah) case final s?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BigTile(
                      title: 'راجع سورة ${s.name}',
                      subtitle: 'اختبر حفظك وثبّته',
                      icon: Icons.autorenew_rounded,
                      badge: '${s.number}',
                      color: RC.goldDark,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => SurahScreen(surah: s, startInMemorize: true))),
                    ),
                  ),
            ],
            const _Section('القرآن الكريم'),
            for (final s in kSurahs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BigTile(
                  title: 'سورة ${s.name}',
                  subtitle: _surahSubtitle(s, c.hifz[s.number]),
                  icon: Icons.menu_book_rounded,
                  badge: '${s.number}',
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

String _surahSubtitle(Surah s, HifzEntry? e) {
  final n = '${s.ayat.length} آيات';
  if (e == null) return n;
  if (e.mastered) return '$n • متقنة';
  return '$n • محفوظة، ${nextReviewLabel(e, dayNumber(DateTime.now()))}';
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

/// صفحة السورة: قراءة كاملة مع تلاوة الشيخ، أو وضع «أختبر حفظي» الذي يُخفي الآيات ويكشفها واحدة واحدة.
class SurahScreen extends ConsumerStatefulWidget {
  final Surah surah;
  final bool startInMemorize;
  const SurahScreen({super.key, required this.surah, this.startInMemorize = false});

  @override
  ConsumerState<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends ConsumerState<SurahScreen> {
  late bool _memorize = widget.startInMemorize;
  int _shown = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final visible = _memorize ? s.ayat.take(_shown).toList() : s.ayat;
    final args = (surah: s.number, ayahCount: s.ayat.length);
    final rec = ref.watch(recitationControllerProvider(args));
    final basmalaLit = rec.status == RecitationStatus.playing && rec.highlight == null;
    final lit = rec.highlight == null ? null : rec.highlight! - 1;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'سورة ${s.name}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('أقرأ'), icon: Icon(Icons.chrome_reader_mode_rounded)),
              ButtonSegment(value: true, label: Text('أختبر حفظي'), icon: Icon(Icons.quiz_rounded)),
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 24,
                      backgroundColor: basmalaLit ? const Color(0x55F2B544) : null,
                    )),
              ),
            if (visible.isNotEmpty)
              QuranText(
                ayat: visible,
                fontSize: 28,
                highlight: lit != null && lit < visible.length ? lit : null,
                onAyahTap: (n) => ref.read(recitationControllerProvider(args).notifier).playFrom(n),
              ),
            if (_memorize && _shown < s.ayat.length)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(children: [
                  Text('اقرأ الآية ${_shown + 1} من حفظك، ثم اكشفها لتتأكد',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: RC.ink)),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'اكشف الآية',
                    icon: Icons.lightbulb_rounded,
                    color: RC.sea,
                    onTap: () => setState(() => _shown++),
                  ),
                ]),
              ),
            const SizedBox(height: 14),
            RecitationPanel(args: args),
            const SizedBox(height: 14),
            if (_memorize && _shown >= s.ayat.length) _HifzBox(surah: s),
            if (!_memorize)
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

/// بعد كشف كل الآيات في «أختبر حفظي»: تسجيل الحفظ، أو نتيجة المراجعة.
class _HifzBox extends StatelessWidget {
  final Surah surah;
  const _HifzBox({required this.surah});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final entry = st.current?.hifz[surah.number];
    final today = dayNumber(DateTime.now());

    Future<void> close(int stars, String title) async {
      if (stars > 0) await showReward(context, stars: stars, title: title);
      if (context.mounted) Navigator.of(context).pop();
    }

    if (entry == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('قريتها كلها من حفظك؟',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: RC.ink)),
        const SizedBox(height: RS.sm),
        PrimaryButton(
          label: 'حفظتها',
          icon: Icons.verified_rounded,
          onTap: () => close(st.markMemorized(surah.number) ? 5 : 0, 'ما شاء الله، حفظت سورة ${surah.name}'),
        ),
        const SizedBox(height: RS.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('باقي أحتاج أتدرب', style: TextStyle(fontSize: 17)),
        ),
      ]);
    }

    final due = entry.isDue(today);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _StrengthBar(entry: entry),
      const SizedBox(height: RS.sm),
      Text(due ? 'كيف كانت مراجعتك؟' : nextReviewLabel(entry, today),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RC.ink)),
      const SizedBox(height: RS.sm),
      PrimaryButton(
        label: 'قريتها صح',
        icon: Icons.check_rounded,
        onTap: () {
          st.reviewSurah(surah.number, ok: true);
          close(due ? 2 : 0, 'أحسنت، حفظك ثابت');
        },
      ),
      const SizedBox(height: RS.sm),
      PrimaryButton(
        label: 'تلخبطت شوي',
        icon: Icons.replay_rounded,
        color: RC.sea,
        onTap: () {
          st.reviewSurah(surah.number, ok: false);
          close(0, '');
        },
      ),
    ]);
  }
}

/// شريط قوة الحفظ بخمس خانات.
class _StrengthBar extends StatelessWidget {
  final HifzEntry entry;
  const _StrengthBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'قوة الحفظ ${entry.level} من $kHifzMaxLevel',
      excludeSemantics: true,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < kHifzMaxLevel; i++)
          Container(
            width: 34,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i < entry.level ? RC.garden : RC.sandDark,
              borderRadius: BorderRadius.circular(6),
            ),
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
