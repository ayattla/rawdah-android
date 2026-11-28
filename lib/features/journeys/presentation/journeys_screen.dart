import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/journeys/data/journeys_data.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/games/presentation/games_hub_screen.dart';
import 'package:rawdah/features/games/presentation/more_games_screen.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/school/presentation/school_screen.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';

/// المحطات المتاحة لفئة الطفل العمرية.
List<Station> stationsFor(Journey j, int band) => j.stations.where((s) {
      if (s.type == 'story') {
        final st = kStories.where((x) => x.id == s.ref);
        return st.isNotEmpty && st.first.minBand <= band;
      }
      if (s.type == 'lesson') {
        final l = kLessons.where((x) => x.id == s.ref);
        return l.isNotEmpty && l.first.minBand <= band;
      }
      return true;
    }).toList();

class JourneysScreen extends StatelessWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      theme: SceneTheme.journey,
      child: Column(children: [
        const KidBar(title: 'رحلاتي'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kJourneys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final j = kJourneys[i];
              final st = stationsFor(j, c.ageBand);
              final done = st.where((s) => c.completed.contains(s.doneId(j.id))).length;
              final ratio = st.isEmpty ? 0.0 : done / st.length;
              return Chunky(
                color: Colors.white,
                edge: j.color.withValues(alpha: 0.45),
                border: Border.all(color: j.color.withValues(alpha: 0.3), width: 2),
                padding: const EdgeInsets.all(14),
                semanticLabel: j.title,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JourneyMap(journey: j))),
                child: Row(children: [
                  KhatamBadge(
                    icon: ratio >= 1 ? Icons.workspace_premium_rounded : j.icon,
                    color: ratio >= 1 ? RC.gold : j.color,
                    iconColor: ratio >= 1 ? RC.ink : Colors.white,
                    size: 66,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(j.title, style: RT.display(21))),
                        Text('$done من ${st.length}', style: RT.display(15, color: j.color, weight: FontWeight.w700)),
                      ]),
                      Text(j.subtitle, style: RT.body(15, color: RC.inkSoft)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          color: j.color,
                          backgroundColor: j.color.withValues(alpha: 0.14),
                        ),
                      ),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class JourneyMap extends StatelessWidget {
  final Journey journey;
  const JourneyMap({super.key, required this.journey});

  Widget? _screenFor(Station s, int band) {
    switch (s.type) {
      case 'story':
        return StoryReader(story: kStories.firstWhere((x) => x.id == s.ref));
      case 'lesson':
        return LessonScreen(lesson: kLessons.firstWhere((x) => x.id == s.ref));
      case 'surah':
        final n = int.tryParse(s.ref) ?? 1;
        return SurahScreen(surah: kSurahs.firstWhere((x) => x.number == n, orElse: () => kSurahs.first));
      case 'adhkar':
        return const AdhkarScreen();
      case 'game':
        switch (s.ref) {
          case 'game_wudu':
            return const WuduOrderGame();
          case 'game_match':
            return const MatchGame();
          case 'game_mosque':
            return const MosqueBuilderGame();
          case 'game_memory':
            return const MemoryGame();
        }
        return null;
      case 'quiz':
        var qs = s.qids.map(questionById).whereType<Question>().where((q) => q.band <= band).toList();
        if (qs.length < 3) qs = s.qids.map(questionById).whereType<Question>().toList();
        return QuizRunner(title: s.title, questions: qs, completionId: s.doneId(journey.id));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final st = stationsFor(journey, c.ageBand);
    final doneFlags = st.map((s) => c.completed.contains(s.doneId(journey.id))).toList();
    final firstOpen = doneFlags.indexOf(false); // -1 = الرحلة مكتملة
    final allDone = firstOpen == -1;
    return ChildShell(
      theme: SceneTheme.journey,
      child: Column(children: [
        KidBar(title: journey.title),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: st.length + 1,
            itemBuilder: (context, i) {
              if (i == st.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: allDone
                      ? PrimaryButton(
                          label: 'شهادة الإتمام',
                          icon: Icons.workspace_premium_rounded,
                          color: RC.gold,
                          onTap: () {
                            // مكافأة إتمام الرحلة مرة واحدة
                            AppScope.read(context).complete('journey_${journey.id}', stars: 20);
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => CertificateScreen(journey: journey)));
                          },
                        )
                      : Center(
                          child: Text('أكمل المحطات لتنال شهادة الرحلة', style: RT.body(16, color: RC.onDarkSoft, weight: FontWeight.w600)),
                        ),
                );
              }
              final s = st[i];
              final done = doneFlags[i];
              final open = done || i == firstOpen;
              final current = i == firstOpen;
              return _StationRow(
                index: i,
                last: i == st.length - 1,
                title: s.title,
                kind: _kindName(s.type),
                icon: _iconFor(s.type),
                color: journey.color,
                done: done,
                open: open,
                current: current,
                onTap: () {
                  if (!open) {
                    Haptics.error();
                    Voice.instance.say('أكمل المحطة السابقة أولًا');
                    return;
                  }
                  final screen = _screenFor(s, c.ageBand);
                  if (screen != null) {
                    Navigator.of(context).push(WarpRoute<void>(builder: (_) => screen, title: s.title, color: journey.color, icon: _iconFor(s.type)));
                  }
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  String _kindName(String type) => switch (type) {
        'story' => 'قصة',
        'lesson' => 'درس',
        'surah' => 'سورة',
        'adhkar' => 'أذكار',
        'game' => 'لعبة',
        _ => 'مسابقة',
      };

  IconData _iconFor(String type) {
    switch (type) {
      case 'story':
        return Icons.auto_stories_rounded;
      case 'lesson':
        return Icons.lightbulb_rounded;
      case 'surah':
        return Icons.menu_book_rounded;
      case 'adhkar':
        return Icons.wb_twilight_rounded;
      case 'game':
        return Icons.extension_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

/// شهادة إتمام الرحلة: تصميم مزخرف بلا ذوات أرواح، يصوّرها الوالد من الشاشة.
class CertificateScreen extends StatelessWidget {
  final Journey journey;
  const CertificateScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: RC.sand,
      appBar: AppBar(backgroundColor: RC.sand, title: const Text('شهادة إتمام')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9B865), width: 6),
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: journey.color, width: 2),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const Lantern(size: 90, glow: 1),
                  const Text('شهادة إتمام', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: RC.greenDark)),
                  const Text('تُمنح هذه الشهادة إلى', style: TextStyle(fontSize: 18, color: RC.ink)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(symbolIcon(c.symbol), color: RC.gold, size: 34),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(c.name,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.coral)),
                    ),
                  ]),
                  Text('لإتمامه ${journey.title} بنجاح',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: RC.ink)),
                  Icon(journey.icon, color: journey.color, size: 48),
                  Text('${now.day}/${now.month}/${now.year}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const Text('تطبيق روضة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RC.green)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// محطة في الرحلة: قرص مجسم على طريق متعرج، ولوحة اسم واضحة بجانبه.
/// المكتملة ميدالية ذهبية بعلم، والحالية أكبر بهالة تنبض ولافتة «ابدأ من هنا»،
/// والمقفلة قرص بنفسجي بقفل واسمها مقروء.
class _StationRow extends StatefulWidget {
  final int index;
  final bool last;
  final String title;
  final String kind;
  final IconData icon;
  final Color color;
  final bool done, open, current;
  final VoidCallback onTap;
  const _StationRow({required this.index, required this.last, required this.title, required this.kind, required this.icon, required this.color, required this.done, required this.open, required this.current, required this.onTap});

  @override
  State<_StationRow> createState() => _StationRowState();
}

class _StationRowState extends State<_StationRow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  static const _ink = Color(0xFF2A1A66);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.current && !A11y.reduceMotionOf(context) && !LiveScene.inTest) {
      _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final right = w.index.isEven;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    final h = 132.0 * scale;
    final disc = w.current ? 86.0 : 72.0;
    final discColor = w.done ? const Color(0xFFFFC23F) : (w.open ? w.color : const Color(0xFF4B3B8F));
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final cx = right ? width * 0.72 : width * 0.28;
        final nx = right ? width * 0.28 : width * 0.72;
        return Stack(clipBehavior: Clip.none, children: [
          if (!w.last)
            Positioned.fill(child: CustomPaint(painter: _RoadPainter(Offset(cx, h * 0.42), Offset(nx, h * 1.42), w.done))),
          // القرص
          Positioned(
            left: cx - disc / 2 - 10,
            top: h * 0.42 - disc / 2 - 10,
            width: disc + 20,
            height: disc + 20,
            child: GestureDetector(
              onTapDown: (d) => WarpRoute.lastTap = d.globalPosition,
              onTap: w.onTap,
              child: Semantics(
                button: true,
                label: '${w.title}${w.done ? '، مكتملة' : (w.open ? '' : '، مقفلة')}',
                excludeSemantics: true,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => CustomPaint(painter: _HaloPainter(w.current ? _pulse.value : -1, w.color), child: child),
                  child: Center(
                    child: Container(
                      width: disc,
                      height: disc,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(center: const Alignment(-0.35, -0.4), colors: [Color.lerp(discColor, Colors.white, 0.35)!, discColor, Color.lerp(discColor, Colors.black, 0.25)!]),
                        border: Border.all(color: _ink, width: 3.5),
                        boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 5))],
                      ),
                      child: Icon(
                        w.done ? Icons.check_rounded : (w.open ? w.icon : Icons.lock_rounded),
                        color: w.done ? _ink : Colors.white.withValues(alpha: w.open ? 1 : 0.85),
                        size: disc * 0.46,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // علم صغير على المحطة المكتملة
          if (w.done)
            Positioned(
              left: cx + disc / 2 - 12,
              top: h * 0.42 - disc / 2 - 18,
              child: const Icon(Icons.flag_rounded, color: Color(0xFFFF5D8F), size: 26),
            ),
          // لوحة الاسم على الجانب الآخر
          Positioned(
            left: right ? 8 : null,
            right: right ? null : 8,
            top: h * 0.42 - 34,
            width: width * 0.44,
            child: GestureDetector(
              onTap: w.onTap,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  decoration: BoxDecoration(
                    color: w.open ? Colors.white : const Color(0xFF3A2C80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: w.current ? const Color(0xFFFFD43B) : _ink, width: w.current ? 3.5 : 2.5),
                    boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 4))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(w.kind, style: RT.body(12, color: w.open ? w.color : const Color(0xFFCFC6FF), weight: FontWeight.w700)),
                    Text(w.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: RT.display(15.5, color: w.open ? _ink : Colors.white)),
                    if (w.current)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFD43B), borderRadius: BorderRadius.circular(10)),
                        child: Text('ابدأ من هنا', style: RT.display(12.5, color: _ink)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final Offset a, b;
  final bool done;
  _RoadPainter(this.a, this.b, this.done);

  @override
  void paint(Canvas canvas, Size size) {
    final mid = (a.dy + b.dy) / 2;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, mid + 20, b.dx, mid - 20, b.dx, b.dy);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF2A1A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()
      ..color = done ? const Color(0xFFFFB020) : const Color(0xFF5A4AA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: done ? 0.9 : 0.45)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (var d = 10.0; d < m.length - 6; d += 16) {
        final p = m.getTangentForOffset(d)!.position, q = m.getTangentForOffset(d + 7)!.position;
        canvas.drawLine(p, q, dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter o) => o.a != a || o.b != b || o.done != done;
}

class _HaloPainter extends CustomPainter {
  final double t; // -1 بلا هالة
  final Color color;
  _HaloPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r * (0.85 + 0.15 * t), Paint()..color = const Color(0xFFFFD43B).withValues(alpha: 0.35 * (1 - t)));
    canvas.drawCircle(c, r * 0.92, Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _HaloPainter o) => o.t != t;
}
