import 'package:rawdah/core/content/content.dart';

/// مستودع المحتوى: الأسئلة والقصص والدروس.
/// المحتوى اليوم مضمّن في التطبيق ويعمل بلا إنترنت؛ يمكن لاحقًا استبدال التنفيذ
/// بمصدر يُحدَّث من الخادم دون تغيير أي شاشة.
abstract interface class ContentRepository {
  List<Question> questionsFor(int band);
  Question? questionById(String id);
  List<Story> get stories;
  List<Lesson> get lessons;
}

class BundledContentRepository implements ContentRepository {
  const BundledContentRepository();

  @override
  List<Question> questionsFor(int band) => [for (final q in kQuestions) if (q.band <= band) q];

  @override
  Question? questionById(String id) {
    for (final q in kQuestions) {
      if (q.id == id) return q;
    }
    return null;
  }

  @override
  List<Story> get stories => kStories;

  @override
  List<Lesson> get lessons => kLessons;
}
