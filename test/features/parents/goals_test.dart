import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/parents/domain/goals.dart';

void main() {
  test('هدف ولي الأمر يقاس من بعد لحظة وضعه', () {
    final c = ChildProfile.fromJson(const {'id': 'x', 'name': 'سارة'});
    expect(goalOf(c), isNull);
    c.counters['total_tower'] = 7;
    setGoal(c, goalKindById('tower')!, 10, 20);
    final g = goalOf(c)!;
    expect(g.progress(c), 0);
    c.counters['total_tower'] = 12;
    expect(g.progress(c), 5);
    expect(g.done(c), false);
    c.counters['total_tower'] = 30;
    expect(g.progress(c), 10);
    expect(g.done(c), true);
    expect(g.reward, 20);
    expect(g.text, contains('10'));
    clearGoal(c);
    expect(goalOf(c), isNull);
    expect(goalKindById('zzz'), isNull);
    c.counters['goal_kind'] = 99;
    expect(goalOf(c), isNull);
  });

  test('نشاط الأسبوع سبعة أيام', () {
    final c = ChildProfile.fromJson(const {'id': 'x', 'name': 'سارة'});
    final now = DateTime(2026, 11, 27);
    c.counters['dq_${todayKey(now)}_correct'] = 4;
    final w = weekActivity(c, now);
    expect(w.length, 7);
    expect(w.last.$2, 4);
    expect(DateTime.parse(w.first.$1).isBefore(now), true);
  });
}
