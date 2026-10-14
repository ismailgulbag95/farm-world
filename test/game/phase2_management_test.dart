import 'package:farm_world/game/components/crop_plot_component.dart';
import 'package:farm_world/game/components/worker_ai.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/opening_mowing_world.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 - Farm Management & Multi-Plot Expansion Tests', () {
    test('Default expansion plots are initialized with correct costs and states', () {
      final session = OpeningSession();
      final plots = session.plots;

      expect(plots.length, equals(4));
      // Starter plot
      expect(plots[0].id, equals(0));
      expect(plots[0].isOwned, isFalse);

      // North plot
      expect(plots[1].id, equals(1));
      expect(plots[1].isOwned, isFalse);
      expect(plots[1].purchaseCostCredits, equals(1000));

      // West plot
      expect(plots[2].id, equals(2));
      expect(plots[2].isOwned, isFalse);
      expect(plots[2].purchaseCostCredits, equals(1120));

      // South plot
      expect(plots[3].id, equals(3));
      expect(plots[3].isOwned, isFalse);
      expect(plots[3].purchaseCostCredits, equals(1250));
    });

    test('Purchasing plots validates management stage and credit balance', () {
      final session = OpeningSession();

      // Cannot buy plot before management stage
      expect(session.canBuyPlot(1), isFalse);

      session.addCredits(500);

      // Transition to management
      expect(session.buyMower(), isTrue);
      expect(session.hireWorker(), isTrue);
      expect(session.stage, equals(OpeningStage.management));

      // Cannot afford 1000 credits initially
      expect(session.canBuyPlot(1), isFalse);

      // Add credits for plot
      session.addCredits(1500);
      expect(session.farmCredits, greaterThanOrEqualTo(1000));

      expect(session.canBuyPlot(1), isTrue);
      expect(session.buyPlot(1), isTrue);
      expect(session.plots.firstWhere((p) => p.id == 1).isOwned, isTrue);

      // Cannot re-purchase already owned plot
      expect(session.canBuyPlot(1), isFalse);
    });

    test('Planting and harvesting on expansion plots cycles independently', () {
      final session = OpeningSession();
      session.addCredits(2000);

      expect(session.buyMower(), isTrue);
      expect(session.hireWorker(), isTrue);
      expect(session.buyPlot(1), isTrue);

      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.recordFirstSuccessfulPlanting(now);

      expect(session.canPlantCropOnPlot(1, OpeningSession.starterWheatId), isTrue);
      expect(session.plantCropOnPlot(1, OpeningSession.starterWheatId, now), isTrue);

      final plot1 = session.plots.firstWhere((p) => p.id == 1);
      expect(plot1.hasActiveCrop, isTrue);
      expect(plot1.activeCropId, equals(OpeningSession.starterWheatId));

      // Cannot harvest immediately
      expect(session.harvestCropOnPlot(1, now), isFalse);

      // Harvest after 6 minutes
      final harvestTime = now.add(const Duration(minutes: 6));
      expect(session.harvestCropOnPlot(1, harvestTime), isTrue);

      final harvestedPlot1 = session.plots.firstWhere((p) => p.id == 1);
      expect(harvestedPlot1.hasHarvestedActiveCrop, isTrue);
      expect(harvestedPlot1.soilConditionPoints, equals(79));
    });

    test('Autonomous worker state machine steps through tasks', () {
      final session = OpeningSession();
      session.addCredits(1000);

      expect(session.buyMower(), isTrue);
      expect(session.hireWorker(), isTrue);

      final worker = AutonomousWorkerComponent(
        position: Vector2.zero(),
        session: session,
        barnPosition: Vector2(100, 100),
      );

      expect(worker.state, equals(WorkerState.idle));

      // Update worker while plots exist to trigger moving to plot
      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.recordFirstSuccessfulPlanting(now);

      // Update idle timer (threshold is 1.5s)
      worker.update(2.0);
      expect(worker.state, equals(WorkerState.movingToPlot));

      // Simulate movement step
      worker.update(1.0);
      expect(worker.position.length, greaterThan(0));
    });

    test('Interactive crop plot renders and handles tap callbacks', () {
      final session = OpeningSession();
      final selectedNotifier = ValueNotifier<ManagementMapSelection>(
        ManagementMapSelection.starterPlot,
      );

      final plotComp = InteractiveCropPlotComponent(
        plotId: 1,
        position: Vector2.zero(),
        size: Vector2(100, 100),
        session: session,
        selectedMapItem: selectedNotifier,
      );

      expect(plotComp.plotId, equals(1));
      expect(plotComp.plot.isOwned, isFalse);
    });
  });
}
