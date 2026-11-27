import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/shop/economy.dart';

ChildProfile kid() => ChildProfile.fromJson(const {'id': 'a', 'name': 'سارة'});

void main() {
  test('تقويم المكافأة يتقدم يوميا ويرجع لو انقطع', () {
    final c = kid();
    final d1 = DateTime(2026, 11, 1);
    expect(calendarDayToClaim(c, d1), 0);
    c.counters['cal_day'] = 1;
    c.counters['cal_last'] = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 86400000;
    expect(calendarDayToClaim(c, d1), -1);
    expect(calendarDayToClaim(c, DateTime(2026, 11, 2)), 1);
    expect(calendarDayToClaim(c, DateTime(2026, 11, 4)), 0);
    c.counters['cal_day'] = 7;
    expect(calendarDayToClaim(c, DateTime(2026, 11, 2)), 0);
  });

  test('بداية الأسبوع السبت وعداد التحدي', () {
    expect(weekStart(DateTime(2026, 11, 27)).weekday, DateTime.saturday);
    expect(weekStart(DateTime(2026, 11, 28)), DateTime(2026, 11, 28));
    final c = kid();
    c.counters['dq_2026-11-22_correct'] = 40;
    c.counters['dq_2026-11-26_correct'] = 70;
    c.counters['dq_2026-11-20_correct'] = 500; // الأسبوع الماضي
    expect(weekCount(c, 'correct', DateTime(2026, 11, 27)), 110);
  });

  test('جوائز الأوسمة تحسب الدرجات غير المستلمة', () {
    final c = kid();
    c.counters['total_correct'] = 250; // درجتان
    expect(badgeUnclaimed(c, 0), 2);
    expect(badgePrize(c, 0), 20 + 40);
    c.counters['bdg_0'] = 1;
    expect(badgePrize(c, 0), 40);
  });

  test('عرض اليوم ثابت وسعره أقل', () {
    final a = dealOfDay(DateTime(2026, 5, 3, 8));
    expect(dealOfDay(DateTime(2026, 5, 3, 22)).id, a.id);
    expect(dealPrice(a), lessThan(a.price));
    expect(allCosmetics().map((x) => x.id).toSet().length, allCosmetics().length);
    expect(kSkies.first.price, 0);
  });
}
