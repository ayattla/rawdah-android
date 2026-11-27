import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/shop/economy.dart';

/// متجر الروضة: يصرف الطفل نجومه على ألوان إطارات الرئيسية وألقاب تظهر تحت اسمه.
/// كل شيء بالنجوم فقط، بلا أي شراء حقيقي.
class FramePalette {
  final String id;
  final String name;
  final int price;
  final List<Color> colors;
  const FramePalette(this.id, this.name, this.price, this.colors);
}

const kFramePalettes = <FramePalette>[
  FramePalette('pal_candy', 'حلوى', 0, [Color(0xFFFFC23F), Color(0xFFFF5D8F), Color(0xFF22D3EE), Color(0xFF9BE15D), Color(0xFFFF9F1C), Color(0xFFA78BFA)]),
  FramePalette('pal_ocean', 'محيط', 60, [Color(0xFF22D3EE), Color(0xFF38BDF8), Color(0xFF2DD4BF), Color(0xFF60A5FA), Color(0xFF67E8F9), Color(0xFF5EEAD4)]),
  FramePalette('pal_desert', 'صحراء', 80, [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFFFB923C), Color(0xFFFDE68A)]),
  FramePalette('pal_garden', 'بستان', 100, [Color(0xFF86EFAC), Color(0xFF4ADE80), Color(0xFFA3E635), Color(0xFF34D399), Color(0xFFBEF264), Color(0xFF6EE7B7)]),
  FramePalette('pal_sunset', 'غروب', 120, [Color(0xFFF472B6), Color(0xFFC084FC), Color(0xFFFB7185), Color(0xFFA78BFA), Color(0xFFF9A8D4), Color(0xFFE879F9)]),
  FramePalette('pal_gold', 'ذهبي', 200, [Color(0xFFFACC15), Color(0xFFEAB308), Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFFFEF08A), Color(0xFFFBBF24)]),
];

class KidTitle {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  const KidTitle(this.id, this.name, this.price, this.icon);
}

const kTitles = <KidTitle>[
  KidTitle('t_explorer', 'مستكشف صغير', 40, Icons.explore_rounded),
  KidTitle('t_reader', 'صديق الكتاب', 60, Icons.menu_book_rounded),
  KidTitle('t_puzzler', 'حلال الألغاز', 80, Icons.extension_rounded),
  KidTitle('t_master', 'بطل الإتقان', 120, Icons.psychology_rounded),
  KidTitle('t_inventor', 'مخترع المستقبل', 150, Icons.lightbulb_rounded),
  KidTitle('t_hafiz', 'محب القرآن', 200, Icons.auto_stories_rounded),
  KidTitle('t_star', 'فخر الروضة', 300, Icons.workspace_premium_rounded),
];

/// ألوان الإطارات المختارة للطفل الحالي.
List<Color> equippedFrames(AppState st) {
  final i = st.counter('equip_frames').clamp(0, kFramePalettes.length - 1);
  return kFramePalettes[i].colors;
}

/// اللقب المختار أو null.
KidTitle? equippedTitle(AppState st) {
  final i = st.counter('equip_title');
  return i <= 0 || i > kTitles.length ? null : kTitles[i - 1];
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    const outline = Color(0xFF2A1A66);

    Future<void> buyOrEquip({required String id, required int price, required VoidCallback equip, required String name}) async {
      final owned = price == 0 || c.owned.contains(id);
      if (owned) {
        Haptics.tap();
        equip();
        return;
      }
      if (c.balance < price) {
        Haptics.error();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تحتاج ${price - c.balance} نجمة زيادة')));
        return;
      }
      if (st.buy(id, price)) {
        equip();
        await showReward(context, stars: 0, title: 'صار عندك $name');
      }
    }

    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'متجر الروضة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFFC23F), width: 3)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFC23F), size: 34),
                const SizedBox(width: 8),
                Text('رصيدك ${c.balance} نجمة', style: RT.display(22, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final d = dealOfDay(DateTime.now());
              final got = c.owned.contains(d.id);
              return Chunky(
                color: got ? RC.sandDark : const Color(0xFFEF4444),
                onTap: got
                    ? null
                    : () async {
                        if (st.buy(d.id, dealPrice(d))) {
                          Haptics.celebrate();
                          await showReward(context, stars: 0, title: 'صار عندك ${d.name}، استعمله من تحت');
                        } else {
                          Haptics.error();
                        }
                      },
                child: Column(children: [
                  Text('عرض اليوم: خصم ٤٠٪', style: RT.display(17, color: Colors.white)),
                  Text(got ? '${d.name} • عندك' : '${d.name} • ${dealPrice(d)} بدل ${d.price}', textAlign: TextAlign.center, style: RT.body(15, color: Colors.white)),
                ]),
              );
            }),
            const SizedBox(height: 10),
            Chunky(
              color: const Color(0xFF8B5CF6),
              onTap: () async {
                final got = openMystery(st, Random());
                if (got.isEmpty) {
                  Haptics.error();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تحتاج ${kMysteryPrice - c.balance} نجمة زيادة')));
                  return;
                }
                Haptics.celebrate();
                await showReward(context, stars: 3, title: 'طلع لك: $got');
              },
              child: Column(children: [
                Text('صندوق الهدية', style: RT.display(19, color: Colors.white)),
                Text('$kMysteryPrice نجمة • يعطيك أرخص غرض ناقص عندك', style: RT.body(14, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('مساعدات', textAlign: TextAlign.center, style: RT.display(19)),
            const SizedBox(height: 10),
            for (final h in kHelpers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Chunky(
                  color: Colors.white,
                  border: Border.all(color: outline, width: 3),
                  radius: 20,
                  depth: 5,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    if (buyHelper(st, h)) {
                      Haptics.success();
                    } else {
                      Haptics.error();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تحتاج ${h.price - c.balance} نجمة زيادة')));
                    }
                  },
                  child: Row(children: [
                    KhatamBadge(icon: h.icon, color: const Color(0xFF0EA5E9), size: 40),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(children: [
                        Text('${h.name} • عندك ${st.counter(h.key)}', style: RT.display(17)),
                        Text(h.what, textAlign: TextAlign.center, style: RT.body(13, color: RC.inkSoft)),
                      ]),
                    ),
                    _PriceTag(owned: false, on: false, price: h.price),
                  ]),
                ),
              ),
            const SizedBox(height: 10),
            Text('سماء الرئيسية', textAlign: TextAlign.center, style: RT.display(19)),
            const SizedBox(height: 10),
            for (var i = 0; i < kSkies.length; i++)
              Builder(builder: (context) {
                final k = kSkies[i];
                final owned = k.price == 0 || c.owned.contains(k.id);
                final on = st.counter('equip_sky') == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Chunky(
                    color: on ? const Color(0xFFFFF7E0) : Colors.white,
                    border: Border.all(color: outline, width: 3),
                    radius: 20,
                    depth: 5,
                    padding: const EdgeInsets.all(12),
                    onTap: () => buyOrEquip(id: k.id, price: k.price, name: 'سماء ${k.name}', equip: () => st.setCounter('equip_sky', i)),
                    child: Row(children: [
                      Container(
                        width: 60,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: k.colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: outline, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(k.name, textAlign: TextAlign.center, style: RT.display(18))),
                      _PriceTag(owned: owned, on: on, price: k.price),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 10),
            Text('ألوان إطارات الرئيسية', textAlign: TextAlign.center, style: RT.display(19)),
            const SizedBox(height: 10),
            for (var i = 0; i < kFramePalettes.length; i++)
              Builder(builder: (context) {
                final p = kFramePalettes[i];
                final owned = p.price == 0 || c.owned.contains(p.id);
                final on = st.counter('equip_frames') == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Chunky(
                    color: on ? const Color(0xFFFFF7E0) : Colors.white,
                    border: Border.all(color: outline, width: 3),
                    radius: 20,
                    depth: 5,
                    padding: const EdgeInsets.all(12),
                    semanticLabel: 'ألوان ${p.name}',
                    onTap: () => buyOrEquip(id: p.id, price: p.price, name: 'ألوان ${p.name}', equip: () => st.setCounter('equip_frames', i)),
                    child: Row(children: [
                      for (final col in p.colors.take(5))
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsetsDirectional.only(end: 4),
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle, border: Border.all(color: outline, width: 2)),
                        ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, textAlign: TextAlign.center, style: RT.display(18))),
                      _PriceTag(owned: owned, on: on, price: p.price),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 10),
            Text('ألقاب تظهر تحت اسمك', textAlign: TextAlign.center, style: RT.display(19)),
            const SizedBox(height: 10),
            for (var i = 0; i < kTitles.length; i++)
              Builder(builder: (context) {
                final t = kTitles[i];
                final owned = c.owned.contains(t.id);
                final on = st.counter('equip_title') == i + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Chunky(
                    color: on ? const Color(0xFFFFF7E0) : Colors.white,
                    border: Border.all(color: outline, width: 3),
                    radius: 20,
                    depth: 5,
                    padding: const EdgeInsets.all(12),
                    semanticLabel: 'لقب ${t.name}',
                    onTap: () => buyOrEquip(id: t.id, price: t.price, name: 'لقب ${t.name}', equip: () => st.setCounter('equip_title', i + 1)),
                    child: Row(children: [
                      KhatamBadge(icon: t.icon, color: const Color(0xFF8B5CF6), size: 40),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.name, textAlign: TextAlign.center, style: RT.display(18))),
                      _PriceTag(owned: owned, on: on, price: t.price),
                    ]),
                  ),
                );
              }),
          ]),
        ),
      ]),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final bool owned;
  final bool on;
  final int price;
  const _PriceTag({required this.owned, required this.on, required this.price});

  @override
  Widget build(BuildContext context) {
    final text = on ? 'مستعمل' : (owned ? 'استعمل' : '$price نجمة');
    final color = on ? const Color(0xFF10B981) : (owned ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A1A66), width: 2)),
      child: Text(text, style: RT.display(14, color: Colors.white)),
    );
  }
}
