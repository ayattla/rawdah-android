import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// رمز الوالدين: لا يُحفظ الرمز نفسه أبدًا، بل بصمته (SHA-256 مكرر مع ملح عشوائي)،
/// داخل المخزن المشفّر. وبعد 5 محاولات خاطئة يُقفل الإدخال مدة تتضاعف.
class ParentPin {
  static const iterations = 20000;
  static const maxAttempts = 5;

  final String salt;
  final String hash;
  const ParentPin(this.salt, this.hash);

  static bool validFormat(String pin) => RegExp(r'^[0-9]{4}$').hasMatch(pin);

  static String _digest(String salt, String pin) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  factory ParentPin.create(String pin, {Random? random}) {
    final r = random ?? Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
    return ParentPin(salt, _digest(salt, pin));
  }

  bool verify(String pin) {
    final d = _digest(salt, pin);
    // مقارنة بزمن ثابت
    if (d.length != hash.length) return false;
    var diff = 0;
    for (var i = 0; i < d.length; i++) {
      diff |= d.codeUnitAt(i) ^ hash.codeUnitAt(i);
    }
    return diff == 0;
  }

  Map<String, String> toJson() => {'salt': salt, 'hash': hash};
  static ParentPin? fromJson(Object? j) {
    if (j is! Map) return null;
    final s = j['salt'], h = j['hash'];
    return s is String && h is String ? ParentPin(s, h) : null;
  }
}

/// عدّاد المحاولات الخاطئة: بعد 5 أخطاء قفل 30 ثانية، ثم يتضاعف حتى 15 دقيقة.
class PinAttempts {
  int failures = 0;
  DateTime? lockedUntil;

  bool isLocked(DateTime now) => lockedUntil != null && now.isBefore(lockedUntil!);

  void recordFailure(DateTime now) {
    failures++;
    if (failures >= ParentPin.maxAttempts) {
      final rounds = failures - ParentPin.maxAttempts;
      final secs = (30 * (1 << rounds)).clamp(30, 900);
      lockedUntil = now.add(Duration(seconds: secs));
    }
  }

  void reset() {
    failures = 0;
    lockedUntil = null;
  }
}
