import 'package:rawdah/core/state/app_state.dart';

/// مستودع تقدّم الطفل: النجوم والإجابات والأنشطة المنجزة.
/// الواجهات لا تعرف أين تُحفظ البيانات، بل تتعامل مع هذا العقد فقط.
abstract interface class ProgressRepository {
  ChildProfile? get currentChild;
  void recordAnswer(String questionId, bool correct);

  /// يعيد true إذا كانت أول مرة يُنجز فيها النشاط.
  bool completeActivity(String activityId, {int stars = 3});
  void recordRaceScore(int score);
  void recordLiveScore(int score);
}

/// التنفيذ المحلي: يحفظ عبر AppState (SharedPreferences + المخزن المشفّر للوالدين).
class LocalProgressRepository implements ProgressRepository {
  final AppState _state;
  const LocalProgressRepository(this._state);

  @override
  ChildProfile? get currentChild => _state.current;

  @override
  void recordAnswer(String questionId, bool correct) => _state.recordAnswer(questionId, correct);

  @override
  bool completeActivity(String activityId, {int stars = 3}) => _state.complete(activityId, stars: stars);

  @override
  void recordRaceScore(int score) => _state.recordRaceScore(score);

  @override
  void recordLiveScore(int score) => _state.recordLiveScore(score);
}
