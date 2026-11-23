import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:rawdah/core/content/names.dart';
import 'package:rawdah/core/state/app_state.dart';

/// المنافسة أون لاين: ترتيب بالألقاب والنقاط فقط.
/// لا محادثة ولا رسائل ولا أي بيانات شخصية. الدخول مجهول لكل جهاز.
class Online {
  Online._();
  static final Online instance = Online._();

  static const _options = FirebaseOptions(
    apiKey: 'AIzaSyBaWYPSYuL0HU75Y-j-xRlCtRHPs5mU7CQ',
    appId: '1:299684362863:android:b0bfcf3de275c72b8eab9a',
    messagingSenderId: '299684362863',
    projectId: 'rawdah-kids-41f10',
    storageBucket: 'rawdah-kids-41f10.firebasestorage.app',
  );

  bool _ready = false;
  String? uid;
  Timer? _flushTimer;
  bool _flushing = false;

  /// منازل الهرم وحدودها الدنيا من مجموع النقاط.
  static const tiers = <(String, int)>[
    ('البذرة', 0),
    ('البرعم', 50),
    ('الغصن', 150),
    ('الشجرة', 300),
    ('النخلة', 600),
    ('الواحة', 1000),
    ('الروضة', 1500),
  ];

  static int tierIndex(int total) {
    var t = 0;
    for (var i = 0; i < tiers.length; i++) {
      if (total >= tiers[i].$2) t = i;
    }
    return t;
  }

  /// رقم الأسبوع بتوقيت الرياض، ويبدأ الأسبوع يوم السبت.
  static int weekIndex() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return now.difference(DateTime.utc(2024, 1, 6)).inDays ~/ 7;
  }

  static String weekKey(int band) => 'w${weekIndex()}_b$band';

  /// كأس رمضان 1448هـ: من 7 فبراير إلى 10 مارس 2027 تقريبًا (بتوقيت الرياض).
  static final DateTime ramadanStart = DateTime(2027, 2, 7);
  static final DateTime ramadanEnd = DateTime(2027, 3, 10, 23, 59);

  static bool get ramadanActive {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final n = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return !n.isBefore(ramadanStart) && !n.isAfter(ramadanEnd);
  }

  /// رقم يوم رمضان من 1 إلى 30، أو 0 خارج رمضان.
  static int get ramadanDay {
    if (!ramadanActive) return 0;
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final d = DateTime(now.year, now.month, now.day).difference(ramadanStart).inDays + 1;
    return d.clamp(1, 30);
  }

  static int get daysToRamadan {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return ramadanStart.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  static String cupKeyFor(int band) => 'r1448_b$band';

  Future<bool> ensure() async {
    if (_ready && uid != null) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _options);
        // نوقف طابور الكتابة الخفي في Firestore: نحن ندير الطابور بأنفسنا (pendingPoints)،
        // ولو بقي مفعّلًا لأُعيدت دفعة معلّقة بعد عودة الاتصال فتُحسب النقاط مرتين.
        // القراءة بلا اتصال تتولاها طبقة Hive في CachedCompetitionRepository.
        FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
      }
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously();
      uid = auth.currentUser?.uid;
      _ready = uid != null;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String playerId(ChildProfile c) => '${uid}_${c.id}';

  /// رقم قصير ثابت يميّز الألقاب المتشابهة، مشتق من المعرّف لا من أي بيانات شخصية.
  static String tag(String pid) {
    var h = 0;
    for (final u in pid.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return (1000 + h % 9000).toString();
  }

  /// تفعيل المنافسة لطفل: يقرأ رصيده من الخادم أو ينشئ ملفه.
  Future<String?> join(AppState st, ChildProfile c) async {
    if (!await ensure()) return 'تعذّر الاتصال بالإنترنت';
    try {
      final ref = _db.collection('players').doc(playerId(c));
      final snap = await ref.get();
      if (snap.exists) {
        c.onlineTotal = (snap.data()?['total'] as num?)?.toInt() ?? 0;
        await ref.update({
          'nick': c.nick,
          'na': c.nickA,
          'nb': c.nickB,
          'symbol': c.symbol,
          'band': c.ageBand,
          'total': c.onlineTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      } else {
        await ref.set({
          'nick': c.nick,
          'na': c.nickA,
          'nb': c.nickB,
          'symbol': c.symbol,
          'band': c.ageBand,
          'total': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        c.onlineTotal = 0;
      }
      await _syncWeek(c);
      c.onlineEnabled = true;
      st.updateChild(c);
      return null;
    } catch (e) {
      return 'تعذّر التسجيل، حاول لاحقًا';
    }
  }

  Future<void> _syncWeek(ChildProfile c) async {
    final key = weekKey(c.ageBand);
    if (c.weekKey == key) return;
    final snap = await _db.collection('leagues').doc(key).collection('entries').doc(playerId(c)).get();
    c.weekKey = key;
    c.weekPoints = snap.exists ? (snap.data()?['points'] as num?)?.toInt() ?? 0 : 0;
  }

  /// يرسل النقاط المتراكمة على دفعات (60 نقطة كحد أقصى كل 10 ثوانٍ، كما تشترط قواعد الخادم).
  void scheduleFlush(AppState st) {
    _watchConnectivity(st);
    _flushTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      // تراجع أُسّي عند الفشل: 10، 20، 40 ثانية ثم دقيقة كحد أقصى
      if (_skipTicks > 0) {
        _skipTicks--;
        return;
      }
      flush(st);
    });
  }

  int _failures = 0;
  int _skipTicks = 0;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  /// عند عودة الاتصال نرسل فورًا بدل انتظار دورة التراجع.
  void _watchConnectivity(AppState st) {
    _connSub ??= Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _failures = 0;
        _skipTicks = 0;
        if (st.children.any((c) => c.onlineEnabled && c.pendingPoints > 0)) scheduleFlush(st);
      }
    });
  }

  void _onFlushResult(bool ok) {
    if (ok) {
      _failures = 0;
      _skipTicks = 0;
    } else {
      _failures = (_failures + 1).clamp(0, 6);
      _skipTicks = (1 << (_failures - 1)).clamp(0, 5);
    }
  }

  Future<void> flush(AppState st) async {
    if (_flushing) return;
    // لا يُرسل لطفل لم يُختر له لقب من القوائم المعتمدة
    final pending = st.children.where((c) => c.onlineEnabled && c.nickReady && c.pendingPoints > 0).toList();
    if (pending.isEmpty) {
      _flushTimer?.cancel();
      _flushTimer = null;
      return;
    }
    if (!await ensure()) {
      _onFlushResult(false);
      return;
    }
    _flushing = true;
    var ok = false;
    try {
      // طفل واحد في كل دورة: قواعد الخادم تسمح بدفعة واحدة لكل مستخدم كل 8 ثوانٍ.
      for (final c in pending.take(1)) {
        final chunk = c.pendingPoints > 60 ? 60 : c.pendingPoints;
        await _syncWeek(c);
        final pid = playerId(c);
        final batch = _db.batch();
        // ختم حد السرعة: يتحقق منه الخادم مع كل ملف نقاط في الدفعة نفسها.
        batch.set(_db.collection('limits').doc(uid!), {'at': FieldValue.serverTimestamp(), 'pid': pid});
        batch.set(_db.collection('players').doc(pid), {
          'nick': c.nick,
          'na': c.nickA,
          'nb': c.nickB,
          'symbol': c.symbol,
          'band': c.ageBand,
          'total': c.onlineTotal + chunk,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(_db.collection('leagues').doc(c.weekKey).collection('entries').doc(pid), {
          'nick': c.nick,
          'na': c.nickA,
          'nb': c.nickB,
          'symbol': c.symbol,
          'points': c.weekPoints + chunk,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final cup = ramadanActive ? cupKeyFor(c.ageBand) : null;
        if (cup != null) {
          if (c.cupKey != cup) {
            final cs = await _db.collection('cups').doc(cup).collection('entries').doc(pid).get();
            c.cupKey = cup;
            c.cupPoints = cs.exists ? (cs.data()?['points'] as num?)?.toInt() ?? 0 : 0;
          }
          batch.set(_db.collection('cups').doc(cup).collection('entries').doc(pid), {
            'nick': c.nick,
            'na': c.nickA,
            'nb': c.nickB,
            'symbol': c.symbol,
            'points': c.cupPoints + chunk,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        final circle = c.circleCode.isNotEmpty ? c.circleCode : null;
        if (circle != null) {
          // update وليس set: إن أخرج المعلم الطفل لا يُعاد إنشاؤه بنقاطه.
          batch.update(_db.collection('circles').doc(circle).collection('members').doc(pid), {
            'nick': c.nick,
            'na': c.nickA,
            'nb': c.nickB,
            'symbol': c.symbol,
            'points': c.circlePoints + chunk,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        try {
          await batch.commit().timeout(const Duration(seconds: 12));
        } catch (e) {
          // إن حذف المعلم الحلقة أو أخرج الطفل منها، نفصلها ونعيد المحاولة لاحقًا.
          if (circle != null && !await _circleMemberOk(circle, pid)) {
            c.circleCode = '';
            c.circleName = '';
            c.circlePoints = 0;
            st.updateChild(c);
          }
          rethrow;
        }
        if (circle != null) c.circlePoints += chunk;
        if (cup != null) c.cupPoints += chunk;
        c.onlineTotal += chunk;
        c.weekPoints += chunk;
        c.pendingPoints -= chunk;
      }
      st.updateChild(pending.first);
      ok = true;
    } catch (_) {
      // نعيد المحاولة لاحقًا مع التراجع.
    } finally {
      _flushing = false;
      _onFlushResult(ok);
    }
  }

  Future<void> leave(ChildProfile c) async {
    if (!await ensure()) return;
    try {
      await _db.collection('players').doc(playerId(c)).delete();
      await _db.collection('leagues').doc(weekKey(c.ageBand)).collection('entries').doc(playerId(c)).delete();
      if (c.circleCode.isNotEmpty) {
        await _db.collection('circles').doc(c.circleCode).collection('members').doc(playerId(c)).delete();
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------- القراءة

  Future<List<RankRow>> weekBoard(int band) async {
    if (!await ensure()) return const [];
    final q = await _db
        .collection('leagues')
        .doc(weekKey(band))
        .collection('entries')
        .orderBy('points', descending: true)
        .limit(50)
        .get();
    return q.docs.map((d) => RankRow.from(d.id, d.data(), 'points')).toList();
  }

  Future<List<RankRow>> cupBoard(int band) async {
    if (!await ensure()) return const [];
    final q = await _db
        .collection('cups')
        .doc(cupKeyFor(band))
        .collection('entries')
        .orderBy('points', descending: true)
        .limit(50)
        .get();
    return q.docs.map((d) => RankRow.from(d.id, d.data(), 'points')).toList();
  }

  Future<List<RankRow>> allTimeBoard() async {
    if (!await ensure()) return const [];
    final q = await _db.collection('players').orderBy('total', descending: true).limit(50).get();
    return q.docs.map((d) => RankRow.from(d.id, d.data(), 'total')).toList();
  }

  /// ترتيب الطفل في أسبوعه: عدد من يزيدون عليه + 1.
  Future<int?> myWeekRank(ChildProfile c) async {
    if (!await ensure()) return null;
    try {
      final agg = await _db
          .collection('leagues')
          .doc(weekKey(c.ageBand))
          .collection('entries')
          .where('points', isGreaterThan: c.weekPoints)
          .count()
          .get();
      return (agg.count ?? 0) + 1;
    } catch (_) {
      return null;
    }
  }

  /// عدد الأطفال في كل منزلة من منازل الهرم.
  Future<List<int>> pyramidCounts() async {
    if (!await ensure()) return const [];
    final counts = <int>[];
    for (final t in tiers) {
      final agg = await _db.collection('players').where('total', isGreaterThanOrEqualTo: t.$2).count().get();
      counts.add(agg.count ?? 0);
    }
    // تحويل «من بلغ الحد» إلى «من في المنزلة بالضبط».
    return [for (var i = 0; i < counts.length; i++) counts[i] - (i + 1 < counts.length ? counts[i + 1] : 0)];
  }

  // ---------------------------------------------------------------- تحدي صديق

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// ينشئ تحديًا بخمسة أسئلة ونتيجة المنشئ، ويعيد رمزًا من 6 خانات يشاركه الوالد.
  Future<String?> createChallenge(ChildProfile c, List<String> qids, int score) async {
    if (!await ensure()) return null;
    final now = DateTime.now().microsecondsSinceEpoch;
    var seed = now ^ uid.hashCode;
    final code = List.generate(6, (_) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return _codeChars[seed % _codeChars.length];
    }).join();
    try {
      await _db.collection('challenges').doc(code).set({
        'band': c.ageBand,
        'qids': qids,
        'aNick': c.nick,
        'aNa': c.nickA,
        'aNb': c.nickB,
        'aSymbol': c.symbol,
        'aScore': score,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getChallenge(String code) async {
    if (!await ensure()) return null;
    try {
      final d = await _db.collection('challenges').doc(code.trim().toUpperCase()).get();
      return d.exists ? d.data() : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> answerChallenge(String code, ChildProfile c, int score) async {
    if (!await ensure()) return false;
    try {
      await _db.collection('challenges').doc(code).update({
        'bNick': c.nick,
        'bNa': c.nickA,
        'bNb': c.nickB,
        'bSymbol': c.symbol,
        'bScore': score,
        'bAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------- الحلقات

  String _newCode() {
    var seed = DateTime.now().microsecondsSinceEpoch ^ uid.hashCode;
    return List.generate(6, (_) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return _codeChars[seed % _codeChars.length];
    }).join();
  }

  Future<bool> _circleMemberOk(String code, String pid) async {
    try {
      final d = await _db.collection('circles').doc(code).get();
      if (!d.exists) return false;
      final m = await _db.collection('circles').doc(code).collection('members').doc(pid).get();
      return m.exists;
    } catch (_) {
      return true; // خطأ شبكة: لا نفصل الطفل.
    }
  }

  /// ينشئ حلقة جديدة (للمعلم أو الوالد) ويعيد رمزها.
  /// ينشئ حلقة باسم من القائمة المعتمدة ورقم، ويعيد رمزها. لا نص حر.
  Future<String?> createCircle(int nameKey, int number) async {
    if (!await ensure()) return null;
    for (var attempt = 0; attempt < 3; attempt++) {
      final code = _newCode();
      try {
        final ref = _db.collection('circles').doc(code);
        if ((await ref.get()).exists) continue;
        await ref.set({'nameKey': nameKey, 'num': number, 'owner': uid, 'createdAt': FieldValue.serverTimestamp()});
        return code;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> circleName(String code) async {
    if (!await ensure()) return null;
    try {
      final d = await _db.collection('circles').doc(code.trim().toUpperCase()).get();
      if (!d.exists) return null;
      final j = d.data()!;
      return circleDisplayName((j['nameKey'] as num?)?.toInt() ?? 0, (j['num'] as num?)?.toInt() ?? 1);
    } catch (_) {
      return null;
    }
  }

  /// ترتيب الحلقة لحظيًا (Real-time Listener): يتحدّث فور تغيّر أي نقطة.
  Stream<List<RankRow>> watchCircle(String code) => _db
      .collection('circles')
      .doc(code)
      .collection('members')
      .orderBy('points', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map((d) => RankRow.from(d.id, d.data(), 'points')).toList());


  /// انضمام الطفل إلى حلقة برمزها. يعيد رسالة خطأ أو null عند النجاح.
  Future<String?> joinCircle(AppState st, ChildProfile c, String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) return 'الرمز من 6 خانات';
    if (!c.onlineEnabled) return 'فعّل المنافسة أون لاين أولًا';
    if (!c.nickReady) return 'اختر لقب الطفل من القائمة أولًا';
    final name = await circleName(code);
    if (name == null) return 'لم نجد حلقة بهذا الرمز';
    try {
      final ref = _db.collection('circles').doc(code).collection('members').doc(playerId(c));
      final snap = await ref.get();
      if (snap.exists) {
        c.circlePoints = (snap.data()?['points'] as num?)?.toInt() ?? 0;
      } else {
        await ref.set({
          'nick': c.nick,
          'na': c.nickA,
          'nb': c.nickB,
          'symbol': c.symbol,
          'points': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        c.circlePoints = 0;
      }
      c.circleCode = code;
      c.circleName = name;
      st.updateChild(c);
      return null;
    } catch (_) {
      return 'تعذّر الانضمام، حاول لاحقًا';
    }
  }

  Future<void> leaveCircle(AppState st, ChildProfile c) async {
    final code = c.circleCode;
    c.circleCode = '';
    c.circleName = '';
    c.circlePoints = 0;
    st.updateChild(c);
    if (code.isEmpty || !await ensure()) return;
    try {
      await _db.collection('circles').doc(code).collection('members').doc(playerId(c)).delete();
    } catch (_) {}
  }

  Future<List<RankRow>> circleBoard(String code) async {
    if (!await ensure()) return const [];
    final q = await _db
        .collection('circles')
        .doc(code)
        .collection('members')
        .orderBy('points', descending: true)
        .limit(100)
        .get();
    return q.docs.map((d) => RankRow.from(d.id, d.data(), 'points')).toList();
  }

  /// للمعلم: إخراج عضو من حلقته.
  Future<bool> removeMember(String code, String pid) async {
    if (!await ensure()) return false;
    try {
      await _db.collection('circles').doc(code).collection('members').doc(pid).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// للمعلم: حذف الحلقة (يبقى الأعضاء حتى يُفصلوا تلقائيًا عند أول مزامنة).
  Future<bool> deleteCircle(String code) async {
    if (!await ensure()) return false;
    try {
      await _db.collection('circles').doc(code).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------- المسابقة المباشرة

  /// ينشئ غرفة مسابقة مباشرة (للمعلم) ويعيد رمزها.
  Future<String?> createRoom(int band, List<String> qids) async {
    if (!await ensure()) return null;
    for (var attempt = 0; attempt < 3; attempt++) {
      final code = _newCode();
      try {
        final ref = _db.collection('rooms').doc(code);
        if ((await ref.get()).exists) continue;
        await ref.set({
          'owner': uid,
          'band': band,
          'qids': qids,
          'index': 0,
          'state': 'wait',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return code;
      } catch (_) {}
    }
    return null;
  }

  Stream<LiveRoom?> roomStream(String code) => _db
      .collection('rooms')
      .doc(code)
      .snapshots()
      .map((d) => d.exists && d.data() != null ? LiveRoom.from(d.data()!) : null);

  Stream<List<LivePlayer>> roomPlayers(String code) => _db
      .collection('rooms')
      .doc(code)
      .collection('players')
      .snapshots()
      .map((q) => q.docs.map((d) => LivePlayer.from(d.id, d.data())).toList()
        ..sort((a, b) => b.score.compareTo(a.score)));

  Future<bool> setRoom(String code, {required int index, required String state}) async {
    if (!await ensure()) return false;
    try {
      await _db.collection('rooms').doc(code).update({'index': index, 'state': state});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteRoom(String code) async {
    if (!await ensure()) return;
    try {
      await _db.collection('rooms').doc(code).delete();
    } catch (_) {}
  }

  /// انضمام الطفل لغرفة. يعيد (رسالة خطأ، نقاطه، آخر سؤال أجابه).
  Future<(String?, int, int)> joinRoom(ChildProfile c, String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) return ('الرمز من 6 خانات', 0, -1);
    if (!c.onlineEnabled || !c.nickReady) return ('اطلب من والديك تفعيل المنافسة واختيار لقبك', 0, -1);
    if (!await ensure()) return ('تعذّر الاتصال بالإنترنت', 0, -1);
    try {
      final room = await _db.collection('rooms').doc(code).get();
      if (!room.exists) return ('لم نجد مسابقة بهذا الرمز', 0, -1);
      if (room.data()?['state'] == 'end') return ('انتهت هذه المسابقة', 0, -1);
      final ref = _db.collection('rooms').doc(code).collection('players').doc(playerId(c));
      final snap = await ref.get();
      if (snap.exists) {
        final d = snap.data()!;
        return (null, (d['score'] as num?)?.toInt() ?? 0, (d['answered'] as num?)?.toInt() ?? -1);
      }
      await ref.set({
        'nick': c.nick,
        'na': c.nickA,
        'nb': c.nickB,
        'symbol': c.symbol,
        'score': 0,
        'answered': -1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (null, 0, -1);
    } catch (_) {
      return ('تعذّر الدخول، حاول مرة أخرى', 0, -1);
    }
  }

  Future<bool> answerRoom(String code, ChildProfile c, int index, int newScore) async {
    if (!await ensure()) return false;
    try {
      await _db.collection('rooms').doc(code).collection('players').doc(playerId(c)).update({
        'answered': index,
        'score': newScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> report(String pid) async {
    if (!await ensure()) return;
    try {
      await _db.collection('reports').add({'target': pid, 'createdAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}

class RankRow {
  final String id;
  final String nick;
  final String symbol;
  final int points;
  const RankRow(this.id, this.nick, this.symbol, this.points);

  factory RankRow.from(String id, Map<String, dynamic> d, String field) => RankRow(
        id,
        (d['nick'] ?? '').toString(),
        (d['symbol'] ?? 'star').toString(),
        (d[field] as num?)?.toInt() ?? 0,
      );
}

class LiveRoom {
  final int band;
  final List<String> qids;
  final int index;
  final String state; // wait | q | end
  const LiveRoom(this.band, this.qids, this.index, this.state);

  factory LiveRoom.from(Map<String, dynamic> d) => LiveRoom(
        (d['band'] as num?)?.toInt() ?? 0,
        ((d['qids'] as List?) ?? const []).map((e) => e.toString()).toList(),
        (d['index'] as num?)?.toInt() ?? 0,
        (d['state'] ?? 'wait').toString(),
      );
}

class LivePlayer {
  final String id;
  final String nick;
  final String symbol;
  final int score;
  final int answered;
  const LivePlayer(this.id, this.nick, this.symbol, this.score, this.answered);

  factory LivePlayer.from(String id, Map<String, dynamic> d) => LivePlayer(
        id,
        (d['nick'] ?? '').toString(),
        (d['symbol'] ?? 'star').toString(),
        (d['score'] as num?)?.toInt() ?? 0,
        (d['answered'] as num?)?.toInt() ?? -1,
      );
}
