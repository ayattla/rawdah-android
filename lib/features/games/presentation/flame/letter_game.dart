import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:rawdah/core/perf/object_pool.dart';

/// لعبة «صيد الحروف»: فوانيس تصعد وعليها حروف، والطفل يلمس الفانوس الذي يحمل الحرف المطلوب.
/// العناصر كلها جمادات (فوانيس)، بلا أي ذوات أرواح.
///
/// الأداء:
/// - الفوانيس تُدار بمجمّع كائنات: تُنشأ مرة واحدة وتبقى في الشجرة، وعند خروجها من
///   الشاشة تُعطَّل وتعود للمجمّع بدل الحذف والإنشاء (لا ضغط على جامع القمامة).
/// - نص كل حرف يُخطَّط مرة واحدة ويُخزَّن (TextPainter) بدل تخطيطه مع كل فانوس.
/// - أدوات الرسم (Paint) والتوهج مُعدّة مسبقًا، والتوهج بتدرج دائري بدل التمويه المكلف.
class LetterGame extends FlameGame {
  String target;
  final List<String> pool;
  final void Function() onHit;
  final void Function() onMiss;
  final double speedFactor;

  /// أقصى عدد فوانيس ظاهرة معًا.
  static const maxActive = 9;

  LetterGame({
    required this.target,
    required this.pool,
    required this.onHit,
    required this.onMiss,
    this.speedFactor = 1,
  });

  final _rnd = Random();
  double _spawn = 0;
  bool running = true;
  late final ObjectPool<LanternComponent> lanterns = ObjectPool(
    create: () {
      final l = LanternComponent(onDone: _recycle);
      add(l);
      return l;
    },
    onRelease: (l) => l.deactivate(),
    maxFree: maxActive,
  );
  int _active = 0;
  List<String> _others = const [];

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    LanternComponent.warmUp(pool);
    _others = pool.where((l) => l != target).toList(growable: false);
  }

  /// جولة جديدة بالحرف نفسه أو بحرف آخر، دون إنشاء لعبة جديدة.
  void restart(String newTarget) {
    target = newTarget;
    _others = pool.where((l) => l != target).toList(growable: false);
    for (final l in children.whereType<LanternComponent>()) {
      if (l.active) _recycle(l);
    }
    _spawn = 0;
    running = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!running) return;
    _spawn += dt;
    if (_spawn > 1.0 / speedFactor) {
      _spawn = 0;
      _spawnLantern();
    }
  }

  void _spawnLantern() {
    if (size.x < 100 || _active >= maxActive) return;
    final isTarget = _rnd.nextDouble() < 0.4 || _others.isEmpty;
    final letter = isTarget ? target : _others[_rnd.nextInt(_others.length)];
    lanterns.acquire().activate(
          letter: letter,
          isTarget: letter == target,
          speed: (55 + _rnd.nextDouble() * 45) * speedFactor,
          at: Vector2(50 + _rnd.nextDouble() * (size.x - 100), size.y + 50),
        );
    _active++;
  }

  void _recycle(LanternComponent l) {
    if (!l.active) return;
    _active--;
    lanterns.release(l);
  }

  void tapped(LanternComponent l) {
    if (!running || l.popped || !l.active) return;
    if (l.isTarget) {
      l.pop();
      onHit();
    } else {
      l.shake();
      onMiss();
    }
  }
}

class LanternComponent extends PositionComponent with TapCallbacks, HasGameReference<LetterGame> {
  final void Function(LanternComponent) onDone;
  LanternComponent({required this.onDone}) : super(size: Vector2(76, 96), anchor: Anchor.center);

  String letter = '';
  bool isTarget = false;
  double speed = 0;
  bool active = false;
  bool popped = false;
  double _shake = 0;
  double _fade = 1;

  // ---- موارد مشتركة بين كل الفوانيس، تُعدّ مرة واحدة
  static final Map<String, TextPainter> _letters = {};
  static const _brass = Color(0xFF8A5A2B);
  static const _glass = Color(0xFFFFE08A);
  static final Paint _framePaint = Paint();
  static final Paint _bodyPaint = Paint();
  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _glowPaint = Paint()
    ..shader = const RadialGradient(colors: [Color(0x99F2B544), Color(0x00F2B544)])
        .createShader(Rect.fromCircle(center: const Offset(38, 53), radius: 46));
  static final RRect _cap = RRect.fromRectAndRadius(const Rect.fromLTWH(22.8, 0, 30.4, 9.6), const Radius.circular(4));
  static final RRect _body = RRect.fromRectAndRadius(const Rect.fromLTWH(6.08, 9.6, 63.84, 74.88), const Radius.circular(21.3));
  static final RRect _base = RRect.fromRectAndRadius(const Rect.fromLTWH(19, 84.48, 38, 7.68), const Radius.circular(4));

  /// يخطّط نصوص كل الحروف مسبقًا قبل بدء اللعب.
  static void warmUp(Iterable<String> letters) {
    for (final l in letters) {
      _letters.putIfAbsent(
        l,
        () => TextPainter(
          text: TextSpan(
            text: l,
            style: const TextStyle(fontFamily: 'Baloo', fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFF5A3A14)),
          ),
          textDirection: TextDirection.rtl,
        )..layout(),
      );
    }
  }

  void activate({required String letter, required bool isTarget, required double speed, required Vector2 at}) {
    this.letter = letter;
    this.isTarget = isTarget;
    this.speed = speed;
    position.setFrom(at);
    scale.setValues(1, 1);
    popped = false;
    _shake = 0;
    _fade = 1;
    active = true;
    warmUp([letter]);
  }

  void deactivate() {
    active = false;
    popped = false;
  }

  void pop() => popped = true;
  void shake() => _shake = 0.4;

  /// الفانوس المعطّل لا يستقبل اللمس.
  @override
  bool containsLocalPoint(Vector2 point) => active && !popped && super.containsLocalPoint(point);

  @override
  void update(double dt) {
    if (!active) return;
    super.update(dt);
    position.y -= speed * dt;
    if (_shake > 0) _shake = max(0, _shake - dt);
    if (popped) {
      _fade -= dt * 3;
      scale.setAll(1 + (1 - _fade) * 0.6);
      if (_fade <= 0) onDone(this);
    } else if (position.y < -80) {
      onDone(this);
    }
  }

  @override
  void onTapDown(TapDownEvent event) => game.tapped(this);

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final dx = _shake > 0 ? sin(_shake * 60) * 6 : 0.0;
    final alpha = _fade.clamp(0.0, 1.0).toDouble();
    canvas.save();
    canvas.translate(dx, 0);
    _glowPaint.color = Color.fromRGBO(0, 0, 0, alpha);
    canvas.drawCircle(const Offset(38, 53), 46, _glowPaint);
    _framePaint.color = _brass.withValues(alpha: alpha);
    canvas.drawRRect(_cap, _framePaint);
    _bodyPaint.color = _glass.withValues(alpha: alpha);
    canvas.drawRRect(_body, _bodyPaint);
    _strokePaint.color = _brass.withValues(alpha: alpha);
    canvas.drawRRect(_body, _strokePaint);
    canvas.drawRRect(_base, _framePaint);
    final tp = _letters[letter];
    if (tp != null) tp.paint(canvas, Offset((size.x - tp.width) / 2, size.y * 0.49 - tp.height / 2));
    canvas.restore();
  }
}
