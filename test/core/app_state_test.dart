import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/data/content_repository.dart';
import 'package:rawdah/core/data/progress_repository.dart';
import 'package:rawdah/core/parental/time_lock.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/core/storage/parental_store.dart';

Future<AppState> fresh({LocalStore? local, ParentalStore? parental}) async {
  SharedPreferences.setMockInitialValues({});
  final st = AppState(parental: parental ?? MemoryParentalStore(), local: local ?? MemoryLocalStore());
  await st.load();
  return st;
}

void main() {
  late AppState st;
  late ChildProfile c;

  setUp(() async {
    st = await fresh();
    st.giveConsent();
    c = st.addChild('سارة', 'moon', 1);
    st.enterChild(c.id);
    st.pauseClock();
  });

  tearDown(() => st.dispose());

  group('الملفات والدخول', () {
    test('إضافة طفل والدخول والخروج', () {
      expect(st.children, hasLength(1));
      expect(st.current?.name, 'سارة');
      st.leaveChild();
      expect(st.current, isNull);
      st.enterChild(c.id);
      expect(c.activeDays, contains(todayKey()));
      expect(c.streak, 1);
    });

    test('حذف طفل', () {
      final b = st.addChild('عمر', 'star', 0);
      st.removeChild(b.id);
      expect(st.children.map((x) => x.name), ['سارة']);
    });
  });

  group('النجوم والإنجازات', () {
    test('الإنجاز يمنح النجوم مرة واحدة ويُحسب في مهام اليوم', () {
      expect(st.complete('story_fil'), isTrue);
      expect(st.complete('story_fil'), isFalse);
      expect(c.stars, 3);
      expect(c.learnToday, 2, reason: 'يُحسب التعلّم حتى لو تكرر');
      st.complete('game_wudu', stars: 5);
      expect(c.gamesToday, 1);
      expect(c.stars, 8);
    });

    test('الإجابات تضيف نجمتين للصحيحة وتحفظ الخاطئة للمراجعة', () {
      st.recordAnswer('q01', false);
      expect(c.wrongQuestions, contains('q01'));
      st.recordAnswer('q01', true);
      expect(c.wrongQuestions, isNot(contains('q01')));
      expect(c.stars, 2);
      expect((c.quizCorrect, c.quizTotal), (1, 2));
    });

    test('المستوى ينمو مع النجوم', () {
      expect(c.level, 1);
      st.addStars(ChildProfile.levelStart(4));
      expect(c.level, 4);
    });

    test('الألعاب: الحروف والسباق والمسابقة المباشرة', () {
      st.recordLetterScore(9);
      expect((c.stars, c.bestLetterScore), (3, 9));
      st.recordRaceScore(7);
      expect((c.stars, c.bestRace), (10, 7));
      st.recordLiveScore(4);
      expect(c.stars, 18);
      expect(c.gamesToday, 3);
    });
  });

  group('المهام اليومية', () {
    test('تُستلم مكافأتها مرة واحدة بعد إتمامها', () {
      expect(st.missionsDone, isFalse);
      expect(st.claimMissions(), isFalse);
      for (var i = 0; i < 5; i++) {
        st.recordAnswer('q0$i', true);
      }
      st.complete('lesson_islam');
      st.complete('game_order_salah');
      expect(st.missionsDone, isTrue);
      final before = c.stars;
      expect(st.claimMissions(), isTrue);
      expect(c.stars, before + 10);
      expect(st.claimMissions(), isFalse);
    });
  });

  group('المتجر والعادات والتحديات', () {
    test('الشراء من الرصيد ولا يتكرر', () {
      st.addStars(20);
      expect(st.buy('lamp', 15), isTrue);
      expect(c.balance, 5);
      expect(st.buy('lamp', 1), isFalse);
      expect(st.buy('dome', 50), isFalse);
    });

    test('العادة تنتظر اعتماد الوالدين', () {
      st.markHabit('h1');
      st.markHabit('h1');
      expect(c.pendingHabits, hasLength(1));
      expect(st.habitPendingToday('h1'), isTrue);
      st.approveHabit(c, c.pendingHabits.first, true);
      expect((c.approvedHabits, c.stars), (1, 3));
      st.markHabit('h2');
      st.approveHabit(c, c.pendingHabits.first, false);
      expect(c.approvedHabits, 1);
    });

    test('سجل التحديات بلا تكرار وبحد 20', () {
      for (var i = 0; i < 25; i++) {
        st.addChallenge('C$i');
      }
      st.addChallenge('C24');
      expect(c.myChallenges, hasLength(20));
      expect(c.myChallenges.first, 'C24');
    });
  });

  group('نقاط المنافسة المعلّقة', () {
    test('تتراكم فقط للطفل المفعّل', () {
      st.recordAnswer('q01', true);
      expect(c.pendingPoints, 0);
      var pinged = 0;
      st.onPoints = () => pinged++;
      c.onlineEnabled = true;
      st.recordAnswer('q02', true);
      st.complete('story_x');
      expect(c.pendingPoints, 15);
      expect(pinged, greaterThan(0));
    });
  });

  group('القفل الزمني', () {
    test('الحد اليومي يقفل والتمديد يفتح', () {
      c.dailyLimitMinutes = 1;
      c.usageSeconds[todayKey()] = 60;
      expect(st.lockReason, LockReason.dailyLimit);
      expect(st.overLimit, isTrue);
      st.addBonusMinutes(15);
      expect(st.lockReason, LockReason.none);
    });

    test('إرجاع الساعة يقفل حتى يؤكد الوالدان', () {
      c.dailyLimitMinutes = 0;
      st.lastSeen = DateTime.now().add(const Duration(days: 2));
      expect(st.lockReason, LockReason.clockChanged);
      st.acknowledgeClock();
      expect(st.lockReason, LockReason.none);
    });

    test('الرمز: تعيين وتحقق وإلغاء', () {
      expect(st.verifyPin('0000'), isNull, reason: 'بلا رمز لا يوجد ما يُتحقق منه');
      st.setPin('2468');
      expect(st.verifyPin('2468'), isNull);
      expect(st.verifyPin('1111'), 'الرمز غير صحيح');
      for (var i = 0; i < 5; i++) {
        st.verifyPin('1111');
      }
      expect(st.verifyPin('2468'), startsWith('محاولات كثيرة'));
      st.clearPin();
      expect(st.pin, isNull);
    });
  });

  group('الحفظ والاستعادة', () {
    test('كل الإعدادات والتقدم تعود بعد إعادة التشغيل', () async {
      final local = MemoryLocalStore();
      final parental = MemoryParentalStore();
      final a = await fresh(local: local, parental: parental);
      a.giveConsent();
      final k = a.addChild('يوسف', 'tree', 2);
      a.enterChild(k.id);
      a.pauseClock();
      a.recordAnswer('q05', true);
      a.setAccessibility(highContrast: true, reduceMotion: true, textScale: 1.3);
      a.setVoice(false);
      a.setPin('1357');
      a.setKioskWanted(true);
      a.addOwnedCircle('ABC123', 'حلقة الفجر 1');
      k
        ..allowedFrom = 7
        ..allowedTo = 20
        ..nickA = 2
        ..nickB = 3;
      a.addBonusMinutes(10);
      await a.save();
      a.dispose();

      final b = await fresh(local: local, parental: parental);
      final k2 = b.children.single;
      expect(k2.stars, 2);
      expect((b.highContrast, b.reduceMotion, b.textScale, b.voiceOn), (true, true, 1.3, false));
      expect(b.pin?.verify('1357'), isTrue);
      expect(b.kioskWanted, isTrue);
      expect(b.ownedCircles, ['ABC123|حلقة الفجر 1']);
      expect((k2.allowedFrom, k2.allowedTo, k2.nickA, k2.nickB), (7, 20, 2, 3));
      expect(k2.todayBonus, 600);
      b.removeOwnedCircle('ABC123');
      expect(b.ownedCircles, isEmpty);
      b.dispose();
    });

    test('ملف تالف لا يوقف التطبيق', () async {
      final local = MemoryLocalStore()..data['rawdah_state_v1'] = '{ليس json';
      final s = await fresh(local: local);
      expect(s.loaded, isTrue);
      expect(s.children, isEmpty);
      s.dispose();
    });

    test('المخزن المشفّر الفعلي يكتب ويقرأ ولا يعيد الكتابة بلا تغيير', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureParentalStore();
      expect(await store.read(), isNull);
      expect(await store.write({'consent': true}), isTrue);
      expect(await store.write({'consent': true}), isTrue);
      expect((await store.read())?['consent'], isTrue);
    });
  });

  group('المستودعات', () {
    test('مستودع التقدم المحلي يمرّر إلى الحالة', () {
      final repo = LocalProgressRepository(st);
      expect(repo.currentChild?.id, c.id);
      repo.recordAnswer('q09', true);
      expect(repo.completeActivity('lesson_wudu'), isTrue);
      repo.recordRaceScore(2);
      repo.recordLiveScore(1);
      expect(c.stars, 2 + 3 + 2 + 2);
    });

    test('مستودع المحتوى', () {
      const repo = BundledContentRepository();
      expect(repo.questionsFor(0).every((q) => q.band == 0), isTrue);
      expect(repo.questionById('q01')?.id, 'q01');
      expect(repo.questionById('لا يوجد'), isNull);
      expect(repo.stories, isNotEmpty);
      expect(repo.lessons, isNotEmpty);
    });
  });
}
