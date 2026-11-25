import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/islamic/data/islamic_content.dart';
import 'package:rawdah/features/islamic/domain/games.dart';

void main() {
  test('مجموعات الترتيب سليمة', () {
    final ids = <String>{};
    for (final s in kOrderSets) {
      expect(ids.add(s.id), true);
      expect(s.items.toSet().length, s.items.length, reason: s.id);
      expect(s.source, isNotEmpty);
      expect(s.completionId, 'order_${s.id}');
    }
    expect(kOrderSets.firstWhere((s) => s.id == 'islam').items.length, 5);
    expect(kOrderSets.firstWhere((s) => s.id == 'iman').items.length, 6);
    expect(kDhikrPairs.every((p) => p.source.isNotEmpty), true);
    expect(kDhikrPairs.map((p) => p.dhikr).toSet().length, kDhikrPairs.length);
    expect(kSeerah.length, greaterThanOrEqualTo(6));
    expect(kSeerahQuestions.map((q) => q.id).toSet().length, kSeerahQuestions.length);
  });

  test('لعبة الترتيب', () {
    final g = OrderGame(const ['أ', 'ب', 'ج'], random: Random(1));
    expect(g.shuffled, isNot(['أ', 'ب', 'ج']));
    expect(g.shuffled.toSet(), {'أ', 'ب', 'ج'});
    expect(g.pick('ب'), false);
    expect(g.mistakes, 1);
    expect(g.pick('أ'), true);
    expect(g.pick('أ'), false);
    expect(g.isPlaced('أ'), true);
    expect(g.next, 'ب');
    g.pick('ب');
    g.pick('ج');
    expect(g.done, true);
    expect(g.next, isNull);
    expect(g.pick('ج'), false);
    expect(g.stars, 2);
    expect(OrderGame(const ['x']).shuffled, ['x']);
  });

  test('لعبة الذاكرة', () {
    final g = MemoryGame(const [('a', '1'), ('b', '2')], random: Random(2));
    expect(g.cards.length, 4);
    int idx(String t) => g.cards.indexWhere((c) => c.text == t);
    expect(g.flip(idx('a')), false);
    expect(g.flip(idx('a')), isNull); // مفتوحة
    expect(g.flip(idx('2')), false);
    expect(g.hasWrongPair, true);
    expect(g.flip(idx('b')), isNull); // يجب الإغلاق أولًا
    g.closeWrong();
    expect(g.flip(idx('a')), false);
    expect(g.flip(idx('1')), true);
    expect(g.isFaceUp(idx('1')), true);
    expect(g.flip(idx('b')), false);
    expect(g.flip(idx('2')), true);
    expect(g.done, true);
    expect(g.moves, 3);
    expect(g.stars, 3);
    expect(g.flip(99), isNull);
  });
}
