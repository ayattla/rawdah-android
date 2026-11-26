import 'dart:math';

/// مهمة من رحلة اليوم: نوع العداد والهدف ونصها.
class DailyQuest {
  final String kind; // correct | tower | activity | review
  final int goal;
  final String text;
  final int stars;
  const DailyQuest(this.kind, this.goal, this.text, this.stars);
}

const _templates = <DailyQuest>[
  DailyQuest('correct', 8, 'أجب ٨ إجابات صحيحة', 3),
  DailyQuest('correct', 15, 'أجب ١٥ إجابة صحيحة', 5),
  DailyQuest('correct', 25, 'أجب ٢٥ إجابة صحيحة', 8),
  DailyQuest('tower', 5, 'حل ٥ ألغاز في برج الألغاز', 4),
  DailyQuest('tower', 10, 'حل ١٠ ألغاز في برج الألغاز', 6),
  DailyQuest('activity', 3, 'أنجز ٣ أنشطة (درس أو لعبة أو قصة)', 4),
  DailyQuest('activity', 5, 'أنجز ٥ أنشطة', 6),
];

const _reviewQuest = DailyQuest('review', 1, 'راجع سورة من محفوظك', 4);

/// أربع مهام لليوم تتغير كل يوم، وتصعب مع مستوى الطفل.
List<DailyQuest> questsFor(DateTime day, {required int level, bool hasHifz = false}) {
  final r = Random(day.year * 10000 + day.month * 100 + day.day);
  final hard = level >= 8;
  final pick = <DailyQuest>[];
  final byKind = <String, List<DailyQuest>>{};
  for (final q in _templates) {
    byKind.putIfAbsent(q.kind, () => []).add(q);
  }
  for (final kind in ['correct', 'tower', 'activity']) {
    final list = byKind[kind]!;
    final i = hard ? list.length - 1 - r.nextInt(min(2, list.length)) : r.nextInt(min(2, list.length));
    pick.add(list[i]);
  }
  pick.add(hasHifz ? _reviewQuest : const DailyQuest('tower', 3, 'حل ٣ ألغاز إضافية', 3));
  return pick;
}

/// نجوم صندوق اليوم عند إتمام كل المهام.
int chestStars(List<DailyQuest> qs) => 10 + qs.fold<int>(0, (n, q) => n + q.stars);
