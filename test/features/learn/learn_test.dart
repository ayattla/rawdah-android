import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/learn/domain/letters.dart';
import 'package:rawdah/features/learn/domain/word_builder.dart';

void main() {
  group('الحروف', () {
    test('٢٨ حرفًا بلا تكرار وكل مثال فيه حرفه', () {
      expect(kLetters.length, 28);
      expect(kLetters.map((l) => l.char).toSet().length, 28);
      for (final l in kLetters) {
        expect(l.words, isNotEmpty);
        for (final w in l.words) {
          expect(splitForHighlight(w, l.char).any((p) => p.$2), true, reason: '${l.name}: $w');
        }
        expect(l.id, 'letter_${l.char}');
        expect(l.isolated, l.char);
        expect(l.initial.contains(l.char), true);
        expect(l.medial.startsWith('ـ'), true, reason: l.name);
        expect(l.medial.contains('ــ'), false, reason: l.name);
      }
      expect(kLetters.where((l) => l.nonJoining).map((l) => l.char).toSet(), {'ا', 'د', 'ذ', 'ر', 'ز', 'و'});
    });

    test('حروف العائلة الواحدة تختلف بالنقاط', () {
      for (final f in kLetterFamilies.where((f) => f.title.startsWith('عائلة'))) {
        expect(f.letters.map((l) => l.dots).toSet().length, f.letters.length, reason: f.title);
      }
    });

    test('تقسيم الكلمة للتلوين يحفظ النص', () {
      final parts = splitForHighlight('كتاب', 'ب');
      expect(parts.map((p) => p.$1).join(), 'كتاب');
      expect(parts.last, ('ب', true));
      expect(splitForHighlight('أرض', 'ا').first, ('أ', true));
      expect(letterByChar('ق')!.name, 'قاف');
      expect(letterByChar('x'), isNull);
    });
  });

  group('تركيب الكلمة', () {
    test('وضع الحروف بالترتيب مع الأخطاء والتلميح', () {
      const w = BuildWord('باب', BuildWord.defaultIcon, 1);
      final g = WordBuilder(w, random: Random(3));
      expect(g.tiles.length, 3);
      expect(g.isComplete, false);
      final alef = g.tiles.indexOf('ا');
      expect(g.place(alef), false); // أول حرف باء
      expect(g.mistakes, 1);
      final h = g.hint()!;
      expect(g.tiles[h], 'ب');
      expect(g.place(h), true);
      expect(g.place(h), false); // مستعمل
      expect(g.place(99), false);
      expect(g.place(alef), true);
      expect(g.typed, 'با');
      final last = g.hint()!;
      expect(g.place(last), true);
      expect(g.isCorrect, true);
      expect(g.hint(), isNull);
      expect(g.place(0), false);
      expect(g.stars, 2);
    });

    test('حروف التمويه لا تكرر حروف الكلمة', () {
      const w = BuildWord('قلم', BuildWord.defaultIcon, 1);
      final g = WordBuilder(w, random: Random(1), decoys: 2);
      expect(g.tiles.length, 5);
      expect(g.tiles.toSet().length, 5);
      expect(g.stars, 3);
      final g2 = WordBuilder(w, random: Random(1));
      for (var i = 0; i < 4; i++) {
        g2.mistakes++;
      }
      expect(g2.stars, 1);
    });

    test('قائمة الكلمات حسب الفئة', () {
      expect(wordsForBand(0).every((w) => w.level == 1), true);
      expect(wordsForBand(2).length, kBuildWords.length);
      expect(kBuildWords.map((w) => w.word).toSet().length, kBuildWords.length);
      expect(const BuildWord('بيت', BuildWord.defaultIcon, 1).letters, ['ب', 'ي', 'ت']);
    });
  });

  group('العدّ والمقارنة', () {
    test('جولات العد صحيحة', () {
      for (final band in [0, 1, 2]) {
        final rs = countRounds(band, random: Random(band));
        expect(rs.length, 6);
        for (var i = 0; i < rs.length; i++) {
          final r = rs[i];
          expect(r.options, contains(r.count));
          expect(r.options.toSet().length, 3);
          expect(r.options.every((o) => o >= 1), true);
          expect(r.count, lessThanOrEqualTo(band == 0 ? 10 : (band == 1 ? 20 : 30)));
          if (i > 0) expect(r.count, isNot(rs[i - 1].count));
        }
      }
    });

    test('جولات المقارنة وفيها تساوٍ', () {
      final rs = compareRounds(0, random: Random(2));
      expect(rs.length, 6);
      expect(rs[3].answer, 2);
      expect(const CompareRound(5, 3).answer, 0);
      expect(const CompareRound(2, 7).answer, 1);
      expect(rs.every((r) => r.a <= 9 && r.b <= 9), true);
    });
  });
}
