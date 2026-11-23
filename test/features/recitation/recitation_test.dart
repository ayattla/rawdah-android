import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rawdah/features/recitation/data/ayah_cache.dart';
import 'package:rawdah/features/recitation/data/ayah_cache_io.dart';
import 'package:rawdah/features/recitation/domain/recitation_plan.dart';
import 'package:rawdah/features/recitation/presentation/recitation_controller.dart';

import 'recitation_fakes.dart';

List<int> mp3Bytes([int n = 2048]) => [0x49, 0x44, 0x33, ...List.filled(n, 7)];
List<int> htmlBytes() => '<html>404</html>'.codeUnits + List.filled(2000, 32);

Future<void> settle() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('خطة التلاوة', () {
    test('البسملة قبل السورة إلا الفاتحة والتوبة', () {
      expect(buildPlan(const RecitationOptions(surah: 112, ayahCount: 4)).first, const PlayAyah(1, 1));
      expect((buildPlan(const RecitationOptions(surah: 1, ayahCount: 7)).first as PlayAyah).displayAyah, 1);
      expect((buildPlan(const RecitationOptions(surah: 9, ayahCount: 3)).first as PlayAyah).isBasmala, false);
      // البدء من منتصف السورة بلا بسملة
      final mid = buildPlan(const RecitationOptions(surah: 112, ayahCount: 4, from: 2));
      expect(mid.first, const PlayAyah(112, 2, displayAyah: 2));
      expect(mid.length, 3);
      // إيقاف البسملة يدويًا
      expect(buildPlan(const RecitationOptions(surah: 112, ayahCount: 4, basmala: false)).length, 4);
    });

    test('التكرار و«ردّد بعدي» والجولات', () {
      final p = buildPlan(const RecitationOptions(surah: 108, ayahCount: 3, from: 1, to: 2, repeatEach: 2, echo: true, rounds: 2, basmala: false));
      expect(p.length, 2 * 2 * 2 * 2);
      expect(p[0], const PlayAyah(108, 1, displayAyah: 1));
      expect(p[1], const EchoGap(1, 1.15));
      expect(p[2], const PlayAyah(108, 1, displayAyah: 1, repeatIndex: 1));
      expect(p[4], const PlayAyah(108, 2, displayAyah: 2));
      expect(p.toString(), contains('Gap'));
    });

    test('تصحيح القيم الخارجة عن الحدود', () {
      final p = buildPlan(const RecitationOptions(surah: 108, ayahCount: 3, from: 0, to: 99, repeatEach: 50, rounds: 9, basmala: false));
      expect(p.whereType<PlayAyah>().length, 3 * 10 * 5);
      expect(buildPlan(const RecitationOptions(surah: 108, ayahCount: 0)), isEmpty);
      final inverted = buildPlan(const RecitationOptions(surah: 108, ayahCount: 3, from: 3, to: 1, basmala: false));
      expect(inverted, [const PlayAyah(108, 3, displayAyah: 3)]);
    });

    test('أسماء الملفات والروابط الاحتياطية', () {
      expect(ayahFileName(1, 1), '001001.mp3');
      expect(ayahFileName(114, 6), '114006.mp3');
      final m = ayahUrls(Reciter.husaryMuallim, 105, 3);
      expect(m.first, 'https://everyayah.com/data/Husary_Muallim_128kbps/105003.mp3');
      expect(m, contains('https://everyayah.com/data/Husary_128kbps/105003.mp3'));
      expect(m.last, 'https://verses.quran.com/Husary/mp3/105003.mp3');
      expect(ayahUrls(Reciter.husary, 1, 1).length, 2);
      expect(Reciter.byName('husary'), Reciter.husary);
      expect(Reciter.byName('???'), Reciter.husaryMuallim);
      expect(filesForSurah(112, 4).length, 5);
      expect(filesForSurah(1, 7).length, 7);
    });

    test('النسخ والمقارنة', () {
      const o = RecitationOptions(surah: 108, ayahCount: 3);
      final c = o.copyWith(from: 2, echo: true, rounds: 3, repeatEach: 3, basmala: false, to: 3);
      expect([c.from, c.to, c.echo, c.rounds, c.repeatEach, c.basmala], [2, 3, true, 3, 3, false]);
      expect(const PlayAyah(1, 1).hashCode, const PlayAyah(1, 1).hashCode);
      expect(const EchoGap(1, 1).hashCode, const EchoGap(1, 1).hashCode);
    });
  });

  test('التحقق من ملف الصوت', () {
    expect(looksLikeMp3(mp3Bytes()), true);
    expect(looksLikeMp3([0xFF, 0xFB, ...List.filled(2000, 0)]), true);
    expect(looksLikeMp3(htmlBytes()), false);
    expect(looksLikeMp3([0x49, 0x44, 0x33]), false);
    expect(const AyahAudio(path: 'x').isLocal, true);
    expect(const RecitationUnavailable('م').toString(), 'م');
  });

  group('حافظة الملفات', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('rec'));
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('يتجاوز الرابط المعطوب إلى الاحتياطي ويحفظ الملف', () async {
      final asked = <String>[];
      final cache = FileAyahCache(
        root: () async => tmp,
        fetch: (u) async {
          asked.add(u.toString());
          if (u.host == 'everyayah.com' && u.path.contains('Muallim')) return htmlBytes();
          return mp3Bytes();
        },
      );
      final a = await cache.resolve(Reciter.husaryMuallim, 112, 1);
      expect(a.isLocal, true);
      expect(File(a.path!).existsSync(), true);
      expect(asked.length, 2);
      // المرة الثانية من الجهاز بلا شبكة
      await cache.resolve(Reciter.husaryMuallim, 112, 1);
      expect(asked.length, 2);
      expect(await cache.sizeOnDisk(), greaterThan(2000));
    });

    test('تنزيل السورة كاملة ودمج الطلبات المتزامنة', () async {
      var calls = 0;
      final cache = FileAyahCache(root: () async => tmp, fetch: (u) async {
        calls++;
        return mp3Bytes();
      });
      expect(await cache.hasSurah(Reciter.husary, 108, 3), false);
      await Future.wait([cache.resolve(Reciter.husary, 108, 1), cache.resolve(Reciter.husary, 108, 1)]);
      expect(calls, 1);
      final progress = <double>[];
      await cache.downloadSurah(Reciter.husary, 108, 3, onProgress: progress.add);
      expect(progress.first, 0);
      expect(progress.last, 1);
      expect(await cache.hasSurah(Reciter.husary, 108, 3), true);
      expect(calls, 4); // البسملة + آيتان جديدتان + الأولى سابقًا
      await cache.clear();
      expect(await cache.sizeOnDisk(), 0);
      await cache.clear();
    });

    test('فشل كل الروابط يعطي رسالة واضحة ولا يترك ملفًا ناقصًا', () async {
      final cache = FileAyahCache(root: () async => tmp, fetch: (u) async => throw const SocketException('offline'));
      await expectLater(cache.resolve(Reciter.husary, 112, 2), throwsA(isA<RecitationUnavailable>()));
      expect(tmp.listSync(recursive: true).whereType<File>(), isEmpty);
    });
  });

  group('متحكم التلاوة', () {
    late FakeCache cache;
    late FakePlayer player;
    late ProviderContainer box;
    const args = (surah: 108, ayahCount: 3);

    setUp(() {
      cache = FakeCache();
      player = FakePlayer();
      box = ProviderContainer(overrides: [
        ayahCacheProvider.overrideWithValue(cache),
        ayahPlayerFactoryProvider.overrideWithValue(() => player),
        recitationSleepProvider.overrideWithValue((_) => Future<void>.delayed(Duration.zero)),
      ]);
    });
    tearDown(() => box.dispose());

    RecitationController c() => box.read(recitationControllerProvider(args).notifier);
    RecitationState s() => box.read(recitationControllerProvider(args));

    test('يشغّل السورة بالبسملة ثم ينتهي ويحفظها', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      await settle();
      expect(s().offlineReady, false);
      await c().play();
      expect(player.played.length, 4);
      expect(player.played.first, '/fake/1/1.mp3');
      expect(s().status, RecitationStatus.idle);
      expect(s().finishedRuns, 1);
      await settle();
      expect(s().offlineReady, true);
      sub.close();
    });

    test('ردّد بعدي مع التكرار', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      await c().setOptions(echo: true, repeatEach: 3, from: 2, to: 1);
      expect(s().options.to, 2);
      final seen = <RecitationStatus>{};
      final sub2 = box.listen(recitationControllerProvider(args), (_, n) => seen.add(n.status));
      await c().play();
      expect(player.played.length, 3);
      expect(seen, containsAll([RecitationStatus.preparing, RecitationStatus.playing, RecitationStatus.echo]));
      sub.close();
      sub2.close();
    });

    test('إيقاف مؤقت واستئناف وإيقاف', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      player.auto = false;
      final run = c().play();
      await settle();
      expect(s().status, RecitationStatus.playing);
      expect(s().highlight, null); // البسملة
      await c().pause();
      expect(s().status, RecitationStatus.paused);
      expect(player.pauses, 1);
      await c().play(); // يستأنف
      expect(s().status, RecitationStatus.playing);
      expect(player.resumes, 1);
      await c().play(); // جارية: لا شيء
      player.finish();
      await settle();
      expect(s().highlight, 1);
      await c().stop();
      await run;
      expect(s().status, RecitationStatus.idle);
      expect(s().highlight, null);
      expect(s().finishedRuns, 0);
      await c().pause(); // لا شيء
      await c().resume(); // لا شيء
      sub.close();
    });

    test('الإيقاف المؤقت أثناء مهلة الترديد', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      await c().setOptions(echo: true, from: 3);
      player.auto = false;
      final run = c().play();
      await settle();
      player.finish();
      await Future<void>.delayed(Duration.zero);
      expect(s().status, RecitationStatus.echo);
      await c().pause();
      expect(s().status, RecitationStatus.paused);
      await settle();
      expect(s().status, RecitationStatus.paused);
      await c().resume();
      expect(s().status, RecitationStatus.echo);
      expect(player.resumes, 0);
      await run;
      expect(s().status, RecitationStatus.idle);
      sub.close();
    });

    test('البدء من آية ملموسة', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      await c().setOptions(to: 1);
      await c().playFrom(2);
      expect(s().options.from, 2);
      expect(s().options.to, 3);
      expect(player.played, ['/fake/108/2.mp3', '/fake/108/3.mp3']);
      sub.close();
    });

    test('تعذّر الشبكة يظهر رسالة', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      cache.fail = true;
      await c().play();
      expect(s().status, RecitationStatus.error);
      expect(s().error, isNotNull);
      expect(await c().download(), false);
      expect(s().error, contains('الإنترنت'));
      expect(s().isDownloading, false);
      sub.close();
    });

    test('تنزيل السورة وتغيير القارئ', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      await settle();
      final progress = <double?>[];
      final sub2 = box.listen(recitationControllerProvider(args), (_, n) => progress.add(n.downloadProgress));
      expect(await c().download(), true);
      expect(progress, contains(1.0));
      expect(s().offlineReady, true);
      await c().setReciter(Reciter.husaryMuallim); // نفسه
      await c().setReciter(Reciter.husary);
      expect(s().reciter, Reciter.husary);
      expect(s().offlineReady, false);
      sub.close();
      sub2.close();
    });

    test('خطأ غير متوقع من المشغّل', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      final bad = ProviderContainer(overrides: [
        ayahCacheProvider.overrideWithValue(cache),
        ayahPlayerFactoryProvider.overrideWithValue(() => _ThrowingPlayer()),
        recitationSleepProvider.overrideWithValue((_) async {}),
      ]);
      final keep = bad.listen(recitationControllerProvider(args), (_, __) {});
      await bad.read(recitationControllerProvider(args).notifier).play();
      expect(bad.read(recitationControllerProvider(args)).status, RecitationStatus.error);
      keep.close();
      bad.dispose();
      sub.close();
    });

    test('يحرّر المشغّل عند إغلاق الشاشة', () async {
      final sub = box.listen(recitationControllerProvider(args), (_, __) {});
      expect(c().steps, isEmpty);
      sub.close();
      await settle();
      expect(player.disposed, true);
    });
  });
}

class _ThrowingPlayer extends FakePlayer {
  @override
  Future<Duration?> play(AyahAudio audio) async => throw StateError('codec');
}
