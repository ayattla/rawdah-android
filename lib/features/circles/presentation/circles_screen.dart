import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/core/content/names.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/features/competition/presentation/competition_screen.dart';
import 'package:rawdah/features/circles/presentation/live_quiz_screen.dart';

/// حلقاتي: للمعلم أو الوالد. ينشئ حلقة برمز يعطيه للأطفال، ويرى ترتيبهم ويخرج من يشاء.
/// لا محادثة ولا رسائل، فقط الألقاب والنقاط.
class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  int _nameKey = 0;
  int _number = 1;
  String? _error;
  bool _busy = false;

  /// الاسم من القائمة المعتمدة ورقم: لا يُكتب أي نص حر.
  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final st = AppScope.read(context);
    final code = await Online.instance.createCircle(_nameKey, _number);
    if (!mounted) return;
    setState(() => _busy = false);
    if (code == null) {
      setState(() => _error = 'تعذّر الإنشاء، تأكد من الإنترنت');
      return;
    }
    st.addOwnedCircle(code, circleDisplayName(_nameKey, _number));
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('حلقاتي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
          'للمعلم أو المحفّظ أو الوالد: أنشئ حلقة وأعطِ رمزها لأولياء أمور الطلاب. '
          'ينضم الطفل من لوحة الوالدين، فيظهر لقبه ونقاطه في ترتيب الحلقة فقط، بلا أي تواصل.',
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: RC.sea),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveHostScreen())),
          icon: const Icon(Icons.live_tv_rounded),
          label: const Text('ابدأ مسابقة مباشرة', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 18),
        const Text('حلقة دائمة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < kCircleNames.length; i++)
            ChoiceChip(
              label: Text(kCircleNames[i]),
              selected: _nameKey == i,
              onSelected: _busy ? null : (_) => setState(() => _nameKey = i),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('رقم الحلقة', style: TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            tooltip: 'أقل',
            onPressed: _number > 1 ? () => setState(() => _number--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('$_number', style: RT.display(20)),
          IconButton(
            tooltip: 'أكثر',
            onPressed: _number < 99 ? () => setState(() => _number++) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                : Text('إنشاء «${circleDisplayName(_nameKey, _number)}»'),
          ),
        ]),
        if (_error != null) Text(_error!, style: const TextStyle(color: RC.coral)),
        const SizedBox(height: 8),
        if (st.ownedCircles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد حلقات بعد', style: TextStyle(color: Colors.black54))),
          ),
        for (final e in st.ownedCircles)
          Builder(builder: (context) {
            final code = e.split('|').first;
            final name = e.substring(code.length + 1);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.groups_2_outlined, color: RC.green),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('الرمز: $code'),
                trailing: IconButton(
                  tooltip: 'نسخ الرمز',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ الرمز')));
                  },
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CircleBoardScreen(code: code, name: name, owner: true),
                )),
              ),
            );
          }),
      ]),
    );
  }
}

/// ترتيب حلقة واحدة. للمالك: إخراج عضو وحذف الحلقة.
class CircleBoardScreen extends StatelessWidget {
  final String code;
  final String name;
  final bool owner;
  const CircleBoardScreen({super.key, required this.code, required this.name, this.owner = false});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('حذف الحلقة'),
        content: Text('سيُحذف «$name» ولن يستطيع أحد الانضمام إليه. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final st = AppScope.read(context);
    final done = await Online.instance.deleteCircle(code);
    if (!context.mounted) return;
    if (done) {
      st.removeOwnedCircle(code);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الحذف، تأكد من الإنترنت')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (owner)
            IconButton(
              tooltip: 'حذف الحلقة',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context),
            ),
        ],
      ),
      backgroundColor: RC.sand,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('رمز الحلقة: $code', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: RankBoard(
            loader: () => competitionRepo(context).circleBoard(code),
            live: competitionRepo(context).watchCircle(code),
            meId: '',
            onRemove: owner ? (r) => Online.instance.removeMember(code, r.id) : null,
          ),
        ),
      ]),
    );
  }
}
