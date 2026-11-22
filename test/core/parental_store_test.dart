import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/parental_store.dart';

void main() {
  test('إعدادات الوالدين تُحفظ في المخزن المشفّر وتُحذف من الملف العادي', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryParentalStore();
    final st = AppState(parental: store);
    await st.load();
    st.giveConsent();
    final c = st.addChild('سارة', 'moon', 1);
    c.dailyLimitMinutes = 45;
    c.onlineEnabled = true;
    c.nick = 'نجم الهدى';
    await st.save();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rawdah_state_v1')!;
    expect(raw.contains('dailyLimitMinutes'), isFalse);
    expect(raw.contains('نجم الهدى'), isFalse);
    expect(raw.contains('consentGiven'), isFalse);

    final secured = (await store.read())!;
    expect(secured['consent'], isTrue);

    // تحميل جديد يستعيد الإعدادات من المخزن المشفّر
    final again = AppState(parental: store);
    await again.load();
    final k = again.children.single;
    expect(again.consentGiven, isTrue);
    expect(k.dailyLimitMinutes, 45);
    expect(k.onlineEnabled, isTrue);
    expect(k.nick, 'نجم الهدى');
    again.pauseClock();
    st.pauseClock();
  });
}
