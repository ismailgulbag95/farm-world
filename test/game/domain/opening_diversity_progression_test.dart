import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/opening_crop_catalog.dart';
import 'package:farm_world/game/domain/opening_session.dart';

void main() {
  group('Opening crop diversification', () {
    test('requires P2, C2, and the matching family before crop access', () {
      final session = _readySession(farmCredits: 2000);

      expect(
        session.canPurchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
        isFalse,
      );
      expect(session.canPlantCrop(OpeningCropCatalog.sunflowerId), isFalse);

      expect(
        session.purchaseTechnology(
          OpeningCropCatalog.oilseedFamilyTechnologyId,
        ),
        isTrue,
      );
      expect(
        session.canPurchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
        isTrue,
      );
      expect(session.canPlantCrop(OpeningCropCatalog.sunflowerId), isFalse);

      expect(
        session.purchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
        isTrue,
      );
      expect(session.canPlantCrop(OpeningCropCatalog.sunflowerId), isTrue);
      expect(session.farmCredits, 800);
    });

    test(
      'full in-season sunflower harvest completes V1 with grain evidence',
      () {
        final session = _readySession(farmCredits: 2000);
        final plantedAt = DateTime.utc(2026, 10, 11);

        expect(
          session.purchaseTechnology(
            OpeningCropCatalog.oilseedFamilyTechnologyId,
          ),
          isTrue,
        );
        expect(
          session.purchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
          isTrue,
        );
        expect(
          session.plantCrop(OpeningCropCatalog.sunflowerId, plantedAt),
          isTrue,
        );

        final readyAt = plantedAt.add(const Duration(minutes: 15));
        expect(session.canHarvestCropAt(readyAt), isTrue);
        expect(session.harvestCrop(readyAt), isTrue);
        expect(session.state.fullHarvestedCropIds, {
          OpeningCropCatalog.maizeId,
          OpeningCropCatalog.sunflowerId,
        });
        expect(session.cropDiversityEvidenceCount, 2);
        expect(session.hasCompletedV1Diversity, isTrue);
        expect(session.farmCredits, 2219);
        expect(session.lifetimeProductionEvidence, 2617);
      },
    );

    test('off-season reduced yield does not count as a full V1 harvest', () {
      final anchor = DateTime.utc(2026, 10, 11);
      final session = _readySession(
        farmCredits: 2000,
        anchor: anchor,
        includeFullGrain: false,
      );
      final plantedAt = anchor.add(const Duration(hours: 4, minutes: 30));

      expect(
        session.purchaseTechnology(
          OpeningCropCatalog.oilseedFamilyTechnologyId,
        ),
        isTrue,
      );
      expect(
        session.purchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
        isTrue,
      );
      expect(
        session.plantCrop(OpeningCropCatalog.sunflowerId, plantedAt),
        isTrue,
      );
      final readyAt = plantedAt.add(const Duration(minutes: 15));
      expect(session.cropSnapshotAt(readyAt)!.harvestYield, 1212.75);
      expect(session.harvestCrop(readyAt), isTrue);
      expect(session.state.fullHarvestedCropIds, isEmpty);
      expect(session.hasCompletedV1Diversity, isFalse);
    });

    test('both crop-family routes remain independently purchasable', () {
      final session = _readySession(farmCredits: 3000);

      expect(
        session.purchaseTechnology(
          OpeningCropCatalog.oilseedFamilyTechnologyId,
        ),
        isTrue,
      );
      expect(
        session.purchaseTechnology(
          OpeningCropCatalog.rootTuberFamilyTechnologyId,
        ),
        isTrue,
      );
      expect(
        session.purchaseTechnology(OpeningCropCatalog.sunflowerTechnologyId),
        isTrue,
      );
      expect(
        session.purchaseTechnology(OpeningCropCatalog.potatoTechnologyId),
        isTrue,
      );
      expect(session.farmCredits, 600);
    });

    test('T15 and T16 unlock the first legume crop only after V1', () {
      final beforeV1 = _readySession(farmCredits: 2000);
      expect(
        beforeV1.canPurchaseTechnology(
          OpeningCropCatalog.legumeFamilyTechnologyId,
        ),
        isFalse,
      );

      final session = OpeningSession(
        initialState: beforeV1.state.copyWith(
          fullHarvestedCropIds: {
            OpeningCropCatalog.maizeId,
            OpeningCropCatalog.sunflowerId,
          },
        ),
      );
      expect(session.hasCompletedV1Diversity, isTrue);
      expect(
        session.canPurchaseTechnology(
          OpeningCropCatalog.legumeFamilyTechnologyId,
        ),
        isTrue,
      );
      expect(
        session.canPurchaseTechnology(OpeningCropCatalog.chickpeaTechnologyId),
        isFalse,
      );
      expect(session.canPlantCrop(OpeningCropCatalog.chickpeaId), isFalse);

      expect(
        session.purchaseTechnology(OpeningCropCatalog.legumeFamilyTechnologyId),
        isTrue,
      );
      expect(
        session.canPurchaseTechnology(OpeningCropCatalog.chickpeaTechnologyId),
        isTrue,
      );
      expect(
        session.purchaseTechnology(OpeningCropCatalog.chickpeaTechnologyId),
        isTrue,
      );
      expect(session.farmCredits, 800);
      expect(session.canPlantCrop(OpeningCropCatalog.chickpeaId), isTrue);

      final winterPlanting = DateTime.utc(
        2026,
        10,
        11,
      ).add(const Duration(hours: 13, minutes: 30));
      expect(
        session.plantCrop(OpeningCropCatalog.chickpeaId, winterPlanting),
        isTrue,
      );
      final readyAt = winterPlanting.add(const Duration(minutes: 22));
      expect(session.cropSnapshotAt(readyAt)?.isHarvestable, isTrue);
      expect(session.harvestCrop(readyAt), isTrue);
      expect(
        session.state.fullHarvestedCropIds,
        contains(OpeningCropCatalog.chickpeaId),
      );
    });

    test('persists purchased technologies and full-harvest evidence', () {
      final state = _readySession(farmCredits: 2000).state.copyWith(
        purchasedTechnologyIds: {
          OpeningCropCatalog.oilseedFamilyTechnologyId,
          OpeningCropCatalog.sunflowerTechnologyId,
        },
        fullHarvestedCropIds: {
          OpeningCropCatalog.maizeId,
          OpeningCropCatalog.sunflowerId,
        },
      );

      expect(OpeningSessionState.fromJson(state.toJson()), state);
    });
  });
}

OpeningSession _readySession({
  required int farmCredits,
  DateTime? anchor,
  bool includeFullGrain = true,
}) {
  final plantingAnchor = anchor ?? DateTime.utc(2026, 10, 11);
  return OpeningSession(
    initialState: OpeningSessionState(
      farmCredits: farmCredits,
      lifetimeProductionEvidence: OpeningCropCatalog.p2EvidenceThresholdCredits,
      stage: OpeningStage.management,
      hasOwnedInitialPlot: true,
      firstSuccessfulPlantingAt: plantingAnchor,
      hasCompletedStarterTrade: true,
      hasStarterTruck: true,
      fullHarvestedCropIds: includeFullGrain
          ? const {OpeningCropCatalog.maizeId}
          : const {},
    ),
  );
}
