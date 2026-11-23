import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/parental/time_lock.dart';
import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/parents/presentation/parent_gate.dart';

/// شاشة القفل: لا تُفتح إلا برمز الوالدين (أو ببوابتهم إن لم يعيّنوا رمزًا).
/// الطفل يرى سبب القفل بلطف، والوالدان يمددان الوقت أو يؤكدان وقت الجهاز.
class LockScreen extends StatelessWidget {
  final LockReason reason;
  const LockScreen({super.key, required this.reason});

  String _hour(int h) {
    final hh = h % 24;
    final period = hh < 12 ? 'صباحًا' : 'مساءً';
    final v = hh % 12 == 0 ? 12 : hh % 12;
    return '$v $period';
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.current;
    final (title, body) = switch (reason) {
      LockReason.dailyLimit => ('انتهى وقت اليوم', 'أحسنت اليوم يا ${c?.name ?? ''}. نرتاح الآن ونلتقي غدًا بإذن الله.'),
      LockReason.outsideHours => (
          'الروضة مغلقة الآن',
          'وقت الروضة من ${_hour(c?.allowedFrom ?? 0)} إلى ${_hour(c?.allowedTo ?? 0)}. نلتقي في الموعد بإذن الله.'
        ),
      LockReason.clockChanged => ('تغيّر وقت الجهاز', 'اطلب من والديك تأكيد الوقت لنكمل.'),
      LockReason.none => ('', ''),
    };
    Future<void> parentAction(void Function() action) async {
      if (await passParentGate(context)) action();
    }

    return Scaffold(
      body: SceneBackground(
        night: true,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Lantern(size: 130, glow: 0.15),
              const SizedBox(height: 20),
              Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: RT.display(32, color: Colors.white))),
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center, style: RT.body(20, color: Colors.white)),
              const SizedBox(height: 26),
              if (reason == LockReason.dailyLimit) ...[
                PrimaryButton(
                  label: 'تمديد 15 دقيقة (للوالدين)',
                  icon: Icons.lock_clock_rounded,
                  color: RC.green,
                  onTap: () => parentAction(() => st.addBonusMinutes(15)),
                ),
                const SizedBox(height: 12),
              ],
              if (reason == LockReason.clockChanged) ...[
                PrimaryButton(
                  label: 'تأكيد الوقت (للوالدين)',
                  icon: Icons.verified_user_rounded,
                  color: RC.green,
                  onTap: () => parentAction(st.acknowledgeClock),
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: 'تبديل الطفل',
                icon: Icons.swap_horiz_rounded,
                color: RC.plum,
                onTap: () {
                  st.leaveChild();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
