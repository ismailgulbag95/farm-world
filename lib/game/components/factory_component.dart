import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/processing_plant.dart';

/// Flame visual component rendering an interactive industrial processing facility.
class FactoryBuildingComponent extends PositionComponent {
  FactoryBuildingComponent({
    required this.facility,
  }) : super(
          position: Vector2(facility.positionX, facility.positionY),
          size: Vector2(96, 76),
          anchor: Anchor.center,
          priority: 8,
        );

  final ProcessingFacility facility;
  double _smokeAnimTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (facility.status == FacilityStatus.processing) {
      _smokeAnimTimer += dt * 3.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Factory building foundation
    final Paint foundationPaint = Paint()..color = const Color(0xFF455A64);
    final Paint wallPaint = Paint()..color = const Color(0xFF90A4AE);
    final Paint roofPaint = Paint()..color = const Color(0xFFD32F2F); // Industrial red
    final Paint doorPaint = Paint()..color = const Color(0xFF263238);
    final Paint windowPaint = Paint()..color = const Color(0xFFB3E5FC);
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Foundation
    final Rect fRect = Rect.fromCenter(center: const Offset(0, 15), width: 92, height: 44);
    canvas.drawRRect(RRect.fromRectAndRadius(fRect, const Radius.circular(4)), wallPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(fRect, const Radius.circular(4)), borderPaint);

    // Industrial Sawtooth Roof
    final Path roofPath = Path()
      ..moveTo(-46, -7)
      ..lineTo(-23, -25)
      ..lineTo(-23, -7)
      ..lineTo(0, -25)
      ..lineTo(0, -7)
      ..lineTo(23, -25)
      ..lineTo(23, -7)
      ..lineTo(46, -7)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    canvas.drawPath(roofPath, borderPaint);

    // Smokestack (Chimney)
    final Rect chimneyRect = Rect.fromLTWH(26, -34, 12, 28);
    canvas.drawRect(chimneyRect, foundationPaint);
    canvas.drawRect(chimneyRect, borderPaint);

    // Smoke puffs if processing
    if (facility.status == FacilityStatus.processing) {
      final Paint smokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7);
      final puffOffset1 = Offset(32, -42 - (sin(_smokeAnimTimer) * 4));
      final puffOffset2 = Offset(34, -54 - (cos(_smokeAnimTimer) * 5));
      canvas.drawCircle(puffOffset1, 5.0, smokePaint);
      canvas.drawCircle(puffOffset2, 7.0, smokePaint);
    }

    // Roll-up Cargo Door
    final Rect doorRect = Rect.fromCenter(center: const Offset(0, 22), width: 28, height: 26);
    canvas.drawRect(doorRect, doorPaint);
    canvas.drawRect(doorRect, borderPaint);

    // Factory Windows
    final Rect winL = Rect.fromCenter(center: const Offset(-26, 16), width: 14, height: 12);
    final Rect winR = Rect.fromCenter(center: const Offset(26, 16), width: 14, height: 12);
    canvas.drawRect(winL, windowPaint);
    canvas.drawRect(winL, borderPaint);
    canvas.drawRect(winR, windowPaint);
    canvas.drawRect(winR, borderPaint);

    // Status Indicator Light
    final Color statusColor;
    switch (facility.status) {
      case FacilityStatus.processing:
        statusColor = const Color(0xFF00E676); // Green
        break;
      case FacilityStatus.starvedInput:
        statusColor = const Color(0xFFFFB300); // Amber (waiting for crops)
        break;
      case FacilityStatus.blockedOutput:
        statusColor = const Color(0xFFFF1744); // Red (full output)
        break;
      case FacilityStatus.idle:
        statusColor = const Color(0xFF78909C);
        break;
    }
    final Paint statusLampPaint = Paint()..color = statusColor;
    canvas.drawCircle(const Offset(-32, 2), 4.5, statusLampPaint);
    canvas.drawCircle(const Offset(-32, 2), 4.5, borderPaint);

    // Facility Name Tag
    final textPainter = TextPainter(
      text: TextSpan(
        text: facility.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -2),
    );
  }
}
