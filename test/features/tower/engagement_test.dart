import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/daily/domain/quests.dart';
import 'package:rawdah/features/quizzes/domain/mastery.dart';
import 'package:rawdah/features/tower/domain/puzzles.dart';

int _solve(String t) {
  final m = RegExp(r'^(\d+) (.) ؟ = (\d+)$').firstMatch(t.substring(1, t.length - 1));
  if (m != null) {
    final a = int.parse(m[1]!), c = int.parse(m[3]!);
    return switch (m[2]) { '+' => c - a, '−' => a - c, '÷' => a ~/ c, _ => c ~/ a };
  }
  final d = RegExp(r'^(\d+) ÷ ؟ = (\d+)$').firstMatch(t.substring(1, t.length - 1))!;
  return int.parse(d[1]!) ~/ int.parse(d[2]!);
}

void main() {
  group('الإتقان', () {
    test('الصناديق تصعد بالصح وتعود بالخطأ', () {
      var m = masteryAfter(null, true, 100);
      expect(m, [1, 101]);
      m = masteryAfter(m, true, 101);
      expect(m, [2, 103]);
      m = masteryAfter(m, false, 103);
      expect(m, [0, 103]);
      for (var i = 0; i < 6; i++) {
        m = masteryAfter(m, true, 200);
      }
      expect(m[0], kMasteryGaps.length - 1);
      expect(isMastered(m), true);
      expect(isMastered(null), false);
    });

    test('الاختيار الذكي يقدم المستحق والجديد ويؤخر المتقن', () {
      final pool = [for (var i = 0; i < 20; i++) Question('q$i', 0, 's', const ['a', 'b'], 0, '')];
      final mastery = <String, List<int>>{
        for (var i = 0; i < 10; i++) 'q$i': [5, 999], // متقن
        'q10': [1, 50], // مستحق
        'q11': [2, 50],
      };
      final pick = smartPick(pool, mastery, 100, count: 5, random: Random(1));
      expect(pick.length, 5);
      expect(pick.map((q) => q.id), containsAll(['q10', 'q11']));
      expect(pick.where((q) => isMastered(mastery[q.id])), isEmpty);
      expect(masteryRatio(pool, mastery), 0.5);
      expect(masteryRatio(const [], mastery), 0);
      expect(smartPick(pool.take(3).toList(), mastery, 100, count: 5).length, 3);
    });
  });

  group('برج الألغاز', () {
    test('أكمل النمط والميزان صحيحان في كل المستويات', () {
      final r = Random(3);
      for (var level = 1; level <= 40; level++) {
        for (var k = 0; k < 5; k++) {
          final s = sequencePuzzle(level, r);
          expect(s.answer, isNot(-1));
          expect(s.options.toSet().length, s.options.length);
          final b = balancePuzzle(level, r);
          expect(int.parse(b.options[b.answer]), _solve(b.shown.first), reason: b.shown.first);
          final o = oddOnePuzzle(level, r);
          expect(o.options.toSet().length, o.options.length);
          expect(o.why, contains(o.options[o.answer]));
        }
      }
    });

    test('النمط الحسابي يعطي الرقم التالي الصحيح', () {
      final s = sequencePuzzle(1, Random(7));
      final nums = s.shown.map(int.parse).toList();
      final step = nums[1] - nums[0];
      expect(int.parse(s.options[s.answer]), nums.last + step);
    });

    test('رتب الحروف والسودوكو', () {
      final r = Random(5);
      for (var level = 1; level <= 30; level++) {
        final w = scramblePuzzle(level, r);
        expect(w.tiles.join().runes.toList()..sort(), w.word.runes.toList()..sort());
        final s = sudokuPuzzle(level, r);
        expect(Sudoku4.validSolution(s.solution), true);
        expect(s.given.where((g) => !g).length, min(4 + level ~/ 2, 10));
      }
      expect(Sudoku4.validSolution(List.filled(16, 1)), false);
      expect(floorName(1), isNotEmpty);
      expect(floorName(50), 'قمة البرج');
      expect(TowerGame.sudoku.perLevel, 1);
      expect(kScrambleWords.toSet().length, kScrambleWords.length);
    });
  });

  test('رحلة اليوم: أربع مهام تتغير وتصعب', () {
    final a = questsFor(DateTime(2026, 11, 27), level: 1);
    expect(a.length, 4);
    expect(a.map((q) => q.kind).toSet(), containsAll(['correct', 'tower', 'activity']));
    expect(questsFor(DateTime(2026, 11, 27), level: 1, hasHifz: true).last.kind, 'review');
    final hard = questsFor(DateTime(2026, 11, 27), level: 20);
    expect(hard.first.goal, greaterThanOrEqualTo(a.first.goal));
    expect(chestStars(a), greaterThan(10));
  });
}
