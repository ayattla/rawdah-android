import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/quran_text.dart';
import '../ui/widgets.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final list = kStories.where((s) => s.minBand <= c.ageBand).toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'بيت القصص'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = list[i];
              return BigTile(
                title: s.title,
                subtitle: s.moral,
                icon: switch (s.scene) {
                  'night' => Icons.nightlight_round,
                  'desert' => Icons.wb_sunny_rounded,
                  'city' => Icons.mosque_rounded,
                  _ => Icons.local_florist_rounded,
                },
                color: switch (s.scene) {
                  'night' => RC.ink,
                  'desert' => RC.goldDark,
                  'city' => RC.sea,
                  _ => RC.green,
                },
                done: c.completed.contains(s.id),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryReader(story: s))),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class StoryReader extends StatefulWidget {
  final Story story;
  const StoryReader({super.key, required this.story});

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  final _pc = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read(0));
  }

  @override
  void dispose() {
    Voice.instance.stop();
    _pc.dispose();
    super.dispose();
  }

  void _read(int i) {
    final p = widget.story.pages[i];
    // الآيات لا تُقرأ بالصوت الآلي، نقرأ التمهيد فقط.
    Voice.instance.say(p.text);
  }

  Future<void> _finish() async {
    final st = AppScope.read(context);
    final first = st.complete(widget.story.id, stars: 3);
    if (first) await showReward(context, stars: 3, title: 'انتهت القصة');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final last = _page == s.pages.length - 1;
    return ChildShell(
      night: s.scene == 'night',
      child: Column(children: [
        KidBar(title: s.title),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: s.pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _read(i);
            },
            itemBuilder: (context, i) {
              final p = s.pages[i];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  StoryScene(scene: s.scene, page: i),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: s.scene == 'night' ? RC.gold : RC.sandDark, width: 3),
                    ),
                    child: Text(p.text,
                        textAlign: TextAlign.center,
                        style: RT.display(25, weight: FontWeight.w500).copyWith(height: 1.75)),
                  ),
                  if (p.passage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Builder(builder: (_) {
                      final r = resolvePassage(p.passage);
                      return QuranText(ayat: r.ayat, firstNumber: r.from);
                    }),
                    const SizedBox(height: 6),
                    Text(p.ayatRef, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                  ],
                  if (i == s.pages.length - 1) ...[
                    const SizedBox(height: 14),
                    Text('المصدر: ${s.source}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(children: [
            RoundIcon(icon: Icons.volume_up_rounded, color: RC.sea, onTap: () => _read(_page)),
            const SizedBox(width: 12),
            // نقاط الصفحات: نجمة لكل صفحة، تمتلئ حتى الصفحة الحالية
            Expanded(
              child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                for (var k = 0; k < s.pages.length; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: k == _page ? 22 : 14,
                    height: k == _page ? 22 : 14,
                    decoration: ShapeDecoration(
                      color: k <= _page ? RC.gold : (s.scene == 'night' ? Colors.white24 : RC.sandDark),
                      shape: const KhatamBorder(),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            last
                ? RoundIcon(icon: Icons.check_rounded, color: RC.green, onTap: _finish)
                : RoundIcon(
                    icon: Icons.arrow_forward_rounded,
                    color: RC.green,
                    onTap: () => _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                  ),
          ]),
        ),
      ]),
    );
  }
}

/// لوحة المشهد أعلى صفحة القصة: صحراء، ليل، بستان، أو مدينة. جمادات ونبات فقط.
class StoryScene extends StatelessWidget {
  final String scene;
  final int page;
  const StoryScene({super.key, required this.scene, this.page = 0});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(aspectRatio: 2.1, child: CustomPaint(painter: _ScenePainter(scene, page))),
      );
}

class _ScenePainter extends CustomPainter {
  final String scene;
  final int page;
  _ScenePainter(this.scene, this.page);

  void _palm(Canvas c, Offset base, double h, Color trunk, Color leaf) {
    final t = Paint()
      ..color = trunk
      ..strokeWidth = h * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final top = base + Offset(h * 0.12, -h);
    c.drawPath(Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx - h * 0.05, base.dy - h * 0.5, top.dx, top.dy), t);
    final l = Paint()
      ..color = leaf
      ..strokeWidth = h * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final a in [-2.7, -2.2, -1.6, -1.0, -0.45]) {
      final end = top + Offset(math.cos(a) * h * 0.42, math.sin(a) * h * 0.42 + h * 0.18);
      final mid = top + Offset(math.cos(a) * h * 0.25, math.sin(a) * h * 0.25 - h * 0.05);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy), l);
    }
  }

  void _domes(Canvas c, Size s, Color color, double baseY) {
    final p = Paint()..color = color;
    final w = s.width, h = s.height;
    void dome(double cx, double r) {
      c.drawRect(Rect.fromLTWH(cx - r, baseY - r * 0.9, r * 2, r * 0.9 + 2), p);
      c.drawPath(
          Path()
            ..moveTo(cx - r, baseY - r * 0.9)
            ..cubicTo(cx - r, baseY - r * 2.1, cx, baseY - r * 2.2, cx, baseY - r * 2.6)
            ..cubicTo(cx, baseY - r * 2.2, cx + r, baseY - r * 2.1, cx + r, baseY - r * 0.9)
            ..close(),
          p);
    }

    void minaret(double cx, double top) {
      c.drawRect(Rect.fromLTWH(cx - w * 0.012, top, w * 0.024, baseY - top), p);
      c.drawPath(
          Path()
            ..moveTo(cx - w * 0.018, top)
            ..lineTo(cx, top - h * 0.12)
            ..lineTo(cx + w * 0.018, top)
            ..close(),
          p);
    }

    dome(w * 0.5, h * 0.16);
    dome(w * 0.32, h * 0.1);
    dome(w * 0.68, h * 0.1);
    minaret(w * 0.18, h * 0.32);
    minaret(w * 0.82, h * 0.32);
    c.drawRect(Rect.fromLTWH(0, baseY, w, s.height - baseY), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final r = math.Random(scene.hashCode + page);
    switch (scene) {
      case 'night':
        canvas.drawRect(
            rect,
            Paint()
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF111A45), Color(0xFF3B3E9A)])
                  .createShader(rect));
        final star = Paint()..color = Colors.white.withValues(alpha: 0.9);
        for (var i = 0; i < 40; i++) {
          canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h * 0.7), r.nextDouble() * 1.5 + 0.4, star);
        }
        final m = Offset(w * 0.78, h * 0.3);
        canvas.drawCircle(m, h * 0.14, Paint()..color = const Color(0xFFFFE9A8));
        canvas.drawCircle(m + Offset(h * 0.06, -h * 0.03), h * 0.125, Paint()..color = const Color(0xFF1E2766));
        // جبل وغار
        final hill = Path()
          ..moveTo(0, h)
          ..lineTo(0, h * 0.7)
          ..quadraticBezierTo(w * 0.25, h * 0.35, w * 0.5, h * 0.62)
          ..quadraticBezierTo(w * 0.7, h * 0.8, w, h * 0.72)
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(hill, Paint()..color = const Color(0xFF0D1436));
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.26, h * 0.68), width: w * 0.08, height: h * 0.14),
            Paint()..color = const Color(0xFF05081C));
      case 'desert':
        canvas.drawRect(
            rect,
            Paint()
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE3A3), Color(0xFFFFF6E0)])
                  .createShader(rect));
        canvas.drawPath(khatamPath(Offset(w * 0.8, h * 0.28), h * 0.17), Paint()..color = RC.gold);
        canvas.drawCircle(Offset(w * 0.8, h * 0.28), h * 0.1, Paint()..color = const Color(0xFFFFD45E));
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.72)
              ..quadraticBezierTo(w * 0.3, h * 0.55, w * 0.6, h * 0.7)
              ..quadraticBezierTo(w * 0.85, h * 0.8, w, h * 0.66)
              ..lineTo(w, h)
              ..lineTo(0, h)
              ..close(),
            Paint()..color = const Color(0xFFE9B96E));
        _palm(canvas, Offset(w * 0.2, h * 0.8), h * 0.5, const Color(0xFF8A5A2B), const Color(0xFF3E9B4F));
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.88)
              ..quadraticBezierTo(w * 0.5, h * 0.74, w, h * 0.9)
              ..lineTo(w, h)
              ..lineTo(0, h)
              ..close(),
            Paint()..color = const Color(0xFFD99A4E));
      case 'city':
        canvas.drawRect(
            rect,
            Paint()
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBFE3FF), Color(0xFFEAF6FF)])
                  .createShader(rect));
        canvas.drawCircle(Offset(w * 0.15, h * 0.25), h * 0.09, Paint()..color = RC.gold);
        _domes(canvas, size, RC.green, h * 0.86);
        ZellijPainter(color: Colors.white.withValues(alpha: 0.18), cell: 22).paint(
            canvas, Size(w, h));
      default: // garden
        canvas.drawRect(rect, Paint()..color = const Color(0xFFDDF4EC));
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.75)
              ..quadraticBezierTo(w * 0.5, h * 0.55, w, h * 0.75)
              ..lineTo(w, h)
              ..lineTo(0, h)
              ..close(),
            Paint()..color = const Color(0xFF7CC68D));
        _palm(canvas, Offset(w * 0.15, h * 0.85), h * 0.6, const Color(0xFF8A5A2B), const Color(0xFF2F8A43));
        _palm(canvas, Offset(w * 0.82, h * 0.88), h * 0.5, const Color(0xFF8A5A2B), const Color(0xFF2F8A43));
        for (var i = 0; i < 9; i++) {
          final c = Offset(w * (0.3 + r.nextDouble() * 0.42), h * (0.78 + r.nextDouble() * 0.15));
          canvas.drawPath(khatamPath(c, h * 0.035),
              Paint()..color = [RC.coral, RC.gold, Colors.white, RC.plum][i % 4]);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.scene != scene || old.page != page;
}
