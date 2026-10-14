import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/logistics_fleet.dart';

/// Renders stylized logistics transport routes with dashed lines and stop markers.
class RouteVisualComponent extends Component {
  RouteVisualComponent({
    required this.fleetManager,
  }) : super(priority: 4);

  final LogisticsFleetManager fleetManager;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final linePaint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final dotPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;

    final outerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final route in fleetManager.routes) {
      if (!route.isActive || route.stops.length < 2) continue;

      final path = Path();
      final first = route.stops.first;
      path.moveTo(first.positionX, first.positionY);

      for (int i = 1; i < route.stops.length; i++) {
        final stop = route.stops[i];
        path.lineTo(stop.positionX, stop.positionY);
      }
      path.close();

      // Draw route connecting lines
      canvas.drawPath(path, linePaint);

      // Draw stop indicator circles
      for (final stop in route.stops) {
        final center = Offset(stop.positionX, stop.positionY);
        canvas.drawCircle(center, 7.0, outerDotPaint);
        canvas.drawCircle(center, 5.0, dotPaint);
      }
    }
  }
}
