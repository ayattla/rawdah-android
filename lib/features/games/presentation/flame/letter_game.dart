import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// لعبة «صيد الحروف»: فوانيس تصعد وعليها حروف، والطفل يلمس الفانوس الذي يحمل الحرف المطلوب.
/// العناصر كلها جمادات (فوانيس ونجوم)، بلا أي ذوات أرواح.
class LetterGame extends FlameGame {
  final String target;
  final List<String> pool;
  final void Function() onHit;
  final void Function() onMiss;
  final double speedFactor;

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

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    if (!running) return;
    _spawn += dt;
    if (_spawn > 1.0 / speedFactor) {
      _spawn = 0;
      _addLantern();
    }
  }

  void _addLantern() {
    if (size.x < 100) return;
    final isTarget = _rnd.nextDouble() < 0.4;
    final others = pool.where((l) => l != target).toList();
    final letter = isTarget || others.isEmpty ? target : others[_rnd.nextInt(others.length)];
    add(LanternComponent(
      letter: letter,
      isTarget: letter == target,
      speed: (55 + _rnd.nextDouble() * 45) * speedFactor,
      position: Vector2(50 + _rnd.nextDouble() * (size.x - 100), size.y + 50),
    ));
  }

  void tapped(LanternComponent l) {
    if (!running || l.popped) return;
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
  final String letter;
  final bool isTarget;
  final double speed;
  bool popped = false;
  double _shake = 0;
  double _fade = 1;
  late final TextPainter _tp;

  LanternComponent({
    required this.letter,
    required this.isTarget,
    required this.speed,
    required Vector2 position,
  }) : super(position: position, size: Vector2(76, 96), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(fontFamily: 'Rubik', fontSize: 38, fontWeight: FontWeight.w700, color: Color(0xFF5A3A14)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
  }

  void pop() => popped = true;
  void shake() => _shake = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (_shake > 0) _shake = max(0, _shake - dt);
    if (popped) {
      _fade -= dt * 3;
      scale = Vector2.all(1 + (1 - _fade) * 0.6);
      if (_fade <= 0) removeFromParent();
    }
    if (position.y < -80) removeFromParent();
  }

  @override
  void onTapDown(TapDownEvent event) => game.tapped(this);

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;
    final dx = _shake > 0 ? sin(_shake * 60) * 6 : 0.0;
    canvas.save();
    canvas.translate(dx, 0);
    final alpha = _fade.clamp(0.0, 1.0).toDouble();
    final glow = Paint()
      ..color = const Color(0xFFF2B544).withValues(alpha: 0.35 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(w / 2, h * 0.55), w * 0.55, glow);
    final frame = Paint()..color = const Color(0xFF8A5A2B).withValues(alpha: alpha);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.1), const Radius.circular(4)), frame);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.1, w * 0.84, h * 0.78), Radius.circular(w * 0.28));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFFE08A).withValues(alpha: alpha));
    canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF8A5A2B).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.88, w * 0.5, h * 0.08), const Radius.circular(4)), frame);
    _tp.paint(canvas, Offset((w - _tp.width) / 2, h * 0.49 - _tp.height / 2));
    canvas.restore();
  }
}
