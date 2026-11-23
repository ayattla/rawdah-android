import 'package:flutter/material.dart';

/// إعدادات الوصول السارية في الشاشة: تجمع اختيار الوالدين في التطبيق
/// مع إعدادات النظام (التباين العالي، إيقاف الحركة، حجم الخط).
class A11y extends InheritedWidget {
  /// تباين عالٍ: بلا نقوش خلفية، وحدود وألوان نص أقوى.
  final bool highContrast;

  /// تقليل الحركة: لا دوران ولا تأرجح، فقط تغيّرات فورية.
  final bool reduceMotion;

  const A11y({super.key, required this.highContrast, required this.reduceMotion, required super.child});

  static A11y? _of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<A11y>();

  static bool highContrastOf(BuildContext context) =>
      (_of(context)?.highContrast ?? false) || MediaQuery.maybeOf(context)?.highContrast == true;

  static bool reduceMotionOf(BuildContext context) =>
      (_of(context)?.reduceMotion ?? false) || MediaQuery.maybeOf(context)?.disableAnimations == true;

  @override
  bool updateShouldNotify(A11y old) => old.highContrast != highContrast || old.reduceMotion != reduceMotion;
}

/// يطبّق إعدادات الوصول على كل التطبيق: حجم الخط بحد أقصى آمن للتخطيط،
/// والتباين العالي وتقليل الحركة.
class A11yScope extends StatelessWidget {
  final double appTextScale;
  final bool highContrast;
  final bool reduceMotion;
  final Widget child;
  const A11yScope({
    super.key,
    required this.appTextScale,
    required this.highContrast,
    required this.reduceMotion,
    required this.child,
  });

  /// أقصى تكبير يتحمله تخطيط البلاطات دون قص.
  static const maxScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final system = mq.textScaler.scale(16) / 16;
    final scale = (system * appTextScale).clamp(1.0, maxScale);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(scale)),
      child: A11y(highContrast: highContrast, reduceMotion: reduceMotion, child: child),
    );
  }
}
