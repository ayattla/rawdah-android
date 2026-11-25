import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/core/storage/parental_store.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';

void main() {
  group('جدول المراجعة', () {
    test('رقم اليوم يتجاهل الساعة', () {
      expect(dayNumber(DateTime(2026, 11, 25, 1)), dayNumber(DateTime(2026, 11, 25, 23)));
      expect(dayNumber(DateTime(2026, 11, 26)) - dayNumber(DateTime(2026, 11, 25)), 1);
    });

    test('المراجعة الناجحة تبعد الموعد والتعثّر يعيده للغد', () {
      var e = HifzEntry.memorized(105, 100);
      expect(e.due, 101);
      expect(e.isDue(100), false);
      expect(e.isDue(101), true);
      e = e.review(ok: true, today: 101);
      expect([e.level, e.due, e.reviews], [1, 104, 1]);
      for (var i = 0; i < 10; i++) {
        e = e.review(ok: true, today: e.due);
      }
      expect(e.level, kHifzMaxLevel);
      expect(e.mastered, true);
      expect(e.strength, 1);
      e = e.review(ok: false, today: 500);
      expect([e.level, e.due], [0, 501]);
      expect(e.mastered, false);
    });

    test('ترتيب المستحق: الأكثر تأخرًا ثم الأضعف', () {
      const a = HifzEntry(1, level: 3, due: 98);
      const b = HifzEntry(2, level: 1, due: 100);
      const c = HifzEntry(3, level: 0, due: 100);
      const d = HifzEntry(4, level: 0, due: 105);
      expect(dueToday([d, b, c, a], 100).map((e) => e.surah), [1, 3, 2]);
      expect(a.overdueDays(100), 2);
    });

    test('التحويل من وإلى JSON مع تجاهل التالف', () {
      const e = HifzEntry(112, level: 2, due: 300, reviews: 4);
      expect(HifzEntry.fromJson('112', e.toJson()), e);
      expect(HifzEntry.fromJson('x', e.toJson()), isNull);
      expect(HifzEntry.fromJson('1', 'bad'), isNull);
      expect(HifzEntry.fromJson('1', [9, 5]), const HifzEntry(1, level: kHifzMaxLevel, due: 5));
      expect(e.hashCode, const HifzEntry(112, level: 2, due: 300, reviews: 4).hashCode);
    });

    test('ملخص التقرير', () {
      final m = summarize(const [
        HifzEntry(1, level: kHifzMaxLevel, due: 200, reviews: 6),
        HifzEntry(2, level: 1, due: 90, reviews: 1),
      ], 100);
      expect([m.memorized, m.mastered, m.due, m.reviews], [2, 1, 1, 7]);
    });

    test('نص الموعد', () {
      String l(int due) => nextReviewLabel(HifzEntry(1, due: due), 10);
      expect(l(9), 'راجعها اليوم');
      expect(l(11), 'مراجعتها بكرة');
      expect(l(12), 'مراجعتها بعد يومين');
      expect(l(17), 'مراجعتها بعد 7 أيام');
      expect(l(40), 'مراجعتها بعد 30 يوم');
    });
  });

  group('الحفظ في حالة التطبيق', () {
    late AppState st;
    final day = DateTime(2026, 11, 25, 9);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      st = AppState(parental: MemoryParentalStore(), local: MemoryLocalStore());
      await st.load();
      expect(st.markMemorized(105), false); // لا يوجد طفل
      expect(st.reviewSurah(105, ok: true), isNull);
      expect(st.hifzDue(), isEmpty);
      st.giveConsent();
      final c = st.addChild('سارة', 'moon', 1);
      st.enterChild(c.id);
      st.pauseClock();
    });

    test('حفظ ثم مراجعة في موعدها تعطي نجومًا', () {
      final before = st.current!.stars;
      expect(st.markMemorized(105, now: day), true);
      expect(st.markMemorized(105, now: day), false);
      expect(st.current!.stars, before + 5);
      expect(st.hifzDue(now: day), isEmpty);
      final tomorrow = day.add(const Duration(days: 1));
      expect(st.hifzDue(now: tomorrow).single.surah, 105);
      final e = st.reviewSurah(105, ok: true, now: tomorrow)!;
      expect(e.level, 1);
      expect(st.current!.stars, before + 7);
      // مراجعة مبكرة: لا نجوم إضافية
      st.reviewSurah(105, ok: true, now: tomorrow);
      expect(st.current!.stars, before + 7);
      expect(st.reviewSurah(1, ok: true, now: day), isNull);
    });

    test('الجدول يُحفظ ويُستعاد', () {
      st.markMemorized(112, now: day);
      st.reviewSurah(112, ok: false, now: day);
      final json = st.current!.toJson();
      final back = ChildProfile.fromJson(json);
      expect(back.hifz[112], st.current!.hifz[112]);
      final old = Map<String, dynamic>.from(json)..remove('hifz');
      expect(ChildProfile.fromJson(old).hifz, isEmpty);
    });
  });
}
