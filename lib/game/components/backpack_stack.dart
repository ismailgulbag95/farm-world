import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/opening_session.dart';
import '../farm_world_artwork.dart';

/// Renders a bouncy vertical stack of grass bales on the player's back,
/// inspired by hypercasual arcade idle grass-cutting games (Grass Cutter).
class BackpackStackComponent extends PositionComponent {
  BackpackStackComponent({
    required this.session,
  }) : super(priority: 12);

  final OpeningSession session;
  FarmWorldArtwork? artwork;

  double _wobblePhase = 0.0;
  double _wobbleAmplitude = 0.0;
  double _fullPulseTimer = 0.0;

  void triggerStepWobble(double movementIntensity) {
    _wobbleAmplitude = min(1.0, _wobbleAmplitude + movementIntensity * 0.4);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _wobblePhase += dt * 10.0;
    _wobbleAmplitude = max(0.0, _wobbleAmplitude - dt * 2.5);
    _fullPulseTimer = (_fullPulseTimer + dt * 4.0) % (2 * pi);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage == OpeningStage.management) return;

    final carried = session.carriedBaleCount;
    if (carried <= 0) return;

    final capacity = session.backpackCapacity;
    final isFull = carried >= capacity;

    const baleWidth = 24.0;
    const baleHeight = 11.0;
    const baleSpacing = 7.0;

    // Visual cap for rendered bales to keep clean on mobile
    final visualBaleCount = min(carried, 12);

    final balePaint = Paint()
      ..color = const Color(0xFFC7A246)
      ..style = PaintingStyle.fill;
    final baleBorderPaint = Paint()
      ..color = const Color(0xFF8B6B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final grassTiePaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < visualBaleCount; i++) {
      final yOffset = -18.0 - (i * baleSpacing);
      // Progressive wobble tilt the higher the bale is
      final tilt = sin(_wobblePhase + i * 0.4) * _wobbleAmplitude * 0.12 * (i + 1);
      final xOffset = sin(_wobblePhase + i * 0.3) * _wobbleAmplitude * 3.0;

      canvas.save();
      canvas.translate(xOffset, yOffset);
      canvas.rotate(tilt);

      final baleRect = Rect.fromCenter(
        center: Offset.zero,
        width: baleWidth,
        height: baleHeight,
      );

      final baleRRect = RRect.fromRectAndRadius(
        baleRect,
        const Radius.circular(3),
      );

      canvas.drawRRect(baleRRect, balePaint);
      canvas.drawRRect(baleRRect, baleBorderPaint);

      // Straw ties
      canvas.drawLine(
        Offset(-baleWidth * 0.25, -baleHeight / 2),
        Offset(-baleWidth * 0.25, baleHeight / 2),
        grassTiePaint,
      );
      canvas.drawLine(
        Offset(baleWidth * 0.25, -baleHeight / 2),
        Offset(baleWidth * 0.25, baleHeight / 2),
        grassTiePaint,
      );

      canvas.restore();
    }

    // "FULL!" pulsing bubble above player's head when backpack is at max capacity
    if (isFull) {
      final bubbleY = -24.0 - (visualBaleCount * baleSpacing) - 14.0;
      final scale = 1.0 + sin(_fullPulseTimer) * 0.12;

      canvas.save();
      canvas.translate(0, bubbleY);
      canvas.scale(scale);

      final bubblePaint = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill;
      final bubbleBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final badgeRect = Rect.fromCenter(
        center: Offset.zero,
        width: 48,
        height: 20,
      );
      final badgeRRect = RRect.fromRectAndRadius(
        badgeRect,
        const Radius.circular(10),
      );

      canvas.drawRRect(badgeRRect, bubblePaint);
      canvas.drawRRect(badgeRRect, bubbleBorder);

      final tp = TextPainter(
        text: const TextSpan(
          text: 'DOLU!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }
}
