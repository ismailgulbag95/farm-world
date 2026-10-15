import 'dart:math';

import 'farm_equipment.dart';
import 'farm_calendar.dart';
import 'opening_session.dart';
import 'market_price_simulator.dart';

export 'market_price_simulator.dart';

/// Structured summary report presented to the player upon returning from an offline absence.
class OfflineProgressReport {
  const OfflineProgressReport({
    required this.elapsedDuration,
    required this.simulatedDuration,
    required this.startingSeason,
    required this.endingSeason,
    required this.harvestedCropsCount,
    required this.processedGoodsCount,
    required this.deliveriesCount,
    required this.earnedCredits,
  });

  final Duration elapsedDuration;
  final Duration simulatedDuration;
  final Season startingSeason;
  final Season endingSeason;
  final int harvestedCropsCount;
  final int processedGoodsCount;
  final int deliveriesCount;
  final int earnedCredits;

  String get summaryText =>
      'Çevrimdışı İlerleme\n'
      'Simüle edilen süre: ${simulatedDuration.inMinutes} dk'
      '${simulatedDuration < elapsedDuration ? ' / toplam ${elapsedDuration.inMinutes} dk çevrimdışı' : ''}\n'
      '• Mevsim: ${startingSeason.name.toUpperCase()} ➔ ${endingSeason.name.toUpperCase()}\n'
      '• Hasat Edilen Ürünler: $harvestedCropsCount adet\n'
      '• İşlenen Mamuller: $processedGoodsCount birim\n'
      '• Tır Teslimatları: $deliveriesCount sefer\n'
      '• Kazanılan Gelir: +$earnedCredits ÇK';
}

/// Offline progression simulation runner using deterministic time slices.
class OfflineProgressSimulator {
  const OfflineProgressSimulator();

  OfflineProgressReport simulateCatchUp(
    OpeningSession session,
    Duration offlineDuration, {
    MarketPriceSimulator? market,
    DateTime? from,
  }) {
    if (offlineDuration <= Duration.zero ||
        session.stage != OpeningStage.management) {
      return OfflineProgressReport(
        elapsedDuration: offlineDuration,
        simulatedDuration: Duration.zero,
        startingSeason: Season.spring,
        endingSeason: Season.spring,
        harvestedCropsCount: 0,
        processedGoodsCount: 0,
        deliveriesCount: 0,
        earnedCredits: 0,
      );
    }

    final totalSeconds = min(
      offlineDuration.inSeconds.toDouble(),
      12.0 * 3600.0,
    );
    final simulationDuration = Duration(seconds: totalSeconds.toInt());
    final requestedStart =
        (from ?? DateTime.now().toUtc().subtract(offlineDuration)).toUtc();
    final skippedDuration = offlineDuration - simulationDuration;
    final simStart = requestedStart.add(
      skippedDuration.isNegative ? Duration.zero : skippedDuration,
    );
    final anchor = session.firstSuccessfulPlantingAt ?? simStart;
    final startElapsed = simStart.difference(anchor);
    final startingSeason = FarmCalendar.fromElapsed(
      elapsed: startElapsed.isNegative ? Duration.zero : startElapsed,
    ).season;

    final marketSim = market ?? session.marketPrices;
    final initialCredits = session.farmCredits;
    var harvestedCount = 0;
    var processedCount = 0;
    int initialDeliveries = session.fleetManager.vehicles.fold(
      0,
      (sum, v) => sum + v.totalDeliveriesCount,
    );

    // Slice offline time into deterministic 60-second steps (up to max 12 hours)
    const stepSeconds = 60.0;
    double accumulated = 0.0;

    DateTime simTime = simStart;

    while (accumulated < totalSeconds) {
      final dt = min(stepSeconds, totalSeconds - accumulated);
      accumulated += dt;
      simTime = simTime.add(Duration(seconds: dt.toInt()));

      // Resolve completed field operations before producers claim free space.
      final dueHarvestPlotIds = session.plots
          .where(
            (plot) =>
                plot.activeJob?.operation == FarmOperation.harvest &&
                !simTime.isBefore(plot.activeJob!.completesAt),
          )
          .map((plot) => plot.id)
          .toSet();
      session.advanceFarmOperations(simTime);
      harvestedCount += dueHarvestPlotIds.where((plotId) {
        final plot = session.plotById(plotId);
        return plot != null &&
            plot.activeJob == null &&
            plot.hasHarvestedActiveCrop;
      }).length;

      // 1. Advance logistics transport
      session.advanceLogistics(dt, now: simTime, marketOverride: marketSim);

      // 2. Advance industrial processing
      final previousOutput = session.plantManager.facilities.fold<int>(
        0,
        (sum, facility) => sum + facility.totalOutputProduced,
      );
      session.advanceProcessing(dt, now: simTime);
      final currentOutput = session.plantManager.facilities.fold<int>(
        0,
        (sum, facility) => sum + facility.totalOutputProduced,
      );
      processedCount += currentOutput - previousOutput;
      session.advanceLivestock(dt, now: simTime);
      session.advanceBuildingOperatingCosts(simTime);

      // 3. Harvest ripe plots if ready and re-plant
      for (final plot in session.plots) {
        if (!plot.isOwned) continue;
        if (plot.hasActiveCrop) {
          session.harvestCropOnPlot(plot.id, simTime);
        } else if (plot.hasHarvestedActiveCrop && !plot.hasActiveJob) {
          if (!plot.isCultivated) {
            session.cultivatePlot(plot.id, simTime);
          } else if (plot.activeCropId != null) {
            session.plantCropOnPlot(plot.id, plot.activeCropId!, simTime);
          }
        }
      }
    }

    final endCalendar = FarmCalendar.fromElapsed(
      elapsed: simTime.difference(anchor),
    );
    final endingSeason = endCalendar.season;

    final finalDeliveries = session.fleetManager.vehicles.fold(
      0,
      (sum, v) => sum + v.totalDeliveriesCount,
    );
    final netDeliveries = max(0, finalDeliveries - initialDeliveries);
    final netCredits = max(0, session.farmCredits - initialCredits);

    return OfflineProgressReport(
      elapsedDuration: offlineDuration,
      simulatedDuration: simulationDuration,
      startingSeason: startingSeason,
      endingSeason: endingSeason,
      harvestedCropsCount: harvestedCount,
      processedGoodsCount: processedCount,
      deliveriesCount: netDeliveries,
      earnedCredits: netCredits,
    );
  }
}
