import 'dart:math';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/features/islamic/data/islamic_content.dart';
import 'package:rawdah/features/learn/domain/letters.dart';

/// بنك أسئلة يُبنى من بيانات التطبيق الموثقة نفسها (أرقام السور وعدد آياتها،
/// معاني الأسماء الحسنى، ترتيب الأشهر، نقاط الحروف)، فيكبر البنك بلا كتابة يدوية
/// وبلا خطأ في المعلومة. المعرفات ثابتة فيعمل معها محرك الإتقان.
List<Question> buildGeneratedQuestions() {
  final out = <Question>[];
  final r = Random(42);

  List<String> numOpts(int ans, {int spread = 3}) {
    final s = <int>{ans};
    var d = 1;
    while (s.length < 3) {
      final v = ans + (r.nextBool() ? d : -d);
      if (v > 0) s.add(v);
      d = d % spread + 1;
      if (s.length < 3 && d == 1) spread++;
    }
    return [for (final v in s.toList()..shuffle(r)) '$v'];
  }

  // ما السورة التي بعد هذه في ترتيب المصحف (للسور المتتالية الموجودة)
  final byNum = {for (final s in kSurahs) s.number: s};
  final names = [for (final s in kSurahs) s.name];
  for (final s in kSurahs) {
    final nx = byNum[s.number + 1];
    if (nx == null) continue;
    final wrong = (names.where((x) => x != nx.name && x != s.name).toList()..shuffle(r)).take(2);
    final o = [nx.name, ...wrong]..shuffle(r);
    out.add(Question('gen_next_${s.number}', 1, 'ما السورة التي تأتي بعد سورة ${s.name} في المصحف؟', o, o.indexOf(nx.name), 'بعد سورة ${s.name} تأتي سورة ${nx.name}.'));
  }
  // في أي سورة هذه الآية؟ (الآية الأولى بنصها من المصحف)
  for (final s in kSurahs) {
    if (s.number == 1 || s.ayat.isEmpty) continue;
    final wrong = (names.where((x) => x != s.name).toList()..shuffle(r)).take(2);
    final o = [s.name, ...wrong]..shuffle(r);
    out.add(Question('gen_where_${s.number}', s.ayat.length <= 8 ? 1 : 2, 'في أي سورة هذه الآية: ﴿${s.ayat.first}﴾؟', o, o.indexOf(s.name), 'هذه أول آية في سورة ${s.name}.'));
  }
  for (final s in kSurahs) {
    final n = s.ayat.length;
    final o1 = numOpts(n);
    out.add(Question('gen_ayat_${s.number}', n <= 8 ? 0 : 1, 'كم عدد آيات سورة ${s.name}؟', o1, o1.indexOf('$n'), 'سورة ${s.name} عدد آياتها $n.'));
    final o2 = numOpts(s.number, spread: 4);
    out.add(Question('gen_num_${s.number}', 2, 'ما رقم سورة ${s.name} في المصحف؟', o2, o2.indexOf('${s.number}'), 'سورة ${s.name} رقمها ${s.number}.'));
  }

  for (var i = 0; i < kGodNames.length; i++) {
    final g = kGodNames[i];
    final wrong = [for (final x in kGodNames) if (x.name != g.name) x.meaning]..shuffle(r);
    final opts = [g.meaning, ...wrong.take(2)]..shuffle(r);
    out.add(Question('gen_name_$i', 1, 'ما معنى اسم الله ${g.name}؟', opts, opts.indexOf(g.meaning), '${g.name}: ${g.meaning}.'));
  }

  const months = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
  for (var i = 0; i < months.length; i++) {
    final next = months[(i + 1) % 12];
    final wrong = [for (final m in months) if (m != next && m != months[i]) m]..shuffle(r);
    final opts = [next, ...wrong.take(2)]..shuffle(r);
    out.add(Question('gen_month_$i', 1, 'أي شهر هجري يأتي بعد ${months[i]}؟', opts, opts.indexOf(next), 'بعد ${months[i]} يأتي $next.'));
  }

  for (final l in kLetters) {
    final n = l.dots.abs();
    final opts = ['بلا نقاط', 'نقطة واحدة', 'نقطتان', 'ثلاث نقاط'];
    final ans = opts[n];
    final where = n == 0 ? '' : (l.dots > 0 ? ' فوقه' : ' تحته');
    out.add(Question('gen_dots_${l.char}', 0, 'كم نقطة في حرف ${l.name} (${l.char})؟', opts, opts.indexOf(ans), 'حرف ${l.name}: $ans$where.'));
  }
  // عواصم الدول العربية والإسلامية
  final caps = kCapitals.map((e) => e.$2).toList();
  for (var i = 0; i < kCapitals.length; i++) {
    final (country, cap) = kCapitals[i];
    final wrong = (caps.where((x) => x != cap).toList()..shuffle(r)).take(2);
    final o = [cap, ...wrong]..shuffle(r);
    out.add(Question('gen_cap_$i', i < 8 ? 1 : 2, 'ما عاصمة $country؟', o, o.indexOf(cap), 'عاصمة $country هي $cap.'));
  }
  // جدول الضرب
  for (var a = 2; a <= 10; a++) {
    for (var b = 2; b <= 10; b++) {
      if (b < a) continue;
      final o = numOpts(a * b, spread: a);
      out.add(Question('gen_mul_${a}_$b', 1, 'كم ناتج ‪$a × $b‬؟', o, o.indexOf('${a * b}'), '‪$a × $b = ${a * b}‬'));
    }
  }
  return out;
}

const kCapitals = <(String, String)>[
  ('السعودية', 'الرياض'), ('مصر', 'القاهرة'), ('الإمارات', 'أبوظبي'), ('الكويت', 'الكويت'),
  ('قطر', 'الدوحة'), ('البحرين', 'المنامة'), ('عمان', 'مسقط'), ('الأردن', 'عمّان'),
  ('اليمن', 'صنعاء'), ('العراق', 'بغداد'), ('سوريا', 'دمشق'), ('لبنان', 'بيروت'),
  ('فلسطين', 'القدس'), ('المغرب', 'الرباط'), ('الجزائر', 'الجزائر'), ('تونس', 'تونس'),
  ('ليبيا', 'طرابلس'), ('السودان', 'الخرطوم'), ('موريتانيا', 'نواكشوط'), ('الصومال', 'مقديشو'),
  ('جيبوتي', 'جيبوتي'), ('جزر القمر', 'موروني'), ('تركيا', 'أنقرة'), ('باكستان', 'إسلام آباد'),
  ('إندونيسيا', 'جاكرتا'), ('ماليزيا', 'كوالالمبور'), ('أفغانستان', 'كابل'), ('بنغلاديش', 'دكا'),
  ('نيجيريا', 'أبوجا'), ('السنغال', 'داكار'),
];

final List<Question> kGeneratedQuestions = buildGeneratedQuestions();
