import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/names.dart';
import 'package:rawdah/core/parental/parent_pin.dart';
import 'package:rawdah/core/parental/time_lock.dart';

void main() {
  group('القفل الزمني', () {
    final noon = DateTime(2026, 11, 23, 12);

    test('الحد اليومي مع الدقائق الإضافية', () {
      const p = TimePolicy(dailyLimitMinutes: 30);
      expect(TimeLock.evaluate(policy: p, usedSeconds: 29 * 60, bonusSeconds: 0, now: noon), LockReason.none);
      expect(TimeLock.evaluate(policy: p, usedSeconds: 30 * 60, bonusSeconds: 0, now: noon), LockReason.dailyLimit);
      expect(TimeLock.evaluate(policy: p, usedSeconds: 30 * 60, bonusSeconds: 15 * 60, now: noon), LockReason.none,
          reason: 'تمديد الوالدين يفتح 15 دقيقة');
      expect(TimeLock.remainingSeconds(policy: p, usedSeconds: 20 * 60, bonusSeconds: 0), 10 * 60);
    });

    test('بلا حد يومي لا يُقفل بالوقت المستخدم', () {
      expect(TimeLock.evaluate(policy: const TimePolicy(), usedSeconds: 999999, bonusSeconds: 0, now: noon),
          LockReason.none);
    });

    test('الساعات المسموحة، ومنها نافذة تعبر منتصف الليل', () {
      const day = TimePolicy(fromHour: 7, toHour: 20);
      expect(day.insideWindow(DateTime(2026, 1, 1, 6, 59)), isFalse);
      expect(day.insideWindow(DateTime(2026, 1, 1, 7)), isTrue);
      expect(day.insideWindow(DateTime(2026, 1, 1, 19, 59)), isTrue);
      expect(day.insideWindow(DateTime(2026, 1, 1, 20)), isFalse);
      const night = TimePolicy(fromHour: 20, toHour: 6);
      expect(night.insideWindow(DateTime(2026, 1, 1, 23)), isTrue);
      expect(night.insideWindow(DateTime(2026, 1, 1, 12)), isFalse);
      expect(TimeLock.evaluate(policy: day, usedSeconds: 0, bonusSeconds: 0, now: DateTime(2026, 1, 1, 22)),
          LockReason.outsideHours);
    });

    test('إرجاع ساعة الجهاز للخلف يُقفل، والتصحيح البسيط لا يُقفل', () {
      const p = TimePolicy(dailyLimitMinutes: 30);
      expect(
          TimeLock.evaluate(
              policy: p, usedSeconds: 0, bonusSeconds: 0, now: noon, lastSeen: noon.add(const Duration(days: 1))),
          LockReason.clockChanged);
      expect(
          TimeLock.evaluate(
              policy: p, usedSeconds: 0, bonusSeconds: 0, now: noon, lastSeen: noon.add(const Duration(minutes: 2))),
          LockReason.none);
    });
  });

  group('رمز الوالدين', () {
    test('يتحقق من الرمز الصحيح فقط، ولا يُحفظ الرمز نفسه', () {
      final pin = ParentPin.create('4821', random: Random(1));
      expect(pin.verify('4821'), isTrue);
      expect(pin.verify('4822'), isFalse);
      expect(pin.toJson().values.any((v) => v.contains('4821')), isFalse);
      final again = ParentPin.fromJson(pin.toJson())!;
      expect(again.verify('4821'), isTrue);
    });

    test('صيغة الرمز 4 أرقام', () {
      expect(ParentPin.validFormat('1234'), isTrue);
      expect(ParentPin.validFormat('123'), isFalse);
      expect(ParentPin.validFormat('12a4'), isFalse);
    });

    test('القفل بعد 5 محاولات خاطئة ويتضاعف', () {
      final a = PinAttempts();
      final t = DateTime(2026, 1, 1);
      for (var i = 0; i < 4; i++) {
        a.recordFailure(t);
      }
      expect(a.isLocked(t), isFalse);
      a.recordFailure(t);
      expect(a.isLocked(t.add(const Duration(seconds: 29))), isTrue);
      expect(a.isLocked(t.add(const Duration(seconds: 31))), isFalse);
      a.recordFailure(t);
      expect(a.isLocked(t.add(const Duration(seconds: 59))), isTrue, reason: 'المرة التالية 60 ثانية');
    });
  });

  group('لا نص حر', () {
    test('كل الألقاب المركّبة حروف عربية ومسافات، وطولها مناسب', () {
      final arabic = RegExp(r'^[ء-ي ]+$');
      for (var a = 0; a < kNickFirst.length; a++) {
        for (var b = 0; b < kNickSecond.length; b++) {
          final n = composeNick(a, b);
          expect(arabic.hasMatch(n), isTrue, reason: n);
          expect(n.length, inInclusiveRange(2, 16), reason: n);
        }
      }
    });

    test('قوائم قواعد Firestore تطابق قوائم التطبيق حرفيًا وبالترتيب', () {
      final rules = File('firestore.rules').readAsStringSync();
      List<String> listOf(String fn) {
        final body = RegExp('function $fn\\(\\) \\{ return \\[(.*?)\\]; \\}').firstMatch(rules)!.group(1)!;
        return RegExp(r"'([^']+)'").allMatches(body).map((m) => m.group(1)!).toList();
      }

      expect(listOf('nickFirst'), kNickFirst);
      expect(listOf('nickSecond'), kNickSecond);
      expect(rules.contains('data().nameKey < ${kCircleNames.length}'), isTrue);
    });
  });
}
