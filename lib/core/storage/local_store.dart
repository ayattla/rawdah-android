import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// التخزين المحلي (Offline-First): تقدم الأطفال ونسخ لوحات الترتيب المخزّنة.
/// Hive أسرع من SharedPreferences في الكتابة المتكررة، ولا يعيد كتابة الملف كله كل مرة.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class HiveLocalStore implements LocalStore {
  static const _boxName = 'rawdah_v1';
  static Future<Box<String>>? _opening;

  static Future<Box<String>> _box() => _opening ??= () async {
        await Hive.initFlutter();
        return Hive.openBox<String>(_boxName);
      }();

  @override
  Future<String?> read(String key) async => (await _box()).get(key);

  @override
  Future<void> write(String key, String value) async => (await _box()).put(key, value);

  @override
  Future<void> delete(String key) async => (await _box()).delete(key);
}

/// للاختبارات.
class MemoryLocalStore implements LocalStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}
