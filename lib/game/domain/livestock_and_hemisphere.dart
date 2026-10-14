import 'dart:math';

import 'farm_calendar.dart';

/// Livestock types supported in Farm World.
enum AnimalType {
  chicken(
    name: 'Tavuk',
    feedCropId: 'CR01', // Consumes wheat or corn
    feedConsumptionPerMinute: 0.10,
    produceItemId: 'fresh_eggs',
    produceValueCredits: 45,
    productionPerMinute: 0.25,
  );

  const AnimalType({
    required this.name,
    required this.feedCropId,
    required this.feedConsumptionPerMinute,
    required this.produceItemId,
    required this.produceValueCredits,
    required this.productionPerMinute,
  });

  final String name;
  final String feedCropId;
  final double feedConsumptionPerMinute;
  final String produceItemId;
  final int produceValueCredits;
  final double productionPerMinute;
}

/// A chicken coop managing flock size, feed rations, and egg yields.
class ChickenCoop {
  ChickenCoop({
    this.chickenCount = 0,
    this.maxCapacity = 50,
    this.feedStock = 0.0,
    this.maxFeedCapacity = 200.0,
    this.eggStock = 0,
    this.maxEggCapacity = 100,
    bool? isUnlocked,
    this.eggProductionProgress = 0.0,
  }) : isUnlocked = isUnlocked ?? (chickenCount > 0);

  int chickenCount;
  int maxCapacity;
  double feedStock;
  double maxFeedCapacity;
  int eggStock;
  int maxEggCapacity;
  bool isUnlocked;

  double eggProductionProgress;

  bool get isFeedStarved => feedStock <= 0.01;
  double get remainingFeedCapacity => max(0.0, maxFeedCapacity - feedStock);
  int get remainingEggCapacity => max(0, maxEggCapacity - eggStock);

  /// Adds raw grain feed to the feeder.
  bool addFeed(double amount) {
    if (amount <= 0 || remainingFeedCapacity <= 0) return false;
    final toAdd = min(amount, remainingFeedCapacity);
    feedStock += toAdd;
    return true;
  }

  /// Collects all ready eggs for storage or direct delivery.
  int collectEggs() {
    final collected = eggStock;
    eggStock = 0;
    return collected;
  }

  int takeEggs(int amount) {
    if (amount <= 0 || eggStock <= 0) return 0;
    final taken = min(amount, eggStock);
    eggStock -= taken;
    return taken;
  }

  /// Purchases additional hens for the flock.
  bool buyChickens(
    int count,
    int creditCostPerChicken, {
    required bool Function(int totalCost) paymentProcessor,
  }) {
    if (count <= 0 || chickenCount + count > maxCapacity) return false;
    final totalCost = count * creditCostPerChicken;
    if (!paymentProcessor(totalCost)) return false;
    chickenCount += count;
    return true;
  }

  /// Deterministic update simulating consumption and egg production.
  void update(double dtSeconds) {
    if (!isUnlocked || chickenCount <= 0 || dtSeconds <= 0) return;

    final minutes = dtSeconds / 60.0;
    final feedNeeded =
        chickenCount * AnimalType.chicken.feedConsumptionPerMinute * minutes;

    if (feedStock >= feedNeeded) {
      feedStock -= feedNeeded;

      // Produce eggs
      final eggsProducedFraction =
          chickenCount * AnimalType.chicken.productionPerMinute * minutes;
      eggProductionProgress += eggsProducedFraction;

      final wholeEggs = eggProductionProgress.floor();
      if (wholeEggs > 0) {
        eggProductionProgress -= wholeEggs;
        eggStock = min(maxEggCapacity, eggStock + wholeEggs);
      }
    } else {
      // Consume whatever remaining feed is available; production pauses without starving animals to death
      feedStock = 0.0;
    }
  }

  Map<String, dynamic> toJson() => {
    'chickenCount': chickenCount,
    'maxCapacity': maxCapacity,
    'feedStock': feedStock,
    'maxFeedCapacity': maxFeedCapacity,
    'eggStock': eggStock,
    'maxEggCapacity': maxEggCapacity,
    'isUnlocked': isUnlocked,
    'eggProductionProgress': eggProductionProgress,
  };

  factory ChickenCoop.fromJson(Map<String, dynamic> json) => ChickenCoop(
    chickenCount: json['chickenCount'] as int? ?? 0,
    maxCapacity: json['maxCapacity'] as int? ?? 50,
    feedStock: (json['feedStock'] as num?)?.toDouble() ?? 0.0,
    maxFeedCapacity: (json['maxFeedCapacity'] as num?)?.toDouble() ?? 200.0,
    eggStock: json['eggStock'] as int? ?? 0,
    maxEggCapacity: json['maxEggCapacity'] as int? ?? 100,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    eggProductionProgress:
        (json['eggProductionProgress'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Operating region representation supporting multi-hemisphere expansion.
class FarmRegion {
  const FarmRegion({
    required this.id,
    required this.name,
    required this.hemisphere,
    required this.unlockCostCredits,
    this.isUnlocked = false,
  });

  final String id;
  final String name;
  final Hemisphere hemisphere;
  final int unlockCostCredits;
  final bool isUnlocked;

  Season currentSeasonAt(Duration elapsedTotal) {
    return FarmCalendar.resolve(elapsedTotal, hemisphere: hemisphere).season;
  }

  FarmRegion copyWith({bool? isUnlocked}) => FarmRegion(
    id: id,
    name: name,
    hemisphere: hemisphere,
    unlockCostCredits: unlockCostCredits,
    isUnlocked: isUnlocked ?? this.isUnlocked,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hemisphere': hemisphere.name,
    'unlockCostCredits': unlockCostCredits,
    'isUnlocked': isUnlocked,
  };

  factory FarmRegion.fromJson(Map<String, dynamic> json) => FarmRegion(
    id: json['id'] as String,
    name: json['name'] as String,
    hemisphere: Hemisphere.values.byName(json['hemisphere'] as String),
    unlockCostCredits: json['unlockCostCredits'] as int? ?? 0,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
  );
}

/// Regional territory manager handling planetary hemisphere expansions.
class TerritoryExpansionManager {
  TerritoryExpansionManager({List<FarmRegion>? regions})
    : regions = regions ?? List<FarmRegion>.from(defaultRegions);

  final List<FarmRegion> regions;

  static List<FarmRegion> get defaultRegions => const [
    FarmRegion(
      id: 'reg_northern_temperate',
      name: 'Kuzey Ilıman Bölge (Ana Çiftlik)',
      hemisphere: Hemisphere.northern,
      unlockCostCredits: 0,
      isUnlocked: true,
    ),
    FarmRegion(
      id: 'reg_southern_valley',
      name: 'Güney Vadi Operasyon Sahası',
      hemisphere: Hemisphere.southern,
      unlockCostCredits: 3500,
      isUnlocked: false,
    ),
  ];

  bool canUnlockSouthernHemisphere(int currentCredits) {
    final southern = regions.firstWhere((r) => r.id == 'reg_southern_valley');
    return !southern.isUnlocked && currentCredits >= southern.unlockCostCredits;
  }

  bool unlockSouthernHemisphere({required bool Function(int cost) pay}) {
    final idx = regions.indexWhere((r) => r.id == 'reg_southern_valley');
    if (idx == -1) return false;
    final southern = regions[idx];
    if (southern.isUnlocked) return false;

    if (!pay(southern.unlockCostCredits)) return false;
    regions[idx] = southern.copyWith(isUnlocked: true);
    return true;
  }

  Map<String, dynamic> toJson() => {
    'regions': regions.map((r) => r.toJson()).toList(),
  };

  factory TerritoryExpansionManager.fromJson(Map<String, dynamic> json) =>
      TerritoryExpansionManager(
        regions: (json['regions'] as List<dynamic>?)
            ?.map((r) => FarmRegion.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
