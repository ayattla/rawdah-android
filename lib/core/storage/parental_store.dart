import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مخزن إعدادات الوالدين المشفّرة: الموافقة، والحد اليومي، وتفعيل المنافسة، واللقب.
///
/// على أندرويد تُشفَّر بمفتاح في Android Keystore، فلا تُقرأ ولا تُعدَّل من ملفات
/// التطبيق العادية كما كانت في SharedPreferences.
abstract interface class ParentalStore {
  Future<Map<String, dynamic>?> read();
  Future<bool> write(Map<String, dynamic> data);
}

class SecureParentalStore implements ParentalStore {
  static const _key = 'rawdah_parental_v1';
  final FlutterSecureStorage _storage;
  String? _lastWritten;

  SecureParentalStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      _lastWritten = raw;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// لا يكتب إلا إذا تغيّرت الإعدادات فعلًا، لأن الكتابة المشفّرة أبطأ من العادية.
  @override
  Future<bool> write(Map<String, dynamic> data) async {
    final raw = jsonEncode(data);
    if (raw == _lastWritten) return true;
    try {
      await _storage.write(key: _key, value: raw);
      _lastWritten = raw;
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// للاختبارات: يحفظ في الذاكرة فقط.
class MemoryParentalStore implements ParentalStore {
  Map<String, dynamic>? _data;
  @override
  Future<Map<String, dynamic>?> read() async => _data;
  @override
  Future<bool> write(Map<String, dynamic> data) async {
    _data = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    return true;
  }
}
