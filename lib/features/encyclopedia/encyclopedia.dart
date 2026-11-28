import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';

/// موسوعة روضة: بطاقات معلومات ثقافية ودينية قصيرة، بانتظار اعتماد اللجنة الشرعية.
class EncShelf {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> facts;
  const EncShelf(this.id, this.title, this.icon, this.color, this.facts);
}

const kEncShelves = <EncShelf>[
  EncShelf('deen', 'ديني', Icons.menu_book_rounded, Color(0xFF10B981), [
    'القرآن الكريم 114 سورة، أولها الفاتحة وآخرها الناس.',
    'أطول سورة في القرآن سورة البقرة، وأقصرها سورة الكوثر.',
    'أول ما نزل من القرآن: اقرأ باسم ربك الذي خلق، في سورة العلق.',
    'أركان الإسلام خمسة: الشهادتان والصلاة والزكاة وصوم رمضان وحج البيت.',
    'شهر رمضان هو الشهر الذي أنزل فيه القرآن، كما في سورة البقرة.',
    'الكعبة قبلة المسلمين في صلاتهم، وهي في المسجد الحرام بمكة المكرمة.',
    'التقويم الهجري يبدأ من هجرة النبي ﷺ من مكة إلى المدينة.',
    'الأشهر الحرم أربعة: ذو القعدة وذو الحجة ومحرم ورجب.',
    'آية الكرسي هي الآية رقم 255 من سورة البقرة.',
    'سورة الفاتحة نقرؤها في كل ركعة من ركعات الصلاة.',
    'بئر زمزم في المسجد الحرام قريبا من الكعبة.',
    'الصلوات المفروضة خمس: الفجر والظهر والعصر والمغرب والعشاء.',
  ]),
  EncShelf('seerah', 'سيرة ونور', Icons.route_rounded, Color(0xFFFF9F1C), [
    'ولد النبي محمد ﷺ في مكة المكرمة في عام الفيل.',
    'كان النبي ﷺ يلقب قبل البعثة بالصادق الأمين.',
    'نزل الوحي أول مرة على النبي ﷺ في غار حراء.',
    'اختبأ النبي ﷺ وصاحبه أبو بكر في غار ثور أثناء الهجرة.',
    'أول مسجد بني في الإسلام هو مسجد قباء.',
    'بلال بن رباح رضي الله عنه أول مؤذن في الإسلام.',
    'لقب عمر بن الخطاب رضي الله عنه بالفاروق.',
    'لقب عثمان بن عفان رضي الله عنه بذي النورين.',
    'لقب خالد بن الوليد رضي الله عنه بسيف الله.',
    'غزوة بدر كانت في رمضان من السنة الثانية للهجرة.',
    'المسجد النبوي في المدينة المنورة بناه النبي ﷺ بعد الهجرة.',
    'الخلفاء الراشدون: أبو بكر ثم عمر ثم عثمان ثم علي رضي الله عنهم.',
  ]),
  EncShelf('watan', 'بلادي', Icons.flag_rounded, Color(0xFF22C55E), [
    'الرياض عاصمة المملكة العربية السعودية.',
    'اليوم الوطني السعودي في 23 سبتمبر من كل عام.',
    'يوم التأسيس في 22 فبراير، ويذكرنا بتأسيس الدولة السعودية الأولى عام 1727م.',
    'الدرعية كانت عاصمة الدولة السعودية الأولى.',
    'علم المملكة أخضر، فيه الشهادتان وتحتهما سيف.',
    'شعار المملكة نخلة تحتها سيفان متقاطعان.',
    'المملكة تطل على البحر الأحمر غربا والخليج العربي شرقا.',
    'الربع الخالي في جنوب المملكة، أكبر صحراء رملية متصلة في العالم.',
    'الحجر في العلا أول موقع سعودي يسجل في قائمة التراث العالمي.',
    'جبال السروات تمتد في غرب المملكة وجنوبها، وهي خضراء ممطرة.',
    'جدة على ساحل البحر الأحمر، ويصل منها كثير من الحجاج والمعتمرين.',
    'القهوة السعودية من رموز الكرم والضيافة في بلادنا.',
  ]),
  EncShelf('ajaib', 'عجائب ومعارف', Icons.lightbulb_rounded, Color(0xFF8B5CF6), [
    'قلب الإنسان ينبض نحو 100 ألف مرة في اليوم.',
    'الضوء يقطع نحو 300 ألف كيلومتر في الثانية الواحدة.',
    'في جسم الإنسان البالغ 206 عظمات.',
    'أصغر عظمة في جسم الإنسان موجودة داخل الأذن.',
    'القمر يبعد عن الأرض نحو 384 ألف كيلومتر.',
    'الماء يتجمد عند صفر درجة مئوية ويغلي عند 100 درجة.',
    'الحوت الأزرق أكبر حيوان عرفه الإنسان.',
    'الزرافة أطول حيوان يعيش على الأرض.',
    'العسل إذا حفظ جيدا يبقى صالحا مدة طويلة جدا.',
    'نهر النيل يجري من الجنوب إلى الشمال ويصب في البحر الأبيض المتوسط.',
    'الشمس أكبر من الأرض بكثير، ويمكن أن تتسع لأكثر من مليون أرض.',
    'النبات يصنع غذاءه من ضوء الشمس والماء والهواء.',
  ]),
  EncShelf('jismi', 'جسمي وصحتي', Icons.favorite_rounded, Color(0xFFEF4444), [
    'القلب عضلة تضخ الدم إلى كل أجزاء الجسم.',
    'الرئتان تأخذان الأكسجين من الهواء الذي نتنفسه.',
    'الأسنان اللبنية عددها 20 سنا، وتتبدل بأسنان دائمة.',
    'العظام تحمي أعضاء الجسم، والجمجمة تحمي الدماغ.',
    'شرب الماء يساعد الجسم على التخلص من الحرارة والفضلات.',
    'النوم الكافي يساعد الطفل على النمو والتركيز في الدراسة.',
    'غسل اليدين بالماء والصابون يقضي على كثير من الجراثيم.',
    'العين ترى الألوان بفضل خلايا خاصة في داخلها.',
    'الجلد أكبر عضو في جسم الإنسان، ويحميه من الخارج.',
    'المشي واللعب في الهواء يقوي العضلات والقلب.',
    'الخضار والفواكه فيها فيتامينات تقوي مناعة الجسم.',
    'الدماغ يرسل الأوامر لكل أعضاء الجسم عبر الأعصاب.',
  ]),
  EncShelf('ikhtiraa', 'علماء واختراعات', Icons.science_rounded, Color(0xFF0EA5E9), [
    'الخوارزمي عالم مسلم أسس علم الجبر.',
    'ابن الهيثم شرح كيف يدخل الضوء إلى العين فنرى.',
    'ابن سينا طبيب مسلم ألف كتاب القانون في الطب.',
    'الإدريسي رسم خريطة للعالم المعروف في زمانه.',
    'الزهراوي ابتكر أدوات للجراحة ما زال بعضها يشبه أدوات اليوم.',
    'البيروني قاس محيط الأرض بطريقة حسابية ذكية.',
    'الجزري صمم آلات تعمل بالماء وساعات عجيبة.',
    'المطبعة سهلت نشر الكتب بين الناس بسرعة.',
    'المصباح الكهربائي أضاء البيوت في الليل.',
    'الهاتف ينقل الصوت لمسافات بعيدة جدا.',
    'الطائرة قربت البلدان، فصار السفر ساعات بدل أيام.',
    'الحاسوب آلة تحسب وتنظم المعلومات بسرعة كبيرة.',
  ]),
];

int encSeen(ChildProfile c, EncShelf s) => c.counters['enc_${s.id}'] ?? 0;

class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current!;
    final total = kEncShelves.fold(0, (n, s) => n + s.facts.length);
    final seen = kEncShelves.fold(0, (n, s) => n + encSeen(c, s));
    return ChildShell(
      theme: SceneTheme.stories,
      child: Column(children: [
        const KidBar(title: 'موسوعة روضة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('قرأت $seen من $total معلومة', textAlign: TextAlign.center, style: RT.display(18, color: const Color(0xFFFFE48A))),
            const SizedBox(height: 8),
            CandyProgress(value: total == 0 ? 0 : seen / total, color: const Color(0xFFFFB020)),
            const SizedBox(height: 14),
            for (final s in kEncShelves)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BigTile(
                  title: s.title,
                  subtitle: '${encSeen(c, s)} من ${s.facts.length} معلومة',
                  icon: s.icon,
                  color: s.color,
                  done: encSeen(c, s) >= s.facts.length,
                  onTap: () => Navigator.of(context).push(ChannelRoute<void>(builder: (_) => EncShelfScreen(shelf: s))),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class EncShelfScreen extends StatefulWidget {
  final EncShelf shelf;
  const EncShelfScreen({super.key, required this.shelf});
  @override
  State<EncShelfScreen> createState() => _EncShelfScreenState();
}

class _EncShelfScreenState extends State<EncShelfScreen> {
  int _i = 0;

  void _mark() {
    final st = AppScope.read(context);
    final key = 'enc_${widget.shelf.id}';
    if (_i + 1 > st.counter(key)) {
      st.setCounter(key, _i + 1);
      if (_i + 1 == widget.shelf.facts.length) {
        st.complete('enc_${widget.shelf.id}', stars: 3);
        showReward(context, stars: 3, title: 'أنهيت رف ${widget.shelf.title}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shelf;
    final f = s.facts[_i];
    return ChildShell(
      theme: SceneTheme.stories,
      child: Column(children: [
        KidBar(title: s.title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Text('معلومة ${_i + 1} من ${s.facts.length}', textAlign: TextAlign.center, style: RT.body(15, color: RC.onDarkSoft, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
              child: TvFrame(
                key: ValueKey(_i),
                body: s.color,
                variant: _i % 2 == 0 ? 3 : 0,
                child: Column(children: [
                  MiniTv(icon: s.icon, color: s.color, size: 70, seed: _i),
                  const SizedBox(height: 10),
                  Text('هل تعلم؟', style: RT.display(17, color: const Color(0xFFFFE48A))),
                  const SizedBox(height: 6),
                  Text(f, textAlign: TextAlign.center, style: RT.display(20, color: Colors.white, weight: FontWeight.w700)),
                ]),
              ),
            ),
            TextButton.icon(onPressed: () => Voice.instance.say(f), icon: const Icon(Icons.volume_up_rounded), label: const Text('اسمعها')),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: PrimaryButton(
                  label: 'السابقة',
                  color: const Color(0xFF6366F1),
                  onTap: _i == 0 ? null : () => setState(() => _i--),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: _i + 1 == s.facts.length ? 'أنهيت' : 'التالية',
                  color: s.color,
                  onTap: () {
                    _mark();
                    if (_i + 1 < s.facts.length) setState(() => _i++);
                  },
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
