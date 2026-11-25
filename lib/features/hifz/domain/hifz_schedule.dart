/// جدول مراجعة المحفوظ بالتكرار المتباعد: كل مراجعة ناجحة تبعد الموعد التالي،
/// والتعثّر يعيد السورة لمراجعة الغد. منطق صافٍ بلا واجهة ولا تخزين.
library;

/// الفواصل بالأيام لكل مستوى.
const kHifzIntervals = [1, 3, 7, 14, 30, 60];
const kHifzMaxLevel = 5;

/// رقم اليوم المحلي منذ ١٩٧٠ (يتجاهل الساعة).
int dayNumber(DateTime t) => DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;

class HifzEntry {
  final int surah;
  final int level;
  final int due;
  final int reviews;
  const HifzEntry(this.surah, {this.level = 0, required this.due, this.reviews = 0});

  /// حفظ جديد: أول مراجعة غدًا.
  factory HifzEntry.memorized(int surah, int today) => HifzEntry(surah, due: today + kHifzIntervals[0]);

  bool isDue(int today) => due <= today;
  int overdueDays(int today) => today - due;

  /// قوة الحفظ من ٠ إلى ١ للعرض.
  double get strength => level / kHifzMaxLevel;

  /// متقن: وصل أعلى مستوى.
  bool get mastered => level >= kHifzMaxLevel;

  HifzEntry review({required bool ok, required int today}) {
    if (!ok) return HifzEntry(surah, level: 0, due: today + 1, reviews: reviews + 1);
    final next = (level + 1).clamp(0, kHifzMaxLevel);
    return HifzEntry(surah, level: next, due: today + kHifzIntervals[next], reviews: reviews + 1);
  }

  List<int> toJson() => [level, due, reviews];

  static HifzEntry? fromJson(String key, Object? v) {
    final s = int.tryParse(key);
    if (s == null || v is! List || v.length < 2) return null;
    int at(int i) => i < v.length && v[i] is num ? (v[i] as num).toInt() : 0;
    return HifzEntry(s, level: at(0).clamp(0, kHifzMaxLevel), due: at(1), reviews: at(2));
  }

  @override
  bool operator ==(Object o) =>
      o is HifzEntry && o.surah == surah && o.level == level && o.due == due && o.reviews == reviews;
  @override
  int get hashCode => Object.hash(surah, level, due, reviews);
}

/// السور المستحقة اليوم، الأقدم تأخرًا أولًا ثم الأضعف حفظًا.
List<HifzEntry> dueToday(Iterable<HifzEntry> all, int today) {
  final d = all.where((e) => e.isDue(today)).toList()
    ..sort((a, b) {
      final o = b.overdueDays(today).compareTo(a.overdueDays(today));
      return o != 0 ? o : a.level.compareTo(b.level);
    });
  return d;
}

/// نص قصير لموعد المراجعة القادم.
String nextReviewLabel(HifzEntry e, int today) {
  final n = e.due - today;
  if (n <= 0) return 'راجعها اليوم';
  if (n == 1) return 'مراجعتها بكرة';
  if (n == 2) return 'مراجعتها بعد يومين';
  if (n <= 10) return 'مراجعتها بعد $n أيام';
  return 'مراجعتها بعد $n يوم';
}
