import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/features/competition/data/cached_competition_repository.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/features/competition/domain/competition_repository.dart';

/// خادم وهمي يمكن قطع اتصاله.
class FakeRemote implements CompetitionRepository {
  bool online = true;
  List<RankRow> rows = const [RankRow('u_1', 'نجم الهدى', 'star', 40), RankRow('u_2', 'بدر', 'moon', 25)];

  Future<List<RankRow>> _get() async {
    if (!online) throw Exception('لا يوجد اتصال');
    return rows;
  }

  @override
  Future<List<RankRow>> weekBoard(int band) => _get();
  @override
  Future<List<RankRow>> cupBoard(int band) => _get();
  @override
  Future<List<RankRow>> allTimeBoard() => _get();
  @override
  Future<List<RankRow>> circleBoard(String code) => _get();
  @override
  Future<int?> myWeekRank(ChildProfile c) async => null;
  @override
  Future<List<int>> pyramidCounts() async => const [];
  @override
  Stream<LiveRoom?> roomStream(String code) => const Stream.empty();
  @override
  Stream<List<LivePlayer>> roomPlayers(String code) => const Stream.empty();
}

void main() {
  test('بلا اتصال: تُعرض آخر نسخة مخزّنة مع علامة المصدر', () async {
    final remote = FakeRemote();
    final repo = CachedCompetitionRepository(remote, MemoryLocalStore());

    final live = await repo.weekBoard(1) as BoardRows;
    expect(live.fromCache, isFalse);
    expect(live.map((r) => r.nick), ['نجم الهدى', 'بدر']);

    await Future<void>.delayed(Duration.zero); // انتظار الكتابة في المخزن
    remote.online = false;
    final cached = await repo.weekBoard(1) as BoardRows;
    expect(cached.fromCache, isTrue);
    expect(cached.first.points, 40);
    expect(cached.fetchedAt, isNotNull);
  });

  test('بلا اتصال وبلا نسخة سابقة: يظهر الخطأ لتعرض الشاشة رسالة الاتصال', () async {
    final remote = FakeRemote()..online = false;
    final repo = CachedCompetitionRepository(remote, MemoryLocalStore());
    expect(repo.allTimeBoard(), throwsException);
  });

  test('خادم بطيء: المهلة تعيد النسخة المخزّنة', () async {
    final store = MemoryLocalStore();
    final remote = FakeRemote();
    await CachedCompetitionRepository(remote, store).allTimeBoard();
    await Future<void>.delayed(Duration.zero);
    final slow = _SlowRemote(remote);
    final repo = CachedCompetitionRepository(slow, store, timeout: const Duration(milliseconds: 50));
    final r = await repo.allTimeBoard() as BoardRows;
    expect(r.fromCache, isTrue);
  });
}

class _SlowRemote extends FakeRemote {
  _SlowRemote(FakeRemote base) {
    rows = base.rows;
  }
  @override
  Future<List<RankRow>> allTimeBoard() => Future.delayed(const Duration(seconds: 2), () => rows);
}
