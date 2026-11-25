import 'dart:math';

import 'package:flutter/material.dart';

/// كلمة لتركيبها من حروفها، مع أيقونة جماد أو نبات تدل عليها.
class BuildWord {
  final String word;
  final IconData icon;
  final int level;
  const BuildWord(this.word, this.icon, this.level);

  static const defaultIcon = Icons.text_fields_rounded;

  /// الحروف منفصلة بالترتيب.
  List<String> get letters => [for (final r in word.runes) String.fromCharCode(r)];
}

const kBuildWords = <BuildWord>[
  // مستوى ١: ثلاثة حروف
  BuildWord('باب', Icons.door_front_door_rounded, 1),
  BuildWord('بيت', Icons.home_rounded, 1),
  BuildWord('قلم', Icons.edit_rounded, 1),
  BuildWord('شمس', Icons.wb_sunny_rounded, 1),
  BuildWord('قمر', Icons.nightlight_round, 1),
  BuildWord('ماء', Icons.water_drop_rounded, 1),
  BuildWord('تمر', Icons.spa_rounded, 1),
  BuildWord('جبل', Icons.terrain_rounded, 1),
  BuildWord('نجم', Icons.auto_awesome_rounded, 1),
  BuildWord('ورد', Icons.local_florist_rounded, 1),
  // مستوى ٢: أربعة حروف
  BuildWord('كتاب', Icons.menu_book_rounded, 2),
  BuildWord('مسجد', Icons.mosque_rounded, 2),
  BuildWord('سماء', Icons.cloud_rounded, 2),
  BuildWord('شجرة', Icons.park_rounded, 2),
  BuildWord('نخلة', Icons.forest_rounded, 2),
  BuildWord('ساعة', Icons.schedule_rounded, 2),
  BuildWord('كرسي', Icons.chair_rounded, 2),
  BuildWord('مفتاح', Icons.key_rounded, 2),
  // مستوى ٣: خمسة حروف فأكثر
  BuildWord('فانوس', Icons.light_rounded, 3),
  BuildWord('مصباح', Icons.lightbulb_rounded, 3),
  BuildWord('سيارة', Icons.directions_car_rounded, 3),
  BuildWord('حديقة', Icons.yard_rounded, 3),
  BuildWord('مدرسة', Icons.school_rounded, 3),
  BuildWord('طائرة', Icons.flight_rounded, 3),
];

List<BuildWord> wordsForBand(int band) => kBuildWords.where((w) => w.level <= band + 1).toList();

/// حالة لعبة تركيب الكلمة: خانات تُملأ بالترتيب من بلاطات مخلوطة.
class WordBuilder {
  final BuildWord target;

  /// البلاطات المعروضة (حروف الكلمة مخلوطة + حروف تمويه للمستويات الأعلى).
  final List<String> tiles;

  /// لكل خانة: رقم البلاطة التي وُضعت فيها، أو null.
  final List<int?> slots;
  int mistakes = 0;

  WordBuilder._(this.target, this.tiles) : slots = List<int?>.filled(target.letters.length, null);

  factory WordBuilder(BuildWord w, {Random? random, int decoys = 0}) {
    final r = random ?? Random();
    final pool = [...w.letters];
    const extra = 'بتنملسرقكهد';
    var i = 0;
    while (i < decoys) {
      final ch = extra[r.nextInt(extra.length)];
      if (!pool.contains(ch)) {
        pool.add(ch);
        i++;
      }
    }
    pool.shuffle(r);
    return WordBuilder._(w, pool);
  }

  bool isUsed(int tile) => slots.contains(tile);
  int get filled => slots.where((s) => s != null).length;
  bool get isComplete => filled == slots.length;

  /// الكلمة كما رُكبت حتى الآن (تتصل الحروف تلقائيًا في العرض).
  String get typed => [for (final s in slots) if (s != null) tiles[s]].join();
  bool get isCorrect => isComplete && typed == target.word;

  /// يضع البلاطة في أول خانة فارغة إن كانت هي الحرف الصحيح لها. يعيد true عند النجاح.
  bool place(int tile) {
    if (isComplete || isUsed(tile) || tile < 0 || tile >= tiles.length) return false;
    final next = slots.indexOf(null);
    if (tiles[tile] != target.letters[next]) {
      mistakes++;
      return false;
    }
    slots[next] = tile;
    return true;
  }

  /// تلميح: رقم بلاطة الحرف التالي الصحيح.
  int? hint() {
    if (isComplete) return null;
    final need = target.letters[slots.indexOf(null)];
    for (var i = 0; i < tiles.length; i++) {
      if (!isUsed(i) && tiles[i] == need) return i;
    }
    return null;
  }

  /// نجوم حسب الأخطاء: ٣ بلا خطأ، ٢ لخطأ أو اثنين، ١ لأكثر.
  int get stars => mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1);
}

/// جولة عدّ: عدد من حبات التمر وخيارات للجواب.
class CountRound {
  final int count;
  final List<int> options;
  const CountRound(this.count, this.options);
}

List<CountRound> countRounds(int band, {int rounds = 6, Random? random}) {
  final r = random ?? Random();
  final maxN = band == 0 ? 10 : (band == 1 ? 20 : 30);
  final out = <CountRound>[];
  int? last;
  while (out.length < rounds) {
    final n = 1 + r.nextInt(maxN);
    if (n == last) continue;
    last = n;
    final opts = <int>{n};
    while (opts.length < 3) {
      final d = 1 + r.nextInt(3);
      final v = r.nextBool() ? n + d : n - d;
      if (v >= 1) opts.add(v);
    }
    out.add(CountRound(n, opts.toList()..shuffle(r)));
  }
  return out;
}

/// جولة مقارنة: صحنان من التمر، أيهما أكثر؟
class CompareRound {
  final int a;
  final int b;
  const CompareRound(this.a, this.b);

  /// 0 إن كان الأول أكثر، 1 إن كان الثاني، 2 إن تساويا.
  int get answer => a > b ? 0 : (b > a ? 1 : 2);
}

List<CompareRound> compareRounds(int band, {int rounds = 6, Random? random}) {
  final r = random ?? Random();
  final maxN = band == 0 ? 9 : 20;
  return List.generate(rounds, (i) {
    final a = 1 + r.nextInt(maxN);
    // جولة متساوية واحدة تقريبًا في كل ست جولات
    final b = i == 3 ? a : 1 + r.nextInt(maxN);
    return CompareRound(a, b);
  });
}
