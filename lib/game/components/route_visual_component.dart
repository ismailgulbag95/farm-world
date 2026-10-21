import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/logistics_fleet.dart';

/// Renders stylized logistics transport routes with dashed lines and stop markers.
class RouteVisualComponent extends Component {
  RouteVisualComponent({required this.fleetManager}) : super(priority: 4);

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
      if (!route.isActive || !route.hasRoadGeometry) continue;

      final path = Path();
      final legCount = route.stops.length == 2 ? 1 : route.stops.length;
      for (var legIndex = 0; legIndex < legCount; legIndex++) {
        final legPoints = route.pathForLeg(legIndex);
        if (legPoints.isEmpty) continue;

        path.moveTo(legPoints.first.x, legPoints.first.y);
        for (final point in legPoints.skip(1)) {
          path.lineTo(point.x, point.y);
        }
      }

      // Each subpath follows the road geometry stored for that route leg.
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
