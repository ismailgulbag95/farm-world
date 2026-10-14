import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farm_world/game/domain/opening_crop_catalog.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/farm_world_game.dart';
import 'package:farm_world/main.dart';

void main() {
  group('FarmWorldApp - App Bootstrap & Session Integration', () {
    testWidgets('mounts the playable scene with an injected restored session', (
      tester,
    ) async {
      final restoredSession = OpeningSession(
        initialState: const OpeningSessionState(
          farmCredits: 180,
          stage: OpeningStage.mower,
          hasMower: true,
          groundBaleCount: 2,
        ),
      );
      final app = FarmWorldApp(session: restoredSession);

      await tester.runAsync(() async {
        await tester.pumpWidget(app);
        await tester
            .state<FarmWorldAppState>(find.byType(FarmWorldApp))
            .game
            .toBeLoaded();
      });
      await tester.pump();

      expect(find.byType(FarmWorldApp), findsOneWidget);
      expect(find.byType(GameWidget<FarmWorldGame>), findsOneWidget);

      final state = tester.state<FarmWorldAppState>(find.byType(FarmWorldApp));
      expect(state.session.farmCredits, equals(180));
      expect(state.session.hasMower, isTrue);
      expect(state.session.groundBaleCount, equals(2));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'renders opening HUD in portrait and landscape without layout errors',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;

        await tester.runAsync(() async {
          await tester.pumpWidget(FarmWorldApp(session: OpeningSession()));
          await tester
              .state<FarmWorldAppState>(find.byType(FarmWorldApp))
              .game
              .toBeLoaded();
        });
        await tester.pump();
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(800, 400);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('offers the localized chickpea branch after V1', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;

      final session = OpeningSession(
        initialState: OpeningSessionState(
          farmCredits: 2000,
          lifetimeProductionEvidence:
              OpeningCropCatalog.p2EvidenceThresholdCredits,
          stage: OpeningStage.management,
          hasOwnedInitialPlot: true,
          hasCompletedStarterTrade: true,
          firstSuccessfulPlantingAt: DateTime.utc(2026, 10, 11),
          fullHarvestedCropIds: const {
            OpeningCropCatalog.maizeId,
            OpeningCropCatalog.sunflowerId,
          },
        ),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(FarmWorldApp(session: session));
        await tester
            .state<FarmWorldAppState>(find.byType(FarmWorldApp))
            .game
            .toBeLoaded();
      });
      await tester.pump();

      expect(find.text('Unlock legume family'), findsOneWidget);
      await tester.ensureVisible(find.text('Unlock legume family'));
      await tester.tap(find.text('Unlock legume family'));
      await tester.pump();
      expect(find.text('Unlock chickpea crop'), findsOneWidget);

      await tester.ensureVisible(find.text('Unlock chickpea crop'));
      await tester.tap(find.text('Unlock chickpea crop'));
      await tester.pump();
      expect(find.text('Plant chickpeas'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
