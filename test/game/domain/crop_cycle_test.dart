import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/crop_cycle.dart';
import 'package:farm_world/game/domain/farm_calendar.dart';

void main() {
  group('CropDefinition - Invariants and validation', () {
    test('valid parameters construct successfully with explicit properties', () {
      final crop = CropDefinition(
        id: 'CR01',
        fullGrowthDuration: const Duration(minutes: 8),
        fullHarvestYield: 1.0,
      );

      expect(crop.id, equals('CR01'));
      expect(crop.fullGrowthDuration, equals(const Duration(minutes: 8)));
      expect(crop.fullHarvestYield, equals(1.0));
    });

    test('accepts integer yield literal and normalizes to double', () {
      final crop = CropDefinition(
        id: 'CR02',
        fullGrowthDuration: const Duration(minutes: 10),
        fullHarvestYield: 5,
      );

      expect(crop.fullHarvestYield, equals(5.0));
      expect(crop.fullHarvestYield, isA<double>());
    });

    test('rejects empty or whitespace-only crop id', () {
      final emptyCases = ['', '   ', '\t\n'];

      for (final invalidId in emptyCases) {
        expect(
          () => CropDefinition(
            id: invalidId,
            fullGrowthDuration: const Duration(minutes: 5),
            fullHarvestYield: 1.0,
          ),
          throwsArgumentError,
          reason: 'Did not throw for invalid id "$invalidId"',
        );
      }
    });

    test('rejects zero or negative fullGrowthDuration', () {
      final invalidDurations = [
        Duration.zero,
        const Duration(microseconds: -1),
        const Duration(seconds: -10),
        const Duration(hours: -1),
      ];

      for (final duration in invalidDurations) {
        expect(
          () => CropDefinition(
            id: 'CR01',
            fullGrowthDuration: duration,
            fullHarvestYield: 1.0,
          ),
          throwsArgumentError,
          reason: 'Did not throw for invalid duration $duration',
        );
      }
    });

    test('rejects zero, negative, NaN, and infinite fullHarvestYield', () {
      final invalidYields = [
        0,
        0.0,
        -0.001,
        -1.0,
        -500,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ];

      for (final invalidYield in invalidYields) {
        expect(
          () => CropDefinition(
            id: 'CR01',
            fullGrowthDuration: const Duration(minutes: 5),
            fullHarvestYield: invalidYield,
          ),
          throwsArgumentError,
          reason: 'Did not throw for invalid yield $invalidYield',
        );
      }
    });

    test('supports equality, hashCode, and toString', () {
      final a = CropDefinition(
        id: 'CR01',
        fullGrowthDuration: const Duration(minutes: 7),
        fullHarvestYield: 1.25,
      );
      final b = CropDefinition(
        id: 'CR01',
        fullGrowthDuration: const Duration(minutes: 7),
        fullHarvestYield: 1.25,
      );
      final c = CropDefinition(
        id: 'CR02',
        fullGrowthDuration: const Duration(minutes: 7),
        fullHarvestYield: 1.25,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('CR01'));
      expect(a.toString(), contains('fullGrowthDuration'));
    });
  });

  group('CropCycle - Initialization and parameter validation', () {
    final testCrop = CropDefinition(
      id: 'CR01',
      fullGrowthDuration: const Duration(minutes: 6),
      fullHarvestYield: 10.0,
    );

    test('valid parameters construct successfully with calculated properties', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 4, minutes: 30),
      );

      expect(cycle.crop, equals(testCrop));
      expect(cycle.cropDefinition, equals(testCrop));
      expect(cycle.plantedElapsed, equals(const Duration(hours: 1)));
      expect(cycle.plantedAtElapsed, equals(const Duration(hours: 1)));
      expect(cycle.plantedAt, equals(const Duration(hours: 1)));
      expect(
        cycle.harvestWindowCloseElapsed,
        equals(const Duration(hours: 4, minutes: 30)),
      );
      expect(
        cycle.harvestWindowClosesElapsed,
        equals(const Duration(hours: 4, minutes: 30)),
      );
      expect(
        cycle.harvestWindowClosesAtElapsed,
        equals(const Duration(hours: 4, minutes: 30)),
      );
      expect(
        cycle.maturityElapsed,
        equals(const Duration(hours: 1, minutes: 6)),
      );
      expect(
        cycle.harvestWindowDuration,
        equals(const Duration(hours: 3, minutes: 30)),
      );
    });

    test('CropPlanting typedef is identical to CropCycle', () {
      final CropPlanting planting = CropCycle(
        crop: testCrop,
        plantedElapsed: Duration.zero,
        harvestWindowCloseElapsed: const Duration(hours: 2),
      );

      expect(planting, isA<CropCycle>());
    });

    test('rejects negative plantedElapsed duration', () {
      final invalidPlanted = [
        const Duration(microseconds: -1),
        const Duration(seconds: -1),
        const Duration(hours: -5),
      ];

      for (final invalid in invalidPlanted) {
        expect(
          () => CropCycle(
            crop: testCrop,
            plantedElapsed: invalid,
            harvestWindowCloseElapsed: const Duration(hours: 2),
          ),
          throwsArgumentError,
          reason: 'Did not throw for negative plantedElapsed $invalid',
        );
      }
    });

    test('rejects harvestWindowCloseElapsed earlier than plantedElapsed', () {
      expect(
        () => CropCycle(
          crop: testCrop,
          plantedElapsed: const Duration(hours: 2),
          harvestWindowCloseElapsed: const Duration(hours: 1, minutes: 59),
        ),
        throwsArgumentError,
      );
      expect(
        () => CropCycle(
          crop: testCrop,
          plantedElapsed: const Duration(hours: 1),
          harvestWindowCloseElapsed: Duration.zero,
        ),
        throwsArgumentError,
      );
    });

    test('supports zero-duration close window without constructor error', () {
      expect(
        () => CropCycle(
          crop: testCrop,
          plantedElapsed: const Duration(hours: 3),
          harvestWindowCloseElapsed: const Duration(hours: 3),
        ),
        returnsNormally,
      );
    });

    test('supports equality, hashCode, and toString', () {
      final a = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 10),
        harvestWindowCloseElapsed: const Duration(minutes: 40),
      );
      final b = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 10),
        harvestWindowCloseElapsed: const Duration(minutes: 40),
      );
      final c = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 15),
        harvestWindowCloseElapsed: const Duration(minutes: 40),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('CR01'));
      expect(a.toString(), contains('plantedElapsed'));
    });
  });

  group('CropCycle.evaluate - Evaluation time rejection', () {
    final testCrop = CropDefinition(
      id: 'CR01',
      fullGrowthDuration: const Duration(minutes: 8),
      fullHarvestYield: 1.0,
    );

    test('rejects attempts to evaluate before planting elapsed time', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 2),
        harvestWindowCloseElapsed: const Duration(hours: 6),
      );

      final beforePlantedCases = [
        Duration.zero,
        const Duration(hours: 1),
        const Duration(hours: 1, minutes: 59, seconds: 59),
        const Duration(microseconds: -1),
      ];

      for (final invalidTime in beforePlantedCases) {
        expect(
          () => cycle.evaluate(invalidTime),
          throwsArgumentError,
          reason: 'Did not throw for evaluation time $invalidTime before 2h',
        );
      }
    });
  });

  group('CropCycle.evaluate - Growing progress', () {
    final testCrop = CropDefinition(
      id: 'CR01',
      fullGrowthDuration: const Duration(minutes: 10),
      fullHarvestYield: 2.0,
    );

    test('at exact planting instant (0 elapsed growth), progress is 0.0 and status is growing', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 3),
      );

      final snapshot = cycle.evaluate(const Duration(hours: 1));

      expect(snapshot.status, equals(CropCycleStatus.growing));
      expect(snapshot.isGrowing, isTrue);
      expect(snapshot.isReadyForHarvest, isFalse);
      expect(snapshot.isClosedWithPartialHarvest, isFalse);
      expect(snapshot.isHarvestable, isFalse);
      expect(snapshot.growthProgress, equals(0.0));
      expect(snapshot.progress, equals(0.0));
      expect(snapshot.harvestYield, equals(0.0));
      expect(snapshot.yield, equals(0.0));
      expect(snapshot.potentialYield, equals(0.0));
      expect(snapshot.currentElapsed, equals(const Duration(hours: 1)));
      expect(snapshot.evaluationElapsed, equals(const Duration(hours: 1)));
      expect(snapshot.crop, equals(testCrop));
      expect(snapshot.cropDefinition, equals(testCrop));
    });

    test('progress scales linearly with elapsed growth before maturity and window close', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 5),
      );

      // After 2.5 minutes of a 10-minute growth duration -> 25% progress.
      final snap25 = cycle.evaluate(const Duration(hours: 1, minutes: 2, seconds: 30));
      expect(snap25.status, equals(CropCycleStatus.growing));
      expect(snap25.growthProgress, closeTo(0.25, 0.000001));
      expect(snap25.harvestYield, equals(0.0));
      expect(snap25.potentialYield, closeTo(0.5, 0.000001));

      // After 5 minutes -> 50% progress.
      final snap50 = cycle.evaluate(const Duration(hours: 1, minutes: 5));
      expect(snap50.status, equals(CropCycleStatus.growing));
      expect(snap50.growthProgress, closeTo(0.50, 0.000001));
      expect(snap50.harvestYield, equals(0.0));
      expect(snap50.potentialYield, closeTo(1.0, 0.000001));

      // After 7.5 minutes -> 75% progress.
      final snap75 = cycle.evaluate(const Duration(hours: 1, minutes: 7, seconds: 30));
      expect(snap75.status, equals(CropCycleStatus.growing));
      expect(snap75.growthProgress, closeTo(0.75, 0.000001));
      expect(snap75.harvestYield, equals(0.0));

      // 1 microsecond before 10-minute maturity -> strictly less than 1.0 progress.
      final snapAlmost = cycle.evaluate(
        const Duration(hours: 1, minutes: 9, seconds: 59, milliseconds: 999, microseconds: 999),
      );
      expect(snapAlmost.status, equals(CropCycleStatus.growing));
      expect(snapAlmost.growthProgress, lessThan(1.0));
      expect(snapAlmost.growthProgress, closeTo(1.0, 0.00001));
      expect(snapAlmost.harvestYield, equals(0.0));
    });

    test('callable syntax behaves identically to evaluate', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: Duration.zero,
        harvestWindowCloseElapsed: const Duration(hours: 1),
      );

      final snapEval = cycle.evaluate(const Duration(minutes: 5));
      final snapCall = cycle(const Duration(minutes: 5));

      expect(snapCall, equals(snapEval));
    });
  });

  group('CropCycle.evaluate - Full maturity', () {
    final testCrop = CropDefinition(
      id: 'CR02',
      fullGrowthDuration: const Duration(minutes: 8),
      fullHarvestYield: 4.5,
    );

    test('transitions to readyForHarvest at exact maturity instant with full yield', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 20),
        harvestWindowCloseElapsed: const Duration(minutes: 50),
      );

      // Maturity at 20 + 8 = 28 minutes.
      final snapMaturity = cycle.evaluate(const Duration(minutes: 28));

      expect(snapMaturity.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapMaturity.isGrowing, isFalse);
      expect(snapMaturity.isReadyForHarvest, isTrue);
      expect(snapMaturity.isReadyForFullHarvest, isTrue);
      expect(snapMaturity.isMature, isTrue);
      expect(snapMaturity.isClosedWithPartialHarvest, isFalse);
      expect(snapMaturity.isHarvestable, isTrue);
      expect(snapMaturity.growthProgress, equals(1.0));
      expect(snapMaturity.harvestYield, equals(4.5));
      expect(snapMaturity.yield, equals(4.5));
    });

    test('evaluating past maturity within open window preserves readyForHarvest and full yield', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 20),
        harvestWindowCloseElapsed: const Duration(minutes: 50),
      );

      final snapLater = cycle.evaluate(const Duration(minutes: 35));

      expect(snapLater.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapLater.growthProgress, equals(1.0));
      expect(snapLater.harvestYield, equals(4.5));
      expect(snapLater.isHarvestable, isTrue);
    });

    test('evaluating past window close preserves full yield if crop matured before closure', () {
      // Rule: "If maturity occurs at or before closure, full yield remains available after maturity."
      // "A completed crop remains a full-yield harvest candidate."
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(minutes: 20),
        harvestWindowCloseElapsed: const Duration(minutes: 50),
      );

      // Window closed at 50 min; crop reached maturity at 28 min.
      // Evaluated at 1 hour (60 min) and 24 hours later.
      final snapPostClose = cycle.evaluate(const Duration(minutes: 60));
      final snapNextDay = cycle.evaluate(const Duration(hours: 24));

      expect(snapPostClose.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapPostClose.growthProgress, equals(1.0));
      expect(snapPostClose.harvestYield, equals(4.5));
      expect(snapPostClose.isReadyForHarvest, isTrue);

      expect(snapNextDay.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapNextDay.growthProgress, equals(1.0));
      expect(snapNextDay.harvestYield, equals(4.5));
      expect(snapNextDay.isReadyForHarvest, isTrue);
    });
  });

  group('CropCycle.evaluate - Incomplete season-close yield and post-close ratio', () {
    final testCrop = CropDefinition(
      id: 'CR01',
      fullGrowthDuration: const Duration(minutes: 10),
      fullHarvestYield: 100.0,
    );

    test('at exact season closure before maturity, yields ratio of elapsed growth / full duration', () {
      // 10-minute crop planted at 0h; harvest window closes at 6 minutes (60% growth).
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: Duration.zero,
        harvestWindowCloseElapsed: const Duration(minutes: 6),
      );

      // Evaluated while growing at 3 minutes -> 30% progress, 0 harvest yield yet.
      final snapGrowing = cycle.evaluate(const Duration(minutes: 3));
      expect(snapGrowing.status, equals(CropCycleStatus.growing));
      expect(snapGrowing.growthProgress, closeTo(0.3, 0.000001));
      expect(snapGrowing.harvestYield, equals(0.0));

      // Evaluated at exact closure instant (6 minutes).
      final snapClose = cycle.evaluate(const Duration(minutes: 6));
      expect(
        snapClose.status,
        equals(CropCycleStatus.closedWithPartialHarvest),
      );
      expect(snapClose.isGrowing, isFalse);
      expect(snapClose.isReadyForHarvest, isFalse);
      expect(snapClose.isClosedWithPartialHarvest, isTrue);
      expect(snapClose.isClosed, isTrue);
      expect(snapClose.isHarvestable, isTrue);
      expect(snapClose.growthProgress, closeTo(0.6, 0.000001));
      expect(snapClose.harvestYield, closeTo(60.0, 0.000001));
      expect(snapClose.yield, closeTo(60.0, 0.000001));
    });

    test('evaluating after the close uses the close-time ratio and does not continue growing', () {
      // Rule: "If the window closes before maturity, final progress and yield are
      // calculated at the closure instant, even if evaluation happens later."
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 2),
        harvestWindowCloseElapsed: const Duration(hours: 2, minutes: 4), // 4 mins of 10 = 40%
      );

      final postCloseInstants = [
        const Duration(hours: 2, minutes: 4), // at close
        const Duration(hours: 2, minutes: 5), // 1 min after close
        const Duration(hours: 2, minutes: 10), // at would-be maturity
        const Duration(hours: 3), // 56 mins after close
        const Duration(hours: 18), // 1 full game year later
        const Duration(days: 30), // 30 days later
      ];

      for (final t in postCloseInstants) {
        final snapshot = cycle.evaluate(t);

        expect(
          snapshot.status,
          equals(CropCycleStatus.closedWithPartialHarvest),
          reason: 'Status should be closedWithPartialHarvest at $t',
        );
        expect(
          snapshot.growthProgress,
          closeTo(0.40, 0.000001),
          reason: 'Growth progress must be frozen at closure instant 40% at $t',
        );
        expect(
          snapshot.harvestYield,
          closeTo(40.0, 0.000001),
          reason: 'Yield must be frozen at 40.0 at $t',
        );
        expect(
          snapshot.evaluationElapsed,
          equals(t),
          reason: 'Evaluation timestamp should match passed instant $t',
        );
      }
    });
  });

  group('CropCycle.evaluate - Exact maturity/close tie', () {
    final testCrop = CropDefinition(
      id: 'CR01',
      fullGrowthDuration: const Duration(minutes: 10),
      fullHarvestYield: 50.0,
    );

    test('exact maturity/close tie awards full yield at tie instant', () {
      // Rule: "At equal maturity/closure timestamps, use full yield."
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 1, minutes: 10),
      );

      // Maturity is at 1h + 10m = 1h 10m.
      // harvestWindowCloseElapsed is also 1h 10m. Exact tie!
      expect(cycle.maturityElapsed, equals(cycle.harvestWindowCloseElapsed));

      // Right before tie instant -> growing at ~99.99% progress, 0.0 harvest yield.
      final snapJustBefore = cycle.evaluate(
        const Duration(hours: 1, minutes: 9, seconds: 59, milliseconds: 999),
      );
      expect(snapJustBefore.status, equals(CropCycleStatus.growing));
      expect(snapJustBefore.growthProgress, lessThan(1.0));
      expect(snapJustBefore.harvestYield, equals(0.0));

      // At exact tie instant -> readyForHarvest, 1.0 progress, full yield.
      final snapTie = cycle.evaluate(const Duration(hours: 1, minutes: 10));
      expect(snapTie.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapTie.isReadyForHarvest, isTrue);
      expect(snapTie.isClosedWithPartialHarvest, isFalse);
      expect(snapTie.growthProgress, equals(1.0));
      expect(snapTie.harvestYield, equals(50.0));
    });

    test('exact maturity/close tie preserves full yield when evaluated long after tie', () {
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 1, minutes: 10),
      );

      final snapLater = cycle.evaluate(const Duration(hours: 5));
      expect(snapLater.status, equals(CropCycleStatus.readyForHarvest));
      expect(snapLater.growthProgress, equals(1.0));
      expect(snapLater.harvestYield, equals(50.0));
    });
  });

  group('CropCycle.evaluate - Zero-duration close window handling', () {
    final testCrop = CropDefinition(
      id: 'CR03',
      fullGrowthDuration: const Duration(minutes: 15),
      fullHarvestYield: 25.0,
    );

    test('zero-duration window (closure at planting instant) handles safely without division error', () {
      // plantedElapsed == harvestWindowCloseElapsed
      final cycle = CropCycle(
        crop: testCrop,
        plantedElapsed: const Duration(hours: 4),
        harvestWindowCloseElapsed: const Duration(hours: 4),
      );

      expect(cycle.harvestWindowDuration, equals(Duration.zero));

      // Evaluated at exact planting/closure instant.
      final snapInstant = cycle.evaluate(const Duration(hours: 4));
      expect(
        snapInstant.status,
        equals(CropCycleStatus.closedWithPartialHarvest),
      );
      expect(snapInstant.growthProgress, equals(0.0));
      expect(snapInstant.harvestYield, equals(0.0));

      // Evaluated long after zero-duration closure.
      final snapAfter = cycle.evaluate(const Duration(hours: 10));
      expect(
        snapAfter.status,
        equals(CropCycleStatus.closedWithPartialHarvest),
      );
      expect(snapAfter.growthProgress, equals(0.0));
      expect(snapAfter.harvestYield, equals(0.0));
    });
  });

  group('CropCycle - Integration with FarmCalendar and DateTime timestamps', () {
    test('works smoothly with calendar season durations from FarmCalendar', () {
      final crop = CropDefinition(
        id: 'CR01',
        fullGrowthDuration: const Duration(minutes: 10),
        fullHarvestYield: 1.0,
      );

      // In FarmCalendar, Spring ends at 4.5h (Duration(hours: 4, minutes: 30)).
      final springClose = FarmCalendar.seasonDuration;

      // Planting 5 minutes before season close.
      final latePlanting = CropCycle(
        crop: crop,
        plantedElapsed: springClose - const Duration(minutes: 5),
        harvestWindowCloseElapsed: springClose,
      );

      // Window closes at springClose, when only 5 of 10 minutes elapsed (50%).
      final snap = latePlanting.evaluate(springClose);
      expect(snap.status, equals(CropCycleStatus.closedWithPartialHarvest));
      expect(snap.growthProgress, closeTo(0.5, 0.000001));
      expect(snap.harvestYield, closeTo(0.5, 0.000001));
    });

    test('evaluateAtTimestamps resolves UTC/local timestamps identically to elapsed duration', () {
      final crop = CropDefinition(
        id: 'CR02',
        fullGrowthDuration: const Duration(minutes: 8),
        fullHarvestYield: 3.0,
      );

      final anchor = DateTime.utc(2026, 10, 11, 8, 0);
      final cycle = CropCycle(
        crop: crop,
        plantedElapsed: const Duration(hours: 1),
        harvestWindowCloseElapsed: const Duration(hours: 3),
      );

      // Evaluate 1h 4m after anchor (4 min of 8 min growth -> 50%).
      final evalTime = anchor.add(const Duration(hours: 1, minutes: 4));
      final snapshot = cycle.evaluateAtTimestamps(
        firstSuccessfulPlantingAt: anchor,
        now: evalTime,
      );

      expect(snapshot.status, equals(CropCycleStatus.growing));
      expect(snapshot.growthProgress, closeTo(0.5, 0.000001));
      expect(snapshot.evaluationElapsed, equals(const Duration(hours: 1, minutes: 4)));
    });
  });

  group('CropCycleSnapshot - Diagnostics and equality', () {
    test('supports value equality, hashCode, and toString formatting', () {
      final crop = CropDefinition(
        id: 'CR01',
        fullGrowthDuration: const Duration(minutes: 10),
        fullHarvestYield: 2.0,
      );
      final cycle = CropCycle(
        crop: crop,
        plantedElapsed: Duration.zero,
        harvestWindowCloseElapsed: const Duration(hours: 1),
      );

      final snapA = cycle.evaluate(const Duration(minutes: 5));
      final snapB = cycle.evaluate(const Duration(minutes: 5));
      final snapC = cycle.evaluate(const Duration(minutes: 6));

      expect(snapA, equals(snapB));
      expect(snapA.hashCode, equals(snapB.hashCode));
      expect(snapA, isNot(equals(snapC)));

      final desc = snapA.toString();
      expect(desc, contains('CropCycleSnapshot'));
      expect(desc, contains('CR01'));
      expect(desc, contains('growing'));
    });
  });
}
