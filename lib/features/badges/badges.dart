import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

/// أوسمتي: أهداف طويلة بدرجات (برونزي، فضي، ذهبي، ماسي) تحسب من عدادات الطفل.
class BadgeTrack {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final List<int> levels;
  final int Function(ChildProfile c) value;
  const BadgeTrack(this.title, this.unit, this.icon, this.color, this.levels, this.value);
}

int _t(ChildProfile c, String k) => c.counters['total_$k'] ?? 0;

final kBadgeTracks = <BadgeTrack>[
  BadgeTrack('العالم الصغير', 'إجابة صحيحة', Icons.lightbulb_rounded, const Color(0xFF8B5CF6), [50, 200, 600, 1500], (c) => _t(c, 'correct')),
  BadgeTrack('بطل الألغاز', 'لغز محلول', Icons.extension_rounded, const Color(0xFFFF5D8F), [20, 80, 250, 700], (c) => _t(c, 'tower')),
  BadgeTrack('النشيط', 'نشاط', Icons.bolt_rounded, const Color(0xFFF59E0B), [10, 40, 120, 300], (c) => _t(c, 'activity')),
  BadgeTrack('حافظ المراجعة', 'مراجعة سورة', Icons.menu_book_rounded, const Color(0xFF10B981), [5, 25, 80, 200], (c) => _t(c, 'review')),
  BadgeTrack('المواظب', 'يوم متتالي', Icons.local_fire_department_rounded, const Color(0xFFEF4444), [3, 7, 21, 60], (c) => c.streak),
  BadgeTrack('حافظ السور', 'سورة محفوظة', Icons.auto_stories_rounded, const Color(0xFF0EA5E9), [3, 10, 25, 40], (c) => c.hifz.length),
  BadgeTrack('متابع الحلقات', 'حلقة', Icons.live_tv_rounded, const Color(0xFF6366F1), [7, 30, 60, 78], (c) => c.counters['ep_done'] ?? 0),
  BadgeTrack('بطل الأسبوع', 'وسام أسبوعي', Icons.military_tech_rounded, const Color(0xFFFFC23F), [1, 4, 12, 30], (c) => c.counters['medals'] ?? 0),
  BadgeTrack('سريع الحساب', 'أفضل نتيجة في الدقيقة', Icons.speed_rounded, const Color(0xFFEF4444), [8, 15, 25, 35], (c) => c.counters['speed_best'] ?? 0),
  BadgeTrack('سيد الجداول', 'جدول متقن', Icons.calculate_rounded, const Color(0xFF8B5CF6), [1, 3, 6, 9], (c) => [for (var t = 2; t <= 10; t++) c.counters['mul_t$t'] ?? 0].where((v) => v >= 10).length),
  BadgeTrack('باني المدينة', 'مستوى مدينة', Icons.location_city_rounded, const Color(0xFF10B981), [3, 10, 20, 40], (c) => [for (final e in c.counters.entries) if (e.key.startsWith('b_')) e.value].fold(0, (a, b) => a + b)),
  BadgeTrack('جامع البطاقات', 'بطاقة', Icons.collections_bookmark_rounded, const Color(0xFF6366F1), [5, 15, 30, 40], (c) => c.owned.where((x) => x.startsWith('card_')).length),
  BadgeTrack('متسلق السلم', 'قمة سلم المعرفة', Icons.stairs_rounded, const Color(0xFF14B8A6), [1, 5, 20, 50], (c) => c.counters['ladder_top'] ?? 0),
];

const kBadgeTiers = ['برونزي', 'فضي', 'ذهبي', 'ماسي'];
const kTierColors = [Color(0xFFD97706), Color(0xFF94A3B8), Color(0xFFFFC23F), Color(0xFF67E8F9)];

/// كم درجة وصلها الطفل في المسار (0 = لا شيء).
int tierOf(BadgeTrack t, int v) => t.levels.where((l) => v >= l).length;

int totalTiers(ChildProfile c) => kBadgeTracks.fold(0, (n, t) => n + tierOf(t, t.value(c)));

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current!;
    const outline = Color(0xFF2A1A66);
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'أوسمتي'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('جمعت ${totalTiers(c)} من ${kBadgeTracks.length * 4} وسام', textAlign: TextAlign.center, style: RT.display(20)),
            const SizedBox(height: 12),
            for (final t in kBadgeTracks)
              Builder(builder: (_) {
                final v = t.value(c);
                final tier = tierOf(t, v);
                final next = tier < 4 ? t.levels[tier] : t.levels.last;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: outline, width: 3)),
                  child: Row(children: [
                    KhatamBadge(size: 56, icon: t.icon, color: tier == 0 ? RC.sandDark : kTierColors[tier - 1]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tier == 0 ? t.title : '${t.title} • ${kBadgeTiers[tier - 1]}', style: RT.display(17)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: (v / next).clamp(0, 1).toDouble(), minHeight: 10, color: t.color, backgroundColor: RC.sand),
                        ),
                        const SizedBox(height: 3),
                        Text(tier == 4 ? 'وصلت الماسي! $v ${t.unit}' : '$v من $next ${t.unit}', style: RT.body(13, color: RC.inkSoft)),
                      ]),
                    ),
                  ]),
                );
              }),
          ]),
        ),
      ]),
    );
  }
}
