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
    final c = st.current!;
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
                icon: Icons.auto_stories_rounded,
                color: RC.coral,
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
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(p.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 25, height: 1.7, color: RC.ink, fontWeight: FontWeight.w500)),
                  ),
                  if (p.ayat.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    QuranText(ayat: resolveAyat(p.ayat), firstNumber: s.id == 'story_naml' ? 18 : 1),
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
            Expanded(
              child: Text('${_page + 1} / ${s.pages.length}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: RC.ink)),
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
