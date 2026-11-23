import 'package:rawdah/features/recitation/data/ayah_cache.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';

/// على الويب (المعاينة): لا تخزين، يُبث الصوت من الروابط مباشرة.
class StreamingAyahCache implements AyahCache {
  @override
  Future<AyahAudio> resolve(Reciter r, int surah, int ayah) async => AyahAudio(urls: ayahUrls(r, surah, ayah));

  @override
  Future<bool> hasSurah(Reciter r, int surah, int ayahCount) async => false;

  @override
  Future<void> downloadSurah(Reciter r, int surah, int ayahCount, {void Function(double)? onProgress}) async =>
      throw const RecitationUnavailable('التنزيل متاح في تطبيق الجوال فقط');

  @override
  Future<int> sizeOnDisk() async => 0;

  @override
  Future<void> clear() async {}
}

AyahCache createAyahCache() => StreamingAyahCache();
