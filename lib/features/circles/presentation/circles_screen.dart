import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/features/competition/data/online_service.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/di/providers.dart';
import 'package:rawdah/features/competition/presentation/competition_screen.dart';
import 'package:rawdah/features/circles/presentation/live_quiz_screen.dart';

/// اسم الحلقة: حروف عربية وأرقام ومسافات فقط.
String? validateCircleName(String v) {
  final t = v.trim();
  if (t.length < 2 || t.length > 30) return 'الاسم من 2 إلى 30 حرفًا';
  if (!RegExp(r'^[ء-ي0-9٠-٩ ]+$').hasMatch(t)) return 'حروف عربية وأرقام فقط';
  return null;
}

/// حلقاتي: للمعلم أو الوالد. ينشئ حلقة برمز يعطيه للأطفال، ويرى ترتيبهم ويخرج من يشاء.
/// لا محادثة ولا رسائل، فقط الألقاب والنقاط.
class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final err = validateCircleName(_name.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final st = AppScope.read(context);
    final name = _name.text.trim();
    final code = await Online.instance.createCircle(name);
    if (!mounted) return;
    setState(() => _busy = false);
    if (code == null) {
      setState(() => _error = 'تعذّر الإنشاء، تأكد من الإنترنت');
      return;
    }
    st.addOwnedCircle(code, name);
    _name.clear();
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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: _name,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: 'اسم الحلقة',
                hintText: 'مثال: حلقة الفجر',
                errorText: _error,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                  : const Text('إنشاء'),
            ),
          ),
        ]),
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
            meId: '',
            onRemove: owner ? (r) => Online.instance.removeMember(code, r.id) : null,
          ),
        ),
      ]),
    );
  }
}
