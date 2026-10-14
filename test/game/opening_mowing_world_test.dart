import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/farm_world_game.dart';
import 'package:farm_world/game/opening_mowing_world.dart';

void main() {
  group('OpeningMowingWorld - Initialization & Defaults', () {
    test(
      'initializes with scythe stage, zero credits, zero debt, and clean state',
      () {
        final session = OpeningSession();
        final world = OpeningMowingWorld(session: session);

        expect(world.session.stage, equals(OpeningStage.scythe));
        expect(world.session.farmCredits, equals(0));
        expect(world.session.debt, equals(0));
        expect(world.session.lifetimeProductionEvidence, equals(0));
        expect(world.session.isCarryingBale, isFalse);
        expect(world.session.groundBaleCount, equals(0));
        expect(world.groundBales, isEmpty);
        expect(world.cutTrailPoints, isEmpty);
        expect(world.session.canMow, isTrue);

        expect(world.player.position, equals(Vector2(0, 50)));
        expect(world.grassArea.contains(const Offset(0, 50)), isTrue);
        expect(
          world.grassArea.width * world.grassArea.height,
          equals(3 * 280 * 260),
        );
      },
    );

    test(
      'retains provided OpeningSession balance constants without mutation',
      () {
        final session = OpeningSession(baleMowingDurationSeconds: 10.0);
        final world = OpeningMowingWorld(session: session);

        expect(world.session.baleMowingDurationSeconds, equals(10.0));
        expect(world.session.farmCredits, equals(0));
      },
    );
  });

  group('OpeningMowingWorld - Movement and Mowing Gate', () {
    test('character remains stationary when input is zero', () {
      final world = OpeningMowingWorld();
      final initialPos = world.player.position.clone();

      world.update(1.0);

      expect(world.player.position, equals(initialPos));
      expect(world.player.isMoving, isFalse);
      expect(world.session.mowingProgressSeconds, equals(0.0));
      expect(world.cutTrailPoints, isEmpty);
    });

    test('character moves in direction of input vector', () {
      final world = OpeningMowingWorld();
      final initialY = world.player.position.y;

      world.setMovementInput(Vector2(0, -1)); // Moving upward
      world.update(0.5);

      expect(world.player.position.y, lessThan(initialY));
      expect(world.player.isMoving, isTrue);
    });

    test('scythe animation cycles through the four mowing phases', () {
      final player = OpeningMowingWorld().player;

      player.updateMowing(true, 0.11);
      expect(player.mowingAnimationFrame, 1);
      player.updateMowing(true, 0.11);
      expect(player.mowingAnimationFrame, 2);
      player.updateMowing(true, 0.11);
      expect(player.mowingAnimationFrame, 3);
      player.updateMowing(true, 0.11);
      expect(player.mowingAnimationFrame, 0);

      player.updateMowing(false, 0);
      expect(player.mowingAnimationFrame, 0);
    });

    test('moving over grass field accumulates mowing progress and records cut trail', () {
      final world = OpeningMowingWorld();
      expect(world.session.mowingProgressSeconds, equals(0.0));

      world.setMovementInput(Vector2(0, -1)); // Moving up into grass
      world.update(1.0);

      expect(world.session.mowingProgressSeconds, closeTo(1.0, 0.001));
      expect(world.cutTrailPoints, isNotEmpty);
    });

    test('standing still inside grass does NOT advance mowing progress', () {
      final world = OpeningMowingWorld();
      world.setMovementInput(Vector2.zero());

      world.update(2.0);

      expect(world.session.mowingProgressSeconds, equals(0.0));
      expect(world.cutTrailPoints, isEmpty);
    });

    test('moving outside grass area does NOT accumulate mowing progress', () {
      final world = OpeningMowingWorld();
      // Teleport player to the sale zone (outside grass area)
      world.player.position = Vector2(0, 150);
      expect(world.grassArea.contains(const Offset(0, 150)), isFalse);
      expect(world.saleZoneArea.contains(const Offset(0, 150)), isTrue);

      world.setMovementInput(Vector2(1, 0)); // Move sideways in sale zone
      world.update(1.0);

      expect(world.session.mowingProgressSeconds, equals(0.0));
      expect(world.cutTrailPoints, isEmpty);
    });
  });

  group('OpeningMowingWorld - Ground Bale Generation and Pickup', () {
    test('produces ground bale entity when continuous mowing reaches target duration', () {
      final session = OpeningSession(baleMowingDurationSeconds: 1.0);
      final world = OpeningMowingWorld(session: session);

      expect(world.groundBales, isEmpty);
      expect(session.groundBaleCount, equals(0));

      world.setMovementInput(Vector2(0, -1));
      // Mow for 1.0 second
      world.update(1.0);

      expect(session.groundBaleCount, equals(1));
      expect(world.groundBales.length, equals(1));
      expect(session.isCarryingBale, isFalse);

      final bale = world.groundBales.first;
      expect(bale.position, isNotNull);
    });

    test('ground bale remains on the ground until player walks onto it', () {
      final session = OpeningSession(baleMowingDurationSeconds: 1.0);
      final world = OpeningMowingWorld(session: session);

      world.setMovementInput(Vector2(0, -1));
      world.update(1.0);

      expect(world.groundBales.length, equals(1));
      final balePos = world.groundBales.first.position.clone();

      // Move player away from bale
      world.player.position = Vector2(balePos.x + 80.0, balePos.y + 80.0);
      world.setMovementInput(Vector2.zero());
      world.update(0.5);

      expect(world.groundBales.length, equals(1));
      expect(session.isCarryingBale, isFalse);
    });

    test(
      'walking onto a ground bale auto-picks it up and sets carrying state',
      () {
        final session = OpeningSession(baleMowingDurationSeconds: 1.0);
        final world = OpeningMowingWorld(session: session);

        world.setMovementInput(Vector2(0, -1));
        world.update(1.0);

        expect(world.groundBales.length, equals(1));
        final bale = world.groundBales.first;

        // Walk directly onto the bale
        world.player.position = bale.position.clone();
        world.setMovementInput(Vector2.zero());
        world.update(0.1);

        expect(session.isCarryingBale, isTrue);
        expect(session.groundBaleCount, equals(0));
        expect(world.groundBales, isEmpty);
      },
    );

    test('duplicate pickup prevention: cannot pick up a second bale while already carrying', () {
      // Create session with 2 ground bales
      final session = OpeningSession(
        initialState: const OpeningSessionState(groundBaleCount: 2),
      );
      final world = OpeningMowingWorld(session: session);

      // Spawn two bales near player
      final bale1Pos = Vector2(0, 40);
      final bale2Pos = Vector2(0, 30);
      final bale1 = GroundBaleComponent(position: bale1Pos);
      final bale2 = GroundBaleComponent(position: bale2Pos);
      world.groundBales.addAll([bale1, bale2]);

      // Move player onto bale1
      world.player.position = bale1Pos.clone();
      world.update(0.1);

      expect(session.isCarryingBale, isTrue);
      expect(session.groundBaleCount, equals(1));
      expect(world.groundBales.length, equals(1));
      expect(world.groundBales.first, equals(bale2));

      // Now move player onto bale2 while already carrying bale1
      world.player.position = bale2Pos.clone();
      world.update(0.1);

      // Bale2 must NOT be picked up
      expect(session.isCarryingBale, isTrue);
      expect(session.groundBaleCount, equals(1));
      expect(world.groundBales.length, equals(1));
      expect(world.groundBales.first, equals(bale2));
    });
  });

  group('OpeningMowingWorld - Carrying Blocks Mowing', () {
    test('carrying a bale prevents further mowing accumulation even when moving in grass', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          isCarryingBale: true,
          mowingProgressSeconds: 0.0,
        ),
      );
      final world = OpeningMowingWorld(session: session);

      expect(session.canMow, isFalse);
      final initialTrailCount = world.cutTrailPoints.length;

      world.setMovementInput(Vector2(0, -1)); // Move through grass
      world.update(2.0);

      expect(session.mowingProgressSeconds, equals(0.0));
      expect(session.groundBaleCount, equals(0));
      expect(world.cutTrailPoints.length, equals(initialTrailCount));
    });
  });

  group('OpeningMowingWorld - Sale Zone Overlap and Economy Reward', () {
    test('entering sale zone while carrying bale sells it for 30 ÇK and adds 30 lifetime evidence', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          isCarryingBale: true,
          farmCredits: 0,
          lifetimeProductionEvidence: 0,
        ),
      );
      final world = OpeningMowingWorld(session: session);

      // Move player into the sale zone
      world.player.position = Vector2(0, 150);
      expect(world.saleZoneArea.contains(const Offset(0, 150)), isTrue);

      world.update(0.1);

      expect(session.isCarryingBale, isFalse);
      expect(session.farmCredits, equals(OpeningSession.baleSaleRewardCredits));
      expect(session.farmCredits, equals(30));
      expect(session.lifetimeProductionEvidence, equals(30));
      expect(session.debt, equals(0));
      expect(session.canMow, isTrue);
    });

    test('entering sale zone without carrying bale does not trigger reward or mutate session', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          isCarryingBale: false,
          farmCredits: 0,
        ),
      );
      final world = OpeningMowingWorld(session: session);

      world.player.position = Vector2(0, 150);
      world.update(0.1);

      expect(session.farmCredits, equals(0));
      expect(session.lifetimeProductionEvidence, equals(0));
      expect(session.debt, equals(0));
      expect(session.isCarryingBale, isFalse);
    });

    test(
      'repeated updates in sale zone after sale do not multiply credits',
      () {
        final session = OpeningSession(
          initialState: const OpeningSessionState(
            isCarryingBale: true,
            farmCredits: 0,
          ),
        );
        final world = OpeningMowingWorld(session: session);

        world.player.position = Vector2(0, 150);
        world.update(0.1);
        expect(session.farmCredits, equals(30));

        // Stay in sale zone for further updates
        world.update(0.1);
        world.update(0.5);

        expect(session.farmCredits, equals(30));
        expect(session.lifetimeProductionEvidence, equals(30));
      },
    );
  });

  group('OpeningMowingWorld - Boundaries & Clamping', () {
    test('player position is clamped within world playArea boundaries', () {
      final world = OpeningMowingWorld();

      // Attempt to move player way off to the right
      world.player.position = Vector2(500, 0);
      world.setMovementInput(Vector2(1, 0));
      world.update(0.1);

      expect(world.player.position.x, lessThanOrEqualTo(world.playArea.right));

      // Attempt to move player way off the top
      world.player.position = Vector2(0, -500);
      world.setMovementInput(Vector2(0, -1));
      world.update(0.1);

      expect(world.player.position.y, greaterThanOrEqualTo(world.playArea.top));
    });
  });

  group('FarmWorldGame - Integration, HUD and Responsive Orientations', () {
    test(
      'initializes with OpeningMowingWorld world and follows player',
      () async {
        final game = FarmWorldGame();
        await game.onLoad();

        expect(game.world, isA<OpeningMowingWorld>());
        expect(game.joystick, isNotNull);
        expect(game.balanceIndicator, isNotNull);
        expect(game.world.session.stage, equals(OpeningStage.scythe));
      },
    );

    test('responsive layout: adapts smoothly to portrait and landscape viewports without clipping', () async {
      final game = FarmWorldGame();
      await game.onLoad();

      // 1. Portrait orientation (e.g. 400x800)
      game.onGameResize(Vector2(400, 800));

      expect(game.joystick.position.x, greaterThan(0));
      expect(game.joystick.position.x, lessThan(400));
      expect(game.joystick.position.y, greaterThan(0));
      expect(game.joystick.position.y, lessThan(800));

      expect(game.balanceIndicator.position.x, lessThanOrEqualTo(400));
      expect(game.balanceIndicator.position.y, greaterThanOrEqualTo(0));

      // 2. Landscape orientation (e.g. 800x400)
      game.onGameResize(Vector2(800, 400));

      expect(game.joystick.position.x, greaterThan(0));
      expect(game.joystick.position.x, lessThan(800));
      expect(game.joystick.position.y, greaterThan(0));
      expect(game.joystick.position.y, lessThan(400));

      expect(game.balanceIndicator.position.x, lessThanOrEqualTo(800));
      expect(game.balanceIndicator.position.y, greaterThanOrEqualTo(0));

      // Camera zoom is positive and within acceptable bounds in both
      expect(game.camera.viewfinder.zoom, inInclusiveRange(0.85, 1.4));
    });

    testWidgets(
      'Game widget mounts and renders playable scythe scene without empty canvas',
      (tester) async {
        final game = FarmWorldGame();

        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: GameWidget(game: game)),
            ),
          );
          await game.toBeLoaded();
        });
        game.update(0);
        await game.world.loaded;
        game.update(0);
        await tester.pump();

        expect(game.isLoaded, isTrue);
        expect(game.world.session.stage, equals(OpeningStage.scythe));
        expect(game.world.session.farmCredits, equals(0));
        expect(game.world.player.isMounted, isTrue);
        expect(game.world.grassField.isMounted, isTrue);
        expect(game.world.saleZone.isMounted, isTrue);
      },
    );
  });
}
