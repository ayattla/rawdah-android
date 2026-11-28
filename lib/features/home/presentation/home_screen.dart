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
import 'package:rawdah/features/shop/economy.dart';
import 'package:rawdah/features/shop/treasure_screen.dart';
import 'package:rawdah/features/city/city.dart';
import 'package:rawdah/features/cards/cards.dart';
import 'package:rawdah/features/coding/coding_screen.dart';
import 'package:rawdah/features/friday/friday.dart';
import 'package:rawdah/features/family/family_league.dart';
import 'package:rawdah/features/health/health_screen.dart';
import 'package:rawdah/features/choices/choices_screen.dart';
import 'package:rawdah/features/ladder/ladder.dart';
import 'package:rawdah/features/badges/badges.dart';
import 'package:rawdah/features/speed/speed.dart';
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
      _Place('رحلاتي', 'محطات تصل بك إلى الشهادة', Icons.route_rounded, RC.ink, (_) => const JourneysScreen(), SceneTheme.journey);

  /// الأقسام مجمعة حسب ما يريده الطفل: أول بلاطة في كل جناح عريضة، والباقي صغيرة.
  static List<_Place> get _allPlaces => [for (final w in _wings) ...w.$2];

  static final List<(String, List<_Place>)> _wings = [
    ('قرآني وديني', [
      _Place('المدرسة', 'قرآن وأذكار ودروس', Icons.school_rounded, RC.sea, (_) => const SchoolScreen(), SceneTheme.school),
      _Place('ركن المسلم', 'السيرة والأذكار ورتب', Icons.mosque_rounded, const Color(0xFF1F5E4A), (_) => const IslamicHubScreen(), SceneTheme.islamic),
      _Place('بيت القصص', 'قصص نتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen(), SceneTheme.stories),
    ]),
    ('أتعلم وأكتشف', [
      _Place('حلقة اليوم', 'حلقة جديدة كل يوم', Icons.live_tv_rounded, const Color(0xFFFF5D8F), (_) => const EpisodesScreen(), SceneTheme.quiz),
      _Place('ورشة المخترع', 'كهرباء وآلات وأفكار', Icons.construction_rounded, const Color(0xFF0F766E), (_) => const WorkshopScreen(), SceneTheme.workshop),
      _Place('حروفي وأرقامي', 'حروف وكلمات وعد وقراءة', Icons.abc_rounded, const Color(0xFF1F2A44), (_) => const LearnHubScreen(), SceneTheme.learn),
      _Place('عالم العلوم', 'الفضاء والماء وبلادي', Icons.science_rounded, RC.night, (_) => const ScienceHubScreen(), SceneTheme.science),
      _Place('حديقتي', 'نخلتي وعادات الخير', Icons.park_rounded, RC.garden, (_) => const GardenScreen(), SceneTheme.garden),
    ]),
    ('ألعب وأنافس', [
      _Place('برج الألغاز', 'ألغاز لا تنتهي', Icons.extension_rounded, const Color(0xFF8B5CF6), (_) => const TowerScreen(), SceneTheme.play),
      _Place('دوري العائلة', 'بطولة البيت الشهرية', Icons.emoji_events_rounded, const Color(0xFFFF5D8F), (_) => const FamilyLeagueScreen(), SceneTheme.quiz),
      _Place('ميدان الحساب', 'تحدي الدقيقة وجدول الضرب', Icons.calculate_rounded, const Color(0xFFEF4444), (_) => const SpeedHubScreen(), SceneTheme.school),
      _Place('سلم المعرفة', '١٠ درجات ونجوم أكثر', Icons.stairs_rounded, const Color(0xFF14B8A6), (_) => const LadderScreen(), SceneTheme.quiz),
      _Place('أوسمتي', 'برونزي وفضي وذهبي وماسي', Icons.military_tech_rounded, const Color(0xFFFFC23F), (_) => const BadgesScreen(), SceneTheme.quiz),
      _Place('وش تسوي لو؟', 'مواقف وقرارات', Icons.alt_route_rounded, const Color(0xFFEF4444), (_) => const ChoicesScreen(), SceneTheme.journey),
      _Place('صحتي', 'الماء والطبق الصحي', Icons.favorite_rounded, const Color(0xFF10B981), (_) => const HealthScreen(), SceneTheme.garden),
      _Place('بطولة الجمعة', 'كل جمعة جوائز كبيرة', Icons.emoji_events_rounded, const Color(0xFFFFC23F), (_) => const FridayScreen(), SceneTheme.quiz),
      _Place('المبرمج الصغير', 'أوامر توصل الصاروخ', Icons.code_rounded, const Color(0xFF0EA5E9), (_) => const CodingScreen(), SceneTheme.workshop),
      _Place('ألبوم المعرفة', '٤٠ بطاقة تجمعها', Icons.collections_bookmark_rounded, const Color(0xFF6366F1), (_) => const AlbumScreen(), SceneTheme.stories),
      _Place('مدينتي', 'ابن مدينتك بنجومك', Icons.location_city_rounded, const Color(0xFF10B981), (_) => const CityScreen(), SceneTheme.garden),
      _Place('كنز النجوم', 'مكافآت يومية وتحديات الأسبوع', Icons.diamond_rounded, const Color(0xFF8B5CF6), (_) => const TreasureScreen(), SceneTheme.play),
      _Place('متجر الروضة', 'ألوان وألقاب بنجومك', Icons.storefront_rounded, const Color(0xFFF59E0B), (_) => const ShopScreen(), SceneTheme.play),
      _Place('إتقاني', 'أتقن كل الأسئلة', Icons.psychology_rounded, const Color(0xFF10B981), (_) => const MasteryScreen(), SceneTheme.journey),
      _Place('المسابقات', 'أجب واجمع النجوم', Icons.emoji_events_rounded, RC.goldDark, (_) => const QuizHubScreen(), SceneTheme.quiz),
      _Place('ساحة الألعاب', 'نلعب ونتعلم', Icons.extension_rounded, RC.plum, (_) => const GamesHubScreen(), SceneTheme.play),
      _Place('ميدان المنافسة', 'نافس واصعد', Icons.leaderboard_rounded, RC.green, (_) => const CompetitionScreen(), SceneTheme.quiz),
      _Place('مجلس العائلة', 'مسابقة مع أهلي', Icons.chair_rounded, RC.rose, (_) => const FamilyQuizScreen(), SceneTheme.stories),
      _Place('رمضان', 'فانوس لكل يوم', Icons.nightlight_round, RC.night, (_) => const RamadanScreen(), SceneTheme.islamic),
    ]),
  ];


  Future<void> _open(BuildContext context, _Place p) async {
    Voice.instance.say(p.title);
    SceneTheme.active = p.theme;
    // تنوع الفواصل حسب العالم: ستارة للمسابقات، وتشغيل قناة لبقية الأقسام
    final route = p.theme == SceneTheme.quiz ? CurtainRoute<void>(builder: p.builder) : ChannelRoute<void>(builder: p.builder);
    await Navigator.of(context).push(route);
    SceneTheme.active = SceneTheme.home;
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const Scaffold(body: SizedBox());
    ScenePainter.nightSky = equippedSky(st);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) st.leaveChild();
      },
      child: Stack(children: [
      ChildShell(
        night: true,
        studio: true,
        theme: SceneTheme.home,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _TopBar(child: c)),
          SliverToBoxAdapter(child: _ArchHeader(child: c)),
          SliverToBoxAdapter(child: _TodayWindow(child: c, onOpen: (p) => _open(context, p), places: _allPlaces)),
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
                      await Navigator.of(context).push(WarpRoute<void>(builder: (_) => const PlanetsScreen(), title: 'كواكب المعرفة', color: const Color(0xFF6D4AFF), icon: Icons.public_rounded));
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: (_allPlaces.length + 1) ~/ 2,
                (context, r) => _ShelfRow(
                  row: r,
                  places: _allPlaces.skip(r * 2).take(2).toList(),
                  frames: [equippedFrames(st)[(r * 2) % 6], equippedFrames(st)[(r * 2 + 1) % 6]],
                  onOpen: (p) => _open(context, p),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _HadithCard()),
          const SliverToBoxAdapter(child: _FactCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
      if (!_ChannelIdent.shown && !LiveScene.inTest && !A11y.reduceMotionOf(context)) const Positioned.fill(child: _ChannelIdent()),
      ]),
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
            Positioned.fill(child: CustomPaint(painter: _ArchPainter(DateTime.now().hour))),
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
              left: box.maxWidth * 0.1,
              right: box.maxWidth * 0.1,
              bottom: box.maxHeight * 0.17,
              child: Row(children: [
                _LevelRing(level: lvl, progress: progress),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.streak > 1 ? 'فانوسك مضيء منذ ${c.streak} أيام' : 'تعال كل يوم ليزداد فانوسك نورًا',
                    style: RT.display(15, color: Colors.white, weight: FontWeight.w700).copyWith(shadows: const [Shadow(color: Color(0xAA14204F), blurRadius: 6)]),
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
  /// ساعة اليوم: سماء الشاشة تتبدل بين الصباح والظهر والمغرب والليل.
  final int hour;
  _ArchPainter(this.hour);

  bool get _day => hour >= 5 && hour < 16;
  List<Color> get _sky => hour >= 5 && hour < 11
      ? const [Color(0xFF5AB4F0), Color(0xFF9AD8F5), Color(0xFFFFE3B3)]
      : hour >= 11 && hour < 16
          ? const [Color(0xFF2F8DE0), Color(0xFF6CC4F2), Color(0xFFBDE9FF)]
          : hour >= 16 && hour < 19
              ? const [Color(0xFF1D2B64), Color(0xFF6A5AE0), Color(0xFFF59E5B)]
              : const [Color(0xFF0B1240), Color(0xFF1D2B64), Color(0xFF3B2A7A)];

  // صار القوس شاشة تلفاز عريضة منفوخة مثل شاشات فواصل القنوات
  Path _arch(Size s, double inset) {
    final r = Rect.fromLTWH(0, 0, s.width, s.height - 8);
    return inset == 0 ? tvShape(3, r) : tvShape(3, Rect.fromLTRB(r.width * 0.06, r.height * 0.09, r.width * 0.94, r.height * 0.88));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _arch(size, 0);
    final inner = _arch(size, 12);
    // الإطار البلاستيكي الوردي بظل صلب ولمعة
    canvas.drawPath(outer.shift(const Offset(0, 7)), Paint()..color = _outline);
    canvas.drawPath(
      outer,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF9FD0), Color(0xFFFF5DB1), Color(0xFFE0368F)]).createShader(outer.getBounds()),
    );
    canvas.drawPath(outer, Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    final ob = outer.getBounds();
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ob.width * 0.14, ob.top + 6, ob.width * 0.36, 6), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.6));
    // السماء
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _sky,
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect));
    // نجوم وهلال
    final r = math.Random(3);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < (_day ? 0 : 18); i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.45),
          r.nextDouble() * 1.4 + 0.5, star);
    }
    final moon = Offset(size.width * 0.27, size.height * 0.3);
    if (_day) {
      // شمس الصباح والظهر بأشعة قصيرة
      canvas.drawCircle(moon, size.height * 0.11, Paint()..color = const Color(0xFFFFE680).withValues(alpha: 0.35));
      canvas.drawCircle(moon, size.height * 0.075, Paint()..color = const Color(0xFFFFD43B));
    } else {
      canvas.drawCircle(moon, size.height * 0.07, Paint()..color = const Color(0xFFFFE9A8));
      canvas.drawCircle(moon + Offset(size.height * 0.03, -size.height * 0.018), size.height * 0.062,
          Paint()..color = _sky.first);
    }
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
    canvas.drawPath(inner, Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9);
    canvas.drawPath(inner, Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    for (final (p, c) in [(Offset(w * 0.04, h * 0.12), const Color(0xFFFFD43B)), (Offset(w * 0.96, h * 0.1), const Color(0xFF22D3EE))]) {
      canvas.drawCircle(p, 6, Paint()..color = c);
      canvas.drawCircle(p, 6, Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
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
        color: const Color(0xFF3B2A99),
        edge: _outline,
        border: Border.all(color: const Color(0xFFFFB020), width: 3.5),
        radius: 26,
        depth: 6,
        onTap: onTap,
        semanticLabel: '${place.title}، ${place.hint}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: CustomPaint(
            painter: A11y.highContrastOf(context) ? null : _TrailPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                MiniTv(icon: place.icon, color: const Color(0xFFFF8A3D), size: 78, seed: 1),
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

/// شارة القناة عند أول فتح للرئيسية في كل تشغيل: أشعة تدور وتلفاز روضة ينط
/// ولمباته تومض، ثانية ونصف وتختفي، والضغط يتخطاها.
class _ChannelIdent extends StatefulWidget {
  const _ChannelIdent();
  static bool shown = false;
  @override
  State<_ChannelIdent> createState() => _ChannelIdentState();
}

class _ChannelIdentState extends State<_ChannelIdent> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
    ..forward().whenComplete(_done);
  bool _gone = false;

  void _done() {
    _ChannelIdent.shown = true;
    if (mounted) setState(() => _gone = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        _c.stop();
        _done();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final fade = t > 0.82 ? 1 - (t - 0.82) / 0.18 : 1.0;
          final pop = Curves.elasticOut.transform((t / 0.5).clamp(0, 1));
          return Opacity(
            opacity: fade.clamp(0, 1),
            child: Stack(children: [
              Positioned.fill(child: StudioBackdrop(sky: const [Color(0xFF2B1A8A), Color(0xFF3B1E9E), Color(0xFF1A1150)], child: const SizedBox.expand())),
              Center(
                child: Transform.rotate(
                  angle: (1 - pop) * 0.3,
                  child: Transform.scale(
                    scale: 0.3 + 0.7 * pop,
                    child: SizedBox(
                      width: 260,
                      height: 210,
                      child: CustomPaint(
                        painter: CandyTvPainter(variant: 2, body: const Color(0xFFFF5DB1), screen: const Color(0xFF2B1B7A), rim: const Color(0xFFFFD43B)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Center(child: Text('روضة', style: RT.display(54, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0xFFFF5DB1), blurRadius: 14)]))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

/// خلفية بطاقة رحلاتي: طريق مغامرة متعرج بخط متقطع وأعلام صغيرة.
class _TrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final road = Path()
      ..moveTo(-10, h * 0.9)
      ..cubicTo(w * 0.25, h * 0.4, w * 0.45, h * 1.1, w * 0.7, h * 0.55)
      ..cubicTo(w * 0.82, h * 0.3, w * 0.95, h * 0.5, w + 10, h * 0.2);
    canvas.drawPath(road, Paint()
      ..color = const Color(0xFF5A4AA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round);
    final dash = Paint()
      ..color = const Color(0xFFFFD43B).withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final m in road.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 16) {
        canvas.drawLine(m.getTangentForOffset(d)!.position, m.getTangentForOffset(d + 7)?.position ?? Offset.zero, dash);
      }
    }
    for (final (x, y, c) in [(0.12, 0.62, const Color(0xFFFF5D8F)), (0.9, 0.3, const Color(0xFF34D399))]) {
      final b = Offset(w * x, h * y);
      canvas.drawLine(b, b - const Offset(0, 22), Paint()
        ..color = Colors.white70
        ..strokeWidth = 2);
      canvas.drawPath(Path()..moveTo(b.dx, b.dy - 22)..lineTo(b.dx + 14, b.dy - 17)..lineTo(b.dx, b.dy - 12)..close(), Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

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
  final int variant;
  final int? channel;
  const _TvCard({
    this.variant = 0,
    this.channel,
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
  bool _on = false;
  int _wiggle = 0;

  @override
  Widget build(BuildContext context) {
    final hc = A11y.highContrastOf(context);
    return Semantics(
      button: true,
      label: '${widget.title}، ${widget.hint}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (d) {
          WarpRoute.lastTap = d.globalPosition;
          setState(() => _down = true);
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () async {
          Haptics.tap();
          setState(() {
            _wiggle++;
            _on = true;
          });
          // الشاشة تنطفئ وتشتغل مثل التلفاز القديم قبل السفر
          await Future<void>.delayed(Duration(milliseconds: A11y.reduceMotionOf(context) ? 0 : 230));
          if (!mounted) return;
          widget.onTap();
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (mounted) setState(() => _on = false);
        },
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Transform.rotate(
            angle: hc ? 0 : widget.tilt,
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              final tvSize = Size(w - 8, h - 26);
              final painter = CandyTvPainter(
                variant: widget.wide ? 3 : widget.variant,
                body: widget.frame,
                screen: widget.screen,
                flat: hc,
                pressed: _down,
              );
              final sr = painter.screenRect(Size(tvSize.width, tvSize.height - 6)).shift(const Offset(4, 10));
              final screenRect = sr;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 4, top: 10, width: tvSize.width, height: tvSize.height, child: CustomPaint(painter: painter)),
                if (_on && !hc)
                  Positioned.fromRect(
                    rect: screenRect.deflate(6),
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 230),
                        builder: (_, v, __) => Center(
                          child: Container(
                            width: screenRect.width * (0.2 + 0.8 * v),
                            height: 4 + screenRect.height * 0.7 * (1 - (2 * v - 1).abs()),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fromRect(
                  rect: screenRect,
                  child: Center(
                    child: widget.art ??
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_wiggle),
                          tween: Tween(begin: _wiggle == 0 ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 420),
                          builder: (_, v, ic) => Transform.rotate(angle: math.sin(v * math.pi * 3) * 0.18 * (1 - v), child: Transform.scale(scale: 1 + 0.25 * math.sin(v * math.pi), child: ic)),
                          child: Icon(widget.icon, size: widget.wide ? 54 : 46, color: Colors.white, shadows: const [
                            Shadow(color: Color(0x55000000), offset: Offset(0, 3)),
                          ]),
                        ),
                  ),
                ),
                // رقم القناة في زاوية التلفاز
                if (widget.channel != null && !hc)
                  Positioned(
                    top: 2,
                    right: 6,
                    child: Transform.rotate(
                      angle: 0.12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D6D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _outline, width: 2),
                        ),
                        child: Text('قناة ${widget.channel}', style: RT.display(11.5, color: Colors.white)),
                      ),
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

/// جدار الشاشات: كل رف عليه شاشتان بحجمين مختلفين يتبادلان كل صف،
/// والرف لوح حلوى بظل صلب. الترتيب نفسه بلا تغيير.
class _ShelfRow extends StatelessWidget {
  final int row;
  final List<_Place> places;
  final List<Color> frames;
  final void Function(_Place) onOpen;
  const _ShelfRow({required this.row, required this.places, required this.frames, required this.onOpen});

  static const _planks = [Color(0xFFFF5DB1), Color(0xFF22D3EE), Color(0xFFFFD43B), Color(0xFF9DFF8A)];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    final h = 186.0 * scale;
    final bigFirst = row.isEven;
    final plank = _planks[row % _planks.length];
    Widget tv(int k, int flex) {
      final p = places[k];
      final i = row * 2 + k;
      return Expanded(
        flex: flex,
        child: PopIn(
          child: _TvCard(
            title: p.title,
            hint: p.hint,
            icon: p.icon,
            screen: p.color,
            frame: frames[k],
            variant: (i * 7 + row) % 3,
            channel: i + 1,
            tilt: ((i % 3) - 1) * 0.025,
            onTap: () => onOpen(p),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: SizedBox(
        height: h + 22,
        child: Stack(clipBehavior: Clip.none, children: [
          // الرف
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                color: plank,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _outline, width: 3),
                boxShadow: const [BoxShadow(color: _outline, offset: Offset(0, 5))],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: h,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (places.length == 1)
                tv(0, 1)
              else ...[
                tv(0, bigFirst ? 11 : 9),
                const SizedBox(width: 10),
                tv(1, bigFirst ? 9 : 11),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// نافذة اليوم: تلفاز صغير يعرض اقتراح اليوم ولافتة ترحيب، بدل شريط الأخبار.
/// الاقتراح يتغير كل يوم بين أقسام المغامرة، والضغط يفتحه مباشرة.
class _TodayWindow extends StatelessWidget {
  final ChildProfile child;
  final List<_Place> places;
  final void Function(_Place) onOpen;
  const _TodayWindow({required this.child, required this.places, required this.onOpen});

  static const _picks = ['حلقة اليوم', 'برج الألغاز', 'المبرمج الصغير', 'وش تسوي لو؟', 'ألبوم المعرفة', 'سلم المعرفة', 'ورشة المخترع'];

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    final name = _picks[day % _picks.length];
    final p = places.firstWhere((x) => x.title == name, orElse: () => places.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: GestureDetector(
        onTapDown: (d) => WarpRoute.lastTap = d.globalPosition,
        onTap: () {
          Haptics.tap();
          onOpen(p);
        },
        child: Semantics(
          button: true,
          label: 'اقتراح اليوم: ${p.title}',
          excludeSemantics: true,
          child: Row(children: [
            MiniTv(icon: p.icon, color: p.color, size: 96, seed: day),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(6)),
                  border: Border.all(color: _outline, width: 3),
                  boxShadow: const [BoxShadow(color: _outline, offset: Offset(0, 5))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مغامرة اليوم يا ${child.name}', style: RT.body(13.5, color: const Color(0xFFB45309), weight: FontWeight.w700)),
                  Text(p.title, style: RT.display(21, color: _outline)),
                  Text(p.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: RT.body(13, color: const Color(0xFF5B4BA8))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
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
    final hsl = HSLColor.fromColor(color);
    final body = Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 0.92)).toColor(),
          color,
        ]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline, width: 3),
        boxShadow: const [BoxShadow(color: _outline, offset: Offset(0, 5))],
      ),
      child: Column(children: [
        MiniTv(icon: icon, color: _outline, size: 58, seed: title.length),
        const SizedBox(height: 4),
        Text(title, textAlign: TextAlign.center, style: RT.display(17, color: _outline)),
        FittedBox(fit: BoxFit.scaleDown, child: Text(line, textAlign: TextAlign.center, style: RT.body(12.5, color: _outline, weight: FontWeight.w600))),
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
        color: _outline,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF22D3EE), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x99000000), offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('لوحة مغامرة اليوم', style: RT.display(20, color: const Color(0xFFFFD43B)))),
          if (claimed)
            Text('أنجزتها، بارك الله فيك', style: RT.display(15, color: const Color(0xFF9DFFB8), weight: FontWeight.w700))
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
              const Icon(Icons.star_rounded, color: Color(0xFFFFD43B), size: 20),
              Text(' 10 عند الإتمام', style: RT.body(14, color: RC.onDarkSoft, weight: FontWeight.w600)),
            ]),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: Stack(children: [
            // سكة المغامرة خلف المحطات
            Positioned(
              left: 30,
              right: 30,
              top: 26,
              height: 8,
              child: CustomPaint(painter: _DottedTrack(items.where((m) => m.$3 >= 1).length / items.length)),
            ),
            Row(children: [
              for (final m in items)
                Expanded(
                  child: Column(children: [
                    _MissionOrb(icon: m.$1, progress: m.$3),
                    const SizedBox(height: 8),
                    Text(m.$2, textAlign: TextAlign.center, maxLines: 2, style: RT.body(13, color: RC.onDark, weight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _DottedTrack extends CustomPainter {
  final double done;
  _DottedTrack(this.done);
  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 14) {
      // المسار يمتلئ من اليمين حسب الإنجاز
      final filled = x >= size.width * (1 - done);
      canvas.drawCircle(Offset(x, size.height / 2), 3.5, Paint()..color = filled ? const Color(0xFF9DFFB8) : const Color(0xFF22D3EE).withValues(alpha: 0.6));
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTrack o) => o.done != done;
}

/// محطة مهمة: كرة حلوى بحلقة تقدم؛ خضراء بعلامة صح عند الإنجاز.
class _MissionOrb extends StatelessWidget {
  final IconData icon;
  final double progress;
  const _MissionOrb({required this.icon, required this.progress});

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    final col = done ? const Color(0xFF34D399) : (progress > 0 ? const Color(0xFFFFC23F) : const Color(0xFF8B5CF6));
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CircularProgressIndicator(value: progress, strokeWidth: 5, color: const Color(0xFF9DFFB8), backgroundColor: Colors.white24),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: const Alignment(-0.35, -0.4), colors: [Color.lerp(col, Colors.white, 0.4)!, col]),
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: Icon(done ? Icons.check_rounded : icon, color: _outline, size: 24),
        ),
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
