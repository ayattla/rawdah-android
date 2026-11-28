import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/coding/coding_domain.dart';

const _outline = Color(0xFF2A1A66);

class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});
  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  final _r = Random();
  CodeLevel? _lvl;
  int _n = 1, _mistakes = 0;
  final _prog = <Cmd>[];
  Pos? _pos;
  int _dir = 0;
  bool _running = false;
  String? _msg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lvl == null) {
      _n = AppScope.read(context).counter('code_lvl') + 1;
      _new();
    }
  }

  void _new() {
    _lvl = makeLevel(_n, _r);
    _pos = _lvl!.start;
    _dir = _lvl!.dir;
    _prog.clear();
    _msg = null;
    _mistakes = 0;
  }

  Future<void> _run() async {
    final l = _lvl!;
    setState(() {
      _running = true;
      _pos = l.start;
      _dir = l.dir;
      _msg = null;
    });
    final res = runProgram(l, _prog);
    for (final (p, d) in res.trail) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() {
        _pos = p;
        _dir = d;
      });
    }
    if (!mounted) return;
    if (res.reached) {
      Haptics.success();
      final st = AppScope.read(context);
      st.bump('tower');
      st.setCounter('code_lvl', _n);
      final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
      st.complete('code_$_n', stars: stars);
      await showReward(context, stars: stars, title: 'برنامجك اشتغل! المستوى $_n');
      if (!mounted) return;
      setState(() {
        _n++;
        _new();
        _running = false;
      });
    } else {
      Haptics.error();
      setState(() {
        _mistakes++;
        _running = false;
        _msg = res.crashed ? 'الصاروخ اصطدم! عدل الأوامر وجرب' : 'ما وصل للراية، عدل الأوامر';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _lvl!;
    const names = {Cmd.forward: 'تقدم', Cmd.left: 'لف يسار', Cmd.right: 'لف يمين'};
    const icons = {Cmd.forward: Icons.arrow_upward_rounded, Cmd.left: Icons.turn_left_rounded, Cmd.right: Icons.turn_right_rounded};
    return ChildShell(
      theme: SceneTheme.workshop,
      child: Column(children: [
        KidBar(title: 'المبرمج الصغير • مستوى $_n'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            Text('رتب الأوامر حتى يوصل الصاروخ للراية', textAlign: TextAlign.center, style: RT.body(16, color: RC.onDarkSoft)),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFF1E1458), borderRadius: BorderRadius.circular(20), border: Border.all(color: _outline, width: 4)),
                  padding: const EdgeInsets.all(6),
                  child: GridView.count(
                    crossAxisCount: l.size,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var y = 0; y < l.size; y++)
                        for (var x = 0; x < l.size; x++)
                          Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: _cell(l, Pos(x, y))),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _outline, width: 3)),
              child: Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                if (_prog.isEmpty) Text('برنامجك فاضي', style: RT.body(15, color: RC.inkSoft)),
                for (var i = 0; i < _prog.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${i + 1}', style: RT.body(12, color: Colors.white70)),
                      Icon(icons[_prog[i]], color: Colors.white, size: 20),
                    ]),
                  ),
              ]),
            ),
            Text('${_prog.length} من ${l.maxCmds} أوامر', textAlign: TextAlign.center, style: RT.body(13, color: RC.inkSoft)),
            if (_msg != null) Text(_msg!, textAlign: TextAlign.center, style: RT.display(16, color: const Color(0xFFEF4444))),
            const SizedBox(height: 8),
            Row(children: [
              for (final c in [Cmd.left, Cmd.forward, Cmd.right])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Chunky(
                      color: const Color(0xFF0EA5E9),
                      onTap: _running || _prog.length >= l.maxCmds
                          ? null
                          : () {
                              Haptics.tap();
                              setState(() => _prog.add(c));
                            },
                      child: Column(children: [
                        Icon(icons[c], color: Colors.white, size: 26),
                        Text(names[c]!, style: RT.display(14, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Chunky(
                  color: const Color(0xFFEF4444),
                  onTap: _running || _prog.isEmpty
                      ? null
                      : () => setState(() {
                            _prog.removeLast();
                            _pos = l.start;
                            _dir = l.dir;
                          }),
                  child: Text('امسح آخر أمر', style: RT.display(15, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Chunky(
                  color: const Color(0xFF10B981),
                  onTap: _running || _prog.isEmpty ? null : _run,
                  child: Text('شغل البرنامج', style: RT.display(15, color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget? _cell(CodeLevel l, Pos p) {
    if (p == _pos) {
      return Transform.rotate(angle: _dir * pi / 2, child: const Icon(Icons.rocket_rounded, color: Color(0xFFFFC23F), size: 30));
    }
    if (p == l.target) return const Icon(Icons.flag_rounded, color: Color(0xFF10B981), size: 28);
    if (l.rocks.contains(p)) return const Icon(Icons.public_rounded, color: Color(0xFF94A3B8), size: 26);
    return null;
  }
}
