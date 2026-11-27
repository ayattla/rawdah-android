import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// سلم المعرفة: عشر درجات تصعب تدريجيا، ومعك مساعدتان: حذف خيار والتخطي.
List<Question> ladderQuestions(int band, Random r) {
  final all = [...kQuestions, ...kGeneratedQuestions, ...scienceQuestionsFor(band)].where((q) => q.band <= band).toList()..shuffle(r);
  final out = <Question>[];
  if (band > 0) {
    out.addAll(all.where((q) => q.band < band).take(5));
    out.addAll(all.where((q) => q.band == band).take(5));
  }
  for (final q in all) {
    if (out.length >= 11) break; // ١٠ + واحد احتياط للتخطي
    if (!out.contains(q)) out.add(q);
  }
  return out;
}

const kLadderPrizes = [1, 2, 3, 5, 7, 10, 13, 16, 20, 25];

class LadderScreen extends StatefulWidget {
  const LadderScreen({super.key});
  @override
  State<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends State<LadderScreen> {
  List<Question>? _qs;
  int _step = 0, _qi = 0;
  int? _picked;
  bool _usedHalf = false, _usedSkip = false;
  Set<int> _hidden = {};
  final _r = Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _qs ??= ladderQuestions(AppScope.read(context).current!.ageBand, _r);
  }

  Question get _q => _qs![_qi];

  Future<void> _finish(int reached, {required bool top}) async {
    final st = AppScope.read(context);
    final prize = reached == 0 ? 0 : kLadderPrizes[reached - 1];
    if (prize > 0) st.addStars(prize);
    if (top) st.setCounter('ladder_top', st.counter('ladder_top') + 1);
    await showReward(context, stars: top ? 3 : (reached >= 5 ? 2 : 1), title: top ? 'وصلت القمة! +$prize نجمة' : 'وصلت الدرجة $reached، +$prize نجمة');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pick(int k) async {
    final ok = k == _q.answer;
    ok ? Haptics.success() : Haptics.error();
    setState(() => _picked = k);
    final st = AppScope.read(context);
    st.recordAnswer(_q.id, ok);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (!ok) return _finish(_step, top: false);
    if (_step + 1 >= 10) return _finish(10, top: true);
    setState(() {
      _step++;
      _qi = _step;
      _picked = null;
      _hidden = {};
    });
  }

  void _half() {
    final wrong = [for (var k = 0; k < _q.options.length; k++) if (k != _q.answer) k]..shuffle(_r);
    setState(() {
      _usedHalf = true;
      _hidden = wrong.take(_q.options.length - 2).toSet();
    });
  }

  void _skip() => setState(() {
        _usedSkip = true;
        _qi = _qs!.length - 1;
        _hidden = {};
      });

  @override
  Widget build(BuildContext context) {
    const outline = Color(0xFF2A1A66);
    final q = _q;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'سلم المعرفة • درجة ${_step + 1}'),
        SizedBox(
          height: 46,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (var k = 0; k < 10; k++)
              Container(
                width: 40,
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: k < _step ? const Color(0xFF10B981) : (k == _step ? const Color(0xFFFFC23F) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: outline, width: 2),
                ),
                child: Text('${kLadderPrizes[k]}', style: RT.display(14)),
              ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFFC23F), width: 3)),
              child: Text(q.text, textAlign: TextAlign.center, style: RT.display(20, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            for (var k = 0; k < q.options.length; k++)
              if (!_hidden.contains(k))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Chunky(
                    color: _picked == null
                        ? Colors.white
                        : (k == q.answer ? const Color(0xFFD1FAE5) : (k == _picked ? const Color(0xFFFEE2E2) : Colors.white)),
                    onTap: _picked == null ? () => _pick(k) : null,
                    child: Text(q.options[k], textAlign: TextAlign.center, style: RT.display(18)),
                  ),
                ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Chunky(
                  color: _usedHalf || q.options.length < 3 ? RC.sandDark : const Color(0xFF8B5CF6),
                  onTap: _usedHalf || _picked != null || q.options.length < 3 ? null : _half,
                  child: Text('احذف خيارا', style: RT.display(16, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Chunky(
                  color: _usedSkip ? RC.sandDark : const Color(0xFF0EA5E9),
                  onTap: _usedSkip || _picked != null ? null : _skip,
                  child: Text('غير السؤال', style: RT.display(16, color: Colors.white)),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            if (_picked == null && _step > 0)
              TextButton(
                onPressed: () => _finish(_step, top: false),
                child: Text('أكتفي وآخذ ${kLadderPrizes[_step - 1]} نجمة', style: RT.body(15, color: RC.inkSoft)),
              ),
          ]),
        ),
      ]),
    );
  }
}
