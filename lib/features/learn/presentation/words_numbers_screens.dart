import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/learn/domain/letters.dart';
import 'package:rawdah/features/learn/domain/word_builder.dart';
import 'package:rawdah/features/learn/presentation/letters_screens.dart';
import 'package:rawdah/features/learn/presentation/more_games.dart';
import 'package:rawdah/features/learn/presentation/reading_screens.dart';

const _ink = Color(0xFF1F2A44);
const _gold = Color(0xFFC98A12);
const _paper = Color(0xFFFFFBF0);
const _date = Color(0xFF7A3E1D);

String _ar(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

/// مدرسة الحروف والأرقام: ثلاثة مسارات مختلفة الشكل لأنها مختلفة المهارة.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final letters = kLetters.where((l) => c.completed.contains(l.id)).length;
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'حروفي وأرقامي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _HubCard(
              big: 'أ ب ت',
              title: 'حروفي',
              line: 'تعلمت ${_ar(letters)} من ${_ar(kLetters.length)} حرف',
              color: _ink,
              onTap: () => open(const LettersPathScreen()),
            ),
            const SizedBox(height: 14),
            _HubCard(
              big: 'بـ يـ ت',
              title: 'كلماتي',
              line: 'رتب الحروف وكون الكلمة',
              color: const Color(0xFF2E6B4F),
              onTap: () => open(WordBuilderScreen(band: c.ageBand)),
            ),
            const SizedBox(height: 14),
            _HubCard(
              big: 'أقرأ',
              title: 'أقرأ وأفهم',
              line: 'نصوص قصيرة، المس الكلمة لتسمعها',
              color: const Color(0xFF8A5A12),
              onTap: () => open(const ReadingListScreen()),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _HubCard(
                  big: 'ـ؟ـ',
                  title: 'أول حرف',
                  line: 'اسمع واختر الحرف',
                  color: const Color(0xFF3D5A80),
                  compact: true,
                  onTap: () => open(FirstLetterScreen(band: c.ageBand)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  big: '٣:٣٠',
                  title: 'اقرأ الساعة',
                  line: 'العقارب والأوقات',
                  color: const Color(0xFF5B4B8A),
                  compact: true,
                  onTap: () => open(ClockGameScreen(band: c.ageBand)),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _HubCard(
                  big: '١ ٢ ٣',
                  title: 'عد التمر',
                  line: 'المس كل تمرة وعدها',
                  color: _date,
                  compact: true,
                  onTap: () => open(CountGameScreen(band: c.ageBand)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  big: '٥ > ٣',
                  title: 'أيهما أكثر؟',
                  line: 'قارن بين الصحنين',
                  color: const Color(0xFF8A5A12),
                  compact: true,
                  onTap: () => open(CompareGameScreen(band: c.ageBand)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String big;
  final String title;
  final String line;
  final Color color;
  final bool compact;
  final VoidCallback onTap;
  const _HubCard({required this.big, required this.title, required this.line, required this.color, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title، $line',
      excludeSemantics: true,
      child: Chunky(
        color: color,
        radius: 26,
        depth: 6,
        padding: EdgeInsets.all(compact ? 16 : 20),
        onTap: onTap,
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(big, style: const TextStyle(fontFamily: 'Baloo', fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 6),
                Text(title, style: RT.display(19, color: Colors.white)),
                Text(line, style: RT.body(13, color: Colors.white70)),
              ])
            : Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: RT.display(24, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(line, style: RT.body(15, color: Colors.white70)),
                  ]),
                ),
                Text(big, style: const TextStyle(fontFamily: 'Baloo', fontSize: 46, color: Colors.white, fontWeight: FontWeight.w800, height: 1.2)),
              ]),
      ),
    );
  }
}

/// كون الكلمة: الأيقونة تدل على الكلمة، والطفل يضع الحروف بالترتيب ويرى اتصالها.
class WordBuilderScreen extends StatefulWidget {
  final int band;
  final int rounds;
  final Random? random;
  const WordBuilderScreen({super.key, required this.band, this.rounds = 5, this.random});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> {
  late final Random _r = widget.random ?? Random();
  late final List<BuildWord> _words = (wordsForBand(widget.band)..shuffle(_r)).take(widget.rounds).toList();
  int _i = 0;
  int _stars = 0;
  late WordBuilder _game = _newGame();
  int? _shake;
  bool _solved = false;

  WordBuilder _newGame() => WordBuilder(_words[_i], random: _r, decoys: widget.band == 0 ? 0 : widget.band);

  void _tap(int tile) {
    if (_solved) return;
    final ok = _game.place(tile);
    ok ? Haptics.tap() : Haptics.error();
    setState(() => _shake = ok ? null : tile);
    if (ok && _game.isCorrect) {
      _solved = true;
      Haptics.success();
      _stars += _game.stars;
      Voice.instance.say(_game.target.word);
    }
  }

  Future<void> _next() async {
    if (_i + 1 >= _words.length) {
      final total = (_stars / _words.length).round().clamp(1, 3);
      AppScope.read(context).complete('words_${todayKey()}', stars: total);
      await showReward(context, stars: total, title: 'كونت ${_ar(_words.length)} كلمات!');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _game = _newGame();
      _solved = false;
      _shake = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'كلماتي ${_ar(_i + 1)} / ${_ar(_words.length)}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(color: _paper, shape: BoxShape.circle, border: Border.all(color: RC.sandDark, width: 3)),
                child: Icon(g.target.icon, size: 72, color: const Color(0xFF2E6B4F)),
              ),
            ),
            const SizedBox(height: 14),
            // الكلمة كما ركبت، تتصل حروفها تلقائيا
            SizedBox(
              height: 86,
              child: Center(
                child: Text(
                  g.typed.isEmpty ? '؟' : g.typed,
                  style: TextStyle(
                    fontFamily: 'Baloo',
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: _solved ? const Color(0xFF2E6B4F) : _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var s = 0; s < g.slots.length; s++)
                Container(
                  width: 52,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: g.slots[s] == null ? Colors.white : const Color(0xFFE6F2EA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: g.slots[s] == null && s == g.filled ? _gold : RC.sandDark,
                      width: g.slots[s] == null && s == g.filled ? 3 : 2,
                    ),
                  ),
                  child: Text(g.slots[s] == null ? '' : g.tiles[g.slots[s]!],
                      style: const TextStyle(fontFamily: 'Baloo', fontSize: 32, color: _ink, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 26),
            if (!_solved)
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
                for (var t = 0; t < g.tiles.length; t++)
                  if (!g.isUsed(t))
                    _Tile(
                      key: ValueKey('tile_${_i}_$t'),
                      text: g.tiles[t],
                      wrong: _shake == t,
                      onTap: () => _tap(t),
                    ),
              ])
            else
              Column(children: [
                Text('أحسنت! ${g.target.word}', style: RT.display(24, color: const Color(0xFF9DFFB8))),
                const SizedBox(height: 12),
                PrimaryButton(label: _i + 1 >= _words.length ? 'إنهاء' : 'الكلمة التالية', icon: Icons.arrow_forward_rounded, onTap: _next),
              ]),
            const SizedBox(height: 14),
            if (!_solved)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton.icon(
                  onPressed: () => Voice.instance.say(g.target.word),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('اسمع الكلمة'),
                ),
                TextButton.icon(
                  onPressed: () {
                    final h = g.hint();
                    if (h != null) {
                      g.mistakes++;
                      _tap(h);
                    }
                  },
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: const Text('ساعدني'),
                ),
              ]),
          ]),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final String text;
  final bool wrong;
  final VoidCallback onTap;
  const _Tile({super.key, required this.text, required this.wrong, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(wrong),
      tween: Tween(begin: wrong ? 1 : 0, end: 0),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, child) => Transform.translate(offset: Offset(sin(v * pi * 6) * 8 * v, 0), child: child),
      child: Semantics(
        button: true,
        label: 'حرف $text',
        excludeSemantics: true,
        child: Chunky(
          color: wrong ? const Color(0xFFFDE2E0) : _paper,
          radius: 16,
          depth: 5,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 68,
            child: Center(
              child: Text(text, style: const TextStyle(fontFamily: 'Baloo', fontSize: 36, color: _ink, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

/// حبة تمر مرسومة: شكل بيضاوي بني ولمعة صغيرة.
class _Date extends StatelessWidget {
  final bool counted;
  final int? number;
  final double size;
  const _Date({this.counted = false, this.number, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          decoration: BoxDecoration(
            color: counted ? const Color(0xFFB0703A) : _date,
            borderRadius: BorderRadius.all(Radius.elliptical(size / 2, size * 0.68)),
          ),
        ),
        Positioned(
          top: size * 0.18,
          right: size * 0.22,
          child: Container(
            width: size * 0.16,
            height: size * 0.34,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(size)),
          ),
        ),
        if (number != null)
          Text(_ar(number!), style: RT.display(size * 0.42, color: Colors.white)),
      ]),
    );
  }
}

/// عد التمر: يلمس كل تمرة فيظهر رقمها، ثم يختار العدد.
class CountGameScreen extends StatefulWidget {
  final int band;
  final Random? random;
  const CountGameScreen({super.key, required this.band, this.random});

  @override
  State<CountGameScreen> createState() => _CountGameScreenState();
}

class _CountGameScreenState extends State<CountGameScreen> {
  late final List<CountRound> _rounds = countRounds(widget.band, random: widget.random);
  int _i = 0, _right = 0;
  final Map<int, int> _counted = {};
  int? _wrong;
  bool _missed = false;

  CountRound get _r => _rounds[_i];

  void _tapDate(int k) {
    if (_counted.containsKey(k)) return;
    final n = _counted.length + 1;
    Haptics.tap();
    setState(() => _counted[k] = n);
    Voice.instance.say('$n');
  }

  Future<void> _answer(int v) async {
    if (v != _r.count) {
      Haptics.error();
      setState(() {
        _wrong = v;
        _missed = true;
      });
      return;
    }
    if (!_missed) _right++;
    Voice.instance.say('صح، ${_r.count}');
    if (_i + 1 >= _rounds.length) {
      final stars = _right >= _rounds.length ? 3 : (_right >= _rounds.length - 2 ? 2 : 1);
      AppScope.read(context).complete('count_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'عديت التمر كله!');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _counted.clear();
      _wrong = null;
      _missed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = _r.count > 20 ? 34.0 : (_r.count > 10 ? 40.0 : 50.0);
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'عد التمر ${_ar(_i + 1)} / ${_ar(_rounds.length)}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('كم تمرة في الصحن؟ المسها وعدها', textAlign: TextAlign.center, style: RT.display(19, color: RC.onDark)),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E7CF),
              borderRadius: BorderRadius.circular(200),
              border: Border.all(color: const Color(0xFFD9BE8C), width: 6),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  for (var k = 0; k < _r.count; k++)
                    GestureDetector(
                      key: ValueKey('date_${_i}_$k'),
                      onTap: () => _tapDate(k),
                      child: _Date(counted: _counted.containsKey(k), number: _counted[k], size: size),
                    ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(children: [
            for (final o in _r.options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Chunky(
                    color: _wrong == o ? const Color(0xFFFDE2E0) : Colors.white,
                    radius: 20,
                    depth: 5,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: () => _answer(o),
                    child: Center(child: Text(_ar(o), style: RT.display(34))),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// أيهما أكثر؟ صحنان من التمر، يلمس الطفل الصحن الأكثر أو «متساويان».
class CompareGameScreen extends StatefulWidget {
  final int band;
  final Random? random;
  const CompareGameScreen({super.key, required this.band, this.random});

  @override
  State<CompareGameScreen> createState() => _CompareGameScreenState();
}

class _CompareGameScreenState extends State<CompareGameScreen> {
  late final List<CompareRound> _rounds = compareRounds(widget.band, random: widget.random);
  int _i = 0, _right = 0;
  int? _wrong;
  bool _missed = false;

  Future<void> _answer(int v) async {
    final r = _rounds[_i];
    if (v != r.answer) {
      Haptics.error();
      setState(() {
        _wrong = v;
        _missed = true;
      });
      return;
    }
    if (!_missed) _right++;
    Voice.instance.say(r.answer == 2 ? 'صح، متساويان' : 'صح');
    if (_i + 1 >= _rounds.length) {
      final stars = _right >= _rounds.length ? 3 : (_right >= _rounds.length - 2 ? 2 : 1);
      AppScope.read(context).complete('compare_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'عينك قوية في المقارنة!');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _wrong = null;
      _missed = false;
    });
  }

  Widget _plate(int n, int index) {
    final size = n > 12 ? 26.0 : 34.0;
    return Expanded(
      child: Semantics(
        button: true,
        label: 'صحن فيه ${n} تمرة',
        excludeSemantics: true,
        child: Chunky(
          color: _wrong == index ? const Color(0xFFFDE2E0) : const Color(0xFFF4E7CF),
          radius: 28,
          depth: 6,
          padding: const EdgeInsets.all(12),
          onTap: () => _answer(index),
          child: SizedBox(
            height: 260,
            child: Center(
              child: Wrap(alignment: WrapAlignment.center, spacing: 5, runSpacing: 5, children: [
                for (var k = 0; k < n; k++) _Date(size: size),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _rounds[_i];
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'أيهما أكثر؟ ${_ar(_i + 1)} / ${_ar(_rounds.length)}'),
        Text('المس الصحن الذي فيه تمر أكثر', textAlign: TextAlign.center, style: RT.display(19, color: RC.onDark)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [_plate(r.a, 0), const SizedBox(width: 12), _plate(r.b, 1)]),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Chunky(
            color: _wrong == 2 ? const Color(0xFFFDE2E0) : Colors.white,
            radius: 20,
            depth: 5,
            padding: const EdgeInsets.symmetric(vertical: 14),
            onTap: () => _answer(2),
            child: Center(child: Text('متساويان', style: RT.display(22))),
          ),
        ),
      ]),
    );
  }
}
