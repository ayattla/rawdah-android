import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/cards/cards.dart';

void main() {
  test('الألبوم: مجموعات كاملة وأسماء فريدة', () {
    expect(totalCards(), 40);
    for (final s in kCardSets) {
      expect(s.cards.length, 8);
      expect(s.cards.map((e) => e.$1).toSet().length, 8);
    }
    expect(kCardSets.map((s) => s.id).toSet().length, kCardSets.length);
    expect(weekKey(DateTime(2026, 11, 27)), '2026-11-21');
    expect(cardId('planets', 3), 'card_planets_3');
    expect(Random(1).nextInt(3), isNonNegative);
  });
}
