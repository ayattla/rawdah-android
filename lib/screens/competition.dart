import 'package:flutter/material.dart';

import '../services/online.dart';
import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'challenge.dart';
import 'live.dart';

/// ميدان المنافسة أون لاين: ترتيب بالألقاب فقط، بلا أي تواصل بين الأطفال.
class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    if (c == null) return const SizedBox.shrink();
    return ChildShell(
      child: Column(children: [
        const KidBar(title: 'ميدان المنافسة'),
        if (!c.onlineEnabled)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.emoji_events_rounded, size: 90, color: RC.gold),
                  SizedBox(height: 14),
                  Text('نافس أطفالًا من كل مكان!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: RC.ink)),
                  SizedBox(height: 8),
                  Text('اطلب من والديك تفعيل المنافسة من لوحة الوالدين، ثم اجمع النقاط واصعد في الهرم.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: RC.ink)),
                ]),
              ),
            ),
          )
        else ...[
          _MyCard(child: c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChallengeScreen())),
                    icon: const Icon(Icons.sports_score_rounded, color: RC.coral),
                    label: const Text('تحدي صديق', style: TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveJoinScreen())),
                    icon: const Icon(Icons.live_tv_rounded, color: RC.sea),
                    label: const Text('مسابقة مباشرة', style: TextStyle(fontSize: 17)),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SegmentedButton<int>(
              segments: [
                const ButtonSegment(value: 0, label: Text('هذا الأسبوع')),
                const ButtonSegment(value: 1, label: Text('الهرم')),
                const ButtonSegment(value: 2, label: Text('الأبطال')),
                if (c.circleCode.isNotEmpty) ButtonSegment(value: 3, label: Text('حلقتي')),
              ],
              selected: {_tab == 3 && c.circleCode.isEmpty ? 0 : _tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? RankBoard(key: const ValueKey('week'), loader: () => Online.instance.weekBoard(c.ageBand), meId: _meId(c))
                : _tab == 1
                    ? _Pyramid(child: c)
                    : _tab == 3 && c.circleCode.isNotEmpty
                        ? Column(children: [
                            Text('حلقة: ${c.circleName}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RC.green)),
                            Expanded(
                              child: RankBoard(
                                  key: ValueKey('circle_${c.circleCode}'),
                                  loader: () => Online.instance.circleBoard(c.circleCode),
                                  meId: _meId(c)),
                            ),
                          ])
                        : RankBoard(key: const ValueKey('all'), loader: Online.instance.allTimeBoard, meId: _meId(c)),
          ),
        ],
      ]),
    );
  }

  String _meId(ChildProfile c) => Online.instance.uid == null ? '' : Online.instance.playerId(c);
}

class _MyCard extends StatefulWidget {
  final ChildProfile child;
  const _MyCard({required this.child});

  @override
  State<_MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<_MyCard> {
  int? _rank;

  @override
  void initState() {
    super.initState();
    Online.instance.myWeekRank(widget.child).then((r) {
      if (mounted) setState(() => _rank = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.child;
    final total = c.onlineTotal + c.pendingPoints;
    final tier = Online.tierIndex(total);
    final next = tier + 1 < Online.tiers.length ? Online.tiers[tier + 1] : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Icon(symbolIcon(c.symbol), color: RC.gold, size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.nick, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RC.ink)),
            Text('منزلتك: ${Online.tiers[tier].$1}', style: const TextStyle(fontSize: 16, color: RC.green)),
            if (next != null)
              Text('بقي ${next.$2 - total} نقطة لمنزلة ${next.$1}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ]),
        ),
        Column(children: [
          Text(_rank == null ? '—' : '#$_rank',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: RC.coral)),
          Text('${c.weekPoints + c.pendingPoints} نقطة', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ]),
      ]),
    );
  }
}

class RankBoard extends StatefulWidget {
  final Future<List<RankRow>> Function() loader;
  final String meId;

  /// للمعلم فقط: إخراج عضو من الحلقة بدل الإبلاغ.
  final Future<bool> Function(RankRow r)? onRemove;
  const RankBoard({super.key, required this.loader, required this.meId, this.onRemove});

  @override
  State<RankBoard> createState() => _RankBoardState();
}

class _RankBoardState extends State<RankBoard> {
  late Future<List<RankRow>> _f;

  @override
  void initState() {
    super.initState();
    _f = widget.loader();
  }

  Future<void> _remove(RankRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('إخراج من الحلقة'),
        content: Text('هل تريد إخراج «${r.nick}» من الحلقة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok == true && await widget.onRemove!(r) && mounted) {
      setState(() => _f = widget.loader());
    }
  }

  Future<void> _report(RankRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('إبلاغ عن لقب غير لائق'),
        content: Text('هل لقب «${r.nick}» غير لائق؟ سيراجعه المشرف.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('نعم، أبلغ')),
        ],
      ),
    );
    if (ok == true) {
      await Online.instance.report(r.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكرًا، وصل البلاغ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _f = widget.loader());
        await _f;
      },
      child: FutureBuilder<List<RankRow>>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data ?? const [];
          if (snap.hasError || rows.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              Center(
                child: Text('لا توجد نتائج بعد. كن أول المتسابقين!',
                    style: TextStyle(fontSize: 19, color: RC.ink)),
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              final me = r.id == widget.meId;
              final medal = i == 0
                  ? RC.gold
                  : i == 1
                      ? const Color(0xFFB0B7C3)
                      : i == 2
                          ? const Color(0xFFCD8B5A)
                          : null;
              return GestureDetector(
                onLongPress: me ? null : () => widget.onRemove != null ? _remove(r) : _report(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: me ? RC.gold.withValues(alpha: 0.25) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: me ? RC.gold : Colors.transparent, width: 2),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 38,
                      child: medal != null
                          ? Icon(Icons.emoji_events_rounded, color: medal, size: 30)
                          : Text('${i + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RC.ink)),
                    ),
                    Icon(symbolIcon(r.symbol), color: RC.green, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${r.nick}  #${Online.tag(r.id)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: me ? FontWeight.w700 : FontWeight.w500)),
                    ),
                    Text('${r.points}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: RC.coral)),
                    if (widget.onRemove != null)
                      IconButton(
                        tooltip: 'إخراج',
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.black38),
                        onPressed: () => _remove(r),
                      ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Pyramid extends StatefulWidget {
  final ChildProfile child;
  const _Pyramid({required this.child});

  @override
  State<_Pyramid> createState() => _PyramidState();
}

class _PyramidState extends State<_Pyramid> {
  late Future<List<int>> _f;

  @override
  void initState() {
    super.initState();
    _f = Online.instance.pyramidCounts();
  }

  @override
  Widget build(BuildContext context) {
    final mine = Online.tierIndex(widget.child.onlineTotal + widget.child.pendingPoints);
    return FutureBuilder<List<int>>(
      future: _f,
      builder: (context, snap) {
        final counts = snap.data ?? const <int>[];
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (var i = Online.tiers.length - 1; i >= 0; i--)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FractionallySizedBox(
                widthFactor: 0.4 + 0.6 * i / (Online.tiers.length - 1),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: i == mine ? RC.gold : Color.lerp(const Color(0xFFDFF3E6), RC.green, i / 7),
                    borderRadius: BorderRadius.circular(16),
                    border: i == mine ? Border.all(color: RC.coral, width: 3) : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    if (i == mine) const Icon(Icons.star_rounded, color: Colors.white),
                    Expanded(
                      child: Text(Online.tiers[i].$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: i == mine || i >= 4 ? Colors.white : RC.ink)),
                    ),
                    Text(counts.length > i ? '${counts[i]}' : '',
                        style: TextStyle(fontSize: 15, color: i == mine || i >= 4 ? Colors.white : RC.ink)),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text('الأرقام: عدد الأطفال في كل منزلة. أجب عن الأسئلة وأكمل الدروس والقصص لتصعد.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black54)),
        ]);
      },
    );
  }
}
