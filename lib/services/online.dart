import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../state/app_state.dart';

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

  Future<bool> ensure() async {
    if (_ready && uid != null) return true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: _options);
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
          'symbol': c.symbol,
          'band': c.ageBand,
          'total': c.onlineTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      } else {
        await ref.set({
          'nick': c.nick,
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
    _flushTimer ??= Timer.periodic(const Duration(seconds: 10), (_) => flush(st));
  }

  Future<void> flush(AppState st) async {
    if (_flushing) return;
    final pending = st.children.where((c) => c.onlineEnabled && c.pendingPoints > 0).toList();
    if (pending.isEmpty) {
      _flushTimer?.cancel();
      _flushTimer = null;
      return;
    }
    if (!await ensure()) return;
    _flushing = true;
    try {
      for (final c in pending) {
        final chunk = c.pendingPoints > 60 ? 60 : c.pendingPoints;
        await _syncWeek(c);
        final pid = playerId(c);
        final batch = _db.batch();
        batch.set(_db.collection('players').doc(pid), {
          'nick': c.nick,
          'symbol': c.symbol,
          'band': c.ageBand,
          'total': c.onlineTotal + chunk,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(_db.collection('leagues').doc(c.weekKey).collection('entries').doc(pid), {
          'nick': c.nick,
          'symbol': c.symbol,
          'points': c.weekPoints + chunk,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await batch.commit().timeout(const Duration(seconds: 12));
        c.onlineTotal += chunk;
        c.weekPoints += chunk;
        c.pendingPoints -= chunk;
      }
      st.updateChild(pending.first);
    } catch (_) {
      // نعيد المحاولة في الدورة القادمة.
    } finally {
      _flushing = false;
    }
  }

  Future<void> leave(ChildProfile c) async {
    if (!await ensure()) return;
    try {
      await _db.collection('players').doc(playerId(c)).delete();
      await _db.collection('leagues').doc(weekKey(c.ageBand)).collection('entries').doc(playerId(c)).delete();
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
