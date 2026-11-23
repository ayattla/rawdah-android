import 'package:flutter/services.dart';

/// تثبيت التطبيق على الشاشة (Android Screen Pinning / Lock Task):
/// يمنع الطفل من الخروج إلى تطبيقات أخرى أو الإعدادات (ومنها تغيير الساعة).
/// إلغاء التثبيت يتم من النظام نفسه، ويطلب قفل الجهاز إذا فعّله الوالدان في إعداداته.
class Kiosk {
  static const _ch = MethodChannel('rawdah/kiosk');

  static Future<bool> start() => _call('start');
  static Future<bool> stop() => _call('stop');
  static Future<bool> isPinned() => _call('isPinned');

  static Future<bool> _call(String m) async {
    try {
      return (await _ch.invokeMethod<bool>(m)) ?? false;
    } on MissingPluginException {
      return false; // الويب والاختبارات
    } on PlatformException {
      return false;
    }
  }
}
