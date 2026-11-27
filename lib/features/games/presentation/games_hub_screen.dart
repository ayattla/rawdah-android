import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/games/presentation/flame/letter_game.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/games/presentation/more_games_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ساحة الألعاب'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BigTile(
              title: 'صيد الحروف',
              subtitle: c.bestLetterScore > 0 ? 'أفضل نتيجة: ${c.bestLetterScore}' : 'المس الفانوس الذي يحمل الحرف',
              icon: Icons.abc_rounded,
              color: RC.gold,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LetterGameScreen())),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'رتّب خطوات الوضوء',
              subtitle: 'اسحب البطاقات لترتيبها',
              icon: Icons.water_drop_rounded,
              color: RC.sea,
              done: c.completed.contains('game_wudu'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WuduOrderGame())),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'ابنِ المسجد',
              subtitle: 'كل إجابة صحيحة تبني جزءًا',
              icon: Icons.mosque_rounded,
              color: RC.green,
              done: c.completed.contains('game_mosque'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MosqueBuilderGame())),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'بطاقات الذاكرة',
              subtitle: 'ابحث عن الشكلين المتشابهين',
              icon: Icons.grid_view_rounded,
              color: RC.coral,
              done: c.completed.contains('game_memory'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoryGame())),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'وصّل الذكر بوقته',
              subtitle: 'ماذا نقول؟ ومتى؟',
              icon: Icons.link_rounded,
              color: RC.plum,
              done: c.completed.contains('game_match'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MatchGame())),
            ),
            for (final g in _orderGames)
              if (c.ageBand >= g.$5) ...[
                const SizedBox(height: 12),
                BigTile(
                  title: g.$2,
                  subtitle: 'رتّب البطاقات بالترتيب الصحيح',
                  icon: Icons.format_list_numbered_rounded,
                  color: RC.greenDark,
                  done: c.completed.contains(g.$1),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WuduOrderGame(title: g.$2, prompt: g.$3, gameId: g.$1, items: g.$4))),
                ),
              ],
          ]),
        ),
      ]),
    );
  }
}

/// ألعاب الترتيب: (المعرّف، العنوان، التعليمة الصوتية، الترتيب الصحيح، أقل فئة عمرية).
const List<(String, String, String, List<String>, int)> _orderGames = [
  ('game_order_salah', 'رتّب الصلوات الخمس', 'رتب الصلوات من أول اليوم إلى آخره',
      ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'], 0),
  ('game_order_short', 'رتّب السور كما في المصحف', 'رتب السور كما في المصحف',
      ['الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس'], 0),
  ('game_order_khulafa', 'رتّب الخلفاء الراشدين', 'رتب الخلفاء الراشدين من الأول إلى الرابع',
      ['أبو بكر الصديق', 'عمر بن الخطاب', 'عثمان بن عفان', 'علي بن أبي طالب'], 1),
  ('game_order_hajj', 'رتّب أيام الحج', 'رتب أعمال الحج حسب الأيام',
      ['يوم التروية في منى', 'الوقوف بعرفة', 'المبيت بمزدلفة', 'رمي جمرة العقبة يوم النحر'], 1),
  ('game_order_months', 'رتّب الأشهر الهجرية', 'رتب الأشهر الهجرية من محرم إلى ذي الحجة',
      ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'], 2),
  ('game_order_umrah', 'رتّب أعمال العمرة', 'رتب أعمال العمرة من أولها',
      ['الإحرام من الميقات', 'الطواف بالكعبة سبعة أشواط', 'السعي بين الصفا والمروة', 'الحلق أو التقصير'], 1),
  ('game_order_week', 'رتّب أيام الأسبوع', 'رتب أيام الأسبوع من السبت',
      ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'], 0),
  ('game_order_water', 'رتّب دورة الماء', 'رتب رحلة الماء في الطبيعة',
      ['الشمس تسخن ماء البحر', 'الماء يتبخر ويصعد', 'البخار يبرد ويصير سحابا', 'المطر ينزل على الأرض'], 1),
  ('game_order_plant', 'رتّب نمو النبتة', 'رتب مراحل نمو النبتة',
      ['بذرة في التراب', 'يخرج الجذر', 'تطلع الساق والأوراق', 'تتفتح الزهرة', 'تصير ثمرة'], 0),
  ('game_order_planets', 'رتّب الكواكب من الشمس', 'رتب الكواكب من الأقرب للشمس',
      ['عطارد', 'الزهرة', 'الأرض', 'المريخ', 'المشتري', 'زحل', 'أورانوس', 'نبتون'], 2),
  ('game_order_moon', 'رتّب أطوار القمر', 'رتب أطوار القمر في الشهر الهجري',
      ['الهلال', 'التربيع الأول', 'البدر', 'التربيع الأخير'], 1),
  ('game_order_bread', 'رتّب صنع الخبز', 'رتب خطوات صنع الخبز',
      ['حصاد القمح', 'طحن القمح دقيقا', 'عجن الدقيق بالماء', 'ترك العجين يتخمر', 'خبز العجين في الفرن'], 0),
  ('game_order_hands', 'رتّب غسل اليدين', 'رتب خطوات غسل اليدين',
      ['بلل يديك بالماء', 'ضع الصابون', 'افرك يديك وبين أصابعك', 'اشطفهما بالماء', 'نشفهما بمنديل نظيف'], 0),
  ('game_order_numbers', 'رتّب من الأصغر للأكبر', 'رتب الأعداد من الأصغر إلى الأكبر',
      ['٧', '١٩', '٣٤', '٥٠', '٨٨', '١٠٠'], 0),
];

// ------------------------------------------------------------------ صيد الحروف

class LetterGameScreen extends StatefulWidget {
  const LetterGameScreen({super.key});

  @override
  State<LetterGameScreen> createState() => _LetterGameScreenState();
}

class _LetterGameScreenState extends State<LetterGameScreen> {
  late LetterWord _word;
  LetterGame? _gameInstance;
  LetterGame get _game => _gameInstance!;
  int _score = 0;
  int _seconds = 45;
  Timer? _timer;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final band = AppScope.read(context).current?.ageBand ?? 0;
    _word = kLetterWords[Random().nextInt(kLetterWords.length)];
    _score = 0;
    _seconds = 45;
    _over = false;
    // لعبة واحدة لكل الجولات: الجولة الجديدة تعيد ضبطها ولا تنشئ لعبة ومجمّعًا جديدين
    if (_gameInstance == null) {
      _gameInstance = LetterGame(
        target: _word.letter,
        pool: kLetterWords.map((w) => w.letter).toSet().toList(),
        speedFactor: 0.8 + band * 0.3,
        onHit: () => setState(() => _score++),
        onMiss: () {},
      );
    } else {
      _game.restart(_word.letter);
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) _end();
    });
    Voice.instance.say('ابحث عن حرف ${_word.letter}، مثل ${_word.word}');
  }

  void _end() {
    _timer?.cancel();
    _game.running = false;
    setState(() => _over = true);
    AppScope.read(context).recordLetterScore(_score);
    Voice.instance.say('انتهى الوقت. جمعت $_score');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      night: true,
      child: Column(children: [
        KidBar(
          title: 'صيد الحروف',
          trailing: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('$_seconds ث', style: const TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Text(_word.letter, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: RC.coral)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('كما في: ${_word.word}', style: const TextStyle(fontSize: 22, color: RC.ink)),
            ),
            const Icon(Icons.star_rounded, color: RC.gold, size: 30),
            Text(' $_score', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: RC.ink)),
          ]),
        ),
        Expanded(
          // اللعبة تبقى مركّبة دائمًا، ونافذة النتيجة تظهر فوقها
          child: Stack(children: [
            Positioned.fill(child: GameWidget(game: _game)),
            if (_over)
              Positioned.fill(
                child: ColoredBox(
                  color: RC.night.withValues(alpha: 0.85),
                  child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Lantern(size: 120, glow: (_score / 10).clamp(0.2, 1.0).toDouble()),
                      const SizedBox(height: 12),
                      Text('جمعت $_score فانوسًا',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('وربحت ${_score ~/ 3} نجوم', style: const TextStyle(fontSize: 20, color: Colors.white70)),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'جولة جديدة',
                        icon: Icons.replay_rounded,
                        color: RC.gold,
                        onTap: () => setState(_newRound),
                      ),
                    ]),
                  ),
                ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ ترتيب الوضوء

class WuduOrderGame extends StatefulWidget {
  /// لعبة ترتيب عامة: بلا معاملات هي ترتيب خطوات الوضوء.
  final String title;
  final String prompt;
  final String gameId;
  final List<String>? items;
  const WuduOrderGame({
    super.key,
    this.title = 'رتّب خطوات الوضوء',
    this.prompt = 'رتب خطوات الوضوء من الأولى إلى الأخيرة',
    this.gameId = 'game_wudu',
    this.items,
  });

  @override
  State<WuduOrderGame> createState() => _WuduOrderGameState();
}

class _WuduOrderGameState extends State<WuduOrderGame> {
  late final List<String> _correct;
  late List<String> _items;
  bool? _result;

  @override
  void initState() {
    super.initState();
    _correct = widget.items ?? kLessons.firstWhere((l) => l.id == 'lesson_wudu').items.map((e) => e.title).toList();
    _items = List.of(_correct)..shuffle();
    Voice.instance.say(widget.prompt);
  }

  Future<void> _check() async {
    final ok = List.generate(_items.length, (i) => _items[i] == _correct[i]).every((e) => e);
    setState(() => _result = ok);
    if (ok) {
      final first = AppScope.read(context).complete(widget.gameId, stars: 5);
      await showReward(context, stars: first ? 5 : 0, title: 'ترتيب صحيح');
    } else {
      Voice.instance.say('قريب! راجع الترتيب مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        KidBar(title: widget.title),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('اضغط مطوّلًا على البطاقة واسحبها إلى مكانها', style: TextStyle(fontSize: 17, color: RC.ink)),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            onReorder: (a, b) => setState(() {
              if (b > a) b--;
              final x = _items.removeAt(a);
              _items.insert(b, x);
              _result = null;
            }),
            itemBuilder: (context, i) {
              final right = _result != null && _items[i] == _correct[i];
              return Container(
                key: ValueKey(_items[i]),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _result == null ? Colors.white : (right ? const Color(0xFFDFF3E6) : const Color(0xFFFBE3DA)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: RC.sea,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(_items[i], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.drag_indicator_rounded),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: PrimaryButton(label: 'تحقق', icon: Icons.check_rounded, onTap: _check),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ المطابقة

class MatchGame extends StatefulWidget {
  const MatchGame({super.key});

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> {
  late List<String> _rights;
  String? _pickedLeft;
  final Set<String> _matched = {};
  String? _wrong;

  @override
  void initState() {
    super.initState();
    _rights = kMatchPairs.map((p) => p.right).toList()..shuffle();
    Voice.instance.say('اختر الوقت، ثم اختر الذكر المناسب له');
  }

  Future<void> _pickRight(String r) async {
    if (_pickedLeft == null) return;
    final pair = kMatchPairs.firstWhere((p) => p.left == _pickedLeft);
    if (pair.right == r) {
      setState(() {
        _matched.add(pair.left);
        _pickedLeft = null;
        _wrong = null;
      });
      Voice.instance.say(r);
      if (_matched.length == kMatchPairs.length) {
        final first = AppScope.read(context).complete('game_match', stars: 5);
        await showReward(context, stars: first ? 5 : 0, title: 'أحسنت');
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      setState(() => _wrong = r);
    }
  }

  Widget _chip(String text, {required bool selected, required bool done, required bool wrong, required VoidCallback onTap}) {
    Color bg = Colors.white;
    if (done) bg = const Color(0xFFDFF3E6);
    if (selected) bg = RC.gold.withValues(alpha: 0.35);
    if (wrong) bg = const Color(0xFFFBE3DA);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: done ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchedRights =
        kMatchPairs.where((p) => _matched.contains(p.left)).map((p) => p.right).toSet();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'وصّل الذكر بوقته'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(children: [
                  const Text('الوقت', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.greenDark)),
                  const SizedBox(height: 8),
                  for (final p in kMatchPairs)
                    _chip(p.left,
                        selected: _pickedLeft == p.left,
                        done: _matched.contains(p.left),
                        wrong: false,
                        onTap: () => setState(() {
                              _pickedLeft = p.left;
                              _wrong = null;
                            })),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(children: [
                  const Text('الذكر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.plum)),
                  const SizedBox(height: 8),
                  for (final r in _rights)
                    _chip(r,
                        selected: false,
                        done: matchedRights.contains(r),
                        wrong: _wrong == r,
                        onTap: () => _pickRight(r)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
