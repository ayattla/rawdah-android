import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';

// ------------------------------------------------------------------ بطاقات الذاكرة

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  static const _icons = <IconData>[
    Icons.star_rounded,
    Icons.nightlight_round,
    Icons.wb_sunny_rounded,
    Icons.park_rounded,
    Icons.menu_book_rounded,
    Icons.water_drop_rounded,
  ];
  static const _colors = <Color>[RC.gold, RC.plum, RC.coral, RC.green, RC.sea, Color(0xFF3A7BD5)];

  late List<int> _cards;
  final Set<int> _open = {};
  final Set<int> _done = {};
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final band = AppScope.read(context).current?.ageBand ?? 0;
    final pairs = band == 0 ? 4 : 6;
    _cards = [for (var i = 0; i < pairs; i++) ...[i, i]]..shuffle();
    Voice.instance.say('اقلب بطاقتين، وابحث عن الشكلين المتشابهين');
  }

  Future<void> _tap(int i) async {
    if (_busy || _open.contains(i) || _done.contains(i)) return;
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    _moves++;
    final a = _open.first, b = _open.last;
    if (_cards[a] == _cards[b]) {
      HapticFeedback.lightImpact();
      setState(() {
        _done.addAll([a, b]);
        _open.clear();
      });
      if (_done.length == _cards.length) {
        final first = AppScope.read(context).complete('game_memory', stars: 4);
        await showReward(context, stars: first ? 4 : 1, title: 'أنهيتها في $_moves محاولة');
        if (!first) AppScope.read(context).addStars(1);
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      _busy = true;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _open.clear();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _cards.length <= 8 ? 2 : 3;
    return ChildShell(
      theme: SceneTheme.play,
      child: Column(children: [
        KidBar(title: 'بطاقات الذاكرة', trailing: Text('$_moves  ', style: const TextStyle(fontSize: 20))),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _cards.length,
            itemBuilder: (_, i) {
              final shown = _open.contains(i) || _done.contains(i);
              final k = _cards[i];
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: shown ? Colors.white : RC.green,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _done.contains(i) ? RC.gold : Colors.transparent, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Center(
                    child: shown
                        ? Icon(_icons[k], size: 64, color: _colors[k])
                        : const Icon(Icons.star_border_rounded, size: 46, color: Colors.white54),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ ابنِ المسجد

const List<String> _mosqueParts = ['القاعدة', 'الجدران', 'الباب', 'القبة', 'المئذنة', 'الهلال'];

class MosqueBuilderGame extends StatefulWidget {
  const MosqueBuilderGame({super.key});

  @override
  State<MosqueBuilderGame> createState() => _MosqueBuilderGameState();
}

class _MosqueBuilderGameState extends State<MosqueBuilderGame> {
  late List<Question> _qs;
  int _qi = 0;
  int _built = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    final band = AppScope.read(context).current?.ageBand ?? 0;
    _qs = questionsFor(band)..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say('كل إجابة صحيحة تبني جزءًا من المسجد. ${_qs.first.text}'));
  }

  Question get _q => _qs[_qi % _qs.length];

  void _answer(int k) {
    if (_picked != null) return;
    final ok = k == _q.answer;
    setState(() {
      _picked = k;
      if (ok) _built++;
    });
    AppScope.read(context).recordAnswer(_q.id, ok);
    if (ok) {
      HapticFeedback.lightImpact();
      Voice.instance.say('أحسنت، أضفنا ${_mosqueParts[_built - 1]}');
    } else {
      HapticFeedback.heavyImpact();
      Voice.instance.say('الإجابة الصحيحة: ${_q.options[_q.answer]}');
    }
  }

  Future<void> _next() async {
    if (_built >= _mosqueParts.length) {
      final first = AppScope.read(context).complete('game_mosque', stars: 6);
      await showReward(context, stars: first ? 6 : 0, title: 'اكتمل المسجد');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _qi++;
      _picked = null;
    });
    Voice.instance.say(_q.text);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return ChildShell(
      theme: SceneTheme.play,
      child: Column(children: [
        const KidBar(title: 'ابنِ المسجد'),
        SizedBox(height: 200, child: CustomPaint(size: Size.infinite, painter: MosquePainter(_built))),
        Text('بنينا $_built من ${_mosqueParts.length}', style: const TextStyle(fontSize: 18, color: RC.ink)),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Text(q.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.ink)),
            ),
            const SizedBox(height: 10),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _picked == null
                      ? Colors.white
                      : k == q.answer
                          ? RC.green
                          : (k == _picked ? RC.coral : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _answer(k),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 62),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Text(q.options[k],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _picked != null && (k == q.answer || k == _picked) ? Colors.white : RC.ink)),
                    ),
                  ),
                ),
              ),
            if (_picked != null) PrimaryButton(label: 'التالي', onTap: _next),
          ]),
        ),
      ]),
    );
  }
}

/// مسجد يُبنى جزءًا جزءًا. عمارة فقط.
class MosquePainter extends CustomPainter {
  final int parts;
  MosquePainter(this.parts);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 16;
    final w = 180.0;
    final ghost = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final wall = Paint()..color = const Color(0xFFF4EBDD);
    final stone = Paint()..color = const Color(0xFFD9C3A0);
    final green = Paint()..color = RC.green;
    final gold = Paint()..color = RC.gold;

    final baseR = Rect.fromLTWH(cx - w / 2 - 14, baseY - 14, w + 28, 14);
    final wallR = Rect.fromLTWH(cx - w / 2, baseY - 94, w, 80);
    final doorR = Rect.fromLTWH(cx - 18, baseY - 60, 36, 46);
    final domeC = Offset(cx, baseY - 94);
    final minR = Rect.fromLTWH(cx + w / 2 + 6, baseY - 160, 22, 146);

    // المخطط الباهت لما لم يُبنَ بعد
    canvas.drawRect(baseR, ghost);
    canvas.drawRect(wallR, ghost);
    canvas.drawArc(Rect.fromCircle(center: domeC, radius: 56), 3.1416, 3.1416, false, ghost);
    canvas.drawRect(minR, ghost);

    if (parts >= 1) canvas.drawRRect(RRect.fromRectAndRadius(baseR, const Radius.circular(4)), stone);
    if (parts >= 2) {
      canvas.drawRect(wallR, wall);
      final win = Paint()..color = const Color(0xFF9FD8F0);
      for (final dx in [-62.0, 46.0]) {
        canvas.drawRRect(
            RRect.fromRectAndCorners(Rect.fromLTWH(cx + dx, baseY - 78, 16, 26),
                topLeft: const Radius.circular(8), topRight: const Radius.circular(8)),
            win);
      }
    }
    if (parts >= 3) {
      canvas.drawRRect(
          RRect.fromRectAndCorners(doorR, topLeft: const Radius.circular(18), topRight: const Radius.circular(18)), green);
    }
    if (parts >= 4) {
      canvas.drawArc(Rect.fromCircle(center: domeC, radius: 56), 3.1416, 3.1416, true, green);
    }
    if (parts >= 5) {
      canvas.drawRect(minR, wall);
      canvas.drawRect(Rect.fromLTWH(minR.left - 4, minR.top + 40, minR.width + 8, 8), stone);
      final cap = Path()
        ..moveTo(minR.left - 2, minR.top)
        ..lineTo(minR.center.dx, minR.top - 26)
        ..lineTo(minR.right + 2, minR.top)
        ..close();
      canvas.drawPath(cap, green);
    }
    if (parts >= 6) {
      final c = Offset(cx, domeC.dy - 74);
      canvas.drawCircle(c, 12, gold);
      canvas.drawCircle(c + const Offset(5, -3), 10, Paint()..color = const Color(0xFFEAF7FC));
      canvas.drawLine(Offset(cx, domeC.dy - 56), Offset(cx, domeC.dy - 62), gold..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant MosquePainter old) => old.parts != parts;
}
