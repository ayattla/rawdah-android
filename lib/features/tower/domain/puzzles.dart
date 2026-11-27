import 'dart:math';

/// برج الألغاز: مولدات لا تنتهي، صعوبتها تكبر مع المستوى.
/// كل لغز سؤال باختيارات، ما عدا السودوكو له شبكة خاصة.

class ChoicePuzzle {
  final String prompt;
  final List<String> shown; // ما يعرض (أرقام النمط أو الكلمات)
  final List<String> options;
  final int answer;
  final String why;
  const ChoicePuzzle(this.prompt, this.shown, this.options, this.answer, this.why);
}

List<String> _opts(int correct, Random r, {int n = 3}) {
  final s = <int>{correct};
  var spread = max(2, correct.abs() ~/ 4);
  while (s.length < n) {
    final v = correct + (r.nextBool() ? 1 : -1) * (1 + r.nextInt(spread));
    if (v >= 0) s.add(v);
    spread++;
  }
  return [for (final v in (s.toList()..shuffle(r))) '$v'];
}

/// أكمل النمط: جمع ثابت ← خطوة أكبر ← مضاعفة ← نمطان متناوبان.
ChoicePuzzle sequencePuzzle(int level, Random r) {
  final n = level < 6 ? 4 : 5;
  late List<int> seq;
  late String why;
  if (level < 4) {
    final step = 1 + r.nextInt(2 + level);
    final a = 1 + r.nextInt(10);
    seq = [for (var i = 0; i <= n; i++) a + step * i];
    why = 'كل مرة نزيد $step';
  } else if (level < 9) {
    final step = 2 + r.nextInt(3 + level);
    final down = r.nextBool() && level > 5;
    final a = down ? step * (n + 2) + r.nextInt(20) : 1 + r.nextInt(20);
    seq = [for (var i = 0; i <= n; i++) down ? a - step * i : a + step * i];
    why = down ? 'كل مرة ننقص $step' : 'كل مرة نزيد $step';
  } else if (level < 15) {
    if (r.nextBool()) {
      final a = 1 + r.nextInt(4);
      seq = [for (var i = 0; i <= n; i++) a * pow(2, i).toInt()];
      why = 'كل عدد ضعف الذي قبله';
    } else {
      final a = 1 + r.nextInt(5);
      seq = [a];
      for (var i = 1; i <= n; i++) {
        seq.add(seq.last + i);
      }
      why = 'الزيادة تكبر: ١ ثم ٢ ثم ٣...';
    }
  } else {
    final x = 1 + r.nextInt(4), y = 2 + r.nextInt(6);
    final a = 1 + r.nextInt(10);
    seq = [a];
    for (var i = 1; i <= n; i++) {
      seq.add(seq.last + (i.isOdd ? x : y));
    }
    why = 'نزيد $x ثم $y بالتناوب';
  }
  return ChoicePuzzle('أكمل النمط', [for (final v in seq.take(n)) '$v'], _opts(seq[n], r, n: level < 6 ? 3 : 4), -1, why)
      ._withAnswer('${seq[n]}');
}

extension on ChoicePuzzle {
  ChoicePuzzle _withAnswer(String a) => ChoicePuzzle(prompt, shown, options, options.indexOf(a), why);
}

/// فئات كلمات للدخيل (نصوص فقط).
const kOddCategories = <String, List<String>>{
  'فواكه': ['تفاح', 'موز', 'برتقال', 'عنب', 'رمان', 'تمر', 'مانجو', 'تين'],
  'خضار': ['جزر', 'خيار', 'طماطم', 'بطاطس', 'بصل', 'خس', 'باذنجان'],
  'ألوان': ['أحمر', 'أزرق', 'أخضر', 'أصفر', 'بنفسجي', 'برتقالي', 'وردي'],
  'أشكال': ['دائرة', 'مربع', 'مثلث', 'مستطيل', 'معين'],
  'أدوات مدرسية': ['قلم', 'ممحاة', 'مسطرة', 'دفتر', 'حقيبة', 'مقلمة'],
  'كواكب': ['عطارد', 'الزهرة', 'الأرض', 'المريخ', 'المشتري', 'زحل'],
  'الصلوات': ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'],
  'أشهر هجرية': ['محرم', 'صفر', 'رجب', 'شعبان', 'رمضان', 'شوال'],
  'مدن سعودية': ['الرياض', 'جدة', 'مكة', 'المدينة', 'الدمام', 'أبها', 'تبوك'],
  'وسائل نقل': ['سيارة', 'طائرة', 'قطار', 'سفينة', 'دراجة', 'حافلة'],
  'أعضاء الجسم': ['العين', 'الأذن', 'الأنف', 'اليد', 'القدم', 'القلب'],
  'أدوات المطبخ': ['ملعقة', 'شوكة', 'صحن', 'كوب', 'قدر', 'سكين'],
};

/// الدخيل: كلمات من فئة واحدة وبينها كلمة غريبة.
ChoicePuzzle oddOnePuzzle(int level, Random r) {
  final cats = kOddCategories.keys.toList()..shuffle(r);
  final main = cats[0], other = cats[1];
  final k = level < 5 ? 3 : (level < 12 ? 4 : 5);
  final words = (List.of(kOddCategories[main]!)..shuffle(r)).take(k - 1).toList();
  final odd = (List.of(kOddCategories[other]!)..shuffle(r)).first;
  final all = [...words, odd]..shuffle(r);
  return ChoicePuzzle('أي كلمة لا تنتمي للمجموعة؟', const [], all, all.indexOf(odd), '$odd من $other، والباقي $main');
}

/// الميزان: رقم ناقص في معادلة.
ChoicePuzzle balancePuzzle(int level, Random r) {
  int n(int a, int b) => a + r.nextInt(b - a + 1);
  late int ans;
  late String text;
  final kind = level < 4 ? 0 : (level < 10 ? r.nextInt(2) : r.nextInt(4));
  switch (kind) {
    case 0:
      final a = n(1, 5 + level * 2), b = n(1, 5 + level * 2);
      ans = b;
      text = '$a + ؟ = ${a + b}';
    case 1:
      final a = n(5, 20 + level * 3), b = n(1, a);
      ans = b;
      text = '$a − ؟ = ${a - b}';
    case 2:
      final a = n(2, 6 + level ~/ 3), b = n(2, 10);
      ans = b;
      text = '$a × ؟ = ${a * b}';
    default:
      final a = n(2, 9), b = n(2, 10);
      ans = b;
      text = '${a * b} ÷ ؟ = $a';
  }
  final opts = _opts(ans, r, n: level < 8 ? 3 : 4);
  return ChoicePuzzle('ما الرقم الناقص؟', ['‪$text‬'], opts, opts.indexOf('$ans'), '‪${text.replaceFirst('؟', '$ans')}‬');
}

/// كلمات لعبة رتب الحروف: جمادات وطبيعة ومصطلحات إسلامية، مقسمة بالطول.
const kScrambleWords = <String>[
  'باب', 'قلم', 'شمس', 'قمر', 'نجم', 'بحر', 'جبل', 'ورد', 'تمر', 'كتب', 'صوم', 'حج', 'دعاء', 'نور', 'ماء', 'بيت', 'رمل', 'سحاب',
  'مسجد', 'كتاب', 'سماء', 'نخلة', 'شجرة', 'زكاة', 'صلاة', 'قرآن', 'كرسي', 'مفتاح', 'ساعة', 'مطر', 'وضوء', 'قبلة', 'هلال', 'مدرسة',
  'حديقة', 'مصباح', 'فانوس', 'سفينة', 'طائرة', 'مكتبة', 'رمضان', 'الكعبة', 'المدينة', 'الصدق', 'الأمانة', 'الرحمة', 'العلم',
  'المعرفة', 'الصبر', 'الشكر', 'التعاون', 'الكواكب', 'الحاسوب', 'المغناطيس', 'البوصلة', 'الاختراع', 'الأخلاق',
];

class ScramblePuzzle {
  final String word;
  final List<String> tiles;
  const ScramblePuzzle(this.word, this.tiles);
}

ScramblePuzzle scramblePuzzle(int level, Random r) {
  final minLen = level < 4 ? 3 : (level < 10 ? 4 : 5);
  final maxLen = level < 4 ? 4 : (level < 10 ? 6 : 9);
  final pool = kScrambleWords.where((w) => w.runes.length >= minLen && w.runes.length <= maxLen).toList();
  final w = pool[r.nextInt(pool.length)];
  final letters = [for (final c in w.runes) String.fromCharCode(c)];
  var tiles = [...letters];
  var guard = 0;
  do {
    tiles = [...letters]..shuffle(r);
  } while (tiles.join() == w && guard++ < 10);
  return ScramblePuzzle(w, tiles);
}

/// سودوكو الصغار ٤×٤: كل صف وعمود ومربع ٢×٢ فيه ١ ٢ ٣ ٤.
class Sudoku4 {
  final List<int> solution; // ١٦ خانة
  final List<bool> given;
  const Sudoku4(this.solution, this.given);

  static bool validSolution(List<int> g) {
    bool ok(Iterable<int> xs) => xs.toSet().length == 4 && xs.every((x) => x >= 1 && x <= 4);
    for (var i = 0; i < 4; i++) {
      if (!ok([for (var j = 0; j < 4; j++) g[i * 4 + j]])) return false;
      if (!ok([for (var j = 0; j < 4; j++) g[j * 4 + i]])) return false;
    }
    for (final br in [0, 2]) {
      for (final bc in [0, 2]) {
        if (!ok([g[br * 4 + bc], g[br * 4 + bc + 1], g[(br + 1) * 4 + bc], g[(br + 1) * 4 + bc + 1]])) return false;
      }
    }
    return true;
  }
}

Sudoku4 sudokuPuzzle(int level, Random r) {
  const base = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];
  final perm = [1, 2, 3, 4]..shuffle(r);
  var g = [for (final v in base) perm[v - 1]];
  // تبديل صفوف داخل نفس النطاق، وأعمدة داخل نفس النطاق، يحفظ صحة الحل
  List<int> swapRows(List<int> x, int a, int b) {
    final y = [...x];
    for (var j = 0; j < 4; j++) {
      y[a * 4 + j] = x[b * 4 + j];
      y[b * 4 + j] = x[a * 4 + j];
    }
    return y;
  }

  List<int> swapCols(List<int> x, int a, int b) {
    final y = [...x];
    for (var i = 0; i < 4; i++) {
      y[i * 4 + a] = x[i * 4 + b];
      y[i * 4 + b] = x[i * 4 + a];
    }
    return y;
  }

  if (r.nextBool()) g = swapRows(g, 0, 1);
  if (r.nextBool()) g = swapRows(g, 2, 3);
  if (r.nextBool()) g = swapCols(g, 0, 1);
  if (r.nextBool()) g = swapCols(g, 2, 3);
  final blanks = min(4 + level ~/ 2, 10);
  final idx = List.generate(16, (i) => i)..shuffle(r);
  final hidden = idx.take(blanks).toSet();
  return Sudoku4(g, [for (var i = 0; i < 16; i++) !hidden.contains(i)]);
}

/// ألعاب البرج ومعرفاتها.
enum TowerGame {
  sequence('أكمل النمط', 'tower_seq'),
  oddOne('الدخيل', 'tower_odd'),
  balance('الميزان', 'tower_bal'),
  scramble('رتب الحروف', 'tower_scr'),
  sudoku('سودوكو الصغار', 'tower_sud'),
  story('مسائل السوق', 'tower_story'),
  riddle('أحاجي وفوازير', 'tower_rid');

  final String title;
  final String key;
  const TowerGame(this.title, this.key);

  /// عدد الألغاز في كل مستوى.
  int get perLevel => this == TowerGame.sudoku ? 1 : 5;
}

/// اسم الطابق حسب المستوى، يحفز الطفل على الصعود.
/// مسائل كلامية عن أشياء من حياة الطفل، تكبر الأرقام والخطوات مع المستوى.
ChoicePuzzle storyPuzzle(int level, Random r) {
  int n(int a, int b) => a + r.nextInt(b - a + 1);
  const items = ['تمرة', 'قلم', 'كتاب', 'تفاحة', 'كرة', 'وردة', 'برتقالة', 'دفتر'];
  final it = items[r.nextInt(items.length)];
  late int ans;
  late String q;
  final kind = level < 3 ? r.nextInt(2) : (level < 8 ? r.nextInt(4) : r.nextInt(6));
  switch (kind) {
    case 0:
      final a = n(2, 6 + level * 2), b = n(1, 5 + level * 2);
      ans = a + b;
      q = 'معك $a $it وأعطاك أبوك $b، كم صار معك؟';
    case 1:
      final a = n(4, 10 + level * 2), b = n(1, a - 1);
      ans = a - b;
      q = 'عندك $a $it وتصدقت بـ $b، كم بقي عندك؟';
    case 2:
      final a = n(2, 5 + level ~/ 2), b = n(2, 6);
      ans = a * b;
      q = 'في $a صناديق، في كل صندوق $b $it، كم المجموع؟';
    case 3:
      final b = n(2, 5), a = n(2, 6 + level ~/ 3);
      ans = a;
      q = 'وزعت ${a * b} $it على $b من إخوتك بالتساوي، كم نصيب كل واحد؟';
    case 4:
      final p = n(2, 9), c = n(2, 5), pay = (p * c ~/ 10 + 1) * 10;
      ans = pay - p * c;
      q = 'اشتريت $c $it، سعر الواحدة $p ريال، ودفعت $pay ريال، كم يرجع لك؟';
    default:
      final a = n(10, 40), b = n(2, 9), c = n(2, 9);
      ans = a - b + c;
      q = 'عندك $a $it، أهديت $b ثم اشتريت $c، كم صار عندك؟';
  }
  final opts = _opts(ans, r, n: level < 6 ? 3 : 4);
  return ChoicePuzzle(q, const [], opts, opts.indexOf('$ans'), 'الجواب $ans');
}

/// أحاجي عن الجمادات والطبيعة والعبادات فقط.
const kRiddles = <(String, String, List<String>)>[
  ('له أسنان ولا يعض', 'المشط', ['الملعقة', 'الكرسي']),
  ('يكتب ولا يقرأ', 'القلم', ['الدفتر', 'الكتاب']),
  ('كلما أخذت منه كبر', 'الحفرة', ['الجبل', 'الكيس']),
  ('له عين ولا يرى', 'الإبرة', ['الشباك', 'المصباح']),
  ('يمشي بلا رجلين ويبكي بلا عينين', 'السحاب', ['النهر', 'الريح']),
  ('بيت بلا أبواب ولا نوافذ', 'البيضة', ['الصندوق', 'الخيمة']),
  ('له أوراق وليس شجرة، وله جلد وليس حيوانا', 'الكتاب', ['الدفتر', 'الحقيبة']),
  ('يسمع بلا أذن ويتكلم بلا لسان', 'الهاتف', ['المذياع', 'الجرس']),
  ('شيء يملأ الغرفة ولا يأخذ مكانا', 'الضوء', ['الهواء', 'الماء']),
  ('كلما زاد نقص', 'العمر', ['المال', 'الماء']),
  ('له رقبة وليس له رأس', 'الزجاجة', ['القميص', 'الإبريق']),
  ('يدور حول البيت ولا يدخله', 'السور', ['الباب', 'الشارع']),
  ('تراه في الليل ثلاث مرات وفي النهار مرة', 'حرف اللام', ['القمر', 'النجم']),
  ('ابن الماء وإذا وضع في الماء مات', 'الثلج', ['الملح', 'السكر']),
  ('يقرصك ولا تراه', 'الجوع', ['البرد', 'الريح']),
  ('أخضر في الأرض، أسود في السوق، أحمر في البيت', 'الشاي', ['القهوة', 'الفحم']),
  ('له ساق ولا يمشي', 'الشجرة', ['الكرسي', 'الطاولة']),
  ('ما الشيء الذي يكون أخضر ثم أحمر ثم أسود وتأكله', 'التمر', ['العنب', 'الزيتون']),
  ('يقف على رجل واحدة ويحمي الناس من الشمس', 'المظلة', ['الشجرة', 'العمود']),
  ('تذبحه وتبكي عليه', 'البصل', ['الثوم', 'الليمون']),
  ('شيء إذا لمسته صاح', 'الجرس', ['الباب', 'الهاتف']),
  ('عبادة نؤديها خمس مرات في اليوم', 'الصلاة', ['الصيام', 'الزكاة']),
  ('ركن نؤديه في شهر رمضان', 'الصيام', ['الحج', 'الزكاة']),
  ('بيت الله الحرام قبلة المسلمين', 'الكعبة', ['المسجد النبوي', 'المسجد الأقصى']),
  ('ماء نطهر به أعضاءنا قبل الصلاة', 'الوضوء', ['الغسل', 'التيمم']),
  ('ليلة خير من ألف شهر', 'ليلة القدر', ['ليلة العيد', 'ليلة النصف']),
  ('شيء يعطيك ولا يأخذ منك، تقرؤه فتتعلم', 'الكتاب', ['القلم', 'التلفاز']),
  ('له وجه وعقربان ولا يتكلم', 'الساعة', ['المرآة', 'البوصلة']),
  ('ترى فيه نفسك ولا تلمسها', 'المرآة', ['الماء', 'الصورة']),
  ('يشير دائما إلى الشمال', 'البوصلة', ['الساعة', 'الخريطة']),
  ('ينزل من السماء فتحيا به الأرض', 'المطر', ['الثلج', 'الندى']),
  ('أنا ابن الشجرة، أكتب عليّ واجبك', 'الورق', ['الخشب', 'القماش']),
];

ChoicePuzzle riddlePuzzle(int level, Random r) {
  final x = kRiddles[(level * 5 + r.nextInt(kRiddles.length)) % kRiddles.length];
  final opts = [x.$2, ...x.$3]..shuffle(r);
  return ChoicePuzzle('من أنا؟ ${x.$1}', const [], opts, opts.indexOf(x.$2), 'الجواب: ${x.$2}');
}

String floorName(int level) {
  if (level < 5) return 'الطابق الأرضي';
  if (level < 10) return 'طابق المستكشفين';
  if (level < 20) return 'طابق الأذكياء';
  if (level < 35) return 'طابق العباقرة';
  return 'قمة البرج';
}
