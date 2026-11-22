import 'package:flutter/material.dart';

import 'package:rawdah/core/content/content.dart';
import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/core/services/voice.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/widgets.dart';
import 'package:rawdah/features/profiles/presentation/add_child_screen.dart';
import 'package:rawdah/features/circles/presentation/circles_screen.dart';
import 'package:rawdah/features/garden/presentation/garden_screen.dart';

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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.groups_2_outlined),
          label: const Text('حلقاتي: للمعلم والمحفّظ', style: TextStyle(fontSize: 17)),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CirclesScreen())),
        ),
        const SizedBox(height: 18),
        _Panel(title: 'الإعدادات', children: [
          SwitchListTile(
            value: st.voiceOn,
            onChanged: st.setVoice,
            title: const Text('الراوي الصوتي'),
            subtitle: const Text('يقرأ التعليمات والقصص بصوت الجهاز. لا يقرأ آيات القرآن.'),
          ),
          const _VoiceStatus(),
        ]),
        _Panel(title: 'الخصوصية', children: const [
          ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('لا إعلانات ولا تتبّع ولا محادثات'),
            subtitle: Text('البيانات محفوظة على هذا الجهاز. لا يتصل بالإنترنت إلا إذا فعّلت المنافسة لطفل، وعندها يُرسل لقبه ورمزه ونقاطه فقط.'),
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
          _OnlineCard(child: c),
          const SizedBox(height: 14),
          const Text('الاستخدام في آخر 7 أيام (بالدقائق)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _WeekBars(child: c),
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

class _WeekBars extends StatelessWidget {
  final ChildProfile child;
  const _WeekBars({required this.child});

  static const _days = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    final mins = [for (final d in days) (child.usageSeconds[todayKey(d)] ?? 0) ~/ 60];
    final top = mins.fold<int>(0, (a, b) => a > b ? a : b);
    final scaleMax = top < 10 ? 10 : top;
    return SizedBox(
      height: 130,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${mins[i]}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Container(
                height: 80 * mins[i] / scaleMax + 2,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: i == days.length - 1 ? RC.green : RC.green.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Text(_days[days[i].weekday - 1], style: const TextStyle(fontSize: 10)),
            ]),
          ),
      ]),
    );
  }
}

class _VoiceStatus extends StatelessWidget {
  const _VoiceStatus();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Voice.instance.init(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ListTile(title: Text('جارٍ فحص الصوت العربي...'));
        }
        final ok = Voice.instance.arabicAvailable == true;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            leading: Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: ok ? RC.green : RC.coral),
            title: Text(ok ? 'الصوت العربي متوفر' : 'لا يوجد صوت عربي في هذا الجوال'),
            subtitle: Text(ok
                ? 'المحرك: ${Voice.instance.engineName.isEmpty ? 'الافتراضي' : Voice.instance.engineName}'
                : 'لذلك أوقفنا الراوي حتى لا ينطق كلامًا غير مفهوم. ثبّت «خدمات الكلام من Google» من المتجر، '
                    'ثم من إعدادات الجوال: تحويل النص إلى كلام، اختر محرك Google ونزّل اللغة العربية، وأعد فتح التطبيق.'),
          ),
          if (ok)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('تجربة الصوت'),
                onPressed: () => Voice.instance.say('السلام عليكم، أهلًا بك في روضة'),
              ),
            ),
        ]);
      },
    );
  }
}

const _nickA = ['نجم', 'قمر', 'فانوس', 'كوكب', 'شهاب', 'غيمة', 'نخلة', 'وردة'];
const _nickB = ['الصباح', 'الأمل', 'المعرفة', 'الهدى', 'السماء', 'الخير', 'العلم', 'النور'];
const _blocked = ['غبي', 'حمار', 'كلب', 'زق', 'تفو', 'وسخ', 'حقير', 'لعن'];

String? validateNick(String v) {
  final t = v.trim();
  if (t.length < 2 || t.length > 16) return 'اللقب من 2 إلى 16 حرفًا';
  if (!RegExp(r'^[\u0621-\u064A ]+$').hasMatch(t)) return 'حروف عربية فقط، بلا أرقام أو رموز';
  for (final b in _blocked) {
    if (t.contains(b)) return 'اختر لقبًا لائقًا';
  }
  return null;
}

class _OnlineCard extends StatefulWidget {
  final ChildProfile child;
  const _OnlineCard({required this.child});

  @override
  State<_OnlineCard> createState() => _OnlineCardState();
}

class _OnlineCardState extends State<_OnlineCard> {
  late final TextEditingController _nick;
  final _circle = TextEditingController();
  String? _circleError;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final c = widget.child;
    _nick = TextEditingController(text: c.nick.isNotEmpty ? c.nick : '${_nickA[c.id.hashCode.abs() % 8]} ${_nickB[(c.id.hashCode.abs() ~/ 8) % 8]}');
  }

  @override
  void dispose() {
    _nick.dispose();
    _circle.dispose();
    super.dispose();
  }

  Future<void> _joinCircle() async {
    final st = AppScope.read(context);
    setState(() {
      _busy = true;
      _circleError = null;
    });
    final err = await Online.instance.joinCircle(st, widget.child, _circle.text);
    if (mounted) setState(() {
      _busy = false;
      _circleError = err;
    });
  }

  Future<void> _toggle(bool on) async {
    final st = AppScope.read(context);
    final c = widget.child;
    if (on) {
      final err = validateNick(_nick.text);
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      setState(() {
        _busy = true;
        _error = null;
      });
      c.nick = _nick.text.trim();
      final res = await Online.instance.join(st, c);
      if (mounted) setState(() {
        _busy = false;
        _error = res;
      });
    } else {
      setState(() => _busy = true);
      await Online.instance.leave(c);
      c.onlineEnabled = false;
      c.pendingPoints = 0;
      c.circleCode = '';
      c.circleName = '';
      c.circlePoints = 0;
      st.updateChild(c);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.child;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.leaderboard_rounded, color: RC.coral),
          const SizedBox(width: 8),
          const Expanded(child: Text('المنافسة أون لاين', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          _busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
              : Switch(value: c.onlineEnabled, onChanged: _toggle),
        ]),
        const Text('يظهر طفلك في الترتيب باللقب والرمز والنقاط فقط. لا محادثة ولا رسائل ولا أي بيانات شخصية.',
            style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _nick,
          enabled: !c.onlineEnabled && !_busy,
          maxLength: 16,
          decoration: InputDecoration(
            labelText: 'لقب الطفل في المنافسة',
            helperText: 'لا تكتب الاسم الحقيقي الكامل',
            errorText: _error,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (c.onlineEnabled)
          Text('النقاط الكلية: ${c.onlineTotal}  ·  نقاط الأسبوع: ${c.weekPoints}  ·  المنزلة: ${Online.tiers[Online.tierIndex(c.onlineTotal)].$1}',
              style: const TextStyle(fontSize: 13)),
        if (c.onlineEnabled) ...[
          const Divider(height: 20),
          if (c.circleCode.isEmpty)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  controller: _circle,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'رمز حلقة المعلم (اختياري)',
                    errorText: _circleError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(onPressed: _busy ? null : _joinCircle, child: const Text('انضمام')),
              ),
            ])
          else
            Row(children: [
              const Icon(Icons.groups_2_outlined, color: RC.green),
              const SizedBox(width: 6),
              Expanded(child: Text('في حلقة: ${c.circleName}  ·  ${c.circlePoints} نقطة')),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await Online.instance.leaveCircle(AppScope.read(context), c);
                        if (mounted) setState(() => _busy = false);
                      },
                child: const Text('مغادرة'),
              ),
            ]),
        ],
      ]),
    );
  }
}
