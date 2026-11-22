import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/quran_text.dart';
import '../ui/widgets.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    final list = kStories.where((s) => s.minBand <= c.ageBand).toList();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'بيت القصص'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = list[i];
              return BigTile(
                title: s.title,
                subtitle: s.moral,
                icon: switch (s.scene) {
                  'night' => Icons.nightlight_round,
                  'desert' => Icons.wb_sunny_rounded,
                  'city' => Icons.mosque_rounded,
                  _ => Icons.local_florist_rounded,
                },
                color: switch (s.scene) {
                  'night' => RC.ink,
                  'desert' => RC.goldDark,
                  'city' => RC.sea,
                  _ => RC.green,
                },
                done: c.completed.contains(s.id),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryReader(story: s))),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class StoryReader extends StatefulWidget {
  final Story story;
  const StoryReader({super.key, required this.story});

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  final _pc = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read(0));
  }

  @override
  void dispose() {
    Voice.instance.stop();
    _pc.dispose();
    super.dispose();
  }

  void _read(int i) {
    final p = widget.story.pages[i];
    // الآيات لا تُقرأ بالصوت الآلي، نقرأ التمهيد فقط.
    Voice.instance.say(p.text);
  }

  Future<void> _finish() async {
    final st = AppScope.read(context);
    final first = st.complete(widget.story.id, stars: 3);
    if (first) await showReward(context, stars: 3, title: 'انتهت القصة');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final last = _page == s.pages.length - 1;
    return ChildShell(
      night: s.scene == 'night',
      child: Column(children: [
        KidBar(title: s.title),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: s.pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _read(i);
            },
            itemBuilder: (context, i) {
              final p = s.pages[i];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: s.scene == 'night' ? RC.gold : RC.sandDark, width: 3),
                    ),
                    child: Text(p.text,
                        textAlign: TextAlign.center,
                        style: RT.display(25, weight: FontWeight.w500).copyWith(height: 1.75)),
                  ),
                  if (p.passage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Builder(builder: (_) {
                      final r = resolvePassage(p.passage);
                      return QuranText(ayat: r.ayat, firstNumber: r.from);
                    }),
                    const SizedBox(height: 6),
                    Text(p.ayatRef, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                  ],
                  if (i == s.pages.length - 1) ...[
                    const SizedBox(height: 14),
                    Text('المصدر: ${s.source}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(children: [
            RoundIcon(icon: Icons.volume_up_rounded, color: RC.sea, onTap: () => _read(_page)),
            const SizedBox(width: 12),
            // نقاط الصفحات: نجمة لكل صفحة، تمتلئ حتى الصفحة الحالية
            Expanded(
              child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                for (var k = 0; k < s.pages.length; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: k == _page ? 22 : 14,
                    height: k == _page ? 22 : 14,
                    decoration: ShapeDecoration(
                      color: k <= _page ? RC.gold : (s.scene == 'night' ? Colors.white24 : RC.sandDark),
                      shape: const KhatamBorder(),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            last
                ? RoundIcon(icon: Icons.check_rounded, color: RC.green, onTap: _finish)
                : RoundIcon(
                    icon: Icons.arrow_forward_rounded,
                    color: RC.green,
                    onTap: () => _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                  ),
          ]),
        ),
      ]),
    );
  }
}
