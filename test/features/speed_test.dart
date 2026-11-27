import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/quizzes/data/generated_questions.dart';
import 'package:rawdah/features/speed/speed.dart';

void main() {
  test('مسائل السرعة صحيحة والخيار الصحيح موجود', () {
    final r = Random(4);
    for (var band = 0; band < 3; band++) {
      for (var k = 0; k < 200; k++) {
        final q = quickMath(band, r);
        expect(q.$2.contains(q.$3), true);
        expect(q.$2.toSet().length, 3);
        expect(q.$3, greaterThanOrEqualTo(0));
      }
    }
    final t = quickMath(1, r, table: 7);
    expect(t.$3 % 7, 0);
  });

  test('بنك العواصم والضرب', () {
    final cap = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_cap_0');
    expect(cap.options[cap.answer], 'الرياض');
    final m = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_mul_7_8');
    expect(m.options[m.answer], '56');
    expect(kGeneratedQuestions.where((q) => q.id.startsWith('gen_cap_')).length, kCapitals.length);
  });
}
