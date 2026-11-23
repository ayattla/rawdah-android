/// الأسماء المسموح بها في المنافسة. لا يوجد أي حقل نص حر يُرسل إلى الخادم:
/// اللقب يُركّب من جزأين يختارهما الوالدان، واسم الحلقة من قائمة ورقم.
/// قواعد Firestore تحمل القوائم نفسها وترفض أي نص لا يطابق التركيب حرفيًا.
/// تنبيه: أي تعديل هنا يجب أن يُنقل إلى firestore.rules بالترتيب نفسه.
const List<String> kNickFirst = [
  'نجم', 'بدر', 'قمر', 'نور', 'سراج', 'لؤلؤ', 'ياقوت', 'غيث', //
  'نسيم', 'ريحان', 'زهر', 'فجر', 'ضياء', 'سنا', 'أمل', 'شهاب',
];

const List<String> kNickSecond = [
  'الهدى', 'الإيمان', 'الخير', 'السلام', 'الفجر', 'الروضة', 'العلم', 'الصباح', //
  'الأمل', 'الوفاء', 'الصدق', 'البر', 'الرحمة', 'الحكمة', 'المعرفة', 'النقاء',
];

const List<String> kCircleNames = [
  'الفجر', 'النور', 'الهدى', 'الفرقان', 'البيان', 'الإحسان', //
  'الرحمة', 'الإيمان', 'الريان', 'الفردوس', 'التقوى', 'اليقين',
];

String composeNick(int first, int second) => '${kNickFirst[first]} ${kNickSecond[second]}';

bool validNickParts(int first, int second) =>
    first >= 0 && first < kNickFirst.length && second >= 0 && second < kNickSecond.length;

String circleDisplayName(int nameKey, int number) =>
    'حلقة ${kCircleNames[nameKey.clamp(0, kCircleNames.length - 1)]} $number';
