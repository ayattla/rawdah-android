import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rawdah/core/design_system/design_system.dart';
import 'package:rawdah/core/state/app_state.dart';

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
/// إذا عيّن الوالدان رمزًا تظهر لوحة الرمز، وإلا البوابة البسيطة.
Future<bool> passParentGate(BuildContext context) async {
  final hasPin = AppScope.read(context).pin != null;
  final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => hasPin ? const PinPadScreen() : const _ParentGate()));
  return ok ?? false;
}

/// لوحة أرقام رمز الوالدين. وضع الإعداد يطلب الرمز مرتين ويعيده.
class PinPadScreen extends StatefulWidget {
  final bool setup;
  const PinPadScreen({super.key, this.setup = false});

  /// يعيد الرمز الجديد بعد إدخاله مرتين متطابقتين، أو null.
  static Future<String?> askNewPin(BuildContext context) => Navigator.of(context)
      .push<String>(MaterialPageRoute(builder: (_) => const PinPadScreen(setup: true)));

  @override
  State<PinPadScreen> createState() => _PinPadScreenState();
}

class _PinPadScreenState extends State<PinPadScreen> {
  String _code = '';
  String? _first;
  String? _error;

  String get _title => !widget.setup
      ? 'أدخل رمز الوالدين'
      : _first == null
          ? 'اختر رمزًا من 4 أرقام'
          : 'أعد إدخال الرمز للتأكيد';

  void _press(String d) {
    if (_code.length >= 4) return;
    setState(() {
      _code += d;
      _error = null;
    });
    if (_code.length == 4) Future.delayed(const Duration(milliseconds: 120), _submit);
  }

  void _submit() {
    if (!mounted) return;
    final code = _code;
    if (widget.setup) {
      if (_first == null) {
        setState(() {
          _first = code;
          _code = '';
        });
      } else if (_first == code) {
        Navigator.of(context).pop(code);
      } else {
        setState(() {
          _first = null;
          _code = '';
          _error = 'الرمزان غير متطابقين، ابدأ من جديد';
        });
      }
      return;
    }
    final err = AppScope.read(context).verifyPin(code);
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _code = '';
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon, String? semantic}) => Padding(
          padding: const EdgeInsets.all(8),
          child: Chunky(
            color: Colors.white.withValues(alpha: 0.12),
            edge: Colors.black26,
            radius: 20,
            depth: 4,
            onTap: onTap,
            semanticLabel: semantic ?? label,
            child: SizedBox(
              width: 76,
              height: 64,
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 28)
                    : Text(label, style: RT.display(28, color: Colors.white)),
              ),
            ),
          ),
        );
    return Scaffold(
      backgroundColor: RC.night,
      appBar: AppBar(backgroundColor: RC.night, foregroundColor: Colors.white, title: const Text('للوالدين فقط')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_title, style: RT.display(22, color: Colors.white)),
              const SizedBox(height: 18),
              Semantics(
                label: 'أُدخل ${_code.length} من 4 أرقام',
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 22,
                      height: 22,
                      decoration: ShapeDecoration(
                        color: i < _code.length ? RC.gold : Colors.white24,
                        shape: const KhatamBorder(),
                      ),
                    ),
                ]),
              ),
              SizedBox(
                height: 34,
                child: Center(child: Text(_error ?? '', style: RT.body(16, color: const Color(0xFFFF9AA2)))),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d, onTap: () => _press(d))]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 92),
                    key('0', onTap: () => _press('0')),
                    key('', icon: Icons.backspace_rounded, semantic: 'حذف', onTap: () {
                      if (_code.isNotEmpty) setState(() => _code = _code.substring(0, _code.length - 1));
                    }),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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
