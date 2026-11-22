import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/data/content_repository.dart';
import 'package:rawdah/core/data/progress_repository.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/quizzes/data/quiz_repository_impl.dart';
import 'package:rawdah/features/quizzes/domain/quiz_session.dart';
import 'package:rawdah/features/quizzes/presentation/quiz_controller.dart';

/// مستودع تقدم وهمي يسجّل ما يصله، بلا تخزين.
class FakeProgress implements ProgressRepository {
  final answers = <(String, bool)>[];
  final completed = <String>[];
  @override
  ChildProfile? get currentChild => null;
  @override
  void recordAnswer(String questionId, bool correct) => answers.add((questionId, correct));
  @override
  bool completeActivity(String activityId, {int stars = 3}) {
    final first = !completed.contains(activityId);
    completed.add(activityId);
    return first;
  }

  @override
  void recordRaceScore(int score) {}
  @override
  void recordLiveScore(int score) {}
}

const _q1 = Question('t1', 0, 'كم عدد الصلوات المفروضة؟', ['3', '5', '7'], 1, 'خمس صلوات');
const _q2 = Question('t2', 0, 'ماذا نقول قبل الأكل؟', ['بسم الله', 'شكرًا'], 0, 'نسمّي الله');

void main() {
  group('QuizSession', () {
    test('تبدأ من السؤال الأول بلا إجابات', () {
      final s = QuizSession.start([_q1, _q2]);
      expect(s.index, 0);
      expect(s.answered, isFalse);
      expect(s.right, 0);
      expect(s.isLast, isFalse);
    });

    test('حالة الخيارات بعد إجابة خاطئة', () {
      final s = QuizSession.start([_q1]).answer(2);
      expect(s.lastCorrect, isFalse);
      expect(s.optionState(1), 1); // الصحيحة
      expect(s.optionState(2), 2); // اختيار الطفل
      expect(s.optionState(0), 0);
    });

    test('الانتقال يمسح الاختيار ويحفظ النتائج', () {
      final s = QuizSession.start([_q1, _q2]).answer(1).advance();
      expect(s.index, 1);
      expect(s.picked, isNull);
      expect(s.results, [true]);
      expect(s.isLast, isTrue);
    });
  });

  group('QuizController', () {
    late FakeProgress progress;
    late ProviderContainer container;
    const args = QuizArgs(title: 'اختبار', questions: [_q1, _q2], completionId: 'daily_x');

    setUp(() {
      progress = FakeProgress();
      container = ProviderContainer(overrides: [progressRepositoryProvider.overrideWithValue(progress)]);
      addTearDown(container.dispose);
    });

    test('يسجّل الإجابة في المستودع مرة واحدة فقط', () {
      final sub = container.listen(quizControllerProvider(args), (_, __) {});
      addTearDown(sub.close);
      final ctrl = container.read(quizControllerProvider(args).notifier);
      expect(ctrl.answer(1), isTrue);
      expect(ctrl.answer(0), isNull, reason: 'لا تُقبل إجابة ثانية للسؤال نفسه');
      expect(progress.answers, [('t1', true)]);
    });

    test('جلسة كاملة: المكافأة = نجمتان لكل صحيحة + 3 للإتمام', () {
      final sub = container.listen(quizControllerProvider(args), (_, __) {});
      addTearDown(sub.close);
      final ctrl = container.read(quizControllerProvider(args).notifier);
      ctrl.answer(1);
      expect(ctrl.next(), isTrue);
      ctrl.answer(1); // خطأ
      expect(ctrl.next(), isFalse, reason: 'هذا آخر سؤال');
      expect(ctrl.finish(), 1 * 2 + 3);
      expect(progress.completed, ['daily_x']);
      expect(container.read(quizControllerProvider(args)).results, [true, false]);
    });
  });

  group('LocalQuizRepository', () {
    final repo = LocalQuizRepository(content: const BundledContentRepository(), progress: FakeProgress());

    test('تحدي اليوم ثابت لليوم نفسه ومن مستوى الطفل', () {
      final a = repo.dailyChallenge(0, '2026-11-23');
      final b = repo.dailyChallenge(0, '2026-11-23');
      expect(a.map((q) => q.id), b.map((q) => q.id));
      expect(a, hasLength(3));
      expect(a.every((q) => q.band == 0), isTrue);
    });

    test('المسابقة السريعة لا تتجاوز مستوى الطفل', () {
      final qs = repo.quickQuiz(1, count: 20);
      expect(qs, hasLength(20));
      expect(qs.every((q) => q.band <= 1), isTrue);
    });
  });

  test('كل سؤال في بنك الأسئلة سليم البنية', () {
    final ids = <String>{};
    for (final q in kQuestions) {
      expect(ids.add(q.id), isTrue, reason: 'معرّف مكرر: ${q.id}');
      expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
      expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
      expect(q.band, inInclusiveRange(0, 2), reason: q.id);
      expect(q.explain, isNotEmpty, reason: q.id);
    }
  });
}
