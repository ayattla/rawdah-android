import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/content/names.dart';
import 'package:rawdah/core/parental/parent_pin.dart';
import 'package:rawdah/core/parental/time_lock.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/core/storage/parental_store.dart';
import 'package:rawdah/features/hifz/domain/hifz_schedule.dart';
import 'package:rawdah/features/quizzes/domain/mastery.dart';

/// الفئات العمرية: 0 = 4-6، 1 = 7-9، 2 = 10-12
const List<String> kAgeBandNames = ['البراعم 4-6', 'المستكشفون 7-9', 'الفرسان 10-12'];

/// رموز الأطفال: كلها جمادات ونباتات وأجرام، بلا ذوات أرواح.
const List<String> kSymbols = ['star', 'moon', 'sun', 'tree', 'book', 'gem'];

String monthKey([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}';
}

String todayKey([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

class PendingHabit {
  final String habitId;
  final String day;
  PendingHabit(this.habitId, this.day);
  Map<String, dynamic> toJson() => {'h': habitId, 'd': day};
  static PendingHabit fromJson(Map<String, dynamic> j) => PendingHabit(j['h'] as String, j['d'] as String);
}

class ChildProfile {
  String id;
  String name;
  String symbol;
  int ageBand;
  int stars;
  int quizCorrect;
  int quizTotal;
  int approvedHabits;
  int bestLetterScore;
  int dailyLimitMinutes; // 0 = بلا حد
  // المنافسة أون لاين
  bool onlineEnabled;
  String nick;
  int onlineTotal;
  int pendingPoints;
  String weekKey;
  int weekPoints;
  // المتجر والمهام اليومية والتحديات
  int spentStars;
  Set<String> owned;
  String dayKey;
  int correctToday;
  int learnToday;
  int gamesToday;
  List<String> myChallenges;
  String cupKey;
  int cupPoints;
  // الحلقة (فصل المعلم أو حلقة التحفيظ)
  String circleCode;
  String circleName;
  int circlePoints;
  int bestRace;
  // اللقب المركّب من القوائم المعتمدة (-1 = لم يُختر بعد)
  int nickA;
  int nickB;
  // الساعات المسموحة (من == إلى يعني بلا قيد)
  int allowedFrom;
  int allowedTo;
  // دقائق إضافية يمنحها الوالدان برمزهم: {يوم: ثوانٍ}
  Map<String, int> bonusSeconds;
  Set<String> completed;
  Set<String> wrongQuestions;
  List<PendingHabit> pendingHabits;
  Map<String, int> usageSeconds;
  List<String> activeDays;

  /// جدول مراجعة المحفوظ: رقم السورة ← مستوى الحفظ وموعد المراجعة.
  Map<int, HifzEntry> hifz;

  /// إتقان الأسئلة بالتكرار المتباعد: معرف السؤال ← [الصندوق، يوم المراجعة].
  Map<String, List<int>> mastery;

  /// عدادات عامة: مستويات الألغاز، وتقدم مهام اليوم، والصناديق المستلمة.
  Map<String, int> counters;

  ChildProfile({
    required this.id,
    required this.name,
    required this.symbol,
    required this.ageBand,
    this.stars = 0,
    this.quizCorrect = 0,
    this.quizTotal = 0,
    this.approvedHabits = 0,
    this.bestLetterScore = 0,
    this.dailyLimitMinutes = 30,
    this.onlineEnabled = false,
    this.nick = '',
    this.onlineTotal = 0,
    this.pendingPoints = 0,
    this.weekKey = '',
    this.weekPoints = 0,
    this.spentStars = 0,
    Set<String>? owned,
    this.dayKey = '',
    this.correctToday = 0,
    this.learnToday = 0,
    this.gamesToday = 0,
    List<String>? myChallenges,
    this.cupKey = '',
    this.cupPoints = 0,
    this.circleCode = '',
    this.circleName = '',
    this.circlePoints = 0,
    this.bestRace = 0,
    this.nickA = -1,
    this.nickB = -1,
    this.allowedFrom = 0,
    this.allowedTo = 0,
    Map<String, int>? bonusSeconds,
    Set<String>? completed,
    Set<String>? wrongQuestions,
    List<PendingHabit>? pendingHabits,
    Map<String, int>? usageSeconds,
    List<String>? activeDays,
    Map<int, HifzEntry>? hifz,
    Map<String, List<int>>? mastery,
    Map<String, int>? counters,
  })  : hifz = hifz ?? <int, HifzEntry>{},
        mastery = mastery ?? <String, List<int>>{},
        counters = counters ?? <String, int>{},
         owned = owned ?? <String>{},
        myChallenges = myChallenges ?? <String>[],
        completed = completed ?? <String>{},
        wrongQuestions = wrongQuestions ?? <String>{},
        pendingHabits = pendingHabits ?? <PendingHabit>[],
        usageSeconds = usageSeconds ?? <String, int>{},
        bonusSeconds = bonusSeconds ?? <String, int>{},
        activeDays = activeDays ?? <String>[];

  int get todaySeconds => usageSeconds[todayKey()] ?? 0;
  int get todayBonus => bonusSeconds[todayKey()] ?? 0;
  bool get nickReady => validNickParts(nickA, nickB);
  TimePolicy get timePolicy => TimePolicy(dailyLimitMinutes: dailyLimitMinutes, fromHour: allowedFrom, toHour: allowedTo);

  /// الرصيد المتاح للشراء من متجر الحديقة.
  int get balance => stars - spentStars;

  /// المستوى الشخصي من 1 إلى 50 حسب مجموع النجوم المكتسبة.
  int get level {
    var l = 1;
    while (l < 50 && stars >= levelStart(l + 1)) {
      l++;
    }
    return l;
  }

  static int levelStart(int l) => 5 * (l - 1) * (l - 1);

  void rollDay() {
    final k = todayKey();
    if (dayKey != k) {
      dayKey = k;
      correctToday = 0;
      learnToday = 0;
      gamesToday = 0;
    }
  }

  /// عدد الأيام المتتالية التي استخدم فيها الطفل التطبيق حتى اليوم.
  int get streak {
    final days = activeDays.toSet();
    var n = 0;
    var d = DateTime.now();
    while (days.contains(todayKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbol': symbol,
        'ageBand': ageBand,
        'stars': stars,
        'quizCorrect': quizCorrect,
        'quizTotal': quizTotal,
        'approvedHabits': approvedHabits,
        'bestLetterScore': bestLetterScore,
        'dailyLimitMinutes': dailyLimitMinutes,
        'onlineEnabled': onlineEnabled,
        'nick': nick,
        'onlineTotal': onlineTotal,
        'pendingPoints': pendingPoints,
        'weekKey': weekKey,
        'weekPoints': weekPoints,
        'spentStars': spentStars,
        'owned': owned.toList(),
        'dayKey': dayKey,
        'correctToday': correctToday,
        'learnToday': learnToday,
        'gamesToday': gamesToday,
        'myChallenges': myChallenges,
        'cupKey': cupKey,
        'cupPoints': cupPoints,
        'circleCode': circleCode,
        'circleName': circleName,
        'circlePoints': circlePoints,
        'bestRace': bestRace,
        'completed': completed.toList(),
        'wrongQuestions': wrongQuestions.toList(),
        'pendingHabits': pendingHabits.map((e) => e.toJson()).toList(),
        'usageSeconds': usageSeconds,
        'activeDays': activeDays,
        'hifz': {for (final e in hifz.values) '${e.surah}': e.toJson()},
        'mastery': mastery,
        'counters': counters,
      };

  static ChildProfile fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        symbol: (j['symbol'] as String?) ?? 'star',
        ageBand: (j['ageBand'] as num?)?.toInt() ?? 0,
        stars: (j['stars'] as num?)?.toInt() ?? 0,
        quizCorrect: (j['quizCorrect'] as num?)?.toInt() ?? 0,
        quizTotal: (j['quizTotal'] as num?)?.toInt() ?? 0,
        approvedHabits: (j['approvedHabits'] as num?)?.toInt() ?? 0,
        bestLetterScore: (j['bestLetterScore'] as num?)?.toInt() ?? 0,
        dailyLimitMinutes: (j['dailyLimitMinutes'] as num?)?.toInt() ?? 30,
        onlineEnabled: (j['onlineEnabled'] as bool?) ?? false,
        nick: (j['nick'] as String?) ?? '',
        onlineTotal: (j['onlineTotal'] as num?)?.toInt() ?? 0,
        pendingPoints: (j['pendingPoints'] as num?)?.toInt() ?? 0,
        weekKey: (j['weekKey'] as String?) ?? '',
        weekPoints: (j['weekPoints'] as num?)?.toInt() ?? 0,
        spentStars: (j['spentStars'] as num?)?.toInt() ?? 0,
        owned: ((j['owned'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        dayKey: (j['dayKey'] as String?) ?? '',
        correctToday: (j['correctToday'] as num?)?.toInt() ?? 0,
        learnToday: (j['learnToday'] as num?)?.toInt() ?? 0,
        gamesToday: (j['gamesToday'] as num?)?.toInt() ?? 0,
        myChallenges: ((j['myChallenges'] as List?) ?? const []).map((e) => e.toString()).toList(),
        cupKey: (j['cupKey'] as String?) ?? '',
        cupPoints: (j['cupPoints'] as num?)?.toInt() ?? 0,
        circleCode: (j['circleCode'] as String?) ?? '',
        circleName: (j['circleName'] as String?) ?? '',
        circlePoints: (j['circlePoints'] as num?)?.toInt() ?? 0,
        bestRace: (j['bestRace'] as num?)?.toInt() ?? 0,
        completed: ((j['completed'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        wrongQuestions: ((j['wrongQuestions'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        pendingHabits: ((j['pendingHabits'] as List?) ?? const [])
            .map((e) => PendingHabit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        usageSeconds: Map<String, dynamic>.from((j['usageSeconds'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        activeDays: ((j['activeDays'] as List?) ?? const []).map((e) => e.toString()).toList(),
        mastery: {
          for (final kv in ((j['mastery'] as Map?) ?? const {}).entries)
            if (kv.value is List && (kv.value as List).length >= 2)
              kv.key.toString(): [for (final v in (kv.value as List).take(2)) (v as num).toInt()],
        },
        counters: {
          for (final kv in ((j['counters'] as Map?) ?? const {}).entries)
            if (kv.value is num) kv.key.toString(): (kv.value as num).toInt(),
        },
        hifz: {
          for (final kv in ((j['hifz'] as Map?) ?? const {}).entries)
            if (HifzEntry.fromJson(kv.key.toString(), kv.value) case final e?) e.surah: e,
        },
      );
}

/// حالة التطبيق محفوظة على الجهاز. إعدادات الوالدين في مخزن مشفّر منفصل (ParentalStore)،
/// وبقية التقدم في Hive (LocalStore). لا يتصل بالإنترنت إلا عبر خدمة المنافسة إن فُعّلت.
class AppState extends ChangeNotifier {
  static const _key = 'rawdah_state_v1';

  /// الحقول التي تخص الوالدين ولا تُحفظ إلا مشفّرة.
  static const _parentalChildKeys = ['dailyLimitMinutes', 'onlineEnabled', 'nick'];

  final ParentalStore parental;
  final LocalStore local;
  AppState({ParentalStore? parental, LocalStore? local})
      : parental = parental ?? SecureParentalStore(),
        local = local ?? HiveLocalStore();

  bool loaded = false;
  bool consentGiven = false;
  bool voiceOn = true;
  List<ChildProfile> children = [];
  String? currentChildId;

  /// الحلقات التي أنشأها هذا الجهاز (المعلم أو الوالد): «الرمز|الاسم».
  List<String> ownedCircles = [];

  /// إعدادات الوصول (يختارها الوالدان).
  bool highContrast = false;
  bool reduceMotion = false;
  double textScale = 1.0; // 1.0 عادي، 1.15 كبير، 1.3 أكبر

  Timer? _ticker;
  bool _childActive = false;

  /// يُستدعى عند كسب نقاط منافسة، ليرسلها إلى الخادم على دفعات.
  void Function()? onPoints;

  /// نقاط المنافسة أون لاين للطفل الحالي (إن كان مشاركًا).
  void _earn(int n) {
    final c = current;
    if (c == null || !c.onlineEnabled || n <= 0) return;
    c.pendingPoints += n;
    onPoints?.call();
  }

  ChildProfile? get current {
    for (final c in children) {
      if (c.id == currentChildId) return c;
    }
    return null;
  }

  // ---------- القفل الزمني ورمز الوالدين ----------
  ParentPin? pin;
  final PinAttempts pinAttempts = PinAttempts();
  bool kioskWanted = false;

  /// آخر وقت رآه التطبيق: إن رجعت ساعة الجهاز قبله يُقفل حتى يأذن الوالدان.
  DateTime? lastSeen;

  LockReason get lockReason {
    final c = current;
    if (c == null) return LockReason.none;
    return TimeLock.evaluate(
      policy: c.timePolicy,
      usedSeconds: c.todaySeconds,
      bonusSeconds: c.todayBonus,
      now: DateTime.now(),
      lastSeen: lastSeen,
    );
  }

  bool get overLimit => lockReason != LockReason.none;

  /// يمنحه الوالدان بعد إدخال الرمز.
  void addBonusMinutes(int minutes) {
    final c = current;
    if (c == null) return;
    final k = todayKey();
    c.bonusSeconds
      ..removeWhere((day, _) => day != k)
      ..[k] = (c.bonusSeconds[k] ?? 0) + minutes * 60;
    _changed();
  }

  /// بعد تأكد الوالدين من وقت الجهاز.
  void acknowledgeClock() {
    lastSeen = DateTime.now();
    _changed();
  }

  void setPin(String code) {
    pin = ParentPin.create(code);
    pinAttempts.reset();
    _changed();
  }

  void clearPin() {
    pin = null;
    _changed();
  }

  /// يعيد null عند النجاح، أو رسالة الخطأ.
  String? verifyPin(String code) {
    final p = pin;
    if (p == null) return null;
    final now = DateTime.now();
    if (pinAttempts.isLocked(now)) {
      final s = pinAttempts.lockedUntil!.difference(now).inSeconds + 1;
      return 'محاولات كثيرة. انتظر $s ثانية';
    }
    if (p.verify(code)) {
      pinAttempts.reset();
      return null;
    }
    pinAttempts.recordFailure(now);
    return 'الرمز غير صحيح';
  }

  void setKioskWanted(bool v) {
    kioskWanted = v;
    _changed();
  }

  Future<void> load() async {
    try {
      var raw = await local.read(_key);
      if (raw == null) {
        // ترحيل لمرة واحدة من التخزين القديم (SharedPreferences) إلى Hive
        final p = await SharedPreferences.getInstance();
        raw = p.getString(_key);
        if (raw != null) {
          await local.write(_key, raw);
          await p.remove(_key);
        }
      }
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        consentGiven = (j['consentGiven'] as bool?) ?? false;
        voiceOn = (j['voiceOn'] as bool?) ?? true;
        ownedCircles = ((j['ownedCircles'] as List?) ?? const []).map((e) => e.toString()).toList();
        highContrast = (j['highContrast'] as bool?) ?? false;
        reduceMotion = (j['reduceMotion'] as bool?) ?? false;
        textScale = ((j['textScale'] as num?) ?? 1.0).toDouble();
        lastSeen = DateTime.tryParse((j['lastSeen'] as String?) ?? '');
        children = ((j['children'] as List?) ?? const [])
            .map((e) => ChildProfile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // ملف تالف: نبدأ من جديد دون إيقاف التطبيق.
      children = [];
    }
    // إعدادات الوالدين المشفّرة تتقدّم على أي قيمة قديمة في الملف العادي.
    final sec = await parental.read();
    if (sec != null) {
      consentGiven = (sec['consent'] as bool?) ?? consentGiven;
      pin = ParentPin.fromJson(sec['pin']);
      kioskWanted = (sec['kiosk'] as bool?) ?? false;
      final kids = Map<String, dynamic>.from((sec['kids'] as Map?) ?? const {});
      for (final c in children) {
        final k = kids[c.id];
        if (k is Map) {
          c.dailyLimitMinutes = (k['limit'] as num?)?.toInt() ?? c.dailyLimitMinutes;
          c.onlineEnabled = (k['online'] as bool?) ?? c.onlineEnabled;
          c.nick = (k['nick'] as String?) ?? c.nick;
          c.nickA = (k['na'] as num?)?.toInt() ?? c.nickA;
          c.nickB = (k['nb'] as num?)?.toInt() ?? c.nickB;
          c.allowedFrom = (k['from'] as num?)?.toInt() ?? c.allowedFrom;
          c.allowedTo = (k['to'] as num?)?.toInt() ?? c.allowedTo;
          c.bonusSeconds = Map<String, dynamic>.from((k['bonus'] as Map?) ?? const {})
              .map((day, v) => MapEntry(day, (v as num).toInt()));
        }
      }
    }
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> _parentalSnapshot() => {
        'v': 1,
        'consent': consentGiven,
        'kids': {
          for (final c in children)
            c.id: {
              'limit': c.dailyLimitMinutes,
              'online': c.onlineEnabled,
              'nick': c.nick,
              'na': c.nickA,
              'nb': c.nickB,
              'from': c.allowedFrom,
              'to': c.allowedTo,
              'bonus': c.bonusSeconds,
            },
        },
        if (pin != null) 'pin': pin!.toJson(),
        'kiosk': kioskWanted,
      };

  Future<void> save() async {
    // نكتب المشفّر أولًا، ولا نحذف القيم من الملف العادي إلا إذا نجحت الكتابة المشفّرة.
    final secured = await parental.write(_parentalSnapshot());
    await local.write(
      _key,
      jsonEncode({
        if (!secured) 'consentGiven': consentGiven,
        'voiceOn': voiceOn,
        'ownedCircles': ownedCircles,
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
        'textScale': textScale,
        if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
        'children': [
          for (final c in children)
            if (secured) (c.toJson()..removeWhere((k, _) => _parentalChildKeys.contains(k))) else c.toJson(),
        ],
      }),
    );
  }

  void _changed() {
    notifyListeners();
    save();
  }

  /// نسخة احتياطية سحابية: ملفات الأطفال وتقدمهم كاملة.
  String exportBackup() => jsonEncode({'v': 1, 'children': [for (final c in children) c.toJson()]});

  /// استرجاع النسخة: يستبدل ملفات الأطفال بما في النسخة. يعيد عدد الأطفال المسترجعين.
  int importBackup(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final list = ((j['children'] as List?) ?? const []).map((e) => ChildProfile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    if (list.isEmpty) return 0;
    children = list;
    _changed();
    return list.length;
  }

  void setAccessibility({bool? highContrast, bool? reduceMotion, double? textScale}) {
    if (highContrast != null) this.highContrast = highContrast;
    if (reduceMotion != null) this.reduceMotion = reduceMotion;
    if (textScale != null) this.textScale = textScale.clamp(1.0, 1.3).toDouble();
    _changed();
  }

  void addOwnedCircle(String code, String name) {
    ownedCircles.removeWhere((e) => e.startsWith('$code|'));
    ownedCircles.insert(0, '$code|$name');
    _changed();
  }

  void removeOwnedCircle(String code) {
    ownedCircles.removeWhere((e) => e.startsWith('$code|'));
    _changed();
  }

  void giveConsent() {
    consentGiven = true;
    _changed();
  }

  void setVoice(bool v) {
    voiceOn = v;
    _changed();
  }

  ChildProfile addChild(String name, String symbol, int band) {
    final c = ChildProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'بطل' : name.trim(),
      symbol: symbol,
      ageBand: band,
    );
    children.add(c);
    _changed();
    return c;
  }

  void updateChild(ChildProfile c) => _changed();

  void removeChild(String id) {
    children.removeWhere((c) => c.id == id);
    if (currentChildId == id) currentChildId = null;
    _changed();
  }

  // ---------- جلسة الطفل وحساب الوقت ----------

  void enterChild(String id) {
    currentChildId = id;
    final c = current;
    if (c != null && !c.activeDays.contains(todayKey())) {
      c.activeDays.add(todayKey());
      if (c.activeDays.length > 60) c.activeDays.removeAt(0);
    }
    _childActive = true;
    _startTicker();
    _changed();
  }

  void leaveChild() {
    _childActive = false;
    _ticker?.cancel();
    currentChildId = null;
    _changed();
  }

  void pauseClock() => _ticker?.cancel();

  void resumeClock() {
    if (_childActive) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      final c = current;
      if (c == null) return;
      final now = DateTime.now();
      if (lockReason == LockReason.clockChanged) return; // لا نعدّ ولا نحدّث حتى يأذن الوالدان
      if (lastSeen == null || now.isAfter(lastSeen!)) lastSeen = now;
      final k = todayKey();
      c.usageSeconds[k] = (c.usageSeconds[k] ?? 0) + 15;
      if (c.usageSeconds.length > 40) {
        final keys = c.usageSeconds.keys.toList()..sort();
        c.usageSeconds.remove(keys.first);
      }
      _changed();
    });
  }

  // ---------- النجوم والإنجازات ----------

  void addStars(int n) {
    final c = current;
    if (c == null) return;
    c.stars += n;
    _changed();
  }

  /// يسجّل إكمال نشاط مرة واحدة، ويمنح النجوم أول مرة فقط.
  bool complete(String activityId, {int stars = 3}) {
    final c = current;
    if (c == null) return false;
    c.rollDay();
    bump('activity');
    if (activityId.startsWith('game_')) {
      c.gamesToday++;
    } else if (activityId.startsWith('story_') ||
        activityId.startsWith('lesson_') ||
        activityId.startsWith('surah_') ||
        activityId == 'adhkar') {
      c.learnToday++;
    }
    if (c.completed.add(activityId)) {
      c.stars += stars;
      _earn(10);
      _changed();
      return true;
    }
    return false;
  }

  /// يسجّل حفظ سورة جديدة (بعد اختبار الحفظ كاملًا). يعيد true أول مرة.
  bool markMemorized(int surah, {DateTime? now}) {
    final c = current;
    if (c == null || c.hifz.containsKey(surah)) return false;
    c.hifz[surah] = HifzEntry.memorized(surah, dayNumber(now ?? DateTime.now()));
    c.stars += 5;
    _earn(10);
    _changed();
    return true;
  }

  /// نتيجة مراجعة سورة محفوظة. المراجعة الناجحة في موعدها تعطي نجمتين.
  HifzEntry? reviewSurah(int surah, {required bool ok, DateTime? now}) {
    final c = current;
    final e = c?.hifz[surah];
    if (c == null || e == null) return null;
    final today = dayNumber(now ?? DateTime.now());
    final wasDue = e.isDue(today);
    final next = e.review(ok: ok, today: today);
    c.hifz[surah] = next;
    bump('review');
    if (ok && wasDue) {
      c.stars += 2;
      _earn(4);
    }
    _changed();
    return next;
  }

  /// السور المستحقة للمراجعة اليوم للطفل الحالي.
  List<HifzEntry> hifzDue({DateTime? now}) {
    final c = current;
    if (c == null) return const [];
    return dueToday(c.hifz.values, dayNumber(now ?? DateTime.now()));
  }

  void recordAnswer(String questionId, bool correct) {
    final c = current;
    if (c == null) return;
    c.quizTotal++;
    c.rollDay();
    if (correct) {
      c.correctToday++;
      c.quizCorrect++;
      c.stars += 2;
      _earn(5);
      c.wrongQuestions.remove(questionId);
      bump('correct');
    } else {
      c.wrongQuestions.add(questionId);
    }
    final today = dayNumber(DateTime.now());
    c.mastery[questionId] = masteryAfter(c.mastery[questionId], correct, today);
    _changed();
  }

  /// يزيد عداد مهمة يومية (يُخزن باسم اليوم فيتجدد كل يوم).
  void bump(String kind, [int by = 1]) {
    final c = current;
    if (c == null) return;
    final k = 'dq_${todayKey()}_$kind';
    c.counters[k] = (c.counters[k] ?? 0) + by;
    c.counters['total_$kind'] = (c.counters['total_$kind'] ?? 0) + by;
    // نقاط دوري العائلة الشهري
    const w = {'correct': 1, 'tower': 2, 'activity': 3, 'review': 3};
    final mk = 'mp_${monthKey()}';
    c.counters[mk] = (c.counters[mk] ?? 0) + (w[kind] ?? 0) * by;
    // تنظيف عدادات الأيام القديمة حتى لا يكبر الملف
    if (c.counters.length > 400) {
      // نبقي آخر أسبوعين لتقرير الوالدين
      final keep = {for (var i = 0; i < 14; i++) 'dq_${todayKey(DateTime.now().subtract(Duration(days: i)))}'};
      c.counters.removeWhere((key, _) => key.startsWith('dq_') && !keep.any(key.startsWith));
    }
  }

  int todayCount(String kind) => current?.counters['dq_${todayKey()}_$kind'] ?? 0;

  int counter(String key) => current?.counters[key] ?? 0;

  void setCounter(String key, int value) {
    final c = current;
    if (c == null) return;
    c.counters[key] = value;
    _changed();
  }

  /// صندوق اليوم: يُستلم مرة واحدة عند إتمام كل مهام رحلة اليوم.
  bool claimDailyChest(int stars) {
    final c = current;
    if (c == null) return false;
    final k = 'chest_${todayKey()}';
    if ((c.counters[k] ?? 0) > 0) return false;
    c.counters[k] = 1;
    c.stars += stars;
    _earn(stars);
    _changed();
    return true;
  }

  /// سباق الدقيقة: نجمة لكل إجابة صحيحة، ونقاط منافسة بحد أقصى 20 للجولة.
  void recordRaceScore(int score) {
    final c = current;
    if (c == null) return;
    c.rollDay();
    c.gamesToday++;
    c.correctToday += score;
    c.stars += score;
    _earn(score > 10 ? 20 : score * 2);
    if (score > c.bestRace) c.bestRace = score;
    _changed();
  }

  /// المسابقة المباشرة: نجمتان لكل إجابة صحيحة، ونقاط منافسة بحد أقصى 20.
  void recordLiveScore(int score) {
    final c = current;
    if (c == null) return;
    c.rollDay();
    c.gamesToday++;
    c.stars += score * 2;
    _earn(score > 10 ? 20 : score * 2);
    _changed();
  }

  void recordLetterScore(int score) {
    final c = current;
    if (c == null) return;
    c.rollDay();
    c.gamesToday++;
    c.stars += score ~/ 3;
    _earn(score);
    if (score > c.bestLetterScore) c.bestLetterScore = score;
    _changed();
  }

  // ---------- المهام اليومية ----------

  bool get missionsDone {
    final c = current;
    if (c == null) return false;
    c.rollDay();
    return c.correctToday >= 5 && c.learnToday >= 1 && c.gamesToday >= 1;
  }

  /// يمنح مكافأة المهام مرة واحدة في اليوم.
  bool claimMissions() {
    final c = current;
    if (c == null || !missionsDone) return false;
    final id = 'missions_${todayKey()}';
    if (c.completed.contains(id)) return false;
    c.completed.add(id);
    c.stars += 10;
    _earn(15);
    _changed();
    return true;
  }

  // ---------- متجر الحديقة ----------

  bool buy(String itemId, int price) {
    final c = current;
    if (c == null || c.owned.contains(itemId) || c.balance < price) return false;
    c.owned.add(itemId);
    c.spentStars += price;
    _changed();
    return true;
  }

  void addChallenge(String code) {
    final c = current;
    if (c == null || c.myChallenges.contains(code)) return;
    c.myChallenges.insert(0, code);
    if (c.myChallenges.length > 20) c.myChallenges.removeLast();
    _changed();
  }

  // ---------- عادات الخير ----------

  bool habitPendingToday(String habitId) {
    final c = current;
    if (c == null) return false;
    return c.pendingHabits.any((p) => p.habitId == habitId && p.day == todayKey());
  }

  void markHabit(String habitId) {
    final c = current;
    if (c == null || habitPendingToday(habitId)) return;
    c.pendingHabits.add(PendingHabit(habitId, todayKey()));
    _changed();
  }

  void approveHabit(ChildProfile c, PendingHabit p, bool approve) {
    c.pendingHabits.remove(p);
    if (approve) {
      c.approvedHabits++;
      c.stars += 3;
    }
    _changed();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// يوفّر الحالة لكل الشاشات.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
