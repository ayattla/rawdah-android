import 'dart:async';

import 'package:rawdah/features/recitation/data/ayah_cache.dart';
import 'package:rawdah/features/recitation/data/ayah_player.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';

class FakeCache implements AyahCache {
  final Set<String> stored = {};
  bool fail = false;
  final List<String> resolved = [];

  @override
  Future<AyahAudio> resolve(Reciter r, int surah, int ayah) async {
    if (fail) throw const RecitationUnavailable();
    resolved.add('$surah:$ayah');
    stored.add('${r.name}/$surah/$ayah');
    return AyahAudio(path: '/fake/$surah/$ayah.mp3');
  }

  @override
  Future<bool> hasSurah(Reciter r, int surah, int ayahCount) async =>
      filesForSurah(surah, ayahCount).every((x) => stored.contains('${r.name}/${x.surah}/${x.ayah}'));

  @override
  Future<void> downloadSurah(Reciter r, int surah, int ayahCount, {void Function(double)? onProgress}) async {
    if (fail) throw const RecitationUnavailable();
    final files = filesForSurah(surah, ayahCount);
    for (var i = 0; i < files.length; i++) {
      stored.add('${r.name}/${files[i].surah}/${files[i].ayah}');
      onProgress?.call((i + 1) / files.length);
    }
  }

  @override
  Future<int> sizeOnDisk() async => stored.length * 1000;

  @override
  Future<void> clear() async => stored.clear();
}

/// مشغّل وهمي: إما ينهي الآية فورًا، أو ينتظر حتى يُستدعى [finish] (للتحكم الدقيق في الاختبار).
class FakePlayer implements AyahPlayer {
  FakePlayer({this.auto = true});
  bool auto;
  final List<String> played = [];
  Completer<Duration?>? _current;
  int pauses = 0, resumes = 0, stops = 0;
  bool disposed = false;

  @override
  Future<Duration?> play(AyahAudio audio) {
    played.add(audio.path ?? audio.urls.first);
    if (auto) return Future.value(const Duration(seconds: 2));
    _current = Completer<Duration?>();
    return _current!.future;
  }

  void finish() {
    final c = _current;
    _current = null;
    c?.complete(const Duration(seconds: 2));
  }

  @override
  Future<void> pause() async => pauses++;
  @override
  Future<void> resume() async => resumes++;
  @override
  Future<void> stop() async {
    stops++;
    finish();
  }

  @override
  Future<void> dispose() async => disposed = true;
}
