import 'package:farm_world/game/domain/farm_calendar.dart';
import 'package:farm_world/game/domain/market_and_offline.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 - Dynamic Market, 18-Hour Calendar & Offline Progress Tests', () {
    test('MarketPriceSimulator calculates seasonal demand and preserves price floors', () {
      final market = MarketPriceSimulator();

      final baseWheat = market.getBasePrice('CR01');
      expect(baseWheat, greaterThan(0));

      // In off-season (summer for winter wheat), scarcity yields higher price
      final summerPrice = market.calculatePrice('CR01', Season.summer);
      final winterPrice = market.calculatePrice('CR01', Season.winter);
      expect(summerPrice, greaterThan(winterPrice));

      // Quote check before market flooding
      final quote = market.getQuote('CR01', Season.summer);
      expect(quote.minPrice, equals((baseWheat * 0.60).round()));
      expect(quote.trend, equals(PriceTrend.rising));

      // Test floor protection under heavy supply
      market.recordSale('CR01', 5000);
      final floodedPrice = market.calculatePrice('CR01', Season.winter);
      final minAllowed = (baseWheat * 0.60).round();
      expect(floodedPrice, greaterThanOrEqualTo(minAllowed));
    });

    test('18-Hour FarmCalendar cycles through all 4 seasons accurately', () {
      // 0h: Spring
      final c0 = FarmCalendar(elapsed: Duration.zero);
      expect(c0.season, equals(Season.spring));

      // 4.5h: Summer
      final c4_5 = FarmCalendar(elapsed: const Duration(minutes: 270));
      expect(c4_5.season, equals(Season.summer));

      // 9h: Autumn
      final c9 = FarmCalendar(elapsed: const Duration(minutes: 540));
      expect(c9.season, equals(Season.autumn));

      // 13.5h: Winter
      final c13_5 = FarmCalendar(elapsed: const Duration(minutes: 810));
      expect(c13_5.season, equals(Season.winter));

      // 18h: Full cycle back to Spring
      final c18 = FarmCalendar(elapsed: const Duration(minutes: 1080));
      expect(c18.season, equals(Season.spring));
    });

    test('OfflineProgressSimulator computes deterministic deliveries and crop cycles', () {
      final session = OpeningSession();
      session.addCredits(5000);
      session.buyMower();
      session.hireWorker();

      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.recordFirstSuccessfulPlanting(now);

      // Buy expansion plot 1 and plant starter wheat
      session.buyPlot(1);
      session.plantCropOnPlot(1, OpeningSession.starterWheatId, now);

      // Setup fleet
      session.fleetManager.initializeStarterFleet();
      session.fleetManager.depositToWarehouse('CR01', 100);

      // Simulate 1 hour of offline progress
      const sim = OfflineProgressSimulator();
      final report = sim.simulateCatchUp(
        session,
        const Duration(hours: 1),
      );

      expect(report.elapsedDuration.inMinutes, equals(60));
      expect(report.deliveriesCount, greaterThan(0));
      expect(report.earnedCredits, greaterThan(0));
      expect(report.summaryText, contains('Çevrimdışı İlerleme'));
      expect(report.summaryText, contains('Tır Teslimatları'));
    });
  });
}
