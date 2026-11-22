import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/online.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'quizzes.dart';

/// تحدي صديق: الطفلان يجيبان عن نفس الأسئلة الخمسة كلٌّ في وقته.
/// لا محادثة ولا رسائل؛ الرمز يتبادله الوالدان خارج التطبيق.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _code = TextEditingController();
  String? _msg;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final st = AppScope.read(context);
    final c = st.current!;
    final qs = questionsFor(c.ageBand)..shuffle();
    final picked = qs.take(5).toList();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizRunner(
        title: 'تحدي صديق',
        questions: picked,
        onFinish: (right) async {
          final code = await Online.instance.createChallenge(c, picked.map((q) => q.id).toList(), right);
          if (code != null) {
            st.addChallenge(code);
            if (mounted) setState(() => _msg = 'رمز تحديك: $code\nأعطه لوالديك ليرسلوه لوالدي صديقك.');
            Voice.instance.say('أجبت $right من خمسة. أعط الرمز لوالديك');
          } else if (mounted) {
            setState(() => _msg = 'تعذّر إنشاء التحدي، تأكد من الإنترنت');
          }
        },
      ),
    ));
  }

  Future<void> _join() async {
    final st = AppScope.read(context);
    final c = st.current!;
    final code = _code.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _msg = 'الرمز 6 خانات');
      return;
    }
    setState(() => _busy = true);
    final d = await Online.instance.getChallenge(code);
    setState(() => _busy = false);
    if (d == null) {
      setState(() => _msg = 'لم نجد تحديًا بهذا الرمز');
      return;
    }
    if (d['bScore'] != null) {
      setState(() => _msg = 'هذا التحدي أُجيب عنه من قبل');
      return;
    }
    final qs = ((d['qids'] as List?) ?? const []).map((e) => questionById(e.toString())).whereType<Question>().toList();
    if (qs.isEmpty) {
      setState(() => _msg = 'أسئلة هذا التحدي غير متوفرة في نسختك، حدّث التطبيق');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizRunner(
        title: 'تحدي ${d['aNick'] ?? ''}',
        questions: qs,
        onFinish: (right) async {
          final ok = await Online.instance.answerChallenge(code, c, right);
          if (ok) {
            st.addChallenge(code);
            final a = (d['aScore'] as num?)?.toInt() ?? 0;
            final res = right > a ? 'فزت!' : (right == a ? 'تعادل جميل' : 'أحسنت، حاول مرة أخرى');
            if (mounted) setState(() => _msg = '$res\nأنت: $right   ${d['aNick']}: $a');
            Voice.instance.say(res);
          } else if (mounted) {
            setState(() => _msg = 'تعذّر حفظ النتيجة');
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'تحدي صديق'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (!c.onlineEnabled)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('اطلب من والديك تفعيل المنافسة أولًا.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
              )
            else ...[
              BigTile(
                title: 'أنشئ تحديًا',
                subtitle: 'أجب عن 5 أسئلة، ثم شارك الرمز',
                icon: Icons.add_circle_rounded,
                color: RC.coral,
                onTap: _create,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('عندك رمز من صديق؟', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _code,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 26, letterSpacing: 6, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(hintText: 'ABC123', border: OutlineInputBorder()),
                  ),
                  _busy
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(label: 'ابدأ التحدي', icon: Icons.play_arrow_rounded, onTap: _join),
                ]),
              ),
              if (_msg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: RC.gold.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                  child: SelectableText(_msg!,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 20),
              if (c.myChallenges.isNotEmpty)
                const Text('تحدياتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              for (final code in c.myChallenges) _ChallengeRow(code: code),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final String code;
  const _ChallengeRow({required this.code});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Online.instance.getChallenge(code),
      builder: (context, snap) {
        final d = snap.data;
        final text = d == null
            ? '...'
            : d['bScore'] == null
                ? '${d['aNick']}: ${d['aScore']}  ·  بانتظار الصديق'
                : '${d['aNick']}: ${d['aScore']}  ·  ${d['bNick']}: ${d['bScore']}';
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ]),
        );
      },
    );
  }
}
