import 'dart:math';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';

class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final pool = questionsFor(c.ageBand);
    final dailyId = 'daily_${todayKey()}';
    final review = c.wrongQuestions.map(questionById).whereType<Question>().toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'المسابقات'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BigTile(
              title: 'تحدي اليوم',
              subtitle: c.completed.contains(dailyId) ? 'أنجزته اليوم، عد غدًا' : '3 أسئلة جديدة كل يوم',
              icon: Icons.today_rounded,
              color: RC.coral,
              done: c.completed.contains(dailyId),
              onTap: () {
                final seed = int.parse(todayKey().replaceAll('-', ''));
                final qs = List.of(pool)..shuffle(Random(seed));
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizRunner(title: 'تحدي اليوم', questions: qs.take(3).toList(), completionId: dailyId)));
              },
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'مسابقة سريعة',
              subtitle: '5 أسئلة من مستواك',
              icon: Icons.bolt_rounded,
              color: RC.gold,
              onTap: () {
                final qs = List.of(pool)..shuffle();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizRunner(title: 'مسابقة سريعة', questions: qs.take(5).toList())));
              },
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'سباق الدقيقة',
              subtitle: c.bestRace == 0 ? 'أجب أكبر عدد في 60 ثانية' : 'أفضل نتيجة لك: ${c.bestRace}',
              icon: Icons.timer_rounded,
              color: RC.plum,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RaceScreen())),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'راجع أخطائي',
              subtitle: review.isEmpty ? 'لا توجد أسئلة للمراجعة' : '${review.length} أسئلة تحتاج مراجعة',
              icon: Icons.refresh_rounded,
              color: RC.sea,
              onTap: () {
                if (review.isEmpty) {
                  Voice.instance.say('ممتاز، لا توجد أخطاء للمراجعة');
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizRunner(title: 'مراجعة', questions: review.take(5).toList())));
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18)),
              child: Text(
                c.quizTotal == 0
                    ? 'كل إجابة صحيحة تمنحك نجمتين'
                    : 'أجبت ${c.quizCorrect} إجابة صحيحة من ${c.quizTotal}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: RC.ink),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class QuizRunner extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final String? completionId;
  /// عند وجوده يُستدعى بعدد الإجابات الصحيحة بدل نافذة المكافأة (يستخدمه تحدي الصديق).
  final Future<void> Function(int right)? onFinish;
  const QuizRunner({super.key, required this.title, required this.questions, this.completionId, this.onFinish});

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int _i = 0;
  int? _picked;
  int _right = 0;

  Question get _q => widget.questions[_i];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say(_q.text));
  }

  @override
  void dispose() {
    Voice.instance.stop();
    super.dispose();
  }

  void _answer(int k) {
    if (_picked != null) return;
    final ok = k == _q.answer;
    setState(() {
      _picked = k;
      if (ok) _right++;
    });
    AppScope.read(context).recordAnswer(_q.id, ok);
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    Voice.instance.say(ok ? 'إجابة صحيحة. ${_q.explain}' : 'الإجابة الصحيحة: ${_q.options[_q.answer]}. ${_q.explain}');
  }

  Future<void> _next() async {
    if (_i < widget.questions.length - 1) {
      setState(() {
        _i++;
        _picked = null;
      });
      Voice.instance.say(_q.text);
      return;
    }
    if (widget.onFinish != null) {
      await widget.onFinish!(_right);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (widget.completionId != null) AppScope.read(context).complete(widget.completionId!, stars: 3);
    await showReward(context, stars: _right * 2 + (widget.completionId != null ? 3 : 0),
        title: '$_right من ${widget.questions.length}');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return ChildShell(
      child: Column(children: [
        KidBar(title: widget.title),
        LinearProgressIndicator(
          value: (_i + 1) / widget.questions.length,
          minHeight: 8,
          color: RC.gold,
          backgroundColor: Colors.white54,
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: Row(children: [
                Expanded(
                  child: Text(q.text,
                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: RC.ink, height: 1.5)),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: RC.sea, size: 32),
                  onPressed: () => Voice.instance.say(q.text),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionButton(
                  text: q.options[k],
                  state: _picked == null
                      ? 0
                      : k == q.answer
                          ? 1
                          : (k == _picked ? 2 : 0),
                  onTap: () => _answer(k),
                ),
              ),
            if (_picked != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _picked == q.answer ? const Color(0xFFDFF3E6) : const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(q.explain, style: const TextStyle(fontSize: 19, color: RC.ink, height: 1.5)),
              ),
              const SizedBox(height: 14),
              PrimaryButton(label: _i < widget.questions.length - 1 ? 'التالي' : 'النتيجة', onTap: _next),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final int state; // 0 عادي، 1 صحيح، 2 خطأ
  final VoidCallback onTap;
  const _OptionButton({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = state == 1
        ? RC.green
        : state == 2
            ? RC.coral
            : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: state == 0 ? RC.ink : Colors.white)),
        ),
      ),
    );
  }
}

/// سباق الدقيقة: أسئلة متتالية سريعة، بلا شرح، والنتيجة عدد الإجابات الصحيحة.
class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  static const _total = 60;
  late List<Question> _qs;
  int _i = 0;
  int _right = 0;
  int _left = _total;
  int? _flash; // 1 صحيح، 2 خطأ
  bool _started = false;
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final c = AppScope.read(context).current;
    _qs = questionsFor(c?.ageBand ?? 0)..shuffle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    final st = AppScope.read(context);
    final best = st.current?.bestRace ?? 0;
    st.recordRaceScore(_right);
    await showReward(context, stars: _right, title: _right > best ? 'رقم جديد! $_right' : '$_right إجابة صحيحة');
    if (mounted) Navigator.of(context).pop();
  }

  void _answer(int k) {
    if (_done || _flash != null) return;
    final q = _qs[_i % _qs.length];
    final ok = k == q.answer;
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _flash = ok ? 1 : 2;
      if (ok) _right++;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _flash = null;
        _i++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _qs[_i % _qs.length];
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'سباق الدقيقة'),
        if (!_started)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_rounded, size: 90, color: RC.plum),
                  const SizedBox(height: 12),
                  const Text('عندك 60 ثانية! أجب بسرعة وانتبه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink)),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'ابدأ', onTap: _start),
                ]),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(children: [
              const Icon(Icons.timer_rounded, color: RC.plum),
              const SizedBox(width: 6),
              Text('$_left', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.plum)),
              const Spacer(),
              const Icon(Icons.check_circle_rounded, color: RC.green),
              const SizedBox(width: 6),
              Text('$_right', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.green)),
            ]),
          ),
          LinearProgressIndicator(
            value: _left / _total,
            minHeight: 8,
            color: _left > 10 ? RC.plum : RC.coral,
            backgroundColor: Colors.white54,
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(18), children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _flash == 1
                      ? const Color(0xFFDFF3E6)
                      : _flash == 2
                          ? const Color(0xFFFFE3DA)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(q.text,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink, height: 1.5)),
              ),
              const SizedBox(height: 16),
              for (var k = 0; k < q.options.length; k++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionButton(
                    text: q.options[k],
                    state: _flash == null ? 0 : (k == q.answer ? 1 : 0),
                    onTap: () => _answer(k),
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}
