import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

const _outline = Color(0xFF2A1A66);

/// مسألة سريعة: نص وثلاثة خيارات، صعوبتها حسب العمر.
(String, List<int>, int) quickMath(int band, Random r, {int? table}) {
  late int a, b, ans;
  late String op;
  if (table != null) {
    a = table;
    b = 1 + r.nextInt(10);
    op = '×';
    ans = a * b;
  } else {
    final kind = band == 0 ? r.nextInt(2) : r.nextInt(band == 1 ? 3 : 4);
    final top = band == 0 ? 10 : (band == 1 ? 30 : 60);
    switch (kind) {
      case 0:
        a = 1 + r.nextInt(top);
        b = 1 + r.nextInt(top);
        op = '+';
        ans = a + b;
      case 1:
        a = 2 + r.nextInt(top);
        b = 1 + r.nextInt(a);
        op = '−';
        ans = a - b;
      case 2:
        a = 2 + r.nextInt(9);
        b = 2 + r.nextInt(9);
        op = '×';
        ans = a * b;
      default:
        b = 2 + r.nextInt(9);
        ans = 2 + r.nextInt(9);
        a = ans * b;
        op = '÷';
    }
  }
  final o = <int>{ans};
  while (o.length < 3) {
    final v = ans + (r.nextBool() ? 1 : -1) * (1 + r.nextInt(max(3, ans ~/ 5)));
    if (v >= 0) o.add(v);
  }
  return ('‪$a $op $b‬', o.toList()..shuffle(r), ans);
}

class SpeedHubScreen extends StatelessWidget {
  const SpeedHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return ChildShell(
      theme: SceneTheme.school,
      child: Column(children: [
        const KidBar(title: 'ميدان الحساب'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Chunky(
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedPlayScreen())),
              child: Column(children: [
                Text('تحدي الدقيقة', style: RT.display(22, color: Colors.white)),
                Text('أفضل نتيجة: ${st.counter('speed_best')}', style: RT.body(15, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('جدول الضرب', textAlign: TextAlign.center, style: RT.display(20)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var t = 2; t <= 10; t++)
                  Chunky(
                    color: st.counter('mul_t$t') >= 10 ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SpeedPlayScreen(table: t))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('جدول $t', style: RT.display(18, color: Colors.white)),
                      Text('${st.counter('mul_t$t')} من 10', style: RT.body(13, color: Colors.white)),
                    ]),
                  ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}

/// بدون جدول: تحدي ٦٠ ثانية. مع جدول: ١٠ أسئلة من الجدول.
class SpeedPlayScreen extends StatefulWidget {
  final int? table;
  const SpeedPlayScreen({super.key, this.table});
  @override
  State<SpeedPlayScreen> createState() => _SpeedPlayScreenState();
}

class _SpeedPlayScreenState extends State<SpeedPlayScreen> {
  final _r = Random();
  late (String, List<int>, int) _q;
  int _score = 0, _asked = 0, _left = 60;
  int? _flash;
  Timer? _timer;
  bool _over = false;

  bool get _timed => widget.table == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked == 0 && _timer == null) {
      _q = quickMath(AppScope.read(context).current!.ageBand, _r, table: widget.table);
      if (_timed) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _left--);
          if (_left <= 0) _end();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _end() async {
    if (_over) return;
    _over = true;
    _timer?.cancel();
    final st = AppScope.read(context);
    late int stars;
    if (_timed) {
      final best = st.counter('speed_best');
      if (_score > best) st.setCounter('speed_best', _score);
      stars = _score >= 20 ? 3 : (_score >= 10 ? 2 : 1);
      st.complete('speed_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: _score > best ? 'رقم جديد! $_score إجابة' : 'جاوبت $_score صح');
    } else {
      final key = 'mul_t${widget.table}';
      if (_score > st.counter(key)) st.setCounter(key, _score);
      stars = _score == 10 ? 3 : (_score >= 7 ? 2 : 1);
      st.complete('$key${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'جدول ${widget.table}: $_score من 10');
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _pick(int v) {
    if (_over) return;
    final ok = v == _q.$3;
    ok ? Haptics.success() : Haptics.error();
    if (ok) {
      _score++;
      AppScope.read(context).bump('correct');
    }
    _asked++;
    if (!_timed && _asked >= 10) {
      _end();
      return;
    }
    setState(() {
      _flash = ok ? 1 : 0;
      _q = quickMath(AppScope.read(context).current!.ageBand, _r, table: widget.table);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      theme: SceneTheme.school,
      child: Column(children: [
        KidBar(title: _timed ? 'تحدي الدقيقة' : 'جدول ${widget.table}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Text(_timed ? 'الوقت: $_left' : 'سؤال ${_asked + 1} من 10', style: RT.display(19, color: _left <= 10 ? const Color(0xFFEF4444) : RC.ink)),
              Text('صح: $_score', style: RT.display(19, color: const Color(0xFF10B981))),
            ]),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: _flash == null ? Colors.white : (_flash == 1 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _outline, width: 4),
              ),
              child: Text(_q.$1, textAlign: TextAlign.center, style: RT.display(40)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              for (final v in _q.$2)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Chunky(color: const Color(0xFF0EA5E9), onTap: () => _pick(v), child: Text('$v', style: RT.display(26, color: Colors.white))),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
