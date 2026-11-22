import 'package:flutter/material.dart';

import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'family_quiz.dart';
import 'games_hub.dart';
import 'garden.dart';
import 'quizzes.dart';
import 'school.dart';
import 'stories.dart';

class _Place {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _Place(this.title, this.hint, this.icon, this.color, this.builder);
}

class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  static final List<_Place> _places = [
    _Place('بيت القصص', 'قصص نسمعها ونتعلم منها', Icons.auto_stories_rounded, RC.coral, (_) => const StoriesScreen()),
    _Place('المدرسة', 'قرآن وأذكار ودروس', Icons.school_rounded, RC.sea, (_) => const SchoolScreen()),
    _Place('ساحة الألعاب', 'نلعب ونتعلم', Icons.extension_rounded, RC.plum, (_) => const GamesHubScreen()),
    _Place('المسابقات', 'أجب واجمع النجوم', Icons.emoji_events_rounded, RC.gold, (_) => const QuizHubScreen()),
    _Place('حديقتي', 'نخلتي وعادات الخير', Icons.park_rounded, RC.green, (_) => const GardenScreen()),
    _Place('مجلس العائلة', 'مسابقة مع أهلي', Icons.chair_rounded, RC.greenDark, (_) => const FamilyQuizScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const Scaffold(body: SizedBox());
    final glow = (c.streak / 7).clamp(0.2, 1.0).toDouble();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) st.leaveChild();
      },
      child: ChildShell(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              RoundIcon(
                icon: Icons.swap_horiz_rounded,
                color: RC.plum,
                size: 48,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
              Icon(symbolIcon(c.symbol), color: RC.gold, size: 34),
              const SizedBox(width: 6),
              Expanded(
                child: Text('أهلًا ${c.name}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink),
                    overflow: TextOverflow.ellipsis),
              ),
              StarCount(stars: c.stars),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Lantern(size: 76, glow: glow),
              const SizedBox(width: 10),
              Text(c.streak > 1 ? 'فانوسك يضيء ${c.streak} أيام متتالية' : 'تعال كل يوم ليزداد فانوسك نورًا',
                  style: const TextStyle(fontSize: 16, color: RC.ink)),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemCount: _places.length,
              itemBuilder: (context, i) {
                final p = _places[i];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  elevation: 4,
                  shadowColor: p.color.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Voice.instance.say(p.title);
                      Navigator.of(context).push(MaterialPageRoute(builder: p.builder));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(color: p.color.withValues(alpha: 0.16), shape: BoxShape.circle),
                          child: Icon(p.icon, color: p.color, size: 50),
                        ),
                        const SizedBox(height: 10),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: RC.ink)),
                        Text(p.hint,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: RC.ink.withValues(alpha: 0.6))),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
