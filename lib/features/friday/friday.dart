import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// بطولة الجمعة: تفتح يوم الجمعة فقط، ١٥ سؤالا، مرة واحدة في الأسبوع وجائزتها كبيرة.
bool isFriday(DateTime d) => d.weekday == DateTime.friday;

String fridayKey(DateTime d) => 'fri_${todayKey(d)}';

int fridayPrize(int score) => score * 4 + (score == 15 ? 40 : 0);

List<Question> fridayQuestions(int band, DateTime d) {
  final r = Random(d.year * 1000 + d.month * 40 + d.day); // نفس الأسئلة طول اليوم
  final all = [...kQuestions, ...kGeneratedQuestions, ...scienceQuestionsFor(band)].where((q) => q.band <= band).toList()..shuffle(r);
  return all.take(15).toList();
}

class FridayScreen extends StatefulWidget {
  const FridayScreen({super.key});
  @override
  State<FridayScreen> createState() => _FridayScreenState();
}

class _FridayScreenState extends State<FridayScreen> {
  List<Question>? _qs;
  int _i = 0, _score = 0;
  int? _picked;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current!;
    final now = DateTime.now();
    const outline = Color(0xFF2A1A66);
    final played = st.counter(fridayKey(now));
    Widget body;
    if (!_playing) {
      final daysLeft = (DateTime.friday - now.weekday + 7) % 7;
      body = ListView(padding: const EdgeInsets.all(18), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFC23F), width: 3)),
          child: Column(children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC23F), size: 60),
            Text('بطولة الجمعة', style: RT.display(26, color: Colors.white)),
            const SizedBox(height: 6),
            Text('١٥ سؤال من كل العلوم، مرة وحدة كل جمعة. كل إجابة صح ٤ نجوم، والعلامة الكاملة لها ٤٠ نجمة زيادة',
                textAlign: TextAlign.center, style: RT.body(15, color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 16),
        if (isFriday(now) && played == 0)
          Chunky(
            color: const Color(0xFF10B981),
            onTap: () => setState(() {
              _qs = fridayQuestions(c.ageBand, now);
              _playing = true;
            }),
            child: Text('ابدأ البطولة', style: RT.display(21, color: Colors.white)),
          )
        else
          Text(
            isFriday(now) ? 'خلصت بطولة اليوم: نتيجتك ${played - 1} من 15. نلقاك الجمعة الجاية' : 'البطولة تفتح يوم الجمعة، باقي $daysLeft ${daysLeft == 1 ? 'يوم' : 'أيام'}',
            textAlign: TextAlign.center,
            style: RT.display(18),
          ),
        const SizedBox(height: 14),
        Text('أفضل نتيجة لك: ${st.counter('fri_best')} من 15 • بطولات شاركت فيها: ${st.counter('fri_count')}', textAlign: TextAlign.center, style: RT.body(15, color: RC.inkSoft)),
      ]);
    } else {
      final q = _qs![_i];
      body = ListView(padding: const EdgeInsets.all(18), children: [
        Text('سؤال ${_i + 1} من 15 • صح $_score', textAlign: TextAlign.center, style: RT.display(17)),
        const SizedBox(height: 10),
        StudioQuestion(text: q.text),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CandyAnswer(text: q.options[k], index: k, state: _picked == null ? 0 : (k == q.answer ? 1 : (k == _picked ? 2 : 3)), onTap: _picked == null ? () => _pick(k) : null),
          ),
      ]);
    }
    return ChildShell(child: Column(children: [const KidBar(title: 'بطولة الجمعة'), Expanded(child: body)]));
  }

  Future<void> _pick(int k) async {
    final st = AppScope.read(context);
    final q = _qs![_i];
    final ok = k == q.answer;
    ok ? Haptics.success() : Haptics.error();
    st.recordAnswer(q.id, ok);
    setState(() {
      _picked = k;
      if (ok) _score++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_i + 1 < _qs!.length) {
      setState(() {
        _i++;
        _picked = null;
      });
      return;
    }
    final now = DateTime.now();
    st.setCounter(fridayKey(now), _score + 1);
    st.setCounter('fri_count', st.counter('fri_count') + 1);
    if (_score > st.counter('fri_best')) st.setCounter('fri_best', _score);
    final prize = fridayPrize(_score);
    st.addStars(prize);
    await showReward(context, stars: _score >= 13 ? 3 : (_score >= 8 ? 2 : 1), title: 'نتيجتك $_score من 15 • +$prize نجمة');
    if (mounted) setState(() => _playing = false);
  }
}
