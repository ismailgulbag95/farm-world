import 'package:farm_world/game/domain/opening_crop_catalog.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/domain/tech_tree.dart';
import 'package:farm_world/game/ui/tech_tree_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 - Tech Tree Engine and UI Overlay Tests', () {
    const engine = TechTreeEngine();

    test('TechTreeCatalog defines all core progression branches and nodes', () {
      expect(TechTreeCatalog.all.isNotEmpty, isTrue);

      final h01 = TechTreeCatalog.byId('H01');
      expect(h01, isNotNull);
      expect(h01!.branch, equals(TechBranch.labor));

      final pr01 = TechTreeCatalog.byId('PR01');
      expect(pr01, isNotNull);
      expect(pr01!.branch, equals(TechBranch.processing));
      expect(pr01.requiredEvidenceP, equals(1200));

      final l01 = TechTreeCatalog.byId('L01');
      expect(l01, isNotNull);
      expect(l01!.branch, equals(TechBranch.logistics));
    });

    test('Node status progresses from locked to unlockable and purchased', () {
      final session = OpeningSession();

      final h03 = TechTreeCatalog.byId('H03')!;

      // Locked initially because H02 and P1 evidence are not met
      expect(engine.getNodeStatus(h03, session), equals(TechNodeStatus.locked));

      // Advance session to management stage (owns mower and worker)
      session.addCredits(500);
      session.buyMower();
      session.hireWorker();

      // Still locked if lifetime evidence < 300
      expect(engine.getNodeStatus(h03, session), equals(TechNodeStatus.locked));

      // Satisfy evidence with spring starter crop
      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.plantCrop(OpeningCropCatalog.maizeId, now);
      session.harvestCrop(now.add(const Duration(minutes: 6)));
      expect(session.lifetimeProductionEvidence, greaterThanOrEqualTo(300));

      // Now unlockable!
      expect(engine.getNodeStatus(h03, session), equals(TechNodeStatus.unlockable));

      // Provide credits to afford H03 (costs 250 ÇK)
      session.addCredits(500);

      // Purchase H03
      expect(engine.canPurchaseNode('H03', session), isTrue);
      expect(engine.purchaseNode('H03', session), isTrue);

      // Now purchased!
      expect(engine.getNodeStatus(h03, session), equals(TechNodeStatus.purchased));
      expect(session.hasPurchasedTechnology('H03'), isTrue);
    });

    test('Diversity V gate locks legume tech until required distinct crop families are harvested', () {
      final session = OpeningSession();
      session.addCredits(2000);
      session.buyMower();
      session.hireWorker();
      session.unlockTechnology('T01');

      final t15 = TechTreeCatalog.byId('T15')!;
      // Requires V = 2
      expect(engine.getNodeStatus(t15, session), equals(TechNodeStatus.locked));

      // Harvest starter maize (Grain family in spring season -> V = 1)
      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.plantCrop(OpeningCropCatalog.maizeId, now);
      session.harvestCrop(now.add(const Duration(minutes: 6)));
      expect(session.cropDiversityCount, equals(1));
      expect(engine.getNodeStatus(t15, session), equals(TechNodeStatus.locked));

      // Ambardaki ürünü pazar rotasıyla satarak başlangıç ticaretini tamamla
      expect(
        session.startStarterMarketRoute(
          fieldX: 100,
          fieldY: 100,
          fieldName: 'Başlangıç Tarlası',
        ),
        isTrue,
      );
      session.advanceLogistics(20.0);
      expect(session.hasCompletedStarterTrade, isTrue);

      // Unlock and harvest sunflower (Oilseed family in spring season -> V = 2)
      session.unlockTechnology('T05');
      session.unlockTechnology('T13');
      expect(session.canPlantCrop(OpeningCropCatalog.sunflowerId), isTrue);
      session.plantCrop(OpeningCropCatalog.sunflowerId, now);
      session.harvestCrop(now.add(const Duration(minutes: 15)));
      expect(session.cropDiversityCount, equals(2));

      // Now T15 becomes unlockable!
      expect(engine.getNodeStatus(t15, session), equals(TechNodeStatus.unlockable));
    });

    testWidgets('TechTreeOverlay widget renders and filters nodes cleanly', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = OpeningSession();
      session.addCredits(1500);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: TechTreeOverlay(session: session),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and rail
      expect(find.text('ÇİFTLİK ARAŞTIRMALARI'), findsOneWidget);
      expect(find.text('TÜM DALLAR'), findsOneWidget);

      // Search for visible starter node H01
      await tester.enterText(find.byType(TextField), 'H01');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.textContaining('H01'), findsWidgets);
    });
  });
}
