import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/planets/data/planets_content.dart';
import 'package:rawdah/features/science/data/science_content.dart';

void main() {
  test('محتوى الكواكب سليم ومعرفاته لا تتكرر', () {
    final all = [...kTarikhTopics, ...kMaarifaTopics, ...kZumurrudaTopics, ...kRiyadaTopics];
    final ids = <String>{...kQuestions.map((q) => q.id), for (final t in kScienceTopics) ...t.questions.map((q) => q.id)};
    final topicIds = <String>{for (final t in kScienceTopics) t.id};
    for (final t in all) {
      expect(topicIds.add(t.id), true, reason: t.id);
      expect(t.cards.length, greaterThanOrEqualTo(4), reason: t.id);
      for (final q in t.questions) {
        expect(ids.add(q.id), true, reason: q.id);
        expect(q.answer, inInclusiveRange(0, q.options.length - 1));
        expect(q.options.toSet().length, q.options.length, reason: q.id);
      }
    }
  });

  test('التمارين والأشكال', () {
    expect(exercisesFor(0).every((e) => e.minBand == 0), true);
    expect(exercisesFor(2).length, kExercises.length);
    expect(kExercises.every((e) => e.seconds >= 10 && e.seconds <= 60), true);
    expect(kShapes.map((s) => s.name).toSet().length, kShapes.length);
  });
}
