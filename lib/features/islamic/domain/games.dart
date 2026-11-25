import 'dart:math';

/// لعبة الترتيب: يلمس الطفل العناصر بالترتيب الصحيح من مجموعة مخلوطة.
class OrderGame {
  final List<String> correct;
  final List<String> shuffled;
  final List<String> placed = [];
  int mistakes = 0;

  OrderGame(this.correct, {Random? random}) : shuffled = _shuffle(correct, random ?? Random());

  static List<String> _shuffle(List<String> items, Random r) {
    if (items.length < 2) return [...items];
    var s = [...items];
    // لا نعرضها بترتيبها الصحيح من البداية
    do {
      s = [...items]..shuffle(r);
    } while (_same(s, items));
    return s;
  }

  static bool _same(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get done => placed.length == correct.length;
  String? get next => done ? null : correct[placed.length];
  bool isPlaced(String item) => placed.contains(item);

  bool pick(String item) {
    if (done || isPlaced(item)) return false;
    if (item != next) {
      mistakes++;
      return false;
    }
    placed.add(item);
    return true;
  }

  int get stars => mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1);
}

/// لعبة الذاكرة: بطاقات مقلوبة، كل زوج = مناسبة وذكرها.
class MemoryCard {
  final int pair;
  final String text;
  final bool isOccasion;
  bool matched = false;
  MemoryCard(this.pair, this.text, this.isOccasion);
}

class MemoryGame {
  final List<MemoryCard> cards;
  final List<int> open = [];
  int moves = 0;

  MemoryGame(List<(String, String)> pairs, {Random? random})
      : cards = [
          for (var i = 0; i < pairs.length; i++) ...[MemoryCard(i, pairs[i].$1, true), MemoryCard(i, pairs[i].$2, false)],
        ]..shuffle(random ?? Random());

  bool get done => cards.every((c) => c.matched);
  bool isFaceUp(int i) => cards[i].matched || open.contains(i);

  /// يقلب بطاقة. يعيد true إن اكتمل زوج صحيح، false إن لم يكتمل، null إن كانت الحركة مرفوضة.
  /// بعد زوج خاطئ تبقى البطاقتان مفتوحتين حتى [closeWrong].
  bool? flip(int i) {
    if (i < 0 || i >= cards.length || isFaceUp(i) || open.length >= 2) return null;
    open.add(i);
    if (open.length < 2) return false;
    moves++;
    final a = cards[open[0]], b = cards[open[1]];
    if (a.pair == b.pair) {
      a.matched = b.matched = true;
      open.clear();
      return true;
    }
    return false;
  }

  bool get hasWrongPair => open.length == 2;
  void closeWrong() => open.clear();

  int get stars {
    final pairs = cards.length ~/ 2;
    if (moves <= pairs + 2) return 3;
    if (moves <= pairs * 2) return 2;
    return 1;
  }
}
