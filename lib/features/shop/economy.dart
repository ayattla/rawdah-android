import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/badges/badges.dart';
import 'package:rawdah/features/shop/shop.dart';

/// اقتصاد النجوم: طرق كسب جديدة (تقويم المكافآت، تحديات الأسبوع، جوائز الأوسمة)
/// وطرق صرف جديدة (سماوات، مساعدات، صندوق المفاجآت، عرض اليوم).

// ---------- تقويم المكافأة: سبعة أيام متتالية تكبر جائزتها ----------
const kCalendarRewards = [5, 8, 10, 12, 15, 20, 40];

/// اليوم الذي سيستلمه الطفل الآن (0..6)، أو -1 إن استلم اليوم.
int calendarDayToClaim(ChildProfile c, DateTime now) {
  final last = c.counters['cal_last'] ?? 0;
  final today = _dayNum(now);
  if (last == today) return -1;
  final day = c.counters['cal_day'] ?? 0;
  if (last == today - 1) return day % 7;
  return 0;
}

int claimCalendar(AppState st, DateTime now) {
  final c = st.current!;
  final d = calendarDayToClaim(c, now);
  if (d < 0) return 0;
  st.setCounter('cal_day', d + 1);
  st.setCounter('cal_last', _dayNum(now));
  st.addStars(kCalendarRewards[d]);
  return kCalendarRewards[d];
}

int _dayNum(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

// ---------- تحديات الأسبوع الكبرى ----------
class WeeklyChallenge {
  final String kind;
  final String title;
  final int target;
  final int reward;
  final IconData icon;
  const WeeklyChallenge(this.kind, this.title, this.target, this.reward, this.icon);
}

const kWeeklyChallenges = [
  WeeklyChallenge('correct', 'أجب ١٠٠ إجابة صحيحة', 100, 60, Icons.lightbulb_rounded),
  WeeklyChallenge('tower', 'حل ٣٠ لغزا في البرج', 30, 50, Icons.extension_rounded),
  WeeklyChallenge('activity', 'أنجز ١٥ نشاطا', 15, 50, Icons.bolt_rounded),
  WeeklyChallenge('review', 'راجع ٧ سور', 7, 40, Icons.menu_book_rounded),
];

/// بداية الأسبوع (السبت).
DateTime weekStart(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: (day.weekday + 1) % 7));
}

int weekCount(ChildProfile c, String kind, DateTime now) {
  final s = weekStart(now);
  var n = 0;
  for (var i = 0; i < 7; i++) {
    final d = s.add(Duration(days: i));
    if (d.isAfter(now)) break;
    n += c.counters['dq_${todayKey(d)}_$kind'] ?? 0;
  }
  return n;
}

String _weekKey(DateTime now) => todayKey(weekStart(now));

bool weeklyClaimed(ChildProfile c, WeeklyChallenge w, DateTime now) => (c.counters['wk_${_weekKey(now)}_${w.kind}'] ?? 0) > 0;

bool claimWeekly(AppState st, WeeklyChallenge w, DateTime now) {
  final c = st.current!;
  if (weeklyClaimed(c, w, now) || weekCount(c, w.kind, now) < w.target) return false;
  st.setCounter('wk_${_weekKey(now)}_${w.kind}', 1);
  st.addStars(w.reward);
  return true;
}

// ---------- جوائز الأوسمة: كل درجة جديدة ٢٠ نجمة × رقمها ----------
int badgeUnclaimed(ChildProfile c, int i) {
  final t = kBadgeTracks[i];
  return tierOf(t, t.value(c)) - (c.counters['bdg_$i'] ?? 0);
}

int badgePrize(ChildProfile c, int i) {
  final claimed = c.counters['bdg_$i'] ?? 0;
  final now = tierOf(kBadgeTracks[i], kBadgeTracks[i].value(c));
  var s = 0;
  for (var t = claimed + 1; t <= now; t++) {
    s += 20 * t;
  }
  return s;
}

int claimBadge(AppState st, int i) {
  final c = st.current!;
  final p = badgePrize(c, i);
  if (p <= 0) return 0;
  st.setCounter('bdg_$i', tierOf(kBadgeTracks[i], kBadgeTracks[i].value(c)));
  st.addStars(p);
  return p;
}

// ---------- سماوات الرئيسية ----------
class SkyTheme {
  final String id;
  final String name;
  final int price;
  final List<Color> colors;
  const SkyTheme(this.id, this.name, this.price, this.colors);
}

const kSkies = [
  SkyTheme('sky_space', 'فضاء بنفسجي', 0, [Color(0xFF1E1458), Color(0xFF261A6E), Color(0xFF1A1450)]),
  SkyTheme('sky_navy', 'ليل البحر', 90, [Color(0xFF0B2545), Color(0xFF13315C), Color(0xFF0B1D3A)]),
  SkyTheme('sky_emerald', 'زمرد', 110, [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF022C22)]),
  SkyTheme('sky_dawn', 'فجر', 140, [Color(0xFF3B1E54), Color(0xFF6B2D5C), Color(0xFF2A1640)]),
  SkyTheme('sky_ruby', 'ياقوت', 170, [Color(0xFF4C0519), Color(0xFF7F1D1D), Color(0xFF3B0716)]),
  SkyTheme('sky_galaxy', 'مجرة', 250, [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)]),
];

List<Color> equippedSky(AppState st) => kSkies[st.counter('equip_sky').clamp(0, kSkies.length - 1)].colors;

// ---------- المساعدات ----------
class Helper {
  final String key;
  final String name;
  final String what;
  final int price;
  final IconData icon;
  const Helper(this.key, this.name, this.what, this.price, this.icon);
}

const kHelpers = [
  Helper('inv_half', 'احذف خيارا', 'مساعدة إضافية في سلم المعرفة', 25, Icons.content_cut_rounded),
  Helper('inv_skip', 'غير السؤال', 'مساعدة إضافية في سلم المعرفة', 25, Icons.swap_horiz_rounded),
  Helper('inv_freeze', 'حماية السلسلة', 'لو فاتك يوم ما تنقطع سلسلتك', 60, Icons.ac_unit_rounded),
];

bool buyHelper(AppState st, Helper h, {int? price}) {
  final c = st.current!;
  final p = price ?? h.price;
  if (c.balance < p) return false;
  c.spentStars += p;
  st.setCounter(h.key, st.counter(h.key) + 1);
  return true;
}

bool useHelper(AppState st, String key) {
  if (st.counter(key) <= 0) return false;
  st.setCounter(key, st.counter(key) - 1);
  return true;
}

/// لو فات الطفل يوم أمس فقط وعنده حماية، نرقع اليوم المفقود.
bool applyStreakFreeze(AppState st, DateTime now) {
  final c = st.current;
  if (c == null || st.counter('inv_freeze') <= 0) return false;
  final y = todayKey(now.subtract(const Duration(days: 1)));
  final y2 = todayKey(now.subtract(const Duration(days: 2)));
  if (c.activeDays.contains(y) || !c.activeDays.contains(y2)) return false;
  c.activeDays.add(y);
  useHelper(st, 'inv_freeze');
  return true;
}

// ---------- كل الأغراض التجميلية، وعرض اليوم، وصندوق المفاجآت ----------
class Cosmetic {
  final String id;
  final String name;
  final int price;
  const Cosmetic(this.id, this.name, this.price);
}

List<Cosmetic> allCosmetics() => [
      for (final p in kFramePalettes)
        if (p.price > 0) Cosmetic(p.id, 'ألوان ${p.name}', p.price),
      for (final t in kTitles) Cosmetic(t.id, 'لقب ${t.name}', t.price),
      for (final s in kSkies)
        if (s.price > 0) Cosmetic(s.id, 'سماء ${s.name}', s.price),
    ];

/// عرض اليوم: غرض واحد بخصم ٤٠٪، ثابت طول اليوم.
Cosmetic dealOfDay(DateTime now) {
  final all = allCosmetics();
  return all[_dayNum(now) % all.length];
}

int dealPrice(Cosmetic c) => (c.price * 0.6).round();

const kMysteryPrice = 70;

/// يفتح الصندوق: غرض غير مملوك عشوائي، أو نجوم إن ملك الطفل كل شيء.
String openMystery(AppState st, Random r) {
  final c = st.current!;
  if (c.balance < kMysteryPrice) return '';
  c.spentStars += kMysteryPrice;
  final left = allCosmetics().where((x) => !c.owned.contains(x.id)).toList();
  if (left.isEmpty || r.nextInt(5) == 0) {
    final h = kHelpers[r.nextInt(kHelpers.length)];
    st.setCounter(h.key, st.counter(h.key) + 1);
    if (left.isEmpty) st.addStars(30);
    return h.name;
  }
  final got = left[r.nextInt(left.length)];
  c.owned.add(got.id);
  st.setCounter('mystery_opened', st.counter('mystery_opened') + 1);
  return got.name;
}
