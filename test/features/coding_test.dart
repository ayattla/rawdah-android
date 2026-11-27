import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/coding/coding_domain.dart';

void main() {
  test('كل مستوى له حل صحيح، والاصطدام يكتشف', () {
    final r = Random(11);
    for (var level = 1; level <= 60; level++) {
      final l = makeLevel(level, r);
      final res = runProgram(l, l.solution);
      expect(res.reached, true, reason: 'level $level');
      expect(l.rocks.contains(l.target), false);
      expect(l.target == l.start, false);
    }
    const l = CodeLevel(4, Pos(0, 0), 0, Pos(3, 3), {}, []);
    expect(runProgram(l, [Cmd.forward]).crashed, true);
    expect(runProgram(l, [Cmd.right, Cmd.forward]).trail.last.$1, const Pos(1, 0));
  });
}
