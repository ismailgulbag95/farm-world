import 'dart:math';

const double starterMarketMapX = 0;
const double starterMarketMapY = 155;

/// Truck vehicle classes with distinct trade-offs as specified in game-design-brief.
enum TruckType {
  starter(
    name: 'Başlangıç Kamyoneti',
    capacity: 20,
    speed: 75.0,
    purchaseCostCredits: 0,
    spoilageProtectionMultiplier: 1.0,
  ),
  lightExpress(
    name: 'Hafif Ekspres Kurye',
    capacity: 15,
    speed: 120.0,
    purchaseCostCredits: 850,
    spoilageProtectionMultiplier: 1.0,
  ),
  heavyHauler(
    name: 'Ağır Nakliye Tırı',
    capacity: 60,
    speed: 55.0,
    purchaseCostCredits: 1600,
    spoilageProtectionMultiplier: 1.0,
  ),
  refrigerated(
    name: 'Soğutuculu Tır',
    capacity: 35,
    speed: 70.0,
    purchaseCostCredits: 2200,
    spoilageProtectionMultiplier: 0.35, // Drastically slows down perishability
  ),
  mediumCargo(
    name: 'Ova 32 Orta Sınıf Kamyon',
    capacity: 32,
    speed: 92.0,
    purchaseCostCredits: 1450,
    spoilageProtectionMultiplier: 1.0,
  ),
  semiHauler(
    name: 'Yoltek 70 Uzun Yol Çekicisi',
    capacity: 70,
    speed: 78.0,
    purchaseCostCredits: 4200,
    spoilageProtectionMultiplier: 1.0,
  ),
  regionalRoadTrain(
    name: 'Yoltek 100 Bölgesel Dorse Tırı',
    capacity: 100,
    speed: 58.0,
    purchaseCostCredits: 6100,
    spoilageProtectionMultiplier: 1.0,
  );

  const TruckType({
    required this.name,
    required this.capacity,
    required this.speed,
    required this.purchaseCostCredits,
    required this.spoilageProtectionMultiplier,
  });

  final String name;
  final int capacity;
  final double speed;
  final int purchaseCostCredits;
  final double spoilageProtectionMultiplier;

  String? get requiredTechnologyId => switch (this) {
    TruckType.starter => null,
    TruckType.mediumCargo => 'L01',
    TruckType.lightExpress => 'L06',
    TruckType.heavyHauler || TruckType.semiHauler => 'L07',
    TruckType.refrigerated => 'L08',
    TruckType.regionalRoadTrain => 'L12',
  };

  bool get acceptsTrailer => switch (this) {
    TruckType.starter ||
    TruckType.lightExpress ||
    TruckType.mediumCargo => false,
    _ => true,
  };

  String get imageAsset => switch (this) {
    TruckType.starter ||
    TruckType.lightExpress ||
    TruckType.mediumCargo => 'assets/images/logistics/truck-medium.webp',
    _ => 'assets/images/logistics/truck-semi.webp',
  };
}

/// Interchangeable cargo trailers. Capacity and road speed affect actual fleet
/// simulation as soon as a trailer is fitted to a compatible purchased truck.
enum TrailerType {
  lightFlatbed(
    name: 'Yayla 20 Hafif Platform Dorse',
    capacityBonus: 20,
    speedMultiplier: 0.96,
    purchaseCostCredits: 900,
    requiredTechnologyIds: ['L11'],
    imageAsset: 'assets/images/logistics/trailer-grain.webp',
  ),
  grainBulk(
    name: 'Bereket 55 Dökme Tahıl Dorsesi',
    capacityBonus: 55,
    speedMultiplier: 0.88,
    purchaseCostCredits: 1900,
    requiredTechnologyIds: ['L11', 'L12'],
    imageAsset: 'assets/images/logistics/trailer-grain.webp',
  ),
  refrigerated(
    name: 'Serin Hat 25 Soğutuculu Dorse',
    capacityBonus: 25,
    speedMultiplier: 0.91,
    purchaseCostCredits: 2400,
    requiredTechnologyIds: ['L11', 'L13'],
    imageAsset: 'assets/images/logistics/trailer-cold.webp',
  ),
  roadTrain(
    name: 'Ufuk 80 Çoklu Aks Dorse',
    capacityBonus: 80,
    speedMultiplier: 0.78,
    purchaseCostCredits: 3400,
    requiredTechnologyIds: ['L11', 'L12', 'L15'],
    imageAsset: 'assets/images/logistics/trailer-grain.webp',
  );

  const TrailerType({
    required this.name,
    required this.capacityBonus,
    required this.speedMultiplier,
    required this.purchaseCostCredits,
    required this.requiredTechnologyIds,
    required this.imageAsset,
  });

  final String name;
  final int capacityBonus;
  final double speedMultiplier;
  final int purchaseCostCredits;
  final List<String> requiredTechnologyIds;
  final String imageAsset;
}

/// Policies for handling cargo when destination storage/warehouse has no capacity.
enum OverflowPolicy {
  /// Wait at the destination until warehouse capacity frees up.
  wait,

  /// Divert overflowing cargo to the nearest accessible market and sell at current market price.
  sellAtMarket,

  /// Keep excess cargo in truck and continue route without clearing cargo.
  keepInCargo,
}

/// Stop types on a multi-stop route.
enum StopType { fieldPlot, warehouse, processingFactory, market }

/// Action performed by the truck at a stop.
enum CargoAction { load, unload, loadOrUnload }

/// Single stop along a transport route.
class RouteStop {
  const RouteStop({
    required this.id,
    required this.name,
    required this.positionX,
    required this.positionY,
    required this.stopType,
    required this.action,
    this.targetCropId,
    this.loadAmountLimit,
  });

  final String id;
  final String name;
  final double positionX;
  final double positionY;
  final StopType stopType;
  final CargoAction action;
  final String? targetCropId;

  /// Maximum quantity loaded for this item on one visit; null fills capacity.
  final int? loadAmountLimit;

  RouteStop copyWith({
    String? targetCropId,
    bool clearTargetCropId = false,
    int? loadAmountLimit,
  }) => RouteStop(
    id: id,
    name: name,
    positionX: positionX,
    positionY: positionY,
    stopType: stopType,
    action: action,
    targetCropId: clearTargetCropId ? null : targetCropId ?? this.targetCropId,
    loadAmountLimit: loadAmountLimit ?? this.loadAmountLimit,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positionX': positionX,
    'positionY': positionY,
    'stopType': stopType.name,
    'action': action.name,
    if (targetCropId != null) 'targetCropId': targetCropId,
    if (loadAmountLimit != null) 'loadAmountLimit': loadAmountLimit,
  };

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id: json['id'] as String,
    name: json['name'] as String,
    positionX: (json['positionX'] as num).toDouble(),
    positionY: (json['positionY'] as num).toDouble(),
    stopType: StopType.values.byName(json['stopType'] as String),
    action: CargoAction.values.byName(json['action'] as String),
    targetCropId: json['targetCropId'] as String?,
    loadAmountLimit: json['loadAmountLimit'] as int?,
  );
}

/// Multi-stop looping route for logistics transport.
class TransportRoute {
  const TransportRoute({
    required this.id,
    required this.name,
    required this.stops,
    this.overflowPolicy = OverflowPolicy.sellAtMarket,
    this.isActive = true,
    this.isOneShot = false,
    this.contractId,
  });

  final String id;
  final String name;
  final List<RouteStop> stops;
  final OverflowPolicy overflowPolicy;
  final bool isActive;
  final bool isOneShot;
  final String? contractId;

  int nextStopIndex(int currentIndex) {
    if (stops.isEmpty) return 0;
    return (currentIndex + 1) % stops.length;
  }

  double totalDistance() {
    if (stops.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < stops.length; i++) {
      final current = stops[i];
      final next = stops[(i + 1) % stops.length];
      final dx = next.positionX - current.positionX;
      final dy = next.positionY - current.positionY;
      total += sqrt(dx * dx + dy * dy);
    }
    return total;
  }

  TransportRoute copyWith({
    String? id,
    String? name,
    List<RouteStop>? stops,
    OverflowPolicy? overflowPolicy,
    bool? isActive,
    bool? isOneShot,
    String? contractId,
    bool clearContractId = false,
  }) {
    return TransportRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      stops: stops ?? this.stops,
      overflowPolicy: overflowPolicy ?? this.overflowPolicy,
      isActive: isActive ?? this.isActive,
      isOneShot: isOneShot ?? this.isOneShot,
      contractId: clearContractId ? null : contractId ?? this.contractId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stops': stops.map((s) => s.toJson()).toList(),
    'overflowPolicy': overflowPolicy.name,
    'isActive': isActive,
    'isOneShot': isOneShot,
    if (contractId != null) 'contractId': contractId,
  };

  factory TransportRoute.fromJson(Map<String, dynamic> json) => TransportRoute(
    id: json['id'] as String,
    name: json['name'] as String,
    stops: (json['stops'] as List<dynamic>)
        .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
        .toList(),
    overflowPolicy: OverflowPolicy.values.byName(
      json['overflowPolicy'] as String? ?? OverflowPolicy.sellAtMarket.name,
    ),
    isActive: json['isActive'] as bool? ?? true,
    isOneShot: json['isOneShot'] as bool? ?? false,
    contractId: json['contractId'] as String?,
  );
}

/// Operational status of a vehicle.
enum VehicleStatus {
  idle,
  traveling,
  paused,
  loading,
  unloading,
  divertingToSell,
  waitingForSpace,
  outOfFuel,
  serviceDue,
}

/// Runtime state of a vehicle in the fleet.
class FleetVehicleState {
  const FleetVehicleState({
    required this.id,
    required this.truckType,
    this.trailerType,
    this.assignedRouteId,
    this.currentStopIndex = 0,
    this.progressToNextStop = 0.0,
    this.cargoCropId,
    this.cargoAmount = 0,
    this.cargoAgeMinutes = 0.0,
    this.cargoQuality = 1.0,
    this.status = VehicleStatus.idle,
    this.totalEarnedCredits = 0,
    this.totalDeliveriesCount = 0,
    this.fuelLevel = 100.0,
    this.wearPercent = 0.0,
    this.queuedRouteIds = const [],
    this.finishRouteAfterCycle = false,
    this.isIndividuallyPaused = false,
  });

  final String id;
  final TruckType truckType;
  final TrailerType? trailerType;
  final String? assignedRouteId;
  final int currentStopIndex;
  final double progressToNextStop;
  final String? cargoCropId;
  final int cargoAmount;
  final double cargoAgeMinutes;
  final double cargoQuality; // 1.0 (fresh) to 0.0 (spoiled/salvage floor)
  final VehicleStatus status;
  final int totalEarnedCredits;
  final int totalDeliveriesCount;
  final double fuelLevel;
  final double wearPercent;
  final List<String> queuedRouteIds;

  /// Per-vehicle one-shot override, so queueing a run never edits route policy.
  final bool finishRouteAfterCycle;

  /// Pauses this vehicle without changing the shared route policy.
  final bool isIndividuallyPaused;

  bool get hasCargo => cargoAmount > 0 && cargoCropId != null;
  int get effectiveCapacity =>
      truckType.capacity + (trailerType?.capacityBonus ?? 0);
  double get effectiveSpeed =>
      truckType.speed * (trailerType?.speedMultiplier ?? 1.0);
  double get effectiveSpoilageProtectionMultiplier =>
      trailerType == TrailerType.refrigerated
      ? min(truckType.spoilageProtectionMultiplier, 0.35)
      : truckType.spoilageProtectionMultiplier;
  bool get isFull => cargoAmount >= effectiveCapacity;
  int get remainingCapacity => max(0, effectiveCapacity - cargoAmount);

  FleetVehicleState copyWith({
    String? id,
    TruckType? truckType,
    TrailerType? trailerType,
    String? assignedRouteId,
    int? currentStopIndex,
    double? progressToNextStop,
    String? cargoCropId,
    int? cargoAmount,
    double? cargoAgeMinutes,
    double? cargoQuality,
    VehicleStatus? status,
    int? totalEarnedCredits,
    int? totalDeliveriesCount,
    double? fuelLevel,
    double? wearPercent,
    List<String>? queuedRouteIds,
    bool? finishRouteAfterCycle,
    bool? isIndividuallyPaused,
    bool clearAssignedRouteId = false,
  }) {
    return FleetVehicleState(
      id: id ?? this.id,
      truckType: truckType ?? this.truckType,
      trailerType: trailerType ?? this.trailerType,
      assignedRouteId: clearAssignedRouteId
          ? null
          : assignedRouteId ?? this.assignedRouteId,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      progressToNextStop: progressToNextStop ?? this.progressToNextStop,
      cargoCropId: cargoCropId ?? this.cargoCropId,
      cargoAmount: cargoAmount ?? this.cargoAmount,
      cargoAgeMinutes: cargoAgeMinutes ?? this.cargoAgeMinutes,
      cargoQuality: cargoQuality ?? this.cargoQuality,
      status: status ?? this.status,
      totalEarnedCredits: totalEarnedCredits ?? this.totalEarnedCredits,
      totalDeliveriesCount: totalDeliveriesCount ?? this.totalDeliveriesCount,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      wearPercent: wearPercent ?? this.wearPercent,
      queuedRouteIds: queuedRouteIds ?? this.queuedRouteIds,
      finishRouteAfterCycle:
          finishRouteAfterCycle ?? this.finishRouteAfterCycle,
      isIndividuallyPaused:
          isIndividuallyPaused ?? this.isIndividuallyPaused,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'truckType': truckType.name,
    if (trailerType != null) 'trailerType': trailerType!.name,
    if (assignedRouteId != null) 'assignedRouteId': assignedRouteId,
    'currentStopIndex': currentStopIndex,
    'progressToNextStop': progressToNextStop,
    if (cargoCropId != null) 'cargoCropId': cargoCropId,
    'cargoAmount': cargoAmount,
    'cargoAgeMinutes': cargoAgeMinutes,
    'cargoQuality': cargoQuality,
    'status': status.name,
    'totalEarnedCredits': totalEarnedCredits,
    'totalDeliveriesCount': totalDeliveriesCount,
    'fuelLevel': fuelLevel,
    'wearPercent': wearPercent,
    'queuedRouteIds': queuedRouteIds,
    'finishRouteAfterCycle': finishRouteAfterCycle,
    'isIndividuallyPaused': isIndividuallyPaused,
  };

  factory FleetVehicleState.fromJson(Map<String, dynamic> json) =>
      FleetVehicleState(
        id: json['id'] as String,
        truckType: TruckType.values.byName(json['truckType'] as String),
        trailerType: json['trailerType'] is String
            ? TrailerType.values.byName(json['trailerType'] as String)
            : null,
        assignedRouteId: json['assignedRouteId'] as String?,
        currentStopIndex: json['currentStopIndex'] as int? ?? 0,
        progressToNextStop:
            (json['progressToNextStop'] as num?)?.toDouble() ?? 0.0,
        cargoCropId: json['cargoCropId'] as String?,
        cargoAmount: json['cargoAmount'] as int? ?? 0,
        cargoAgeMinutes: (json['cargoAgeMinutes'] as num?)?.toDouble() ?? 0.0,
        cargoQuality: (json['cargoQuality'] as num?)?.toDouble() ?? 1.0,
        status: VehicleStatus.values.byName(
          json['status'] as String? ?? VehicleStatus.idle.name,
        ),
        totalEarnedCredits: json['totalEarnedCredits'] as int? ?? 0,
        totalDeliveriesCount: json['totalDeliveriesCount'] as int? ?? 0,
        fuelLevel: (json['fuelLevel'] as num?)?.toDouble() ?? 100.0,
        wearPercent: (json['wearPercent'] as num?)?.toDouble() ?? 0.0,
        queuedRouteIds: (json['queuedRouteIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        finishRouteAfterCycle: json['finishRouteAfterCycle'] as bool? ?? false,
        isIndividuallyPaused:
            json['isIndividuallyPaused'] as bool? ?? false,
      );
}

/// Storage warehouse stock container with FIFO perishable batch handling.
class CropStockBatch {
  CropStockBatch({
    required this.cropId,
    required this.amount,
    required this.ageMinutes,
    this.quality = 1.0,
  });

  final String cropId;
  int amount;
  double ageMinutes;
  double quality;

  Map<String, dynamic> toJson() => {
    'cropId': cropId,
    'amount': amount,
    'ageMinutes': ageMinutes,
    'quality': quality,
  };

  factory CropStockBatch.fromJson(Map<String, dynamic> json) => CropStockBatch(
    cropId: json['cropId'] as String,
    amount: json['amount'] as int,
    ageMinutes: (json['ageMinutes'] as num).toDouble(),
    quality: (json['quality'] as num?)?.toDouble() ?? 1.0,
  );
}

/// Complete logistics and fleet manager simulation engine.
class LogisticsFleetManager {
  LogisticsFleetManager({
    List<FleetVehicleState>? vehicles,
    List<TransportRoute>? routes,
    List<CropStockBatch>? warehouseStock,
    this.warehouseCapacity = 200,
  }) : vehicles = vehicles ?? [],
       routes = routes ?? [],
       warehouseStock = warehouseStock ?? [];

  final List<FleetVehicleState> vehicles;
  final List<TransportRoute> routes;
  final List<CropStockBatch> warehouseStock;
  int warehouseCapacity;
  double routeSpeedMultiplier = 1.0;
  double warehouseFreshnessMultiplier = 1.0;

  int get totalWarehouseAmount =>
      warehouseStock.fold(0, (sum, b) => sum + b.amount);

  int get remainingWarehouseCapacity =>
      max(0, warehouseCapacity - totalWarehouseAmount);

  int serviceCostFor(FleetVehicleState vehicle) =>
      (25 +
              (100 - vehicle.fuelLevel).clamp(0, 100) * 2 +
              vehicle.wearPercent.clamp(0, 100) * 5)
          .round();

  bool serviceVehicle(String vehicleId) {
    final index = vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index < 0) return false;
    final vehicle = vehicles[index];
    final activeRoute = routes.where(
      (route) => route.id == vehicle.assignedRouteId,
    );
    vehicles[index] = vehicle.copyWith(
      fuelLevel: 100,
      wearPercent: 0,
      status: vehicle.isIndividuallyPaused
          ? VehicleStatus.paused
          : vehicle.assignedRouteId == null
          ? VehicleStatus.idle
          : activeRoute.isNotEmpty && !activeRoute.first.isActive
          ? VehicleStatus.paused
          : VehicleStatus.traveling,
    );
    return true;
  }

  bool setRouteActive(String routeId, bool isActive) {
    final routeIndex = routes.indexWhere((route) => route.id == routeId);
    if (routeIndex < 0 || routes[routeIndex].isActive == isActive) return false;
    routes[routeIndex] = routes[routeIndex].copyWith(isActive: isActive);
    for (var index = 0; index < vehicles.length; index++) {
      final vehicle = vehicles[index];
      if (vehicle.assignedRouteId != routeId) continue;
      final status = !isActive || vehicle.isIndividuallyPaused
          ? VehicleStatus.paused
          : vehicle.fuelLevel <= 0.01
          ? VehicleStatus.outOfFuel
          : vehicle.wearPercent >= 100
          ? VehicleStatus.serviceDue
          : VehicleStatus.traveling;
      vehicles[index] = vehicle.copyWith(status: status);
    }
    return true;
  }

  bool setVehiclePaused(String vehicleId, bool isPaused) {
    final index = vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index < 0) return false;
    final vehicle = vehicles[index];
    if ((vehicle.assignedRouteId == null && vehicle.queuedRouteIds.isEmpty) ||
        vehicle.isIndividuallyPaused == isPaused) {
      return false;
    }
    final route = routes.where((item) => item.id == vehicle.assignedRouteId);
    final routeIsActive = route.isEmpty || route.first.isActive;
    final VehicleStatus status;
    if (isPaused || !routeIsActive) {
      status = VehicleStatus.paused;
    } else if (vehicle.assignedRouteId == null) {
      status = VehicleStatus.idle;
    } else if (vehicle.fuelLevel <= 0.01) {
      status = VehicleStatus.outOfFuel;
    } else if (vehicle.wearPercent >= 100) {
      status = VehicleStatus.serviceDue;
    } else {
      status = VehicleStatus.traveling;
    }
    vehicles[index] = vehicle.copyWith(
      isIndividuallyPaused: isPaused,
      status: status,
    );
    return true;
  }

  /// Stops this vehicle's active and queued runs while retaining any cargo.
  bool cancelVehicleRoutes(String vehicleId) {
    final index = vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index < 0) return false;
    final vehicle = vehicles[index];
    if (vehicle.assignedRouteId == null && vehicle.queuedRouteIds.isEmpty) {
      return false;
    }
    vehicles[index] = vehicle.copyWith(
      clearAssignedRouteId: true,
      currentStopIndex: 0,
      progressToNextStop: 0,
      queuedRouteIds: const [],
      finishRouteAfterCycle: false,
      isIndividuallyPaused: false,
      status: VehicleStatus.idle,
    );
    return true;
  }

  /// Removes one queued run without disturbing the active route or cargo.
  bool cancelQueuedRoute(String vehicleId, int queueIndex) {
    final index = vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index < 0) return false;
    final vehicle = vehicles[index];
    if (queueIndex < 0 || queueIndex >= vehicle.queuedRouteIds.length) {
      return false;
    }
    final queue = [...vehicle.queuedRouteIds]..removeAt(queueIndex);
    vehicles[index] = vehicle.copyWith(queuedRouteIds: queue);
    return true;
  }

  /// Queues one finite run of an existing route for a vehicle.
  bool enqueueRouteForVehicle(String vehicleId, String routeId) {
    final vehicleIndex = vehicles.indexWhere(
      (vehicle) => vehicle.id == vehicleId,
    );
    final routeIndex = routes.indexWhere((route) => route.id == routeId);
    if (vehicleIndex < 0 ||
        routeIndex < 0 ||
        routes[routeIndex].stops.length < 2) {
      return false;
    }
    var vehicle = vehicles[vehicleIndex];
    if (vehicle.assignedRouteId == null ||
        vehicle.status == VehicleStatus.idle) {
      vehicles[vehicleIndex] = vehicle.copyWith(
        assignedRouteId: routeId,
        currentStopIndex: 0,
        progressToNextStop: 0,
        status: VehicleStatus.traveling,
        finishRouteAfterCycle: true,
      );
      return true;
    }
    vehicle = vehicle.copyWith(
      queuedRouteIds: [...vehicle.queuedRouteIds, routeId],
      finishRouteAfterCycle: true,
    );
    vehicles[vehicleIndex] = vehicle;
    return true;
  }

  FleetVehicleState _finishOneShotRoute(FleetVehicleState vehicle) {
    if (vehicle.queuedRouteIds.isEmpty) {
      return vehicle.copyWith(
        clearAssignedRouteId: true,
        currentStopIndex: 0,
        progressToNextStop: 0,
        status: VehicleStatus.idle,
        finishRouteAfterCycle: false,
      );
    }
    final queue = [...vehicle.queuedRouteIds];
    final nextRouteId = queue.removeAt(0);
    if (!routes.any((route) => route.id == nextRouteId)) {
      return _finishOneShotRoute(vehicle.copyWith(queuedRouteIds: queue));
    }
    return vehicle.copyWith(
      assignedRouteId: nextRouteId,
      queuedRouteIds: queue,
      currentStopIndex: 0,
      progressToNextStop: 0,
      status: VehicleStatus.traveling,
      finishRouteAfterCycle: true,
    );
  }

  /// The starter truck has no active route until the player creates a sales line.
  static TransportRoute defaultStarterRoute = const TransportRoute(
    id: 'route_starter',
    name: 'Tarladan Pazara Ana Hat',
    stops: [
      RouteStop(
        id: 'stop_starter_plot',
        name: 'Başlangıç Tarlası',
        positionX: -300,
        positionY: -235,
        stopType: StopType.fieldPlot,
        action: CargoAction.load,
      ),
      RouteStop(
        id: 'stop_market',
        name: 'Kasaba Pazarı',
        positionX: starterMarketMapX,
        positionY: starterMarketMapY,
        stopType: StopType.market,
        action: CargoAction.unload,
      ),
    ],
    overflowPolicy: OverflowPolicy.sellAtMarket,
  );

  /// Initializes default fleet when starter truck is unlocked.
  void initializeStarterFleet() {
    final hasStarterTruck = vehicles.any(
      (vehicle) => vehicle.truckType == TruckType.starter,
    );
    if (!hasStarterTruck) {
      vehicles.add(
        const FleetVehicleState(
          id: 'truck_starter_01',
          truckType: TruckType.starter,
          status: VehicleStatus.idle,
        ),
      );
    }
  }

  /// Creates or reactivates the starter farm-to-market sale route explicitly.
  void startStarterMarketRoute({
    required double fieldX,
    required double fieldY,
    required String fieldName,
    double marketX = starterMarketMapX,
    double marketY = starterMarketMapY,
    String? targetCropId,
    int? loadAmountLimit,
    bool isOneShot = true,
    String? contractId,
  }) {
    initializeStarterFleet();
    const routeId = 'route_starter';
    final route = TransportRoute(
      id: routeId,
      name: 'Tarladan Pazara Satış Hattı',
      stops: [
        RouteStop(
          id: 'stop_starter_plot',
          name: fieldName,
          positionX: fieldX,
          positionY: fieldY,
          stopType: StopType.fieldPlot,
          action: CargoAction.load,
          targetCropId: targetCropId,
          loadAmountLimit: loadAmountLimit,
        ),
        RouteStop(
          id: 'stop_market',
          name: 'Kasaba Pazarı',
          positionX: marketX,
          positionY: marketY,
          stopType: StopType.market,
          action: CargoAction.unload,
        ),
      ],
      isOneShot: isOneShot,
      contractId: contractId,
    );
    final routeIndex = routes.indexWhere((item) => item.id == routeId);
    if (routeIndex == -1) {
      routes.add(route);
    } else {
      routes[routeIndex] = route;
    }

    final vehicleIndex = vehicles.indexWhere(
      (vehicle) => vehicle.truckType == TruckType.starter,
    );
    if (vehicleIndex != -1) {
      var vehicle = vehicles[vehicleIndex];
      final sourceIndex = targetCropId == null
          ? 0
          : warehouseStock.indexWhere((batch) => batch.cropId == targetCropId);
      if (!vehicle.hasCargo &&
          sourceIndex >= 0 &&
          sourceIndex < warehouseStock.length) {
        final batch = warehouseStock[sourceIndex];
        final loaded = min(
          min(vehicle.remainingCapacity, batch.amount),
          loadAmountLimit ?? vehicle.remainingCapacity,
        );
        batch.amount -= loaded;
        if (batch.amount <= 0) warehouseStock.removeAt(sourceIndex);
        vehicle = vehicle.copyWith(
          cargoCropId: batch.cropId,
          cargoAmount: loaded,
          cargoAgeMinutes: batch.ageMinutes,
          cargoQuality: batch.quality,
        );
      }
      vehicles[vehicleIndex] = vehicle.copyWith(
        assignedRouteId: routeId,
        currentStopIndex: 0,
        progressToNextStop: 0,
        status: VehicleStatus.traveling,
        finishRouteAfterCycle: isOneShot,
      );
    }
  }

  /// Adds a newly purchased truck to the fleet.
  bool purchaseTruck(TruckType type, {String? assignedRouteId}) {
    if (type == TruckType.starter) return false;
    final newId = 'truck_${type.name}_${vehicles.length + 1}';
    final routeId =
        assignedRouteId ?? (routes.isNotEmpty ? routes.first.id : null);
    final vehicle = FleetVehicleState(
      id: newId,
      truckType: type,
      assignedRouteId: routeId,
      status: VehicleStatus.idle,
      finishRouteAfterCycle: routes.any(
        (route) => route.id == routeId && route.isOneShot,
      ),
    );
    vehicles.add(vehicle);
    return true;
  }

  /// Fits a newly purchased trailer to the selected compatible truck.
  bool purchaseTrailer(TrailerType type, String vehicleId) {
    final index = vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index < 0) return false;
    final vehicle = vehicles[index];
    if (!vehicle.truckType.acceptsTrailer) return false;
    vehicles[index] = vehicle.copyWith(trailerType: type);
    return true;
  }

  /// Deposits harvested crop into warehouse stock (FIFO).
  int depositToWarehouse(
    String cropId,
    int amount, {
    double ageMinutes = 0,
    double quality = 1.0,
  }) {
    final accepted = min(amount, remainingWarehouseCapacity);
    if (accepted <= 0) return 0;
    warehouseStock.add(
      CropStockBatch(
        cropId: cropId,
        amount: accepted,
        ageMinutes: ageMinutes,
        quality: quality,
      ),
    );
    return accepted;
  }

  /// Updates all vehicles, route movements, cargo transfers and perishability.
  /// Returns total credits earned from market deliveries in this step.
  int update(
    double dtSeconds, {
    int Function(String cropId)? unitPriceProvider,
    int Function({
      required String contractId,
      required String itemId,
      required int amount,
      required double quality,
      required int saleValue,
    })?
    onMarketDelivery,
  }) {
    int earnedCredits = 0;
    final getPrice = unitPriceProvider ?? ((_) => 30);

    for (final batch in warehouseStock) {
      batch.ageMinutes += dtSeconds / 60.0;
      batch.quality = max(
        0.40,
        batch.quality -
            0.0005 * warehouseFreshnessMultiplier * dtSeconds / 60.0,
      );
    }

    for (int i = 0; i < vehicles.length; i++) {
      var v = vehicles[i];
      if (v.fuelLevel <= 0.01 || v.wearPercent >= 100) {
        final status = v.wearPercent >= 100
            ? VehicleStatus.serviceDue
            : VehicleStatus.outOfFuel;
        if (v.status != status) vehicles[i] = v.copyWith(status: status);
        continue;
      }
      if (v.assignedRouteId == null) continue;
      if (v.isIndividuallyPaused) continue;

      final routeIndex = routes.indexWhere((r) => r.id == v.assignedRouteId);
      if (routeIndex == -1) continue;
      final route = routes[routeIndex];
      if (!route.isActive || route.stops.length < 2) continue;

      final currentStop = route.stops[v.currentStopIndex];
      final nextStopIndex = route.nextStopIndex(v.currentStopIndex);
      final nextStop = route.stops[nextStopIndex];

      // Distance between stops
      final dx = nextStop.positionX - currentStop.positionX;
      final dy = nextStop.positionY - currentStop.positionY;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= 0.001) {
        v = v.copyWith(currentStopIndex: nextStopIndex);
        vehicles[i] = v;
        continue;
      }

      // Age existing cargo and calculate perishable quality loss
      double newAge = v.cargoAgeMinutes;
      double newQuality = v.cargoQuality;
      if (v.hasCargo) {
        newAge += (dtSeconds / 60.0);
        final degradationRate = 0.002 * v.effectiveSpoilageProtectionMultiplier;
        newQuality = max(
          0.40,
          newQuality - degradationRate * (dtSeconds / 60.0),
        );
        v = v.copyWith(cargoAgeMinutes: newAge, cargoQuality: newQuality);
      }

      // Movement progress
      final moveSpeed = v.effectiveSpeed * routeSpeedMultiplier;
      final distanceMoved = min(moveSpeed * dtSeconds, v.fuelLevel * 150.0);
      final progressInc = distanceMoved / dist;
      final newProgress = v.progressToNextStop + progressInc;
      final traveledDistance = min(
        distanceMoved,
        dist * (1 - v.progressToNextStop),
      );
      v = v.copyWith(
        fuelLevel: max(0, v.fuelLevel - traveledDistance / 150.0),
        wearPercent: min(100, v.wearPercent + traveledDistance / 1200.0),
      );

      if (newProgress >= 1.0) {
        // Arrived at nextStop!
        final arrivedStop = nextStop;

        // Perform action at arrivedStop
        if (arrivedStop.stopType == StopType.market) {
          // Unload and sell at market!
          if (v.hasCargo) {
            final unitPrice = getPrice(v.cargoCropId!);
            final saleValue = (v.cargoAmount * unitPrice * v.cargoQuality)
                .round();
            earnedCredits += saleValue;
            earnedCredits +=
                onMarketDelivery?.call(
                  contractId: route.contractId ?? '',
                  itemId: v.cargoCropId!,
                  amount: v.cargoAmount,
                  quality: v.cargoQuality,
                  saleValue: saleValue,
                ) ??
                0;

            v = v.copyWith(
              currentStopIndex: nextStopIndex,
              progressToNextStop: 0.0,
              cargoCropId: null,
              cargoAmount: 0,
              cargoAgeMinutes: 0.0,
              cargoQuality: 1.0,
              status: VehicleStatus.traveling,
              totalEarnedCredits: v.totalEarnedCredits + saleValue,
              totalDeliveriesCount: v.totalDeliveriesCount + 1,
            );
          } else {
            v = v.copyWith(
              currentStopIndex: nextStopIndex,
              progressToNextStop: 0.0,
              status: VehicleStatus.traveling,
            );
          }
          if (v.finishRouteAfterCycle) v = _finishOneShotRoute(v);
        } else if (arrivedStop.action == CargoAction.unload) {
          // Unload cargo to warehouse or processing facility
          if (v.hasCargo) {
            if (remainingWarehouseCapacity >= v.cargoAmount) {
              depositToWarehouse(
                v.cargoCropId!,
                v.cargoAmount,
                ageMinutes: v.cargoAgeMinutes,
                quality: v.cargoQuality,
              );
              v = v.copyWith(
                currentStopIndex: nextStopIndex,
                progressToNextStop: 0.0,
                cargoCropId: null,
                cargoAmount: 0,
                cargoAgeMinutes: 0.0,
                cargoQuality: 1.0,
                totalDeliveriesCount: v.totalDeliveriesCount + 1,
                status: VehicleStatus.traveling,
              );
            } else {
              // Overflow handling!
              switch (route.overflowPolicy) {
                case OverflowPolicy.wait:
                  v = v.copyWith(status: VehicleStatus.waitingForSpace);
                  vehicles[i] = v;
                  continue; // Don't cycle stop index
                case OverflowPolicy.sellAtMarket:
                  final unitPrice = getPrice(v.cargoCropId!);
                  final saleValue = (v.cargoAmount * unitPrice * v.cargoQuality)
                      .round();
                  earnedCredits += saleValue;
                  earnedCredits +=
                      onMarketDelivery?.call(
                        contractId: route.contractId ?? '',
                        itemId: v.cargoCropId!,
                        amount: v.cargoAmount,
                        quality: v.cargoQuality,
                        saleValue: saleValue,
                      ) ??
                      0;
                  v = v.copyWith(
                    currentStopIndex: nextStopIndex,
                    progressToNextStop: 0.0,
                    cargoCropId: null,
                    cargoAmount: 0,
                    cargoAgeMinutes: 0.0,
                    cargoQuality: 1.0,
                    totalEarnedCredits: v.totalEarnedCredits + saleValue,
                    totalDeliveriesCount: v.totalDeliveriesCount + 1,
                    status: VehicleStatus.traveling,
                  );
                  break;
                case OverflowPolicy.keepInCargo:
                  v = v.copyWith(
                    currentStopIndex: nextStopIndex,
                    progressToNextStop: 0.0,
                    status: VehicleStatus.traveling,
                  );
                  break;
              }
            }
          } else {
            v = v.copyWith(
              currentStopIndex: nextStopIndex,
              progressToNextStop: 0.0,
              status: VehicleStatus.traveling,
            );
          }
        } else if (arrivedStop.action == CargoAction.load ||
            arrivedStop.stopType == StopType.fieldPlot) {
          // Load cargo if truck has space
          if (v.remainingCapacity > 0) {
            // Take from warehouse stock if available
            final requestedCropId = arrivedStop.targetCropId;
            final batchIndex = requestedCropId == null
                ? 0
                : warehouseStock.indexWhere(
                    (batch) => batch.cropId == requestedCropId,
                  );
            final takeAmount =
                batchIndex < 0 ||
                    batchIndex >= warehouseStock.length ||
                    (v.hasCargo &&
                        v.cargoCropId != warehouseStock[batchIndex].cropId)
                ? 0
                : min(
                    min(v.remainingCapacity, warehouseStock[batchIndex].amount),
                    max(
                      0,
                      (arrivedStop.loadAmountLimit ?? v.remainingCapacity) -
                          v.cargoAmount,
                    ),
                  );
            if (takeAmount > 0) {
              final firstBatch = warehouseStock[batchIndex];
              final taken = min(takeAmount, firstBatch.amount);
              firstBatch.amount -= taken;
              if (firstBatch.amount <= 0) {
                warehouseStock.removeAt(batchIndex);
              }

              v = v.copyWith(
                cargoCropId: firstBatch.cropId,
                cargoAmount: v.cargoAmount + taken,
                cargoAgeMinutes: firstBatch.ageMinutes,
                cargoQuality: firstBatch.quality,
              );
            }
          }

          v = v.copyWith(
            currentStopIndex: nextStopIndex,
            progressToNextStop: 0.0,
            status: VehicleStatus.traveling,
          );
        } else if (arrivedStop.action == CargoAction.unload) {
          // Unload cargo
          if (v.hasCargo) {
            if (remainingWarehouseCapacity >= v.cargoAmount) {
              depositToWarehouse(
                v.cargoCropId!,
                v.cargoAmount,
                ageMinutes: v.cargoAgeMinutes,
                quality: v.cargoQuality,
              );
              v = v.copyWith(
                cargoCropId: null,
                cargoAmount: 0,
                cargoAgeMinutes: 0.0,
                cargoQuality: 1.0,
                totalDeliveriesCount: v.totalDeliveriesCount + 1,
              );
            } else {
              // Overflow handling!
              switch (route.overflowPolicy) {
                case OverflowPolicy.wait:
                  v = v.copyWith(status: VehicleStatus.waitingForSpace);
                  vehicles[i] = v;
                  continue; // Don't cycle stop index
                case OverflowPolicy.sellAtMarket:
                  final unitPrice = getPrice(v.cargoCropId!);
                  final saleValue = (v.cargoAmount * unitPrice * v.cargoQuality)
                      .round();
                  earnedCredits += saleValue;
                  earnedCredits +=
                      onMarketDelivery?.call(
                        contractId: route.contractId ?? '',
                        itemId: v.cargoCropId!,
                        amount: v.cargoAmount,
                        quality: v.cargoQuality,
                        saleValue: saleValue,
                      ) ??
                      0;
                  v = v.copyWith(
                    cargoCropId: null,
                    cargoAmount: 0,
                    cargoAgeMinutes: 0.0,
                    cargoQuality: 1.0,
                    totalEarnedCredits: v.totalEarnedCredits + saleValue,
                    totalDeliveriesCount: v.totalDeliveriesCount + 1,
                  );
                  break;
                case OverflowPolicy.keepInCargo:
                  // Keep cargo in truck and continue route
                  break;
              }
            }
          }

          v = v.copyWith(
            currentStopIndex: nextStopIndex,
            progressToNextStop: 0.0,
            status: VehicleStatus.traveling,
          );
        } else {
          v = v.copyWith(
            currentStopIndex: nextStopIndex,
            progressToNextStop: 0.0,
            status: VehicleStatus.traveling,
          );
        }
      } else {
        // Continue traveling
        v = v.copyWith(
          progressToNextStop: newProgress,
          cargoAgeMinutes: newAge,
          cargoQuality: newQuality,
          status: VehicleStatus.traveling,
        );
      }

      if (v.finishRouteAfterCycle && nextStopIndex == 0) {
        v = _finishOneShotRoute(v);
      }
      vehicles[i] = v;
    }

    return earnedCredits;
  }

  Map<String, dynamic> toJson() => {
    'warehouseCapacity': warehouseCapacity,
    'warehouseStock': warehouseStock.map((b) => b.toJson()).toList(),
    'routes': routes.map((r) => r.toJson()).toList(),
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
  };

  factory LogisticsFleetManager.fromJson(Map<String, dynamic> json) =>
      LogisticsFleetManager(
        warehouseCapacity: json['warehouseCapacity'] as int? ?? 200,
        warehouseStock:
            (json['warehouseStock'] as List<dynamic>?)
                ?.map((b) => CropStockBatch.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        routes:
            (json['routes'] as List<dynamic>?)
                ?.map((r) => TransportRoute.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        vehicles:
            (json['vehicles'] as List<dynamic>?)
                ?.map(
                  (v) => FleetVehicleState.fromJson(v as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
