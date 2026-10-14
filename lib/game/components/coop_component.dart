import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/livestock_and_hemisphere.dart';

/// Flame visual component rendering an active poultry coop with hens and egg crates.
class ChickenCoopComponent extends PositionComponent {
  ChickenCoopComponent({
    required this.coop,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(90, 72),
          anchor: Anchor.center,
          priority: 8,
        );

  final ChickenCoop coop;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Paints
    final Paint woodWallPaint = Paint()..color = const Color(0xFF8D6E63);
    final Paint roofPaint = Paint()..color = const Color(0xFFC2185B); // Rustic magenta/red roof
    final Paint fencePaint = Paint()..color = const Color(0xFFD7CCC8);
    final Paint strawPaint = Paint()..color = const Color(0xFFFFE082);
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Fenced pen area
    final Rect penRect = Rect.fromCenter(center: const Offset(12, 12), width: 78, height: 42);
    canvas.drawRRect(RRect.fromRectAndRadius(penRect, const Radius.circular(4)), strawPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(penRect, const Radius.circular(4)), borderPaint);

    // Fence posts
    fencePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (double x = -22; x <= 46; x += 17) {
      canvas.drawLine(Offset(x, -6), Offset(x, 30), fencePaint);
    }

    // Coop Shed Building
    final Rect shedRect = Rect.fromCenter(center: const Offset(-20, -6), width: 42, height: 38);
    canvas.drawRRect(RRect.fromRectAndRadius(shedRect, const Radius.circular(3)), woodWallPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(shedRect, const Radius.circular(3)), borderPaint);

    // Roof
    final Path roofPath = Path()
      ..moveTo(-44, -14)
      ..lineTo(-20, -32)
      ..lineTo(4, -14)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    canvas.drawPath(roofPath, borderPaint);

    // Hens roaming inside pen
    final Paint henBodyPaint = Paint()..color = Colors.white;
    final Paint combPaint = Paint()..color = Colors.red;
    final Paint beakPaint = Paint()..color = Colors.orange;

    final henOffsets = [
      const Offset(6, 4),
      const Offset(22, 14),
      const Offset(16, 22),
      const Offset(34, 6),
    ];

    for (final off in henOffsets) {
      canvas.drawCircle(off, 4.0, henBodyPaint);
      canvas.drawCircle(off + const Offset(0, -3), 1.5, combPaint);
      canvas.drawCircle(off + const Offset(3, 0), 1.2, beakPaint);
    }

    // Feeder Trough
    final Paint feedPaint = Paint()..color = const Color(0xFFFFB300);
    final Rect troughRect = Rect.fromCenter(center: const Offset(-12, 22), width: 18, height: 8);
    canvas.drawRect(troughRect, borderPaint);
    if (!coop.isFeedStarved) {
      canvas.drawRect(troughRect.deflate(1.5), feedPaint);
    }

    // Egg Basket Indicator
    if (coop.eggStock > 0) {
      final Paint eggPaint = Paint()..color = const Color(0xFFFFF9C4);
      canvas.drawCircle(const Offset(-32, 16), 5.0, eggPaint);
      canvas.drawCircle(const Offset(-32, 16), 5.0, borderPaint);
    }
  }
}
