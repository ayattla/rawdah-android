import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:rawdah/features/recitation/data/ayah_cache.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';

typedef Fetcher = Future<List<int>> Function(Uri uri);

/// تنزيل عبر HttpClient بمهلة، بلا أي ملفات تعريف أو تتبع.
Future<List<int>> httpFetch(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      await res.drain<void>();
      throw HttpException('HTTP ${res.statusCode}', uri: uri);
    }
    final out = <int>[];
    await for (final chunk in res.timeout(const Duration(seconds: 25))) {
      out.addAll(chunk);
    }
    return out;
  } finally {
    client.close(force: true);
  }
}

class FileAyahCache implements AyahCache {
  FileAyahCache({Future<Directory> Function()? root, Fetcher? fetch})
      : _root = root ?? (() async => Directory('${(await getApplicationSupportDirectory()).path}/recitation')),
        _fetch = fetch ?? httpFetch;

  final Future<Directory> Function() _root;
  final Fetcher _fetch;

  /// تنزيلات جارية لنفس الملف تُدمج في طلب واحد.
  final Map<String, Future<File>> _inflight = {};

  Future<File> _file(Reciter r, int surah, int ayah) async {
    final dir = await _root();
    return File('${dir.path}/${r.everyAyahFolder}/${ayahFileName(surah, ayah)}');
  }

  Future<File> _download(Reciter r, int surah, int ayah) async {
    final target = await _file(r, surah, ayah);
    for (final url in ayahUrls(r, surah, ayah)) {
      try {
        final bytes = await _fetch(Uri.parse(url));
        if (!looksLikeMp3(bytes)) {
          continue;
        }
        await target.parent.create(recursive: true);
        // كتابة ذرّية: ملف مؤقت ثم إعادة تسمية، فلا يبقى ملف ناقص إن انقطع التنزيل.
        final tmp = File('${target.path}.part');
        await tmp.writeAsBytes(bytes, flush: true);
        return await tmp.rename(target.path);
      } catch (_) {
        // نجرّب الرابط التالي
      }
    }
    throw const RecitationUnavailable();
  }

  @override
  Future<AyahAudio> resolve(Reciter r, int surah, int ayah) async {
    final f = await _file(r, surah, ayah);
    if (await f.exists() && await f.length() > 1024) return AyahAudio(path: f.path);
    final key = '${r.name}/$surah/$ayah';
    final file = await (_inflight[key] ??= _download(r, surah, ayah).whenComplete(() {
      _inflight.remove(key);
    }));
    return AyahAudio(path: file.path);
  }

  @override
  Future<bool> hasSurah(Reciter r, int surah, int ayahCount) async {
    for (final x in filesForSurah(surah, ayahCount)) {
      final f = await _file(r, x.surah, x.ayah);
      if (!await f.exists()) return false;
    }
    return true;
  }

  @override
  Future<void> downloadSurah(Reciter r, int surah, int ayahCount, {void Function(double)? onProgress}) async {
    final files = filesForSurah(surah, ayahCount);
    var done = 0;
    onProgress?.call(0);
    for (final x in files) {
      await resolve(r, x.surah, x.ayah);
      done++;
      onProgress?.call(done / files.length);
    }
  }

  @override
  Future<int> sizeOnDisk() async {
    final dir = await _root();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  @override
  Future<void> clear() async {
    final dir = await _root();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

AyahCache createAyahCache() => FileAyahCache();
