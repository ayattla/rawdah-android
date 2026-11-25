/// الحروف مرتبة في «عائلات» حسب الرسم: حروف العائلة الواحدة لها نفس الشكل وتختلف بالنقاط فقط،
/// وهكذا يعلمها معلمو الصفوف الأولى. كل الأمثلة جمادات وأماكن ونبات.
library;

class ArabicLetter {
  final String char;
  final String name;

  /// الحرف في أول الكلمة ووسطها وآخرها.
  final String initial;
  final String medial;
  final String finalForm;

  /// كلمات أمثلة فيها الحرف (الحرف الأول أو داخلها).
  final List<String> words;

  /// عدد النقاط وموضعها: 0 بلا نقاط، موجب فوق، سالب تحت.
  final int dots;

  /// الحروف التي لا تتصل بما بعدها (ا د ذ ر ز و).
  final bool nonJoining;

  const ArabicLetter(this.char, this.name, this.initial, this.medial, this.finalForm, this.words,
      {this.dots = 0, this.nonJoining = false});

  String get isolated => char;
  String get id => 'letter_$char';
}

class LetterFamily {
  final String title;
  final List<ArabicLetter> letters;
  const LetterFamily(this.title, this.letters);
}

const _t = 'ـ'; // التطويل لعرض شكل الحرف متصلا

const kLetterFamilies = <LetterFamily>[
  LetterFamily('الألف', [
    ArabicLetter('ا', 'ألف', 'ا', '${_t}ا', '${_t}ا', ['أرض', 'باب'], nonJoining: true),
  ]),
  LetterFamily('عائلة الباء', [
    ArabicLetter('ب', 'باء', 'بـ', '${_t}بـ', '${_t}ب', ['باب', 'كتاب'], dots: -1),
    ArabicLetter('ت', 'تاء', 'تـ', '${_t}تـ', '${_t}ت', ['تمر', 'بيت'], dots: 2),
    ArabicLetter('ث', 'ثاء', 'ثـ', '${_t}ثـ', '${_t}ث', ['ثلج', 'ثوب'], dots: 3),
  ]),
  LetterFamily('عائلة الجيم', [
    ArabicLetter('ج', 'جيم', 'جـ', '${_t}جـ', '${_t}ج', ['جبل', 'درج'], dots: -1),
    ArabicLetter('ح', 'حاء', 'حـ', '${_t}حـ', '${_t}ح', ['حجر', 'بحر']),
    ArabicLetter('خ', 'خاء', 'خـ', '${_t}خـ', '${_t}خ', ['خبز', 'نخلة'], dots: 1),
  ]),
  LetterFamily('عائلة الدال', [
    ArabicLetter('د', 'دال', 'د', '${_t}د', '${_t}د', ['درج', 'ورد'], nonJoining: true),
    ArabicLetter('ذ', 'ذال', 'ذ', '${_t}ذ', '${_t}ذ', ['ذهب', 'نافذة'], dots: 1, nonJoining: true),
  ]),
  LetterFamily('عائلة الراء', [
    ArabicLetter('ر', 'راء', 'ر', '${_t}ر', '${_t}ر', ['رمل', 'قمر'], nonJoining: true),
    ArabicLetter('ز', 'زاي', 'ز', '${_t}ز', '${_t}ز', ['زيت', 'خبز'], dots: 1, nonJoining: true),
  ]),
  LetterFamily('عائلة السين', [
    ArabicLetter('س', 'سين', 'سـ', '${_t}سـ', '${_t}س', ['سماء', 'شمس']),
    ArabicLetter('ش', 'شين', 'شـ', '${_t}شـ', '${_t}ش', ['شمس', 'عش'], dots: 3),
  ]),
  LetterFamily('عائلة الصاد', [
    ArabicLetter('ص', 'صاد', 'صـ', '${_t}صـ', '${_t}ص', ['صخر', 'صندوق']),
    ArabicLetter('ض', 'ضاد', 'ضـ', '${_t}ضـ', '${_t}ض', ['ضوء', 'أرض'], dots: 1),
  ]),
  LetterFamily('عائلة الطاء', [
    ArabicLetter('ط', 'طاء', 'طـ', '${_t}طـ', '${_t}ط', ['طين', 'قطار']),
    ArabicLetter('ظ', 'ظاء', 'ظـ', '${_t}ظـ', '${_t}ظ', ['ظل', 'نظارة'], dots: 1),
  ]),
  LetterFamily('عائلة العين', [
    ArabicLetter('ع', 'عين', 'عـ', '${_t}عـ', '${_t}ع', ['عسل', 'شمعة']),
    ArabicLetter('غ', 'غين', 'غـ', '${_t}غـ', '${_t}غ', ['غيمة', 'صمغ'], dots: 1),
  ]),
  LetterFamily('الفاء والقاف', [
    ArabicLetter('ف', 'فاء', 'فـ', '${_t}فـ', '${_t}ف', ['فانوس', 'سقف'], dots: 1),
    ArabicLetter('ق', 'قاف', 'قـ', '${_t}قـ', '${_t}ق', ['قمر', 'ورق'], dots: 2),
  ]),
  LetterFamily('الكاف واللام', [
    ArabicLetter('ك', 'كاف', 'كـ', '${_t}كـ', '${_t}ك', ['كتاب', 'شباك']),
    ArabicLetter('ل', 'لام', 'لـ', '${_t}لـ', '${_t}ل', ['ليمون', 'جبل']),
  ]),
  LetterFamily('الميم والنون', [
    ArabicLetter('م', 'ميم', 'مـ', '${_t}مـ', '${_t}م', ['مسجد', 'قلم']),
    ArabicLetter('ن', 'نون', 'نـ', '${_t}نـ', '${_t}ن', ['نجم', 'فنجان'], dots: 1),
  ]),
  LetterFamily('الهاء والواو والياء', [
    ArabicLetter('ه', 'هاء', 'هـ', '${_t}هـ', '${_t}ه', ['هلال', 'وجه']),
    ArabicLetter('و', 'واو', 'و', '${_t}و', '${_t}و', ['وردة', 'دلو'], nonJoining: true),
    ArabicLetter('ي', 'ياء', 'يـ', '${_t}يـ', '${_t}ي', ['يد', 'كرسي'], dots: -2),
  ]),
];

final List<ArabicLetter> kLetters = [for (final f in kLetterFamilies) ...f.letters];

ArabicLetter? letterByChar(String c) {
  for (final l in kLetters) {
    if (l.char == c) return l;
  }
  return null;
}

/// يقسم الكلمة إلى مقاطع ملونة: الحرف المطلوب وحده وما حوله، مع الحفاظ على الاتصال.
/// يعامل الهمزات على الألف (أ إ آ) معاملة الألف.
List<(String text, bool hit)> splitForHighlight(String word, String letter) {
  bool match(String ch) => ch == letter || (letter == 'ا' && 'أإآ'.contains(ch));
  final out = <(String, bool)>[];
  final buf = StringBuffer();
  for (final r in word.runes) {
    final ch = String.fromCharCode(r);
    if (match(ch)) {
      if (buf.isNotEmpty) {
        out.add((buf.toString(), false));
        buf.clear();
      }
      out.add((ch, true));
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty) out.add((buf.toString(), false));
  return out;
}
