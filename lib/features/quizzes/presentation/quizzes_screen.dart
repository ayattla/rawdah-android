import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/features/science/data/science_content.dart';
import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/quizzes/presentation/quiz_controller.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final repo = ref.watch(quizRepositoryProvider);
    final dailyId = 'daily_${todayKey()}';
    final review = repo.reviewSet(c, count: 99);
    void open(String title, List<Question> qs, {String? completionId}) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizRunner(title: title, questions: qs, completionId: completionId)));
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
              onTap: () => open('تحدي اليوم', repo.dailyChallenge(c.ageBand, todayKey()), completionId: dailyId),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'مسابقة سريعة',
              subtitle: '5 أسئلة من مستواك',
              icon: Icons.bolt_rounded,
              color: RC.gold,
              onTap: () => open('مسابقة سريعة', repo.quickQuiz(c.ageBand)),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'مسابقة العلوم',
              subtitle: 'الفضاء والماء والنبات وجسمي',
              icon: Icons.science_rounded,
              color: RC.night,
              onTap: () => open('مسابقة العلوم', (scienceQuestionsFor(c.ageBand)..shuffle()).take(6).toList()),
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
                open('مراجعة', review.take(5).toList());
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: RC.sandDark, width: 2),
              ),
              child: Text(
                c.quizTotal == 0
                    ? 'كل إجابة صحيحة تمنحك نجمتين'
                    : 'أجبت ${c.quizCorrect} إجابة صحيحة من ${c.quizTotal}',
                textAlign: TextAlign.center,
                style: RT.display(18, weight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// شاشة المسابقة. المنطق كله في QuizController، والشاشة تعرض الحالة وتنفّذ
/// الأثر الجانبي فقط (الصوت والاهتزاز ونافذة الجائزة).
class QuizRunner extends ConsumerStatefulWidget {
  final String title;
  final List<Question> questions;
  final String? completionId;

  /// عند وجوده يُستدعى بعدد الإجابات الصحيحة بدل نافذة المكافأة (يستخدمه تحدي الصديق).
  final Future<void> Function(int right)? onFinish;
  const QuizRunner({super.key, required this.title, required this.questions, this.completionId, this.onFinish});

  @override
  ConsumerState<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends ConsumerState<QuizRunner> {
  late final QuizArgs _args =
      QuizArgs(title: widget.title, questions: widget.questions, completionId: widget.completionId);

  QuizController get _ctrl => ref.read(quizControllerProvider(_args).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say(widget.questions.first.text));
  }

  @override
  void dispose() {
    Voice.instance.stop();
    super.dispose();
  }

  void _answer(int k) {
    final q = ref.read(quizControllerProvider(_args)).current;
    final ok = _ctrl.answer(k);
    if (ok == null) return;
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    Voice.instance.say(ok ? 'إجابة صحيحة. ${q.explain}' : 'الإجابة الصحيحة: ${q.options[q.answer]}. ${q.explain}');
  }

  Future<void> _next() async {
    if (_ctrl.next()) {
      Voice.instance.say(ref.read(quizControllerProvider(_args)).current.text);
      return;
    }
    final s = ref.read(quizControllerProvider(_args));
    if (widget.onFinish != null) {
      await widget.onFinish!(s.right);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final stars = _ctrl.finish();
    await showReward(context, stars: stars, title: '${s.right} من ${s.total}');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(quizControllerProvider(_args));
    final q = s.current;
    return ChildShell(
      child: Column(children: [
        KidBar(title: widget.title),
        // شريط التقدم: خانة لكل سؤال، تتلون بنتيجته
        Semantics(
          label: 'السؤال ${s.index + 1} من ${s.total}، أجبت ${s.right} إجابات صحيحة',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              for (var k = 0; k < s.total; k++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: k < s.results.length
                          ? (s.results[k] ? RC.green : RC.coral)
                          : (k == s.index ? RC.gold : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: RC.sandDark),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 20),
              decoration: BoxDecoration(color: RC.ink, borderRadius: BorderRadius.circular(28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('السؤال ${s.index + 1} من ${s.total}',
                      style: RT.display(15, color: RC.gold, weight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'استمع',
                    icon: const Icon(Icons.volume_up_rounded, color: RC.gold, size: 30),
                    onPressed: () => Voice.instance.say(q.text),
                  ),
                ]),
                Text(q.text, style: RT.display(26, color: Colors.white, weight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionButton(text: q.options[k], state: s.optionState(k), onTap: () => _answer(k)),
              ),
            if (s.answered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: s.lastCorrect ? RC.green : RC.gold, width: 2.5),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  KhatamBadge(
                    icon: s.lastCorrect ? Icons.check_rounded : Icons.lightbulb_rounded,
                    color: s.lastCorrect ? RC.green : RC.gold,
                    size: 40,
                    iconColor: s.lastCorrect ? Colors.white : RC.ink,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(q.explain, style: RT.body(18, weight: FontWeight.w500))),
                ]),
              ),
              const SizedBox(height: 14),
              PrimaryButton(label: s.isLast ? 'النتيجة' : 'التالي', onTap: _next),
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
    return Chunky(
      color: bg,
      edge: state == 0 ? RC.sandDark : null,
      border: state == 0 ? Border.all(color: RC.sandDark, width: 2) : null,
      radius: 22,
      depth: 5,
      onTap: onTap,
      semanticLabel: switch (state) {
        1 => '$text، الإجابة الصحيحة',
        2 => '$text، إجابتك، خطأ',
        _ => text,
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          if (state != 0) ...[
            Icon(state == 1 ? Icons.check_circle_rounded : Icons.cancel_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(text,
                textAlign: TextAlign.center, style: RT.display(23, color: state == 0 ? RC.ink : Colors.white)),
          ),
          if (state != 0) const SizedBox(width: 36),
        ]),
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
