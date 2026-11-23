import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:rawdah/features/recitation/data/ayah_cache.dart';

/// مشغّل آية واحدة. [play] يكتمل عند انتهاء الآية أو إيقافها، ويعيد مدتها.
abstract class AyahPlayer {
  Future<Duration?> play(AyahAudio audio);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioAyahPlayer implements AyahPlayer {
  final AudioPlayer _p = AudioPlayer();

  @override
  Future<Duration?> play(AyahAudio audio) async {
    Duration? d;
    if (audio.isLocal) {
      d = await _p.setFilePath(audio.path!);
    } else {
      Object? last;
      for (final u in audio.urls) {
        try {
          d = await _p.setUrl(u);
          last = null;
          break;
        } catch (e) {
          last = e;
        }
      }
      if (last != null || audio.urls.isEmpty) throw const RecitationUnavailable();
    }
    final finished = _p.playerStateStream.firstWhere(
      (s) => s.processingState == ProcessingState.completed || s.processingState == ProcessingState.idle,
    );
    unawaited(_p.play());
    await finished;
    return d ?? _p.duration;
  }

  @override
  Future<void> pause() => _p.pause();

  @override
  Future<void> resume() async => unawaited(_p.play());

  @override
  Future<void> stop() => _p.stop();

  @override
  Future<void> dispose() => _p.dispose();
}
