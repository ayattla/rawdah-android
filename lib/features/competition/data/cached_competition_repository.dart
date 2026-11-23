import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/features/competition/domain/competition_repository.dart';

/// قائمة ترتيب تعرف مصدرها: من الخادم الآن، أو من النسخة المخزّنة عند انقطاع الاتصال.
class BoardRows extends ListBase<RankRow> {
  final List<RankRow> _rows;
  final bool fromCache;
  final DateTime? fetchedAt;
  BoardRows(this._rows, {this.fromCache = false, this.fetchedAt});

  @override
  int get length => _rows.length;
  @override
  set length(int v) => throw UnsupportedError('قائمة للقراءة فقط');
  @override
  RankRow operator [](int i) => _rows[i];
  @override
  void operator []=(int i, RankRow v) => throw UnsupportedError('قائمة للقراءة فقط');
}

/// Offline-First للوحات الترتيب: يطلب من الخادم بمهلة قصيرة، ويخزّن كل نتيجة ناجحة،
/// وعند انقطاع الاتصال يعرض آخر نسخة مخزّنة مع وقت تحديثها بدل شاشة خطأ.
class CachedCompetitionRepository implements CompetitionRepository {
  final CompetitionRepository remote;
  final LocalStore store;
  final Duration timeout;
  CachedCompetitionRepository(this.remote, this.store, {this.timeout = const Duration(seconds: 6)});

  Future<List<RankRow>> _cached(String key, Future<List<RankRow>> Function() fetch) async {
    final k = 'board:$key';
    try {
      final rows = await fetch().timeout(timeout);
      unawaited(store.write(
          k,
          jsonEncode({
            'at': DateTime.now().toIso8601String(),
            'rows': [for (final r in rows) {'id': r.id, 'nick': r.nick, 'symbol': r.symbol, 'points': r.points}],
          })));
      return BoardRows(rows, fetchedAt: DateTime.now());
    } catch (_) {
      final raw = await store.read(k);
      if (raw == null) rethrow;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final rows = [
        for (final r in (j['rows'] as List).cast<Map>())
          RankRow(r['id'] as String, r['nick'] as String, r['symbol'] as String, (r['points'] as num).toInt()),
      ];
      return BoardRows(rows, fromCache: true, fetchedAt: DateTime.tryParse(j['at'] as String? ?? ''));
    }
  }

  @override
  Future<List<RankRow>> weekBoard(int band) =>
      _cached('week_${Online.weekIndex()}_$band', () => remote.weekBoard(band));
  @override
  Future<List<RankRow>> cupBoard(int band) => _cached('cup_$band', () => remote.cupBoard(band));
  @override
  Future<List<RankRow>> allTimeBoard() => _cached('all', remote.allTimeBoard);
  @override
  Future<List<RankRow>> circleBoard(String code) => _cached('circle_$code', () => remote.circleBoard(code));

  /// اللحظي يمر كما هو، مع تحديث النسخة المخزّنة عند كل تغيير.
  @override
  Stream<List<RankRow>> watchCircle(String code) => remote.watchCircle(code).map((rows) {
        unawaited(store.write(
            'board:circle_$code',
            jsonEncode({
              'at': DateTime.now().toIso8601String(),
              'rows': [for (final r in rows) {'id': r.id, 'nick': r.nick, 'symbol': r.symbol, 'points': r.points}],
            })));
        return BoardRows(rows, fetchedAt: DateTime.now());
      });

  // هذه لحظية بطبيعتها فلا تُخزَّن
  @override
  Future<int?> myWeekRank(ChildProfile c) => remote.myWeekRank(c);
  @override
  Future<List<int>> pyramidCounts() => remote.pyramidCounts();
  @override
  Stream<LiveRoom?> roomStream(String code) => remote.roomStream(code);
  @override
  Stream<List<LivePlayer>> roomPlayers(String code) => remote.roomPlayers(code);
}
