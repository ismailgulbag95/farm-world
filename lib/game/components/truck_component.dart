import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/logistics_fleet.dart';
import 'floating_text.dart';

/// Flame rendering and animation component for a logistics fleet truck.
class TruckVehicleComponent extends PositionComponent {
  TruckVehicleComponent({
    required this.vehicleId,
    required this.fleetManager,
  }) : super(
          size: Vector2(56, 32),
          anchor: Anchor.center,
          priority: 12,
        );

  final String vehicleId;
  final LogisticsFleetManager fleetManager;

  double _visualHeading = 0.0;
  int _lastEarnedCredits = 0;

  @override
  void update(double dt) {
    super.update(dt);

    final vehicleIndex =
        fleetManager.vehicles.indexWhere((v) => v.id == vehicleId);
    if (vehicleIndex == -1) return;
    final vehicle = fleetManager.vehicles[vehicleIndex];

    if (vehicle.assignedRouteId == null) return;
    final routeIndex =
        fleetManager.routes.indexWhere((r) => r.id == vehicle.assignedRouteId);
    if (routeIndex == -1) return;
    final route = fleetManager.routes[routeIndex];
    if (route.stops.length < 2) return;

    final currentStop = route.stops[vehicle.currentStopIndex];
    final nextStopIndex = route.nextStopIndex(vehicle.currentStopIndex);
    final nextStop = route.stops[nextStopIndex];

    // Interpolate world position
    final t = vehicle.progressToNextStop.clamp(0.0, 1.0);
    final posX = currentStop.positionX + (nextStop.positionX - currentStop.positionX) * t;
    final posY = currentStop.positionY + (nextStop.positionY - currentStop.positionY) * t;
    position.setValues(posX, posY);

    // Calculate heading angle
    final dx = nextStop.positionX - currentStop.positionX;
    final dy = nextStop.positionY - currentStop.positionY;
    if (dx.abs() > 0.01 || dy.abs() > 0.01) {
      final targetAngle = atan2(dy, dx);
      // Smooth heading rotation
      _visualHeading = targetAngle;
      angle = _visualHeading;
    }

    // Check delivery reward popups
    if (vehicle.totalEarnedCredits > _lastEarnedCredits) {
      final gained = vehicle.totalEarnedCredits - _lastEarnedCredits;
      _lastEarnedCredits = vehicle.totalEarnedCredits;
      parent?.add(
        FloatingTextComponent(
          text: '+$gained ÇK',
          position: position.clone(),
          color: const Color(0xFFFFD54F),
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final vehicleIndex =
        fleetManager.vehicles.indexWhere((v) => v.id == vehicleId);
    final hasCargo = vehicleIndex != -1 && fleetManager.vehicles[vehicleIndex].hasCargo;

    // Body paints
    final Paint cabPaint = Paint()..color = const Color(0xFF1E88E5); // Modern blue cab
    final Paint bedPaint = Paint()..color = const Color(0xFF78909C); // Gray cargo bed
    final Paint outlinePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final Paint wheelPaint = Paint()..color = const Color(0xFF212121);
    final Paint rimPaint = Paint()..color = const Color(0xFFECEFF1);
    final Paint windshieldPaint = Paint()..color = const Color(0xFF81D4FA);

    // Wheels
    final Rect wheelFrontL = Rect.fromCenter(center: const Offset(16, -16), width: 10, height: 4);
    final Rect wheelFrontR = Rect.fromCenter(center: const Offset(16, 16), width: 10, height: 4);
    final Rect wheelBackL = Rect.fromCenter(center: const Offset(-16, -16), width: 12, height: 4);
    final Rect wheelBackR = Rect.fromCenter(center: const Offset(-16, 16), width: 12, height: 4);

    for (final r in [wheelFrontL, wheelFrontR, wheelBackL, wheelBackR]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), wheelPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(1)),
        rimPaint,
      );
    }

    // Cargo Bed (Rear)
    final RRect bedRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-8, 0), width: 34, height: 26),
      const Radius.circular(3),
    );
    canvas.drawRRect(bedRect, bedPaint);
    canvas.drawRRect(bedRect, outlinePaint);

    // If carrying cargo, draw cargo crates/bales inside bed
    if (hasCargo) {
      final Paint cargoPaint = Paint()..color = const Color(0xFFFFCA28); // Golden grain boxes
      final Rect crate1 = Rect.fromCenter(center: const Offset(-14, -5), width: 10, height: 10);
      final Rect crate2 = Rect.fromCenter(center: const Offset(-14, 5), width: 10, height: 10);
      final Rect crate3 = Rect.fromCenter(center: const Offset(-4, 0), width: 10, height: 10);
      for (final c in [crate1, crate2, crate3]) {
        canvas.drawRRect(RRect.fromRectAndRadius(c, const Radius.circular(2)), cargoPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(c, const Radius.circular(2)), outlinePaint);
      }
    }

    // Cab (Front)
    final RRect cabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(16, 0), width: 20, height: 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(cabRect, cabPaint);
    canvas.drawRRect(cabRect, outlinePaint);

    // Windshield
    final RRect windRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(19, 0), width: 6, height: 18),
      const Radius.circular(2),
    );
    canvas.drawRRect(windRect, windshieldPaint);

    // Headlights
    final Paint lightPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(const Offset(26, -8), 2.5, lightPaint);
    canvas.drawCircle(const Offset(26, 8), 2.5, lightPaint);
  }
}
