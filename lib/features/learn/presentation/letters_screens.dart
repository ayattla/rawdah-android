import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/learn/domain/letters.dart';

/// لون الحبر لهيكل الحرف، والذهبي للنقاط: النقطة هي ما يفرق حروف العائلة.
const _ink = Color(0xFF1F2A44);
const _dotGold = Color(0xFFC98A12);
const _paper = Color(0xFFFFFBF0);

/// مسار الحروف: عائلات الرسم، كل عائلة صف واحد.
class LettersPathScreen extends StatelessWidget {
  const LettersPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final done = kLetters.where((l) => c.completed.contains(l.id)).length;
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'حروفي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            _PathHeader(done: done, total: kLetters.length),
            for (final f in kLetterFamilies) ...[
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 8, right: 4),
                child: Text(f.title, style: RT.display(17, color: RC.inkSoft)),
              ),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final l in f.letters)
                  _LetterStone(
                    letter: l,
                    done: c.completed.contains(l.id),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => LetterLessonScreen(letter: l, family: f))),
                  ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _PathHeader extends StatelessWidget {
  final int done;
  final int total;
  const _PathHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تعلمت $done من $total حرف', style: RT.display(20, color: Colors.white)),
            const SizedBox(height: 4),
            Text('حروف العائلة الواحدة شكلها واحد، والنقاط تفرق بينها',
                style: RT.body(14, color: Colors.white70)),
          ]),
        ),
        SizedBox(
          width: 58,
          height: 58,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: total == 0 ? 0 : done / total,
              strokeWidth: 6,
              color: _dotGold,
              backgroundColor: Colors.white24,
            ),
            Text('${(done * 100 / max(total, 1)).round()}٪', style: RT.display(13, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}

class _LetterStone extends StatelessWidget {
  final ArabicLetter letter;
  final bool done;
  final VoidCallback onTap;
  const _LetterStone({required this.letter, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'حرف ${letter.name}${done ? '، تعلمته' : ''}',
      excludeSemantics: true,
      child: Chunky(
        color: done ? const Color(0xFFFFF3D6) : _paper,
        radius: 18,
        depth: 4,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 84,
          child: Stack(children: [
            Center(child: _DottedLetter(letter: letter, size: 46)),
            if (done)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.check_circle_rounded, size: 18, color: _dotGold),
              ),
          ]),
        ),
      ),
    );
  }
}

/// الحرف بالحبر، وتحته «مفتاح النقاط»: خط صغير والنقاط الذهبية فوقه أو تحته بعددها،
/// فيرى الطفل بعينه ما يفرق الحرف عن إخوته.
class _DottedLetter extends StatelessWidget {
  final ArabicLetter letter;
  final double size;
  const _DottedLetter({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(letter.char,
          style: TextStyle(fontFamily: 'Baloo', fontSize: size, height: 1.15, fontWeight: FontWeight.w700, color: _ink)),
      CustomPaint(size: Size(size * 0.5, size * 0.22), painter: _DotKeyPainter(letter.dots)),
    ]);
  }
}

class _DotKeyPainter extends CustomPainter {
  final int dots;
  _DotKeyPainter(this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final line = Paint()
      ..color = _ink.withValues(alpha: 0.25)
      ..strokeWidth = max(1.5, size.height * 0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.1, mid), Offset(size.width * 0.9, mid), line);
    final n = dots.abs();
    if (n == 0) return;
    final r = size.height * 0.16;
    final y = dots > 0 ? mid - r * 2.1 : mid + r * 2.1;
    final gold = Paint()..color = _dotGold;
    final gap = r * 2.6;
    final start = size.width / 2 - gap * (n - 1) / 2;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(start + gap * i, y), r, gold);
    }
  }

  @override
  bool shouldRepaint(_DotKeyPainter old) => old.dots != dots;
}

/// درس الحرف في أربع خطوات: أتعرف، أشكاله، في كلمات، أرسمه وأختبر نفسي.
class LetterLessonScreen extends StatefulWidget {
  final ArabicLetter letter;
  final LetterFamily family;
  const LetterLessonScreen({super.key, required this.letter, required this.family});

  @override
  State<LetterLessonScreen> createState() => _LetterLessonScreenState();
}

class _LetterLessonScreenState extends State<LetterLessonScreen> {
  final _pages = PageController();
  int _page = 0;
  static const _steps = ['أتعرف', 'أشكاله', 'في كلمات', 'أرسمه', 'أختبر'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.instance.say('هذا حرف ${widget.letter.name}'));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(i,
      duration: A11y.reduceMotionOf(context) ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic);

  Future<void> _finish(int right, int total) async {
    final st = AppScope.read(context);
    final stars = right == total ? 3 : (right >= total - 1 ? 2 : 1);
    final first = st.complete(widget.letter.id, stars: stars);
    await showReward(context, stars: first ? stars : 0, title: 'أحسنت! تعلمت حرف ${widget.letter.name}');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.letter;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'حرف ${l.name}'),
        _StepRail(steps: _steps, current: _page, onTap: _go),
        Expanded(
          child: PageView(
            controller: _pages,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _MeetStep(letter: l, family: widget.family),
              _FormsStep(letter: l),
              _WordsStep(letter: l),
              _TraceStep(letter: l, onDone: () => _go(4)),
              _PickStep(letter: l, onFinish: _finish),
            ],
          ),
        ),
        if (_page < 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: PrimaryButton(label: 'التالي', icon: Icons.arrow_forward_rounded, onTap: () => _go(_page + 1)),
          ),
      ]),
    );
  }
}

class _StepRail extends StatelessWidget {
  final List<String> steps;
  final int current;
  final ValueChanged<int> onTap;
  const _StepRail({required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == current;
          final past = i < current;
          return GestureDetector(
            onTap: past ? () => onTap(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _ink : (past ? const Color(0xFFFFF3D6) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? _ink : RC.sandDark),
              ),
              child: Text(steps[i],
                  style: RT.display(14, color: active ? Colors.white : (past ? _dotGold : RC.inkSoft))),
            ),
          );
        },
      ),
    );
  }
}

class _MeetStep extends StatelessWidget {
  final ArabicLetter letter;
  final LetterFamily family;
  const _MeetStep({required this.letter, required this.family});

  @override
  Widget build(BuildContext context) {
    final siblings = family.letters.where((x) => x != letter).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      GestureDetector(
        onTap: () => Voice.instance.say('حرف ${letter.name}'),
        child: Container(
          height: 230,
          decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(32), border: Border.all(color: RC.sandDark, width: 2)),
          child: Center(child: _DottedLetter(letter: letter, size: 150)),
        ),
      ),
      const SizedBox(height: 14),
      Text('حرف ${letter.name}', textAlign: TextAlign.center, style: RT.display(28)),
      const SizedBox(height: 6),
      Text(_dotsSentence(letter), textAlign: TextAlign.center, style: RT.body(18, color: RC.inkSoft)),
      if (siblings.isNotEmpty) ...[
        const SizedBox(height: 22),
        Text('إخوته في العائلة', textAlign: TextAlign.center, style: RT.display(17, color: RC.inkSoft)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final s in siblings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(children: [
                _DottedLetter(letter: s, size: 54),
                Text(_dotsShort(s), style: RT.body(13, color: RC.inkSoft)),
              ]),
            ),
        ]),
      ],
      const SizedBox(height: 10),
      Center(
        child: TextButton.icon(
          onPressed: () => Voice.instance.say('حرف ${letter.name}'),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('اسمعه'),
        ),
      ),
    ]);
  }
}

String _dotsShort(ArabicLetter l) {
  final n = l.dots.abs();
  if (n == 0) return 'بلا نقاط';
  final where = l.dots > 0 ? 'فوق' : 'تحت';
  return switch (n) { 1 => 'نقطة $where', 2 => 'نقطتان $where', _ => 'ثلاث $where' };
}

String _dotsSentence(ArabicLetter l) {
  if (l.dots == 0) return 'حرف ${l.name} ليس عليه نقاط';
  return 'حرف ${l.name} له ${_dotsShort(l)}';
}

class _FormsStep extends StatelessWidget {
  final ArabicLetter letter;
  const _FormsStep({required this.letter});

  @override
  Widget build(BuildContext context) {
    final forms = [
      ('في أول الكلمة', letter.initial),
      ('في وسط الكلمة', letter.medial),
      ('في آخر الكلمة', letter.finalForm),
      ('وحده', letter.isolated),
    ];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('يتغير شكل الحرف حسب مكانه', textAlign: TextAlign.center, style: RT.display(20)),
      if (letter.nonJoining)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('وحرف ${letter.name} لا يتصل بالحرف الذي بعده',
              textAlign: TextAlign.center, style: RT.body(16, color: _dotGold, weight: FontWeight.w700)),
        ),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: [
          for (final f in forms)
            Container(
              decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: RC.sandDark, width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(f.$2, style: const TextStyle(fontFamily: 'Baloo', fontSize: 64, color: _ink, fontWeight: FontWeight.w700, height: 1.2)),
                Text(f.$1, style: RT.body(15, color: RC.inkSoft)),
              ]),
            ),
        ],
      ),
    ]);
  }
}

class _WordsStep extends StatelessWidget {
  final ArabicLetter letter;
  const _WordsStep({required this.letter});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('ابحث عن الحرف الذهبي', textAlign: TextAlign.center, style: RT.display(20)),
      const SizedBox(height: 16),
      for (final w in letter.words)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Chunky(
            color: Colors.white,
            radius: 24,
            depth: 4,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            onTap: () => Voice.instance.say(w),
            child: Row(children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    for (final part in splitForHighlight(w, letter.char))
                      TextSpan(text: part.$1, style: TextStyle(color: part.$2 ? _dotGold : _ink)),
                  ]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Baloo', fontSize: 52, fontWeight: FontWeight.w700, height: 1.3),
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: RC.inkSoft),
            ]),
          ),
        ),
    ]);
  }
}

/// لوح الرسم: الحرف باهت في الخلفية، والطفل يمر عليه بإصبعه.
class _TraceStep extends StatefulWidget {
  final ArabicLetter letter;
  final VoidCallback onDone;
  const _TraceStep({required this.letter, required this.onDone});

  @override
  State<_TraceStep> createState() => _TraceStepState();
}

class _TraceStepState extends State<_TraceStep> {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  double get _inkLength {
    var total = 0.0;
    for (final s in _strokes) {
      for (var i = 1; i < s.length; i++) {
        total += (s[i] - s[i - 1]).distance;
      }
    }
    return total;
  }

  /// يكفي أن يرسم طولا معقولا يغطي مساحة الحرف.
  bool get _enough {
    if (_size == Size.zero || _strokes.isEmpty) return false;
    final pts = _strokes.expand((s) => s).toList();
    final xs = pts.map((p) => p.dx), ys = pts.map((p) => p.dy);
    final w = xs.reduce(max) - xs.reduce(min), h = ys.reduce(max) - ys.reduce(min);
    return _inkLength > _size.shortestSide * 0.9 && (w > _size.width * 0.25 || h > _size.height * 0.25);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('مر بإصبعك على الحرف', style: RT.display(20)),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            _size = Size(box.maxWidth, box.maxHeight);
            return GestureDetector(
              onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
              onPanUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
              child: Container(
                decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(32), border: Border.all(color: RC.sandDark, width: 2)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(fit: StackFit.expand, children: [
                    Center(
                      child: Text(widget.letter.char,
                          style: TextStyle(
                              fontFamily: 'Baloo',
                              fontSize: box.maxHeight * 0.62,
                              color: _ink.withValues(alpha: 0.13),
                              fontWeight: FontWeight.w700)),
                    ),
                    CustomPaint(painter: _InkPainter(_strokes)),
                  ]),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(RS.minTouch)),
              onPressed: _strokes.isEmpty ? null : () => setState(_strokes.clear),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('امسح'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: _enough ? 'رسمته!' : 'ارسم الحرف',
              icon: Icons.check_rounded,
              color: _enough ? RC.green : RC.sandDark,
              onTap: _enough ? widget.onDone : null,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _InkPainter(this.strokes);

  static final _paint = Paint()
    ..color = _dotGold
    ..strokeWidth = 16
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s, _paint);
        continue;
      }
      final p = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, _paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => true;
}

/// أربع جولات: «أين حرف كذا؟» بين إخوته وحروف أخرى.
class _PickStep extends StatefulWidget {
  final ArabicLetter letter;
  final Future<void> Function(int right, int total) onFinish;
  const _PickStep({required this.letter, required this.onFinish});

  @override
  State<_PickStep> createState() => _PickStepState();
}

class _PickStepState extends State<_PickStep> {
  static const _rounds = 4;
  final _r = Random();
  int _round = 0, _right = 0;
  int? _wrong;
  late List<ArabicLetter> _options = _make();

  List<ArabicLetter> _make() {
    final fam = kLetterFamilies.firstWhere((f) => f.letters.contains(widget.letter)).letters;
    final pool = <ArabicLetter>{widget.letter, ...fam};
    while (pool.length < 4) {
      pool.add(kLetters[_r.nextInt(kLetters.length)]);
    }
    return pool.take(4).toList()..shuffle(_r);
  }

  Future<void> _tap(ArabicLetter l) async {
    if (l == widget.letter) {
      if (_wrong == null) _right++;
      Haptics.success();
      Voice.instance.say('صح');
      if (_round + 1 >= _rounds) {
        await widget.onFinish(_right, _rounds);
        return;
      }
      setState(() {
        _round++;
        _wrong = null;
        _options = _make();
      });
    } else {
      Haptics.error();
      setState(() => _wrong = kLetters.indexOf(l));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('أين حرف ${widget.letter.name}؟', style: RT.display(24)),
        Text('الجولة ${_round + 1} من $_rounds', style: RT.body(15, color: RC.inkSoft)),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: [
              for (final o in _options)
                Chunky(
                  color: _wrong == kLetters.indexOf(o) ? const Color(0xFFFDE2E0) : Colors.white,
                  radius: 26,
                  depth: 5,
                  padding: EdgeInsets.zero,
                  onTap: () => _tap(o),
                  child: Center(
                    child: Semantics(
                      label: 'حرف ${o.name}',
                      child: Text(o.char,
                          style: const TextStyle(fontFamily: 'Baloo', fontSize: 80, color: _ink, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Voice.instance.say('أين حرف ${widget.letter.name}'),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('اسمع السؤال'),
        ),
      ]),
    );
  }
}
