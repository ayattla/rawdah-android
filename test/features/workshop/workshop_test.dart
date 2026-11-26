import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/episodes/episodes.dart';
import 'package:rawdah/features/workshop/workshop_domain.dart';

void main() {
  test('مسلسل الحلقات: أكثر من شهرين وحلقة واحدة في اليوم', () {
    expect(kEpisodes.length, greaterThan(60));
    expect(kEpisodes.every((e) => e.title.isNotEmpty && e.body.isNotEmpty), true);
    expect(nextEpisodeOpen(0, 0, 10), true);
    expect(nextEpisodeOpen(3, 10, 10), false);
    expect(nextEpisodeOpen(3, 9, 10), true);
    expect(nextEpisodeOpen(kEpisodes.length, 0, 10), false);
  });

  test('ألغاز الكهرباء صحيحة', () {
    final r = Random(2);
    for (var level = 1; level <= 20; level++) {
      for (var k = 0; k < 6; k++) {
        final p = circuitPuzzle(level, r);
        expect(p.answer, inInclusiveRange(0, p.options.length - 1));
        expect(p.options.toSet().length, p.options.length);
        if (p.prompt.startsWith('بطارية')) expect(kConductors, contains(p.options[p.answer]));
        if (p.prompt.startsWith('هل تمر')) {
          expect(p.answer == 0, kConductors.contains(p.detail));
        }
      }
    }
    expect(kConductors.toSet().intersection(kInsulators.toSet()), isEmpty);
    expect(promptOfDay(DateTime(2026, 11, 27)), isNotEmpty);
    expect(kMachinesTopic.cards.length, 6);
  });
}
