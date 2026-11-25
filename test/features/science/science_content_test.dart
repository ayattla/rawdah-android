import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/science/data/science_content.dart';

void main() {
  test('محتوى العلوم سليم', () {
    final ids = <String>{};
    for (final t in kScienceTopics) {
      expect(t.cards.length, greaterThanOrEqualTo(4), reason: t.id);
      expect(t.reflection, isNotEmpty);
      expect(t.completionId, 'science_${t.id}');
      for (final b in {0, 1, 2}) {
        expect(t.questions.any((q) => q.band == b), true, reason: '${t.id} band $b');
      }
      for (final q in t.questions) {
        expect(ids.add(q.id), true, reason: q.id);
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
        expect(q.options.toSet().length, q.options.length, reason: q.id);
      }
    }
    // لا تتصادم مع معرّفات الأسئلة العامة
    expect(kQuestions.map((q) => q.id).toSet().intersection(ids), isEmpty);
  });

  test('أسئلة الفئة تشمل ما دونها', () {
    final small = scienceQuestionsFor(0);
    final big = scienceQuestionsFor(2);
    expect(small.every((q) => q.band == 0), true);
    expect(big.length, kScienceTopics.fold<int>(0, (n, t) => n + t.questions.length));
    expect(big.length, greaterThan(small.length));
  });
}
