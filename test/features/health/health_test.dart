import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/health/health_domain.dart';

void main() {
  test('الطبق الصحي بلا تكرار ونصيحة كل يوم ثابتة', () {
    final round = plateRound(Random(3));
    expect(round.length, 8);
    expect(round.map((e) => e.$1).toSet().length, 8);
    expect(kFoods.map((e) => e.$1).toSet().length, kFoods.length);
    expect(tipOfDay(DateTime(2026, 5, 1)), tipOfDay(DateTime(2026, 5, 1)));
    expect(tipOfDay(DateTime(2026, 5, 1)) == tipOfDay(DateTime(2026, 5, 2)), false);
  });
}
