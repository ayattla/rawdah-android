import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/learn/domain/word_builder.dart';

const _ink = Color(0xFF1F2A44);
const _paper = Color(0xFFFFFBF0);
const _wrongBg = Color(0xFFFDE2E0);

/// هيكل مشترك لألعاب الجولات: سؤال، خيارات، خطأ يلون الخيار، ونجوم في النهاية.
mixin _Rounds<T extends StatefulWidget> on State<T> {
  int i = 0, right = 0;
  Object? wrong;
  bool missed = false;
  int get total;
  String get doneId;
  String get doneTitle;
  void onNext() {}

  Future<void> answer(Object choice, Object correct, {String? say}) async {
    if (choice != correct) {
      Haptics.error();
      setState(() {
        wrong = choice;
        missed = true;
      });
      return;
    }
    if (!missed) right++;
    Haptics.success();
    Voice.instance.say(say ?? 'صح');
    if (i + 1 >= total) {
      final stars = right >= total ? 3 : (right >= total - 2 ? 2 : 1);
      AppScope.read(context).complete('${doneId}_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: doneTitle);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      i++;
      wrong = null;
      missed = false;
      onNext();
    });
  }
}

/// أول حرف: يرى الأيقونة ويسمع الكلمة، ويختار حرفها الأول.
class FirstLetterScreen extends StatefulWidget {
  final int band;
  final Random? random;
  const FirstLetterScreen({super.key, required this.band, this.random});

  @override
  State<FirstLetterScreen> createState() => _FirstLetterScreenState();
}

class _FirstLetterScreenState extends State<FirstLetterScreen> with _Rounds {
  late final rounds = firstLetterRounds(widget.band, random: widget.random);
  @override
  int get total => rounds.length;
  @override
  String get doneId => 'firstletter';
  @override
  String get doneTitle => 'أذنك قوية في الحروف!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say(rounds[0].word.word));
  }

  @override
  void onNext() => Voice.instance.say(rounds[i].word.word);

  @override
  Widget build(BuildContext context) {
    final r = rounds[i];
    return ChildShell(
      theme: SceneTheme.learn,
      child: Column(children: [
        KidBar(title: 'أول حرف ${i + 1} / $total'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('بأي حرف تبدأ الكلمة؟', textAlign: TextAlign.center, style: RT.display(21, color: RC.onDark)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Voice.instance.say(r.word.word),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(color: _paper, shape: BoxShape.circle, border: Border.all(color: RC.sandDark, width: 3)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(r.word.icon, size: 78, color: const Color(0xFF2E6B4F)),
                    const Icon(Icons.volume_up_rounded, color: RC.inkSoft),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // الكلمة تظهر بلا حرفها الأول حتى يجيب
            Text(missed || wrong != null ? r.word.word : 'ـ${r.word.word.substring(r.answer.length)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Baloo', fontSize: 48, color: _ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
              for (final o in r.options)
                Chunky(
                  key: ValueKey('opt_${i}_$o'),
                  color: wrong == o ? _wrongBg : Colors.white,
                  radius: 22,
                  depth: 5,
                  padding: EdgeInsets.zero,
                  onTap: () => answer(o, r.answer, say: r.word.word),
                  child: SizedBox(
                    width: 84,
                    height: 90,
                    child: Center(
                      child: Text(o, style: const TextStyle(fontFamily: 'Baloo', fontSize: 52, color: _ink, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// اقرأ الساعة: ساعة بعقارب، والطفل يختار الوقت الصحيح.
class ClockGameScreen extends StatefulWidget {
  final int band;
  final Random? random;
  const ClockGameScreen({super.key, required this.band, this.random});

  @override
  State<ClockGameScreen> createState() => _ClockGameScreenState();
}

class _ClockGameScreenState extends State<ClockGameScreen> with _Rounds {
  late final rounds = clockRounds(widget.band, random: widget.random);
  @override
  int get total => rounds.length;
  @override
  String get doneId => 'clock';
  @override
  String get doneTitle => 'صرت تعرف تقرأ الساعة!';

  @override
  Widget build(BuildContext context) {
    final r = rounds[i];
    return ChildShell(
      theme: SceneTheme.learn,
      child: Column(children: [
        KidBar(title: 'اقرأ الساعة ${i + 1} / $total'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('كم الساعة؟', textAlign: TextAlign.center, style: RT.display(22, color: RC.onDark)),
            const SizedBox(height: 6),
            Text('العقرب القصير للساعات، والطويل للدقائق',
                textAlign: TextAlign.center, style: RT.body(15, color: RC.onDarkSoft)),
            const SizedBox(height: 14),
            Center(
              child: Semantics(
                label: 'ساعة',
                child: SizedBox(width: 250, height: 250, child: CustomPaint(painter: ClockPainter(r.hour, r.minute))),
              ),
            ),
            const SizedBox(height: 20),
            for (final o in r.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Chunky(
                  key: ValueKey('clk_${i}_${o.$1}_${o.$2}'),
                  color: wrong == o ? _wrongBg : Colors.white,
                  radius: 18,
                  depth: 4,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  onTap: () => answer(o, (r.hour, r.minute), say: clockLabel(r.hour, r.minute)),
                  child: Center(child: Text(clockLabel(o.$1, o.$2), style: RT.display(20))),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  ClockPainter(this.hour, this.minute);

  static const _digits = ['١٢', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '١٠', '١١'];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rad = size.shortestSide / 2;
    canvas.drawCircle(c, rad, Paint()..color = _paper);
    canvas.drawCircle(c, rad - 4, Paint()
      ..color = const Color(0xFFD9BE8C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8);
    for (var k = 0; k < 60; k++) {
      final a = k * pi / 30 - pi / 2;
      final long = k % 5 == 0;
      final p1 = c + Offset(cos(a), sin(a)) * (rad - 14);
      final p2 = c + Offset(cos(a), sin(a)) * (rad - (long ? 26 : 20));
      canvas.drawLine(p1, p2, Paint()
        ..color = _ink.withValues(alpha: long ? 0.7 : 0.25)
        ..strokeWidth = long ? 3 : 1.5);
    }
    for (var k = 0; k < 12; k++) {
      final a = k * pi / 6 - pi / 2;
      final tp = TextPainter(
        text: TextSpan(text: _digits[k], style: const TextStyle(fontFamily: 'Baloo', fontSize: 22, color: _ink, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, c + Offset(cos(a), sin(a)) * (rad - 46) - Offset(tp.width / 2, tp.height / 2));
    }
    void hand(double angle, double len, double w, Color col) {
      final a = angle - pi / 2;
      canvas.drawLine(c, c + Offset(cos(a), sin(a)) * len, Paint()
        ..color = col
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
    }

    hand(((hour % 12) + minute / 60) * pi / 6, rad * 0.48, 9, _ink);
    hand(minute * pi / 30, rad * 0.72, 5, const Color(0xFFC98A12));
    canvas.drawCircle(c, 8, Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(ClockPainter old) => old.hour != hour || old.minute != minute;
}
