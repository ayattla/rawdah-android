import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rawdah/features/profiles/presentation/child_picker_screen.dart';
import 'package:rawdah/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = AppState();
  state.onPoints = () => Online.instance.scheduleFlush(state);
  state.load().then((_) {
    if (state.children.any((c) => c.onlineEnabled)) Online.instance.scheduleFlush(state);
  });
  runApp(ProviderScope(
    overrides: [appStateProvider.overrideWithValue(state)],
    child: RawdahApp(state: state),
  ));
}

class RawdahApp extends StatefulWidget {
  final AppState state;
  const RawdahApp({super.key, required this.state});

  @override
  State<RawdahApp> createState() => _RawdahAppState();
}

class _RawdahAppState extends State<RawdahApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      widget.state.resumeClock();
    } else {
      widget.state.pauseClock();
      Voice.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'روضة',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: rawdahTheme(),
        // في معاينة الويب نعرض التطبيق بعرض هاتف.
        builder: kIsWeb
            ? (context, child) => ColoredBox(
                  color: RC.ink,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 412),
                      child: ClipRect(
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            size: Size(
                              MediaQuery.of(context).size.width.clamp(0.0, 412.0).toDouble(),
                              MediaQuery.of(context).size.height,
                            ),
                          ),
                          child: child ?? const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                )
            : null,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    Voice.instance.enabled = st.voiceOn;
    if (!st.loaded) {
      return const Scaffold(body: SceneBackground(child: Center(child: Lantern(size: 120, glow: 0.8))));
    }
    if (!st.consentGiven || st.children.isEmpty) return const OnboardingScreen();
    return const ChildPickerScreen();
  }
}
