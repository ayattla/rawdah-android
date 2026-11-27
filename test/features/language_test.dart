import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/language/language_data.dart';
import 'package:rawdah/features/quizzes/data/generated_questions.dart';
import 'package:rawdah/features/tower/domain/puzzles.dart';

void main() {
  test('بنك اللغة صحيح', () {
    expect(kOpposites.map((e) => e.$1).toSet().length, kOpposites.length);
    final q = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_opp_0');
    expect(q.options[q.answer], 'صغير');
    final pl = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_pl_2');
    expect(pl.options[pl.answer], 'مساجد');
    final sh = kGeneratedQuestions.firstWhere((q) => q.id == 'gen_shape_5');
    expect(sh.options[sh.answer], '6');
    final ids = kGeneratedQuestions.map((q) => q.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('لغز الكلمات: الخيارات مختلفة والجواب بينها', () {
    final r = Random(5);
    for (var level = 1; level < 30; level++) {
      final p = wordsPuzzle(level, r);
      expect(p.options.toSet().length, p.options.length);
      expect(p.answer, inInclusiveRange(0, p.options.length - 1));
    }
  });
}
