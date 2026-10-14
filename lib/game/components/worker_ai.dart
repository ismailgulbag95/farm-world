import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/opening_session.dart';
import '../farm_world_artwork.dart';

enum WorkerState {
  idle,
  movingToPlot,
  working,
  movingToBarn,
  delivering,
}

/// Autonomous AI farm worker simulating hands-free management gameplay.
class AutonomousWorkerComponent extends PositionComponent {
  AutonomousWorkerComponent({
    required Vector2 position,
    required this.session,
    required this.barnPosition,
  }) : super(
          position: position,
          size: Vector2(84, 64),
          anchor: Anchor.center,
          priority: 11,
        );

  final OpeningSession session;
  final Vector2 barnPosition;
  FarmWorldArtwork? artwork;

  WorkerState state = WorkerState.idle;
  Vector2 targetPosition = Vector2.zero();
  int currentTargetPlotId = 0;
  double _stateTimer = 0.0;
  Vector2 facingDirection = Vector2(0, 1);

  static const double moveSpeed = 85.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (session.stage != OpeningStage.management) return;

    switch (state) {
      case WorkerState.idle:
        _updateIdle(dt);
        break;
      case WorkerState.movingToPlot:
        _updateMovingToPlot(dt);
        break;
      case WorkerState.working:
        _updateWorking(dt);
        break;
      case WorkerState.movingToBarn:
        _updateMovingToBarn(dt);
        break;
      case WorkerState.delivering:
        _updateDelivering(dt);
        break;
    }
  }

  void _updateIdle(double dt) {
    _stateTimer += dt;
    if (_stateTimer < 1.5) return;
    _stateTimer = 0.0;

    // Search for a plot that is ready to harvest or needs planting
    final now = DateTime.now();
    for (final plot in session.plots) {
      if (!plot.isOwned) continue;
      final plotPos = Vector2(plot.positionX, plot.positionY);

      if (plot.hasActiveCrop) {
        final anchor = session.firstSuccessfulPlantingAt;
        if (anchor != null) {
          final snapshot = plot.cropSnapshotAt(now, anchor);
          if (snapshot != null && snapshot.isHarvestable) {
            // Found a ready plot!
            currentTargetPlotId = plot.id;
            targetPosition = plotPos;
            state = WorkerState.movingToPlot;
            return;
          }
        }
      } else if (session.canPlantCropOnPlot(plot.id, OpeningSession.starterWheatId)) {
        // Needs planting
        currentTargetPlotId = plot.id;
        targetPosition = plotPos;
        state = WorkerState.movingToPlot;
        return;
      }
    }
  }

  void _updateMovingToPlot(double dt) {
    final diff = targetPosition - position;
    if (diff.length <= 6.0) {
      state = WorkerState.working;
      _stateTimer = 0.0;
      return;
    }

    final dir = diff.normalized();
    facingDirection = dir;
    position += dir * (moveSpeed * dt);
  }

  void _updateWorking(double dt) {
    _stateTimer += dt;
    if (_stateTimer >= 2.0) {
      _stateTimer = 0.0;
      final now = DateTime.now();

      // Check if planting or harvesting
      final plot = session.plots.firstWhere((p) => p.id == currentTargetPlotId);
      if (plot.hasActiveCrop) {
        session.harvestCropOnPlot(plot.id, now);
        targetPosition = barnPosition.clone();
        state = WorkerState.movingToBarn;
      } else {
        session.plantCropOnPlot(plot.id, OpeningSession.starterWheatId, now);
        state = WorkerState.idle;
      }
    }
  }

  void _updateMovingToBarn(double dt) {
    final diff = targetPosition - position;
    if (diff.length <= 8.0) {
      state = WorkerState.delivering;
      _stateTimer = 0.0;
      return;
    }

    final dir = diff.normalized();
    facingDirection = dir;
    position += dir * (moveSpeed * dt);
  }

  void _updateDelivering(double dt) {
    _stateTimer += dt;
    if (_stateTimer >= 1.0) {
      _stateTimer = 0.0;
      state = WorkerState.idle;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage != OpeningStage.management) return;

    final art = artwork;
    if (art == null) return;

    // Draw mini mower
    art.miniMower.render(
      canvas,
      position: Vector2(24, 16),
      size: Vector2(58, 44),
    );

    // Draw employee
    art.employee.getSprite(0, 0).render(
      canvas,
      position: Vector2(0, 0),
      size: Vector2(44, 62),
    );

    // Small status indicator
    if (state == WorkerState.working) {
      final pulse = (sin(_stateTimer * 8) + 1) / 2;
      canvas.drawCircle(
        Offset(size.x / 2, -8),
        5 + pulse * 2,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
  }
}
