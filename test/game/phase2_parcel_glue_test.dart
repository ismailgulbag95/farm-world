import 'package:farm_world/game/domain/market_and_offline.dart';
import 'package:farm_world/game/domain/opening_crop_catalog.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/domain/procedural_farm_world.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 - Parcel Glue & Multi-Plot Synchronization Tests', () {
    test('Purchasing a world map parcel creates synchronized CropPlotState with matching parcel ID', () {
      final session = OpeningSession();
      session.addCredits(10000);
      session.skipToManagement(minimumCredits: 5000);

      const parcel = WorldMapParcel(
        id: 'field_test_sync_01',
        name: 'Vadi Tarlası',
        center: WorldMapPoint(120, -80),
        width: 100,
        height: 80,
        price: 1200,
        fertility: 85,
        cropType: WorldCropType.grain,
      );

      expect(session.ownsWorldParcel(parcel.id), isFalse);
      expect(session.plotForWorldParcel(parcel.id), isNull);

      // Buy world parcel
      expect(session.buyWorldParcel(parcel), isTrue);
      expect(session.ownsWorldParcel(parcel.id), isTrue);

      // Verify CropPlotState is automatically created and linked
      final linkedPlot = session.plotForWorldParcel(parcel.id);
      expect(linkedPlot, isNotNull);
      expect(linkedPlot!.isOwned, isTrue);
      expect(linkedPlot.mapParcelId, equals(parcel.id));
      expect(linkedPlot.preferredCropFamily, equals(CropFamily.grain));
    });

    test('Cultivation, sowing and harvesting on world plot deposits output directly to warehouse', () {
      final session = OpeningSession();
      session.addCredits(20000);
      session.skipToManagement(minimumCredits: 10000);

      const parcel = WorldMapParcel(
        id: 'field_test_action_02',
        name: 'Ova Tarlası',
        center: WorldMapPoint(-100, 200),
        width: 100,
        height: 80,
        price: 900,
        fertility: 80,
        cropType: WorldCropType.grain,
      );

      session.buyWorldParcel(parcel);
      final plot = session.plotForWorldParcel(parcel.id)!;

      final now = DateTime.utc(2026, 10, 11, 10, 0);
      session.recordFirstSuccessfulPlanting(now);

      // Cultivate
      expect(session.canCultivatePlot(plot.id), isTrue);
      expect(session.cultivatePlot(plot.id, now), isTrue);
      session.advanceFarmOperations(now.add(const Duration(minutes: 10)));

      // Plant
      expect(session.canPlantCropOnPlot(plot.id, OpeningSession.starterWheatId), isTrue);
      expect(session.plantCropOnPlot(plot.id, OpeningSession.starterWheatId, now.add(const Duration(minutes: 10))), isTrue);
      final sowFinish = now.add(const Duration(minutes: 20));
      session.advanceFarmOperations(sowFinish);

      final activePlot = session.plotById(plot.id)!;
      expect(activePlot.hasActiveCrop, isTrue);

      // Harvest after growth
      final harvestTime = sowFinish.add(const Duration(minutes: 10));
      expect(session.canHarvestCropOnPlot(plot.id, harvestTime), isTrue);
      expect(session.harvestCropOnPlot(plot.id, harvestTime), isTrue);
      final checkTime = harvestTime.add(const Duration(minutes: 15));
      expect(session.advanceFarmOperations(checkTime), isTrue);

      // Output lands in warehouse
      expect(session.warehouseAmountFor(OpeningSession.starterWheatId), greaterThan(0));
    });

    test('OfflineProgressSimulator advances plot operations during offline interval', () {
      final session = OpeningSession();
      session.addCredits(20000);
      session.skipToManagement(minimumCredits: 10000);

      const parcel = WorldMapParcel(
        id: 'field_test_offline_03',
        name: 'Çevrimdışı Tarla',
        center: WorldMapPoint(50, 50),
        width: 80,
        height: 60,
        price: 800,
        fertility: 80,
        cropType: WorldCropType.grain,
      );

      session.buyWorldParcel(parcel);
      final plot = session.plotForWorldParcel(parcel.id)!;

      final startTime = DateTime.utc(2026, 10, 11, 12, 0);

      // Start preparation job
      session.cultivatePlot(plot.id, startTime);
      expect(session.plotById(plot.id)!.hasActiveJob, isTrue);

      // Simulate 1 hour offline progress
      const sim = OfflineProgressSimulator();
      final report = sim.simulateCatchUp(
        session,
        const Duration(hours: 1),
        from: startTime,
      );

      expect(report.elapsedDuration.inMinutes, equals(60));
      // Operation should be completed offline!
      final finishedPlot = session.plotById(plot.id)!;
      expect(finishedPlot.hasActiveJob, isFalse);
      expect(finishedPlot.isCultivated, isTrue);
    });
  });
}
