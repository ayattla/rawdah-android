import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/encyclopedia/encyclopedia.dart';
import 'package:rawdah/features/race/daily_race.dart';

void main() {
  test('سباق اليوم: نفس الأسئلة للجميع والترتيب صحيح', () {
    final d = DateTime(2026, 11, 28);
    final a = raceQuestions(d, 1), b = raceQuestions(d, 1);
    expect(a.length, 10);
    expect(a.map((q) => q.id).toList(), b.map((q) => q.id).toList());
    expect(raceKey(d, 2), 'd20261128_b2');
    final r = rankRace(const [RaceEntry('أ', 'star', 7, 30000, false), RaceEntry('ب', 'moon', 9, 50000, false), RaceEntry('ج', 'sun', 9, 40000, true)]);
    expect(r.map((e) => e.nick).toList(), ['ج', 'ب', 'أ']);
  });

  test('الموسوعة: أربعة رفوف بلا تكرار', () {
    expect(kEncShelves.length, 4);
    for (final s in kEncShelves) {
      expect(s.facts.toSet().length, s.facts.length, reason: s.id);
      expect(s.facts.length, 12);
    }
  });
}
