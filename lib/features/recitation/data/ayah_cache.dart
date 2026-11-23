import 'package:rawdah/features/recitation/domain/recitation_plan.dart';

import 'ayah_cache_stub.dart' if (dart.library.io) 'ayah_cache_io.dart' as impl;

/// مرجع صوت لآية: ملف محلي إن نُزّل، وإلا روابط بالترتيب للبث المباشر.
class AyahAudio {
  final String? path;
  final List<String> urls;
  const AyahAudio({this.path, this.urls = const []});
  bool get isLocal => path != null;
}

/// حافظة التلاوات على الجهاز: تنزيل آية آية، ثم تعمل بلا إنترنت.
abstract class AyahCache {
  /// يعيد مرجعًا جاهزًا للتشغيل؛ ينزّل الآية أولًا إن أمكن.
  /// يرمي [RecitationUnavailable] إن تعذّر الحصول عليها.
  Future<AyahAudio> resolve(Reciter r, int surah, int ayah);

  /// هل نُزّلت كل ملفات السورة؟
  Future<bool> hasSurah(Reciter r, int surah, int ayahCount);

  /// ينزّل السورة كاملة ويبلغ عن التقدم بين ٠ و١.
  Future<void> downloadSurah(Reciter r, int surah, int ayahCount, {void Function(double)? onProgress});

  /// حجم التلاوات المنزّلة بالبايت.
  Future<int> sizeOnDisk();

  Future<void> clear();
}

class RecitationUnavailable implements Exception {
  final String message;
  const RecitationUnavailable([this.message = 'تحتاج اتصالًا بالإنترنت أول مرة لتنزيل التلاوة']);
  @override
  String toString() => message;
}

/// يتحقق أن البايتات ملف صوت MP3 حقيقي وليست صفحة خطأ.
bool looksLikeMp3(List<int> b) {
  if (b.length < 1024) return false;
  final id3 = b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33; // "ID3"
  final frameSync = b[0] == 0xFF && (b[1] & 0xE0) == 0xE0;
  return id3 || frameSync;
}

AyahCache createAyahCache() => impl.createAyahCache();
