import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/core/storage/parental_store.dart';

void main() {
  test('ترحيل التقدم من SharedPreferences القديم إلى Hive مرة واحدة', () async {
    SharedPreferences.setMockInitialValues({
      'rawdah_state_v1': '{"consentGiven":true,"voiceOn":false,"children":[]}',
    });
    final local = MemoryLocalStore();
    final st = AppState(parental: MemoryParentalStore(), local: local);
    await st.load();
    expect(st.consentGiven, isTrue);
    expect(st.voiceOn, isFalse);
    expect(local.data.containsKey('rawdah_state_v1'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('rawdah_state_v1'), isNull, reason: 'يُحذف من القديم بعد الترحيل');
    st.pauseClock();
  });

  test('إعدادات الوالدين تُحفظ في المخزن المشفّر وتُحذف من الملف العادي', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryParentalStore();
    final local = MemoryLocalStore();
    final st = AppState(parental: store, local: local);
    await st.load();
    st.giveConsent();
    final c = st.addChild('سارة', 'moon', 1);
    c.dailyLimitMinutes = 45;
    c.onlineEnabled = true;
    c.nick = 'نجم الهدى';
    await st.save();

    final raw = (await local.read('rawdah_state_v1'))!;
    expect(raw.contains('dailyLimitMinutes'), isFalse);
    expect(raw.contains('نجم الهدى'), isFalse);
    expect(raw.contains('consentGiven'), isFalse);

    final secured = (await store.read())!;
    expect(secured['consent'], isTrue);

    // تحميل جديد يستعيد الإعدادات من المخزن المشفّر
    final again = AppState(parental: store, local: local);
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
