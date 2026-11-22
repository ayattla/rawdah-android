import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui/widgets.dart';

/// نموذج إضافة طفل: اسم مستعار + رمز + فئة عمرية فقط. لا نجمع أي بيانات أخرى.
class AddChildForm extends StatefulWidget {
  final VoidCallback? onDone;
  const AddChildForm({super.key, this.onDone});

  @override
  State<AddChildForm> createState() => _AddChildFormState();
}

class _AddChildFormState extends State<AddChildForm> {
  final _name = TextEditingController();
  String _symbol = kSymbols.first;
  int _band = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      const Text('اسم الطفل أو لقبه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: _name,
        maxLength: 16,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          hintText: 'مثل: نجم الصباح',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      const Text('يكفي لقب يحبه الطفل، ولا حاجة لاسمه الحقيقي.', style: TextStyle(fontSize: 14, color: Colors.black54)),
      const SizedBox(height: 14),
      const Text('رمز الطفل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in kSymbols)
          GestureDetector(
            onTap: () => setState(() => _symbol = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _symbol == s ? RC.gold : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _symbol == s ? RC.greenDark : Colors.black12, width: 2),
              ),
              child: Icon(symbolIcon(s), size: 36, color: _symbol == s ? Colors.white : RC.green),
            ),
          ),
      ]),
      const SizedBox(height: 16),
      const Text('الفئة العمرية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < kAgeBandNames.length; i++)
          ChoiceChip(
            label: Text(kAgeBandNames[i], style: const TextStyle(fontSize: 18)),
            selected: _band == i,
            onSelected: (_) => setState(() => _band = i),
            selectedColor: RC.green.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          ),
      ]),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'إضافة',
        icon: Icons.add_rounded,
        onTap: () {
          AppScope.read(context).addChild(_name.text, _symbol, _band);
          widget.onDone?.call();
        },
      ),
    ]);
  }
}
