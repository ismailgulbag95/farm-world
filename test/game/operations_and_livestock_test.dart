import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/farm_equipment.dart';
import 'package:farm_world/game/domain/livestock_and_hemisphere.dart';
import 'package:farm_world/game/domain/crop_plot.dart';
import 'package:farm_world/game/domain/delivery_contracts.dart';
import 'package:farm_world/game/domain/opening_session.dart';

void main() {
  group('Madde 4: Makine Yakıt ve Bakım Sistemi', () {
    test('EquipmentMaintenanceState tracks fuel and wear and supports refuel/service', () {
      final state = EquipmentMaintenanceState(equipmentId: 'eq_tractor_01');
      expect(state.fuelPercent, 100.0);
      expect(state.wearConditionPercent, 100.0);
      expect(state.isOutOfFuel, false);

      state.consumeOperation(fuelDrain: 25.0, wearDrain: 15.0);
      expect(state.fuelPercent, 75.0);
      expect(state.wearConditionPercent, 85.0);

      state.refuel(targetPercent: 100.0);
      expect(state.fuelPercent, 100.0);

      state.serviceOverhaul();
      expect(state.engineOilPercent, 100.0);
      expect(state.wearConditionPercent, 100.0);
    });

    test('OpeningSession refuels and services equipment using farm credits', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(farmCredits: 1000),
      );
      final maint = session.getEquipmentMaintenance('tractor_starter');
      maint.consumeOperation(fuelDrain: 40.0, wearDrain: 30.0);

      final refueled = session.refuelEquipment('tractor_starter', liters: 20);
      expect(refueled, true);
      expect(session.state.farmCredits, lessThan(1000));

      final serviced = session.serviceEquipment('tractor_starter');
      expect(serviced, true);
      expect(maint.wearConditionPercent, 100.0);
    });
  });

  group('Madde 5: Gelişmiş Hayvancılık (İnek, Koyun, Otlama & Ürünler)', () {
    test('LivestockPasture supports buying cows and sheep, grazing and producing milk & wool', () {
      final pasture = LivestockPasture();
      expect(pasture.cowCount, 0);
      expect(pasture.sheepCount, 0);

      final boughtCows = pasture.buyCows(4, 450, paymentProcessor: (_) => true);
      final boughtSheep = pasture.buySheep(6, 300, paymentProcessor: (_) => true);
      expect(boughtCows, true);
      expect(boughtSheep, true);
      expect(pasture.totalAnimals, 10);

      pasture.addFeed(100.0);
      pasture.isPastureGrazingEnabled = true;

      // Advance by 10 minutes
      pasture.update(600.0);
      expect(pasture.milkStock, greaterThan(0));
      expect(pasture.woolStock, greaterThan(0));

      final milk = pasture.collectMilk();
      final wool = pasture.collectWool();
      expect(milk, greaterThan(0));
      expect(wool, greaterThan(0));
      expect(pasture.milkStock, 0);
      expect(pasture.woolStock, 0);
    });
  });

  group('Madde 6: Gübreleme ve Kompost Üretimi', () {
    test('CompostFacility converts biomass/grass bales to organic fertilizer', () {
      final compost = CompostFacility();
      expect(compost.readyCompostBags, 0);

      final added = compost.addGrassBales(2); // 50 biomass
      expect(added, true);
      expect(compost.biomassStock, 50.0);

      // Advance by 70 seconds (produces 2 bags at 30s each)
      compost.update(70.0);
      expect(compost.readyCompostBags, greaterThanOrEqualTo(2));

      final taken = compost.takeCompost(1);
      expect(taken, 1);
      expect(compost.readyCompostBags, greaterThanOrEqualTo(1));
    });

    test('Pasture bales can be transferred to the shared compost facility', () {
      final session = OpeningSession(
        initialState: const OpeningSessionState(
          stage: OpeningStage.management,
          hasMower: true,
          hasWorker: true,
          hasOwnedInitialPlot: true,
          groundBaleCount: 2,
          plots: [
            CropPlotState(
              id: 7,
              name: 'Mera',
              isOwned: true,
              use: CropPlotUse.pasture,
              readyGrassBales: 3,
            ),
          ],
        ),
      );

      expect(session.compostableGrassBaleCount, 5);
      expect(session.addGrassToCompost(4), isTrue);
      expect(session.groundBaleCount, 0);
      expect(session.plotById(7)!.readyGrassBales, 1);
      expect(session.compostFacility.biomassStock, 100);
      expect(session.compostableGrassBaleCount, 1);
    });

    test('Applying organic compost gives plot 40% yield boost (compostYieldMultiplier = 1.40)', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(
          farmCredits: 2000,
          plots: const [
            CropPlotState(id: 1, name: 'Tarla 1', isOwned: true),
          ],
        ),
      );
      session.compostFacility.readyCompostBags = 5;

      final applied = session.applyOrganicCompost(1);
      expect(applied, true);

      final plot = session.plotById(1)!;
      expect(plot.hasOrganicCompostBonus, true);
      expect(plot.compostYieldMultiplier, 1.40);
    });
  });

  group('Madde 7: Sözleşmeli Tarım & Tüccar Siparişleri', () {
    test('Urgent merchant contract awards bonus reward upon delivery', () {
      final now = DateTime.utc(2027, 4, 1, 10, 0);
      final contract = DeliveryContract(
        id: 'merchant_urgent_test',
        itemId: 'CR01',
        targetAmount: 50,
        minimumQuality: 0.70,
        rewardCredits: 400,
        deadline: now.add(const Duration(minutes: 15)),
        merchantTitle: 'Kasaba Fırını (Acil 15 Dk)',
        bonusMultiplier: 1.50,
        urgencyMinutes: 15,
      );

      expect(contract.isUrgentMerchantOrder, true);
      expect(contract.totalRewardWithBonus, 600); // 400 * 1.50

      final manager = DeliveryContractManager(contracts: [contract]);
      final accepted = manager.accept(contract.id, now);
      expect(accepted, true);

      final reward = manager.recordDelivery(
        contractId: contract.id,
        itemId: 'CR01',
        amount: 50,
        quality: 0.85,
        now: now.add(const Duration(minutes: 5)),
      );

      expect(reward, 600); // Delivered on time with 50% bonus
    });
  });
}
