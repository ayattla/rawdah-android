import 'dart:math';

import 'package:rawdah/core/content/content.dart';

/// أسئلة حساب تتولد تلقائيا حسب فئة العمر، فلا تنتهي ولا تتكرر غالبا.
/// البراعم: جمع وطرح حتى ١٠ | المستكشفون: حتى ١٠٠ وجدول ٢-٥ | الفرسان: ضرب وقسمة حتى ١٢.
List<Question> mathQuestions(int band, {int count = 10, Random? random}) {
  final r = random ?? Random();
  final out = <Question>[];
  final seen = <String>{};
  var guard = 0;
  while (out.length < count && guard++ < count * 20) {
    final (raw, answer, explain) = _make(band.clamp(0, 2), r);
    // تضمين من اليسار لليمين حتى تظهر المعادلة بترتيبها الصحيح داخل النص العربي.
    final text = '\u202A$raw\u202C';
    if (!seen.add(text)) continue;
    final options = _options(answer, r);
    out.add(Question('math_${band}_$raw', band, text, [for (final o in options) '$o'], options.indexOf(answer),
        RegExp(r'^\d').hasMatch(explain) ? '\u202A$explain\u202C' : explain));
  }
  return out;
}

(String, int, String) _make(int band, Random r) {
  int n(int min, int max) => min + r.nextInt(max - min + 1);
  switch (band) {
    case 0:
      if (r.nextBool()) {
        final a = n(1, 9), b = n(1, 10 - a);
        return ('$a + $b = ؟', a + b, 'إذا عندك $a وزدت $b يصير المجموع ${a + b}.');
      }
      final a = n(2, 10), b = n(1, a - 1);
      return ('$a − $b = ؟', a - b, 'إذا عندك $a وأخذنا $b يبقى ${a - b}.');
    case 1:
      switch (r.nextInt(3)) {
        case 0:
          final a = n(10, 60), b = n(5, 99 - a);
          return ('$a + $b = ؟', a + b, '$a + $b = ${a + b}');
        case 1:
          final a = n(20, 99), b = n(5, a - 1);
          return ('$a − $b = ؟', a - b, '$a − $b = ${a - b}');
        default:
          final a = n(2, 5), b = n(1, 10);
          return ('$a × $b = ؟', a * b, 'الضرب جمع متكرر: $b مكررة $a مرات = ${a * b}.');
      }
    default:
      switch (r.nextInt(3)) {
        case 0:
          final a = n(3, 12), b = n(3, 12);
          return ('$a × $b = ؟', a * b, '$a × $b = ${a * b}');
        case 1:
          final b = n(2, 12), q = n(2, 12);
          return ('${b * q} ÷ $b = ؟', q, 'لأن $b × $q = ${b * q}.');
        default:
          final a = n(100, 500), b = n(50, 499);
          return ('$a + $b = ؟', a + b, '$a + $b = ${a + b}');
      }
  }
}

/// ثلاثة خيارات قريبة من الجواب الصحيح ومرتبة عشوائيا، كلها موجبة ومختلفة.
List<int> _options(int answer, Random r) {
  final set = <int>{answer};
  final spread = max(2, answer ~/ 5);
  var guard = 0;
  while (set.length < 3 && guard++ < 50) {
    final d = 1 + r.nextInt(spread);
    final v = r.nextBool() ? answer + d : answer - d;
    if (v >= 0) set.add(v);
  }
  var extra = answer + 1;
  while (set.length < 3) {
    set.add(extra++);
  }
  return set.toList()..shuffle(r);
}
