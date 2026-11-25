import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/quizzes/domain/math_questions.dart';

int _solve(String t) {
  expect(t.startsWith('\u202A') && t.endsWith('\u202C'), true);
  final m = RegExp(r'^(\d+) (.) (\d+) = ؟$').firstMatch(t.substring(1, t.length - 1))!;
  final a = int.parse(m[1]!), b = int.parse(m[3]!);
  return switch (m[2]) { '+' => a + b, '−' => a - b, '×' => a * b, _ => a ~/ b };
}

void main() {
  for (final band in [0, 1, 2]) {
    test('أسئلة الحساب صحيحة للفئة $band', () {
      for (var seed = 0; seed < 30; seed++) {
        final qs = mathQuestions(band, count: 10, random: Random(seed));
        expect(qs.length, 10);
        expect(qs.map((q) => q.text).toSet().length, 10);
        for (final q in qs) {
          final ans = _solve(q.text);
          expect(int.parse(q.options[q.answer]), ans, reason: q.text);
          expect(q.options.toSet().length, 3, reason: q.text);
          expect(q.options.every((o) => int.parse(o) >= 0), true);
          expect(q.band, band);
          if (band == 0) expect(ans, inInclusiveRange(0, 10));
          if (band == 1) expect(ans, inInclusiveRange(0, 99));
        }
      }
    });
  }

  test('الفئة خارج الحدود تُصحح ولا تتعطل', () {
    expect(mathQuestions(9, count: 3, random: Random(1)).length, 3);
    expect(mathQuestions(-1, count: 3, random: Random(1)).length, 3);
    expect(mathQuestions(0).length, 10);
  });
}
