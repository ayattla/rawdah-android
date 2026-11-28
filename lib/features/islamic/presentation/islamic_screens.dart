import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/islamic/data/islamic_content.dart';
import 'package:rawdah/features/islamic/domain/games.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';

const _green = Color(0xFF1F5E4A);
const _paper = Color(0xFFFFFBF0);
const _gold = Color(0xFFC98A12);
const _ink = Color(0xFF1F2A44);

/// ركن المسلم الصغير: رتب، ذاكرة الأذكار، السيرة.
/// باب بشكل محراب: لون الورق الدافئ، وخط ذهبي داخلي، وشارة القسم في الوسط.
class _ArchDoor extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool done;
  final VoidCallback onTap;
  const _ArchDoor({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap, this.done = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title، $subtitle${done ? '، مكتمل' : ''}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            Haptics.tap();
            Voice.instance.say(title);
            onTap();
          },
          child: CustomPaint(
            painter: _ArchPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 18),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                KhatamBadge(icon: done ? Icons.check_rounded : icon, color: done ? const Color(0xFF16A34A) : color, size: 58),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, maxLines: 2, style: RT.display(18, color: const Color(0xFF2A1A66))),
                Text(subtitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: RT.body(12.5, color: const Color(0xFF8A6A1A))),
              ]),
            ),
          ),
        ),
      );
}

class _ArchPainter extends CustomPainter {
  Path _arch(Rect r) {
    final top = r.top, spring = r.top + r.width * 0.5;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, spring)
      ..quadraticBezierTo(r.left, top, r.center.dx, top)
      ..quadraticBezierTo(r.right, top, r.right, spring)
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const ink = Color(0xFF2A1A66);
    final outer = _arch(Rect.fromLTWH(0, 0, size.width, size.height - 6));
    canvas.drawPath(outer.shift(const Offset(0, 6)), Paint()..color = ink);
    canvas.drawPath(outer, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFDF6E3), Color(0xFFF3E3BC)]).createShader(outer.getBounds()));
    canvas.drawPath(outer, Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);
    canvas.drawPath(_arch(Rect.fromLTWH(10, 10, size.width - 20, size.height - 22)), Paint()
      ..color = const Color(0xFFD4A537)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class IslamicHubScreen extends StatelessWidget {
  const IslamicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final sets = kOrderSets.where((s) => s.minBand <= c.ageBand).toList();
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        const KidBar(title: 'ركن المسلم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: [
                _ArchDoor(
                  title: 'السيرة النبوية',
                  subtitle: '${kSeerah.length} محطات',
                  icon: Icons.route_rounded,
                  color: _green,
                  done: c.completed.contains('seerah_quiz'),
                  onTap: () => open(const SeerahScreen()),
                ),
                _ArchDoor(
                  title: 'أسماء الله الحسنى',
                  subtitle: '${kGodNames.length} اسما بمعانيها',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF2B3A67),
                  done: c.completed.contains('god_names'),
                  onTap: () => open(const GodNamesScreen()),
                ),
                _ArchDoor(
                  title: 'صح أم خطأ',
                  subtitle: 'آداب المسلم',
                  icon: Icons.rule_rounded,
                  color: const Color(0xFFB3412F),
                  onTap: () => open(const TrueFalseScreen()),
                ),
                _ArchDoor(
                  title: 'ذاكرة الأذكار',
                  subtitle: 'طابق الذكر بوقته',
                  icon: Icons.style_rounded,
                  color: _gold,
                  onTap: () => open(MemoryGameScreen(band: c.ageBand)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text('رتب', style: RT.display(19, color: RC.onDarkSoft)),
            ),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final s in sets)
                _OrderChip(set: s, done: c.completed.contains(s.completionId), onTap: () => open(OrderGameScreen(set: s))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _OrderChip extends StatelessWidget {
  final OrderSet set;
  final bool done;
  final VoidCallback onTap;
  const _OrderChip({required this.set, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 74) / 2;
    return Semantics(
      button: true,
      label: 'رتب ${set.title}${done ? '، أنجزته' : ''}',
      excludeSemantics: true,
      child: Chunky(
        color: done ? const Color(0xFFE6F2EA) : Colors.white,
        radius: 20,
        depth: 4,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: SizedBox(
          width: w - 28,
          child: Row(children: [
            Expanded(child: Text(set.title, style: RT.display(16))),
            Text('${set.items.length}', style: RT.display(18, color: done ? _green : _gold)),
            if (done) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_circle_rounded, size: 18, color: _green)),
          ]),
        ),
      ),
    );
  }
}

/// رتب: سلم من خانات مرقمة يمتلئ من الأعلى، والبطاقات المخلوطة تحته.
class OrderGameScreen extends StatefulWidget {
  final OrderSet set;
  final Random? random;
  const OrderGameScreen({super.key, required this.set, this.random});

  @override
  State<OrderGameScreen> createState() => _OrderGameScreenState();
}

class _OrderGameScreenState extends State<OrderGameScreen> {
  late final OrderGame _g = OrderGame(widget.set.items, random: widget.random);
  String? _wrong;

  Future<void> _pick(String item) async {
    final ok = _g.pick(item);
    ok ? Haptics.tap() : Haptics.error();
    setState(() => _wrong = ok ? null : item);
    if (ok) Voice.instance.say(item);
    if (ok && _g.done) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final first = AppScope.read(context).complete(widget.set.completionId, stars: _g.stars);
      await showReward(context, stars: first ? _g.stars : 0, title: 'رتبت ${widget.set.title}!');
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.set;
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        KidBar(title: s.title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(s.prompt, textAlign: TextAlign.center, style: RT.display(20, color: RC.onDark)),
            const SizedBox(height: 12),
            for (var i = 0; i < s.items.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: i < _g.placed.length ? const Color(0xFFE6F2EA) : _paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == _g.placed.length ? _gold : RC.sandDark, width: i == _g.placed.length ? 2.5 : 1.5),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i < _g.placed.length ? _green : RC.sandDark,
                    child: Text('${i + 1}', style: RT.display(14, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i < _g.placed.length ? _g.placed[i] : '', style: RT.display(18, color: _ink)),
                  ),
                ]),
              ),
            const SizedBox(height: 14),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (final item in _g.shuffled)
                if (!_g.isPlaced(item))
                  Chunky(
                    key: ValueKey('ord_$item'),
                    color: _wrong == item ? const Color(0xFFFDE2E0) : Colors.white,
                    radius: 16,
                    depth: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => _pick(item),
                    child: Text(item, style: RT.display(17)),
                  ),
            ]),
            const SizedBox(height: 16),
            Text('المصدر: ${s.source}', textAlign: TextAlign.center, style: RT.body(13, color: RC.inkSoft)),
          ]),
        ),
      ]),
    );
  }
}

/// ذاكرة الأذكار: بطاقات مقلوبة، المناسبة بالأخضر والذكر بالذهبي.
class MemoryGameScreen extends StatefulWidget {
  final int band;
  final Random? random;
  const MemoryGameScreen({super.key, required this.band, this.random});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late final Random _r = widget.random ?? Random();
  late final List<DhikrPair> _pairs = ([...kDhikrPairs]..shuffle(_r)).take(widget.band == 0 ? 4 : 6).toList();
  late final MemoryGame _g = MemoryGame([for (final p in _pairs) (p.occasion, p.dhikr)], random: _r);
  Timer? _close;

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  Future<void> _flip(int i) async {
    if (_g.hasWrongPair) return;
    final res = _g.flip(i);
    if (res == null) return;
    setState(() {});
    if (res == true) {
      Haptics.success();
      final p = _pairs[_g.cards[i].pair];
      Voice.instance.say(p.dhikr);
      if (_g.done) {
        final first = AppScope.read(context).complete('memory_${todayKey()}', stars: _g.stars);
        await showReward(context, stars: first ? _g.stars : 0, title: 'حفظت أذكار اليوم!');
        if (mounted) Navigator.of(context).pop();
      }
    } else if (_g.hasWrongPair) {
      Haptics.error();
      _close = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(_g.closeWrong);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        const KidBar(title: 'ذاكرة الأذكار'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('اقلب بطاقتين: الوقت الأخضر وذكره الذهبي', textAlign: TextAlign.center, style: RT.body(15, color: RC.onDarkSoft)),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8),
            itemCount: _g.cards.length,
            itemBuilder: (_, i) {
              final card = _g.cards[i];
              final up = _g.isFaceUp(i);
              return Semantics(
                button: true,
                label: up ? card.text : 'بطاقة مقلوبة',
                excludeSemantics: true,
                child: Chunky(
                  key: ValueKey('mem_$i'),
                  color: !up ? _green : (card.matched ? const Color(0xFFE6F2EA) : (card.isOccasion ? const Color(0xFFDDEFE6) : const Color(0xFFFFF3D6))),
                  radius: 18,
                  depth: 4,
                  padding: const EdgeInsets.all(8),
                  onTap: () => _flip(i),
                  child: Center(
                    child: up
                        ? Text(card.text,
                            textAlign: TextAlign.center,
                            style: RT.display(card.text.length > 22 ? 13 : 16, color: card.isOccasion ? _green : const Color(0xFF7A5200)))
                        : const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white54, size: 34),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('المحاولات: ${_g.moves}', style: RT.body(15, color: RC.onDarkSoft)),
        ),
      ]),
    );
  }
}

/// السيرة: خط زمني رأسي بمحطات، ثم مسابقة.
class SeerahScreen extends StatelessWidget {
  const SeerahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final band = AppScope.of(context).current?.ageBand ?? 2;
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        const KidBar(title: 'السيرة النبوية'),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            for (var i = 0; i < kSeerah.length; i++)
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 34,
                    child: Column(children: [
                      Container(width: 4, height: 14, color: i == 0 ? Colors.transparent : _gold),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: _gold, width: 3)),
                      ),
                      Expanded(child: Container(width: 4, color: i == kSeerah.length - 1 ? Colors.transparent : _gold)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Voice.instance.say('${kSeerah[i].title}. ${kSeerah[i].body}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: RC.sandDark)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(kSeerah[i].when, style: RT.body(13, color: _gold, weight: FontWeight.w700)),
                            Text(kSeerah[i].title, style: RT.display(19)),
                            const SizedBox(height: 4),
                            Text(kSeerah[i].body, style: RT.body(16)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'مسابقة السيرة',
              icon: Icons.quiz_rounded,
              color: _green,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuizRunner(
                  title: 'مسابقة السيرة',
                  questions: kSeerahQuestions.where((q) => q.band <= band).toList(),
                  completionId: 'seerah_quiz',
                ),
              )),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// أسماء الله الحسنى: بطاقات تُقلب لتظهر المعنى وموضع الاسم في القرآن.
class GodNamesScreen extends StatefulWidget {
  const GodNamesScreen({super.key});

  @override
  State<GodNamesScreen> createState() => _GodNamesScreenState();
}

class _GodNamesScreenState extends State<GodNamesScreen> {
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        const KidBar(title: 'أسماء الله الحسنى'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('المس الاسم لتعرف معناه', textAlign: TextAlign.center, style: RT.body(15, color: RC.onDarkSoft)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05),
            itemCount: kGodNames.length,
            itemBuilder: (_, i) {
              final n = kGodNames[i];
              final open = _open.contains(i);
              return Chunky(
                key: ValueKey('name_$i'),
                color: open ? _paper : _green,
                radius: 22,
                depth: 5,
                padding: const EdgeInsets.all(12),
                onTap: () {
                  setState(() => open ? _open.remove(i) : _open.add(i));
                  if (!open) {
                    Voice.instance.say('${n.name}. ${n.meaning}');
                    if (_open.length == kGodNames.length) AppScope.read(context).complete('god_names', stars: 3);
                  }
                },
                child: Center(
                  child: open
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(n.name, style: RT.display(20, color: _green)),
                          const SizedBox(height: 4),
                          Text(n.meaning, textAlign: TextAlign.center, style: RT.body(14, color: _ink, weight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(n.where, style: RT.body(12, color: _gold)),
                        ])
                      : Text(n.name, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 34, color: Colors.white, height: 1.6)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// صح أم خطأ: عبارة واحدة كبيرة وزران، ثم السبب.
class TrueFalseScreen extends StatefulWidget {
  final Random? random;
  const TrueFalseScreen({super.key, this.random});

  @override
  State<TrueFalseScreen> createState() => _TrueFalseScreenState();
}

class _TrueFalseScreenState extends State<TrueFalseScreen> {
  late final List<TrueFalse> _items = ([...kTrueFalse]..shuffle(widget.random ?? Random())).take(10).toList();
  int _i = 0, _right = 0;
  bool? _answered;

  void _answer(bool v) {
    if (_answered != null) return;
    final ok = v == _items[_i].isTrue;
    if (ok) _right++;
    ok ? Haptics.success() : Haptics.error();
    setState(() => _answered = ok);
    Voice.instance.say(ok ? 'أحسنت' : 'انتبه');
  }

  Future<void> _next() async {
    if (_i + 1 >= _items.length) {
      final stars = _right >= 9 ? 3 : (_right >= 7 ? 2 : 1);
      AppScope.read(context).complete('truefalse_${todayKey()}', stars: stars);
      await showReward(context, stars: stars, title: 'عرفت $_right من ${_items.length}');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _i++;
      _answered = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _items[_i];
    return ChildShell(
      theme: SceneTheme.islamic,
      child: Column(children: [
        KidBar(title: 'صح أم خطأ ${_i + 1} / ${_items.length}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              constraints: const BoxConstraints(minHeight: 190),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _answered == null ? _paper : (_answered! ? const Color(0xFFE6F2EA) : const Color(0xFFFDE2E0)),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: RC.sandDark, width: 2),
              ),
              child: Text(t.text, textAlign: TextAlign.center, style: RT.display(26)),
            ),
            const SizedBox(height: 18),
            if (_answered == null)
              Row(children: [
                Expanded(child: PrimaryButton(label: 'صح', icon: Icons.check_rounded, color: _green, onTap: () => _answer(true))),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(label: 'خطأ', icon: Icons.close_rounded, color: const Color(0xFFB3412F), onTap: () => _answer(false))),
              ])
            else ...[
              Text(t.isTrue ? 'العبارة صحيحة' : 'العبارة خطأ',
                  textAlign: TextAlign.center, style: RT.display(20, color: t.isTrue ? _green : const Color(0xFFB3412F))),
              const SizedBox(height: 6),
              Text(t.why, textAlign: TextAlign.center, style: RT.body(17, color: RC.onDark)),
              const SizedBox(height: 16),
              PrimaryButton(label: _i + 1 >= _items.length ? 'إنهاء' : 'التالي', icon: Icons.arrow_forward_rounded, onTap: _next),
            ],
          ]),
        ),
      ]),
    );
  }
}
