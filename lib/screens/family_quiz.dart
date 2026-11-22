import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';

/// «مجلس العائلة» على جهاز واحد: يتناوب أفراد الأسرة على الأسئلة.
/// النسخة المباشرة بين عدة أجهزة تأتي مع الخلفية السحابية لاحقًا.
class FamilyQuizScreen extends StatefulWidget {
  const FamilyQuizScreen({super.key});

  @override
  State<FamilyQuizScreen> createState() => _FamilyQuizScreenState();
}

class _FamilyQuizScreenState extends State<FamilyQuizScreen> {
  final List<TextEditingController> _names = [
    TextEditingController(text: 'الفريق الأول'),
    TextEditingController(text: 'الفريق الثاني'),
  ];
  int _level = 0;
  bool _started = false;

  List<Question> _qs = [];
  List<int> _scores = [];
  int _i = 0;
  int? _picked;

  int get _turn => _i % _names.length;

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    Voice.instance.stop();
    super.dispose();
  }

  void _start() {
    final pool = kQuestions.where((q) => q.band == _level).toList()..shuffle();
    final perPlayer = (pool.length ~/ _names.length).clamp(1, 3);
    setState(() {
      _qs = pool.take(perPlayer * _names.length).toList();
      _scores = List.filled(_names.length, 0);
      _i = 0;
      _picked = null;
      _started = true;
    });
    Voice.instance.say('دور ${_names[0].text}. ${_qs[0].text}');
  }

  void _answer(int k) {
    if (_picked != null) return;
    setState(() {
      _picked = k;
      if (k == _qs[_i].answer) _scores[_turn]++;
    });
    Voice.instance.say(k == _qs[_i].answer ? 'صحيح' : 'الإجابة: ${_qs[_i].options[_qs[_i].answer]}');
  }

  Future<void> _next() async {
    if (_i < _qs.length - 1) {
      setState(() {
        _i++;
        _picked = null;
      });
      Voice.instance.say('دور ${_names[_turn].text}. ${_qs[_i].text}');
      return;
    }
    final best = _scores.reduce((a, b) => a > b ? a : b);
    final winners = [for (var k = 0; k < _names.length; k++) if (_scores[k] == best) _names[k].text];
    final first = AppScope.read(context).complete('family_${todayKey()}', stars: 3);
    await showReward(context, stars: first ? 3 : 0, title: winners.length > 1 ? 'تعادل جميل' : 'فاز ${winners.first}');
    if (mounted) setState(() => _started = false);
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'مجلس العائلة'),
        Expanded(child: _started ? _game() : _setup()),
      ]),
    );
  }

  Widget _setup() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('مسابقة على جهاز واحد: يقرأ أحد الوالدين السؤال، ويجيب كل فريق في دوره.',
            style: TextStyle(fontSize: 18, color: RC.ink)),
        const SizedBox(height: 14),
        for (var k = 0; k < _names.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _names[k],
              maxLength: 14,
              style: const TextStyle(fontSize: 19),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(symbolIcon(kSymbols[k]), color: RC.gold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        Row(children: [
          if (_names.length < 4)
            TextButton.icon(
              onPressed: () => setState(() => _names.add(TextEditingController(text: 'الفريق ${_names.length + 1}'))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة فريق', style: TextStyle(fontSize: 17)),
            ),
          if (_names.length > 2)
            TextButton.icon(
              onPressed: () => setState(() => _names.removeLast().dispose()),
              icon: const Icon(Icons.remove_rounded),
              label: const Text('حذف فريق', style: TextStyle(fontSize: 17)),
            ),
        ]),
        const SizedBox(height: 8),
        const Text('مستوى الأسئلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (var b = 0; b < kAgeBandNames.length; b++)
            ChoiceChip(
              label: Text(kAgeBandNames[b], style: const TextStyle(fontSize: 16)),
              selected: _level == b,
              onSelected: (_) => setState(() => _level = b),
            ),
        ]),
        const SizedBox(height: 18),
        PrimaryButton(label: 'ابدأ المجلس', icon: Icons.play_arrow_rounded, onTap: _start),
      ]);

  Widget _game() {
    final q = _qs[_i];
    return ListView(padding: const EdgeInsets.all(16), children: [
      SizedBox(
        height: 64,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var k = 0; k < _names.length; k++)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k == _turn ? RC.gold : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text('${_names[k].text}: ${_scores[k]}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RC.ink)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Text('دور: ${_names[_turn].text}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.greenDark)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Text(q.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink)),
      ),
      const SizedBox(height: 12),
      for (var k = 0; k < q.options.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: _picked == null
                ? Colors.white
                : k == q.answer
                    ? RC.green
                    : (k == _picked ? RC.coral : Colors.white),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _answer(k),
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                alignment: Alignment.center,
                child: Text(q.options[k],
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _picked != null && (k == q.answer || k == _picked) ? Colors.white : RC.ink)),
              ),
            ),
          ),
        ),
      if (_picked != null) ...[
        Text(q.explain, style: const TextStyle(fontSize: 17, color: RC.ink)),
        const SizedBox(height: 12),
        PrimaryButton(label: _i < _qs.length - 1 ? 'السؤال التالي' : 'النتيجة', onTap: _next),
      ],
    ]);
  }
}
