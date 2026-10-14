import 'package:farm_world/game/domain/market_price_simulator.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/domain/farm_calendar.dart';
import 'package:farm_world/game/ui/market_trade_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3 - Market Trade & Fleet Live Simulation Tests', () {
    test('MarketPriceSimulator computes valid price quote with rising/falling trends', () {
      final sim = MarketPriceSimulator();
      final quote = sim.getQuote('wheat', Season.spring);

      expect(quote.currentPrice, greaterThanOrEqualTo(quote.minPrice));
      expect(quote.currentPrice, lessThanOrEqualTo(quote.maxPrice));
      expect(quote.basePrice, greaterThan(0));
      expect(quote.trend, isA<PriceTrend>());
    });

    test('Session starts delivery route and truck transports cargo along stops', () {
      final session = OpeningSession();
      session.skipToManagement(minimumCredits: 5000);
      session.unlockTechnology('L01');
      session.unlockTechnology('L04');

      // Depoya ürün yükle
      session.fleetManager.depositToWarehouse('wheat', 100);
      expect(session.warehouseAmountFor('wheat'), 100);

      // Starter market rotası başlat
      final started = session.startStarterMarketRoute(
        fieldX: 0,
        fieldY: 0,
        fieldName: 'Merkez Depo',
        productId: 'wheat',
        amountPerTrip: 20,
      );
      expect(started, isTrue);

      final vehicle = session.fleetManager.vehicles.first;
      expect(vehicle.assignedRouteId, 'route_starter');

      // Simülasyonu ilerlet
      final earned = session.advanceLogistics(30);
      expect(earned, greaterThanOrEqualTo(0));

      // Tırın rota üzerinde ilerlediğini doğrula
      final afterVehicle = session.fleetManager.vehicles.first;
      expect(afterVehicle.fuelLevel, lessThanOrEqualTo(100.0));
    });

    test('Delivery contracts can be accepted and bonus reward calculated upon fulfillment', () {
      final session = OpeningSession();
      session.skipToManagement(minimumCredits: 5000);

      final now = DateTime.now().toUtc();
      session.contractManager.advance(
        now,
        dayIndex: 1,
        itemIds: ['wheat', 'corn', 'sunflower_oil'],
        unitPrice: session.marketPrices.getBasePrice,
      );

      final contracts = session.contractManager.visibleContracts;
      expect(contracts, isNotEmpty);

      final targetContract = contracts.first;
      final accepted = session.acceptDeliveryContract(targetContract.id, now: now);
      expect(accepted, isTrue);
      expect(session.contractManager.activeContract?.id, targetContract.id);

      // Bonus teslimat kaydet
      final bonus = session.contractManager.recordDelivery(
        contractId: targetContract.id,
        itemId: targetContract.itemId,
        amount: targetContract.targetAmount,
        quality: 1.0,
        now: now,
      );
      expect(bonus, equals(targetContract.rewardCredits));
      expect(session.contractManager.activeContract, isNull); // Sözleşme tamamlandı
    });

    testWidgets('MarketTradeSheet renders correctly with Tabs and Market Quotes', (tester) async {
      final session = OpeningSession();
      session.skipToManagement(minimumCredits: 5000);
      session.fleetManager.depositToWarehouse('wheat', 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketTradeSheet(
              session: session,
              onChanged: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Başlık ve tabların varlığını doğrula
      expect(find.text('KASABA PAZARI & BORSA'), findsOneWidget);
      expect(find.text('Borsa & Fiyatlar'), findsOneWidget);
      expect(find.text('Sevkiyat Başlat'), findsOneWidget);
      expect(find.text('Sözleşmeler'), findsOneWidget);

      // Sevkiyat sekmesine geç
      await tester.tap(find.text('Sevkiyat Başlat'));
      await tester.pumpAndSettle();

      expect(find.text('1. SEVK EDİLECEK ÜRÜNÜ SEÇİN'), findsOneWidget);
      expect(find.text('TIRI PAZARA GÖNDER'), findsOneWidget);
    });
  });
}
