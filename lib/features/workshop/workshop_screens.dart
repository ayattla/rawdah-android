import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/science/presentation/science_screens.dart';
import 'package:rawdah/features/workshop/workshop_domain.dart';

const _outline = Color(0xFF2A1A66);
const _teal = Color(0xFF0F766E);

class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ورشة المخترع'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BigTile(
              title: 'مختبر الكهرباء',
              subtitle: 'المستوى ${st.counter('inv_circuit') + 1} • موصلات ودوائر',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => open(const CircuitLabScreen()),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: kMachinesTopic.title,
              subtitle: kMachinesTopic.subtitle,
              icon: kMachinesTopic.icon,
              color: kMachinesTopic.color,
              done: c.completed.contains(kMachinesTopic.completionId),
              onTap: () => open(const ScienceTopicScreen(topic: kMachinesTopic)),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'دفتر أفكاري',
              subtitle: 'تحدي اليوم: ${promptOfDay(DateTime.now())}',
              icon: Icons.draw_rounded,
              color: const Color(0xFFEC4899),
              done: c.completed.contains('sketch_${todayKey()}'),
              onTap: () => open(const SketchScreen()),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// مختبر الكهرباء: ٦ ألغاز في كل مستوى، والمستويات لا تنتهي.
class CircuitLabScreen extends StatefulWidget {
  final Random? random;
  const CircuitLabScreen({super.key, this.random});

  @override
  State<CircuitLabScreen> createState() => _CircuitLabScreenState();
}

class _CircuitLabScreenState extends State<CircuitLabScreen> {
  late final Random _r = widget.random ?? Random();
  static const _per = 6;
  late int _level;
  int _i = 0, _mistakes = 0;
  int? _wrong;
  bool _solved = false;
  WorkshopPuzzle? _p;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_p == null) {
      _level = AppScope.read(context).counter('inv_circuit') + 1;
      _p = circuitPuzzle(_level, _r);
    }
  }

  Future<void> _tap(int k) async {
    if (_solved) return;
    if (k != _p!.answer) {
      Haptics.error();
      setState(() {
        _wrong = k;
        _mistakes++;
      });
      return;
    }
    Haptics.success();
    AppScope.read(context).bump('tower');
    setState(() => _solved = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_i + 1 >= _per) {
      final st = AppScope.read(context);
      final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
      st.setCounter('inv_circuit', _level);
      st.complete('inv_circuit_$_level', stars: stars);
      await showReward(context, stars: stars, title: 'مهندس صغير! أنهيت المستوى $_level');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _solved = false;
      _wrong = null;
      _p = circuitPuzzle(_level, _r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _p!;
    return ChildShell(
      child: Column(children: [
        KidBar(title: 'مختبر الكهرباء • مستوى $_level'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Text('اللغز ${_i + 1} من $_per', textAlign: TextAlign.center, style: RT.body(14, color: RC.onDarkSoft)),
            const SizedBox(height: 10),
            Container(
              height: 120,
              decoration: BoxDecoration(color: const Color(0xFF1E1458), borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
              child: CustomPaint(painter: _CircuitArt(lit: _solved && p.answer == 0)),
            ),
            const SizedBox(height: 14),
            Text(p.prompt, textAlign: TextAlign.center, style: RT.display(21, color: RC.onDark)),
            const SizedBox(height: 6),
            Text(p.detail, textAlign: TextAlign.center, style: RT.display(18, color: _teal)),
            const SizedBox(height: 16),
            for (var k = 0; k < p.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Chunky(
                  key: ValueKey('c_${_i}_$k'),
                  color: _solved && k == p.answer ? const Color(0xFFD1FAE5) : (_wrong == k ? const Color(0xFFFDE2E0) : Colors.white),
                  border: Border.all(color: _outline, width: 3),
                  radius: 18,
                  depth: 5,
                  padding: const EdgeInsets.all(14),
                  onTap: () => _tap(k),
                  child: Center(child: Text(p.options[k], style: RT.display(18))),
                ),
              ),
            if (_solved) Text(p.why, textAlign: TextAlign.center, style: RT.body(16, color: RC.inkSoft)),
          ]),
        ),
      ]),
    );
  }
}

/// رسم دائرة بسيطة: بطارية وأسلاك ومصباح يضيء عند الحل.
class _CircuitArt extends CustomPainter {
  final bool lit;
  _CircuitArt({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final wire = Paint()
      ..color = const Color(0xFFFFC23F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final rect = Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), wire);
    // بطارية
    final bat = Rect.fromCenter(center: Offset(rect.left, rect.center.dy), width: 22, height: 40);
    canvas.drawRRect(RRect.fromRectAndRadius(bat, const Radius.circular(5)), Paint()..color = const Color(0xFF22C55E));
    canvas.drawRect(Rect.fromCenter(center: Offset(rect.left, bat.top - 3), width: 10, height: 6), Paint()..color = Colors.white70);
    // مصباح
    final bulb = Offset(rect.right, rect.center.dy);
    if (lit) canvas.drawCircle(bulb, 30, Paint()..color = const Color(0x66FFE680));
    canvas.drawCircle(bulb, 16, Paint()..color = lit ? const Color(0xFFFFE680) : const Color(0xFF6B6B8A));
    canvas.drawCircle(bulb, 16, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // خانة الفراغ
    final gap = Offset(rect.center.dx, rect.top);
    canvas.drawCircle(gap, 12, Paint()..color = const Color(0xFF1E1458));
    canvas.drawCircle(gap, 12, Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _CircuitArt old) => old.lit != lit;
}

/// دفتر أفكاري: يرسم الطفل اختراعه لتحدي اليوم بألوان وأحجام فرشاة.
class SketchScreen extends StatefulWidget {
  const SketchScreen({super.key});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _Stroke {
  final List<Offset> pts = [];
  final Color color;
  final double width;
  _Stroke(this.color, this.width);
}

class _SketchScreenState extends State<SketchScreen> {
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFF2563EB);
  double _width = 6;
  static const _palette = [Color(0xFF1F2A44), Color(0xFF2563EB), Color(0xFFEF4444), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFA855F7), Color(0xFFEC4899)];

  @override
  Widget build(BuildContext context) {
    final prompt = promptOfDay(DateTime.now());
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'دفتر أفكاري'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(prompt, textAlign: TextAlign.center, style: RT.display(18)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _outline, width: 3)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: GestureDetector(
                  onPanStart: (d) => setState(() => _strokes.add(_Stroke(_color, _width)..pts.add(d.localPosition))),
                  onPanUpdate: (d) => setState(() => _strokes.last.pts.add(d.localPosition)),
                  child: CustomPaint(painter: _SketchPainter(_strokes), size: Size.infinite),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
            for (final col in _palette)
              GestureDetector(
                onTap: () => setState(() => _color = col),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == col ? const Color(0xFFFFC23F) : _outline, width: _color == col ? 4 : 2),
                  ),
                ),
              ),
            for (final w in [4.0, 8.0, 14.0])
              IconButton(
                tooltip: 'حجم الفرشاة',
                onPressed: () => setState(() => _width = w),
                icon: Icon(Icons.circle, size: 10 + w, color: _width == w ? _outline : RC.inkSoft),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(RS.minTouch)),
                onPressed: _strokes.isEmpty ? null : () => setState(_strokes.removeLast),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('تراجع'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'أنهيت اختراعي',
                icon: Icons.check_rounded,
                color: _strokes.length >= 3 ? const Color(0xFFEC4899) : RC.sandDark,
                onTap: _strokes.length < 3
                    ? null
                    : () async {
                        final first = AppScope.read(context).complete('sketch_${todayKey()}', stars: 3);
                        Voice.instance.say('اختراع رائع! اعرضه على أهلك');
                        await showReward(context, stars: first ? 3 : 0, title: 'اختراع رائع! اعرضه على أهلك');
                        if (context.mounted) Navigator.of(context).pop();
                      },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _SketchPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.pts.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.pts, p);
      } else {
        final path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
        for (final o in s.pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter old) => true;
}
