import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';

/// سباق اليوم أونلاين: نفس الأسئلة العشر لكل أطفال الفئة في هذا اليوم،
/// محاولة واحدة، والترتيب بالدرجة ثم بالسرعة. لا نص حر: الأسماء ألقاب معتمدة فقط.
String raceKey(DateTime d, int band) => 'd${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}_b$band';

List<Question> raceQuestions(DateTime d, int band) {
  final r = Random(d.year * 10000 + d.month * 100 + d.day + band * 7);
  final pool = [...kQuestions, ...kGeneratedQuestions].where((q) => q.band <= band).toList()..shuffle(r);
  return pool.take(10).toList();
}

class RaceEntry {
  final String nick;
  final String symbol;
  final int score;
  final int ms;
  final bool me;
  const RaceEntry(this.nick, this.symbol, this.score, this.ms, this.me);
}

/// ترتيب المتسابقين: الأعلى درجة، وعند التعادل الأسرع.
List<RaceEntry> rankRace(List<RaceEntry> e) => List.of(e)..sort((a, b) => a.score != b.score ? b.score.compareTo(a.score) : a.ms.compareTo(b.ms));

class DailyRaceScreen extends StatefulWidget {
  const DailyRaceScreen({super.key});
  @override
  State<DailyRaceScreen> createState() => _DailyRaceScreenState();
}

class _DailyRaceScreenState extends State<DailyRaceScreen> {
  List<RaceEntry>? _board;
  bool _played = false;
  String? _err;
  bool _loading = true;
  // اللعب
  List<Question>? _qs;
  int _i = 0, _score = 0;
  int? _picked;
  final _watch = Stopwatch();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _board == null && _err == null) _loadBoard();
  }

  CollectionReference<Map<String, dynamic>> _entries(ChildProfile c) =>
      FirebaseFirestore.instance.collection('races').doc(raceKey(DateTime.now(), c.ageBand)).collection('entries');

  Future<void> _loadBoard() async {
    final c = AppScope.read(context).current!;
    if (!c.onlineEnabled || !c.nickReady) {
      setState(() {
        _loading = false;
        _err = 'اطلب من والديك تفعيل المنافسة واختيار لقبك من لوحة الوالدين';
      });
      return;
    }
    if (!await Online.instance.ensure()) {
      setState(() {
        _loading = false;
        _err = 'تحتاج اتصال بالإنترنت للسباق';
      });
      return;
    }
    try {
      final me = Online.instance.playerId(c);
      final mine = await _entries(c).doc(me).get();
      final q = await _entries(c).orderBy('score', descending: true).limit(60).get();
      final list = [
        for (final d in q.docs)
          RaceEntry(d.data()['nick'] as String? ?? '', d.data()['symbol'] as String? ?? 'star', (d.data()['score'] as num?)?.toInt() ?? 0, (d.data()['ms'] as num?)?.toInt() ?? 0, d.id == me),
      ];
      if (!mounted) return;
      setState(() {
        _played = mine.exists;
        _board = rankRace(list);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'تعذر فتح السباق الآن، جرب بعد قليل';
        });
      }
    }
  }

  void _start() {
    final c = AppScope.read(context).current!;
    setState(() {
      _qs = raceQuestions(DateTime.now(), c.ageBand);
      _i = 0;
      _score = 0;
      _picked = null;
    });
    _watch
      ..reset()
      ..start();
  }

  Future<void> _pick(int k) async {
    final q = _qs![_i];
    final ok = k == q.answer;
    ok ? Haptics.success() : Haptics.error();
    setState(() {
      _picked = k;
      if (ok) _score++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (_i + 1 < _qs!.length) {
      setState(() {
        _i++;
        _picked = null;
      });
      return;
    }
    _watch.stop();
    final st = AppScope.read(context);
    final c = st.current!;
    try {
      await _entries(c).doc(Online.instance.playerId(c)).set({
        'nick': c.nick,
        'na': c.nickA,
        'nb': c.nickB,
        'symbol': c.symbol,
        'score': _score,
        'ms': _watch.elapsedMilliseconds.clamp(5000, 600000),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    st.addStars(_score * 2);
    st.setCounter('race_count', st.counter('race_count') + 1);
    if (!mounted) return;
    await showReward(context, stars: _score * 2, title: 'خلصت السباق: $_score من 10');
    if (!mounted) return;
    setState(() {
      _qs = null;
      _loading = true;
    });
    _loadBoard();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _qs != null;
    return ChildShell(
      theme: SceneTheme.quiz,
      child: Column(children: [
        const KidBar(title: 'سباق اليوم أونلاين'),
        Expanded(child: playing ? _playView() : _lobby()),
      ]),
    );
  }

  Widget _playView() {
    final q = _qs![_i];
    return ListView(padding: const EdgeInsets.all(18), children: [
      CandyProgress(value: (_i + 1) / 10, color: const Color(0xFFFFB020)),
      const SizedBox(height: 12),
      StudioQuestion(text: q.text, label: 'سؤال ${_i + 1} من 10'),
      const SizedBox(height: 14),
      for (var k = 0; k < q.options.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CandyAnswer(
            text: q.options[k],
            index: k,
            state: _picked == null ? 0 : (k == q.answer ? 1 : (k == _picked ? 2 : 3)),
            onTap: _picked == null ? () => _pick(k) : null,
          ),
        ),
    ]);
  }

  Widget _lobby() {
    const ink = Color(0xFF2A1A66);
    return ListView(padding: const EdgeInsets.all(16), children: [
      TvFrame(
        body: const Color(0xFFFFB020),
        child: Column(children: [
          const Icon(Icons.public_rounded, color: Color(0xFFFFE48A), size: 48),
          Text('سباق مع أطفال من كل مكان', textAlign: TextAlign.center, style: RT.display(21, color: Colors.white)),
          const SizedBox(height: 4),
          Text('10 أسئلة نفسها للجميع اليوم، محاولة وحدة، والفائز الأعلى درجة ثم الأسرع. كل إجابة صح نجمتان.',
              textAlign: TextAlign.center, style: RT.body(14.5, color: RC.onDarkSoft)),
        ]),
      ),
      const SizedBox(height: 12),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      if (_err != null) Text(_err!, textAlign: TextAlign.center, style: RT.display(17, color: const Color(0xFFFFE48A))),
      if (!_loading && _err == null && !_played) PrimaryButton(label: 'ابدأ السباق', icon: Icons.flag_rounded, color: const Color(0xFFEF4444), onTap: _start),
      if (!_loading && _err == null && _played)
        Text('سابقت اليوم، شوف ترتيبك وتعال بكرة', textAlign: TextAlign.center, style: RT.display(17, color: const Color(0xFF9DFFB8))),
      if (_board != null) ...[
        const SectionRibbon('لوحة الأبطال اليوم', color: Color(0xFFFF5DB1)),
        if (_board!.isEmpty) Text('كن أول متسابق اليوم!', textAlign: TextAlign.center, style: RT.display(17, color: RC.onDark)),
        for (var k = 0; k < _board!.length && k < 20; k++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _board![k].me ? const Color(0xFFFFF7E0) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _board![k].me ? const Color(0xFFFFB020) : ink, width: _board![k].me ? 3.5 : 2.5),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: k == 0 ? const Color(0xFFFFC23F) : (k == 1 ? const Color(0xFFCBD5E1) : (k == 2 ? const Color(0xFFF59E0B) : const Color(0xFFE9E4FF))),
                  border: Border.all(color: ink, width: 2),
                ),
                child: Text('${k + 1}', style: RT.display(16, color: ink)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_board![k].nick, style: RT.display(17, color: ink))),
              Text('${_board![k].score}/10', style: RT.display(17, color: const Color(0xFF8B5CF6))),
              const SizedBox(width: 8),
              Text('${(_board![k].ms / 1000).toStringAsFixed(0)}ث', style: RT.body(13, color: RC.inkSoft)),
            ]),
          ),
      ],
    ]);
  }
}
