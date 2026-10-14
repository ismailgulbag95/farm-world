import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/opening_session.dart';

enum UpgradePadType {
  capacity,
  speed,
  range,
  miniMower,
  worker,
}

/// Interactive on-field arcade upgrade pad that players can walk into.
class UpgradePadComponent extends PositionComponent {
  UpgradePadComponent({
    required Vector2 position,
    required this.type,
    required this.session,
    required this.onPurchased,
  }) : super(
          position: position,
          size: Vector2(74, 52),
          anchor: Anchor.center,
          priority: 3,
        );

  final UpgradePadType type;
  final OpeningSession session;
  final void Function(UpgradePadType type, Vector2 pos) onPurchased;

  double _pulsePhase = 0.0;
  double _cooldown = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * 3.5;
    if (_cooldown > 0) {
      _cooldown -= dt;
    }
  }

  bool canAfford() {
    switch (type) {
      case UpgradePadType.capacity:
        return session.canBuyUpgradeCapacity;
      case UpgradePadType.speed:
        return session.canBuyUpgradeSpeed;
      case UpgradePadType.range:
        return session.canBuyUpgradeRange;
      case UpgradePadType.miniMower:
        return session.canBuyMower;
      case UpgradePadType.worker:
        return session.canHireWorker;
    }
  }

  int getCost() {
    switch (type) {
      case UpgradePadType.capacity:
        return session.upgradeCapacityCost;
      case UpgradePadType.speed:
        return session.upgradeSpeedCost;
      case UpgradePadType.range:
        return session.upgradeRangeCost;
      case UpgradePadType.miniMower:
        return OpeningSession.mowerCost;
      case UpgradePadType.worker:
        return OpeningSession.workerCost;
    }
  }

  String getLabel() {
    switch (type) {
      case UpgradePadType.capacity:
        return '🎒 +Çanta';
      case UpgradePadType.speed:
        return '⚡ +Hız';
      case UpgradePadType.range:
        return '✂️ +Bıçak';
      case UpgradePadType.miniMower:
        return '🚜 Biçici';
      case UpgradePadType.worker:
        return '👨‍🌾 İşçi';
    }
  }

  void tryInteract(Vector2 playerPosition) {
    if (_cooldown > 0 || session.stage == OpeningStage.management) return;
    if ((playerPosition - position).length <= 42.0) {
      if (canAfford()) {
        bool bought = false;
        switch (type) {
          case UpgradePadType.capacity:
            bought = session.buyUpgradeCapacity();
            break;
          case UpgradePadType.speed:
            bought = session.buyUpgradeSpeed();
            break;
          case UpgradePadType.range:
            bought = session.buyUpgradeRange();
            break;
          case UpgradePadType.miniMower:
            bought = session.buyMower();
            break;
          case UpgradePadType.worker:
            bought = session.hireWorker();
            break;
        }

        if (bought) {
          _cooldown = 0.5;
          onPurchased(type, position.clone());
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage == OpeningStage.management) return;
    if (type == UpgradePadType.miniMower && session.hasMower) return;
    if (type == UpgradePadType.worker && session.hasWorker) return;

    final affordable = canAfford();
    final cost = getCost();
    final pulse = affordable ? sin(_pulsePhase) * 2.0 : 0.0;

    final baseRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x + pulse,
      height: size.y + pulse,
    );
    final rrect = RRect.fromRectAndRadius(baseRect, const Radius.circular(10));

    final baseColor = affordable
        ? const Color(0xFF2E7D32)
        : const Color(0xFF455A64);

    final bgPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = affordable ? const Color(0xFFFFD54F) : const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = affordable ? 2.5 : 1.5;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Label
    final labelTp = TextPainter(
      text: TextSpan(
        text: getLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset((size.x - labelTp.width) / 2, (size.y - labelTp.height) / 2 - 8),
    );

    // Cost
    final costTp = TextPainter(
      text: TextSpan(
        text: '$cost ÇK',
        style: TextStyle(
          color: affordable ? const Color(0xFFFFEB3B) : const Color(0xFFCFD8DC),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    costTp.paint(
      canvas,
      Offset((size.x - costTp.width) / 2, (size.y - costTp.height) / 2 + 8),
    );
  }
}
