import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Juicy, bouncy flying grass particle that bursts out when mowing grass.
class GrassParticleComponent extends PositionComponent {
  GrassParticleComponent({
    required Vector2 position,
    required this.velocity,
    Color? color,
  })  : _color = color ?? _palette[_random.nextInt(_palette.length)],
        super(position: position, size: Vector2(4, 7), priority: 15) {
    _lifetime = 0.35 + _random.nextDouble() * 0.25;
    _rotationSpeed = (_random.nextDouble() - 0.5) * 14.0;
  }

  static final Random _random = Random();
  static const List<Color> _palette = [
    Color(0xFF7CB342),
    Color(0xFF8BC34A),
    Color(0xFF689F38),
    Color(0xFF9CCC65),
    Color(0xFF558B2F),
  ];

  final Vector2 velocity;
  final Color _color;
  late final double _lifetime;
  late final double _rotationSpeed;
  double _elapsed = 0.0;
  double _angle = 0.0;

  static const double _gravity = 240.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _lifetime) {
      removeFromParent();
      return;
    }

    velocity.y += _gravity * dt;
    position.add(velocity * dt);
    _angle += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _elapsed / _lifetime;
    final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();

    final paint = Paint()
      ..color = _color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.x * (1.0 - progress * 0.3),
          height: size.y * (1.0 - progress * 0.2),
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.restore();
  }
}
