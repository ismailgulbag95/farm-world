import 'package:farm_world/game/components/coop_component.dart';
import 'package:farm_world/game/domain/farm_calendar.dart';
import 'package:farm_world/game/domain/livestock_and_hemisphere.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7 - Livestock Poultry & Southern Hemisphere Expansion Tests', () {
    test('ChickenCoop consumes feed and produces fresh eggs deterministically', () {
      final coop = ChickenCoop(
        chickenCount: 10,
        feedStock: 20.0,
        eggStock: 0,
      );

      // Advance 10 minutes (600 seconds)
      // Consumption: 10 hens * 0.10 * 10 mins = 10.0 feed
      // Production: 10 hens * 0.25 * 10 mins = 25 eggs
      coop.update(600.0);

      expect(coop.feedStock, closeTo(10.0, 0.1));
      expect(coop.eggStock, equals(25));

      // Collect eggs
      final collected = coop.collectEggs();
      expect(collected, equals(25));
      expect(coop.eggStock, equals(0));
    });

    test('Feed starvation pauses egg production safely without animal loss', () {
      final coop = ChickenCoop(
        chickenCount: 10,
        feedStock: 0.0, // No feed
        eggStock: 0,
      );

      coop.update(300.0);

      expect(coop.isFeedStarved, isTrue);
      expect(coop.eggStock, equals(0)); // Paused
      expect(coop.chickenCount, equals(10)); // Hens preserved safely!

      // Add feed to resume
      expect(coop.addFeed(50.0), isTrue);
      expect(coop.isFeedStarved, isFalse);

      coop.update(300.0);
      expect(coop.eggStock, greaterThan(0));
    });

    test('Multi-Hemisphere territory manager computes 9-hour seasonal phase offset', () {
      final territory = TerritoryExpansionManager();
      expect(territory.regions.length, equals(2));

      final northern = territory.regions.firstWhere((r) => r.id == 'reg_northern_temperate');
      final southern = territory.regions.firstWhere((r) => r.id == 'reg_southern_valley');

      expect(northern.isUnlocked, isTrue);
      expect(southern.isUnlocked, isFalse);

      // At start (0 hours): Northern is Spring, Southern is Autumn (9-hour shift)
      final seasonNorth = northern.currentSeasonAt(Duration.zero);
      final seasonSouth = southern.currentSeasonAt(Duration.zero);
      expect(seasonNorth, equals(Season.spring));
      expect(seasonSouth, equals(Season.autumn));

      // Unlock Southern Hemisphere with funds
      expect(territory.canUnlockSouthernHemisphere(3000), isFalse); // Cost is 3500
      expect(territory.canUnlockSouthernHemisphere(4000), isTrue);

      expect(
        territory.unlockSouthernHemisphere(pay: (cost) => true),
        isTrue,
      );
      expect(territory.regions.firstWhere((r) => r.id == 'reg_southern_valley').isUnlocked, isTrue);
    });

    test('ChickenCoopComponent renders and integrates with OpeningSession', () {
      final session = OpeningSession();
      session.addCredits(2000);
      session.buyMower();
      session.hireWorker();

      final coopComp = ChickenCoopComponent(
        coop: session.coop,
        position: Vector2(-310, -60),
      );

      expect(coopComp.position.x, equals(-310));
      expect(coopComp.position.y, equals(-60));

      // Advance simulation step
      session.advanceLivestock(60.0);
      expect(session.coop.feedStock, lessThan(50.0));
    });
  });
}
