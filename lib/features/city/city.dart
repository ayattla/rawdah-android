import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

/// مدينتي: يبني الطفل مدينته بالنجوم مبنى مبنى، وكل مستوى يعطيه دخلا يوميا يجمعه.
class Building {
  final String key;
  final String name;
  final String fact; // معلومة نافعة تظهر عند البناء
  final IconData icon;
  final Color color;
  final List<int> costs; // تكلفة كل مستوى
  const Building(this.key, this.name, this.fact, this.icon, this.color, this.costs);
  int get maxLevel => costs.length;
}

const kBuildings = <Building>[
  Building('b_mosque', 'المسجد', 'المسجد بيت الله، فيه نصلي ونتعلم القرآن', Icons.mosque_rounded, Color(0xFF10B981), [40, 90, 160, 260]),
  Building('b_library', 'المكتبة', 'القراءة تفتح لك أبواب العلم', Icons.local_library_rounded, Color(0xFF8B5CF6), [50, 100, 180, 280]),
  Building('b_school', 'المدرسة', 'طلب العلم عبادة نتقرب بها إلى الله', Icons.school_rounded, Color(0xFF0EA5E9), [60, 120, 200, 300]),
  Building('b_well', 'بئر الماء', 'سقي الماء من أعظم الصدقات', Icons.water_drop_rounded, Color(0xFF38BDF8), [30, 70, 130, 220]),
  Building('b_palms', 'بستان النخيل', 'النخلة شجرة مباركة، وثمرها التمر', Icons.park_rounded, Color(0xFF65A30D), [45, 95, 170, 270]),
  Building('b_hospital', 'المستشفى', 'زيارة المريض من حق المسلم على المسلم', Icons.local_hospital_rounded, Color(0xFFEF4444), [80, 150, 240, 360]),
  Building('b_market', 'السوق', 'التاجر الصدوق يحبه الناس ويبارك الله في رزقه', Icons.storefront_rounded, Color(0xFFF59E0B), [70, 130, 220, 340]),
  Building('b_observatory', 'المرصد', 'برصد الهلال نعرف بداية الشهور الهجرية', Icons.travel_explore_rounded, Color(0xFF6366F1), [100, 180, 280, 420]),
  Building('b_factory', 'مصنع المخترعين', 'كل اختراع بدأ بفكرة صغيرة وسؤال', Icons.precision_manufacturing_rounded, Color(0xFF64748B), [120, 200, 320, 480]),
  Building('b_port', 'الميناء', 'السفن تنقل الخير بين البلدان', Icons.sailing_rounded, Color(0xFF0891B2), [150, 250, 380, 550]),
];

int buildingLevel(ChildProfile c, Building b) => c.counters[b.key] ?? 0;

int cityLevel(ChildProfile c) => kBuildings.fold(0, (n, b) => n + buildingLevel(c, b));

/// الدخل اليومي: نجمة لكل مستوى مبنى.
int dailyIncome(ChildProfile c) => cityLevel(c);

bool incomeReady(ChildProfile c) => (c.counters['city_collect_${todayKey()}'] ?? 0) == 0 && dailyIncome(c) > 0;

int collectIncome(AppState st) {
  final c = st.current!;
  if (!incomeReady(c)) return 0;
  final n = dailyIncome(c);
  st.setCounter('city_collect_${todayKey()}', 1);
  st.addStars(n);
  return n;
}

bool upgrade(AppState st, Building b) {
  final c = st.current!;
  final lv = buildingLevel(c, b);
  if (lv >= b.maxLevel || c.balance < b.costs[lv]) return false;
  c.spentStars += b.costs[lv];
  st.setCounter(b.key, lv + 1);
  return true;
}

String cityRank(int level) {
  if (level < 5) return 'قرية صغيرة';
  if (level < 12) return 'بلدة';
  if (level < 22) return 'مدينة';
  if (level < 32) return 'مدينة كبيرة';
  return 'عاصمة العلم';
}

class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current!;
    const outline = Color(0xFF2A1A66);
    final lv = cityLevel(c);
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'مدينتي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF10B981), width: 3)),
              child: Column(children: [
                Text(cityRank(lv), style: RT.display(23, color: Colors.white)),
                Text('مستوى المدينة $lv من ${kBuildings.length * 4} • رصيدك ${c.balance} نجمة', style: RT.body(14, color: Colors.white70)),
                const SizedBox(height: 10),
                Chunky(
                  color: incomeReady(c) ? const Color(0xFFFFC23F) : RC.sandDark,
                  onTap: incomeReady(c)
                      ? () async {
                          final n = collectIncome(st);
                          Haptics.celebrate();
                          await showReward(context, stars: 3, title: 'جمعت $n نجمة من مدينتك');
                        }
                      : null,
                  child: Text(
                    dailyIncome(c) == 0 ? 'ابن أول مبنى ليصير لك دخل يومي' : (incomeReady(c) ? 'اجمع دخل اليوم: ${dailyIncome(c)} نجمة' : 'جمعت دخل اليوم، ارجع بكرة'),
                    textAlign: TextAlign.center,
                    style: RT.display(17, color: outline),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
              children: [
                for (final b in kBuildings)
                  Builder(builder: (context) {
                    final l = buildingLevel(c, b);
                    final maxed = l >= b.maxLevel;
                    return Chunky(
                      color: l == 0 ? Colors.white : b.color.withValues(alpha: 0.18),
                      border: Border.all(color: outline, width: 3),
                      radius: 22,
                      padding: const EdgeInsets.all(10),
                      onTap: maxed
                          ? null
                          : () async {
                              if (upgrade(st, b)) {
                                Haptics.celebrate();
                                await showReward(context, stars: 3, title: l == 0 ? 'بنيت ${b.name}! ${b.fact}' : 'طورت ${b.name} للمستوى ${l + 1}');
                              } else {
                                Haptics.error();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تحتاج ${b.costs[l] - c.balance} نجمة زيادة')));
                              }
                            },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Opacity(opacity: l == 0 ? 0.35 : 1, child: Icon(b.icon, size: 30.0 + l * 8, color: b.color)),
                        const SizedBox(height: 6),
                        Text(b.name, textAlign: TextAlign.center, style: RT.display(17, color: RC.onDark)),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (var k = 0; k < b.maxLevel; k++)
                            Container(
                              width: 14,
                              height: 8,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: k < l ? b.color : RC.sand, borderRadius: BorderRadius.circular(4), border: Border.all(color: outline, width: 1)),
                            ),
                        ]),
                        const SizedBox(height: 4),
                        Text(maxed ? 'اكتمل' : (l == 0 ? 'ابن بـ ${b.costs[0]}' : 'طور بـ ${b.costs[l]}'), style: RT.body(13, color: RC.onDarkSoft)),
                      ]),
                    );
                  }),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}
