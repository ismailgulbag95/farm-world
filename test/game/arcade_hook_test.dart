import 'package:farm_world/game/components/backpack_stack.dart';
import 'package:farm_world/game/components/floating_text.dart';
import 'package:farm_world/game/components/grass_particle.dart';
import 'package:farm_world/game/components/upgrade_station.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/opening_mowing_world.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1 - Grass Cutter Arcade Hook Tests', () {
    test('Backpack stack accumulates bales and tracks capacity', () {
      final session = OpeningSession();
      expect(session.carriedBalesCount, equals(0));
      expect(session.backpackCapacity, equals(10));
      expect(session.isBackpackFull, isFalse);

      for (int i = 0; i < 10; i++) {
        expect(session.collectBaleDirectlyToBackpack(), isTrue);
      }

      expect(session.carriedBalesCount, equals(10));
      expect(session.isBackpackFull, isTrue);
      expect(session.isCarryingBale, isTrue);

      // Beyond capacity should reject direct collection
      expect(session.collectBaleDirectlyToBackpack(), isFalse);
    });

    test('Rapid sale stream sells carried bales and adds credits and evidence', () {
      final session = OpeningSession();
      for (int i = 0; i < 5; i++) {
        session.collectBaleDirectlyToBackpack();
      }

      expect(session.carriedBalesCount, equals(5));
      expect(session.farmCredits, equals(0));

      final soldCount = session.sellAllCarriedBales();
      expect(soldCount, equals(5));
      expect(session.carriedBalesCount, equals(0));
      expect(session.isCarryingBale, isFalse);
      expect(session.farmCredits, equals(150));
      expect(session.lifetimeProductionEvidence, equals(150));
    });

    test('Arcade upgrades increase stats and spend credits correctly', () {
      final session = OpeningSession();
      // Give initial credits
      for (int i = 0; i < 10; i++) {
        session.collectBaleDirectlyToBackpack();
      }
      session.sellAllCarriedBales(); // 300 credits

      expect(session.capacityLevel, equals(0));
      expect(session.backpackCapacity, equals(10));

      expect(session.canBuyUpgradeCapacity, isTrue);
      expect(session.buyUpgradeCapacity(), isTrue);
      expect(session.capacityLevel, equals(1));
      expect(session.backpackCapacity, equals(20));

      expect(session.speedLevel, equals(0));
      expect(session.canBuyUpgradeSpeed, isTrue);
      expect(session.buyUpgradeSpeed(), isTrue);
      expect(session.speedLevel, equals(1));
      expect(session.movementSpeedMultiplier, closeTo(1.2, 0.001));

      expect(session.rangeLevel, equals(0));
      expect(session.canBuyUpgradeRange, isTrue);
      expect(session.buyUpgradeRange(), isTrue);
      expect(session.rangeLevel, equals(1));
      expect(session.cuttingRangeMultiplier, closeTo(1.25, 0.001));
    });

    test('Upgrade pads spawn in world and interact with player position', () {
      final world = OpeningMowingWorld();
      expect(world.upgradePads.length, equals(5));

      // Player starts at (0, 50), pads are at y = 150
      final capacityPad = world.upgradePads.firstWhere(
        (p) => p.type == UpgradePadType.capacity,
      );

      // Give credits
      for (int i = 0; i < 5; i++) {
        world.session.collectBaleDirectlyToBackpack();
      }
      world.session.sellAllCarriedBales();

      // Teleport player near capacity pad
      capacityPad.tryInteract(capacityPad.position);
      expect(world.session.capacityLevel, equals(1));
      expect(world.session.backpackCapacity, equals(20));
    });

    test('Juice components instantiate without errors', () {
      final particle = GrassParticleComponent(
        position: Vector2.zero(),
        velocity: Vector2(10, -50),
      );
      particle.update(0.05);
      expect(particle.position.y, lessThan(0));

      final text = FloatingTextComponent(
        position: Vector2.zero(),
        text: '+30 ÇK',
      );
      text.update(0.1);
      expect(text.position.y, lessThan(0));

      final stack = BackpackStackComponent(session: OpeningSession());
      stack.triggerStepWobble(1.0);
      stack.update(0.1);
      expect(stack.isMounted, isFalse);
    });

    test('skipToManagement skips scythe mini-game and activates farm management mode', () {
      final session = OpeningSession();
      expect(session.stage, OpeningStage.scythe);
      expect(session.hasWorker, isFalse);
      expect(session.hasOwnedInitialPlot, isFalse);

      session.skipToManagement();

      expect(session.stage, OpeningStage.management);
      expect(session.hasMower, isTrue);
      expect(session.hasWorker, isTrue);
      expect(session.isMowerAssignedToWorker, isTrue);
      expect(session.hasOwnedInitialPlot, isTrue);
      expect(session.freeInitialSeedsCount, greaterThanOrEqualTo(1));
      expect(session.farmCredits, greaterThanOrEqualTo(250));
      expect(session.isCarryingBale, isFalse);
      expect(session.carriedBalesCount, 0);
      expect(session.groundBaleCount, 0);
    });
  });
}
