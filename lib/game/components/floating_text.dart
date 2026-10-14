import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating, fading popup text (e.g. "+30 ÇK", "DOLU!", "+Kapasite").
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    this.color = const Color(0xFFFFD54F),
    this.duration = 0.85,
    this.fontSize = 16.0,
  }) : super(position: position, size: Vector2(120, 30), priority: 30);

  final String text;
  final Color color;
  final double duration;
  final double fontSize;
  double _elapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }
    // Float upwards
    position.y -= 45.0 * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _elapsed / duration;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: opacity * 0.7),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
