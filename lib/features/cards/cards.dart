import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

/// ألبوم بطاقات المعرفة: مجموعات يجمعها الطفل من الأظرف، وكل بطاقة معلومة.
class CardSet {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<(String, String)> cards; // اسم، معلومة
  const CardSet(this.id, this.name, this.icon, this.color, this.cards);
}

const kCardSets = <CardSet>[
  CardSet('planets', 'كواكب المجموعة الشمسية', Icons.public_rounded, Color(0xFF6366F1), [
    ('عطارد', 'أقرب الكواكب إلى الشمس وأصغرها'),
    ('الزهرة', 'أشد الكواكب حرارة، وتُرى لامعة قرب الفجر والمغرب'),
    ('الأرض', 'كوكبنا، فيه الماء والهواء الذي خلقه الله لنا'),
    ('المريخ', 'يسمى الكوكب الأحمر بسبب لون ترابه'),
    ('المشتري', 'أكبر كواكب المجموعة الشمسية'),
    ('زحل', 'أشهر الكواكب بحلقاته الواسعة'),
    ('أورانوس', 'كوكب بارد يدور وهو مائل على جنبه'),
    ('نبتون', 'أبعد الكواكب عن الشمس'),
  ]),
  CardSet('mosques', 'مساجد شهيرة', Icons.mosque_rounded, Color(0xFF10B981), [
    ('المسجد الحرام', 'في مكة المكرمة، وفيه الكعبة قبلة المسلمين'),
    ('المسجد النبوي', 'في المدينة المنورة، بناه النبي ﷺ'),
    ('المسجد الأقصى', 'في القدس، أولى القبلتين وثالث المسجدين'),
    ('مسجد قباء', 'أول مسجد بني في الإسلام'),
    ('الجامع الأموي', 'في دمشق، من أقدم المساجد الكبيرة'),
    ('جامع القرويين', 'في فاس، ومن أقدم الجامعات في العالم'),
    ('الجامع الأزهر', 'في القاهرة، منارة علم منذ أكثر من ألف سنة'),
    ('جامع الشيخ زايد', 'في أبوظبي، من أكبر مساجد العالم'),
  ]),
  CardSet('scholars', 'علماء مسلمون', Icons.school_rounded, Color(0xFF8B5CF6), [
    ('الخوارزمي', 'أسس علم الجبر، ومن اسمه جاءت كلمة الخوارزمية'),
    ('ابن الهيثم', 'رائد علم البصريات وشرح كيف نرى'),
    ('ابن سينا', 'طبيب ألف كتاب القانون في الطب'),
    ('الإدريسي', 'رسم خريطة للعالم المعروف في زمانه'),
    ('البيروني', 'قاس محيط الأرض بطريقة ذكية'),
    ('الزهراوي', 'ابتكر أدوات للجراحة ما زال بعضها يشبه أدوات اليوم'),
    ('الجزري', 'صمم آلات تعمل بالماء، وسبق في الهندسة الميكانيكية'),
    ('البخاري', 'جمع صحيح البخاري، أصح كتب الحديث'),
  ]),
  CardSet('nature', 'عجائب الأرض', Icons.landscape_rounded, Color(0xFFF59E0B), [
    ('جبل إيفرست', 'أعلى قمة جبل على سطح الأرض'),
    ('نهر النيل', 'من أطول أنهار العالم ويجري في أفريقيا'),
    ('الربع الخالي', 'أكبر صحراء رملية متصلة في العالم، في جزيرتنا العربية'),
    ('المحيط الهادئ', 'أكبر المحيطات وأعمقها'),
    ('البحر الميت', 'أخفض منطقة على اليابسة، وماؤه شديد الملوحة'),
    ('القارة القطبية الجنوبية', 'أبرد قارات الأرض ويغطيها الجليد'),
    ('غابات الأمازون', 'أكبر غابة مطيرة في العالم'),
    ('جبال السروات', 'سلسلة جبال خضراء في جنوب غرب المملكة'),
  ]),
  CardSet('inventions', 'اختراعات غيرت العالم', Icons.lightbulb_rounded, Color(0xFFEF4444), [
    ('العجلة', 'سهلت نقل الأشياء الثقيلة منذ آلاف السنين'),
    ('الورق', 'حفظ العلم وسهّل الكتابة والتعليم'),
    ('البوصلة', 'تشير إلى الشمال وتساعد المسافرين'),
    ('المطبعة', 'نشرت الكتب بسرعة بين الناس'),
    ('المصباح الكهربائي', 'أضاء البيوت بالليل'),
    ('الهاتف', 'نقل الصوت لمسافات بعيدة'),
    ('الطائرة', 'قربت البلدان ببعض'),
    ('الحاسوب', 'آلة تحسب وتنظم المعلومات بسرعة كبيرة'),
  ]),
];

String cardId(String set, int i) => 'card_${set}_$i';

int setOwned(ChildProfile c, CardSet s) => [for (var i = 0; i < s.cards.length; i++) c.owned.contains(cardId(s.id, i))].where((x) => x).length;

int totalCards() => kCardSets.fold(0, (n, s) => n + s.cards.length);
int ownedCards(ChildProfile c) => kCardSets.fold(0, (n, s) => n + setOwned(c, s));

const kPackPrice = 40;
const kDupStars = 5;
const kSetPrize = 100;

/// ظرف فيه ٣ بطاقات؛ المكرر يتحول نجوما. يعيد الأسماء وعدد المكرر.
(List<String>, int) openPack(AppState st, Random r, {bool free = false}) {
  final c = st.current!;
  if (!free) {
    if (c.balance < kPackPrice) return (const [], 0);
    c.spentStars += kPackPrice;
  }
  final names = <String>[];
  var dups = 0;
  for (var k = 0; k < 3; k++) {
    // نفضل البطاقات الناقصة قليلا حتى لا يمل الطفل من التكرار
    final missing = <(CardSet, int)>[
      for (final s in kCardSets)
        for (var i = 0; i < s.cards.length; i++)
          if (!c.owned.contains(cardId(s.id, i))) (s, i)
    ];
    late CardSet s;
    late int i;
    if (missing.isNotEmpty && r.nextInt(10) < 7) {
      (s, i) = missing[r.nextInt(missing.length)];
    } else {
      s = kCardSets[r.nextInt(kCardSets.length)];
      i = r.nextInt(s.cards.length);
    }
    final id = cardId(s.id, i);
    if (c.owned.contains(id)) {
      dups++;
    } else {
      c.owned.add(id);
    }
    names.add(s.cards[i].$1);
  }
  if (dups > 0) st.addStars(dups * kDupStars);
  if (free) st.setCounter('pack_free_${weekKey()}', 1);
  st.setCounter('packs_opened', st.counter('packs_opened') + 1);
  return (names, dups);
}

String weekKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  return todayKey(day.subtract(Duration(days: (day.weekday + 1) % 7)));
}

bool freePackReady(ChildProfile c) => (c.counters['pack_free_${weekKey()}'] ?? 0) == 0;

bool setPrizeReady(ChildProfile c, CardSet s) => setOwned(c, s) == s.cards.length && (c.counters['set_prize_${s.id}'] ?? 0) == 0;

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current!;
    const outline = Color(0xFF2A1A66);

    Future<void> open({required bool free}) async {
      final (names, dups) = openPack(st, Random(), free: free);
      if (names.isEmpty) {
        Haptics.error();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تحتاج ${kPackPrice - c.balance} نجمة زيادة')));
        return;
      }
      Haptics.celebrate();
      await showReward(context, stars: 3, title: 'طلع لك: ${names.join('، ')}${dups > 0 ? ' (+${dups * kDupStars} نجمة من المكرر)' : ''}');
    }

    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ألبوم المعرفة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('جمعت ${ownedCards(c)} من ${totalCards()} بطاقة • رصيدك ${c.balance} نجمة', textAlign: TextAlign.center, style: RT.display(17)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Chunky(
                  color: freePackReady(c) ? const Color(0xFF10B981) : RC.sandDark,
                  onTap: freePackReady(c) ? () => open(free: true) : null,
                  child: Text(freePackReady(c) ? 'ظرف الأسبوع مجانا' : 'ظرفك المجاني السبت', textAlign: TextAlign.center, style: RT.display(16, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Chunky(
                  color: const Color(0xFFF59E0B),
                  onTap: () => open(free: false),
                  child: Text('ظرف بـ $kPackPrice نجمة', textAlign: TextAlign.center, style: RT.display(16, color: Colors.white)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            for (final s in kCardSets) ...[
              Row(children: [
                KhatamBadge(icon: s.icon, color: s.color, size: 40),
                const SizedBox(width: 8),
                Expanded(child: Text('${s.name} (${setOwned(c, s)}/${s.cards.length})', style: RT.display(18))),
              ]),
              if (setPrizeReady(c, s))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Chunky(
                    color: s.color,
                    onTap: () async {
                      st.setCounter('set_prize_${s.id}', 1);
                      st.addStars(kSetPrize);
                      Haptics.celebrate();
                      await showReward(context, stars: 3, title: 'كملت مجموعة ${s.name}! +$kSetPrize نجمة');
                    },
                    child: Text('كملت المجموعة! استلم $kSetPrize نجمة', style: RT.display(16, color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35,
                children: [
                  for (var i = 0; i < s.cards.length; i++)
                    Builder(builder: (_) {
                      final has = c.owned.contains(cardId(s.id, i));
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: has ? s.color.withValues(alpha: 0.15) : RC.sand,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: has ? s.color : outline.withValues(alpha: 0.3), width: 2.5),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(has ? s.cards[i].$1 : '؟', textAlign: TextAlign.center, style: RT.display(15)),
                          if (has) Text(s.cards[i].$2, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: RT.body(11.5, color: RC.inkSoft)),
                        ]),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ]),
        ),
      ]),
    );
  }
}
