import 'package:flutter/gestures.dart';
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
/// [onAyahTap] اختياري: لمس آية يعيد رقمها في السورة (للبدء منها في التلاوة).
class QuranText extends StatefulWidget {
  final List<String> ayat;
  final int firstNumber;
  final double fontSize;
  final int? highlight;
  final ValueChanged<int>? onAyahTap;
  const QuranText({
    super.key,
    required this.ayat,
    this.firstNumber = 1,
    this.fontSize = 26,
    this.highlight,
    this.onAyahTap,
  });

  @override
  State<QuranText> createState() => _QuranTextState();
}

class _QuranTextState extends State<QuranText> {
  final List<TapGestureRecognizer> _taps = [];

  void _syncRecognizers() {
    final cb = widget.onAyahTap;
    final need = cb == null ? 0 : widget.ayat.length;
    while (_taps.length > need) {
      _taps.removeLast().dispose();
    }
    while (_taps.length < need) {
      _taps.add(TapGestureRecognizer());
    }
    for (var i = 0; i < _taps.length; i++) {
      final n = widget.firstNumber + i;
      _taps[i].onTap = () => cb?.call(n);
    }
  }

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncRecognizers();
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.ayat.length; i++) {
      final lit = widget.highlight == i;
      spans.add(TextSpan(
        text: widget.ayat[i],
        recognizer: i < _taps.length ? _taps[i] : null,
        style: TextStyle(
          backgroundColor: lit ? const Color(0x55F2B544) : null,
          color: lit ? const Color(0xFF0A4F47) : null,
        ),
      ));
      spans.add(TextSpan(
        text: '\u00A0﴿${arabicNumber(widget.firstNumber + i)}﴾ ',
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
        style: TextStyle(
            fontFamily: 'AmiriQuran', fontSize: widget.fontSize, height: 2.1, color: const Color(0xFF1B1B1B)),
      ),
    );
  }
}
