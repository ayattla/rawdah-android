import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

/// ترتيب أطفال البيت حسب نقاط الشهر، من الأعلى.
List<(ChildProfile, int)> familyRanking(List<ChildProfile> kids, String month) =>
    [for (final k in kids) (k, k.counters['mp_$month'] ?? 0)]..sort((a, b) => b.$2.compareTo(a.$2));

const _monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

/// دوري العائلة الشهري: أطفال البيت فقط على نفس الجهاز، بلا أي تواصل خارجي.
class FamilyLeagueScreen extends StatelessWidget {
  const FamilyLeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final now = DateTime.now();
    final rank = familyRanking(st.children, monthKey(now));
    const outline = Color(0xFF2A1A66);
    const medals = [Color(0xFFFFC23F), Color(0xFFCBD5E1), Color(0xFFF59E0B)];
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'دوري العائلة'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFF5D8F), width: 3)),
              child: Column(children: [
                Text('بطولة شهر ${_monthNames[now.month - 1]}', style: RT.display(21, color: Colors.white)),
                Text('كل إجابة صحيحة نقطة، وكل لغز نقطتان، وكل نشاط أو مراجعة ٣ نقاط', textAlign: TextAlign.center, style: RT.body(13.5, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            if (rank.length < 2)
              Text('أضف إخوتك من شاشة الأطفال لتتنافسوا في البيت، وتقدر تتنافس مع نفسك وتكسر رقمك كل شهر',
                  textAlign: TextAlign.center, style: RT.body(16, color: RC.inkSoft)),
            for (var i = 0; i < rank.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rank[i].$1.id == st.current?.id ? const Color(0xFFFFF7E0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: outline, width: 3),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < 3 ? medals[i] : RC.sand,
                        shape: BoxShape.circle,
                        border: Border.all(color: outline, width: 2.5),
                      ),
                      child: Text('${i + 1}', style: RT.display(18, color: outline)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rank[i].$1.name, style: RT.display(19, color: RC.onDark))),
                    Text('${rank[i].$2} نقطة', style: RT.display(17, color: const Color(0xFF8B5CF6))),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
