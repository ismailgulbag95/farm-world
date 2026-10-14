import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/opening_session.dart';

void main() {
  group('Opening plot soil condition', () {
    test('starts at 80 points and applies the documented yield factor', () {
      final plantedAt = DateTime.utc(2026, 10, 11);
      final session = OpeningSession(
        initialState: OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          freeInitialSeedsCount: 1,
        ),
      );

      expect(session.soilConditionPoints, 80);
      expect(session.soilYieldMultiplier, closeTo(0.98, 0.000001));
      expect(session.plantCrop('CR02', plantedAt), isTrue);

      final readyAt = plantedAt.add(const Duration(minutes: 6));
      expect(session.cropSnapshotAt(readyAt)!.harvestYield, 980);
      expect(session.harvestCrop(readyAt), isTrue);
      expect(session.soilConditionPoints, 79);
      expect(session.lifetimeProductionEvidence, 980);
    });

    test('T02 requires P2, C2, and the owned starter field', () {
      final noP2 = OpeningSession(
        initialState: OpeningSessionState(
          farmCredits: 600,
          lifetimeProductionEvidence: 999,
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
        ),
      );
      expect(
        noP2.canPurchaseTechnology(OpeningSession.soilCareTechnologyId),
        isFalse,
      );

      final shortOnCredits = OpeningSession(
        initialState: OpeningSessionState(
          farmCredits: 599,
          lifetimeProductionEvidence: 1000,
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
        ),
      );
      expect(
        shortOnCredits.canPurchaseTechnology(
          OpeningSession.soilCareTechnologyId,
        ),
        isFalse,
      );

      final session = OpeningSession(
        initialState: OpeningSessionState(
          farmCredits: 600,
          lifetimeProductionEvidence: 1000,
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
        ),
      );
      expect(
        session.purchaseTechnology(OpeningSession.soilCareTechnologyId),
        isTrue,
      );
      expect(
        session.hasPurchasedTechnology(OpeningSession.soilCareTechnologyId),
        isTrue,
      );
      expect(session.automaticSoilCareEnabled, isTrue);
      expect(session.farmCredits, 0);
    });

    test(
      'T02 restores 3 points below 75 for 20 credits after a full harvest',
      () {
        final plantedAt = DateTime.utc(2026, 10, 11);
        final session = _ripeMaizeSession(
          plantedAt: plantedAt,
          soilPoints: 75,
          automaticSoilCareEnabled: true,
        );

        expect(
          session
              .cropSnapshotAt(plantedAt.add(const Duration(minutes: 6)))!
              .harvestYield,
          975,
        );
        expect(
          session.harvestCrop(plantedAt.add(const Duration(minutes: 6))),
          isTrue,
        );
        expect(session.soilConditionPoints, 77);
        expect(session.farmCredits, 955);
        expect(session.debt, 0);
      },
    );

    test('soil care waits without debt when the balance cannot cover it', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          soilConditionPoints: 74,
          purchasedTechnologyIds: {OpeningSession.soilCareTechnologyId},
        ),
      );

      expect(session.setAutomaticSoilCareEnabled(true), isTrue);
      expect(session.automaticSoilCareEnabled, isTrue);
      expect(session.soilConditionPoints, 74);
      expect(session.farmCredits, 0);
      expect(session.debt, 0);
    });

    test('persists soil condition and automation setting', () {
      final state = OpeningSessionState(
        stage: OpeningStage.management,
        hasOwnedInitialPlot: true,
        soilConditionPoints: 54,
        automaticSoilCareEnabled: false,
        purchasedTechnologyIds: {OpeningSession.soilCareTechnologyId},
      );

      expect(OpeningSessionState.fromJson(state.toJson()), state);
    });
  });
}

OpeningSession _ripeMaizeSession({
  required DateTime plantedAt,
  required int soilPoints,
  required bool automaticSoilCareEnabled,
}) {
  return OpeningSession(
    initialState: OpeningSessionState(
      stage: OpeningStage.management,
      hasOwnedInitialPlot: true,
      farmCredits: 0,
      lifetimeProductionEvidence: 1000,
      firstSuccessfulPlantingAt: plantedAt,
      activeCropId: 'CR02',
      activeCropPlantedAt: plantedAt,
      hasCompletedStarterTrade: true,
      soilConditionPoints: soilPoints,
      automaticSoilCareEnabled: automaticSoilCareEnabled,
      purchasedTechnologyIds: {OpeningSession.soilCareTechnologyId},
    ),
  );
}
