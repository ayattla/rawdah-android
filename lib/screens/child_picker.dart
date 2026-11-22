import 'package:flutter/material.dart';

import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'home_map.dart';
import 'parent_dashboard.dart';
import 'parent_gate.dart';

class ChildPickerScreen extends StatelessWidget {
  const ChildPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Scaffold(
      body: SceneBackground(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              const Expanded(
                child: Text('من سيلعب الآن؟',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.greenDark)),
              ),
              RoundIcon(
                icon: Icons.lock_rounded,
                color: RC.night,
                size: 48,
                onTap: () async {
                  if (await passParentGate(context) && context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentDashboard()));
                  }
                },
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(18),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                for (final c in st.children)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        st.enterChild(c.id);
                        Voice.instance.say('أهلًا ${c.name}');
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeMapScreen()));
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(symbolIcon(c.symbol), size: 72, color: RC.gold),
                        const SizedBox(height: 8),
                        Text(c.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RC.ink)),
                        Text('${c.stars} نجمة', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
