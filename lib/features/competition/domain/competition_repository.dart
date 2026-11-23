import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/competition/data/online_service.dart';

/// مستودع المنافسة: لوحات الترتيب والحلقات والمسابقة المباشرة.
/// لا يحتوي أي دالة لإرسال نص حر، فلا تواصل بين الأطفال.
abstract interface class CompetitionRepository {
  Future<List<RankRow>> weekBoard(int band);
  Future<List<RankRow>> cupBoard(int band);
  Future<List<RankRow>> allTimeBoard();
  Future<List<RankRow>> circleBoard(String code);
  Stream<List<RankRow>> watchCircle(String code);
  Future<int?> myWeekRank(ChildProfile c);
  Future<List<int>> pyramidCounts();
  Stream<LiveRoom?> roomStream(String code);
  Stream<List<LivePlayer>> roomPlayers(String code);
}

/// التنفيذ عبر Firestore (يغلّف خدمة Online الحالية).
class FirestoreCompetitionRepository implements CompetitionRepository {
  final Online _online;
  const FirestoreCompetitionRepository(this._online);

  @override
  Future<List<RankRow>> weekBoard(int band) => _online.weekBoard(band);
  @override
  Future<List<RankRow>> cupBoard(int band) => _online.cupBoard(band);
  @override
  Future<List<RankRow>> allTimeBoard() => _online.allTimeBoard();
  @override
  Future<List<RankRow>> circleBoard(String code) => _online.circleBoard(code);
  @override
  Stream<List<RankRow>> watchCircle(String code) => _online.watchCircle(code);
  @override
  Future<int?> myWeekRank(ChildProfile c) => _online.myWeekRank(c);
  @override
  Future<List<int>> pyramidCounts() => _online.pyramidCounts();
  @override
  Stream<LiveRoom?> roomStream(String code) => _online.roomStream(code);
  @override
  Stream<List<LivePlayer>> roomPlayers(String code) => _online.roomPlayers(code);
}
