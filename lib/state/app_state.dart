import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الفئات العمرية: 0 = 4-6، 1 = 7-9، 2 = 10-12
const List<String> kAgeBandNames = ['البراعم 4-6', 'المستكشفون 7-9', 'الفرسان 10-12'];

/// رموز الأطفال: كلها جمادات ونباتات وأجرام، بلا ذوات أرواح.
const List<String> kSymbols = ['star', 'moon', 'sun', 'tree', 'book', 'gem'];

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
  Set<String> completed;
  Set<String> wrongQuestions;
  List<PendingHabit> pendingHabits;
  Map<String, int> usageSeconds;
  List<String> activeDays;

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
    Set<String>? completed,
    Set<String>? wrongQuestions,
    List<PendingHabit>? pendingHabits,
    Map<String, int>? usageSeconds,
    List<String>? activeDays,
  })  : completed = completed ?? <String>{},
        wrongQuestions = wrongQuestions ?? <String>{},
        pendingHabits = pendingHabits ?? <PendingHabit>[],
        usageSeconds = usageSeconds ?? <String, int>{},
        activeDays = activeDays ?? <String>[];

  int get todaySeconds => usageSeconds[todayKey()] ?? 0;

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
        'completed': completed.toList(),
        'wrongQuestions': wrongQuestions.toList(),
        'pendingHabits': pendingHabits.map((e) => e.toJson()).toList(),
        'usageSeconds': usageSeconds,
        'activeDays': activeDays,
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
        completed: ((j['completed'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        wrongQuestions: ((j['wrongQuestions'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        pendingHabits: ((j['pendingHabits'] as List?) ?? const [])
            .map((e) => PendingHabit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        usageSeconds: Map<String, dynamic>.from((j['usageSeconds'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        activeDays: ((j['activeDays'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

/// حالة التطبيق كلها تُحفظ على الجهاز فقط. لا يوجد أي اتصال بالإنترنت.
class AppState extends ChangeNotifier {
  static const _key = 'rawdah_state_v1';

  bool loaded = false;
  bool consentGiven = false;
  bool voiceOn = true;
  List<ChildProfile> children = [];
  String? currentChildId;

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

  bool get overLimit {
    final c = current;
    if (c == null || c.dailyLimitMinutes <= 0) return false;
    return c.todaySeconds >= c.dailyLimitMinutes * 60;
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        consentGiven = (j['consentGiven'] as bool?) ?? false;
        voiceOn = (j['voiceOn'] as bool?) ?? true;
        children = ((j['children'] as List?) ?? const [])
            .map((e) => ChildProfile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // ملف تالف: نبدأ من جديد دون إيقاف التطبيق.
      children = [];
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      jsonEncode({
        'consentGiven': consentGiven,
        'voiceOn': voiceOn,
        'children': children.map((c) => c.toJson()).toList(),
      }),
    );
  }

  void _changed() {
    notifyListeners();
    save();
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
    if (c.completed.add(activityId)) {
      c.stars += stars;
      _earn(10);
      _changed();
      return true;
    }
    return false;
  }

  void recordAnswer(String questionId, bool correct) {
    final c = current;
    if (c == null) return;
    c.quizTotal++;
    if (correct) {
      c.quizCorrect++;
      c.stars += 2;
      _earn(5);
      c.wrongQuestions.remove(questionId);
    } else {
      c.wrongQuestions.add(questionId);
    }
    _changed();
  }

  void recordLetterScore(int score) {
    final c = current;
    if (c == null) return;
    c.stars += score ~/ 3;
    _earn(score);
    if (score > c.bestLetterScore) c.bestLetterScore = score;
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
