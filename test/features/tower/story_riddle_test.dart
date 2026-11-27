import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/tower/domain/puzzles.dart';

void main() {
  test('مسائل السوق صحيحة وإجاباتها غير سالبة', () {
    final r = Random(7);
    for (var level = 1; level < 40; level++) {
      for (var k = 0; k < 20; k++) {
        final p = storyPuzzle(level, r);
        expect(p.answer, greaterThanOrEqualTo(0));
        expect(int.parse(p.options[p.answer]), greaterThanOrEqualTo(0));
        expect(p.options.toSet().length, p.options.length);
      }
    }
  });

  test('الأحاجي اختياراتها مميزة والجواب بينها', () {
    for (final x in kRiddles) {
      expect({x.$2, ...x.$3}.length, 3, reason: x.$1);
    }
    final r = Random(1);
    for (var level = 1; level < 30; level++) {
      final p = riddlePuzzle(level, r);
      expect(p.why, 'الجواب: ${p.options[p.answer]}');
    }
  });
}
