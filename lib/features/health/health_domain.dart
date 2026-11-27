import 'dart:math';

/// صحتي: نصائح يومية، وعداد الماء، ولعبة الطبق الصحي.

const kHealthTips = <String>[
  'اغسل يديك بالماء والصابون قبل الأكل وبعده',
  'نظف أسنانك بالفرشاة أو السواك صباحا وقبل النوم',
  'نم مبكرا، فالنوم الكافي يساعدك على النمو والتركيز',
  'اشرب الماء على دفعات طول اليوم، ولا تنتظر العطش',
  'كل الخضار والفواكه بألوان مختلفة كل يوم',
  'لا تكثر من الحلويات والمشروبات الغازية',
  'العب وتحرك ساعة كل يوم في مكان آمن',
  'اجلس معتدلا وأنت تقرأ أو تكتب',
  'ابعد الشاشة عن عينيك وارتح منها كل فترة',
  'افطر قبل المدرسة، فالفطور يعطيك طاقة للتعلم',
  'غط فمك بمنديل أو بمرفقك إذا عطست أو سعلت',
  'سم الله قبل الأكل، وكل بيمينك ومما يليك',
  'لا تملأ بطنك حتى التخمة، واترك مكانا للماء والنفس',
  'البس ملابس تناسب الجو، واحم رأسك من الشمس الحارة',
  'قص أظافرك ونظفها دائما',
  'استحم وحافظ على نظافة جسمك وملابسك',
];

String tipOfDay(DateTime d) => kHealthTips[(d.difference(DateTime(2026)).inDays).abs() % kHealthTips.length];

enum FoodKind { daily, sometimes }

const kFoods = <(String, FoodKind)>[
  ('تمر', FoodKind.daily), ('ماء', FoodKind.daily), ('حليب', FoodKind.daily), ('تفاح', FoodKind.daily),
  ('موز', FoodKind.daily), ('خيار', FoodKind.daily), ('جزر', FoodKind.daily), ('خبز بر', FoodKind.daily),
  ('أرز', FoodKind.daily), ('عدس', FoodKind.daily), ('بيض', FoodKind.daily), ('لبن', FoodKind.daily),
  ('برتقال', FoodKind.daily), ('طماطم', FoodKind.daily), ('خس', FoodKind.daily), ('زيتون', FoodKind.daily),
  ('عسل', FoodKind.daily), ('فول', FoodKind.daily), ('بطاطس مقلية', FoodKind.sometimes), ('حلاوة', FoodKind.sometimes),
  ('مشروب غازي', FoodKind.sometimes), ('شيبس', FoodKind.sometimes), ('كيك', FoodKind.sometimes), ('شوكولاتة', FoodKind.sometimes),
  ('آيسكريم', FoodKind.sometimes), ('دونات', FoodKind.sometimes), ('عصير معلب', FoodKind.sometimes), ('مشروب طاقة', FoodKind.sometimes),
];

/// جولة من لعبة الطبق الصحي: أطعمة مختلطة بلا تكرار.
List<(String, FoodKind)> plateRound(Random r, {int count = 8}) =>
    (List.of(kFoods)..shuffle(r)).take(count).toList();

const kWaterGoal = 6;
