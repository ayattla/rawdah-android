import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/science/data/science_content.dart';

/// ورشة المخترع: مولدات ألغاز علمية لا تنتهي، وتحديات أفكار يومية.

const kConductors = ['سلك نحاس', 'مسمار حديد', 'ملعقة معدن', 'مفتاح معدني', 'ورق ألمنيوم', 'عملة معدنية', 'مشبك معدني'];
const kInsulators = ['ممحاة', 'مسطرة بلاستيك', 'قلم خشب', 'ورقة', 'قطعة قماش', 'كأس زجاج', 'حجر', 'بالون'];

class WorkshopPuzzle {
  final String prompt;
  final String detail;
  final List<String> options;
  final int answer;
  final String why;
  const WorkshopPuzzle(this.prompt, this.detail, this.options, this.answer, this.why);
}

/// موصل أم عازل، ثم أكمل الدائرة، ثم مفتاح مفتوح أو مغلق، تصعب مع المستوى.
WorkshopPuzzle circuitPuzzle(int level, Random r) {
  final kind = level < 3 ? 0 : (level < 7 ? r.nextInt(2) : r.nextInt(3));
  switch (kind) {
    case 0:
      final cond = r.nextBool();
      final item = cond ? kConductors[r.nextInt(kConductors.length)] : kInsulators[r.nextInt(kInsulators.length)];
      return WorkshopPuzzle('هل تمر الكهرباء في هذا الشيء؟', item, const ['موصل: تمر فيه', 'عازل: لا تمر فيه'], cond ? 0 : 1,
          cond ? 'المعادن موصلة للكهرباء' : 'البلاستيك والخشب والورق والزجاج عوازل');
    case 1:
      final good = kConductors[r.nextInt(kConductors.length)];
      final bad = (List.of(kInsulators)..shuffle(r)).take(level < 8 ? 2 : 3).toList();
      final opts = [good, ...bad]..shuffle(r);
      return WorkshopPuzzle('بطارية ← سلك ← ؟ ← مصباح', 'ماذا نضع في الفراغ ليضيء المصباح؟', opts, opts.indexOf(good),
          '$good موصل فيكمل الدائرة');
    default:
      final closed = r.nextBool();
      return WorkshopPuzzle('الدائرة فيها مفتاح ${closed ? 'مغلق' : 'مفتوح'}', 'هل يضيء المصباح؟', const ['نعم يضيء', 'لا يضيء'], closed ? 0 : 1,
          closed ? 'المفتاح المغلق يكمل الطريق للكهرباء' : 'المفتاح المفتوح يقطع الدائرة');
  }
}

/// تحديات الأفكار: يرسم الطفل اختراعه في دفتر الأفكار.
const kInventPrompts = [
  'اخترع أداة تساعد جدك يصل إلى الرف العالي',
  'صمم حقيبة مدرسية لا تثقل على ظهرك',
  'اخترع آلة تسقي النباتات وأنت في المدرسة',
  'صمم مظلة تحميك من المطر والشمس معا',
  'اخترع لعبة تعلم أخاك الصغير الحروف',
  'صمم بيتا للطيور في حديقتكم',
  'اخترع كرسيا يساعد من يتعب من الوقوف في المسجد',
  'صمم قارورة ماء تذكرك بالشرب',
  'اخترع طريقة توفر الماء عند الوضوء',
  'صمم مصباحا يعمل بضوء الشمس',
  'اخترع صندوقا يرتب ألعابك وحده',
  'صمم سيارة صغيرة تمشي بالهواء',
  'اخترع أداة تساعد على رفع الأشياء الثقيلة',
  'صمم ساعة تذكرك بمواعيد الصلاة',
];

String promptOfDay(DateTime d) => kInventPrompts[(d.year * 400 + d.month * 31 + d.day) % kInventPrompts.length];

/// الآلات البسيطة: بطاقات ومسابقة.
const kMachinesTopic = ScienceTopic(
  id: 'simple_machines',
  title: 'الآلات البسيطة',
  subtitle: 'كيف نرفع الثقيل بجهد قليل؟',
  icon: Icons.precision_manufacturing_rounded,
  color: Color(0xFF0F766E),
  reflection: 'سخر الله لنا العقل لنفكر ونصنع أدوات تسهل حياتنا وتنفع الناس.',
  cards: [
    ScienceCard('الرافعة', 'لوح يرتكز على نقطة، نضغط طرفا فيرتفع الطرف الآخر بثقله.', 'الأرجوحة المتوازنة في الحديقة رافعة.', Icons.swap_vert_rounded),
    ScienceCard('البكرة', 'عجلة يمر عليها حبل، نسحب الحبل للأسفل فيرتفع الحمل.', 'تستعمل البكرة في رفع الدلو من البئر ورفع العلم.', Icons.settings_rounded),
    ScienceCard('العجلة والمحور', 'عجلة كبيرة تدور حول عمود، فتسهل الحركة والنقل.', 'مقبض الباب والدراجة من العجلة والمحور.', Icons.trip_origin_rounded),
    ScienceCard('المستوى المائل', 'سطح منحدر يجعل رفع الشيء أسهل من رفعه مباشرة.', 'منحدر الكراسي المتحركة عند المساجد مستوى مائل.', Icons.signal_cellular_alt_rounded),
    ScienceCard('الإسفين', 'قطعة رفيعة من طرف وسميكة من الآخر تشق الأشياء.', 'السكين والفأس من الإسفين.', Icons.change_history_rounded),
    ScienceCard('البرغي', 'مستوى مائل ملفوف حول عمود يثبت الأشياء.', 'غطاء القارورة يعمل مثل البرغي.', Icons.hardware_rounded),
  ],
  questions: [
    Question('mach_1', 0, 'بماذا نرفع الدلو من البئر بسهولة؟', ['البكرة', 'المسطرة', 'الكأس'], 0, 'البكرة ترفع الأحمال بالحبل.'),
    Question('mach_2', 0, 'الأرجوحة المتوازنة مثال على:', ['الرافعة', 'البرغي', 'الإسفين'], 0, 'الأرجوحة المتوازنة رافعة.'),
    Question('mach_3', 1, 'منحدر الكراسي المتحركة مثال على:', ['المستوى المائل', 'البكرة', 'العجلة'], 0, 'المنحدر مستوى مائل.'),
    Question('mach_4', 1, 'السكين مثال على:', ['الإسفين', 'الرافعة', 'البكرة'], 0, 'السكين إسفين يشق.'),
    Question('mach_5', 2, 'غطاء القارورة يعمل مثل:', ['البرغي', 'البكرة', 'الرافعة'], 0, 'الغطاء يلتف مثل البرغي.'),
    Question('mach_6', 2, 'مقبض الباب مثال على:', ['العجلة والمحور', 'الإسفين', 'المستوى المائل'], 0, 'المقبض يدور حول محور.'),
  ],
);
