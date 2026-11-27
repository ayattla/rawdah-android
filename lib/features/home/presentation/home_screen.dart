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
import 'package:rawdah/features/science/data/science_content.dart';
import 'package:rawdah/features/learn/presentation/words_numbers_screens.dart';
import 'package:rawdah/features/islamic/presentation/islamic_screens.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';
import 'package:rawdah/features/planets/presentation/planets_screen.dart';
import 'package:rawdah/features/tower/presentation/tower_screens.dart';
import 'package:rawdah/features/episodes/episodes.dart';
import 'package:rawdah/features/shop/shop.dart';
import 'package:rawdah/features/family/family_league.dart';
import 'package:rawdah/features/health/health_screen.dart';
import 'package:rawdah/features/choices/choices_screen.dart';
import 'package:rawdah/features/ladder/ladder.dart';
import 'package:rawdah/features/badges/badges.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';
import 'package:rawdah/features/workshop/workshop_screens.dart';
import 'package:rawdah/features/daily/presentation/daily_screen.dart';
import 'package:rawdah/features/daily/domain/quests.dart';
import 'package:rawdah/features/quizzes/domain/mastery.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';

class _Place {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final SceneTheme theme;
  const _Place(this.title, this.hint, this.icon, this.color, this.builder, [this.theme = SceneTheme.play]);
}

/// الصفحة الرئيسية: «صحن الروضة».
/// في الأعلى قوس كمحراب يطل على سماء المغرب وفانوس الطفل، وتحته بلاطات الأقسام.
class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  static final _journeys =
      _Place('رحلاتي', 'محطات تصل بك إلى الشهادة', Icons.route_rounded, RC.ink, (_) => const JourneysScreen());

  /// الأقسام مجمعة حسب ما يريده الطفل: أول بلاطة في كل جناح عريضة، والباقي صغيرة.
  static List<_Place> get _allPlaces => [for (final w in _wings) ...w.$2];

  static final List<(String, List<_Place>)> _wings = [
    ('قرآني وديني', [
      _Place('المدرسة', 'قرآن وأذكار ودروس', Icons.school_rounded, RC.sea, (_) => const SchoolScreen(), SceneTheme.quran),
      _Place('ركن المسلم', 'السيرة والأذكار ورتب', Icons.mosque_rounded, const Color(0xFF1F5E4A), (_) => const IslamicHubScreen(), SceneTheme.islamic),
      _Place('بيت القصص', 'قصص نتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen(), SceneTheme.islamic),
    ]),
    ('أتعلم وأكتشف', [
      _Place('حلقة اليوم', 'حلقة جديدة كل يوم', Icons.live_tv_rounded, const Color(0xFFFF5D8F), (_) => const EpisodesScreen(), SceneTheme.islamic),
      _Place('ورشة المخترع', 'كهرباء وآلات وأفكار', Icons.construction_rounded, const Color(0xFF0F766E), (_) => const WorkshopScreen(), SceneTheme.science),
      _Place('حروفي وأرقامي', 'حروف وكلمات وعد وقراءة', Icons.abc_rounded, const Color(0xFF1F2A44), (_) => const LearnHubScreen(), SceneTheme.learn),
      _Place('عالم العلوم', 'الفضاء والماء وبلادي', Icons.science_rounded, RC.night, (_) => const ScienceHubScreen(), SceneTheme.science),
      _Place('حديقتي', 'نخلتي وعادات الخير', Icons.park_rounded, RC.garden, (_) => const GardenScreen(), SceneTheme.islamic),
    ]),
    ('ألعب وأنافس', [
      _Place('برج الألغاز', 'ألغاز لا تنتهي', Icons.extension_rounded, const Color(0xFF8B5CF6), (_) => const TowerScreen()),
      _Place('دوري العائلة', 'بطولة البيت الشهرية', Icons.emoji_events_rounded, const Color(0xFFFF5D8F), (_) => const FamilyLeagueScreen()),
      _Place('سلم المعرفة', '١٠ درجات ونجوم أكثر', Icons.stairs_rounded, const Color(0xFF14B8A6), (_) => const LadderScreen()),
      _Place('أوسمتي', 'برونزي وفضي وذهبي وماسي', Icons.military_tech_rounded, const Color(0xFFFFC23F), (_) => const BadgesScreen()),
      _Place('وش تسوي لو؟', 'مواقف وقرارات', Icons.alt_route_rounded, const Color(0xFFEF4444), (_) => const ChoicesScreen()),
      _Place('صحتي', 'الماء والطبق الصحي', Icons.favorite_rounded, const Color(0xFF10B981), (_) => const HealthScreen()),
      _Place('متجر الروضة', 'ألوان وألقاب بنجومك', Icons.storefront_rounded, const Color(0xFFF59E0B), (_) => const ShopScreen()),
      _Place('إتقاني', 'أتقن كل الأسئلة', Icons.psychology_rounded, const Color(0xFF10B981), (_) => const MasteryScreen()),
      _Place('المسابقات', 'أجب واجمع النجوم', Icons.emoji_events_rounded, RC.goldDark, (_) => const QuizHubScreen()),
      _Place('ساحة الألعاب', 'نلعب ونتعلم', Icons.extension_rounded, RC.plum, (_) => const GamesHubScreen()),
      _Place('ميدان المنافسة', 'نافس واصعد', Icons.leaderboard_rounded, RC.green, (_) => const CompetitionScreen()),
      _Place('مجلس العائلة', 'مسابقة مع أهلي', Icons.chair_rounded, RC.rose, (_) => const FamilyQuizScreen()),
      _Place('رمضان', 'فانوس لكل يوم', Icons.nightlight_round, RC.night, (_) => const RamadanScreen()),
    ]),
  ];


  Future<void> _open(BuildContext context, _Place p) async {
    Voice.instance.say(p.title);
    SceneTheme.active = p.theme;
    await Navigator.of(context).push(MaterialPageRoute(builder: p.builder));
    SceneTheme.active = SceneTheme.home;
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
        night: true,
        theme: SceneTheme.home,
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
          SliverToBoxAdapter(child: _HomeWidgets(child: c)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 200 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
                child: PopIn(
                  child: _TvCard(
                    title: 'كواكب المعرفة',
                    hint: 'أبجد وتاريخ ومغامرات ورياضة وزمردة',
                    icon: Icons.public_rounded,
                    screen: const Color(0xFF2B1B7A),
                    frame: const Color(0xFFFFC23F),
                    wide: true,
                    art: const _MiniPlanetsArt(),
                    onTap: () async {
                      Voice.instance.say('كواكب المعرفة');
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanetsScreen()));
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                mainAxisExtent: 172 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4),
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: _allPlaces.length,
                (context, i) {
                  final p = _allPlaces[i];
                  return PopIn(
                    child: _TvCard(
                      title: p.title,
                      hint: p.hint,
                      icon: p.icon,
                      screen: p.color,
                      frame: equippedFrames(st)[i % 6],
                      tilt: (i.isEven ? -1 : 1) * 0.022,
                      onTap: () => _open(context, p),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _HadithCard()),
          const SliverToBoxAdapter(child: _FactCard()),
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
              Text('السلام عليكم', style: RT.body(14, color: const Color(0xFFCFC6FF))),
              Text(child.name, style: RT.display(26, color: Colors.white), overflow: TextOverflow.ellipsis),
              if (equippedTitle(AppScope.of(context)) case final t?)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(t.icon, size: 16, color: const Color(0xFFFFC23F)),
                  const SizedBox(width: 4),
                  Text(t.name, style: RT.body(13.5, color: const Color(0xFFFFC23F), weight: FontWeight.w700)),
                ]),
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

const _outline = Color(0xFF2A1A66);

/// بطاقة «تلفاز كرتوني»: إطار حلوى متموج بحد غامق، وشاشة ملونة فيها الأيقونة،
/// وهوائي وزران، ولافتة الاسم معلقة أسفل الإطار. تميل قليلًا وتقفز عند اللمس.
class _TvCard extends StatefulWidget {
  final String title;
  final String hint;
  final IconData icon;
  final Color screen;
  final Color frame;
  final double tilt;
  final bool wide;
  final Widget? art;
  final VoidCallback onTap;
  const _TvCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.screen,
    required this.frame,
    required this.onTap,
    this.tilt = 0,
    this.wide = false,
    this.art,
  });

  @override
  State<_TvCard> createState() => _TvCardState();
}

class _TvCardState extends State<_TvCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final hc = A11y.highContrastOf(context);
    return Semantics(
      button: true,
      label: '${widget.title}، ${widget.hint}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          Haptics.tap();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Transform.rotate(
            angle: hc ? 0 : widget.tilt,
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              final frameRect = Rect.fromLTWH(4, 10, w - 8, h - 30);
              final screenRect = frameRect.deflate(11);
              return Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TvPainter(
                      frame: wobblyFramePath(frameRect, radius: 26, amp: hc ? 0 : 2.2, wave: 90),
                      screen: wobblyFramePath(screenRect, radius: 18, amp: hc ? 0 : 1.6, wave: 80),
                      frameColor: widget.frame,
                      screenColor: widget.screen,
                      flat: hc,
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: screenRect,
                  child: Center(
                    child: widget.art ??
                        Icon(widget.icon, size: widget.wide ? 54 : 46, color: Colors.white, shadows: const [
                          Shadow(color: Color(0x55000000), offset: Offset(0, 3)),
                        ]),
                  ),
                ),
                // الهوائي
                if (!hc)
                  Positioned(
                    top: -4,
                    left: w / 2 - 22,
                    child: CustomPaint(size: const Size(44, 18), painter: _AntennaPainter(widget.frame)),
                  ),
                // لافتة الاسم المعلقة
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: const StadiumBorder(side: BorderSide(color: _outline, width: 3)),
                        shadows: const [BoxShadow(color: _outline, offset: Offset(0, 3))],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(widget.title, maxLines: 1, textAlign: TextAlign.center, style: RT.display(widget.wide ? 19 : 16, color: RC.ink)),
                        ),
                        if (widget.wide)
                          Text(widget.hint, maxLines: 1, textAlign: TextAlign.center, style: RT.body(12.5, color: RC.inkSoft)),
                      ]),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

class _TvPainter extends CustomPainter {
  final Path frame;
  final Path screen;
  final Color frameColor;
  final Color screenColor;
  final bool flat;
  _TvPainter({required this.frame, required this.screen, required this.frameColor, required this.screenColor, required this.flat});

  @override
  void paint(Canvas canvas, Size size) {
    final hsl = HSLColor.fromColor(screenColor);
    final dark = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    final light = hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
    if (!flat) canvas.drawPath(frame.shift(const Offset(0, 6)), Paint()..color = _outline);
    canvas.drawPath(frame, Paint()..color = frameColor);
    canvas.drawPath(frame, Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    final sb = screen.getBounds();
    canvas.drawPath(
      screen,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [light, screenColor, dark]).createShader(sb),
    );
    canvas.drawPath(screen, Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    if (flat) return;
    // لمعة الشاشة
    canvas.save();
    canvas.clipPath(screen);
    canvas.drawPath(
      Path()
        ..moveTo(sb.left, sb.top)
        ..lineTo(sb.left + sb.width * 0.55, sb.top)
        ..lineTo(sb.left + sb.width * 0.25, sb.bottom)
        ..lineTo(sb.left, sb.bottom)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.restore();
    // زران على الإطار
    for (final (dx, col) in [(sb.right - 14.0, const Color(0xFFFF5D8F)), (sb.right - 30.0, const Color(0xFF22D3EE))]) {
      final p = Offset(dx, sb.bottom + 6);
      canvas.drawCircle(p, 5, Paint()..color = col);
      canvas.drawCircle(p, 5, Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(covariant _TvPainter old) => old.frameColor != frameColor || old.screenColor != screenColor || old.flat != flat;
}

class _AntennaPainter extends CustomPainter {
  final Color color;
  _AntennaPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _outline
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final base = Offset(size.width / 2, size.height + 2);
    canvas.drawLine(base, Offset(4, 4), line);
    canvas.drawLine(base, Offset(size.width - 4, 4), line);
    for (final p in [const Offset(4, 4), Offset(size.width - 4, 4)]) {
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(p, 4.5, Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _AntennaPainter old) => old.color != color;
}

/// كواكب صغيرة مرسومة داخل شاشة «كواكب المعرفة».
class _MiniPlanetsArt extends StatelessWidget {
  const _MiniPlanetsArt();
  @override
  Widget build(BuildContext context) => const SizedBox.expand(child: CustomPaint(painter: _MiniPlanetsPainter()));
}

class _MiniPlanetsPainter extends CustomPainter {
  const _MiniPlanetsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(4);
    for (var i = 0; i < 26; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), r.nextDouble() * 1.4 + 0.5,
          Paint()..color = Colors.white70);
    }
    void planet(Offset c, double rad, Color col, Color ring) {
      final edge = Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final ringP = Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = rad * 0.22;
      final oval = Rect.fromCenter(center: c, width: rad * 3, height: rad * 0.8);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.3);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(oval, math.pi, math.pi, false, ringP);
      canvas.restore();
      canvas.drawCircle(c, rad, Paint()..color = col);
      canvas.drawCircle(c, rad, edge);
      canvas.drawCircle(c + Offset(-rad * 0.35, -rad * 0.35), rad * 0.22, Paint()..color = Colors.white54);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.3);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(oval, 0, math.pi, false, ringP);
      canvas.restore();
    }

    final w = size.width, h = size.height;
    planet(Offset(w * 0.22, h * 0.55), h * 0.22, const Color(0xFFFF9F1C), const Color(0xFFFFE680));
    planet(Offset(w * 0.52, h * 0.38), h * 0.16, const Color(0xFF22C55E), const Color(0xFF22D3EE));
    planet(Offset(w * 0.80, h * 0.58), h * 0.20, const Color(0xFFFF5D8F), const Color(0xFFA78BFA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ودجات أعلى الرئيسية: تحدي اليوم وسلسلة الأيام، كلافتات حلوى.
class _HomeWidgets extends StatelessWidget {
  final ChildProfile child;
  const _HomeWidgets({required this.child});

  @override
  Widget build(BuildContext context) {
    final done = child.completed.contains('daily_${todayKey()}');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(
          child: _CandyWidget(
            color: const Color(0xFFFFC23F),
            icon: done ? Icons.check_circle_rounded : Icons.bolt_rounded,
            title: 'تحدي اليوم',
            line: done ? 'أنجزته اليوم' : '٥ أسئلة تختار لك ما تحتاجه',
            onTap: () {
              final pool = [...kQuestions, ...kGeneratedQuestions].where((q) => q.band <= child.ageBand).toList();
              final qs = smartPick(pool, child.mastery, dayNumber(DateTime.now()), count: 5);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuizRunner(title: 'تحدي اليوم', questions: qs, completionId: 'daily_${todayKey()}'),
              ));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(builder: (context) {
            final st = AppScope.of(context);
            final qs = questsFor(DateTime.now(), level: child.level, hasHifz: child.hifz.isNotEmpty);
            final n = qs.where((q) => st.todayCount(q.kind) >= q.goal).length;
            return _CandyWidget(
              color: const Color(0xFF22D3EE),
              icon: Icons.map_rounded,
              title: 'رحلة اليوم',
              line: '$n من ${qs.length} مهام • سلسلة ${child.streak}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyScreen())),
            );
          }),
        ),
      ]),
    );
  }
}

class _CandyWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String line;
  final VoidCallback? onTap;
  const _CandyWidget({required this.color, required this.icon, required this.title, required this.line, this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline, width: 3),
        boxShadow: [BoxShadow(color: color, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _outline, width: 2.5)),
          child: Icon(icon, color: _outline, size: 24),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: RT.display(16, color: RC.ink)),
        FittedBox(fit: BoxFit.scaleDown, child: Text(line, textAlign: TextAlign.center, style: RT.body(12.5, color: RC.inkSoft))),
      ]),
    );
    if (onTap == null) return Semantics(label: '$title، $line', child: body);
    return Semantics(
      button: true,
      label: '$title، $line',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          onTap!();
        },
        child: body,
      ),
    );
  }
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

/// هل تعلم؟ معلومة واحدة كل يوم من بطاقات عالم العلوم.
class _FactCard extends StatelessWidget {
  const _FactCard();

  @override
  Widget build(BuildContext context) {
    final f = factOfDay(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Chunky(
        color: const Color(0xFFFFF3D6),
        radius: 20,
        depth: 4,
        padding: const EdgeInsets.all(14),
        onTap: () => Voice.instance.say('هل تعلم؟ ${f.fact}'),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFC98A12), size: 24),
            const SizedBox(width: 6),
            Text('هل تعلم؟', style: RT.display(17, color: const Color(0xFF7A5200))),
          ]),
          const SizedBox(height: 4),
          Text(f.fact, textAlign: TextAlign.center, style: RT.body(15.5)),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(color: RC.ink, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Text('حديث اليوم', style: RT.display(15, color: RC.gold, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('قال رسول الله ﷺ: ${h.$1}',
            textAlign: TextAlign.center, style: RT.display(19, color: Colors.white, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(h.$2, textAlign: TextAlign.center, style: RT.body(13, color: Colors.white70)),
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
