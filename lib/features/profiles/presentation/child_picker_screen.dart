import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/features/home/presentation/home_screen.dart';
import 'package:rawdah/features/parents/presentation/parent_dashboard_screen.dart';
import 'package:rawdah/features/parents/presentation/parent_gate.dart';

class ChildPickerScreen extends StatelessWidget {
  const ChildPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    const colors = [RC.green, RC.plum, RC.sea, RC.coral, RC.goldDark, RC.ink];
    return Scaffold(
      body: SceneBackground(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SvgPicture.asset('assets/brand/rawdah_mark.svg', width: 70, height: 70, excludeFromSemantics: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('روضة', style: RT.display(36, color: RC.green)),
                    Text('من سيتعلم اليوم؟', style: RT.display(22, weight: FontWeight.w700)),
                  ]),
                ),
                RoundIcon(
                  icon: Icons.lock_rounded,
                  color: RC.ink,
                  size: 48,
                  tooltip: 'لوحة الوالدين',
                  onTap: () async {
                    if (await passParentGate(context) && context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentDashboard()));
                    }
                  },
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: st.children.length,
                (context, i) {
                  final c = st.children[i];
                  final color = colors[i % colors.length];
                  return Chunky(
                    color: color,
                    radius: 28,
                    depth: 7,
                    semanticLabel: c.name,
                    onTap: () {
                      st.enterChild(c.id);
                      Voice.instance.say('أهلًا ${c.name}');
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeMapScreen()));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: CustomPaint(
                        painter: ZellijPainter(color: Colors.white.withValues(alpha: 0.13), cell: 40),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            KhatamBadge(icon: symbolIcon(c.symbol), color: Colors.white, size: 86, iconColor: color),
                            const SizedBox(height: 10),
                            Text(c.name,
                                style: RT.display(24, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, color: RC.gold, size: 20),
                              Text(' ${c.stars}  ·  مستوى ${c.level}',
                                  style: RT.body(15, color: Colors.white, weight: FontWeight.w500)),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
