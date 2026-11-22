import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/features/quizzes/domain/quiz_session.dart';

/// معطيات جلسة المسابقة. تُنشأ مرة واحدة لكل شاشة.
class QuizArgs {
  final String title;
  final List<Question> questions;
  final String? completionId;
  const QuizArgs({required this.title, required this.questions, this.completionId});
}

/// منطق المسابقة مفصول عن الواجهة: الإجابة والانتقال وحساب المكافأة.
class QuizController extends Notifier<QuizSession> {
  QuizController(this.args);
  final QuizArgs args;

  @override
  QuizSession build() => QuizSession.start(args.questions);

  /// يعيد null إذا كان السؤال مُجابًا من قبل، وإلا صحة الإجابة.
  bool? answer(int option) {
    if (state.answered) return null;
    final question = state.current;
    state = state.answer(option);
    final ok = state.lastCorrect;
    ref.read(quizRepositoryProvider).recordAnswer(question.id, ok);
    return ok;
  }

  /// يعيد false إذا كان هذا آخر سؤال.
  bool next() {
    if (state.isLast) return false;
    state = state.advance();
    return true;
  }

  /// ينهي الجلسة ويعيد عدد نجوم المكافأة للعرض.
  int finish() {
    final id = args.completionId;
    if (id != null) ref.read(quizRepositoryProvider).completeSession(id, stars: 3);
    return state.right * 2 + (id != null ? 3 : 0);
  }
}

/// مزوّد لكل جلسة، يُحذف تلقائيًا عند إغلاق الشاشة.
final quizControllerProvider =
    NotifierProvider.autoDispose.family<QuizController, QuizSession, QuizArgs>(QuizController.new);
