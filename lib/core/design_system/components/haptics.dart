import 'package:flutter/services.dart';

/// اهتزازات تتكيف مع ما حدث: نقرة خفيفة للمس، نبضة مزدوجة للصح،
/// اهتزاز ثقيل متكرر للخطأ، وسلسلة احتفالية للجائزة.
class Haptics {
  Haptics._();

  /// يوقفها ولي الأمر مع «تقليل الحركة».
  static bool enabled = true;

  static Future<void> _pulse(List<Future<void> Function()> steps, {int gapMs = 70}) async {
    if (!enabled) return;
    for (var i = 0; i < steps.length; i++) {
      await steps[i]();
      if (i < steps.length - 1) await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
  }

  static Future<void> tap() => _pulse([HapticFeedback.selectionClick]);
  static Future<void> success() => _pulse([HapticFeedback.lightImpact, HapticFeedback.mediumImpact], gapMs: 90);
  static Future<void> error() => _pulse([HapticFeedback.heavyImpact, HapticFeedback.heavyImpact], gapMs: 110);
  static Future<void> celebrate() => _pulse(
        [HapticFeedback.mediumImpact, HapticFeedback.lightImpact, HapticFeedback.mediumImpact, HapticFeedback.heavyImpact],
        gapMs: 120,
      );
}
