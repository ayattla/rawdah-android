import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/choices/choices_domain.dart';

void main() {
  test('المواقف سليمة وكل قسم فيه جولة', () {
    expect(kSituations.map((s) => s.id).toSet().length, kSituations.length);
    for (final s in kSituations) {
      expect(s.answer, inInclusiveRange(0, s.options.length - 1), reason: s.id);
      expect(kSituationTopics.contains(s.topic), true, reason: s.id);
    }
    for (final t in kSituationTopics) {
      final r = situationRound(t, Random(2));
      expect(r.length, greaterThanOrEqualTo(4), reason: t);
      expect(r.map((s) => s.id).toSet().length, r.length);
    }
  });
}
