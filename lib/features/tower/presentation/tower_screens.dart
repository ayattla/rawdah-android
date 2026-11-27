import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/tower/domain/puzzles.dart';

const _outline = Color(0xFF2A1A66);
const _gameColors = {
  TowerGame.sequence: Color(0xFF8B5CF6),
  TowerGame.oddOne: Color(0xFFFF5D8F),
  TowerGame.balance: Color(0xFF0EA5E9),
  TowerGame.scramble: Color(0xFFF59E0B),
  TowerGame.sudoku: Color(0xFF10B981),
  TowerGame.story: Color(0xFFEF4444),
  TowerGame.riddle: Color(0xFF6366F1),
  TowerGame.compare: Color(0xFF14B8A6),
  TowerGame.missing: Color(0xFFD946EF),
};
const _gameIcons = {
  TowerGame.sequence: Icons.trending_up_rounded,
  TowerGame.oddOne: Icons.search_rounded,
  TowerGame.balance: Icons.balance_rounded,
  TowerGame.scramble: Icons.abc_rounded,
  TowerGame.sudoku: Icons.grid_4x4_rounded,
  TowerGame.story: Icons.shopping_basket_rounded,
  TowerGame.riddle: Icons.lightbulb_rounded,
  TowerGame.compare: Icons.compare_arrows_rounded,
  TowerGame.missing: Icons.spellcheck_rounded,
};

/// برج الألغاز: خمس ألعاب لا تنتهي، كل واحدة بمستويات تصعد بلا حد.
class TowerScreen extends StatelessWidget {
  const TowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (st.current == null) return const SizedBox.shrink();
    final total = TowerGame.values.fold<int>(0, (n, g) => n + st.counter(g.key));
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'برج الألغاز'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _outline,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFC23F), width: 3),
              ),
              child: Column(children: [
                Text('صعدت $total طابقا', style: RT.display(22, color: Colors.white)),
                Text('كل لعبة مستوياتها لا تنتهي، وكل مستوى أصعب من الذي قبله', textAlign: TextAlign.center, style: RT.body(14, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            for (final g in TowerGame.values) ...[
              BigTile(
                title: g.title,
                subtitle: 'المستوى ${st.counter(g.key) + 1} • ${floorName(st.counter(g.key) + 1)}',
                icon: _gameIcons[g]!,
                color: _gameColors[g]!,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TowerPlayScreen(game: g))),
              ),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// لعب مستوى واحد: عدة ألغاز متتالية، ثم يفتح المستوى التالي.
class TowerPlayScreen extends StatefulWidget {
  final TowerGame game;
  final Random? random;
  const TowerPlayScreen({super.key, required this.game, this.random});

  @override
  State<TowerPlayScreen> createState() => _TowerPlayScreenState();
}

class _TowerPlayScreenState extends State<TowerPlayScreen> {
  late final Random _r = widget.random ?? Random();
  late int _level;
  int _i = 0, _mistakes = 0;
  int? _wrong;
  bool _solved = false;
  ChoicePuzzle? _choice;
  ScramblePuzzle? _scr;
  List<int> _picked = [];
  Sudoku4? _sud;
  List<int> _cells = [];
  int? _sel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_choice == null && _scr == null && _sud == null) {
      _level = AppScope.read(context).counter(widget.game.key) + 1;
      _make();
    }
  }

  void _make() {
    _wrong = null;
    _solved = false;
    switch (widget.game) {
      case TowerGame.sequence:
        _choice = sequencePuzzle(_level, _r);
      case TowerGame.oddOne:
        _choice = oddOnePuzzle(_level, _r);
      case TowerGame.balance:
        _choice = balancePuzzle(_level, _r);
      case TowerGame.story:
        _choice = storyPuzzle(_level, _r);
      case TowerGame.riddle:
        _choice = riddlePuzzle(_level, _r);
      case TowerGame.compare:
        _choice = comparePuzzle(_level, _r);
      case TowerGame.missing:
        _choice = missingPuzzle(_level, _r);
      case TowerGame.scramble:
        _scr = scramblePuzzle(_level, _r);
        _picked = [];
      case TowerGame.sudoku:
        _sud = sudokuPuzzle(_level, _r);
        _cells = [for (var k = 0; k < 16; k++) _sud!.given[k] ? _sud!.solution[k] : 0];
        _sel = null;
    }
  }

  Future<void> _solvedOne() async {
    Haptics.success();
    AppScope.read(context).bump('tower');
    setState(() => _solved = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_i + 1 >= widget.game.perLevel) {
      final st = AppScope.read(context);
      final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
      st.setCounter(widget.game.key, _level);
      st.complete('${widget.game.key}_$_level', stars: stars);
      await showReward(context, stars: stars, title: 'أنهيت المستوى $_level! صعدت طابقا');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _make();
    });
  }

  void _miss(int? k) {
    Haptics.error();
    setState(() {
      _mistakes++;
      _wrong = k;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _gameColors[widget.game]!;
    return ChildShell(
      child: Column(children: [
        KidBar(title: '${widget.game.title} • مستوى $_level'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(children: [
            for (var k = 0; k < widget.game.perLevel; k++)
              Expanded(
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: k < _i || (k == _i && _solved) ? color : RC.sandDark,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _outline, width: 1.5),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [_body(color)])),
      ]),
    );
  }

  Widget _body(Color color) {
    switch (widget.game) {
      case TowerGame.scramble:
        return _scrambleBody(color);
      case TowerGame.sudoku:
        return _sudokuBody(color);
      default:
        return _choiceBody(color);
    }
  }

  Widget _choiceBody(Color color) {
    final p = _choice!;
    return Column(children: [
      Text(p.prompt, textAlign: TextAlign.center, style: RT.display(22)),
      const SizedBox(height: 14),
      if (p.shown.isNotEmpty)
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final s in p.shown) _pill(s, color),
          if (widget.game == TowerGame.sequence) _pill('؟', const Color(0xFFFFC23F)),
        ]),
      const SizedBox(height: 20),
      Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
        for (var k = 0; k < p.options.length; k++)
          Chunky(
            key: ValueKey('opt_${_i}_$k'),
            color: _solved && k == p.answer ? const Color(0xFFD1FAE5) : (_wrong == k ? const Color(0xFFFDE2E0) : Colors.white),
            border: Border.all(color: _outline, width: 3),
            radius: 20,
            depth: 5,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            onTap: () {
              if (_solved) return;
              if (k == p.answer) {
                Voice.instance.say('صح');
                _solvedOne();
              } else {
                _miss(k);
              }
            },
            child: Text(p.options[k], style: RT.display(22)),
          ),
      ]),
      if (_solved || _wrong != null) ...[
        const SizedBox(height: 16),
        Text(_solved ? p.why : 'فكر مرة ثانية', textAlign: TextAlign.center, style: RT.body(16, color: RC.inkSoft)),
      ],
    ]);
  }

  Widget _pill(String s, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outline, width: 2.5),
        ),
        child: Text(s, style: RT.display(24, color: RC.ink)),
      );

  Widget _scrambleBody(Color color) {
    final p = _scr!;
    final typed = [for (final k in _picked) p.tiles[k]].join();
    return Column(children: [
      Text('رتب الحروف لتكوّن كلمة', textAlign: TextAlign.center, style: RT.display(22)),
      const SizedBox(height: 16),
      Container(
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
        child: Text(typed.isEmpty ? '؟' : typed,
            style: TextStyle(fontFamily: 'Baloo', fontSize: 44, fontWeight: FontWeight.w800, color: _solved ? const Color(0xFF059669) : RC.ink)),
      ),
      const SizedBox(height: 18),
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        for (var k = 0; k < p.tiles.length; k++)
          if (!_picked.contains(k))
            Chunky(
              key: ValueKey('t_${_i}_$k'),
              color: _wrong == k ? const Color(0xFFFDE2E0) : const Color(0xFFFFF7E0),
              border: Border.all(color: _outline, width: 3),
              radius: 16,
              depth: 5,
              padding: EdgeInsets.zero,
              onTap: () {
                if (_solved) return;
                final need = [for (final c in p.word.runes) String.fromCharCode(c)][_picked.length];
                if (p.tiles[k] != need) return _miss(k);
                Haptics.tap();
                setState(() {
                  _picked.add(k);
                  _wrong = null;
                });
                if (_picked.length == p.tiles.length) {
                  Voice.instance.say(p.word);
                  _solvedOne();
                }
              },
              child: SizedBox(
                width: 58,
                height: 62,
                child: Center(child: Text(p.tiles[k], style: const TextStyle(fontFamily: 'Baloo', fontSize: 32, fontWeight: FontWeight.w700, color: RC.ink))),
              ),
            ),
      ]),
    ]);
  }

  Widget _sudokuBody(Color color) {
    final s = _sud!;
    final full = !_cells.contains(0);
    return Column(children: [
      Text('املأ الشبكة: كل صف وعمود ومربع فيه ١ ٢ ٣ ٤', textAlign: TextAlign.center, style: RT.display(18)),
      const SizedBox(height: 14),
      AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(color: _outline, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(4),
          child: GridView.count(
            crossAxisCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: [
              for (var k = 0; k < 16; k++)
                GestureDetector(
                  key: ValueKey('cell_$k'),
                  onTap: s.given[k] || _solved ? null : () => setState(() => _sel = k),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: k % 4 == 2 ? 3 : 0,
                      top: k ~/ 4 == 2 ? 3 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: s.given[k] ? const Color(0xFFE9E3FF) : (_sel == k ? const Color(0xFFFFF1B8) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(_cells[k] == 0 ? '' : '${_cells[k]}',
                        style: RT.display(30, color: s.given[k] ? _outline : color)),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var v = 1; v <= 4; v++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Chunky(
              color: Colors.white,
              border: Border.all(color: _outline, width: 3),
              radius: 16,
              depth: 5,
              padding: EdgeInsets.zero,
              onTap: () {
                if (_sel == null || _solved) return;
                Haptics.tap();
                setState(() => _cells[_sel!] = v);
              },
              child: SizedBox(width: 58, height: 58, child: Center(child: Text('$v', style: RT.display(28)))),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      PrimaryButton(
        label: full ? 'تحقق' : 'املأ كل الخانات',
        icon: Icons.check_rounded,
        color: full ? color : RC.sandDark,
        onTap: !full || _solved
            ? null
            : () {
                if (Sudoku4.validSolution(_cells)) {
                  _solvedOne();
                } else {
                  _miss(null);
                }
              },
      ),
      if (_wrong == null && _mistakes > 0 && !_solved)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('في رقم مكرر، دوره وصححه', textAlign: TextAlign.center, style: RT.body(15, color: RC.coral)),
        ),
    ]);
  }
}
