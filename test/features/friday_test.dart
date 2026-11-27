import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/friday/friday.dart';

void main() {
  test('بطولة الجمعة: يوم ثابت وأسئلة ثابتة', () {
    expect(isFriday(DateTime(2026, 11, 27)), true);
    expect(isFriday(DateTime(2026, 11, 28)), false);
    final a = fridayQuestions(1, DateTime(2026, 11, 27));
    final b = fridayQuestions(1, DateTime(2026, 11, 27));
    expect(a.length, 15);
    expect(a.map((q) => q.id).toList(), b.map((q) => q.id).toList());
    expect(a.map((q) => q.id).toSet().length, 15);
    expect(fridayPrize(15), 100);
    expect(fridayPrize(5), 20);
  });
}
