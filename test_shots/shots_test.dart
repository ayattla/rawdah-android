// لقطات الشاشات: ترسم شاشات روضة الحقيقية صورًا PNG للمراجعة البصرية.
// تعمل في GitHub Actions فقط: flutter test test_shots --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rawdah/data/content.dart';
import 'package:rawdah/screens/child_picker.dart';
import 'package:rawdah/screens/games_hub.dart';
import 'package:rawdah/screens/home_map.dart';
import 'package:rawdah/screens/onboarding.dart';
import 'package:rawdah/screens/quizzes.dart';
import 'package:rawdah/screens/school.dart';
import 'package:rawdah/screens/stories.dart';
import 'package:rawdah/services/voice.dart';
import 'package:rawdah/state/app_state.dart';
import 'package:rawdah/ui/widgets.dart';

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
  final st = AppState();
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

Future<void> _shot(WidgetTester tester, String name, AppState st, Widget home,
    {double height = 915, Future<void> Function()? act}) async {
  tester.view.physicalSize = Size(412 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
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
      home: home,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  if (act != null) await act();
  await tester.pump(const Duration(milliseconds: 900));
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
}
