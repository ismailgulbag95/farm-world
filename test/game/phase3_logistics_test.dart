import 'package:farm_world/game/components/route_visual_component.dart';
import 'package:farm_world/game/components/truck_component.dart';
import 'package:farm_world/game/domain/logistics_fleet.dart';
import 'package:farm_world/game/domain/opening_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3 - Logistics Fleet & Transport System Tests', () {
    test('TruckType catalog has correct capacities, speeds and trade-offs', () {
      expect(TruckType.starter.capacity, equals(20));
      expect(TruckType.starter.speed, equals(75.0));

      expect(TruckType.lightExpress.capacity, equals(15));
      expect(TruckType.lightExpress.speed, equals(120.0));
      expect(TruckType.lightExpress.purchaseCostCredits, equals(850));

      expect(TruckType.heavyHauler.capacity, equals(60));
      expect(TruckType.heavyHauler.speed, equals(55.0));
      expect(TruckType.heavyHauler.purchaseCostCredits, equals(1600));

      expect(TruckType.refrigerated.spoilageProtectionMultiplier, lessThan(0.5));
      expect(TruckType.refrigerated.purchaseCostCredits, equals(2200));
    });

    test('Initial fleet initializes when starter truck is awarded', () {
      final session = OpeningSession();
      session.addCredits(2000);
      session.buyMower();
      session.hireWorker();

      expect(session.fleetManager.vehicles.isEmpty, isTrue);

      final now = DateTime.utc(2026, 10, 11, 12, 0);
      session.plantCrop(OpeningSession.starterWheatId, now);

      // Harvest starter crop -> awards starter truck and initializes fleet
      final harvestTime = now.add(const Duration(minutes: 6));
      expect(session.harvestCrop(harvestTime), isTrue);
      expect(session.hasStarterTruck, isTrue);

      expect(session.fleetManager.vehicles.length, equals(1));
      final truck = session.fleetManager.vehicles.first;
      expect(truck.truckType, equals(TruckType.starter));
      expect(truck.assignedRouteId, equals('route_starter'));
      expect(session.fleetManager.warehouseStock.isNotEmpty, isTrue);
    });

    test('Multi-stop route simulation loads cargo from warehouse and sells at market', () {
      final manager = LogisticsFleetManager();
      manager.initializeStarterFleet();
      manager.depositToWarehouse('CR01', 50);

      expect(manager.totalWarehouseAmount, equals(50));
      final truck = manager.vehicles.first;
      expect(truck.hasCargo, isFalse);

      // Travel to market stop first (first leg)
      manager.update(5.0);
      expect(manager.vehicles.first.currentStopIndex, equals(1));

      // Travel back to starter plot / warehouse (loads cargo!)
      manager.update(5.0);
      final loadedTruck = manager.vehicles.first;
      expect(loadedTruck.hasCargo, isTrue);
      expect(loadedTruck.cargoCropId, equals('CR01'));
      expect(loadedTruck.cargoAmount, equals(20)); // Starter capacity is 20
      expect(manager.totalWarehouseAmount, equals(30)); // 50 - 20 = 30 left

      // Advance route to market stop (travel distance is approx 368 px at 75 speed -> ~5 seconds)
      int creditsEarned = 0;
      for (int i = 0; i < 20; i++) {
        creditsEarned += manager.update(0.3, unitPriceProvider: (_) => 30);
      }

      // Sold at market!
      expect(creditsEarned, greaterThan(0));
      final deliveredTruck = manager.vehicles.first;
      expect(deliveredTruck.totalDeliveriesCount, greaterThanOrEqualTo(1));
    });

    test('OverflowPolicy redirects to market or waits when warehouse is full', () {
      final fullWarehouseManager = LogisticsFleetManager(
        warehouseCapacity: 20,
        warehouseStock: [CropStockBatch(cropId: 'CR01', amount: 20, ageMinutes: 0)],
        routes: [
          const TransportRoute(
            id: 'route_overflow',
            name: 'Taşma Rotası',
            stops: [
              RouteStop(
                id: 's1',
                name: 'Tarla',
                positionX: 0,
                positionY: 0,
                stopType: StopType.fieldPlot,
                action: CargoAction.load,
              ),
              RouteStop(
                id: 's2',
                name: 'Dolu Ambar',
                positionX: 50,
                positionY: 0,
                stopType: StopType.warehouse,
                action: CargoAction.unload,
              ),
            ],
            overflowPolicy: OverflowPolicy.sellAtMarket,
          ),
        ],
        vehicles: [
          const FleetVehicleState(
            id: 'truck_overflow',
            truckType: TruckType.starter,
            assignedRouteId: 'route_overflow',
            cargoCropId: 'CR01',
            cargoAmount: 15,
            status: VehicleStatus.traveling,
          ),
        ],
      );

      // Travel to s2
      final earned = fullWarehouseManager.update(2.0, unitPriceProvider: (_) => 30);
      // OverflowPolicy.sellAtMarket sells cargo because warehouse has 0 capacity left
      expect(earned, greaterThan(0));
      expect(fullWarehouseManager.vehicles.first.cargoAmount, equals(0));
    });

    test('Refrigerated truck protects perishable quality significantly longer', () {
      final normalTruck = const FleetVehicleState(
        id: 't_normal',
        truckType: TruckType.starter,
        assignedRouteId: 'r',
        cargoCropId: 'CR01',
        cargoAmount: 20,
      );

      final fridgeTruck = const FleetVehicleState(
        id: 't_fridge',
        truckType: TruckType.refrigerated,
        assignedRouteId: 'r',
        cargoCropId: 'CR01',
        cargoAmount: 20,
      );

      final route = const TransportRoute(
        id: 'r',
        name: 'R',
        stops: [
          RouteStop(id: '1', name: '1', positionX: 0, positionY: 0, stopType: StopType.fieldPlot, action: CargoAction.load),
          RouteStop(id: '2', name: '2', positionX: 10000, positionY: 0, stopType: StopType.market, action: CargoAction.unload),
        ],
      );

      final manager = LogisticsFleetManager(
        routes: [route],
        vehicles: [normalTruck, fridgeTruck],
      );

      // Simulate 120 seconds of transport
      manager.update(120.0);

      final afterNormal = manager.vehicles.firstWhere((v) => v.id == 't_normal');
      final afterFridge = manager.vehicles.firstWhere((v) => v.id == 't_fridge');

      expect(afterFridge.cargoQuality, greaterThan(afterNormal.cargoQuality));
    });

    test('Flame components TruckVehicleComponent and RouteVisualComponent update and render', () {
      final manager = LogisticsFleetManager();
      manager.initializeStarterFleet();

      final truckComp = TruckVehicleComponent(
        vehicleId: 'truck_starter_01',
        fleetManager: manager,
      );

      final routeVisualComp = RouteVisualComponent(
        fleetManager: manager,
      );

      expect(truckComp.vehicleId, equals('truck_starter_01'));
      expect(routeVisualComp.priority, equals(4));

      // Update position
      manager.update(1.0);
      truckComp.update(0.1);
      expect(truckComp.position, isNotNull);
    });

    test('OpeningSession purchasing additional truck classes', () {
      final session = OpeningSession();
      session.addCredits(5000);
      session.buyMower();
      session.hireWorker();

      expect(session.canBuyTruck(TruckType.lightExpress), isTrue);
      expect(session.buyTruck(TruckType.lightExpress), isTrue);
      expect(session.fleetManager.vehicles.any((v) => v.truckType == TruckType.lightExpress), isTrue);

      expect(session.canBuyTruck(TruckType.heavyHauler), isTrue);
      expect(session.buyTruck(TruckType.heavyHauler), isTrue);
      expect(session.fleetManager.vehicles.any((v) => v.truckType == TruckType.heavyHauler), isTrue);
    });
  });
}
