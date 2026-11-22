import 'dart:math';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/data/content_repository.dart';
import 'package:rawdah/core/data/progress_repository.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/quizzes/domain/quiz_repository.dart';

class LocalQuizRepository implements QuizRepository {
  final ContentRepository content;
  final ProgressRepository progress;
  final Random _random;

  LocalQuizRepository({required this.content, required this.progress, Random? random})
      : _random = random ?? Random();

  @override
  List<Question> pool(int band) => content.questionsFor(band);

  @override
  List<Question> dailyChallenge(int band, String dayKey) {
    final seed = int.tryParse(dayKey.replaceAll('-', '')) ?? 0;
    return (List.of(pool(band))..shuffle(Random(seed))).take(3).toList();
  }

  @override
  List<Question> quickQuiz(int band, {int count = 5}) =>
      (List.of(pool(band))..shuffle(_random)).take(count).toList();

  @override
  List<Question> reviewSet(ChildProfile child, {int count = 5}) =>
      child.wrongQuestions.map(content.questionById).whereType<Question>().take(count).toList();

  @override
  void recordAnswer(String questionId, bool correct) => progress.recordAnswer(questionId, correct);

  @override
  bool completeSession(String completionId, {int stars = 3}) =>
      progress.completeActivity(completionId, stars: stars);
}
