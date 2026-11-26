import 'dart:math';

import 'package:rawdah/core/content/content.dart';

/// فواصل صناديق الإتقان بالأيام: السؤال يعود حتى يستقر في الصندوق الأخير.
const kMasteryGaps = [0, 1, 2, 4, 8, 16];
const kMasteredBox = 4;

/// حالة السؤال بعد الإجابة: الصح يرفعه صندوقا، والخطأ يعيده للبداية اليوم.
List<int> masteryAfter(List<int>? prev, bool correct, int today) {
  final box = prev == null ? 0 : prev[0];
  if (!correct) return [0, today];
  final next = (box + 1).clamp(0, kMasteryGaps.length - 1);
  return [next, today + kMasteryGaps[next]];
}

bool isMastered(List<int>? m) => m != null && m[0] >= kMasteredBox;

/// اختيار ذكي: المستحق للمراجعة أولا، ثم الجديد، ثم غير المتقن، والمتقن أخيرا.
/// فلا ينتهي البنك حتى يتقن الطفل كل سؤال عبر أيام.
List<Question> smartPick(List<Question> pool, Map<String, List<int>> mastery, int today,
    {int count = 5, Random? random}) {
  final r = random ?? Random();
  final due = <Question>[], fresh = <Question>[], learning = <Question>[], done = <Question>[];
  for (final q in pool) {
    final m = mastery[q.id];
    if (m == null) {
      fresh.add(q);
    } else if (isMastered(m)) {
      done.add(q);
    } else if (m[1] <= today) {
      due.add(q);
    } else {
      learning.add(q);
    }
  }
  for (final l in [due, fresh, learning, done]) {
    l.shuffle(r);
  }
  // نخلط قليلا من الجديد مع المستحق حتى لا تكون الجلسة مراجعة فقط
  final out = <Question>[...due.take((count * 0.6).ceil())];
  for (final l in [fresh, due.skip(out.length).toList(), learning, done]) {
    for (final q in l) {
      if (out.length >= count) break;
      if (!out.contains(q)) out.add(q);
    }
  }
  return out..shuffle(r);
}

/// نسبة الإتقان في بنك أسئلة من ٠ إلى ١.
double masteryRatio(Iterable<Question> pool, Map<String, List<int>> mastery) {
  var n = 0, m = 0;
  for (final q in pool) {
    n++;
    if (isMastered(mastery[q.id])) m++;
  }
  return n == 0 ? 0 : m / n;
}
