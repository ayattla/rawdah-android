import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/perf/object_pool.dart';

class _Bullet {
  bool active = false;
}

void main() {
  test('المجمّع يعيد استخدام الكائنات بدل إنشاء جديدة', () {
    final pool = ObjectPool<_Bullet>(create: _Bullet.new, onRelease: (b) => b.active = false);
    // محاكاة 60 ثانية من اللعب: فانوس كل ثانية، يبقى 8 ثوانٍ على الشاشة
    final live = <_Bullet>[];
    for (var t = 0; t < 60; t++) {
      if (live.length >= 8) pool.release(live.removeAt(0));
      live.add(pool.acquire()..active = true);
    }
    expect(pool.created, 8, reason: 'أُنشئت 8 فقط طوال الجولة');
    expect(pool.reused, 52);
  });

  test('التهيئة المسبقة والحد الأقصى للمخزون', () {
    final pool = ObjectPool<_Bullet>(create: _Bullet.new, prewarm: 4, maxFree: 5);
    expect(pool.available, 4);
    expect(pool.created, 4);
    final items = [for (var i = 0; i < 10; i++) pool.acquire()];
    for (final b in items) {
      pool.release(b);
    }
    expect(pool.available, 5, reason: 'لا يحتفظ بأكثر من الحد');
  });
}
