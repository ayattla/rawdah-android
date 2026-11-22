import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/core/data/content_repository.dart';
import 'package:rawdah/core/data/progress_repository.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/features/competition/domain/competition_repository.dart';
import 'package:rawdah/features/quizzes/data/quiz_repository_impl.dart';
import 'package:rawdah/features/quizzes/domain/quiz_repository.dart';

/// حقن التبعيات: كل شاشة تطلب المستودع من هنا، ولا تنشئ مصدر البيانات بنفسها.
/// في الاختبارات نستبدل أي مزوّد بنسخة وهمية عبر ProviderScope(overrides: ...).

/// حالة التطبيق المحمّلة، تُحقن في main بعد التحميل.
final appStateProvider = Provider<AppState>(
  (ref) => throw UnimplementedError('appStateProvider يجب أن يُحقن في main'),
);

final contentRepositoryProvider = Provider<ContentRepository>((ref) => const BundledContentRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => LocalProgressRepository(ref.watch(appStateProvider)),
);

final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => FirestoreCompetitionRepository(Online.instance),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => LocalQuizRepository(
    content: ref.watch(contentRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
  ),
);
