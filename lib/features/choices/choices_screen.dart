import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/choices/choices_domain.dart';

const _outline = Color(0xFF2A1A66);
const _topicColors = {
  'الكل': Color(0xFF8B5CF6),
  'سلامة': Color(0xFFEF4444),
  'أخلاق': Color(0xFF10B981),
  'بيت': Color(0xFFF59E0B),
  'مدرسة': Color(0xFF0EA5E9),
  'مال': Color(0xFFFF5D8F),
};

class ChoicesScreen extends StatelessWidget {
  const ChoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      theme: SceneTheme.journey,
      child: Column(children: [
        const KidBar(title: 'وش تسوي لو؟'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('مواقف من حياتك، اختر التصرف الصح', textAlign: TextAlign.center, style: RT.body(17, color: RC.inkSoft)),
            const SizedBox(height: 14),
            for (final t in kSituationTopics)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Chunky(
                  color: _topicColors[t]!,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SituationPlayScreen(topic: t))),
                  child: Text(t == 'الكل' ? 'كل المواقف' : 'مواقف $t', style: RT.display(20, color: Colors.white)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class SituationPlayScreen extends StatefulWidget {
  final String topic;
  const SituationPlayScreen({super.key, required this.topic});
  @override
  State<SituationPlayScreen> createState() => _SituationPlayScreenState();
}

class _SituationPlayScreenState extends State<SituationPlayScreen> {
  late final List<Situation> _round = situationRound(widget.topic, Random());
  int _i = 0, _right = 0;
  int? _picked;

  void _pick(int k) {
    final ok = k == _round[_i].answer;
    ok ? Haptics.success() : Haptics.error();
    if (ok) {
      _right++;
      AppScope.read(context).bump('correct');
    }
    setState(() => _picked = k);
  }

  Future<void> _next() async {
    if (_i + 1 >= _round.length) {
      final st = AppScope.read(context);
      final stars = _right == _round.length ? 3 : (_right >= _round.length - 2 ? 2 : 1);
      st.complete('sit_${widget.topic}_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'اخترت الصح $_right من ${_round.length}');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _round[_i];
    final c = _topicColors[s.topic]!;
    return ChildShell(
      theme: SceneTheme.journey,
      child: Column(children: [
        KidBar(title: 'موقف ${_i + 1} من ${_round.length}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
              child: Text(s.text, textAlign: TextAlign.center, style: RT.display(21, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            for (var k = 0; k < s.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CandyAnswer(
                  text: s.options[k],
                  index: k,
                  state: _picked == null ? 0 : (k == s.answer ? 1 : (k == _picked ? 2 : 3)),
                  onTap: _picked == null ? () => _pick(k) : null,
                ),
              ),
            if (_picked != null) ...[
              const SizedBox(height: 6),
              Text(s.why, textAlign: TextAlign.center, style: RT.body(16, color: RC.inkSoft)),
              const SizedBox(height: 12),
              Chunky(color: c, onTap: _next, child: Text('التالي', style: RT.display(19, color: Colors.white))),
            ],
          ]),
        ),
      ]),
    );
  }
}
