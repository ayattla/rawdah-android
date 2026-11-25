import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/learn/data/reading.dart';
import 'package:rawdah/features/quizzes/presentation/quizzes_screen.dart';

const _ink = Color(0xFF1F2A44);
const _paper = Color(0xFFFFFBF0);
const _gold = Color(0xFFC98A12);

/// أقرأ وأفهم: قائمة النصوص حسب المستوى.
class ReadingListScreen extends StatelessWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    final list = passagesForBand(c.ageBand);
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'أقرأ وأفهم'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final p in list) ...[
              BigTile(
                title: p.title,
                subtitle: '${p.sentences.length} جمل • المستوى ${p.level}',
                icon: Icons.chrome_reader_mode_rounded,
                color: const [Color(0xFF3D5A80), Color(0xFF2E6B4F), Color(0xFF8A5A12)][p.level - 1],
                done: c.completed.contains(p.completionId),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReadingScreen(passage: p))),
              ),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// النص على ورقة: كل كلمة تلمس فتسمع وتتلون، وكل جملة لها زر استماع.
class ReadingScreen extends StatefulWidget {
  final ReadingPassage passage;
  const ReadingScreen({super.key, required this.passage});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  String? _lit;
  final Set<int> _heard = {};

  void _word(String key, String w) {
    setState(() => _lit = key);
    Voice.instance.say(w.replaceAll(RegExp(r'[.,،:؟!]'), ''));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passage;
    return ChildShell(
      child: Column(children: [
        KidBar(title: p.title),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Text('المس أي كلمة لتسمعها', textAlign: TextAlign.center, style: RT.body(15, color: RC.inkSoft)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: RC.sandDark, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var s = 0; s < p.sentences.length; s++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      IconButton(
                        tooltip: 'اسمع الجملة',
                        onPressed: () {
                          setState(() => _heard.add(s));
                          Voice.instance.say(p.sentences[s]);
                        },
                        icon: Icon(_heard.contains(s) ? Icons.check_circle_rounded : Icons.volume_up_rounded,
                            color: _heard.contains(s) ? const Color(0xFF2E6B4F) : RC.inkSoft),
                      ),
                      Expanded(
                        child: Wrap(spacing: 8, runSpacing: 4, children: [
                          for (final (wi, w) in p.sentences[s].split(' ').indexed)
                            GestureDetector(
                              onTap: () => _word('$s-$wi', w),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _lit == '$s-$wi' ? const Color(0x33C98A12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(w,
                                    style: TextStyle(
                                      fontFamily: 'Baloo',
                                      fontSize: p.level == 1 ? 34 : (p.level == 2 ? 28 : 24),
                                      height: 1.6,
                                      fontWeight: FontWeight.w700,
                                      color: _lit == '$s-$wi' ? _gold : _ink,
                                    )),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => Voice.instance.say(p.sentences.join(' ')),
              icon: const Icon(Icons.record_voice_over_rounded),
              label: const Text('اسمع النص كله'),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'أجب عن الأسئلة',
              icon: Icons.quiz_rounded,
              onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => QuizRunner(title: 'أسئلة: ${p.title}', questions: p.questions, completionId: p.completionId),
              )),
            ),
          ]),
        ),
      ]),
    );
  }
}
