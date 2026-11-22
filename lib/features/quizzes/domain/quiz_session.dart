import 'package:flutter/foundation.dart';

import 'package:rawdah/core/content/content.dart';

/// حالة جلسة مسابقة واحدة. ثابتة (immutable): كل تغيير ينتج نسخة جديدة،
/// فلا تتغير البيانات من خلف الواجهة، وتسهل كتابة الاختبارات.
@immutable
class QuizSession {
  final List<Question> questions;
  final int index;
  final int? picked;
  final List<bool> results;

  const QuizSession({required this.questions, required this.index, required this.picked, required this.results});

  factory QuizSession.start(List<Question> questions) =>
      QuizSession(questions: List.unmodifiable(questions), index: 0, picked: null, results: const []);

  Question get current => questions[index];
  bool get answered => picked != null;
  bool get isLast => index >= questions.length - 1;
  int get total => questions.length;
  int get right => results.where((r) => r).length;
  bool get lastCorrect => answered && picked == current.answer;

  /// حالة الخيار للعرض: 0 عادي، 1 الإجابة الصحيحة، 2 اختيار الطفل الخاطئ.
  int optionState(int k) {
    if (!answered) return 0;
    if (k == current.answer) return 1;
    return k == picked ? 2 : 0;
  }

  QuizSession answer(int k) => QuizSession(
        questions: questions,
        index: index,
        picked: k,
        results: List.unmodifiable([...results, k == current.answer]),
      );

  QuizSession advance() => QuizSession(questions: questions, index: index + 1, picked: null, results: results);
}
