import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/city/city.dart';

void main() {
  test('مدينتي: المستويات والدخل والرتب', () {
    final c = ChildProfile.fromJson(const {'id': 'a', 'name': 'سارة'});
    expect(cityLevel(c), 0);
    expect(incomeReady(c), false);
    c.counters['b_mosque'] = 2;
    c.counters['b_well'] = 1;
    expect(cityLevel(c), 3);
    expect(dailyIncome(c), 3);
    expect(incomeReady(c), true);
    c.counters['city_collect_${todayKey()}'] = 1;
    expect(incomeReady(c), false);
    expect(cityRank(0), 'قرية صغيرة');
    expect(cityRank(40), 'عاصمة العلم');
    expect(kBuildings.map((b) => b.key).toSet().length, kBuildings.length);
    for (final b in kBuildings) {
      for (var i = 1; i < b.costs.length; i++) {
        expect(b.costs[i], greaterThan(b.costs[i - 1]));
      }
    }
  });
}
