import 'package:flutter/material.dart';

import '../data/content.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'add_child.dart';
import 'garden.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text('لوحة الوالدين'), backgroundColor: RC.night, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final c in st.children) _ChildCard(child: c),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة طفل', style: TextStyle(fontSize: 18)),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(child: AddChildForm(onDone: () => Navigator.of(ctx).pop())),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Panel(title: 'الإعدادات', children: [
          SwitchListTile(
            value: st.voiceOn,
            onChanged: st.setVoice,
            title: const Text('الراوي الصوتي'),
            subtitle: const Text('يقرأ التعليمات والقصص بصوت الجهاز. لا يقرأ آيات القرآن.'),
          ),
        ]),
        _Panel(title: 'الخصوصية', children: const [
          ListTile(
            leading: Icon(Icons.wifi_off_rounded),
            title: Text('التطبيق لا يتصل بالإنترنت'),
            subtitle: Text('كل البيانات محفوظة على هذا الجهاز فقط، ولا توجد إعلانات ولا أدوات تتبّع.'),
          ),
          ListTile(
            leading: Icon(Icons.landscape_rounded),
            title: Text('خالٍ من ذوات الأرواح والموسيقى'),
            subtitle: Text('الرسوم نباتات وجمادات وأجرام فقط، والأصوات صوت بشري ومؤثرات طبيعية.'),
          ),
          ListTile(
            leading: Icon(Icons.fact_check_rounded),
            title: Text('حالة المحتوى'),
            subtitle: Text('$kContentStatus. الآيات من نص مصحف المدينة برواية حفص، والأحاديث مخرّجة من الصحيحين والسنن.'),
          ),
        ]),
      ]),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Panel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...children,
          ]),
        ),
      );
}

class _ChildCard extends StatelessWidget {
  final ChildProfile child;
  const _ChildCard({required this.child});

  String _habitTitle(String id) {
    for (final h in kHabits) {
      if (h.id == id) return h.title;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = child;
    final minutes = c.todaySeconds ~/ 60;
    final stories = c.completed.where((e) => e.startsWith('story_')).length;
    final surahs = c.completed.where((e) => e.startsWith('surah_')).length;
    final lessons = c.completed.where((e) => e.startsWith('lesson_')).length;
    final accuracy = c.quizTotal == 0 ? '—' : '${(c.quizCorrect * 100 / c.quizTotal).round()}%';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(symbolIcon(c.symbol), color: RC.gold, size: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(kAgeBandNames[c.ageBand], style: const TextStyle(color: Colors.black54)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('حذف بيانات الطفل'),
                      content: Text('سيُحذف ملف ${c.name} وكل تقدّمه من هذا الجهاز نهائيًا.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف')),
                      ],
                    ),
                  );
                  if (ok == true) st.removeChild(c.id);
                } else if (v.startsWith('band')) {
                  c.ageBand = int.parse(v.substring(4));
                  st.updateChild(c);
                }
              },
              itemBuilder: (_) => [
                for (var b = 0; b < kAgeBandNames.length; b++)
                  PopupMenuItem(value: 'band$b', child: Text('الفئة: ${kAgeBandNames[b]}')),
                const PopupMenuItem(value: 'delete', child: Text('حذف الطفل وبياناته')),
              ],
            ),
          ]),
          const Divider(height: 24),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _Stat('النجوم', '${c.stars}'),
            _Stat('اليوم', '$minutes د'),
            _Stat('أيام متتالية', '${c.streak}'),
            _Stat('قصص', '$stories'),
            _Stat('سور', '$surahs'),
            _Stat('دروس', '$lessons'),
            _Stat('دقة الإجابات', accuracy),
            _Stat('عادات معتمدة', '${c.approvedHabits}'),
            _Stat('مرحلة النخلة', '${palmStage(c.stars) + 1} من 6'),
          ]),
          const SizedBox(height: 14),
          const Text('الحد اليومي للاستخدام', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (final m in const [15, 30, 45, 60, 0])
              ChoiceChip(
                label: Text(m == 0 ? 'بلا حد' : '$m دقيقة'),
                selected: c.dailyLimitMinutes == m,
                onSelected: (_) {
                  c.dailyLimitMinutes = m;
                  st.updateChild(c);
                },
              ),
          ]),
          if (c.pendingHabits.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('عادات بانتظار اعتمادك', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final p in List.of(c.pendingHabits))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.eco_rounded, color: RC.green),
                title: Text(_habitTitle(p.habitId)),
                subtitle: Text(p.day),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'اعتماد',
                    icon: const Icon(Icons.check_circle_rounded, color: RC.green),
                    onPressed: () => st.approveHabit(c, p, true),
                  ),
                  IconButton(
                    tooltip: 'رفض',
                    icon: const Icon(Icons.cancel_rounded, color: RC.coral),
                    onPressed: () => st.approveHabit(c, p, false),
                  ),
                ]),
              ),
          ],
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF1F4EF), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.greenDark)),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ]),
      );
}
