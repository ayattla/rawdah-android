import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/features/recitation/data/ayah_cache.dart';
import 'package:rawdah/features/recitation/data/ayah_player.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';

enum RecitationStatus { idle, preparing, playing, paused, echo, error }

class RecitationState {
  final RecitationOptions options;
  final Reciter reciter;
  final RecitationStatus status;
  final int stepIndex;
  final int? highlight;
  final int repeatIndex;
  final String? error;

  /// null = لم يُفحص بعد.
  final bool? offlineReady;
  final double? downloadProgress;
  final int finishedRuns;

  const RecitationState({
    required this.options,
    this.reciter = Reciter.husaryMuallim,
    this.status = RecitationStatus.idle,
    this.stepIndex = 0,
    this.highlight,
    this.repeatIndex = 0,
    this.error,
    this.offlineReady,
    this.downloadProgress,
    this.finishedRuns = 0,
  });

  bool get isActive =>
      status == RecitationStatus.playing ||
      status == RecitationStatus.preparing ||
      status == RecitationStatus.echo;
  bool get isDownloading => downloadProgress != null;

  RecitationState copyWith({
    RecitationOptions? options,
    Reciter? reciter,
    RecitationStatus? status,
    int? stepIndex,
    int? Function()? highlight,
    int? repeatIndex,
    String? Function()? error,
    bool? Function()? offlineReady,
    double? Function()? downloadProgress,
    int? finishedRuns,
  }) =>
      RecitationState(
        options: options ?? this.options,
        reciter: reciter ?? this.reciter,
        status: status ?? this.status,
        stepIndex: stepIndex ?? this.stepIndex,
        highlight: highlight != null ? highlight() : this.highlight,
        repeatIndex: repeatIndex ?? this.repeatIndex,
        error: error != null ? error() : this.error,
        offlineReady: offlineReady != null ? offlineReady() : this.offlineReady,
        downloadProgress: downloadProgress != null ? downloadProgress() : this.downloadProgress,
        finishedRuns: finishedRuns ?? this.finishedRuns,
      );
}

typedef RecitationArgs = ({int surah, int ayahCount});

final ayahCacheProvider = Provider<AyahCache>((ref) => createAyahCache());
final ayahPlayerFactoryProvider = Provider<AyahPlayer Function()>((ref) => JustAudioAyahPlayer.new);
final recitationSleepProvider = Provider<Future<void> Function(Duration)>((ref) => (d) => Future<void>.delayed(d));

/// يشغّل خطة التلاوة خطوة خطوة، مع الإيقاف المؤقت والتكرار ومهلة «ردّد بعدي».
class RecitationController extends Notifier<RecitationState> {
  RecitationController(this.args);
  final RecitationArgs args;

  late AyahPlayer _player;
  late AyahCache _cache;
  late Future<void> Function(Duration) _sleep;

  /// رقم الجولة الحالية؛ أي تغيير يُلغي الحلقة الجارية.
  int _gen = 0;
  Duration _lastDuration = const Duration(seconds: 3);
  List<RecitationStep> _steps = const [];

  @override
  RecitationState build() {
    _cache = ref.watch(ayahCacheProvider);
    _player = ref.watch(ayahPlayerFactoryProvider)();
    _sleep = ref.watch(recitationSleepProvider);
    ref.onDispose(() {
      _gen++;
      unawaited(_player.stop().catchError((_) {}).then((_) => _player.dispose()).catchError((_) {}));
    });
    Future.microtask(_checkOffline);
    return RecitationState(options: RecitationOptions(surah: args.surah, ayahCount: args.ayahCount));
  }

  List<RecitationStep> get steps => _steps;

  Future<void> _checkOffline() async {
    try {
      final ok = await _cache.hasSurah(state.reciter, args.surah, args.ayahCount);
      if (ref.mounted) state = state.copyWith(offlineReady: () => ok);
    } catch (_) {}
  }

  /// يبدأ التلاوة، أو يستأنفها إن كانت موقوفة مؤقتًا.
  Future<void> play() async {
    if (state.status == RecitationStatus.paused) return resume();
    if (state.isActive) return;
    await _run(0);
  }

  /// يبدأ من آية بعينها (عند لمسها في المصحف).
  Future<void> playFrom(int ayah) async {
    await stop();
    final o = state.options;
    final from = ayah.clamp(1, args.ayahCount);
    final to = o.to < from ? args.ayahCount : o.to;
    state = state.copyWith(options: o.copyWith(from: from, to: to));
    await _run(0);
  }

  Future<void> _run(int start) async {
    final gen = ++_gen;
    _steps = buildPlan(state.options);
    state = state.copyWith(error: () => null);
    try {
      for (var i = start; i < _steps.length; i++) {
        if (gen != _gen || !ref.mounted) return;
        state = state.copyWith(stepIndex: i);
        switch (_steps[i]) {
          case final PlayAyah step:
            state = state.copyWith(
              status: RecitationStatus.preparing,
              highlight: () => step.displayAyah,
              repeatIndex: step.repeatIndex,
            );
            final audio = await _cache.resolve(state.reciter, step.surah, step.ayah);
            if (gen != _gen || !ref.mounted) return;
            state = state.copyWith(status: RecitationStatus.playing);
            final d = await _player.play(audio);
            if (d != null && d > Duration.zero) _lastDuration = d;
          case final EchoGap gap:
            await _echo(gen, gap);
        }
      }
      if (gen != _gen || !ref.mounted) return;
      state = state.copyWith(
        status: RecitationStatus.idle,
        stepIndex: 0,
        highlight: () => null,
        finishedRuns: state.finishedRuns + 1,
      );
      unawaited(_checkOffline());
    } on RecitationUnavailable catch (e) {
      if (gen != _gen || !ref.mounted) return;
      state = state.copyWith(status: RecitationStatus.error, error: () => e.message, highlight: () => null);
    } catch (_) {
      if (gen != _gen || !ref.mounted) return;
      state = state.copyWith(
        status: RecitationStatus.error,
        error: () => 'تعذّر تشغيل التلاوة، حاول مرة أخرى',
        highlight: () => null,
      );
    }
  }

  /// مهلة صامتة يردّد فيها الطفل، تتوقف مع الإيقاف المؤقت.
  Future<void> _echo(int gen, EchoGap step) async {
    state = state.copyWith(status: RecitationStatus.echo, highlight: () => step.displayAyah);
    const tick = Duration(milliseconds: 100);
    final total = _lastDuration * step.factor + const Duration(milliseconds: 600);
    var waited = Duration.zero;
    while (waited < total) {
      if (gen != _gen || !ref.mounted) return;
      await _sleep(tick);
      if (state.status != RecitationStatus.paused) waited += tick;
    }
  }

  Future<void> pause() async {
    if (!state.isActive) return;
    final wasPlaying = state.status == RecitationStatus.playing;
    state = state.copyWith(status: RecitationStatus.paused);
    if (wasPlaying) await _player.pause();
  }

  Future<void> resume() async {
    if (state.status != RecitationStatus.paused) return;
    final step = state.stepIndex < _steps.length ? _steps[state.stepIndex] : null;
    if (step is EchoGap) {
      state = state.copyWith(status: RecitationStatus.echo);
    } else {
      state = state.copyWith(status: RecitationStatus.playing);
      await _player.resume();
    }
  }

  Future<void> stop() async {
    _gen++;
    state = state.copyWith(status: RecitationStatus.idle, stepIndex: 0, highlight: () => null);
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> setOptions({int? from, int? to, int? repeatEach, bool? echo, int? rounds}) async {
    if (state.isActive || state.status == RecitationStatus.paused) await stop();
    var o = state.options.copyWith(from: from, to: to, repeatEach: repeatEach, echo: echo, rounds: rounds);
    if (o.to < o.from) o = o.copyWith(to: o.from);
    state = state.copyWith(options: o);
  }

  Future<void> setReciter(Reciter r) async {
    if (r == state.reciter) return;
    await stop();
    state = state.copyWith(reciter: r, offlineReady: () => null);
    await _checkOffline();
  }

  /// ينزّل السورة كاملة لتعمل بلا إنترنت.
  Future<bool> download() async {
    if (state.isDownloading) return false;
    state = state.copyWith(downloadProgress: () => 0, error: () => null);
    try {
      await _cache.downloadSurah(state.reciter, args.surah, args.ayahCount, onProgress: (p) {
        if (ref.mounted) state = state.copyWith(downloadProgress: () => p);
      });
      if (!ref.mounted) return true;
      state = state.copyWith(downloadProgress: () => null, offlineReady: () => true);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        downloadProgress: () => null,
        error: () => e is RecitationUnavailable ? e.message : const RecitationUnavailable().message,
      );
      return false;
    }
  }
}

final recitationControllerProvider =
    NotifierProvider.autoDispose.family<RecitationController, RecitationState, RecitationArgs>(RecitationController.new);
