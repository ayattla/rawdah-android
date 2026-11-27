import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/badges/badges.dart';
import 'package:rawdah/features/ladder/ladder.dart';
import 'package:rawdah/features/tower/domain/puzzles.dart';

void main() {
  test('سلم المعرفة فيه ١١ سؤال بلا تكرار لكل الأعمار', () {
    for (var band = 0; band < 3; band++) {
      final qs = ladderQuestions(band, Random(band));
      expect(qs.length, 11);
      expect(qs.map((q) => q.id).toSet().length, 11);
      expect(qs.every((q) => q.band <= band), true);
    }
    expect(kLadderPrizes.length, 10);
  });

  test('درجات الأوسمة', () {
    final c = ChildProfile.fromJson(const {'id': 'a', 'name': 'سارة'});
    expect(totalTiers(c), 0);
    c.counters['total_correct'] = 250;
    final t = kBadgeTracks.first;
    expect(tierOf(t, t.value(c)), 2);
    c.counters['total_correct'] = 5000;
    expect(tierOf(t, t.value(c)), 4);
  });

  test('ألغاز المقارنة والحرف الناقص صحيحة', () {
    final r = Random(9);
    for (var level = 1; level < 30; level++) {
      final p = comparePuzzle(level, r);
      expect(p.shown.length, 2);
      expect(p.answer, inInclusiveRange(0, 2));
      final m = missingPuzzle(level, r);
      final word = m.why.substring('الكلمة: '.length);
      expect(word, m.shown.first.replaceFirst('_', m.options[m.answer]));
      expect(m.options.toSet().length, 3);
    }
  });
}
