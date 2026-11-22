import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../services/online.dart';
import '../services/voice.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';

const _bandNames = ['4 إلى 6', '7 إلى 9', '10 إلى 12'];

// =================================================================== شاشة المعلم

/// المسابقة المباشرة للمعلم: ينشئ غرفة، يعطي الرمز، ويعرض الأسئلة واحدًا واحدًا.
/// الأطفال يجيبون من أجهزتهم، ويظهر ترتيبهم بالألقاب فقط، بلا أي تواصل.
class LiveHostScreen extends StatefulWidget {
  const LiveHostScreen({super.key});

  @override
  State<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends State<LiveHostScreen> {
  int _band = 1;
  int _count = 10;
  String? _code;
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final pool = kQuestions.where((q) => q.band == _band).toList()..shuffle();
    final qids = pool.take(_count).map((q) => q.id).toList();
    final code = await Online.instance.createRoom(_band, qids);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _code = code;
      if (code == null) _error = 'تعذّر إنشاء المسابقة، تأكد من الإنترنت';
    });
  }

  Future<void> _close() async {
    final code = _code;
    if (code != null) await Online.instance.deleteRoom(code);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return Scaffold(
      appBar: AppBar(title: const Text('مسابقة مباشرة')),
      backgroundColor: RC.sand,
      body: code == null ? _setup() : _HostRoom(code: code, onClose: _close),
    );
  }

  Widget _setup() => ListView(padding: const EdgeInsets.all(18), children: [
        const Text(
          'أنشئ مسابقة وأعطِ رمزها للطلاب. يدخل كل طفل الرمز من «ميدان المنافسة» في جهازه، '
          'وتعرض أنت الأسئلة واحدًا بعد الآخر، ويجيبون جميعًا في الوقت نفسه.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 18),
        const Text('الفئة العمرية', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          segments: [for (var b = 0; b < 3; b++) ButtonSegment(value: b, label: Text(_bandNames[b]))],
          selected: {_band},
          onSelectionChanged: (v) => setState(() => _band = v.first),
        ),
        const SizedBox(height: 16),
        const Text('عدد الأسئلة', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 5, label: Text('5')),
            ButtonSegment(value: 10, label: Text('10')),
            ButtonSegment(value: 15, label: Text('15')),
          ],
          selected: {_count},
          onSelectionChanged: (v) => setState(() => _count = v.first),
        ),
        const SizedBox(height: 22),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error!, style: const TextStyle(color: RC.coral)),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _busy ? null : _create,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
              : const Icon(Icons.play_circle_outline_rounded),
          label: const Text('أنشئ المسابقة', style: TextStyle(fontSize: 18)),
        ),
      ]);
}

class _HostRoom extends StatelessWidget {
  final String code;
  final Future<void> Function() onClose;
  const _HostRoom({required this.code, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveRoom?>(
      stream: Online.instance.roomStream(code),
      builder: (context, rs) {
        final room = rs.data;
        if (room == null) return const Center(child: CircularProgressIndicator());
        return StreamBuilder<List<LivePlayer>>(
          stream: Online.instance.roomPlayers(code),
          builder: (context, ps) {
            final players = ps.data ?? const <LivePlayer>[];
            return ListView(padding: const EdgeInsets.all(16), children: [
              _CodeCard(code: code, players: players.length),
              const SizedBox(height: 12),
              if (room.state == 'wait') ..._waiting(context, room, players),
              if (room.state == 'q') ..._question(context, room, players),
              if (room.state == 'end') ..._end(context, players),
            ]);
          },
        );
      },
    );
  }

  List<Widget> _waiting(BuildContext context, LiveRoom room, List<LivePlayer> players) => [
        Text(players.isEmpty ? 'بانتظار انضمام الطلاب...' : 'انضم ${players.length}:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in players)
            Chip(avatar: Icon(symbolIcon(p.symbol), color: RC.gold, size: 20), label: Text(p.nick)),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: players.isEmpty ? null : () => Online.instance.setRoom(code, index: 0, state: 'q'),
          child: Text('ابدأ (${room.qids.length} أسئلة)', style: const TextStyle(fontSize: 18)),
        ),
      ];

  List<Widget> _question(BuildContext context, LiveRoom room, List<LivePlayer> players) {
    final q = questionById(room.qids[room.index]);
    final answered = players.where((p) => p.answered >= room.index).length;
    final last = room.index >= room.qids.length - 1;
    return [
      Text('السؤال ${room.index + 1} من ${room.qids.length}', style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q?.text ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.5)),
          const SizedBox(height: 10),
          if (q != null)
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(k == q.answer ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: k == q.answer ? RC.green : Colors.black26, size: 20),
                  const SizedBox(width: 6),
                  Expanded(child: Text(q.options[k], style: const TextStyle(fontSize: 17))),
                ]),
              ),
        ]),
      ),
      const SizedBox(height: 10),
      LinearProgressIndicator(
        value: players.isEmpty ? 0 : answered / players.length,
        minHeight: 10,
        color: RC.green,
        backgroundColor: Colors.white,
      ),
      const SizedBox(height: 4),
      Text('أجاب $answered من ${players.length}', style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 14),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        onPressed: () => last
            ? Online.instance.setRoom(code, index: room.index, state: 'end')
            : Online.instance.setRoom(code, index: room.index + 1, state: 'q'),
        child: Text(last ? 'إنهاء وعرض النتائج' : 'السؤال التالي', style: const TextStyle(fontSize: 18)),
      ),
      const SizedBox(height: 16),
      _Ranking(players: players),
    ];
  }

  List<Widget> _end(BuildContext context, List<LivePlayer> players) => [
        const Text('النتائج النهائية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _Ranking(players: players),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: onClose,
          child: const Text('إغلاق المسابقة'),
        ),
      ];
}

class _CodeCard extends StatelessWidget {
  final String code;
  final int players;
  const _CodeCard({required this.code, required this.players});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: RC.greenDark, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('رمز المسابقة', style: TextStyle(color: Colors.white70)),
              Text(code,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 4)),
              Text('المشاركون: $players', style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          IconButton(
            tooltip: 'نسخ الرمز',
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ الرمز')));
            },
          ),
        ]),
      );
}

class _Ranking extends StatelessWidget {
  final List<LivePlayer> players;
  final String meId;
  const _Ranking({required this.players, this.meId = ''});

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < players.length && i < 30; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: players[i].id == meId ? RC.gold.withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              SizedBox(
                width: 34,
                child: i < 3
                    ? Icon(Icons.emoji_events_rounded,
                        color: [RC.gold, const Color(0xFFB0B7C3), const Color(0xFFCD8B5A)][i])
                    : Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Icon(symbolIcon(players[i].symbol), color: RC.green, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(players[i].nick, style: const TextStyle(fontSize: 17))),
              Text('${players[i].score}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RC.coral)),
            ]),
          ),
      ]);
}

// =================================================================== شاشة الطفل

class LiveJoinScreen extends StatefulWidget {
  const LiveJoinScreen({super.key});

  @override
  State<LiveJoinScreen> createState() => _LiveJoinScreenState();
}

class _LiveJoinScreenState extends State<LiveJoinScreen> {
  final _codeCtl = TextEditingController();
  String? _code;
  String? _error;
  bool _busy = false;
  int _score = 0;
  int _answered = -1;
  int? _picked;
  int _pickedFor = -1;
  bool _rewarded = false;

  @override
  void dispose() {
    _codeCtl.dispose();
    Voice.instance.stop();
    super.dispose();
  }

  Future<void> _join() async {
    final c = AppScope.read(context).current;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await Online.instance.joinRoom(c, _codeCtl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = res.$1;
      if (res.$1 == null) {
        _code = _codeCtl.text.trim().toUpperCase();
        _score = res.$2;
        _answered = res.$3;
      }
    });
  }

  Future<void> _answer(LiveRoom room, Question q, int k) async {
    if (_picked != null && _pickedFor == room.index) return;
    final c = AppScope.read(context).current;
    if (c == null) return;
    final ok = k == q.answer;
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _picked = k;
      _pickedFor = room.index;
    });
    final newScore = _score + (ok ? 1 : 0);
    final sent = await Online.instance.answerRoom(_code!, c, room.index, newScore);
    if (!mounted) return;
    setState(() {
      if (sent) {
        _score = newScore;
        _answered = room.index;
      } else {
        _picked = null;
        _pickedFor = -1;
      }
    });
  }

  void _reward() {
    if (_rewarded) return;
    _rewarded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).recordLiveScore(_score);
      showReward(context, stars: _score * 2, title: '$_score إجابة صحيحة');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'مسابقة مباشرة'),
        Expanded(child: _code == null ? _entry() : _room(c)),
      ]),
    );
  }

  Widget _entry() => ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.groups_rounded, size: 80, color: RC.sea),
        const SizedBox(height: 10),
        const Text('اكتب رمز المسابقة الذي أعطاك إياه المعلم',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: RC.ink)),
        const SizedBox(height: 16),
        TextField(
          controller: _codeCtl,
          maxLength: 6,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 30, letterSpacing: 6, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            errorText: _error,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 10),
        _busy
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(label: 'دخول', onTap: _join),
      ]);

  Widget _room(ChildProfile c) {
    final code = _code!;
    final meId = Online.instance.playerId(c);
    return StreamBuilder<LiveRoom?>(
      stream: Online.instance.roomStream(code),
      builder: (context, rs) {
        if (rs.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final room = rs.data;
        if (room == null) {
          return _message(Icons.door_front_door_outlined, 'أُغلقت المسابقة', 'شكرًا لمشاركتك');
        }
        if (room.state == 'wait') {
          return _message(Icons.hourglass_top_rounded, 'أنت داخل المسابقة', 'انتظر حتى يبدأ المعلم...');
        }
        if (room.state == 'end') {
          _reward();
          return StreamBuilder<List<LivePlayer>>(
            stream: Online.instance.roomPlayers(code),
            builder: (context, ps) {
              final players = ps.data ?? const <LivePlayer>[];
              final rank = players.indexWhere((p) => p.id == meId) + 1;
              return ListView(padding: const EdgeInsets.all(16), children: [
                const Icon(Icons.emoji_events_rounded, size: 80, color: RC.gold),
                Text(rank > 0 ? 'ترتيبك $rank من ${players.length}' : 'انتهت المسابقة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: RC.ink)),
                Text('إجاباتك الصحيحة: $_score',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, color: RC.green)),
                const SizedBox(height: 12),
                _Ranking(players: players, meId: meId),
              ]);
            },
          );
        }
        final q = questionById(room.qids[room.index]);
        if (q == null) return const SizedBox.shrink();
        final done = _answered >= room.index;
        final picked = _pickedFor == room.index ? _picked : null;
        return ListView(padding: const EdgeInsets.all(18), children: [
          Row(children: [
            Text('السؤال ${room.index + 1} من ${room.qids.length}',
                style: const TextStyle(fontSize: 17, color: RC.ink)),
            const Spacer(),
            const Icon(Icons.check_circle_rounded, color: RC.green),
            const SizedBox(width: 4),
            Text('$_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.green)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
            child: Row(children: [
              Expanded(
                child: Text(q.text,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.ink, height: 1.5)),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: RC.sea, size: 30),
                onPressed: () => Voice.instance.say(q.text),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          for (var k = 0; k < q.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: picked == null
                    ? Colors.white
                    : k == q.answer
                        ? RC.green
                        : (k == picked ? RC.coral : Colors.white),
                borderRadius: BorderRadius.circular(22),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: done ? null : () => _answer(room, q, k),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 66),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: Text(q.options[k],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: picked != null && (k == q.answer || k == picked) ? Colors.white : RC.ink)),
                  ),
                ),
              ),
            ),
          if (done)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('أحسنت! انتظر السؤال التالي...',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: RC.ink)),
            ),
        ]);
      },
    );
  }

  Widget _message(IconData icon, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 80, color: RC.sea),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: RC.ink)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, color: RC.ink)),
          ]),
        ),
      );
}
