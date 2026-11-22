import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/widgets.dart';

const Map<int, String> _numberWords = {
  21: 'واحد وعشرون',
  23: 'ثلاثة وعشرون',
  24: 'أربعة وعشرون',
  26: 'ستة وعشرون',
  27: 'سبعة وعشرون',
  28: 'ثمانية وعشرون',
  31: 'واحد وثلاثون',
  34: 'أربعة وثلاثون',
  36: 'ستة وثلاثون',
  37: 'سبعة وثلاثون',
  42: 'اثنان وأربعون',
  45: 'خمسة وأربعون',
  48: 'ثمانية وأربعون',
  53: 'ثلاثة وخمسون',
  57: 'سبعة وخمسون',
  64: 'أربعة وستون',
  69: 'تسعة وستون',
  72: 'اثنان وسبعون',
  85: 'خمسة وثمانون',
  96: 'ستة وتسعون',
};

/// بوابة الوالدين: ضغط مطوّل ثلاث ثوانٍ ثم كتابة رقم مكتوب بالحروف.
/// تعيد true إذا اجتاز الوالد البوابة.
Future<bool> passParentGate(BuildContext context) async {
  final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _ParentGate()));
  return ok ?? false;
}

class _ParentGate extends StatefulWidget {
  const _ParentGate();

  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  double _hold = 0;
  Timer? _timer;
  bool _held = false;
  late int _target;
  final _input = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final keys = _numberWords.keys.toList();
    _target = keys[Random().nextInt(keys.length)];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _hold += 50 / 3000);
      if (_hold >= 1) {
        t.cancel();
        setState(() => _held = true);
      }
    });
  }

  void _stop() {
    if (_held) return;
    _timer?.cancel();
    setState(() => _hold = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RC.night,
      appBar: AppBar(backgroundColor: RC.night, foregroundColor: Colors.white, title: const Text('للوالدين فقط')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _held ? _question() : _holdButton(),
        ),
      ),
    );
  }

  Widget _holdButton() => Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('اضغط مطوّلًا على القفل ثلاث ثوانٍ',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 26),
        GestureDetector(
          onTapDown: (_) => _start(),
          onTapUp: (_) => _stop(),
          onTapCancel: _stop,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(value: _hold, strokeWidth: 10, color: RC.gold, backgroundColor: Colors.white12),
            ),
            const Icon(Icons.lock_rounded, color: Colors.white, size: 64),
          ]),
        ),
      ]);

  Widget _question() => Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('اكتب هذا الرقم بالأرقام:', style: TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 10),
        Text(_numberWords[_target]!, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _input,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(fontSize: 28, color: Colors.white),
            decoration: InputDecoration(
              errorText: _error,
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'دخول',
          icon: Icons.lock_open_rounded,
          color: RC.gold,
          onTap: () {
            final v = int.tryParse(_input.text.trim());
            if (v == _target) {
              Navigator.of(context).pop(true);
            } else {
              setState(() => _error = 'الرقم غير صحيح');
            }
          },
        ),
      ]);
}
