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
class IslamicHubScreen extends StatelessWidget {
  const IslamicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final sets = kOrderSets.where((s) => s.minBand <= c.ageBand).toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ركن المسلم الصغير'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            BigTile(
              title: 'السيرة النبوية',
              subtitle: '${kSeerah.length} محطات من حياة النبي ﷺ',
              icon: Icons.route_rounded,
              color: _green,
              done: c.completed.contains('seerah_quiz'),
              onTap: () => open(const SeerahScreen()),
            ),
            const SizedBox(height: 12),
            BigTile(
              title: 'ذاكرة الأذكار',
              subtitle: 'اقلب البطاقات وطابق الذكر بوقته',
              icon: Icons.style_rounded,
              color: _gold,
              onTap: () => open(MemoryGameScreen(band: c.ageBand)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text('رتّب', style: RT.display(19, color: RC.inkSoft)),
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
    final w = (MediaQuery.sizeOf(context).width - 42) / 2;
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

/// رتّب: سلّم من خانات مرقمة يمتلئ من الأعلى، والبطاقات المخلوطة تحته.
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
      child: Column(children: [
        KidBar(title: s.title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(s.prompt, textAlign: TextAlign.center, style: RT.display(20)),
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
      final p = _pairs[_g.cards[i].pair];
      Voice.instance.say(p.dhikr);
      if (_g.done) {
        final first = AppScope.read(context).complete('memory_${todayKey()}', stars: _g.stars);
        await showReward(context, stars: first ? _g.stars : 0, title: 'حفظت أذكار اليوم!');
        if (mounted) Navigator.of(context).pop();
      }
    } else if (_g.hasWrongPair) {
      _close = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(_g.closeWrong);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ذاكرة الأذكار'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('اقلب بطاقتين: الوقت الأخضر وذكره الذهبي', textAlign: TextAlign.center, style: RT.body(15, color: RC.inkSoft)),
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
          child: Text('المحاولات: ${_g.moves}', style: RT.body(15, color: RC.inkSoft)),
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
