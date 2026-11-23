import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/design_system/design_system.dart';

void main() {
  Future<double> scaleWith(WidgetTester t, {required double system, required double app}) async {
    late double result;
    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(system)),
      child: A11yScope(
        appTextScale: app,
        highContrast: false,
        reduceMotion: false,
        child: Builder(builder: (context) {
          result = MediaQuery.textScalerOf(context).scale(10) / 10;
          return const SizedBox();
        }),
      ),
    ));
    return result;
  }

  testWidgets('تكبير الخط يجمع إعداد الجهاز والتطبيق بحد أقصى 1.6', (t) async {
    expect(await scaleWith(t, system: 1.0, app: 1.0), 1.0);
    expect(await scaleWith(t, system: 1.0, app: 1.3), closeTo(1.3, 0.001));
    expect(await scaleWith(t, system: 1.5, app: 1.3), A11yScope.maxScale);
    expect(await scaleWith(t, system: 0.8, app: 1.0), 1.0, reason: 'لا يصغر الخط عن الحجم المصمم');
  });

  testWidgets('التباين العالي من التطبيق أو من النظام', (t) async {
    late bool hc;
    Widget probe() => Builder(builder: (c) {
          hc = A11y.highContrastOf(c);
          return const SizedBox();
        });
    await t.pumpWidget(const MediaQuery(data: MediaQueryData(), child: A11y(highContrast: true, reduceMotion: false, child: SizedBox())));
    await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(), child: A11y(highContrast: true, reduceMotion: false, child: probe())));
    expect(hc, isTrue);
    await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: A11y(highContrast: false, reduceMotion: false, child: probe())));
    expect(hc, isTrue);
  });

  test('ألوان البلاطات تحقق تباين 4.5:1 مع النص الأبيض', () {
    double lum(Color c) => c.computeLuminance();
    double ratio(Color a, Color b) {
      final x = lum(a), y = lum(b);
      return (([x, y]..sort()).last + 0.05) / (([x, y]..sort()).first + 0.05);
    }

    for (final c in [RC.green, RC.goldDark, RC.sea, RC.coral, RC.plum, RC.ink, RC.night, RC.garden, RC.rose]) {
      expect(ratio(c, Colors.white), greaterThanOrEqualTo(4.5), reason: c.toString());
    }
    expect(ratio(RC.inkSoft, RC.sand), greaterThanOrEqualTo(7));
  });
}
