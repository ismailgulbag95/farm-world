import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/farm_calendar.dart';
import 'package:farm_world/game/domain/opening_session.dart';

void main() {
  group('OpeningSession - Initial state', () {
    test('starts with 0 ÇK, scythe stage, no equipment, no plot, no seeds, and no debt', () {
      final session = OpeningSession();

      expect(session.farmCredits, equals(0));
      expect(session.credits, equals(0));
      expect(session.debt, equals(0));
      expect(session.stage, equals(OpeningStage.scythe));
      expect(session.isScytheStage, isTrue);
      expect(session.isMowerStage, isFalse);
      expect(session.isManagementStage, isFalse);

      expect(session.hasMower, isFalse);
      expect(session.hasWorker, isFalse);
      expect(session.isMowerAssignedToWorker, isFalse);

      expect(session.hasOwnedInitialPlot, isFalse);
      expect(session.hasOwnedStartingPlot, isFalse);
      expect(session.freeInitialSeedsCount, equals(0));
      expect(session.hasFreeInitialSeed, isFalse);

      expect(session.isCarryingBale, isFalse);
      expect(session.carriedBaleCount, equals(0));
      expect(session.groundBaleCount, equals(0));
      expect(session.hasGroundBale, isFalse);

      expect(session.lifetimeProductionEvidence, equals(0));
      expect(session.cropDiversityCount, equals(0));

      expect(session.canMow, isTrue);
      expect(session.canPickUpBale, isFalse);
      expect(session.canSellBale, isFalse);
      expect(session.canBuyMower, isFalse);
      expect(session.canHireWorker, isFalse);
    });

    test('state object defaults match session defaults', () {
      const state = OpeningSessionState.initial;

      expect(state.farmCredits, equals(0));
      expect(state.debt, equals(0));
      expect(state.lifetimeProductionEvidence, equals(0));
      expect(state.stage, equals(OpeningStage.scythe));
      expect(state.hasMower, isFalse);
      expect(state.hasWorker, isFalse);
      expect(state.isMowerAssignedToWorker, isFalse);
      expect(state.hasOwnedInitialPlot, isFalse);
      expect(state.freeInitialSeedsCount, equals(0));
      expect(state.isCarryingBale, isFalse);
      expect(state.groundBaleCount, equals(0));
      expect(state.mowingProgressSeconds, equals(0.0));
      expect(
        state.baleMowingDurationSeconds,
        equals(OpeningSession.defaultBaleMowingDurationSeconds),
      );
    });
  });

  group('OpeningSession - Bale timing and production', () {
    test(
      'default bale mowing duration is 22.5s (midpoint of 20-25s source range)',
      () {
        expect(OpeningSession.defaultBaleMowingDurationSeconds, equals(22.5));
        final session = OpeningSession();
        expect(session.baleMowingDurationSeconds, equals(22.5));
      },
    );

    test(
      'mowing for less than 22.5s accumulates progress without producing bale',
      () {
        final session = OpeningSession();

        final result = session.mow(12.0);

        expect(result, isTrue);
        expect(session.mowingProgressSeconds, equals(12.0));
        expect(session.groundBaleCount, equals(0));
        expect(session.hasGroundBale, isFalse);
      },
    );

    test('exact 22.5s produces one ground bale and resets progress', () {
      final session = OpeningSession();

      final result = session.mow(22.5);

      expect(result, isTrue);
      expect(session.mowingProgressSeconds, equals(0.0));
      expect(session.groundBaleCount, equals(1));
      expect(session.hasGroundBale, isTrue);
    });

    test(
      'continuous mowing across multiple steps accumulates and produces bale',
      () {
        final session = OpeningSession();

        expect(session.mow(10.0), isTrue);
        expect(session.groundBaleCount, equals(0));
        expect(session.mowingProgressSeconds, equals(10.0));

        expect(session.mow(12.5), isTrue);
        expect(session.groundBaleCount, equals(1));
        expect(session.mowingProgressSeconds, equals(0.0));
      },
    );

    test('overshoot retains remainder progress after producing bale', () {
      final session = OpeningSession();

      expect(session.mow(25.0), isTrue);
      expect(session.groundBaleCount, equals(1));
      expect(session.mowingProgressSeconds, closeTo(2.5, 0.0001));
    });

    test('large single tick produces multiple ground bales if multiple durations elapse', () {
      final session = OpeningSession();

      expect(session.mow(46.0), isTrue);
      expect(session.groundBaleCount, equals(2));
      expect(session.mowingProgressSeconds, closeTo(1.0, 0.0001));
    });

    test(
      'non-positive delta time returns false and does not mutate progress',
      () {
        final session = OpeningSession();

        expect(session.mow(0.0), isFalse);
        expect(session.mow(-5.0), isFalse);
        expect(session.mowingProgressSeconds, equals(0.0));
        expect(session.groundBaleCount, equals(0));
      },
    );

    test('custom tunable bale mowing duration works deterministically', () {
      final session = OpeningSession(baleMowingDurationSeconds: 10.0);

      expect(session.mow(10.0), isTrue);
      expect(session.groundBaleCount, equals(1));
      expect(session.mowingProgressSeconds, equals(0.0));
    });

    test('zero, negative, infinite, and NaN bale durations are rejected on construction', () {
      for (final invalid in [
        0.0,
        -1.0,
        -22.5,
        double.infinity,
        -double.infinity,
        double.nan,
      ]) {
        expect(
          () => OpeningSession(baleMowingDurationSeconds: invalid),
          throwsArgumentError,
        );
        expect(
          () => OpeningSession.initial(baleMowingDurationSeconds: invalid),
          throwsArgumentError,
        );
        expect(
          () => OpeningSession(
            initialState: OpeningSessionState(
              baleMowingDurationSeconds: invalid,
            ),
          ),
          throwsArgumentError,
        );
      }
    });

    test(
      'zero, negative, infinite, and NaN mowing deltas do not mutate state',
      () {
        final session = OpeningSession();
        expect(session.mow(5.0), isTrue);
        expect(session.mowingProgressSeconds, equals(5.0));

        for (final invalid in [
          0.0,
          -5.0,
          double.infinity,
          -double.infinity,
          double.nan,
        ]) {
          expect(session.mow(invalid), isFalse);
          expect(session.advanceMowing(invalid), isFalse);
          expect(session.mowingProgressSeconds, equals(5.0));
          expect(session.groundBaleCount, equals(0));
        }
      },
    );

    test('ordinary multi-bale calls work with constant-time quotient and remainder arithmetic', () {
      final session = OpeningSession();

      // 225.0s / 22.5s = exactly 10 bales, 0.0 remainder.
      expect(session.mow(225.0), isTrue);
      expect(session.groundBaleCount, equals(10));
      expect(session.mowingProgressSeconds, equals(0.0));

      // 95.0s: 95.0 / 22.5 = 4 bales (90.0s), 5.0 remainder.
      expect(session.mow(95.0), isTrue);
      expect(session.groundBaleCount, equals(14));
      expect(session.mowingProgressSeconds, closeTo(5.0, 0.0001));
    });

    test('double.maxFinite deltaSeconds fails safely without hanging or mutating state', () {
      final session = OpeningSession();

      expect(session.mow(12.0), isTrue);
      expect(session.mowingProgressSeconds, equals(12.0));
      expect(session.groundBaleCount, equals(0));

      final stateBefore = session.state;

      expect(session.mow(double.maxFinite), isFalse);
      expect(session.state, equals(stateBefore));
      expect(session.mowingProgressSeconds, equals(12.0));
      expect(session.groundBaleCount, equals(0));

      expect(session.advanceMowing(double.maxFinite), isFalse);
      expect(session.state, equals(stateBefore));
    });

    test('tiny positive baleMowingDurationSeconds fails safely on unsafe quotient without hanging', () {
      final session = OpeningSession(baleMowingDurationSeconds: 1e-18);
      final stateBefore = session.state;

      // 100.0s / 1e-18s = 1e20 bales (cannot be represented safely in int/double).
      expect(session.mow(100.0), isFalse);
      expect(session.state, equals(stateBefore));
      expect(session.groundBaleCount, equals(0));
      expect(session.mowingProgressSeconds, equals(0.0));
    });

    test('double.maxFinite with tiny positive duration fails safely without hanging', () {
      final session = OpeningSession(baleMowingDurationSeconds: 1e-100);
      final stateBefore = session.state;

      expect(session.mow(double.maxFinite), isFalse);
      expect(session.state, equals(stateBefore));
    });

    test('overflow of updated groundBaleCount beyond max exact integer is safely rejected', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          groundBaleCount: 9007199254740990,
        ),
      );
      final stateBefore = session.state;

      // 45.0s would produce 2 bales, pushing groundBaleCount to 9007199254740992 (> maxExactInteger).
      expect(session.mow(45.0), isFalse);
      expect(session.state, equals(stateBefore));
      expect(session.groundBaleCount, equals(9007199254740990));
      expect(session.mowingProgressSeconds, equals(0.0));
    });
  });

  group('OpeningSession - Carry and mow mutual exclusion', () {
    test('carrying a bale prevents further mowing', () {
      final session = OpeningSession();

      // Produce and pick up a bale.
      session.mow(22.5);
      expect(session.groundBaleCount, equals(1));
      expect(session.pickUpBale(), isTrue);
      expect(session.isCarryingBale, isTrue);
      expect(session.canMow, isFalse);

      // Attempt to mow while carrying.
      final result = session.mow(10.0);
      expect(result, isFalse);
      expect(session.mowingProgressSeconds, equals(0.0));
      expect(session.groundBaleCount, equals(0));
    });

    test('selling carried bale re-enables mowing', () {
      final session = OpeningSession();

      session.mow(22.5);
      session.pickUpBale();
      expect(session.canMow, isFalse);

      session.enterSaleZone();
      expect(session.isCarryingBale, isFalse);
      expect(session.canMow, isTrue);

      expect(session.mow(5.0), isTrue);
      expect(session.mowingProgressSeconds, equals(5.0));
    });
  });

  group('OpeningSession - Pickup and sale mechanics', () {
    test('cannot pick up bale when no ground bale is available', () {
      final session = OpeningSession();

      expect(session.canPickUpBale, isFalse);
      expect(session.pickUpBale(), isFalse);
      expect(session.isCarryingBale, isFalse);
    });

    test('cannot pick up a second bale while already carrying one', () {
      final session = OpeningSession();

      // Produce 2 ground bales.
      session.mow(45.0);
      expect(session.groundBaleCount, equals(2));

      // Pick up first bale.
      expect(session.pickUpBale(), isTrue);
      expect(session.isCarryingBale, isTrue);
      expect(session.groundBaleCount, equals(1));

      // Try to pick up second bale.
      expect(session.canPickUpBale, isFalse);
      expect(session.pickUpBale(), isFalse);
      expect(session.groundBaleCount, equals(1));
      expect(session.isCarryingBale, isTrue);
    });

    test('entering sale zone while carrying sells bale for 30 ÇK and adds 30 lifetime evidence', () {
      final session = OpeningSession();

      session.mow(22.5);
      session.pickUpBale();

      expect(session.canSellBale, isTrue);
      final sold = session.enterSaleZone();

      expect(sold, isTrue);
      expect(session.isCarryingBale, isFalse);
      expect(session.farmCredits, equals(30));
      expect(session.lifetimeProductionEvidence, equals(30));
      expect(session.cropDiversityCount, equals(0));
    });

    test('entering sale zone while not carrying does not mutate state', () {
      final session = OpeningSession();

      expect(session.canSellBale, isFalse);
      final sold = session.enterSaleZone();

      expect(sold, isFalse);
      expect(session.farmCredits, equals(0));
      expect(session.lifetimeProductionEvidence, equals(0));
    });

    test('grass sale does not increase crop diversity count', () {
      final session = OpeningSession();

      for (var i = 0; i < 3; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }

      expect(session.farmCredits, equals(90));
      expect(session.lifetimeProductionEvidence, equals(90));
      expect(session.cropDiversityCount, equals(0));
      expect(session.cropDiversityEvidenceCount, equals(0));
    });

    test('pickup and sale are not available in management stage', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          groundBaleCount: 1,
          isCarryingBale: true,
          farmCredits: 60,
          lifetimeProductionEvidence: 60,
        ),
      );

      expect(session.canPickUpBale, isFalse);
      expect(session.pickUpBale(), isFalse);
      expect(session.groundBaleCount, equals(1));

      expect(session.canSellBale, isFalse);
      expect(session.enterSaleZone(), isFalse);
      expect(session.sellCarriedBale(), isFalse);
      expect(session.farmCredits, equals(60));
      expect(session.lifetimeProductionEvidence, equals(60));
      expect(session.isCarryingBale, isTrue);
    });
  });

  group('OpeningSession - Lifetime evidence and no debt', () {
    test('spending funds does not reduce non-spending lifetime production evidence', () {
      final session = OpeningSession();

      // Earn 90 ÇK by selling 3 bales.
      for (var i = 0; i < 3; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(90));
      expect(session.lifetimeProductionEvidence, equals(90));

      // Buy mower for 90 ÇK.
      expect(session.buyMower(), isTrue);
      expect(session.farmCredits, equals(0));
      // Lifetime evidence must remain 90!
      expect(session.lifetimeProductionEvidence, equals(90));
      expect(session.debt, equals(0));
    });

    test('debt is always zero and balance never negative', () {
      final session = OpeningSession();

      expect(session.debt, equals(0));
      expect(session.farmCredits, greaterThanOrEqualTo(0));

      // Attempt purchases without funds.
      expect(session.buyMower(), isFalse);
      expect(session.hireWorker(), isFalse);

      expect(session.debt, equals(0));
      expect(session.farmCredits, equals(0));
    });
  });

  group('OpeningSession - H01 Mower purchase gate and costs', () {
    test('mower costs exactly 90 ÇK and requires sufficient funds', () {
      expect(OpeningSession.mowerCost, equals(90));
      final session = OpeningSession();

      // Earn 60 ÇK (2 bales).
      for (var i = 0; i < 2; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(60));
      expect(session.canBuyMower, isFalse);

      // Attempt mower purchase with 60 ÇK -> fails without state mutation.
      expect(session.buyMower(), isFalse);
      expect(session.hasMower, isFalse);
      expect(session.stage, equals(OpeningStage.scythe));
      expect(session.farmCredits, equals(60));

      // Earn 3rd bale -> 90 ÇK.
      session.mow(22.5);
      session.pickUpBale();
      session.enterSaleZone();
      expect(session.farmCredits, equals(90));
      expect(session.canBuyMower, isTrue);

      // Purchase mower.
      expect(session.buyMower(), isTrue);
      expect(session.hasMower, isTrue);
      expect(session.stage, equals(OpeningStage.mower));
      expect(session.isMowerStage, isTrue);
      expect(session.farmCredits, equals(0));
    });

    test('mower purchase is a one-time upgrade', () {
      final session = OpeningSession();

      // Earn 180 ÇK (6 bales).
      for (var i = 0; i < 6; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(180));

      // First purchase succeeds.
      expect(session.buyMower(), isTrue);
      expect(session.hasMower, isTrue);
      expect(session.farmCredits, equals(90));

      // Second purchase fails without state mutation.
      expect(session.canBuyMower, isFalse);
      expect(session.buyMower(), isFalse);
      expect(session.farmCredits, equals(90));
    });
  });

  group('OpeningSession - H02 Worker hire gate, transfer, and starting plot', () {
    test('worker costs exactly 180 ÇK and strictly requires mower first', () {
      expect(OpeningSession.workerCost, equals(180));
      final session = OpeningSession();

      // Earn 180 ÇK without buying mower (6 bales).
      for (var i = 0; i < 6; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(180));
      expect(session.hasMower, isFalse);

      // Cannot hire worker without mower!
      expect(session.canHireWorker, isFalse);
      expect(session.hireWorker(), isFalse);
      expect(session.hasWorker, isFalse);
      expect(session.stage, equals(OpeningStage.scythe));
      expect(session.farmCredits, equals(180));

      // Buy mower first (90 ÇK).
      expect(session.buyMower(), isTrue);
      expect(session.hasMower, isTrue);
      expect(session.stage, equals(OpeningStage.mower));
      expect(session.farmCredits, equals(90));

      // With mower but only 90 ÇK, worker hire fails.
      expect(session.canHireWorker, isFalse);
      expect(session.hireWorker(), isFalse);
      expect(session.hasWorker, isFalse);
      expect(session.farmCredits, equals(90));

      // Earn 3 more bales (90 ÇK) -> total 180 ÇK.
      for (var i = 0; i < 3; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(180));
      expect(session.canHireWorker, isTrue);

      // Hire worker.
      expect(session.hireWorker(), isTrue);
      expect(session.hasWorker, isTrue);
      expect(session.stage, equals(OpeningStage.management));
      expect(session.isManagementStage, isTrue);
      expect(session.farmCredits, equals(0));
      expect(session.debt, equals(0));
    });

    test('hiring worker assigns mower, grants initial plot, and grants 1 free seed', () {
      final session = OpeningSession();

      // Earn 90 for mower + 180 for worker = 270 ÇK (9 bales).
      for (var i = 0; i < 9; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(270));

      session.buyMower();
      expect(session.isMowerAssignedToWorker, isFalse);
      expect(session.hasOwnedInitialPlot, isFalse);
      expect(session.freeInitialSeedsCount, equals(0));

      expect(session.hireWorker(), isTrue);

      // State post-hire:
      expect(session.stage, equals(OpeningStage.management));
      expect(session.hasWorker, isTrue);
      expect(session.isMowerAssignedToWorker, isTrue);
      expect(session.mowerAssignedToWorker, isTrue);
      expect(session.hasOwnedInitialPlot, isTrue);
      expect(session.hasOwnedStartingPlot, isTrue);
      expect(session.freeInitialSeedsCount, equals(1));
      expect(session.hasFreeInitialSeed, isTrue);

      // Total lifetime evidence is 270 ÇK (9 bales * 30 ÇK).
      expect(session.lifetimeProductionEvidence, equals(270));
    });

    test('manual mowing is disabled in management stage', () {
      final session = OpeningSession();

      for (var i = 0; i < 9; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      session.buyMower();
      session.hireWorker();

      expect(session.canMow, isFalse);
      expect(session.mow(10.0), isFalse);
      expect(session.mowingProgressSeconds, equals(0.0));
      expect(session.groundBaleCount, equals(0));
    });

    test('cannot hire worker a second time', () {
      final session = OpeningSession();

      for (var i = 0; i < 15; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      session.buyMower();
      expect(session.hireWorker(), isTrue);

      // Second hire fails.
      expect(session.canHireWorker, isFalse);
      expect(session.hireWorker(), isFalse);
    });

    test('worker transfer is blocked until carried and ground opening bales are cleared', () {
      final session = OpeningSession();

      // Accumulate 270 ÇK (9 bales) and buy mower (leaves 180 ÇK).
      for (var i = 0; i < 9; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.buyMower(), isTrue);
      expect(session.farmCredits, equals(180));
      expect(session.hasMower, isTrue);

      // Condition 1: Player has mower, 180 ÇK, but has a ground bale.
      expect(session.mow(22.5), isTrue);
      expect(session.groundBaleCount, equals(1));
      expect(session.canHireWorker, isFalse);
      expect(session.hireWorker(), isFalse);
      expect(session.hasWorker, isFalse);
      expect(session.stage, equals(OpeningStage.mower));

      // Condition 2: Player picks up the bale -> carrying bale, 0 ground bales.
      expect(session.pickUpBale(), isTrue);
      expect(session.isCarryingBale, isTrue);
      expect(session.groundBaleCount, equals(0));
      expect(session.canHireWorker, isFalse);
      expect(session.hireWorker(), isFalse);
      expect(session.hasWorker, isFalse);
      expect(session.stage, equals(OpeningStage.mower));

      // Clear carried bale by selling it.
      expect(session.enterSaleZone(), isTrue);
      expect(session.isCarryingBale, isFalse);
      expect(session.groundBaleCount, equals(0));

      // Both opening inventory conditions are now clear -> worker transfer succeeds.
      expect(session.canHireWorker, isTrue);
      expect(session.hireWorker(), isTrue);
      expect(session.hasWorker, isTrue);
      expect(session.stage, equals(OpeningStage.management));
    });

    test('normal transfer still grants plot and one seed after the bale loop is complete', () {
      final session = OpeningSession();

      // Normal flow: mow, carry, sell 9 bales to fund mower (90 ÇK) and worker (180 ÇK).
      for (var i = 0; i < 9; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      expect(session.farmCredits, equals(270));
      expect(session.groundBaleCount, equals(0));
      expect(session.isCarryingBale, isFalse);

      expect(session.buyMower(), isTrue);
      expect(session.farmCredits, equals(180));
      expect(session.hasOwnedInitialPlot, isFalse);
      expect(session.freeInitialSeedsCount, equals(0));

      // Hire worker after the manual bale loop is complete.
      expect(session.canHireWorker, isTrue);
      expect(session.hireWorker(), isTrue);

      expect(session.stage, equals(OpeningStage.management));
      expect(session.isManagementStage, isTrue);
      expect(session.hasWorker, isTrue);
      expect(session.isMowerAssignedToWorker, isTrue);
      expect(session.hasOwnedInitialPlot, isTrue);
      expect(session.hasOwnedStartingPlot, isTrue);
      expect(session.freeInitialSeedsCount, equals(1));
      expect(session.hasFreeInitialSeed, isTrue);
      expect(session.farmCredits, equals(0));
      expect(session.debt, equals(0));
    });
  });

  group('OpeningSession - Serialization and state preservation', () {
    test('roundtrips OpeningSessionState to and from json', () {
      const original = OpeningSessionState(
        farmCredits: 120,
        debt: 0,
        lifetimeProductionEvidence: 210,
        stage: OpeningStage.mower,
        hasMower: true,
        hasWorker: false,
        isMowerAssignedToWorker: false,
        hasOwnedInitialPlot: false,
        freeInitialSeedsCount: 0,
        isCarryingBale: true,
        groundBaleCount: 2,
        mowingProgressSeconds: 15.5,
        baleMowingDurationSeconds: 22.5,
      );

      final json = original.toJson();
      final restored = OpeningSessionState.fromJson(json);

      expect(restored, equals(original));
      expect(restored.farmCredits, equals(120));
      expect(restored.stage, equals(OpeningStage.mower));
      expect(restored.hasMower, isTrue);
      expect(restored.isCarryingBale, isTrue);
      expect(restored.groundBaleCount, equals(2));
      expect(restored.mowingProgressSeconds, equals(15.5));
    });

    test('roundtrips OpeningSession to and from json', () {
      final session = OpeningSession();

      // Perform a gameplay sequence:
      session.mow(22.5); // 1 ground bale
      session.mow(10.0); // 10s progress
      session.pickUpBale(); // carrying 1 bale
      session.enterSaleZone(); // sold, 30 ÇK, 30 lifetime evidence

      final json = session.toJson();
      final restored = OpeningSession.fromJson(json);

      expect(restored.farmCredits, equals(30));
      expect(restored.lifetimeProductionEvidence, equals(30));
      expect(restored.mowingProgressSeconds, equals(10.0));
      expect(restored.isCarryingBale, isFalse);
      expect(restored.groundBaleCount, equals(0));
      expect(restored.stage, equals(OpeningStage.scythe));
    });
  });

  group('OpeningSession - First successful planting calendar anchor', () {
    test('initial state starts with null firstSuccessfulPlantingAt', () {
      final session = OpeningSession();

      expect(session.firstSuccessfulPlantingAt, isNull);
      expect(session.firstSuccessfulPlantingTime, isNull);
      expect(session.hasFirstSuccessfulPlanting, isFalse);
      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
    });

    test('cannot record anchor before management takeover', () {
      final session = OpeningSession();
      final now = DateTime.utc(2026, 10, 11, 12, 0);

      // Scythe stage:
      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
      expect(session.recordFirstSuccessfulPlanting(now), isFalse);
      expect(session.firstSuccessfulPlantingAt, isNull);

      // Mower stage:
      for (var i = 0; i < 3; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      session.buyMower();
      expect(session.isMowerStage, isTrue);
      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
      expect(session.recordFirstSuccessfulPlanting(now), isFalse);
      expect(session.firstSuccessfulPlantingAt, isNull);
    });

    test('cannot record anchor without owned initial plot even in management stage', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: false,
          freeInitialSeedsCount: 1,
        ),
      );

      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
      expect(
        session.recordFirstSuccessfulPlanting(
          DateTime.utc(2026, 10, 11, 12, 0),
        ),
        isFalse,
      );
      expect(session.firstSuccessfulPlantingAt, isNull);
      expect(session.freeInitialSeedsCount, equals(1));
    });

    test('cannot record anchor without available free initial seed', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          freeInitialSeedsCount: 0,
        ),
      );

      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
      expect(
        session.recordFirstSuccessfulPlanting(
          DateTime.utc(2026, 10, 11, 12, 0),
        ),
        isFalse,
      );
      expect(session.firstSuccessfulPlantingAt, isNull);
    });

    test('successfully records anchor after management transfer, consuming free seed', () {
      final session = OpeningSession();

      // Complete opening bale loop to reach management stage:
      for (var i = 0; i < 9; i++) {
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
      }
      session.buyMower();
      session.hireWorker();

      expect(session.isManagementStage, isTrue);
      expect(session.hasOwnedInitialPlot, isTrue);
      expect(session.freeInitialSeedsCount, equals(1));
      expect(session.canRecordFirstSuccessfulPlanting, isTrue);

      final plantingTime = DateTime.utc(2026, 10, 11, 10, 15);
      final result = session.recordFirstSuccessfulPlanting(plantingTime);

      expect(result, isTrue);
      expect(session.firstSuccessfulPlantingAt, equals(plantingTime));
      expect(session.firstSuccessfulPlantingTime, equals(plantingTime));
      expect(session.hasFirstSuccessfulPlanting, isTrue);
      expect(session.freeInitialSeedsCount, equals(0));
      expect(session.hasFreeInitialSeed, isFalse);
      expect(session.canRecordFirstSuccessfulPlanting, isFalse);
    });

    test('normalizes plantedAt timestamp to UTC', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          freeInitialSeedsCount: 1,
        ),
      );

      final localTime = DateTime(2026, 10, 11, 14, 30);
      final success = session.recordFirstSuccessfulPlanting(localTime);

      expect(success, isTrue);
      expect(session.firstSuccessfulPlantingAt, isNotNull);
      expect(session.firstSuccessfulPlantingAt!.isUtc, isTrue);
      expect(session.firstSuccessfulPlantingAt, equals(localTime.toUtc()));
    });

    test(
      'is write-once: repeated calls do not reset anchor or consume resources',
      () {
        final session = OpeningSession(
          initialState: const OpeningSessionState(
            stage: OpeningStage.management,
            hasOwnedInitialPlot: true,
            freeInitialSeedsCount: 1,
          ),
        );

        final originalTime = DateTime.utc(2026, 10, 11, 12, 0);
        final laterTime = DateTime.utc(2026, 10, 11, 16, 0);

        expect(session.recordFirstSuccessfulPlanting(originalTime), isTrue);
        expect(session.firstSuccessfulPlantingAt, equals(originalTime));
        expect(session.freeInitialSeedsCount, equals(0));

        expect(session.canRecordFirstSuccessfulPlanting, isFalse);
        final repeatedResult = session.recordFirstSuccessfulPlanting(laterTime);

        expect(repeatedResult, isFalse);
        expect(session.firstSuccessfulPlantingAt, equals(originalTime));
        expect(session.freeInitialSeedsCount, equals(0));
      },
    );

    test('roundtrips firstSuccessfulPlantingAt to and from JSON', () {
      final plantingTime = DateTime.utc(2026, 10, 11, 9, 30, 45);
      final original = OpeningSessionState(
        stage: OpeningStage.management,
        hasOwnedInitialPlot: true,
        freeInitialSeedsCount: 0,
        firstSuccessfulPlantingAt: plantingTime,
      );

      final json = original.toJson();
      expect(
        json['firstSuccessfulPlantingAt'],
        equals(plantingTime.toIso8601String()),
      );

      final restored = OpeningSessionState.fromJson(json);
      expect(restored, equals(original));
      expect(restored.firstSuccessfulPlantingAt, equals(plantingTime));
      expect(restored.firstSuccessfulPlantingAt!.isUtc, isTrue);
    });

    test('maintains backward compatibility when older JSON lacks firstSuccessfulPlantingAt', () {
      final legacyJson = {
        'farmCredits': 50,
        'debt': 0,
        'lifetimeProductionEvidence': 50,
        'stage': 'management',
        'hasMower': true,
        'hasWorker': true,
        'isMowerAssignedToWorker': true,
        'hasOwnedInitialPlot': true,
        'freeInitialSeedsCount': 1,
        'isCarryingBale': false,
        'groundBaleCount': 0,
        'mowingProgressSeconds': 0.0,
        'baleMowingDurationSeconds': 22.5,
      };

      final restored = OpeningSessionState.fromJson(legacyJson);

      expect(restored.firstSuccessfulPlantingAt, isNull);
      expect(restored.hasFirstSuccessfulPlanting, isFalse);
      expect(restored.stage, equals(OpeningStage.management));
      expect(restored.hasOwnedInitialPlot, isTrue);
      expect(restored.freeInitialSeedsCount, equals(1));
    });

    test(
      'integrates with FarmCalendar elapsed contract measured from anchor',
      () {
        final session = OpeningSession(
          initialState: const OpeningSessionState(
            stage: OpeningStage.management,
            hasOwnedInitialPlot: true,
            freeInitialSeedsCount: 1,
          ),
        );

        final anchor = DateTime.utc(2026, 10, 11, 10, 0);
        expect(session.recordFirstSuccessfulPlanting(anchor), isTrue);

        final checkTime = anchor.add(const Duration(hours: 4, minutes: 30));
        final elapsed = checkTime.difference(
          session.firstSuccessfulPlantingAt!,
        );

        final calendar = FarmCalendar.resolve(elapsed);
        expect(calendar.season, equals(Season.summer));
        expect(calendar.timeInSeason, equals(Duration.zero));
      },
    );
  });

  group('OpeningSession - starter crop and trade loop', () {
    test('uses the free starter seed and harvests after six minutes', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          freeInitialSeedsCount: 1,
        ),
      );
      final plantedAt = DateTime.utc(2026, 10, 11, 10);

      expect(session.canPlantCrop(OpeningSession.starterMaizeId), isTrue);
      expect(
        session.plantCrop(OpeningSession.starterMaizeId, plantedAt),
        isTrue,
      );
      expect(session.firstSuccessfulPlantingAt, equals(plantedAt));
      expect(session.freeInitialSeedsCount, 0);
      expect(session.state.activeCropId, OpeningSession.starterMaizeId);
      expect(
        session.canHarvestCropAt(plantedAt.add(const Duration(minutes: 5))),
        isFalse,
      );

      final readyAt = plantedAt.add(OpeningSession.starterCropGrowthDuration);
      expect(session.canHarvestCropAt(readyAt), isTrue);
      expect(session.harvestCrop(readyAt), isTrue);
      expect(session.farmCredits, OpeningSession.starterTradeCredits);
      expect(session.lifetimeProductionEvidence, 980);
      expect(session.soilConditionPoints, 79);
      expect(session.hasCompletedStarterTrade, isTrue);
      expect(session.hasStarterTruck, isTrue);
      expect(session.harvestCrop(readyAt), isFalse);
    });

    test(
      'charges the next seed and applies the provisional off-season yield',
      () {
        final session = OpeningSession(
          initialState: const OpeningSessionState(
            stage: OpeningStage.management,
            hasOwnedInitialPlot: true,
            freeInitialSeedsCount: 1,
          ),
        );
        final firstPlanting = DateTime.utc(2026, 10, 11, 10);

        expect(
          session.plantCrop(OpeningSession.starterMaizeId, firstPlanting),
          isTrue,
        );
        expect(
          session.harvestCrop(
            firstPlanting.add(OpeningSession.starterCropGrowthDuration),
          ),
          isTrue,
        );

        final secondPlanting = firstPlanting.add(const Duration(minutes: 7));
        expect(session.canPlantCrop(OpeningSession.starterWheatId), isTrue);
        expect(
          session.plantCrop(OpeningSession.starterWheatId, secondPlanting),
          isTrue,
        );
        expect(session.farmCredits, 750 - OpeningSession.starterCropSeedCost);

        final readyAt = secondPlanting.add(
          OpeningSession.starterCropGrowthDuration,
        );
        expect(session.cropSnapshotAt(readyAt)?.harvestYield, 734.25);
        expect(session.harvestCrop(readyAt), isTrue);
        expect(session.farmCredits, 750 - 120 + 734);
        expect(session.lifetimeProductionEvidence, 1714);
      },
    );

    test('preserves an active crop through session JSON serialization', () {
      final plantedAt = DateTime.utc(2026, 10, 11, 10);
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          freeInitialSeedsCount: 1,
        ),
      );
      expect(
        session.plantCrop(OpeningSession.starterMaizeId, plantedAt),
        isTrue,
      );

      final restored = OpeningSession.fromJson(session.toJson());

      expect(restored.state, session.state);
      expect(restored.hasActiveCrop, isTrue);
      expect(
        restored
            .cropSnapshotAt(plantedAt.add(const Duration(minutes: 3)))
            ?.growthProgress,
        0.5,
      );
    });
  });
}
