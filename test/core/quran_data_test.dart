import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/core/content/quran_data.dart';

/// عدد آيات كل سورة في مصحف المدينة (العدّ الكوفي) للتحقق من سلامة النص المولّد.
const _standard = {
  1: 7, 78: 40, 79: 46, 80: 42, 81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30,
  90: 20, 91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11, 101: 11, 102: 8,
  103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4, 113: 5, 114: 6,
};

void main() {
  test('جزء عمّ كامل مع الفاتحة وعدد الآيات صحيح', () {
    expect(kSurahs.map((s) => s.number).toSet().length, kSurahs.length);
    expect({for (final s in kSurahs) s.number: s.ayat.length}, _standard);
    for (final s in kSurahs) {
      expect(s.name, isNotEmpty);
      expect(s.ayat.every((a) => a.trim().isNotEmpty), true, reason: s.name);
    }
  });

  test('الترتيب: الفاتحة ثم من الناس نزولًا', () {
    expect(kSurahs.first.number, 1);
    final rest = kSurahs.skip(1).map((s) => s.number).toList();
    expect(rest, List.generate(37, (i) => 114 - i));
  });
}
