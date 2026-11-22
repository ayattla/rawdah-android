import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/state/app_state.dart';

/// عقد ميزة المسابقات: من أين تأتي الأسئلة وأين تُسجّل النتائج.
abstract interface class QuizRepository {
  /// 3 أسئلة ثابتة لكل يوم (نفسها لو أعاد الطفل فتح التطبيق).
  List<Question> dailyChallenge(int band, String dayKey);

  /// أسئلة عشوائية من مستوى الطفل.
  List<Question> quickQuiz(int band, {int count = 5});

  /// الأسئلة التي أخطأ فيها الطفل سابقًا.
  List<Question> reviewSet(ChildProfile child, {int count = 5});

  List<Question> pool(int band);

  void recordAnswer(String questionId, bool correct);

  /// يعيد true إذا كانت أول مرة.
  bool completeSession(String completionId, {int stars = 3});
}
