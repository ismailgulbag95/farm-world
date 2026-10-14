import 'package:farm_world/game/components/factory_component.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/domain/processing_plant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 - Processing Plants & Recipe Production Tests', () {
    test('Recipe catalog includes all brief-specified refined goods and recipes', () {
      expect(ProcessingRecipeCatalog.all.length, equals(10));

      final wheatFlour = ProcessingRecipeCatalog.wheatFlour;
      expect(wheatFlour.inputCropId, equals('CR01'));
      expect(wheatFlour.outputItemId, equals('wheat_flour'));
      expect(wheatFlour.shelfLifeExtensionFactor, lessThan(0.5)); // Significant shelf life extension

      final cornmeal = ProcessingRecipeCatalog.cornmeal;
      expect(cornmeal.inputCropId, equals('CR02'));
      expect(cornmeal.outputItemId, equals('cornmeal'));

      final sunflowerOil = ProcessingRecipeCatalog.sunflowerOil;
      expect(sunflowerOil.inputCropId, equals('CR03'));
      expect(sunflowerOil.outputItemId, equals('sunflower_oil'));

      final potatoStarch = ProcessingRecipeCatalog.potatoStarch;
      expect(potatoStarch.inputCropId, equals('CR04'));
      expect(potatoStarch.outputItemId, equals('potato_starch'));
    });

    test('Processing facility starts starved, processes batch with inputs, and yields output', () {
      final mill = ProcessingFacility(
        id: 'test_mill',
        name: 'Test Un Değirmeni',
        positionX: 0,
        positionY: 0,
        allowedRecipeIds: ['rcp_wheat_flour'],
        isUnlocked: true,
      );

      // Starved initially
      mill.update(1.0);
      expect(mill.status, equals(FacilityStatus.starvedInput));
      expect(mill.outputBuffer.isEmpty, isTrue);

      // Deposit raw wheat into input buffer
      expect(mill.depositInput('CR01', 10), isTrue);
      expect(mill.totalInputAmount, equals(10));

      // Update to trigger batch start
      mill.update(0.1);
      expect(mill.status, equals(FacilityStatus.processing));
      expect(mill.activeRecipeId, equals('rcp_wheat_flour'));
      expect(mill.totalInputAmount, equals(5)); // Consumed 5 inputs for 1 batch

      // Complete batch (duration is 15.0 seconds)
      mill.update(15.0);
      expect(mill.outputBuffer.isNotEmpty, isTrue);
      final flourLot = mill.outputBuffer.first;
      expect(flourLot.itemId, equals('wheat_flour'));
      expect(flourLot.amount, equals(5));

      // Extract output
      final extracted = mill.extractOutput(3);
      expect(extracted, equals(3));
      expect(mill.totalOutputAmount, equals(2));
    });

    test('Output buffer full blocks production until extracted', () {
      final mill = ProcessingFacility(
        id: 'test_mill_blocked',
        name: 'Tıkalı Değirmen',
        positionX: 0,
        positionY: 0,
        outputBufferCapacity: 5,
        allowedRecipeIds: ['rcp_wheat_flour'],
        isUnlocked: true,
      );

      mill.depositInput('CR01', 20);
      mill.update(0.1);
      expect(mill.status, equals(FacilityStatus.processing));

      // Finish first batch (fills 5/5 output capacity)
      mill.update(15.0);
      expect(mill.totalOutputAmount, equals(5));

      // Try next batch when output buffer is full
      mill.update(0.1);
      expect(mill.status, equals(FacilityStatus.blockedOutput));

      // Extract products to free up space
      mill.extractOutput(5);
      expect(mill.totalOutputAmount, equals(0));

      // Resume processing
      mill.update(0.1);
      expect(mill.status, equals(FacilityStatus.processing));
    });

    test('FactoryBuildingComponent animates and updates with facility status', () {
      final facility = ProcessingFacility(
        id: 'mill',
        name: 'Un Fabrikası',
        positionX: 100,
        positionY: 50,
        allowedRecipeIds: ['rcp_wheat_flour'],
      );

      final component = FactoryBuildingComponent(facility: facility);
      expect(component.position.x, equals(100));
      expect(component.position.y, equals(50));

      // Idle update
      component.update(0.1);

      // Processing update (activates chimney smoke animation)
      facility.status = FacilityStatus.processing;
      component.update(0.5);
      expect(component.facility.status, equals(FacilityStatus.processing));
    });

    test('OpeningSession integrates ProcessingPlantManager in management mode', () {
      final session = OpeningSession();
      session.addCredits(20000);
      session.buyMower();
      session.hireWorker();

      // Research building and crop technologies
      session.unlockTechnology('PR13');

      final flourMill = ProcessingFacility(
        id: 'built_mill_01',
        name: 'Un Fabrikası',
        positionX: 0,
        positionY: 0,
        allowedRecipeIds: ['rcp_wheat_flour'],
        isUnlocked: true,
      );
      session.plantManager.facilities.add(flourMill);
      expect(session.plantManager.facilities.length, equals(1));

      flourMill.depositInput('CR01', 10);
      flourMill.update(0.1);
      expect(flourMill.status, equals(FacilityStatus.processing));
    });
  });
}
