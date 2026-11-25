// لقطات الشاشات: ترسم شاشات روضة الحقيقية صورًا PNG للمراجعة البصرية.
// تعمل في GitHub Actions فقط: flutter test test_shots --update-goldens
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/core/content/quran_data.dart';
import 'package:rawdah/features/recitation/presentation/recitation_controller.dart';
import '../test/features/recitation/recitation_fakes.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/core/storage/local_store.dart';
import 'package:rawdah/core/storage/parental_store.dart';
import 'package:rawdah/features/journeys/data/journeys_data.dart';
import 'package:rawdah/features/profiles/presentation/child_picker_screen.dart';
import 'package:rawdah/features/competition/presentation/competition_screen.dart';
import 'package:rawdah/features/games/presentation/games_hub_screen.dart';
import 'package:rawdah/features/garden/presentation/garden_screen.dart';
import 'package:rawdah/features/journeys/presentation/journeys_screen.dart';
import 'package:rawdah/features/parents/presentation/parent_dashboard_screen.dart';
import 'package:rawdah/features/ramadan/presentation/ramadan_screen.dart';
import 'package:rawdah/features/home/presentation/home_screen.dart';
import 'package:rawdah/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';
import 'package:rawdah/features/school/presentation/school_screen.dart';
import 'package:rawdah/features/stories/presentation/stories_screen.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final l = FontLoader(name);
    for (final a in assets) {
      l.addFont(rootBundle.load(a));
    }
    await l.load();
  }

  await family('Baloo', ['assets/fonts/Baloo-500.ttf', 'assets/fonts/Baloo-700.ttf', 'assets/fonts/Baloo-800.ttf']);
  await family('Rubik', ['assets/fonts/Rubik.ttf']);
  await family('AmiriQuran', ['assets/fonts/AmiriQuran.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await l.load();
  }
}

Future<AppState> _state({bool withKids = true}) async {
  SharedPreferences.setMockInitialValues({});
  final st = AppState(parental: MemoryParentalStore(), local: MemoryLocalStore());
  await st.load();
  if (withKids) {
    st.giveConsent();
    final a = st.addChild('سارة', 'moon', 1);
    a.stars = 137;
    st.addChild('عبدالله', 'star', 2).stars = 64;
    st.addChild('يوسف', 'tree', 0).stars = 12;
    st.enterChild(a.id);
    st.pauseClock();
  }
  return st;
}

/// تلاوة وهمية في اللقطات: لا شبكة ولا صوت، والآية تبقى «قيد التلاوة» لنرى التظليل.
List<Override> _recitation() => [
      ayahCacheProvider.overrideWithValue(FakeCache()),
      ayahPlayerFactoryProvider.overrideWithValue(() => FakePlayer(auto: false)),
    ];

Future<void> _shot(WidgetTester tester, String name, AppState st, Widget home,
    {double height = 915, Future<void> Function()? act}) async {
  tester.view.physicalSize = Size(412 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [appStateProvider.overrideWithValue(st), ..._recitation()],
    child: AppScope(
    state: st,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: rawdahTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => A11yScope(
        appTextScale: st.textScale,
        highContrast: st.highContrast,
        reduceMotion: st.reduceMotion,
        child: child!,
      ),
      home: home,
    ),
  )));
  await tester.pump(const Duration(milliseconds: 300));
  if (act != null) await act();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('../shots_out/$name.png'));
  st.pauseClock();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    Voice.instance.enabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => null);
    await _loadFonts();
  });

  testWidgets('01 الترحيب', (t) async {
    final st = await _state(withKids: false);
    await _shot(t, '01_onboarding', st, const OnboardingScreen());
  });

  testWidgets('02 اختيار الطفل', (t) async {
    final st = await _state();
    st.leaveChild();
    await _shot(t, '02_picker', st, const ChildPickerScreen());
  });

  testWidgets('03 الرئيسية', (t) async {
    final st = await _state();
    await _shot(t, '03_home', st, const HomeMapScreen(), height: 1900);
  });

  testWidgets('04 مسابقة', (t) async {
    final st = await _state();
    final qs = questionsFor(1).take(5).toList();
    await _shot(t, '04_quiz', st, QuizRunner(title: 'تحدي اليوم', questions: qs));
  });

  testWidgets('05 مسابقة بعد الإجابة', (t) async {
    final st = await _state();
    final qs = questionsFor(1).take(5).toList();
    final wrong = (qs.first.answer + 1) % qs.first.options.length;
    await _shot(t, '05_quiz_answered', st, QuizRunner(title: 'تحدي اليوم', questions: qs), act: () async {
      await t.tap(find.text(qs.first.options[wrong]));
    });
  });

  testWidgets('06 الألعاب', (t) async {
    final st = await _state();
    await _shot(t, '06_games', st, const GamesHubScreen(), height: 1500);
  });

  testWidgets('07 القصص', (t) async {
    final st = await _state();
    await _shot(t, '07_stories', st, const StoriesScreen(), height: 1400);
  });

  testWidgets('08 المدرسة', (t) async {
    final st = await _state();
    await _shot(t, '08_school', st, const SchoolScreen(), height: 1400);
  });

  testWidgets('09 الجائزة', (t) async {
    final st = await _state();
    await _shot(t, '09_reward', st, Builder(builder: (context) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: () => showReward(context, stars: 8, title: 'أحسنت!'), child: const Text('x')),
        ),
      );
    }), act: () async {
      await t.tap(find.text('x'));
      await t.pump(const Duration(milliseconds: 500));
    });
  });

  for (final scene in ['desert', 'night', 'garden', 'city']) {
    testWidgets('10 قصة $scene', (t) async {
      final st = await _state();
      final story = kStories.firstWhere((x) => x.scene == scene, orElse: () => kStories.first);
      await _shot(t, '10_story_$scene', st, StoryReader(story: story));
    });
  }

  testWidgets('11 الرحلات', (t) async {
    final st = await _state();
    await _shot(t, '11_journeys', st, const JourneysScreen(), height: 1300);
  });

  testWidgets('12 خريطة رحلة', (t) async {
    final st = await _state();
    await _shot(t, '12_journey_map', st, JourneyMap(journey: kJourneys.first), height: 1500);
  });

  testWidgets('13 حديقتي', (t) async {
    final st = await _state();
    await _shot(t, '13_garden', st, const GardenScreen(), height: 1500);
  });

  testWidgets('14 المنافسة', (t) async {
    final st = await _state();
    await _shot(t, '14_competition', st, const CompetitionScreen());
  });

  testWidgets('15 رمضان', (t) async {
    final st = await _state();
    await _shot(t, '15_ramadan', st, const RamadanScreen(), height: 1300);
  });

  testWidgets('16 لوحة الوالدين', (t) async {
    final st = await _state();
    st.leaveChild();
    await _shot(t, '16_parents', st, const ParentDashboard(), height: 1800);
  });

  testWidgets('17 الرئيسية بتباين عالٍ', (t) async {
    final st = await _state();
    st.setAccessibility(highContrast: true);
    st.pauseClock();
    await _shot(t, '17_home_high_contrast', st, const HomeMapScreen(), height: 1900);
  });

  testWidgets('18 الرئيسية بخط أكبر', (t) async {
    final st = await _state();
    st.setAccessibility(textScale: 1.3);
    st.pauseClock();
    await _shot(t, '18_home_large_text', st, const HomeMapScreen(), height: 2300);
  });

  testWidgets('19 المسابقة بخط أكبر', (t) async {
    final st = await _state();
    st.setAccessibility(textScale: 1.3);
    st.pauseClock();
    await _shot(t, '19_quiz_large_text', st, QuizRunner(title: 'تحدي اليوم', questions: questionsFor(1).take(5).toList()));
  });

  testWidgets('20 السورة مع التلاوة', (t) async {
    final st = await _state();
    await _shot(t, '20_surah', st, SurahScreen(surah: kSurahs.firstWhere((x) => x.number == 105)), height: 1500);
  });

  testWidgets('21 أثناء التلاوة', (t) async {
    final st = await _state();
    final surah = kSurahs.firstWhere((x) => x.number == 105);
    await _shot(t, '21_surah_playing', st, SurahScreen(surah: surah), height: 1500, act: () async {
      final box = ProviderScope.containerOf(t.element(find.byType(SurahScreen)));
      final args = (surah: 105, ayahCount: surah.ayat.length);
      final c = box.read(recitationControllerProvider(args).notifier);
      await c.setOptions(repeatEach: 3, echo: true);
      unawaited(c.playFrom(2));
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  testWidgets('22 مراجعة اليوم', (t) async {
    final st = await _state();
    final past = DateTime.now().subtract(const Duration(days: 3));
    st.markMemorized(112, now: past);
    st.markMemorized(108, now: past);
    st.markMemorized(1, now: DateTime.now());
    await _shot(t, '22_school_review', st, const SchoolScreen(), height: 1100);
  });

  // فحوص إرشادات الوصول المضمّنة في Flutter: حجم أهداف اللمس، وجود وصف لكل زر، وتباين النص.
  for (final entry in <String, Widget Function()>{
    'الرئيسية': () => const HomeMapScreen(),
    'المسابقة': () => QuizRunner(title: 'تحدي', questions: questionsFor(1).take(3).toList()),
    'المسابقات': () => const QuizHubScreen(),
    'السورة': () => SurahScreen(surah: kSurahs.firstWhere((x) => x.number == 105)),
  }.entries) {
    testWidgets('إرشادات الوصول: ${entry.key}', (t) async {
      final st = await _state();
      t.view.physicalSize = const Size(412 * 2, 1900 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final handle = t.ensureSemantics();
      await t.pumpWidget(ProviderScope(
        overrides: [appStateProvider.overrideWithValue(st), ..._recitation()],
        child: AppScope(
          state: st,
          child: MaterialApp(
            theme: rawdahTheme(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: entry.value(),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      handle.dispose();
      st.pauseClock();
      await t.pumpWidget(const SizedBox());
    });
  }
}
