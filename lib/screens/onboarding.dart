import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'add_child.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _agree = false;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (st.consentGiven && _step < 2) _step = 2;
    return Scaffold(
      body: SceneBackground(
        child: ListView(padding: const EdgeInsets.all(22), children: [
          if (_step == 0) ..._welcome(),
          if (_step == 1) ..._consent(st),
          if (_step == 2) ..._addChild(),
        ]),
      ),
    );
  }

  List<Widget> _welcome() => [
        const SizedBox(height: 30),
        const Center(child: Lantern(size: 150, glow: 0.9)),
        const SizedBox(height: 18),
        const Text('روضة',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: RC.greenDark)),
        const Text('قصص ودروس وألعاب ومسابقات لأطفالنا',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: RC.ink)),
        const SizedBox(height: 26),
        _card(const [
          _Point(Icons.block_rounded, 'بلا إعلانات وبلا موسيقى'),
          _Point(Icons.landscape_rounded, 'بلا صور لذوات الأرواح'),
          _Point(Icons.wifi_off_rounded, 'يعمل بلا إنترنت، وبياناته على جهازك فقط'),
          _Point(Icons.verified_rounded, 'آيات من نص المصحف، وأحاديث صحيحة مع تخريجها'),
        ]),
        const SizedBox(height: 22),
        PrimaryButton(label: 'ابدأ (للوالدين)', onTap: () => setState(() => _step = 1)),
      ];

  List<Widget> _consent(AppState st) => [
        const SizedBox(height: 10),
        const Text('موافقة ولي الأمر',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.greenDark)),
        const SizedBox(height: 12),
        _card(const [
          _Point(Icons.edit_note_rounded, 'نحفظ لكل طفل: لقبًا ورمزًا وفئة عمرية وتقدّمه فقط'),
          _Point(Icons.phone_android_rounded, 'كل البيانات محفوظة على هذا الجهاز ولا تُرسل إلى أي خادم'),
          _Point(Icons.do_not_disturb_on_rounded, 'لا نطلب موقعًا ولا صورًا ولا جهات اتصال ولا ميكروفونًا'),
          _Point(Icons.delete_outline_rounded, 'تستطيع حذف بيانات أي طفل في أي وقت من لوحة الوالدين'),
        ]),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
          title: const Text('أنا ولي أمر الطفل، وأوافق على استخدامه للتطبيق وفق ما سبق',
              style: TextStyle(fontSize: 17)),
          controlAffinity: ListTileControlAffinity.leading,
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'موافق ومتابعة',
          onTap: _agree
              ? () {
                  st.giveConsent();
                  setState(() => _step = 2);
                }
              : null,
        ),
      ];

  List<Widget> _addChild() => [
        const SizedBox(height: 10),
        const Text('أضف طفلك الأول',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: RC.greenDark)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(24)),
          child: const AddChildForm(),
        ),
      ];

  Widget _card(List<Widget> rows) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24)),
        child: Column(children: rows),
      );
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, color: RC.green, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, color: RC.ink))),
        ]),
      );
}
