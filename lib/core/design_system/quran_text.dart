import 'package:flutter/material.dart';

import 'package:rawdah/core/content/quran_data.dart';

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String arabicNumber(int n) => n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();

Surah? surahByNumber(int n) {
  for (final s in kSurahs) {
    if (s.number == n) return s;
  }
  return null;
}

class ResolvedAyat {
  final List<String> ayat;
  final int from;
  const ResolvedAyat(this.ayat, this.from);
}

/// يحوّل مفتاح المقطع إلى آيات من نص المصحف: 'surah:105' أو مفتاح من kPassages.
ResolvedAyat resolvePassage(String key) {
  if (key.startsWith('surah:')) {
    final s = surahByNumber(int.tryParse(key.substring(6)) ?? 0);
    return ResolvedAyat(s?.ayat ?? const [], 1);
  }
  final p = kPassages[key];
  return p == null ? const ResolvedAyat([], 1) : ResolvedAyat(p.ayat, p.from);
}

/// عرض آيات بخط المصحف مع أرقام الآيات. لا يُقرأ بالصوت الآلي.
class QuranText extends StatelessWidget {
  final List<String> ayat;
  final int firstNumber;
  final double fontSize;
  final int? highlight;
  const QuranText({super.key, required this.ayat, this.firstNumber = 1, this.fontSize = 26, this.highlight});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < ayat.length; i++) {
      spans.add(TextSpan(
        text: ayat[i],
        style: TextStyle(
          backgroundColor: highlight == i ? const Color(0x33F2B544) : null,
        ),
      ));
      spans.add(TextSpan(
        text: ' ﴿${arabicNumber(firstNumber + i)}﴾ ',
        style: const TextStyle(color: Color(0xFF2E7D5B)),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9B865), width: 2),
      ),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'AmiriQuran', fontSize: fontSize, height: 2.1, color: const Color(0xFF1B1B1B)),
      ),
    );
  }
}
