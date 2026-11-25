import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rawdah/core/design_system/quran_text.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/competition/presentation/competition_screen.dart';
import 'package:rawdah/features/quizzes/presentation/family_quiz_screen.dart';
import 'package:rawdah/features/games/presentation/games_hub_screen.dart';
import 'package:rawdah/features/garden/presentation/garden_screen.dart';
import 'package:rawdah/features/journeys/presentation/journeys_screen.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/ramadan/presentation/ramadan_screen.dart';
import 'package:rawdah/features/school/presentation/school_screen.dart';
import 'package:rawdah/features/science/presentation/science_screens.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';

class _Place {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _Place(this.title, this.hint, this.icon, this.color, this.builder);
}

/// الصفحة الرئيسية: «صحن الروضة».
/// في الأعلى قوس كمحراب يطل على سماء المغرب وفانوس الطفل، وتحته بلاطات الأقسام.
class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  static final _journeys =
      _Place('رحلاتي', 'محطات تصل بك إلى الشهادة', Icons.route_rounded, RC.ink, (_) => const JourneysScreen());

  static final List<_Place> _places = [
    _Place('بيت القصص', 'قصص نتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen()),
    _Place('المدرسة', 'قرآن وأذكار ودروس', Icons.school_rounded, RC.sea, (_) => const SchoolScreen()),
    _Place('المسابقات', 'أجب واجمع النجوم', Icons.emoji_events_rounded, RC.goldDark, (_) => const QuizHubScreen()),
    _Place('عالم العلوم', 'الفضاء والماء والنبات', Icons.science_rounded, RC.night, (_) => const ScienceHubScreen()),
    _Place('ساحة الألعاب', 'نلعب ونتعلم', Icons.extension_rounded, RC.plum, (_) => const GamesHubScreen()),
    _Place('ميدان المنافسة', 'نافس واصعد الهرم', Icons.leaderboard_rounded, RC.green, (_) => const CompetitionScreen()),
    _Place('حديقتي', 'نخلتي وعادات الخير', Icons.park_rounded, RC.garden, (_) => const GardenScreen()),
    _Place('رمضان', 'فانوس لكل يوم', Icons.nightlight_round, RC.night, (_) => const RamadanScreen()),
    _Place('مجلس العائلة', 'مسابقة مع أهلي', Icons.chair_rounded, RC.rose, (_) => const FamilyQuizScreen()),
  ];

  void _open(BuildContext context, _Place p) {
    Voice.instance.say(p.title);
    Navigator.of(context).push(MaterialPageRoute(builder: p.builder));
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const Scaffold(body: SizedBox());
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) st.leaveChild();
      },
      child: ChildShell(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _TopBar(child: c)),
          SliverToBoxAdapter(child: _ArchHeader(child: c)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(child: _HeroTile(place: _journeys, onTap: () => _open(context, _journeys))),
          ),
          if (c.onlineEnabled && c.circleCode.isNotEmpty) SliverToBoxAdapter(child: _CircleChip(child: c)),
          const SliverToBoxAdapter(child: _MissionsCard()),
          if (st.hifzDue().isNotEmpty) SliverToBoxAdapter(child: _ReviewBanner(count: st.hifzDue().length)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverGrid(
              // البلاطة تطول مع تكبير الخط حتى لا يُقص العنوان
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.02 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: _places.length,
                (context, i) => _PlaceTile(place: _places[i], onTap: () => _open(context, _places[i])),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _HadithCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ الشريط العلوي

class _TopBar extends StatelessWidget {
  final ChildProfile child;
  const _TopBar({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(children: [
          RoundIcon(
            icon: Icons.swap_horiz_rounded,
            color: RC.ink,
            size: 48,
            tooltip: 'تبديل الطفل',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السلام عليكم', style: RT.body(14, color: RC.inkSoft)),
              Text(child.name, style: RT.display(26), overflow: TextOverflow.ellipsis),
            ]),
          ),
          StarCount(stars: child.stars),
        ]),
      );
}

// ------------------------------------------------------------------ القوس

class _ArchHeader extends StatelessWidget {
  final ChildProfile child;
  const _ArchHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = child;
    final glow = (c.streak / 7).clamp(0.25, 1.0).toDouble();
    final lvl = c.level;
    final from = ChildProfile.levelStart(lvl);
    final to = ChildProfile.levelStart(lvl + 1);
    final progress = lvl >= 50 ? 1.0 : ((c.stars - from) / (to - from)).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: LayoutBuilder(builder: (context, box) {
          return Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _ArchPainter())),
            // الفانوس معلّق من قمة القوس
            Positioned(
              top: box.maxHeight * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Column(children: [
                  _SwayingLantern(
                    chain: box.maxHeight * 0.08,
                    child: Lantern(size: box.maxHeight * 0.42, glow: glow),
                  ),
                ]),
              ),
            ),
            // المستوى والأيام المتتالية على عتبة القوس
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(children: [
                _LevelRing(level: lvl, progress: progress),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.streak > 1 ? 'فانوسك مضيء منذ ${c.streak} أيام' : 'تعال كل يوم ليزداد فانوسك نورًا',
                    style: RT.display(16, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

class _LevelRing extends StatelessWidget {
  final int level;
  final double progress;
  const _LevelRing({required this.level, required this.progress});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'المستوى $level',
        child: SizedBox(
          width: 58,
          height: 58,
          child: Stack(alignment: Alignment.center, children: [
            const KhatamBadge(icon: Icons.circle, color: RC.gold, size: 58, iconColor: Colors.transparent),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                color: RC.ink,
                backgroundColor: Colors.white54,
              ),
            ),
            Text('$level', style: RT.display(18, color: RC.ink)),
          ]),
        ),
      );
}

/// قوس مدبب كمحراب: إطار فيروزي مزخرف، وفي داخله سماء المغرب وقبة ومئذنتان.
class _ArchPainter extends CustomPainter {
  Path _arch(Size s, double inset) {
    final w = s.width, h = s.height;
    final l = inset, r = w - inset, b = h - inset * 0.4;
    final spring = h * 0.42 + inset * 0.3; // بداية انحناء القوس
    final apex = inset * 0.9;
    return Path()
      ..moveTo(l, b)
      ..lineTo(l, spring)
      ..cubicTo(l, spring - h * 0.2, w / 2 - w * 0.12, apex + h * 0.06, w / 2, apex)
      ..cubicTo(w / 2 + w * 0.12, apex + h * 0.06, r, spring - h * 0.2, r, spring)
      ..lineTo(r, b)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _arch(size, 0);
    final inner = _arch(size, 12);
    // الإطار
    canvas.drawPath(outer, Paint()..color = RC.green);
    canvas.save();
    canvas.clipPath(outer);
    ZellijPainter(color: Colors.white.withValues(alpha: 0.22), cell: 26).paint(canvas, size);
    canvas.restore();
    // السماء
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D2B64), Color(0xFF6A5AE0), Color(0xFFF59E5B)],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect));
    // نجوم وهلال
    final r = math.Random(3);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.45),
          r.nextDouble() * 1.4 + 0.5, star);
    }
    final moon = Offset(size.width * 0.27, size.height * 0.3);
    canvas.drawCircle(moon, size.height * 0.07, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(moon + Offset(size.height * 0.03, -size.height * 0.018), size.height * 0.062,
        Paint()..color = const Color(0xFF3B3E9A));
    // قبة ومئذنتان على الأفق
    final sil = Paint()..color = const Color(0xFF14204F);
    final w = size.width, h = size.height;
    final base = h * 0.86;
    final dome = Path()
      ..moveTo(w * 0.6, base)
      ..lineTo(w * 0.6, h * 0.72)
      ..cubicTo(w * 0.6, h * 0.6, w * 0.7, h * 0.56, w * 0.71, h * 0.52)
      ..cubicTo(w * 0.72, h * 0.56, w * 0.82, h * 0.6, w * 0.82, h * 0.72)
      ..lineTo(w * 0.82, base)
      ..close();
    canvas.drawPath(dome, sil);
    canvas.drawRect(Rect.fromLTWH(w * 0.705, h * 0.47, w * 0.01, h * 0.06), sil);
    for (final x in [0.55, 0.87]) {
      canvas.drawRect(Rect.fromLTWH(w * x - w * 0.012, h * 0.55, w * 0.024, base - h * 0.55), sil);
      canvas.drawPath(
          Path()
            ..moveTo(w * x - w * 0.016, h * 0.55)
            ..lineTo(w * x, h * 0.48)
            ..lineTo(w * x + w * 0.016, h * 0.55)
            ..close(),
          sil);
    }
    canvas.drawRect(Rect.fromLTWH(0, base, w, h - base), sil);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ------------------------------------------------------------------ البلاطات

/// بلاطة «رحلاتي» العريضة: لازوردية بنقش زليج ذهبي.
class _HeroTile extends StatelessWidget {
  final _Place place;
  final VoidCallback onTap;
  const _HeroTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) => Chunky(
        color: place.color,
        radius: 26,
        depth: 6,
        onTap: onTap,
        semanticLabel: '${place.title}، ${place.hint}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: CustomPaint(
            painter: ZellijPainter(
                color: RC.gold.withValues(alpha: A11y.highContrastOf(context) ? 0 : 0.22), cell: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                KhatamBadge(icon: place.icon, color: RC.gold, size: 72, iconColor: RC.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place.title, style: RT.display(28, color: Colors.white)),
                    Text(place.hint, style: RT.body(16, color: Colors.white)),
                  ]),
                ),
                const Icon(Icons.chevron_left_rounded, color: RC.gold, size: 36),
              ]),
            ),
          ),
        ),
      );
}

class _PlaceTile extends StatelessWidget {
  final _Place place;
  final VoidCallback onTap;
  const _PlaceTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) => Chunky(
        color: place.color,
        radius: 24,
        depth: 6,
        onTap: onTap,
        semanticLabel: '${place.title}، ${place.hint}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [
            // نجمة كبيرة مقصوصة في الزاوية: توقيع البلاطة (تختفي في التباين العالي)
            if (!A11y.highContrastOf(context))
            PositionedDirectional(
              end: -34,
              top: -34,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _CornerStarPainter(Colors.white.withValues(alpha: 0.16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                KhatamBadge(icon: place.icon, color: Colors.white, size: 58, iconColor: place.color),
                const Spacer(),
                Text(place.title,
                    style: RT.display(21, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(place.hint,
                    style: RT.body(13.5, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
}

class _CornerStarPainter extends CustomPainter {
  final Color color;
  _CornerStarPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(khatamPath(c, size.width / 2), Paint()..color = color);
    canvas.drawPath(
        khatamPath(c, size.width * 0.3, rotation: math.pi / 8),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _CornerStarPainter old) => old.color != color;
}

// ------------------------------------------------------------------ البطاقات

class _CircleChip extends StatelessWidget {
  final ChildProfile child;
  const _CircleChip({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Chunky(
          color: Colors.white,
          edge: RC.sandDark,
          border: Border.all(color: RC.sandDark, width: 2),
          depth: 4,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompetitionScreen())),
          child: Row(children: [
            const KhatamBadge(icon: Icons.groups_2_rounded, color: RC.green, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text('حلقتي: ${child.circleName}', overflow: TextOverflow.ellipsis, style: RT.display(18)),
            ),
            Text('${child.circlePoints + child.pendingPoints} نقطة', style: RT.display(17, color: RC.coral)),
          ]),
        ),
      );
}

class _MissionsCard extends StatelessWidget {
  const _MissionsCard();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    c.rollDay();
    final claimed = c.completed.contains('missions_${todayKey()}');
    final items = [
      (Icons.check_circle_outline_rounded, '5 إجابات صحيحة', (c.correctToday / 5).clamp(0.0, 1.0).toDouble()),
      (Icons.menu_book_rounded, 'قصة أو درس أو سورة', c.learnToday >= 1 ? 1.0 : 0.0),
      (Icons.extension_rounded, 'لعبة واحدة', c.gamesToday >= 1 ? 1.0 : 0.0),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RC.sandDark, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('مهام اليوم', style: RT.display(20))),
          if (claimed)
            Text('أنجزتها، بارك الله فيك', style: RT.display(15, color: RC.green, weight: FontWeight.w700))
          else if (st.missionsDone)
            Chunky(
              color: RC.gold,
              radius: 14,
              depth: 4,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              onTap: () {
                if (st.claimMissions()) showReward(context, stars: 10, title: 'أنجزت مهام اليوم');
              },
              child: Text('استلم 10 نجوم', style: RT.display(16)),
            )
          else
            Row(children: [
              const Icon(Icons.star_rounded, color: RC.goldDark, size: 20),
              Text(' 10 عند الإتمام', style: RT.body(14, color: RC.inkSoft)),
            ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final m in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: m.$3,
                          strokeWidth: 5,
                          color: m.$3 >= 1 ? RC.green : RC.gold,
                          backgroundColor: RC.sandDark,
                        ),
                      ),
                      Icon(m.$3 >= 1 ? Icons.check_rounded : m.$1, color: m.$3 >= 1 ? RC.green : RC.ink, size: 24),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Text(m.$2, textAlign: TextAlign.center, style: RT.body(13, weight: FontWeight.w500)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// تنبيه لطيف بالسور المستحقة للمراجعة، يفتح أول سورة على وضع «أختبر حفظي».
class _ReviewBanner extends StatelessWidget {
  final int count;
  const _ReviewBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? 'عندك سورة وحدة للمراجعة اليوم' : 'عندك $count سور للمراجعة اليوم';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Chunky(
        color: RC.goldDark,
        radius: 20,
        depth: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () {
          final due = AppScope.read(context).hifzDue();
          if (due.isEmpty) return;
          final s = surahByNumber(due.first.surah);
          if (s == null) return;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => SurahScreen(surah: s, startInMemorize: true)));
        },
        child: Row(children: [
          const Icon(Icons.autorenew_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: RT.display(17, color: Colors.white))),
          const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ]),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
    final h = kDailyHadith[day % kDailyHadith.length];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(color: RC.ink, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('حديث اليوم', style: RT.display(15, color: RC.gold, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('قال رسول الله ﷺ: ${h.$1}', style: RT.display(19, color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(h.$2, style: RT.body(13, color: Colors.white70)),
          ]),
        ),
        IconButton(
          tooltip: 'استمع',
          icon: const Icon(Icons.volume_up_rounded, color: RC.gold, size: 30),
          onPressed: () => Voice.instance
              .say('قال رسول الله صلى الله عليه وسلم: ${h.$1.replaceAll('«', '').replaceAll('»', '')}'),
        ),
      ]),
    );
  }
}

/// الفانوس يتأرجح برفق من سلسلته: الحركة الوحيدة الدائمة في الرئيسية،
/// وتتوقف تمامًا عند تفعيل تقليل الحركة.
class _SwayingLantern extends StatefulWidget {
  final double chain;
  final Widget child;
  const _SwayingLantern({required this.chain, required this.child});

  @override
  State<_SwayingLantern> createState() => _SwayingLanternState();
}

class _SwayingLanternState extends State<_SwayingLantern> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (A11y.reduceMotionOf(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.rotate(
          angle: (Curves.easeInOut.transform(_c.value) - 0.5) * 0.09,
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: Column(children: [
          Container(width: 2, height: widget.chain, color: const Color(0xFF7A4E12)),
          widget.child,
        ]),
      );
}
