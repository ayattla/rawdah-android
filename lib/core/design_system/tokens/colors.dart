import 'package:flutter/material.dart';

/// الألوان. كل لون يحمل نصًا أبيض يحقق تباين WCAG AA (4.5:1) على الأقل.
class RC {
  /// نص فوق خلفيات العوالم الداكنة.
  static const onDark = Color(0xFFFFFFFF);
  static const onDarkSoft = Color(0xFFD9D2FF);

  /// فيروزي الزليج: اللون الأساسي.
  static const green = Color(0xFF0B7A6E); // نص أبيض عليه 5.2:1
  static const greenDark = Color(0xFF0A6C61);

  /// ورق نعناعي: خلفية الشاشات.
  static const sand = Color(0xFFEAF6F4);
  static const sandDark = Color(0xFFCDE6E1);
  static const sky = Color(0xFFD8ECFF);

  /// زعفراني: النجوم والجوائز.
  static const gold = Color(0xFFF5B82E);
  static const goldDark = Color(0xFF9A6700); // نص أبيض عليه 4.9:1

  static const sea = Color(0xFF1C6FB8); // نص أبيض عليه 5.2:1

  /// رماني: الحماس والتنبيه.
  static const coral = Color(0xFFCC3A47); // نص أبيض عليه 4.9:1

  /// بنفسجي البلاط.
  static const plum = Color(0xFF6A5AE0);

  /// لازوردي: النصوص والخلفيات الداكنة.
  static const ink = Color(0xFF1D2B64);

  /// نص ثانوي: بديل الشفافية حتى يبقى التباين فوق 7:1 على الخلفيات الفاتحة.
  static const inkSoft = Color(0xFF3D4878);

  /// ألوان بلاطات إضافية (كلها تحقق 4.5:1 مع النص الأبيض).
  static const garden = Color(0xFF2E7D3E);
  static const rose = Color(0xFF9C4068);
  static const night = Color(0xFF18204D);
  static const paper = Colors.white;
}

/// ظل البلاطة المجسّمة: نسخة أغمق من اللون نفسه.
Color shadeOf(Color c, [double amount = 0.18]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// أنماط الخط. «بلو بهيجان» للعناوين والأرقام، و«روبيك» للنص.
