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
  ),
  cow(
    name: 'Süt İneği',
    feedCropId: 'CR01', // Consumes silage / grain / pasture
    feedConsumptionPerMinute: 0.25,
    produceItemId: 'fresh_milk',
    produceValueCredits: 85,
    productionPerMinute: 0.18,
  ),
  sheep(
    name: 'Merinos Koyunu',
    feedCropId: 'CR01', // Consumes pasture grass / hay
    feedConsumptionPerMinute: 0.18,
    produceItemId: 'wool_bale',
    produceValueCredits: 120,
    productionPerMinute: 0.12,
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

/// Manages dairy cows, sheep, open pasture grazing, milk yield and wool shearing.
class LivestockPasture {
  LivestockPasture({
    this.cowCount = 0,
    this.maxCowCapacity = 30,
    this.sheepCount = 0,
    this.maxSheepCapacity = 40,
    this.feedStock = 0.0,
    this.maxFeedCapacity = 500.0,
    this.milkStock = 0,
    this.maxMilkCapacity = 250,
    this.woolStock = 0,
    this.maxWoolCapacity = 150,
    this.isPastureGrazingEnabled = false,
    bool? isUnlocked,
    this.milkProductionProgress = 0.0,
    this.woolProductionProgress = 0.0,
  }) : isUnlocked = isUnlocked ?? (cowCount > 0 || sheepCount > 0);

  int cowCount;
  int maxCowCapacity;
  int sheepCount;
  int maxSheepCapacity;
  double feedStock;
  double maxFeedCapacity;
  int milkStock;
  int maxMilkCapacity;
  int woolStock;
  int maxWoolCapacity;
  bool isPastureGrazingEnabled;
  bool isUnlocked;

  double milkProductionProgress;
  double woolProductionProgress;

  int get totalAnimals => cowCount + sheepCount;
  double get remainingFeedCapacity => max(0.0, maxFeedCapacity - feedStock);
  int get remainingMilkCapacity => max(0, maxMilkCapacity - milkStock);
  int get remainingWoolCapacity => max(0, maxWoolCapacity - woolStock);

  bool addFeed(double amount) {
    if (amount <= 0 || remainingFeedCapacity <= 0) return false;
    final toAdd = min(amount, remainingFeedCapacity);
    feedStock += toAdd;
    return true;
  }

  bool buyCows(
    int count,
    int creditCostPerCow, {
    required bool Function(int totalCost) paymentProcessor,
  }) {
    if (count <= 0 || cowCount + count > maxCowCapacity) return false;
    if (!paymentProcessor(count * creditCostPerCow)) return false;
    cowCount += count;
    isUnlocked = true;
    return true;
  }

  bool buySheep(
    int count,
    int creditCostPerSheep, {
    required bool Function(int totalCost) paymentProcessor,
  }) {
    if (count <= 0 || sheepCount + count > maxSheepCapacity) return false;
    if (!paymentProcessor(count * creditCostPerSheep)) return false;
    sheepCount += count;
    isUnlocked = true;
    return true;
  }

  int collectMilk() {
    final collected = milkStock;
    milkStock = 0;
    return collected;
  }

  int collectWool() {
    final collected = woolStock;
    woolStock = 0;
    return collected;
  }

  void update(double dtSeconds) {
    if (!isUnlocked || totalAnimals <= 0 || dtSeconds <= 0) return;

    final minutes = dtSeconds / 60.0;
    // When grazing on pasture, feed consumption is halved and animals produce slightly more
    final consumptionDiscount = isPastureGrazingEnabled ? 0.50 : 1.0;
    final productionMultiplier = isPastureGrazingEnabled ? 1.20 : 1.0;

    final cowsFeedNeeded =
        cowCount *
        AnimalType.cow.feedConsumptionPerMinute *
        minutes *
        consumptionDiscount;
    final sheepFeedNeeded =
        sheepCount *
        AnimalType.sheep.feedConsumptionPerMinute *
        minutes *
        consumptionDiscount;
    final totalNeeded = cowsFeedNeeded + sheepFeedNeeded;

    final hasEnoughFeed = feedStock >= totalNeeded;
    if (hasEnoughFeed) {
      feedStock -= totalNeeded;
    } else {
      feedStock = 0.0;
    }

    if (hasEnoughFeed || isPastureGrazingEnabled) {
      // Cows produce milk
      if (cowCount > 0) {
        final milkFraction =
            cowCount *
            AnimalType.cow.productionPerMinute *
            minutes *
            productionMultiplier;
        milkProductionProgress += milkFraction;
        final wholeMilk = milkProductionProgress.floor();
        if (wholeMilk > 0) {
          milkProductionProgress -= wholeMilk;
          milkStock = min(maxMilkCapacity, milkStock + wholeMilk);
        }
      }

      // Sheep produce wool
      if (sheepCount > 0) {
        final woolFraction =
            sheepCount *
            AnimalType.sheep.productionPerMinute *
            minutes *
            productionMultiplier;
        woolProductionProgress += woolFraction;
        final wholeWool = woolProductionProgress.floor();
        if (wholeWool > 0) {
          woolProductionProgress -= wholeWool;
          woolStock = min(maxWoolCapacity, woolStock + wholeWool);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'cowCount': cowCount,
    'maxCowCapacity': maxCowCapacity,
    'sheepCount': sheepCount,
    'maxSheepCapacity': maxSheepCapacity,
    'feedStock': feedStock,
    'maxFeedCapacity': maxFeedCapacity,
    'milkStock': milkStock,
    'maxMilkCapacity': maxMilkCapacity,
    'woolStock': woolStock,
    'maxWoolCapacity': maxWoolCapacity,
    'isPastureGrazingEnabled': isPastureGrazingEnabled,
    'isUnlocked': isUnlocked,
    'milkProductionProgress': milkProductionProgress,
    'woolProductionProgress': woolProductionProgress,
  };

  factory LivestockPasture.fromJson(Map<String, dynamic> json) =>
      LivestockPasture(
        cowCount: json['cowCount'] as int? ?? 0,
        maxCowCapacity: json['maxCowCapacity'] as int? ?? 30,
        sheepCount: json['sheepCount'] as int? ?? 0,
        maxSheepCapacity: json['maxSheepCapacity'] as int? ?? 40,
        feedStock: (json['feedStock'] as num?)?.toDouble() ?? 0.0,
        maxFeedCapacity:
            (json['maxFeedCapacity'] as num?)?.toDouble() ?? 500.0,
        milkStock: json['milkStock'] as int? ?? 0,
        maxMilkCapacity: json['maxMilkCapacity'] as int? ?? 250,
        woolStock: json['woolStock'] as int? ?? 0,
        maxWoolCapacity: json['maxWoolCapacity'] as int? ?? 150,
        isPastureGrazingEnabled:
            json['isPastureGrazingEnabled'] as bool? ?? false,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        milkProductionProgress:
            (json['milkProductionProgress'] as num?)?.toDouble() ?? 0.0,
        woolProductionProgress:
            (json['woolProductionProgress'] as num?)?.toDouble() ?? 0.0,
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
