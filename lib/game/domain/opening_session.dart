/// Pure Dart domain model and session state for the Farm World opening hook.
///
/// Designed in accordance with:
/// - docs/game-design-brief.md (Section 2, Opening hook, grass sales & planting anchor line 87)
/// - docs/economy-and-progression-proposal.md (Section 2, Opening economy)
/// - docs/technology-tree-comprehensive-proposal.md (Section 3, H01 & H02 nodes)
library;

import 'dart:convert';
import 'dart:math';

import 'crop_cycle.dart';
import 'crop_plot.dart';
import 'farm_equipment.dart';
import 'farm_calendar.dart';
import 'logistics_fleet.dart';
import 'opening_crop_catalog.dart';
import 'processing_plant.dart';
import 'livestock_and_hemisphere.dart';
import 'procedural_farm_world.dart';
import 'farm_building.dart';
import 'market_price_simulator.dart';
import 'delivery_contracts.dart';
import 'audio_controller.dart';

/// Lifecycle stages of the opening gameplay hook.
enum OpeningStage {
  /// Initial stage: player controls manual scythe mowing.
  scythe,

  /// Upgraded stage: player owns the mini mower (H01).
  mower,

  /// Automated stage: worker hired (H02), manual control ends, management begins.
  management,
}

/// Immutable value object representing the snapshot state of an opening session.
class OpeningSessionState {
  const OpeningSessionState({
    this.farmCredits = 0,
    this.debt = 0,
    this.lifetimeProductionEvidence = 0,
    this.stage = OpeningStage.scythe,
    this.hasMower = false,
    this.hasWorker = false,
    this.isMowerAssignedToWorker = false,
    this.hasOwnedInitialPlot = false,
    this.freeInitialSeedsCount = 0,
    bool isCarryingBale = false,
    int carriedBalesCount = 0,
    this.backpackCapacity = 10,
    this.speedLevel = 0,
    this.rangeLevel = 0,
    this.capacityLevel = 0,
    this.groundBaleCount = 0,
    this.mowingProgressSeconds = 0.0,
    this.baleMowingDurationSeconds =
        OpeningSession.defaultBaleMowingDurationSeconds,
    this.firstSuccessfulPlantingAt,
    this.activeCropId,
    this.activeCropPlantedAt,
    this.hasHarvestedActiveCrop = false,
    this.hasCompletedStarterTrade = false,
    this.hasStarterTruck = false,
    this.soilConditionPoints = OpeningSession.initialSoilConditionPoints,
    this.automaticSoilCareEnabled = false,
    this.purchasedTechnologyIds = const <String>{},
    this.hasStandaloneResearchBudget = false,
    this.fullHarvestedCropIds = const <String>{},
    this.plots = const <CropPlotState>[],
    this.logisticsFleetJson,
    this.farmSystemsJson,
    this.worldSeed = ProceduralFarmWorld.defaultSeed,
    this.worldGenerationVersion = ProceduralFarmWorld.currentGenerationVersion,
    this.ownedWorldParcelIds = const <String>{},
    this.worldLogisticsLinks = const <WorldLogisticsLink>[],
    this.buildings = const <FarmBuildingInstance>[],
    this.equipmentStarterKitGranted = false,
    this.ownedEquipmentIds = const <String>{},
    this.equippedEquipmentByOperation = const <String, String>{},
    this.farmTutorialStep = FarmTutorialStep.story,
  }) : isCarryingBale = isCarryingBale || carriedBalesCount > 0,
       carriedBalesCount = carriedBalesCount > 0
           ? carriedBalesCount
           : (isCarryingBale ? 1 : 0);

  /// Canonical initial state for a brand-new player session.
  static const OpeningSessionState initial = OpeningSessionState();

  /// Primary player currency in Çiftlik Kredisi (ÇK).
  final int farmCredits;

  /// Player debt in ÇK. Never drops below 0 per design requirements.
  final int debt;

  /// Non-spending lifetime production evidence value for milestone P1 (in ÇK value).
  final int lifetimeProductionEvidence;

  /// Current lifecycle stage of the opening session.
  final OpeningStage stage;

  /// Whether the H01 mini mower has been acquired.
  final bool hasMower;

  /// Whether the H02 first worker has been hired.
  final bool hasWorker;

  /// Whether the mower has been handed over to the worker.
  final bool isMowerAssignedToWorker;

  /// Whether the player owns the initial starting plot.
  final bool hasOwnedInitialPlot;

  /// Number of free initial crop seeds available.
  final int freeInitialSeedsCount;

  /// Whether the player is currently carrying a grass bale.
  final bool isCarryingBale;

  /// Number of grass bales currently stacked in the player's backpack.
  final int carriedBalesCount;

  /// Maximum number of grass bales the backpack can hold.
  final int backpackCapacity;

  /// Purchased movement speed upgrade tier.
  final int speedLevel;

  /// Purchased mower cutting radius / blade width tier.
  final int rangeLevel;

  /// Purchased backpack capacity upgrade tier.
  final int capacityLevel;

  /// Number of ready grass bales currently lying on the ground.
  final int groundBaleCount;

  /// Continuous mowing seconds accumulated toward the next grass bale.
  final double mowingProgressSeconds;

  /// Configurable continuous mowing duration in seconds required to produce one bale.
  final double baleMowingDurationSeconds;

  /// Optional UTC timestamp of the first successful crop planting anchor.
  ///
  /// Per docs/game-design-brief.md:87, the player's personal 18-hour seasonal cycle
  /// begins after the first successful planting and continues offline.
  final DateTime? firstSuccessfulPlantingAt;

  /// Stable crop identifier for the currently growing starter field cycle.
  final String? activeCropId;

  /// UTC timestamp at which the current starter field cycle was planted.
  final DateTime? activeCropPlantedAt;

  /// Whether the current field cycle has already been collected.
  final bool hasHarvestedActiveCrop;

  /// Whether the mandatory first-harvest trade has been completed.
  final bool hasCompletedStarterTrade;

  /// Whether the one-time starter grain truck has been awarded.
  final bool hasStarterTruck;

  /// Starter plot condition on the design's 0–100 soil scale.
  final int soilConditionPoints;

  /// T02's automatic soil correction setting; disabled until purchased.
  final bool automaticSoilCareEnabled;

  /// Purchased opening technologies, stored as stable technology IDs.
  final Set<String> purchasedTechnologyIds;

  /// Whether the one-time budget for the standalone research-tree build was granted.
  final bool hasStandaloneResearchBudget;

  /// Crops that have produced at least one full, in-season harvest.
  final Set<String> fullHarvestedCropIds;

  /// Expansion crop plots managed in the farm management view.
  final List<CropPlotState> plots;

  /// Serialized live fleet state so autosaves detect vehicle movement and cargo.
  final String? logisticsFleetJson;

  /// Persisted market, contract, processing and livestock runtime state.
  final String? farmSystemsJson;

  /// Seed for the infinite deterministic world-map generator.
  final int worldSeed;

  /// Preserves parcel IDs for saves made before the versioned terrain update.
  final int worldGenerationVersion;

  /// Generated parcel IDs purchased by the player.
  final Set<String> ownedWorldParcelIds;

  /// Paid logistics corridors between purchased world parcels.
  final List<WorldLogisticsLink> worldLogisticsLinks;

  /// Placed facilities and their persistent construction/operating state.
  final List<FarmBuildingInstance> buildings;

  /// Whether the original, complete grain-equipment pack has been granted.
  final bool equipmentStarterKitGranted;

  /// Equipment owned by the farm, stored by stable catalogue ID.
  final Set<String> ownedEquipmentIds;

  /// One selected implement ID per operation, plus `tractor` as the power unit.
  final Map<String, String> equippedEquipmentByOperation;

  /// Persistent step in the one-time opening farm tutorial.
  final FarmTutorialStep farmTutorialStep;

  /// Returns whether the player has at least one free seed.
  bool get hasFreeInitialSeed => freeInitialSeedsCount > 0;

  /// Returns whether there is at least one bale on the ground.
  bool get hasGroundBale => groundBaleCount > 0;

  /// Returns whether the first successful crop planting anchor has been recorded.
  bool get hasFirstSuccessfulPlanting => firstSuccessfulPlantingAt != null;

  OpeningSessionState copyWith({
    int? farmCredits,
    int? debt,
    int? lifetimeProductionEvidence,
    OpeningStage? stage,
    bool? hasMower,
    bool? hasWorker,
    bool? isMowerAssignedToWorker,
    bool? hasOwnedInitialPlot,
    int? freeInitialSeedsCount,
    bool? isCarryingBale,
    int? carriedBalesCount,
    int? backpackCapacity,
    int? speedLevel,
    int? rangeLevel,
    int? capacityLevel,
    int? groundBaleCount,
    double? mowingProgressSeconds,
    double? baleMowingDurationSeconds,
    DateTime? firstSuccessfulPlantingAt,
    String? activeCropId,
    DateTime? activeCropPlantedAt,
    bool? hasHarvestedActiveCrop,
    bool? hasCompletedStarterTrade,
    bool? hasStarterTruck,
    int? soilConditionPoints,
    bool? automaticSoilCareEnabled,
    Set<String>? purchasedTechnologyIds,
    bool? hasStandaloneResearchBudget,
    Set<String>? fullHarvestedCropIds,
    List<CropPlotState>? plots,
    String? logisticsFleetJson,
    String? farmSystemsJson,
    int? worldSeed,
    int? worldGenerationVersion,
    Set<String>? ownedWorldParcelIds,
    List<WorldLogisticsLink>? worldLogisticsLinks,
    List<FarmBuildingInstance>? buildings,
    bool? equipmentStarterKitGranted,
    Set<String>? ownedEquipmentIds,
    Map<String, String>? equippedEquipmentByOperation,
    FarmTutorialStep? farmTutorialStep,
  }) {
    return OpeningSessionState(
      farmCredits: farmCredits ?? this.farmCredits,
      debt: debt ?? this.debt,
      lifetimeProductionEvidence:
          lifetimeProductionEvidence ?? this.lifetimeProductionEvidence,
      stage: stage ?? this.stage,
      hasMower: hasMower ?? this.hasMower,
      hasWorker: hasWorker ?? this.hasWorker,
      isMowerAssignedToWorker:
          isMowerAssignedToWorker ?? this.isMowerAssignedToWorker,
      hasOwnedInitialPlot: hasOwnedInitialPlot ?? this.hasOwnedInitialPlot,
      freeInitialSeedsCount:
          freeInitialSeedsCount ?? this.freeInitialSeedsCount,
      isCarryingBale: isCarryingBale ?? this.isCarryingBale,
      carriedBalesCount: carriedBalesCount ?? this.carriedBalesCount,
      backpackCapacity: backpackCapacity ?? this.backpackCapacity,
      speedLevel: speedLevel ?? this.speedLevel,
      rangeLevel: rangeLevel ?? this.rangeLevel,
      capacityLevel: capacityLevel ?? this.capacityLevel,
      groundBaleCount: groundBaleCount ?? this.groundBaleCount,
      mowingProgressSeconds:
          mowingProgressSeconds ?? this.mowingProgressSeconds,
      baleMowingDurationSeconds:
          baleMowingDurationSeconds ?? this.baleMowingDurationSeconds,
      firstSuccessfulPlantingAt:
          firstSuccessfulPlantingAt ?? this.firstSuccessfulPlantingAt,
      activeCropId: activeCropId ?? this.activeCropId,
      activeCropPlantedAt: activeCropPlantedAt ?? this.activeCropPlantedAt,
      hasHarvestedActiveCrop:
          hasHarvestedActiveCrop ?? this.hasHarvestedActiveCrop,
      hasCompletedStarterTrade:
          hasCompletedStarterTrade ?? this.hasCompletedStarterTrade,
      hasStarterTruck: hasStarterTruck ?? this.hasStarterTruck,
      soilConditionPoints: soilConditionPoints ?? this.soilConditionPoints,
      automaticSoilCareEnabled:
          automaticSoilCareEnabled ?? this.automaticSoilCareEnabled,
      purchasedTechnologyIds:
          purchasedTechnologyIds ?? this.purchasedTechnologyIds,
      hasStandaloneResearchBudget:
          hasStandaloneResearchBudget ?? this.hasStandaloneResearchBudget,
      fullHarvestedCropIds: fullHarvestedCropIds ?? this.fullHarvestedCropIds,
      plots: plots ?? this.plots,
      logisticsFleetJson: logisticsFleetJson ?? this.logisticsFleetJson,
      farmSystemsJson: farmSystemsJson ?? this.farmSystemsJson,
      worldSeed: worldSeed ?? this.worldSeed,
      worldGenerationVersion:
          worldGenerationVersion ?? this.worldGenerationVersion,
      ownedWorldParcelIds: ownedWorldParcelIds ?? this.ownedWorldParcelIds,
      worldLogisticsLinks: worldLogisticsLinks ?? this.worldLogisticsLinks,
      buildings: buildings ?? this.buildings,
      equipmentStarterKitGranted:
          equipmentStarterKitGranted ?? this.equipmentStarterKitGranted,
      ownedEquipmentIds: ownedEquipmentIds ?? this.ownedEquipmentIds,
      equippedEquipmentByOperation:
          equippedEquipmentByOperation ?? this.equippedEquipmentByOperation,
      farmTutorialStep: farmTutorialStep ?? this.farmTutorialStep,
    );
  }

  Map<String, dynamic> toJson() => {
    'farmCredits': farmCredits,
    'debt': debt,
    'lifetimeProductionEvidence': lifetimeProductionEvidence,
    'stage': stage.name,
    'hasMower': hasMower,
    'hasWorker': hasWorker,
    'isMowerAssignedToWorker': isMowerAssignedToWorker,
    'hasOwnedInitialPlot': hasOwnedInitialPlot,
    'freeInitialSeedsCount': freeInitialSeedsCount,
    'isCarryingBale': isCarryingBale,
    'carriedBalesCount': carriedBalesCount,
    'backpackCapacity': backpackCapacity,
    'speedLevel': speedLevel,
    'rangeLevel': rangeLevel,
    'capacityLevel': capacityLevel,
    'groundBaleCount': groundBaleCount,
    'mowingProgressSeconds': mowingProgressSeconds,
    'baleMowingDurationSeconds': baleMowingDurationSeconds,
    if (firstSuccessfulPlantingAt != null)
      'firstSuccessfulPlantingAt': firstSuccessfulPlantingAt!
          .toUtc()
          .toIso8601String(),
    if (activeCropId != null) 'activeCropId': activeCropId,
    if (activeCropPlantedAt != null)
      'activeCropPlantedAt': activeCropPlantedAt!.toUtc().toIso8601String(),
    'hasHarvestedActiveCrop': hasHarvestedActiveCrop,
    'hasCompletedStarterTrade': hasCompletedStarterTrade,
    'hasStarterTruck': hasStarterTruck,
    'soilConditionPoints': soilConditionPoints,
    'automaticSoilCareEnabled': automaticSoilCareEnabled,
    'purchasedTechnologyIds': purchasedTechnologyIds.toList()..sort(),
    'hasStandaloneResearchBudget': hasStandaloneResearchBudget,
    'fullHarvestedCropIds': fullHarvestedCropIds.toList()..sort(),
    'plots': plots.map((p) => p.toJson()).toList(),
    if (logisticsFleetJson != null)
      'logisticsFleet': jsonDecode(logisticsFleetJson!),
    if (farmSystemsJson != null) 'farmSystems': jsonDecode(farmSystemsJson!),
    'worldSeed': worldSeed,
    'worldGenerationVersion': worldGenerationVersion,
    'ownedWorldParcelIds': ownedWorldParcelIds.toList()..sort(),
    'worldLogisticsLinks': worldLogisticsLinks
        .map((link) => link.toJson())
        .toList(),
    'buildings': buildings.map((building) => building.toJson()).toList(),
    'equipmentStarterKitGranted': equipmentStarterKitGranted,
    'ownedEquipmentIds': ownedEquipmentIds.toList()..sort(),
    'equippedEquipmentByOperation': equippedEquipmentByOperation,
    'farmTutorialStep': farmTutorialStep.name,
  };

  factory OpeningSessionState.fromJson(Map<String, dynamic> json) {
    final ownedParcelIds =
        (json['ownedWorldParcelIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet();
    return OpeningSessionState(
      farmCredits: json['farmCredits'] as int? ?? 0,
      debt: json['debt'] as int? ?? 0,
      lifetimeProductionEvidence:
          json['lifetimeProductionEvidence'] as int? ?? 0,
      stage: OpeningStage.values.byName(
        json['stage'] as String? ?? OpeningStage.scythe.name,
      ),
      hasMower: json['hasMower'] as bool? ?? false,
      hasWorker: json['hasWorker'] as bool? ?? false,
      isMowerAssignedToWorker:
          json['isMowerAssignedToWorker'] as bool? ?? false,
      hasOwnedInitialPlot: json['hasOwnedInitialPlot'] as bool? ?? false,
      freeInitialSeedsCount: json['freeInitialSeedsCount'] as int? ?? 0,
      isCarryingBale: json['isCarryingBale'] as bool? ?? false,
      carriedBalesCount: json['carriedBalesCount'] as int? ?? 0,
      backpackCapacity: json['backpackCapacity'] as int? ?? 10,
      speedLevel: json['speedLevel'] as int? ?? 0,
      rangeLevel: json['rangeLevel'] as int? ?? 0,
      capacityLevel: json['capacityLevel'] as int? ?? 0,
      groundBaleCount: json['groundBaleCount'] as int? ?? 0,
      mowingProgressSeconds:
          (json['mowingProgressSeconds'] as num?)?.toDouble() ?? 0.0,
      baleMowingDurationSeconds:
          (json['baleMowingDurationSeconds'] as num?)?.toDouble() ??
          OpeningSession.defaultBaleMowingDurationSeconds,
      firstSuccessfulPlantingAt:
          (json['firstSuccessfulPlantingAt'] ??
                  json['firstSuccessfulPlantingTime']) !=
              null
          ? DateTime.parse(
              (json['firstSuccessfulPlantingAt'] ??
                      json['firstSuccessfulPlantingTime'])
                  as String,
            ).toUtc()
          : null,
      activeCropId: json['activeCropId'] as String?,
      activeCropPlantedAt: json['activeCropPlantedAt'] != null
          ? DateTime.parse(json['activeCropPlantedAt'] as String).toUtc()
          : null,
      hasHarvestedActiveCrop: json['hasHarvestedActiveCrop'] as bool? ?? false,
      hasCompletedStarterTrade:
          json['hasCompletedStarterTrade'] as bool? ?? false,
      hasStarterTruck: json['hasStarterTruck'] as bool? ?? false,
      soilConditionPoints:
          json['soilConditionPoints'] as int? ??
          OpeningSession.initialSoilConditionPoints,
      automaticSoilCareEnabled:
          json['automaticSoilCareEnabled'] as bool? ?? false,
      purchasedTechnologyIds:
          (json['purchasedTechnologyIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet(),
      hasStandaloneResearchBudget:
          json['hasStandaloneResearchBudget'] as bool? ?? false,
      fullHarvestedCropIds:
          (json['fullHarvestedCropIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet(),
      plots: (json['plots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CropPlotState.fromJson)
          .toList(),
      logisticsFleetJson: json['logisticsFleet'] is Map<String, dynamic>
          ? jsonEncode(json['logisticsFleet'])
          : null,
      farmSystemsJson: json['farmSystems'] is Map<String, dynamic>
          ? jsonEncode(json['farmSystems'])
          : null,
      worldSeed: json['worldSeed'] as int? ?? ProceduralFarmWorld.defaultSeed,
      worldGenerationVersion:
          json['worldGenerationVersion'] as int? ??
          (ownedParcelIds.isEmpty
              ? ProceduralFarmWorld.currentGenerationVersion
              : ProceduralFarmWorld.legacyGenerationVersion),
      ownedWorldParcelIds: ownedParcelIds,
      worldLogisticsLinks:
          (json['worldLogisticsLinks'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(WorldLogisticsLink.fromJson)
              .toList(),
      buildings: (json['buildings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FarmBuildingInstance.fromJson)
          .toList(),
      equipmentStarterKitGranted:
          json['equipmentStarterKitGranted'] as bool? ?? false,
      ownedEquipmentIds:
          (json['ownedEquipmentIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet(),
      equippedEquipmentByOperation:
          (json['equippedEquipmentByOperation'] as Map<String, dynamic>? ??
                  const <String, dynamic>{})
              .map((key, value) => MapEntry(key, value as String)),
      farmTutorialStep: _farmTutorialStepFromJson(json),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpeningSessionState &&
        other.farmCredits == farmCredits &&
        other.debt == debt &&
        other.lifetimeProductionEvidence == lifetimeProductionEvidence &&
        other.stage == stage &&
        other.hasMower == hasMower &&
        other.hasWorker == hasWorker &&
        other.isMowerAssignedToWorker == isMowerAssignedToWorker &&
        other.hasOwnedInitialPlot == hasOwnedInitialPlot &&
        other.freeInitialSeedsCount == freeInitialSeedsCount &&
        other.isCarryingBale == isCarryingBale &&
        other.carriedBalesCount == carriedBalesCount &&
        other.backpackCapacity == backpackCapacity &&
        other.speedLevel == speedLevel &&
        other.rangeLevel == rangeLevel &&
        other.capacityLevel == capacityLevel &&
        other.groundBaleCount == groundBaleCount &&
        other.mowingProgressSeconds == mowingProgressSeconds &&
        other.baleMowingDurationSeconds == baleMowingDurationSeconds &&
        other.firstSuccessfulPlantingAt == firstSuccessfulPlantingAt &&
        other.activeCropId == activeCropId &&
        other.activeCropPlantedAt == activeCropPlantedAt &&
        other.hasHarvestedActiveCrop == hasHarvestedActiveCrop &&
        other.hasCompletedStarterTrade == hasCompletedStarterTrade &&
        other.hasStarterTruck == hasStarterTruck &&
        other.soilConditionPoints == soilConditionPoints &&
        other.automaticSoilCareEnabled == automaticSoilCareEnabled &&
        _stringSetsEqual(
          other.purchasedTechnologyIds,
          purchasedTechnologyIds,
        ) &&
        other.hasStandaloneResearchBudget == hasStandaloneResearchBudget &&
        _stringSetsEqual(other.fullHarvestedCropIds, fullHarvestedCropIds) &&
        _cropPlotsEqual(other.plots, plots) &&
        other.logisticsFleetJson == logisticsFleetJson &&
        other.farmSystemsJson == farmSystemsJson &&
        other.worldSeed == worldSeed &&
        other.worldGenerationVersion == worldGenerationVersion &&
        _stringSetsEqual(other.ownedWorldParcelIds, ownedWorldParcelIds) &&
        _worldLogisticsLinksEqual(
          other.worldLogisticsLinks,
          worldLogisticsLinks,
        ) &&
        _farmBuildingsEqual(other.buildings, buildings) &&
        other.equipmentStarterKitGranted == equipmentStarterKitGranted &&
        _stringSetsEqual(other.ownedEquipmentIds, ownedEquipmentIds) &&
        _stringMapsEqual(
          other.equippedEquipmentByOperation,
          equippedEquipmentByOperation,
        ) &&
        other.farmTutorialStep == farmTutorialStep;
  }

  @override
  int get hashCode => Object.hashAll([
    farmCredits,
    debt,
    lifetimeProductionEvidence,
    stage,
    hasMower,
    hasWorker,
    isMowerAssignedToWorker,
    hasOwnedInitialPlot,
    freeInitialSeedsCount,
    isCarryingBale,
    carriedBalesCount,
    backpackCapacity,
    speedLevel,
    rangeLevel,
    capacityLevel,
    groundBaleCount,
    mowingProgressSeconds,
    baleMowingDurationSeconds,
    firstSuccessfulPlantingAt,
    activeCropId,
    activeCropPlantedAt,
    hasHarvestedActiveCrop,
    hasCompletedStarterTrade,
    hasStarterTruck,
    soilConditionPoints,
    automaticSoilCareEnabled,
    Object.hashAll(purchasedTechnologyIds.toList()..sort()),
    hasStandaloneResearchBudget,
    Object.hashAll(fullHarvestedCropIds.toList()..sort()),
    Object.hashAll(plots),
    logisticsFleetJson,
    farmSystemsJson,
    worldSeed,
    worldGenerationVersion,
    Object.hashAll(ownedWorldParcelIds.toList()..sort()),
    Object.hashAll(worldLogisticsLinks),
    Object.hashAll(buildings),
    equipmentStarterKitGranted,
    Object.hashAll(ownedEquipmentIds.toList()..sort()),
    Object.hashAll(
      equippedEquipmentByOperation.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    ),
    farmTutorialStep,
  ]);

  @override
  String toString() => 'OpeningSessionState(${toJson()})';
}

bool _stringSetsEqual(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

FarmTutorialStep _farmTutorialStepFromJson(Map<String, dynamic> json) {
  if (json.containsKey('farmTutorialStep')) {
    return FarmEquipmentCatalog.tutorialStepFromJson(json['farmTutorialStep']);
  }
  if (json['hasCompletedStarterTrade'] as bool? ?? false) {
    return FarmTutorialStep.complete;
  }
  final plots = (json['plots'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>();
  final hasPriorFieldWork =
      json['activeCropId'] != null ||
      json['hasHarvestedActiveCrop'] == true ||
      plots.any(
        (plot) =>
            plot['activeCropId'] != null ||
            plot['isCultivated'] == true ||
            plot['hasHarvestedActiveCrop'] == true ||
            (plot['readyGrassBales'] as int? ?? 0) > 0,
      );
  return hasPriorFieldWork ? FarmTutorialStep.complete : FarmTutorialStep.story;
}

bool _stringMapsEqual(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

bool _cropPlotsEqual(List<CropPlotState> left, List<CropPlotState> right) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((same) => same);

bool _worldLogisticsLinksEqual(
  List<WorldLogisticsLink> left,
  List<WorldLogisticsLink> right,
) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((same) => same);

bool _farmBuildingsEqual(
  List<FarmBuildingInstance> left,
  List<FarmBuildingInstance> right,
) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((same) => same);

/// Domain session manager for the Farm World opening hook.
///
/// Encapsulates state transitions, deterministic timing rules, and economic gates.
class OpeningSession {
  static const Duration tutorialCropGrowthDuration = Duration(seconds: 15);

  OpeningSession({
    OpeningSessionState? initialState,
    double baleMowingDurationSeconds = defaultBaleMowingDurationSeconds,
  }) : _state =
           initialState ??
           OpeningSessionState(
             baleMowingDurationSeconds: baleMowingDurationSeconds,
           ) {
    _validateBaleDuration(baleMowingDurationSeconds);
    _validateBaleDuration(_state.baleMowingDurationSeconds);
    fleetManager = _restoreFleetManager(_state.logisticsFleetJson);
    final savedSystems = _decodeFarmSystems(_state.farmSystemsJson);
    plantManager = savedSystems['plantManager'] is Map<String, dynamic>
        ? ProcessingPlantManager.fromJson(
            savedSystems['plantManager'] as Map<String, dynamic>,
          )
        : ProcessingPlantManager();
    coop = savedSystems['coop'] is Map<String, dynamic>
        ? ChickenCoop.fromJson(savedSystems['coop'] as Map<String, dynamic>)
        : ChickenCoop();
    marketPrices = savedSystems['market'] is Map<String, dynamic>
        ? MarketPriceSimulator.fromJson(
            savedSystems['market'] as Map<String, dynamic>,
          )
        : MarketPriceSimulator();
    contractManager = savedSystems['contracts'] is Map<String, dynamic>
        ? DeliveryContractManager.fromJson(
            savedSystems['contracts'] as Map<String, dynamic>,
          )
        : DeliveryContractManager();
    _buildingProductionProgress =
        (savedSystems['buildingProductionProgress'] as Map<String, dynamic>? ??
                const <String, dynamic>{})
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
    final initializedAt = DateTime.now().toUtc();
    _syncOperationalBuildings(initializedAt);
    _advanceContractOffers(initializedAt);
    for (final plot in _state.plots) {
      final job = plot.activeJob;
      if (job != null) _activeFarmJobsByPlotId[plot.id] = job;
    }
  }

  factory OpeningSession.initial({
    double baleMowingDurationSeconds = defaultBaleMowingDurationSeconds,
  }) {
    return OpeningSession(baleMowingDurationSeconds: baleMowingDurationSeconds);
  }

  static void _validateBaleDuration(double duration) {
    if (!duration.isFinite || duration <= 0) {
      throw ArgumentError.value(
        duration,
        'baleMowingDurationSeconds',
        'Bale mowing duration must be finite and greater than zero.',
      );
    }
  }

  OpeningSessionState _state;
  OpeningSessionState? _plotsCacheState;
  List<CropPlotState> _plotsCache = const [];
  Map<int, CropPlotState> _plotsByIdCache = const {};
  int _ownedPlotCountCache = 0;
  final Map<int, FarmOperationJob> _activeFarmJobsByPlotId = {};
  late final Map<String, double> _buildingProductionProgress;

  /// Autonomous logistics and fleet manager for truck routes and deliveries.
  late final LogisticsFleetManager fleetManager;

  static Map<String, dynamic> _decodeFarmSystems(String? snapshot) {
    if (snapshot == null) return const {};
    try {
      final decoded = jsonDecode(snapshot);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static LogisticsFleetManager _restoreFleetManager(String? snapshot) {
    if (snapshot == null) return LogisticsFleetManager();
    try {
      final decoded = jsonDecode(snapshot);
      if (decoded is Map<String, dynamic>) {
        return LogisticsFleetManager.fromJson(decoded);
      }
    } catch (_) {
      // A malformed optional fleet snapshot should not invalidate the full farm save.
    }
    return LogisticsFleetManager();
  }

  /// Industrial processing plants converting crops into flour, oil, and starch.
  late final ProcessingPlantManager plantManager;

  /// Poultry livestock coop managing hens, grain feeding and egg yields.
  late final ChickenCoop coop;

  late final MarketPriceSimulator marketPrices;

  late final DeliveryContractManager contractManager;

  /// Multi-hemisphere planetary territory expansion manager.
  final TerritoryExpansionManager territoryManager =
      TerritoryExpansionManager();

  /// Current immutable state snapshot.
  OpeningSessionState get state => _state.copyWith(
    logisticsFleetJson: jsonEncode(fleetManager.toJson()),
    farmSystemsJson: jsonEncode(_farmSystemsToJson()),
  );

  Map<String, dynamic> _farmSystemsToJson() => {
    'plantManager': plantManager.toJson(),
    'coop': coop.toJson(),
    'market': marketPrices.toJson(),
    'contracts': contractManager.toJson(),
    'buildingProductionProgress': _buildingProductionProgress,
  };

  void _advanceContractOffers(DateTime now) {
    final dayIndex =
        now.toUtc().millisecondsSinceEpoch ~/
        const Duration(days: 1).inMilliseconds;
    final items = <String>{
      ...OpeningCropCatalog.all
          .where((crop) => _cropTechnologyAvailable(crop.id))
          .map((crop) => crop.id),
      ...fleetManager.warehouseStock.map((batch) => batch.cropId),
      for (final facility in plantManager.facilities)
        for (final recipeId in availableProcessingRecipeIds(facility, at: now))
          if (ProcessingRecipeCatalog.byId(recipeId) case final recipe?)
            recipe.outputItemId,
      if (coop.isUnlocked) 'fresh_eggs',
    };
    contractManager.advance(
      now,
      dayIndex: dayIndex,
      itemIds: items.toList()..sort(),
      unitPrice: marketPrices.getBasePrice,
    );
  }

  int get ownedPlotCount {
    _ensurePlotsCache();
    return _ownedPlotCountCache;
  }

  List<CropPlotState> get plotsWithActiveJobs {
    _ensurePlotsCache();
    return [
      for (final id in _activeFarmJobsByPlotId.keys) ?_plotsByIdCache[id],
    ];
  }

  FarmTutorialStep get tutorialStep => _state.farmTutorialStep;

  bool get isFarmTutorialComplete =>
      _state.farmTutorialStep == FarmTutorialStep.complete;

  bool isEquipmentOwned(String equipmentId) =>
      _state.ownedEquipmentIds.contains(equipmentId);

  bool hasResearch(String technologyId) =>
      hasPurchasedTechnology(technologyId) ||
      (technologyId == 'H01' && hasMower) ||
      (technologyId == 'H02' && hasWorker);

  bool canBuyEquipment(FarmEquipment item) {
    final requirement = item.requiredResearchId;
    return requirement == null || hasResearch(requirement);
  }

  bool canBuyTruck(TruckType type) {
    final requirement = type.requiredTechnologyId;
    return _state.stage == OpeningStage.management &&
        type != TruckType.starter &&
        (requirement == null || hasResearch(requirement)) &&
        _state.farmCredits >= type.purchaseCostCredits;
  }

  bool buyTruck(TruckType type) {
    if (!canBuyTruck(type)) return false;
    if (!fleetManager.purchaseTruck(type)) return false;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - type.purchaseCostCredits,
    );
    return true;
  }

  bool canBuyTrailer(TrailerType type, String vehicleId) {
    final vehicleIndex = fleetManager.vehicles.indexWhere(
      (item) => item.id == vehicleId,
    );
    if (vehicleIndex < 0) return false;
    final vehicle = fleetManager.vehicles[vehicleIndex];
    return vehicle.truckType.acceptsTrailer &&
        vehicle.trailerType != type &&
        type.requiredTechnologyIds.every(hasResearch) &&
        _state.farmCredits >= type.purchaseCostCredits;
  }

  bool buyTrailer(TrailerType type, String vehicleId) {
    if (!canBuyTrailer(type, vehicleId)) return false;
    if (!fleetManager.purchaseTrailer(type, vehicleId)) return false;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - type.purchaseCostCredits,
    );
    return true;
  }

  FarmEquipment? equippedEquipmentFor(FarmOperation operation) {
    final id = _state.equippedEquipmentByOperation[operation.name];
    if (id == null || !isEquipmentOwned(id)) return null;
    return FarmEquipmentCatalog.forOperation(operation, id);
  }

  FarmEquipment? get equippedTractor {
    final id = _state.equippedEquipmentByOperation['tractor'];
    if (id == null || !isEquipmentOwned(id)) return null;
    final tractor = FarmEquipmentCatalog.byId(id);
    return tractor?.isTractor == true ? tractor : null;
  }

  /// Finds an owned, currently unreserved implement and (when needed) tractor.
  /// Persisted active jobs hold these physical machine IDs until completion.
  ({FarmEquipment equipment, FarmEquipment? tractor})?
  _availableEquipmentAssignmentFor(FarmOperation operation) {
    final busyEquipmentIds = <String>{};
    final busyTractorIds = <String>{};
    final legacyTractorId = equippedTractor?.id;
    for (final job in _activeFarmJobsByPlotId.values) {
      busyEquipmentIds.add(job.equipmentId);
      final jobEquipment = FarmEquipmentCatalog.byId(job.equipmentId);
      final tractorId =
          job.tractorEquipmentId ??
          (jobEquipment?.requiresTractor == true ? legacyTractorId : null);
      if (tractorId != null) busyTractorIds.add(tractorId);
    }

    final preferredEquipment = equippedEquipmentFor(operation);
    final candidates =
        FarmEquipmentCatalog.all
            .where(
              (item) =>
                  !item.isTractor &&
                  item.operation == operation &&
                  isEquipmentOwned(item.id) &&
                  !busyEquipmentIds.contains(item.id),
            )
            .toList()
          ..sort((left, right) {
            if (left.id == preferredEquipment?.id) return -1;
            if (right.id == preferredEquipment?.id) return 1;
            return right.workRateRating.compareTo(left.workRateRating);
          });

    final preferredTractor = equippedTractor;
    for (final equipment in candidates) {
      if (!equipment.requiresTractor) {
        return (equipment: equipment, tractor: null);
      }
      final tractors =
          FarmEquipmentCatalog.all
              .where(
                (item) =>
                    item.isTractor &&
                    isEquipmentOwned(item.id) &&
                    !busyTractorIds.contains(item.id) &&
                    equipment.canOperateWithTractor(item),
              )
              .toList()
            ..sort((left, right) {
              if (left.id == preferredTractor?.id) return -1;
              if (right.id == preferredTractor?.id) return 1;
              return left.torqueCapacityNm.compareTo(right.torqueCapacityNm);
            });
      if (tractors.isNotEmpty) {
        return (equipment: equipment, tractor: tractors.first);
      }
    }
    return null;
  }

  String? equipmentCompatibilityIssue(
    FarmEquipment equipment, {
    FarmEquipment? tractorOverride,
  }) {
    if (equipment.isTractor) {
      final proposedSetup = {
        ..._state.equippedEquipmentByOperation,
        'tractor': equipment.id,
      };
      return _equipmentSetupCompatibilityIssue(proposedSetup);
    }
    if (!equipment.requiresTractor) return null;

    final tractor = tractorOverride ?? equippedTractor;
    if (tractor == null) {
      return 'Bu ekipman için en az ${equipment.requiredTractorTorqueNm} Nm torklu bir traktör gerekli.';
    }
    if (!equipment.canOperateWithTractor(tractor)) {
      return '${equipment.name} ${equipment.requiredTractorTorqueNm} Nm istiyor; ${tractor.name} ${tractor.torqueCapacityNm} Nm sağlıyor.';
    }
    return null;
  }

  String? get equippedEquipmentCompatibilityIssue =>
      _equipmentSetupCompatibilityIssue(_state.equippedEquipmentByOperation);

  String? equipmentPackCompatibilityIssue(Iterable<String> equipmentIds) {
    final ids = equipmentIds.toList(growable: false);
    final items = ids
        .map(FarmEquipmentCatalog.byId)
        .whereType<FarmEquipment>()
        .toList(growable: false);
    if (items.isEmpty || items.length != ids.toSet().length) {
      return 'Paket içeriği geçersiz.';
    }
    final proposedSetup = {..._state.equippedEquipmentByOperation};
    for (final item in items) {
      proposedSetup[item.slotKey] = item.id;
    }
    return _equipmentSetupCompatibilityIssue(proposedSetup);
  }

  String? _equipmentSetupCompatibilityIssue(Map<String, String> setup) {
    final tractorId = setup['tractor'];
    final foundTractor = tractorId == null
        ? null
        : FarmEquipmentCatalog.byId(tractorId);
    final tractor = foundTractor?.isTractor == true ? foundTractor : null;
    for (final operation in FarmOperation.values) {
      final equipmentId = setup[operation.name];
      if (equipmentId == null) continue;
      final equipment = FarmEquipmentCatalog.forOperation(
        operation,
        equipmentId,
      );
      if (equipment == null) continue;
      final issue = equipmentCompatibilityIssue(
        equipment,
        tractorOverride: tractor,
      );
      if (issue != null) return issue;
    }
    return null;
  }

  bool canUseEquippedEquipmentFor(FarmOperation operation) {
    return _availableEquipmentAssignmentFor(operation) != null;
  }

  Duration operationDurationFor(
    FarmOperation operation,
    int areaSquareMeters, {
    bool tutorialFast = false,
  }) {
    final assignment = _availableEquipmentAssignmentFor(operation);
    if (assignment == null) return operation.standardDuration;
    return assignment.equipment.durationFor(
      areaSquareMeters,
      tutorialFast: tutorialFast,
      tractor: assignment.tractor,
    );
  }

  bool grantStarterEquipmentOnce() {
    if (_state.equipmentStarterKitGranted) return false;
    final owned = {..._state.ownedEquipmentIds};
    final equipped = {..._state.equippedEquipmentByOperation};
    for (final item in FarmEquipmentCatalog.starterSet) {
      owned.add(item.id);
      equipped[item.operation.name] = item.id;
    }
    final tractor = FarmEquipmentCatalog.starterTractor;
    if (tractor != null) {
      owned.add(tractor.id);
      equipped['tractor'] = tractor.id;
    }
    _state = _state.copyWith(
      equipmentStarterKitGranted: true,
      ownedEquipmentIds: owned,
      equippedEquipmentByOperation: equipped,
    );
    return true;
  }

  bool buyEquipment(String equipmentId, {bool usedOffer = false}) {
    final item = FarmEquipmentCatalog.byId(equipmentId);
    final price = item == null
        ? null
        : usedOffer
        ? (item.purchasePrice * 0.82).round()
        : item.purchasePrice;
    if (item == null ||
        isEquipmentOwned(equipmentId) ||
        !canBuyEquipment(item) ||
        price == null ||
        _state.farmCredits < price) {
      return false;
    }
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - price,
      ownedEquipmentIds: {..._state.ownedEquipmentIds, equipmentId},
    );
    return true;
  }

  bool buyEquipmentPack(
    Iterable<String> equipmentIds, {
    double discount = 0.10,
  }) {
    final ids = equipmentIds.toList(growable: false);
    final items = ids
        .map(FarmEquipmentCatalog.byId)
        .whereType<FarmEquipment>()
        .toList(growable: false);
    if (items.isEmpty || items.length != ids.toSet().length) {
      return false;
    }
    final newItems = items
        .where((item) => !isEquipmentOwned(item.id))
        .toList(growable: false);
    if (newItems.isEmpty) return false;
    if (newItems.any((item) => !canBuyEquipment(item))) return false;
    final compatibilityIssue = equipmentPackCompatibilityIssue(ids);
    if (compatibilityIssue != null) return false;
    final fullPrice = newItems.fold<int>(
      0,
      (total, item) => total + item.purchasePrice,
    );
    final bundlePrice = (fullPrice * (1 - discount.clamp(0, 0.5))).round();
    if (_state.farmCredits < bundlePrice) return false;

    final owned = {..._state.ownedEquipmentIds};
    final equipped = {..._state.equippedEquipmentByOperation};
    for (final item in items) {
      owned.add(item.id);
      equipped[item.slotKey] = item.id;
    }
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - bundlePrice,
      ownedEquipmentIds: owned,
      equippedEquipmentByOperation: equipped,
    );
    return true;
  }

  bool equipEquipment(String equipmentId) {
    final item = FarmEquipmentCatalog.byId(equipmentId);
    if (item == null || !isEquipmentOwned(equipmentId)) return false;
    final proposedSetup = {
      ..._state.equippedEquipmentByOperation,
      item.slotKey: item.id,
    };
    if (_equipmentSetupCompatibilityIssue(proposedSetup) != null) return false;
    _state = _state.copyWith(equippedEquipmentByOperation: proposedSetup);
    return true;
  }

  void setFarmTutorialStep(FarmTutorialStep step) {
    if (_state.farmTutorialStep == step) return;
    _state = _state.copyWith(farmTutorialStep: step);
  }

  bool get isFarmTutorialActive => !isFarmTutorialComplete;

  // ---------------------------------------------------------------------------
  // Tunable Constants
  // ---------------------------------------------------------------------------

  /// Continuous mowing duration default (22.5s).
  ///
  /// Rationale: The design documentation (docs/game-design-brief.md line 28 and
  /// docs/economy-and-progression-proposal.md line 19) specifies:
  /// "1 balya = 30 ÇK; sürekli biçmede yaklaşık 20–25 saniyede bir balya".
  /// 22.5 seconds is selected as the exact arithmetic midpoint of this 20–25
  /// second target range, providing a deterministic default for simulation.
  static const double defaultBaleMowingDurationSeconds = 22.5;

  /// Maximum integer safely and exactly representable across Dart double
  /// (53-bit IEEE-754 mantissa) and cross-platform Dart int arithmetic.
  static const double maxExactInteger = 9007199254740991.0;
  static const double maxSafeInteger = maxExactInteger;

  /// Sale reward for selling a single grass bale (30 ÇK).
  static const int baleSaleRewardCredits = 30;
  static const int baleSalePrice = baleSaleRewardCredits;

  /// Evidence added to the non-spending P1 milestone counter per bale sale (30).
  static const int baleLifetimeProductionEvidence = 30;

  /// Purchase price for the H01 mini mower upgrade (90 ÇK).
  static const int mowerCost = 90;
  static const int h01MowerCost = mowerCost;

  /// Hiring price for the H02 worker (180 ÇK).
  static const int workerCost = 180;
  static const int h02WorkerCost = workerCost;

  /// Starter products, timing and opening-economy values selected from the
  /// approved crop and economy proposals.
  static const String starterWheatId = 'CR01';
  static const String starterMaizeId = 'CR02';
  static const int adjacentStarterPlotId = 1;
  static const Duration starterCropGrowthDuration = Duration(minutes: 6);
  static const double starterCropHarvestValue = 1000;
  static const int starterCropSeedCost = 120;
  static const int starterTradeCredits = 750;
  static const double offSeasonYieldMultiplier = 0.75;
  static const String soilCareTechnologyId = 'T02';
  static const int initialSoilConditionPoints = 80;
  static const int soilConditionMaximumPoints = 100;
  static const int soilCareTriggerPoints = 75;
  static const int soilCareRestoredPoints = 3;
  static const int soilCareCostCredits = 20;
  static const double lowestSoilYieldMultiplier = 0.90;

  // ---------------------------------------------------------------------------
  // Read-only State Accessors
  // ---------------------------------------------------------------------------

  int get farmCredits => _state.farmCredits;
  int get credits => _state.farmCredits;
  int get balance => _state.farmCredits;

  int get debt => _state.debt;

  int get soilConditionPoints => _state.soilConditionPoints;
  bool get automaticSoilCareEnabled => _state.automaticSoilCareEnabled;
  double get soilYieldMultiplier =>
      lowestSoilYieldMultiplier + _state.soilConditionPoints / 1000.0;

  int get lifetimeProductionEvidence => _state.lifetimeProductionEvidence;
  int get lifetimeProductionEvidenceCounter =>
      _state.lifetimeProductionEvidence;
  int get lifetimeProductionP1 => _state.lifetimeProductionEvidence;

  /// Number of different crop families with at least one full harvest.
  /// Grass does not count toward crop diversity.
  int get cropDiversityEvidenceCount => _state.fullHarvestedCropIds
      .map(OpeningCropCatalog.familyFor)
      .whereType<CropFamily>()
      .toSet()
      .length;
  int get cropDiversityCount => cropDiversityEvidenceCount;

  /// V1 is one full grain harvest plus one full sunflower or potato harvest.
  bool get hasCompletedV1Diversity {
    final families = _state.fullHarvestedCropIds
        .map(OpeningCropCatalog.familyFor)
        .whereType<CropFamily>()
        .toSet();
    return families.contains(CropFamily.grain) &&
        (families.contains(CropFamily.oilseed) ||
            families.contains(CropFamily.rootTuber));
  }

  bool hasPurchasedTechnology(String technologyId) =>
      _state.purchasedTechnologyIds.contains(technologyId);

  bool get canPurchaseP2Technology =>
      _state.stage == OpeningStage.management &&
      _state.lifetimeProductionEvidence >=
          OpeningCropCatalog.p2EvidenceThresholdCredits;

  bool canPurchaseTechnology(String technologyId) {
    if (!canPurchaseP2Technology ||
        hasPurchasedTechnology(technologyId) ||
        _state.farmCredits < OpeningCropCatalog.c2TechnologyCostCredits) {
      return false;
    }

    switch (technologyId) {
      case OpeningCropCatalog.oilseedFamilyTechnologyId:
      case OpeningCropCatalog.rootTuberFamilyTechnologyId:
        return true;
      case OpeningCropCatalog.legumeFamilyTechnologyId:
        return hasCompletedV1Diversity;
      case OpeningCropCatalog.chickpeaTechnologyId:
        return hasPurchasedTechnology(
          OpeningCropCatalog.legumeFamilyTechnologyId,
        );
      case soilCareTechnologyId:
        return _state.hasOwnedInitialPlot;
      case OpeningCropCatalog.sunflowerTechnologyId:
        return hasPurchasedTechnology(
          OpeningCropCatalog.oilseedFamilyTechnologyId,
        );
      case OpeningCropCatalog.potatoTechnologyId:
        return hasPurchasedTechnology(
          OpeningCropCatalog.rootTuberFamilyTechnologyId,
        );
      default:
        return false;
    }
  }

  OpeningStage get stage => _state.stage;
  bool get isScytheStage => _state.stage == OpeningStage.scythe;
  bool get isMowerStage => _state.stage == OpeningStage.mower;
  bool get isManagementStage => _state.stage == OpeningStage.management;

  bool get hasMower => _state.hasMower;
  bool get hasWorker => _state.hasWorker;
  bool get isMowerAssignedToWorker => _state.isMowerAssignedToWorker;
  bool get mowerAssignedToWorker => _state.isMowerAssignedToWorker;

  bool get hasOwnedInitialPlot => _state.hasOwnedInitialPlot;
  bool get hasOwnedStartingPlot => _state.hasOwnedInitialPlot;

  /// Fresh farms begin on the nearby North Field. An in-progress legacy save
  /// keeps its original farmhouse field as the active crop until that cycle ends.
  int get starterPlotId {
    for (final plot in _state.plots) {
      if (plot.id == adjacentStarterPlotId && plot.isOwned) {
        return adjacentStarterPlotId;
      }
    }
    final savedHomePlot = _state.plots.where((plot) => plot.id == 0);
    final hasLegacyHomeCycle =
        _state.activeCropId != null ||
        _state.activeCropPlantedAt != null ||
        _state.hasHarvestedActiveCrop ||
        (savedHomePlot.isNotEmpty &&
            (savedHomePlot.first.activeCropId != null ||
                savedHomePlot.first.activeJob != null ||
                savedHomePlot.first.hasHarvestedActiveCrop));
    return _state.hasOwnedInitialPlot && hasLegacyHomeCycle
        ? 0
        : adjacentStarterPlotId;
  }

  int get freeInitialSeedsCount => _state.freeInitialSeedsCount;
  int get freeInitialSeedCount => _state.freeInitialSeedsCount;
  bool get hasFreeInitialSeed => _state.hasFreeInitialSeed;

  bool get isCarryingBale =>
      _state.isCarryingBale || _state.carriedBalesCount > 0;
  bool get hasCarriedBale => isCarryingBale;
  int get carriedBaleCount => _state.carriedBalesCount > 0
      ? _state.carriedBalesCount
      : (_state.isCarryingBale ? 1 : 0);
  int get carriedBales => carriedBaleCount;
  int get carriedBalesCount => carriedBaleCount;
  int get backpackCapacity => _state.backpackCapacity;
  bool get isBackpackFull => carriedBaleCount >= _state.backpackCapacity;
  int get speedLevel => _state.speedLevel;
  int get rangeLevel => _state.rangeLevel;
  int get capacityLevel => _state.capacityLevel;

  double get movementSpeedMultiplier =>
      1.0 + (_state.speedLevel * 0.20) + (_state.hasMower ? 0.35 : 0.0);

  double get cuttingRangeMultiplier =>
      1.0 + (_state.rangeLevel * 0.25) + (_state.hasMower ? 0.40 : 0.0);

  int get upgradeCapacityCost => 40 + _state.capacityLevel * 30;
  int get upgradeSpeedCost => 50 + _state.speedLevel * 35;
  int get upgradeRangeCost => 60 + _state.rangeLevel * 40;

  bool get canBuyUpgradeCapacity =>
      _state.stage != OpeningStage.management &&
      _state.farmCredits >= upgradeCapacityCost;

  bool get canBuyUpgradeSpeed =>
      _state.stage != OpeningStage.management &&
      _state.farmCredits >= upgradeSpeedCost;

  bool get canBuyUpgradeRange =>
      _state.stage != OpeningStage.management &&
      _state.farmCredits >= upgradeRangeCost;

  int get groundBaleCount => _state.groundBaleCount;
  int get groundBales => _state.groundBaleCount;
  bool get hasGroundBale => _state.hasGroundBale;

  double get mowingProgressSeconds => _state.mowingProgressSeconds;
  double get baleMowingDurationSeconds => _state.baleMowingDurationSeconds;

  DateTime? get firstSuccessfulPlantingAt => _state.firstSuccessfulPlantingAt;
  DateTime? get firstSuccessfulPlantingTime => _state.firstSuccessfulPlantingAt;
  bool get hasFirstSuccessfulPlanting =>
      _state.firstSuccessfulPlantingAt != null;

  bool get hasActiveCrop =>
      _state.activeCropId != null &&
      _state.activeCropPlantedAt != null &&
      !_state.hasHarvestedActiveCrop;

  bool get hasCompletedStarterTrade => _state.hasCompletedStarterTrade;
  bool get hasStarterTruck => _state.hasStarterTruck;

  bool canPlantCrop(String cropId) {
    final crop = OpeningCropCatalog.byId(cropId);
    if (_state.stage != OpeningStage.management ||
        !_state.hasOwnedInitialPlot ||
        hasActiveCrop ||
        crop == null ||
        (!hasCompletedStarterTrade && crop.family != CropFamily.grain) ||
        (cropId == OpeningCropCatalog.sunflowerId &&
            !hasPurchasedTechnology(
              OpeningCropCatalog.sunflowerTechnologyId,
            )) ||
        (cropId == OpeningCropCatalog.potatoId &&
            !hasPurchasedTechnology(OpeningCropCatalog.potatoTechnologyId)) ||
        (cropId == OpeningCropCatalog.chickpeaId &&
            !hasPurchasedTechnology(OpeningCropCatalog.chickpeaTechnologyId))) {
      return false;
    }
    return _state.freeInitialSeedsCount > 0 ||
        _state.farmCredits >= crop.seedCostCredits;
  }

  CropCycleSnapshot? cropSnapshotAt(DateTime now) {
    if (!hasActiveCrop) return null;

    final anchor = _state.firstSuccessfulPlantingAt;
    final plantedAt = _state.activeCropPlantedAt;
    final cropId = _state.activeCropId;
    if (anchor == null || plantedAt == null || cropId == null) return null;

    final crop = OpeningCropCatalog.byId(cropId);
    if (crop == null) return null;
    final starterPlot = plotById(starterPlotId);
    final growthOverride = starterPlot?.cropGrowthDurationOverrideSeconds;
    final baseDefinition = crop.toCycleDefinition();
    final definition = growthOverride == null
        ? baseDefinition
        : CropDefinition(
            id: crop.id,
            fullGrowthDuration: Duration(seconds: growthOverride),
            fullHarvestYield: baseDefinition.fullHarvestYield,
          );
    final anchorUtc = anchor.toUtc();
    final rawPlantedElapsed = plantedAt.toUtc().difference(anchorUtc);
    final plantedElapsed = rawPlantedElapsed.isNegative
        ? Duration.zero
        : rawPlantedElapsed;
    final elapsedFromAnchor = now.toUtc().difference(anchorUtc);
    final elapsed = elapsedFromAnchor < plantedElapsed
        ? plantedElapsed
        : elapsedFromAnchor;
    final plantingCalendar = FarmCalendar.resolve(plantedElapsed);
    final seasonEndElapsed =
        plantedElapsed -
        plantingCalendar.timeInSeason +
        FarmCalendar.seasonDuration;
    final cycle = CropCycle(
      crop: definition,
      plantedElapsed: plantedElapsed,
      harvestWindowCloseElapsed: seasonEndElapsed,
    );
    final snapshot = cycle.evaluate(elapsed);
    final seasonalYieldMultiplier =
        plantingCalendar.season == crop.plantingSeason
        ? 1.0
        : offSeasonYieldMultiplier;
    final yieldPlot =
        starterPlot ?? plots.firstWhere((plot) => plot.id == starterPlotId);

    return CropCycleSnapshot(
      cycle: snapshot.cycle,
      evaluationElapsed: snapshot.evaluationElapsed,
      status: snapshot.status,
      growthProgress: snapshot.growthProgress,
      harvestYield:
          snapshot.harvestYield *
          (yieldPlot.areaSquareMeters / 1000.0) *
          soilYieldMultiplier *
          yieldPlot.suitabilityForCrop(cropId) *
          seasonalYieldMultiplier,
    );
  }

  bool canHarvestCropAt(DateTime now) =>
      cropSnapshotAt(now)?.isHarvestable ?? false;

  // ---------------------------------------------------------------------------
  // Domain Rule Queries
  // ---------------------------------------------------------------------------

  /// Player can only mow if not carrying a bale and management stage has not begun.
  bool get canMow =>
      !_state.isCarryingBale && _state.stage != OpeningStage.management;

  /// Ground bale can be picked up if available, player is not already carrying one,
  /// and management stage has not begun.
  bool get canPickUpBale =>
      _state.groundBaleCount > 0 &&
      !_state.isCarryingBale &&
      _state.stage != OpeningStage.management;

  /// Player can sell a bale only while carrying one and before management stage.
  bool get canSellBale =>
      _state.isCarryingBale && _state.stage != OpeningStage.management;

  /// H01 mower can be bought once if funds are sufficient and not in management stage.
  bool get canBuyMower =>
      !_state.hasMower &&
      _state.stage != OpeningStage.management &&
      _state.farmCredits >= mowerCost;

  /// H02 worker can be hired once if mower is owned, funds are sufficient,
  /// and no opening bales are carried or remain on the ground.
  ///
  /// Conservative handoff rule: derived from the brief's statement that the
  /// manual bale loop ends at takeover. Protects opening-only inventory so
  /// goods are not lost or sold after management starts.
  bool get canHireWorker =>
      _state.hasMower &&
      !_state.hasWorker &&
      _state.stage != OpeningStage.management &&
      _state.farmCredits >= workerCost &&
      !_state.isCarryingBale &&
      _state.groundBaleCount == 0;

  /// First planting anchor can be recorded only in management stage, with owned
  /// initial plot, available free initial seed, and if not already recorded.
  bool get canRecordFirstSuccessfulPlanting =>
      _state.stage == OpeningStage.management &&
      _state.hasOwnedInitialPlot &&
      _state.freeInitialSeedsCount > 0 &&
      _state.firstSuccessfulPlantingAt == null;

  // ---------------------------------------------------------------------------
  // Actions & State Mutations
  // ---------------------------------------------------------------------------

  /// Simulates continuous mowing for [deltaSeconds].
  ///
  /// Produces one ground bale for every completed [baleMowingDurationSeconds]
  /// of accumulated mowing time using constant-time quotient and remainder arithmetic.
  ///
  /// Returns `true` if mowing occurred.
  /// Returns `false` without mutating state if mowing is forbidden (carrying bale,
  /// management stage, non-finite or non-positive [deltaSeconds], or if the resulting
  /// bale count or updated [groundBaleCount] cannot be represented safely and
  /// exactly by Dart int/double arithmetic).
  bool mow(double deltaSeconds) {
    if (!canMow || !deltaSeconds.isFinite || deltaSeconds <= 0) {
      return false;
    }

    final totalSeconds = _state.mowingProgressSeconds + deltaSeconds;
    if (!totalSeconds.isFinite) {
      return false;
    }

    final duration = _state.baleMowingDurationSeconds;
    final rawBales = totalSeconds / duration;

    if (!rawBales.isFinite || rawBales.isNaN || rawBales < 0) {
      return false;
    }

    if (rawBales > maxExactInteger) {
      return false;
    }

    var producedBales = rawBales.floor();
    var remainder = totalSeconds - (producedBales * duration);

    if (remainder >= duration) {
      producedBales += 1;
      remainder -= duration;
    }
    if (remainder < 0) {
      remainder = 0.0;
    }

    if (_state.groundBaleCount + producedBales > maxExactInteger) {
      return false;
    }

    _state = _state.copyWith(
      mowingProgressSeconds: remainder,
      groundBaleCount: _state.groundBaleCount + producedBales,
    );
    return true;
  }

  /// Alias for [mow] to support frame-tick terminology.
  bool advanceMowing(double deltaSeconds) => mow(deltaSeconds);

  /// Explicitly picks up one ground bale.
  ///
  /// Player can carry at most one bale at a time and only during opening hook.
  /// Returns `true` if a bale was picked up.
  /// Returns `false` without state mutation if no ground bale exists, player
  /// is already carrying one, or management stage has begun.
  bool pickUpBale() {
    if (!canPickUpBale) {
      return false;
    }

    _state = _state.copyWith(
      groundBaleCount: _state.groundBaleCount - 1,
      isCarryingBale: true,
    );
    return true;
  }

  /// Enters the sale zone. If carrying a bale and before management stage,
  /// automatically sells it, clears the carried bale, and pays [baleSalePrice]
  /// (30 ÇK). Also increments [lifetimeProductionEvidence] by 30 for milestone P1.
  ///
  /// Returns `true` if a bale was sold.
  /// Returns `false` without state mutation if not carrying a bale or in
  /// management stage.
  bool enterSaleZone() {
    if (!canSellBale) {
      return false;
    }

    _state = _state.copyWith(
      isCarryingBale: false,
      carriedBalesCount: max(0, _state.carriedBalesCount - 1),
      farmCredits: _state.farmCredits + baleSaleRewardCredits,
      lifetimeProductionEvidence:
          _state.lifetimeProductionEvidence + baleLifetimeProductionEvidence,
    );
    return true;
  }

  /// Explicit alias for [enterSaleZone].
  bool sellCarriedBale() => enterSaleZone();

  /// Sells a single bale from the player's stacked backpack.
  bool sellOneBale() => enterSaleZone();

  /// Sells all stacked bales in the player's backpack at once.
  int sellAllCarriedBales() {
    final count = carriedBalesCount;
    if (count <= 0 || _state.stage == OpeningStage.management) {
      return 0;
    }
    final reward = count * baleSaleRewardCredits;
    _state = _state.copyWith(
      isCarryingBale: false,
      carriedBalesCount: 0,
      farmCredits: _state.farmCredits + reward,
      lifetimeProductionEvidence:
          _state.lifetimeProductionEvidence +
          (count * baleLifetimeProductionEvidence),
    );
    return count;
  }

  /// Adds farm credits directly (e.g. from quests, deliveries or external sales).
  void addCredits(int amount) {
    if (amount <= 0) return;
    _state = _state.copyWith(farmCredits: _state.farmCredits + amount);
  }

  /// Directly collects a newly cut bale into the player's backpack stack.
  bool collectBaleDirectlyToBackpack() {
    if (isBackpackFull || _state.stage == OpeningStage.management) {
      return false;
    }
    final newCount = _state.carriedBalesCount + 1;
    _state = _state.copyWith(carriedBalesCount: newCount, isCarryingBale: true);
    return true;
  }

  /// Upgrades backpack capacity by +10.
  bool buyUpgradeCapacity() {
    if (!canBuyUpgradeCapacity) return false;
    final cost = upgradeCapacityCost;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - cost,
      capacityLevel: _state.capacityLevel + 1,
      backpackCapacity: _state.backpackCapacity + 10,
    );
    return true;
  }

  /// Upgrades movement speed tier.
  bool buyUpgradeSpeed() {
    if (!canBuyUpgradeSpeed) return false;
    final cost = upgradeSpeedCost;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - cost,
      speedLevel: _state.speedLevel + 1,
    );
    return true;
  }

  /// Upgrades cutting blade radius / width tier.
  bool buyUpgradeRange() {
    if (!canBuyUpgradeRange) return false;
    final cost = upgradeRangeCost;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - cost,
      rangeLevel: _state.rangeLevel + 1,
    );
    return true;
  }

  /// Purchases the H01 mini mower for [mowerCost] (90 ÇK).
  ///
  /// Sets stage to [OpeningStage.mower] and [hasMower] to true.
  /// Returns `true` on successful purchase.
  /// Returns `false` without state mutation if funds are insufficient or mower
  /// is already owned.
  bool buyMower() {
    if (!canBuyMower) {
      return false;
    }

    _state = _state.copyWith(
      farmCredits: _state.farmCredits - mowerCost,
      hasMower: true,
      stage: OpeningStage.mower,
    );
    return true;
  }

  /// Alias for [buyMower].
  bool purchaseMower() => buyMower();

  /// Purchases one P2 opening technology node for the documented C2 cost.
  ///
  /// T05/T06 start oilseed and root/tuber branches; T13/T14 unlock their first
  /// crops. T15 starts legumes after V1, and T16 unlocks chickpeas. Each node
  /// can be bought once and none changes production evidence.
  bool purchaseTechnology(String technologyId) {
    if (!canPurchaseTechnology(technologyId)) return false;

    _state = _state.copyWith(
      farmCredits:
          _state.farmCredits - OpeningCropCatalog.c2TechnologyCostCredits,
      purchasedTechnologyIds: {..._state.purchasedTechnologyIds, technologyId},
      automaticSoilCareEnabled: technologyId == soilCareTechnologyId
          ? true
          : _state.automaticSoilCareEnabled,
    );
    AudioController.instance.playEffect(SoundEffect.techUnlock);
    return true;
  }

  /// Registers an unlocked technology node from the comprehensive tech tree.
  void unlockTechnology(String technologyId) {
    _state = _state.copyWith(
      purchasedTechnologyIds: {..._state.purchasedTechnologyIds, technologyId},
      automaticSoilCareEnabled: technologyId == soilCareTechnologyId
          ? true
          : _state.automaticSoilCareEnabled,
    );
  }

  /// Adds the research-only budget once so a tree-only session can explore every branch.
  void grantStandaloneResearchBudgetOnce(int amount) {
    if (_state.hasStandaloneResearchBudget) return;
    _state = _state.copyWith(
      farmCredits: _state.farmCredits + max(0, amount),
      hasStandaloneResearchBudget: true,
    );
  }

  /// Changes T02's automatic soil-care setting. Enabling it immediately tries
  /// to correct an already-low field when enough credits are available.
  bool setAutomaticSoilCareEnabled(bool enabled) {
    if (!hasPurchasedTechnology(soilCareTechnologyId) ||
        _state.automaticSoilCareEnabled == enabled) {
      return false;
    }

    _state = _state.copyWith(automaticSoilCareEnabled: enabled);
    if (enabled) _tryAutomaticSoilCare();
    return true;
  }

  void _tryAutomaticSoilCare({DateTime? now}) {
    if (!hasPurchasedTechnology(soilCareTechnologyId) ||
        !_state.automaticSoilCareEnabled ||
        !canUseEquippedEquipmentFor(FarmOperation.fertilize)) {
      return;
    }

    var credits = _state.farmCredits;
    final currentPlots = List<CropPlotState>.from(plots);
    var plotsChanged = false;
    final nowUtc = (now ?? DateTime.now()).toUtc();
    for (var index = 0; index < currentPlots.length; index++) {
      final plot = currentPlots[index];
      if (!plot.isOwned ||
          plot.use != CropPlotUse.arable ||
          plot.hasActiveCrop ||
          plot.hasActiveJob ||
          plot.soilConditionPoints >= soilCareTriggerPoints) {
        continue;
      }
      if (!canUseEquippedEquipmentFor(FarmOperation.fertilize)) break;
      final cost = scaledFieldCost(
        plot,
        fieldFertilizerCostPerThousandSquareMeters,
      );
      if (credits < cost) continue;
      credits -= cost;
      final soilAfter = min(
        soilConditionMaximumPoints,
        plot.soilConditionPoints + soilCareRestoredPoints,
      );
      final job = _newJob(
        plot: plot,
        operation: FarmOperation.fertilize,
        now: nowUtc,
        soilAfter: soilAfter,
      );
      currentPlots[index] = plot.copyWith(activeJob: job);
      _activeFarmJobsByPlotId[plot.id] = job;
      plotsChanged = true;
    }
    if (plotsChanged) {
      _state = _state.copyWith(farmCredits: credits, plots: currentPlots);
    }
  }

  /// Hires the H02 first worker for [workerCost] (180 ÇK).
  ///
  /// Requires H01 mower ownership and that all carried and ground opening
  /// bales have been cleared (conservative handoff rule).
  /// Upon hiring, manual control ends and transfers to [OpeningStage.management],
  /// assigns mower to worker, and grants the owned initial plot plus one free initial seed.
  ///
  /// Returns `true` on successful hire.
  /// Returns `false` without state mutation if mower is missing, funds are
  /// insufficient, worker is already hired, or opening bales remain.
  bool hireWorker() {
    if (!canHireWorker) {
      return false;
    }

    _state = _state.copyWith(
      farmCredits: _state.farmCredits - workerCost,
      hasWorker: true,
      stage: OpeningStage.management,
      isMowerAssignedToWorker: true,
      hasOwnedInitialPlot: true,
      freeInitialSeedsCount: 1,
    );
    grantStarterEquipmentOnce();
    return true;
  }

  /// Alias for [hireWorker].
  bool hireH02Worker() => hireWorker();

  /// Skips the manual scythe / mini-mower opening mini-game and immediately
  /// transitions the farm into full automated management mode.
  ///
  /// Awards the H01 mini mower and H02 worker automations, clears any carried
  /// or ground bales, unlocks the initial plot with a free starter seed,
  /// and ensures sufficient starting farm credits for management operations.
  void skipToManagement({int minimumCredits = 250}) {
    if (_state.stage == OpeningStage.management) return;

    final updatedCredits = max(_state.farmCredits, minimumCredits);
    final updatedSeeds = max(_state.freeInitialSeedsCount, 1);

    _state = _state.copyWith(
      stage: OpeningStage.management,
      hasMower: true,
      hasWorker: true,
      isMowerAssignedToWorker: true,
      hasOwnedInitialPlot: true,
      hasStarterTruck: true,
      freeInitialSeedsCount: updatedSeeds,
      farmCredits: updatedCredits,
      isCarryingBale: false,
      carriedBalesCount: 0,
      groundBaleCount: 0,
    );
    grantStarterEquipmentOnce();
  }

  /// Records the write-once first successful crop planting calendar anchor.
  ///
  /// Per docs/game-design-brief.md:87, the player's personal 18-hour seasonal
  /// cycle begins after the first successful planting and continues offline.
  ///
  /// Preconditions:
  /// - Must be in [OpeningStage.management] stage (post-takeover).
  /// - Player must own the initial plot ([hasOwnedInitialPlot]).
  /// - Free initial seed must be available ([freeInitialSeedsCount] > 0).
  /// - Anchor must not have been previously recorded ([firstSuccessfulPlantingAt] == null).
  ///
  /// On success:
  /// - Consumes 1 free initial seed.
  /// - Stores [plantedAt] normalized to UTC.
  /// - Returns `true`.
  ///
  /// Repeated calls or calls failing preconditions return `false` without
  /// mutating the anchor or consuming seeds.
  bool recordFirstSuccessfulPlanting(DateTime plantedAt) {
    if (!canRecordFirstSuccessfulPlanting) {
      return false;
    }

    _state = _state.copyWith(
      freeInitialSeedsCount: _state.freeInitialSeedsCount - 1,
      firstSuccessfulPlantingAt: plantedAt.toUtc(),
    );
    return true;
  }

  /// Plants an opening crop. A new save's free seed is consumed first; later
  /// cycles buy one seed at the documented 12% starter-crop value.
  bool plantCrop(String cropId, DateTime plantedAt) {
    if (!canPlantCrop(cropId)) return false;

    final usesFreeSeed = _state.freeInitialSeedsCount > 0;
    final currentAnchor = _state.firstSuccessfulPlantingAt;
    final requestedPlantingAt = plantedAt.toUtc();
    final effectivePlantingAt =
        currentAnchor != null &&
            requestedPlantingAt.isBefore(currentAnchor.toUtc())
        ? currentAnchor.toUtc()
        : requestedPlantingAt;
    if (_state.firstSuccessfulPlantingAt == null) {
      if (!recordFirstSuccessfulPlanting(effectivePlantingAt)) return false;
    } else {
      _state = _state.copyWith(
        farmCredits:
            _state.farmCredits -
            (usesFreeSeed
                ? 0
                : OpeningCropCatalog.byId(cropId)!.seedCostCredits),
        freeInitialSeedsCount: usesFreeSeed
            ? _state.freeInitialSeedsCount - 1
            : _state.freeInitialSeedsCount,
      );
    }

    _state = _state.copyWith(
      activeCropId: cropId,
      activeCropPlantedAt: effectivePlantingAt,
      hasHarvestedActiveCrop: false,
    );
    return true;
  }

  /// Collects a ready crop and puts it in the warehouse. Sales happen only
  /// after the player creates a delivery route and the truck reaches market.
  bool harvestCrop(DateTime now) {
    final snapshot = cropSnapshotAt(now);
    if (snapshot == null || !snapshot.isHarvestable) return false;

    final harvestValue = snapshot.harvestYield.round();
    if (harvestValue <= 0) return false;
    final unlocksStarterTruck = !_state.hasStarterTruck;
    final cropId = snapshot.crop.id;
    final crop = OpeningCropCatalog.byId(cropId);
    final firstPlanting = _state.firstSuccessfulPlantingAt;
    final cropPlantedAt = _state.activeCropPlantedAt;
    var isInPlantingSeason = false;
    if (crop != null && firstPlanting != null && cropPlantedAt != null) {
      final rawPlantedElapsed = cropPlantedAt.toUtc().difference(
        firstPlanting.toUtc(),
      );
      final plantedElapsed = rawPlantedElapsed.isNegative
          ? Duration.zero
          : rawPlantedElapsed;
      isInPlantingSeason =
          FarmCalendar.resolve(plantedElapsed).season == crop.plantingSeason;
    }
    final isFullCropHarvest =
        snapshot.status == CropCycleStatus.readyForHarvest &&
        snapshot.growthProgress >= 1;
    final isFullInSeasonHarvest = isFullCropHarvest && isInPlantingSeason;
    final fullHarvestedCropIds = isFullInSeasonHarvest
        ? {..._state.fullHarvestedCropIds, cropId}
        : _state.fullHarvestedCropIds;
    final outputQuantity = max(
      1,
      (harvestValue / max(1, (crop?.fullHarvestValueCredits ?? 300) ~/ 10))
          .round(),
    );
    final newSoil = isFullCropHarvest && _state.soilConditionPoints > 0
        ? _state.soilConditionPoints - 1
        : _state.soilConditionPoints;
    final updatedPlots = plots.map((p) {
      if (p.id == starterPlotId) {
        return p.copyWith(
          soilConditionPoints: newSoil,
          hasHarvestedActiveCrop: true,
        );
      }
      return p;
    }).toList(growable: false);
    _state = _state.copyWith(
      lifetimeProductionEvidence:
          _state.lifetimeProductionEvidence + harvestValue,
      hasHarvestedActiveCrop: true,
      hasStarterTruck: true,
      fullHarvestedCropIds: fullHarvestedCropIds,
      farmTutorialStep: _state.farmTutorialStep == FarmTutorialStep.harvest
          ? FarmTutorialStep.warehouse
          : _state.farmTutorialStep,
      soilConditionPoints: newSoil,
      plots: updatedPlots,
    );
    if (unlocksStarterTruck) fleetManager.initializeStarterFleet();
    fleetManager.depositToWarehouse(cropId, outputQuantity);
    _tryAutomaticSoilCare(now: now);
    AudioController.instance.playEffect(SoundEffect.harvest);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Multi-Plot Expansion Management
  // ---------------------------------------------------------------------------

  bool ownsWorldParcel(String parcelId) => parcelId == 'home'
      ? _state.hasOwnedInitialPlot
      : _state.ownedWorldParcelIds.contains(parcelId);

  List<FarmBuildingInstance> get buildings => _state.buildings;

  ProcessingFacility? facilityForBuilding(FarmBuildingInstance building) {
    final id = 'built_${building.parcelId}';
    for (final facility in plantManager.facilities) {
      if (facility.id == id) return facility;
    }
    return null;
  }

  /// Resolves processing permissions from a physical building and its research
  /// dependencies. Persisted unlock flags are not treated as authorization.
  List<String> availableProcessingRecipeIds(
    ProcessingFacility facility, {
    DateTime? at,
  }) {
    if (!facility.id.startsWith('built_')) return const <String>[];
    final now = (at ?? DateTime.now()).toUtc();
    final parcelId = facility.id.substring('built_'.length);
    final building = buildingOnParcel(parcelId);
    if (building == null || !building.isOperationalAt(now)) {
      return const <String>[];
    }
    final definition = FarmBuildingCatalog.byId(building.definitionId);
    if (definition == null ||
        definition.recipeIds.isEmpty ||
        !definition.requiredTechnologyIds.every(hasResearch)) {
      return const <String>[];
    }
    return definition.recipeIds
        .where((recipeId) {
          final recipe = ProcessingRecipeCatalog.byId(recipeId);
          return recipe != null && hasResearch(recipe.inputCropId);
        })
        .toList(growable: false);
  }

  int get dailyBuildingOperatingCost => _state.buildings
      .where((building) => building.isOperationalAt(DateTime.now()))
      .map((building) => FarmBuildingCatalog.byId(building.definitionId))
      .whereType<FarmBuildingDefinition>()
      .fold(
        0,
        (total, definition) => total + definition.dailyOperatingCostCredits,
      );

  Season seasonAt(DateTime now) {
    final anchor = _state.firstSuccessfulPlantingAt;
    if (anchor == null) return Season.spring;
    final elapsed = now.toUtc().difference(anchor.toUtc());
    return FarmCalendar.fromElapsed(
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
    ).season;
  }

  ItemPriceQuote marketQuote(String itemId, {DateTime? at}) =>
      marketPrices.getQuote(itemId, seasonAt(at ?? DateTime.now()));

  int warehouseAmountFor(String itemId) => fleetManager.warehouseStock
      .where((batch) => batch.cropId == itemId)
      .fold(0, (total, batch) => total + batch.amount);

  void _syncOperationalBuildings(DateTime now) {
    final operational = _state.buildings
        .where((building) => building.isOperationalAt(now))
        .toList(growable: false);
    fleetManager.warehouseCapacity =
        200 +
        operational
            .map((building) => FarmBuildingCatalog.byId(building.definitionId))
            .whereType<FarmBuildingDefinition>()
            .fold(
              0,
              (total, definition) => total + definition.warehouseCapacityBonus,
            );
    fleetManager.routeSpeedMultiplier =
        1 +
        operational
            .map((building) => FarmBuildingCatalog.byId(building.definitionId))
            .whereType<FarmBuildingDefinition>()
            .fold(
              0.0,
              (total, definition) => total + definition.logisticsSpeedBonus,
            );
    fleetManager.warehouseFreshnessMultiplier = operational
        .map((building) => FarmBuildingCatalog.byId(building.definitionId))
        .whereType<FarmBuildingDefinition>()
        .fold(
          1.0,
          (factor, definition) =>
              min(factor, definition.warehouseFreshnessMultiplier),
        );

    for (final facility in plantManager.facilities) {
      if (!facility.id.startsWith('built_')) {
        // Older saves contain virtual free mills (`fac_*`). They are not
        // physical buildings and must not stay active after loading.
        facility.isUnlocked = false;
        continue;
      }
      final parcelId = facility.id.substring('built_'.length);
      final building = buildingOnParcel(parcelId);
      final definition = building == null
          ? null
          : FarmBuildingCatalog.byId(building.definitionId);
      if (definition != null) {
        facility.allowedRecipeIds
          ..clear()
          ..addAll(definition.recipeIds);
      }
      facility.isUnlocked = availableProcessingRecipeIds(
        facility,
        at: now,
      ).isNotEmpty;
    }
    for (final building in operational) {
      final definition = FarmBuildingCatalog.byId(building.definitionId);
      if (definition == null ||
          definition.recipeIds.isEmpty ||
          !definition.requiredTechnologyIds.every(hasResearch)) {
        continue;
      }
      if (facilityForBuilding(building) != null) continue;
      final plot = plotForWorldParcel(building.parcelId);
      final facility = ProcessingFacility(
        id: 'built_${building.parcelId}',
        name: definition.name,
        positionX: plot?.mapX ?? 0,
        positionY: plot?.mapY ?? 0,
        allowedRecipeIds: definition.recipeIds,
      );
      plantManager.facilities.add(facility);
      facility.isUnlocked = availableProcessingRecipeIds(
        facility,
        at: now,
      ).isNotEmpty;
    }

    final poultryBuildings = operational
        .where((building) => building.definitionId == 'poultry_coop')
        .length;
    coop.isUnlocked = poultryBuildings > 0;
    if (poultryBuildings > 0) {
      if (coop.chickenCount <= 0) coop.chickenCount = 10;
      coop.maxCapacity = max(
        coop.maxCapacity,
        50 + (poultryBuildings - 1) * 25,
      );
    }
  }

  int _withdrawFromWarehouse(String itemId, int requestedAmount) {
    if (requestedAmount <= 0) return 0;
    var remaining = requestedAmount;
    for (
      var index = 0;
      index < fleetManager.warehouseStock.length && remaining > 0;
    ) {
      final batch = fleetManager.warehouseStock[index];
      if (batch.cropId != itemId) {
        index++;
        continue;
      }
      final taken = min(remaining, batch.amount);
      batch.amount -= taken;
      remaining -= taken;
      if (batch.amount <= 0) {
        fleetManager.warehouseStock.removeAt(index);
      } else {
        index++;
      }
    }
    return requestedAmount - remaining;
  }

  bool isBuildingOperational(String definitionId, {DateTime? at}) {
    final timestamp = at ?? DateTime.now();
    return _state.buildings.any(
      (building) =>
          building.definitionId == definitionId &&
          building.isOperationalAt(timestamp),
    );
  }

  FarmBuildingInstance? buildingOnParcel(String parcelId) {
    for (final building in _state.buildings) {
      if (building.parcelId == parcelId) return building;
    }
    return null;
  }

  bool canStartBuildingConstruction(
    String definitionId,
    WorldMapParcel parcel,
  ) {
    final definition = FarmBuildingCatalog.byId(definitionId);
    if (_state.stage != OpeningStage.management ||
        definition == null ||
        parcel.isHome ||
        !ownsWorldParcel(parcel.id) ||
        parcel.areaHectares < definition.minimumAreaHectares ||
        _state.farmCredits < definition.constructionCostCredits ||
        buildingOnParcel(parcel.id) != null ||
        !definition.requiredTechnologyIds.every(hasResearch)) {
      return false;
    }
    final plot = plotForWorldParcel(parcel.id);
    if (plot != null &&
        (plot.hasActiveCrop || plot.hasActiveJob || plot.readyGrassBales > 0)) {
      return false;
    }
    return true;
  }

  bool startBuildingConstruction(
    String definitionId,
    WorldMapParcel parcel, {
    DateTime? now,
  }) {
    final startedAt = (now ?? DateTime.now()).toUtc();
    if (!canStartBuildingConstruction(definitionId, parcel)) {
      return false;
    }
    final definition = FarmBuildingCatalog.byId(definitionId)!;
    final building = FarmBuildingInstance(
      definitionId: definition.id,
      parcelId: parcel.id,
      constructionStartedAt: startedAt,
      constructionCompletesAt: startedAt.add(definition.constructionDuration),
      lastOperatingChargeAt: startedAt.add(definition.constructionDuration),
    );
    final currentPlots = List<CropPlotState>.from(plots)
      ..removeWhere((plot) => plot.mapParcelId == parcel.id);
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - definition.constructionCostCredits,
      plots: currentPlots,
      buildings: [..._state.buildings, building],
    );
    return true;
  }

  /// Bills each completed facility once per 24 real hours, including offline
  /// time. A facility pauses cleanly when the balance cannot cover a full day.
  bool advanceBuildingOperatingCosts(DateTime now) {
    final nowUtc = now.toUtc();
    var credits = _state.farmCredits;
    var changed = false;
    final nextBuildings = <FarmBuildingInstance>[];
    for (final building in _state.buildings) {
      final definition = FarmBuildingCatalog.byId(building.definitionId);
      if (definition == null ||
          !building.isCompleteAt(nowUtc) ||
          building.pausedForOperatingCost ||
          definition.dailyOperatingCostCredits <= 0) {
        nextBuildings.add(building);
        continue;
      }
      final duePeriods =
          nowUtc.difference(building.lastOperatingChargeAt.toUtc()).inHours ~/
          24;
      if (duePeriods <= 0) {
        nextBuildings.add(building);
        continue;
      }
      final affordablePeriods =
          (credits ~/ definition.dailyOperatingCostCredits)
              .clamp(0, duePeriods)
              .toInt();
      credits -= affordablePeriods * definition.dailyOperatingCostCredits;
      final lastPaidAt = building.lastOperatingChargeAt.toUtc().add(
        Duration(days: affordablePeriods),
      );
      final cannotPayNextPeriod = affordablePeriods < duePeriods;
      nextBuildings.add(
        building.copyWith(
          lastOperatingChargeAt: lastPaidAt,
          pausedForOperatingCost: cannotPayNextPeriod,
        ),
      );
      changed = true;
    }
    if (!changed) return false;
    _state = _state.copyWith(farmCredits: credits, buildings: nextBuildings);
    _syncOperationalBuildings(nowUtc);
    return true;
  }

  bool resumeBuildingAfterOperatingCost(String parcelId, {DateTime? now}) {
    final index = _state.buildings.indexWhere(
      (building) => building.parcelId == parcelId,
    );
    if (index < 0) return false;
    final current = _state.buildings[index];
    final definition = FarmBuildingCatalog.byId(current.definitionId);
    if (definition == null ||
        !current.pausedForOperatingCost ||
        !current.isCompleteAt(now ?? DateTime.now()) ||
        _state.farmCredits < definition.dailyOperatingCostCredits) {
      return false;
    }
    final nextBuildings = List<FarmBuildingInstance>.from(_state.buildings);
    nextBuildings[index] = current.copyWith(
      lastOperatingChargeAt: (now ?? DateTime.now()).toUtc(),
      pausedForOperatingCost: false,
    );
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - definition.dailyOperatingCostCredits,
      buildings: nextBuildings,
    );
    _syncOperationalBuildings((now ?? DateTime.now()).toUtc());
    return true;
  }

  /// Purchases one deterministically generated remote parcel.
  bool buyWorldParcel(WorldMapParcel parcel) {
    if (_state.stage != OpeningStage.management ||
        parcel.isHome ||
        ownsWorldParcel(parcel.id) ||
        parcel.price <= 0 ||
        _state.farmCredits < parcel.price) {
      return false;
    }

    final currentPlots = List<CropPlotState>.from(plots);
    currentPlots.add(_plotForWorldParcel(parcel, currentPlots));
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - parcel.price,
      ownedWorldParcelIds: {..._state.ownedWorldParcelIds, parcel.id},
      plots: currentPlots,
    );
    AudioController.instance.playEffect(SoundEffect.purchaseParcel);
    return true;
  }

  CropPlotState? plotForWorldParcel(String parcelId) {
    for (final plot in plots) {
      if (plot.mapParcelId == parcelId) return plot;
    }
    return null;
  }

  /// Adds a legacy purchased parcel to the operational field list on first use.
  CropPlotState? ensureOperationalWorldPlot(WorldMapParcel parcel) {
    if (!ownsWorldParcel(parcel.id) || parcel.isHome) return null;
    final existing = plotForWorldParcel(parcel.id);
    if (existing != null) return existing;
    final currentPlots = List<CropPlotState>.from(plots);
    final plot = _plotForWorldParcel(parcel, currentPlots);
    currentPlots.add(plot);
    _state = _state.copyWith(plots: currentPlots);
    return plot;
  }

  CropPlotState _plotForWorldParcel(
    WorldMapParcel parcel,
    List<CropPlotState> currentPlots,
  ) {
    final preferredFamily = switch (parcel.cropType) {
      WorldCropType.grain => CropFamily.grain,
      WorldCropType.oilseed => CropFamily.oilseed,
      WorldCropType.vegetable => CropFamily.rootTuber,
      WorldCropType.pasture => CropFamily.grain,
    };
    final nextId =
        currentPlots.fold<int>(-1, (maxId, plot) => max(maxId, plot.id)) + 1;
    return CropPlotState(
      id: nextId,
      name: parcel.name,
      isOwned: true,
      purchaseCostCredits: parcel.price,
      soilConditionPoints: parcel.fertility,
      positionX: parcel.center.x,
      positionY: parcel.center.y,
      areaSquareMeters: max(1, (parcel.areaHectares * 10000).round()),
      mapX: parcel.center.x,
      mapY: parcel.center.y,
      mapWidth: parcel.width,
      mapHeight: parcel.height,
      mapParcelId: parcel.id,
      use: parcel.cropType == WorldCropType.pasture
          ? CropPlotUse.pasture
          : CropPlotUse.arable,
      preferredCropFamily: preferredFamily,
    );
  }

  bool hasWorldLogisticsLink(String firstParcelId, String secondParcelId) =>
      _state.worldLogisticsLinks.any(
        (link) =>
            (link.fromParcelId == firstParcelId &&
                link.toParcelId == secondParcelId) ||
            (link.fromParcelId == secondParcelId &&
                link.toParcelId == firstParcelId),
      );

  /// Builds and pays for a persistent logistics corridor between owned land.
  bool addWorldLogisticsLink(WorldLogisticsLink link) {
    if (_state.stage != OpeningStage.management ||
        link.fromParcelId == link.toParcelId ||
        !ownsWorldParcel(link.fromParcelId) ||
        !ownsWorldParcel(link.toParcelId) ||
        hasWorldLogisticsLink(link.fromParcelId, link.toParcelId) ||
        link.cost < 0 ||
        _state.farmCredits < link.cost) {
      return false;
    }

    _state = _state.copyWith(
      farmCredits: _state.farmCredits - link.cost,
      worldLogisticsLinks: [..._state.worldLogisticsLinks, link],
    );
    return true;
  }

  static const List<CropPlotState> defaultPlotList = [
    CropPlotState(
      id: 0,
      name: 'Başlangıç Tarlası',
      isOwned: false,
      purchaseCostCredits: 0,
      soilConditionPoints: 80,
      positionX: -165,
      positionY: -175,
      areaSquareMeters: 1000,
      mapX: -300,
      mapY: -235,
      mapWidth: 104,
      mapHeight: 70,
      mapParcelId: 'home-field-0',
      preferredCropFamily: CropFamily.grain,
    ),
    CropPlotState(
      id: 1,
      name: 'Kuzey Tarlası',
      isOwned: false,
      purchaseCostCredits: 1000,
      soilConditionPoints: 80,
      positionX: -165,
      positionY: -290,
      areaSquareMeters: 2400,
      mapX: -430,
      mapY: -340,
      mapWidth: 112,
      mapHeight: 138,
      mapParcelId: 'home-field-1',
      preferredCropFamily: CropFamily.grain,
    ),
    CropPlotState(
      id: 2,
      name: 'Batı Tarlası',
      isOwned: false,
      purchaseCostCredits: 1120,
      soilConditionPoints: 80,
      positionX: -310,
      positionY: -175,
      areaSquareMeters: 2800,
      mapX: -475,
      mapY: -180,
      mapWidth: 154,
      mapHeight: 74,
      mapParcelId: 'home-field-2',
      preferredCropFamily: CropFamily.oilseed,
    ),
    CropPlotState(
      id: 3,
      name: 'Güney Tarlası',
      isOwned: false,
      purchaseCostCredits: 1250,
      soilConditionPoints: 80,
      positionX: -165,
      positionY: -60,
      areaSquareMeters: 3100,
      mapX: -335,
      mapY: 20,
      mapWidth: 102,
      mapHeight: 138,
      mapParcelId: 'home-field-3',
      preferredCropFamily: CropFamily.rootTuber,
    ),
    CropPlotState(
      id: 4,
      name: 'Doğu Tarlası',
      isOwned: false,
      purchaseCostCredits: 1380,
      soilConditionPoints: 84,
      positionX: 80,
      positionY: -220,
      areaSquareMeters: 4200,
      mapX: 20,
      mapY: -245,
      mapWidth: 168,
      mapHeight: 94,
      mapParcelId: 'home-field-4',
      preferredCropFamily: CropFamily.grain,
    ),
    CropPlotState(
      id: 5,
      name: 'Kuzeydoğu Tarlası',
      isOwned: false,
      purchaseCostCredits: 1460,
      soilConditionPoints: 78,
      positionX: -80,
      positionY: -220,
      areaSquareMeters: 2600,
      mapX: -490,
      mapY: -10,
      mapWidth: 92,
      mapHeight: 112,
      mapParcelId: 'home-field-5',
      preferredCropFamily: CropFamily.legume,
    ),
    CropPlotState(
      id: 6,
      name: 'Güney Çayırı',
      isOwned: false,
      purchaseCostCredits: 900,
      soilConditionPoints: 82,
      positionX: 0,
      positionY: -300,
      areaSquareMeters: 3000,
      mapX: -190,
      mapY: 120,
      mapWidth: 148,
      mapHeight: 86,
      mapParcelId: 'home-meadow-6',
      use: CropPlotUse.pasture,
    ),
    CropPlotState(
      id: 7,
      name: 'Doğu Çayırı',
      isOwned: false,
      purchaseCostCredits: 1050,
      soilConditionPoints: 76,
      positionX: 80,
      positionY: -300,
      areaSquareMeters: 2200,
      mapX: 15,
      mapY: -70,
      mapWidth: 88,
      mapHeight: 128,
      mapParcelId: 'home-meadow-7',
      use: CropPlotUse.pasture,
    ),
  ];

  List<CropPlotState> get plots {
    _ensurePlotsCache();
    return _plotsCache;
  }

  void _ensurePlotsCache() {
    if (identical(_plotsCacheState, _state)) return;
    final savedById = {for (final plot in _state.plots) plot.id: plot};
    final knownIds = defaultPlotList.map((plot) => plot.id).toSet();
    final nextPlots = [
      for (final base in defaultPlotList)
        _hydrateStarterPlot(
          _hydrateLegacyMapData(savedById[base.id], base),
          base.id,
        ),
      ..._state.plots.where((plot) => !knownIds.contains(plot.id)),
    ];
    _plotsCache = nextPlots;
    _plotsByIdCache = {for (final plot in nextPlots) plot.id: plot};
    _ownedPlotCountCache = nextPlots.where((plot) => plot.isOwned).length;
    _plotsCacheState = _state;
  }

  CropPlotState _hydrateLegacyMapData(
    CropPlotState? saved,
    CropPlotState base,
  ) {
    if (saved == null) return base;
    if (saved.mapParcelId?.startsWith('home-') == true) {
      return saved.copyWith(
        mapX: base.mapX,
        mapY: base.mapY,
        mapWidth: base.mapWidth,
        mapHeight: base.mapHeight,
        mapParcelId: base.mapParcelId,
        use: base.use,
        preferredCropFamily: base.preferredCropFamily,
      );
    }
    if (saved.mapParcelId != null) return saved;
    return saved.copyWith(
      areaSquareMeters: base.areaSquareMeters,
      mapX: base.mapX,
      mapY: base.mapY,
      mapWidth: base.mapWidth,
      mapHeight: base.mapHeight,
      mapParcelId: base.mapParcelId,
      use: base.use,
      preferredCropFamily: base.preferredCropFamily,
    );
  }

  CropPlotState _hydrateStarterPlot(CropPlotState plot, int id) {
    if (id == 0) {
      if (starterPlotId == 0) {
        return plot.copyWith(
          isOwned: _state.hasOwnedInitialPlot,
          soilConditionPoints: _state.soilConditionPoints,
          activeCropId: _state.activeCropId,
          activeCropPlantedAt: _state.activeCropPlantedAt,
          hasHarvestedActiveCrop: _state.hasHarvestedActiveCrop,
        );
      }
      return plot.copyWith(isOwned: false);
    }
    if (id == adjacentStarterPlotId &&
        starterPlotId == adjacentStarterPlotId &&
        _state.hasOwnedInitialPlot) {
      return plot.copyWith(isOwned: true);
    }
    return plot;
  }

  CropPlotState? plotById(int plotId) {
    _ensurePlotsCache();
    return _plotsByIdCache[plotId];
  }

  bool canBuyPlot(int plotId) {
    if (_state.stage != OpeningStage.management) return false;
    final currentPlots = plots;
    final plotIndex = currentPlots.indexWhere((p) => p.id == plotId);
    if (plotIndex == -1) return false;
    final plot = currentPlots[plotIndex];
    return !plot.isOwned && _state.farmCredits >= plot.purchaseCostCredits;
  }

  bool buyPlot(int plotId) {
    if (!canBuyPlot(plotId)) return false;
    final currentPlots = List<CropPlotState>.from(plots);
    final plotIndex = currentPlots.indexWhere((p) => p.id == plotId);
    final plot = currentPlots[plotIndex];

    currentPlots[plotIndex] = plot.copyWith(isOwned: true);
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - plot.purchaseCostCredits,
      plots: currentPlots,
    );
    return true;
  }

  static const int fieldPreparationCostPerThousandSquareMeters = 45;
  static const int fieldHarvestCostPerThousandSquareMeters = 35;
  static const int fieldFertilizerCostPerThousandSquareMeters = 20;
  static const int pastureBalingCostPerThousandSquareMeters = 5;
  static const Duration pastureRegrowthDuration = Duration(minutes: 20);

  int scaledFieldCost(CropPlotState plot, int costPerThousandSquareMeters) =>
      max(
        1,
        (plot.areaSquareMeters * costPerThousandSquareMeters / 1000).round(),
      );

  int seedCostForPlot(CropPlotState plot, String cropId) {
    final crop = OpeningCropCatalog.byId(cropId);
    if (crop == null) return 0;
    return max(
      1,
      (crop.seedCostCredits * plot.areaSquareMeters / 1000).round(),
    );
  }

  int harvestCostForPlot(CropPlotState plot) =>
      scaledFieldCost(plot, fieldHarvestCostPerThousandSquareMeters);

  bool _tutorialAllows(FarmOperation operation, int plotId) {
    if (plotId != starterPlotId || isFarmTutorialComplete) return true;
    return switch (operation) {
      FarmOperation.prepare =>
        _state.farmTutorialStep == FarmTutorialStep.prepare,
      FarmOperation.fertilize =>
        _state.farmTutorialStep == FarmTutorialStep.fertilize,
      FarmOperation.sow => _state.farmTutorialStep == FarmTutorialStep.sow,
      FarmOperation.harvest =>
        _state.farmTutorialStep == FarmTutorialStep.harvest,
      FarmOperation.bale => true,
    };
  }

  bool _tutorialFastFor(FarmOperation operation, int plotId) =>
      plotId == starterPlotId &&
      switch (operation) {
        FarmOperation.prepare =>
          _state.farmTutorialStep == FarmTutorialStep.prepare,
        FarmOperation.fertilize =>
          _state.farmTutorialStep == FarmTutorialStep.fertilize,
        FarmOperation.sow => _state.farmTutorialStep == FarmTutorialStep.sow,
        FarmOperation.harvest =>
          _state.farmTutorialStep == FarmTutorialStep.harvest,
        FarmOperation.bale => false,
      };

  FarmOperationJob _newJob({
    required CropPlotState plot,
    required FarmOperation operation,
    required DateTime now,
    String? cropId,
    int harvestValue = 0,
    int outputQuantity = 0,
    bool isFullHarvest = false,
    int soilAfter = 0,
    int baleCount = 0,
  }) {
    final assignment = _availableEquipmentAssignmentFor(operation);
    if (assignment == null) {
      throw StateError('No available equipment for ${operation.name}.');
    }
    final equipment = assignment.equipment;
    final startedAt = now.toUtc();
    final tutorialFast = _tutorialFastFor(operation, plot.id);
    return FarmOperationJob(
      operation: operation,
      equipmentId: equipment.id,
      startedAt: startedAt,
      completesAt: startedAt.add(
        equipment.durationFor(
          plot.areaSquareMeters,
          tutorialFast: tutorialFast,
          tractor: assignment.tractor,
        ),
      ),
      cropId: cropId,
      harvestValue: harvestValue,
      outputQuantity: outputQuantity,
      isFullHarvest: isFullHarvest,
      soilAfter: soilAfter,
      baleCount: baleCount,
      tutorialFast: tutorialFast,
      tractorEquipmentId: assignment.tractor?.id,
    );
  }

  void _beginPlotJob(CropPlotState plot, FarmOperationJob job, int cost) {
    final currentPlots = List<CropPlotState>.from(plots);
    final index = currentPlots.indexWhere((item) => item.id == plot.id);
    currentPlots[index] = currentPlots[index].copyWith(activeJob: job);
    _state = _state.copyWith(
      farmCredits: _state.farmCredits - cost,
      plots: currentPlots,
    );
    _activeFarmJobsByPlotId[plot.id] = job;
  }

  bool canCultivatePlot(int plotId) {
    if (_state.stage != OpeningStage.management) return false;
    final plot = plotById(plotId);
    if (plot == null ||
        !plot.isOwned ||
        plot.use != CropPlotUse.arable ||
        plot.hasActiveCrop ||
        plot.hasActiveJob ||
        plot.isCultivated) {
      return false;
    }
    if (!canUseEquippedEquipmentFor(FarmOperation.prepare) ||
        !_tutorialAllows(FarmOperation.prepare, plotId)) {
      return false;
    }
    return _state.farmCredits >=
        scaledFieldCost(plot, fieldPreparationCostPerThousandSquareMeters);
  }

  bool cultivatePlot(int plotId, [DateTime? now]) {
    if (!canCultivatePlot(plotId)) return false;
    final currentPlots = List<CropPlotState>.from(plots);
    final index = currentPlots.indexWhere((plot) => plot.id == plotId);
    final plot = currentPlots[index];
    final cost = scaledFieldCost(
      plot,
      fieldPreparationCostPerThousandSquareMeters,
    );
    final job = _newJob(
      plot: plot,
      operation: FarmOperation.prepare,
      now: (now ?? DateTime.now()).toUtc(),
    );
    _beginPlotJob(plot, job, cost);
    return true;
  }

  bool canFertilizePlot(int plotId) {
    if (_state.stage != OpeningStage.management) return false;
    final plot = plotById(plotId);
    if (plot == null ||
        !plot.isOwned ||
        plot.use != CropPlotUse.arable ||
        plot.hasActiveCrop ||
        plot.hasActiveJob ||
        plot.soilConditionPoints >= soilConditionMaximumPoints) {
      return false;
    }
    if (!canUseEquippedEquipmentFor(FarmOperation.fertilize) ||
        !_tutorialAllows(FarmOperation.fertilize, plotId)) {
      return false;
    }
    return _state.farmCredits >=
        scaledFieldCost(plot, fieldFertilizerCostPerThousandSquareMeters);
  }

  bool fertilizePlot(int plotId, [DateTime? now]) {
    if (!canFertilizePlot(plotId)) return false;
    final plot = plotById(plotId)!;
    final cost = scaledFieldCost(
      plot,
      fieldFertilizerCostPerThousandSquareMeters,
    );
    final soilAfter = min(
      soilConditionMaximumPoints,
      plot.soilConditionPoints + soilCareRestoredPoints,
    );
    final job = _newJob(
      plot: plot,
      operation: FarmOperation.fertilize,
      now: (now ?? DateTime.now()).toUtc(),
      soilAfter: soilAfter,
    );
    _beginPlotJob(plot, job, cost);
    return true;
  }

  bool _cropTechnologyAvailable(String cropId) {
    final crop = OpeningCropCatalog.byId(cropId);
    if (crop == null ||
        (!_state.hasCompletedStarterTrade && crop.family != CropFamily.grain)) {
      return false;
    }
    return switch (cropId) {
      OpeningCropCatalog.sunflowerId => hasPurchasedTechnology(
        OpeningCropCatalog.sunflowerTechnologyId,
      ),
      OpeningCropCatalog.potatoId => hasPurchasedTechnology(
        OpeningCropCatalog.potatoTechnologyId,
      ),
      OpeningCropCatalog.chickpeaId => hasPurchasedTechnology(
        OpeningCropCatalog.chickpeaTechnologyId,
      ),
      _ => true,
    };
  }

  bool isCropUnlockedForFarm(String cropId) => _cropTechnologyAvailable(cropId);

  int estimatedHarvestValueForPlot(int plotId, String cropId) {
    final plot = plotById(plotId);
    final crop = OpeningCropCatalog.byId(cropId);
    if (plot == null || crop == null || plot.use != CropPlotUse.arable) {
      return 0;
    }
    var seasonalMultiplier = 1.0;
    final anchor = _state.firstSuccessfulPlantingAt;
    if (anchor != null) {
      final currentSeason = FarmCalendar.fromElapsed(
        elapsed: DateTime.now().toUtc().difference(anchor.toUtc()),
      ).season;
      seasonalMultiplier = currentSeason == crop.plantingSeason
          ? 1.0
          : offSeasonYieldMultiplier;
    }
    return (crop.fullHarvestValueCredits *
            (plot.areaSquareMeters / 1000.0) *
            plot.soilYieldMultiplier *
            plot.suitabilityForCrop(cropId) *
            plot.rotationYieldMultiplierFor(cropId) *
            seasonalMultiplier)
        .round();
  }

  bool canPlantCropOnPlot(int plotId, String cropId) {
    if (_state.stage != OpeningStage.management) return false;
    final plot = plotById(plotId);
    if (plot == null) return false;
    if (!plot.isOwned ||
        plot.use != CropPlotUse.arable ||
        plot.hasActiveCrop ||
        plot.hasActiveJob ||
        !plot.isCultivated ||
        !_cropTechnologyAvailable(cropId) ||
        !canUseEquippedEquipmentFor(FarmOperation.sow) ||
        !_tutorialAllows(FarmOperation.sow, plotId)) {
      return false;
    }
    final seedCost = seedCostForPlot(plot, cropId);
    final freeSeedOffset =
        plotId == starterPlotId && _state.freeInitialSeedsCount > 0
        ? min(seedCost, OpeningCropCatalog.byId(cropId)!.seedCostCredits)
        : 0;
    return _state.farmCredits >= seedCost - freeSeedOffset;
  }

  bool plantCropOnPlot(int plotId, String cropId, DateTime plantedAt) {
    if (!canPlantCropOnPlot(plotId, cropId)) return false;

    final crop = OpeningCropCatalog.byId(cropId)!;
    final plot = plotById(plotId)!;
    final totalSeedCost = seedCostForPlot(plot, cropId);
    final usesFreeSeed =
        plotId == starterPlotId && _state.freeInitialSeedsCount > 0;
    final seedCost =
        totalSeedCost -
        (usesFreeSeed ? min(totalSeedCost, crop.seedCostCredits).toInt() : 0);
    final job = _newJob(
      plot: plot,
      operation: FarmOperation.sow,
      now: plantedAt,
      cropId: cropId,
    );
    _beginPlotJob(plot, job, seedCost);
    if (usesFreeSeed) {
      _state = _state.copyWith(
        freeInitialSeedsCount: _state.freeInitialSeedsCount - 1,
      );
    }
    return true;
  }

  CropCycleSnapshot? cropSnapshotForPlot(int plotId, DateTime now) {
    if (plotId == 0 && starterPlotId == 0) return cropSnapshotAt(now);
    final plot = plotById(plotId);
    final anchor = _state.firstSuccessfulPlantingAt;
    if (plot == null || anchor == null) return null;
    return plot.cropSnapshotAt(now, anchor);
  }

  int harvestOutputQuantityForPlot(int plotId, DateTime now) {
    final snapshot = cropSnapshotForPlot(plotId, now);
    final crop = snapshot == null
        ? null
        : OpeningCropCatalog.byId(snapshot.crop.id);
    if (snapshot == null || crop == null) return 0;
    final unitPrice = max(1, crop.fullHarvestValueCredits ~/ 10);
    return max(1, (snapshot.harvestYield.round() / unitPrice).round());
  }

  bool canHarvestCropOnPlot(int plotId, DateTime now) {
    final plot = plotById(plotId);
    final snapshot = cropSnapshotForPlot(plotId, now);
    if (_state.stage != OpeningStage.management ||
        plot == null ||
        !plot.isOwned ||
        plot.hasActiveJob ||
        snapshot == null ||
        !snapshot.isHarvestable ||
        _state.farmCredits < harvestCostForPlot(plot) ||
        !canUseEquippedEquipmentFor(FarmOperation.harvest) ||
        !_tutorialAllows(FarmOperation.harvest, plotId)) {
      return false;
    }
    final reservedCapacity = plots
        .where((item) => item.activeJob?.operation == FarmOperation.harvest)
        .fold<int>(0, (total, item) => total + item.activeJob!.outputQuantity);
    return fleetManager.remainingWarehouseCapacity >=
        reservedCapacity + harvestOutputQuantityForPlot(plotId, now);
  }

  bool harvestCropOnPlot(int plotId, DateTime now) {
    if (!canHarvestCropOnPlot(plotId, now)) return false;
    final plot = plotById(plotId)!;
    final snapshot = cropSnapshotForPlot(plotId, now)!;
    final harvestValue = snapshot.harvestYield.round();
    final harvestCost = harvestCostForPlot(plot);
    final cropId = snapshot.crop.id;
    final marketQuantity = harvestOutputQuantityForPlot(plotId, now);
    final isFullHarvest =
        snapshot.status == CropCycleStatus.readyForHarvest &&
        snapshot.growthProgress >= 1;
    final job = _newJob(
      plot: plot,
      operation: FarmOperation.harvest,
      now: now,
      cropId: cropId,
      harvestValue: harvestValue,
      outputQuantity: marketQuantity,
      isFullHarvest: isFullHarvest,
    );
    _beginPlotJob(plot, job, harvestCost);
    AudioController.instance.playEffect(SoundEffect.harvest);
    return true;
  }

  bool canBalePasturePlot(int plotId, DateTime now) {
    final plot = plotById(plotId);
    return _state.stage == OpeningStage.management &&
        plot != null &&
        plot.isOwned &&
        plot.use == CropPlotUse.pasture &&
        !plot.hasActiveJob &&
        canUseEquippedEquipmentFor(FarmOperation.bale) &&
        plot.readyGrassBales == 0 &&
        (plot.nextGrassCutAt == null || !now.isBefore(plot.nextGrassCutAt!)) &&
        _state.farmCredits >=
            scaledFieldCost(plot, pastureBalingCostPerThousandSquareMeters);
  }

  bool balePasturePlot(int plotId, DateTime now) {
    if (!canBalePasturePlot(plotId, now)) return false;
    final plot = plotById(plotId)!;
    final cost = scaledFieldCost(
      plot,
      pastureBalingCostPerThousandSquareMeters,
    );
    final baleCount = max(1, (plot.areaSquareMeters / 1000).floor());
    final job = _newJob(
      plot: plot,
      operation: FarmOperation.bale,
      now: now,
      baleCount: baleCount,
    );
    _beginPlotJob(plot, job, cost);
    return true;
  }

  /// Resolves saved work orders whose wall-clock finish time has passed.
  /// Returns true only when at least one field operation was completed.
  bool advanceFarmOperations(DateTime now) {
    if (_activeFarmJobsByPlotId.isEmpty) return false;
    final nowUtc = now.toUtc();
    final hasDueJob = _activeFarmJobsByPlotId.values.any(
      (job) => !nowUtc.isBefore(job.completesAt),
    );
    if (!hasDueJob) return false;

    final currentPlots = List<CropPlotState>.from(plots);
    var credits = _state.farmCredits;
    var lifetimeEvidence = _state.lifetimeProductionEvidence;
    var firstPlanting = _state.firstSuccessfulPlantingAt;
    var rootCropId = _state.activeCropId;
    var rootCropPlantedAt = _state.activeCropPlantedAt;
    var rootCropHarvested = _state.hasHarvestedActiveCrop;
    var rootSoil = _state.soilConditionPoints;
    final completedStarterTrade = _state.hasCompletedStarterTrade;
    var starterTruck = _state.hasStarterTruck;
    var harvestedCropIds = {..._state.fullHarvestedCropIds};
    var tutorialStep = _state.farmTutorialStep;
    final harvestDeposits = <({String cropId, int quantity})>[];
    var changed = false;

    for (var index = 0; index < currentPlots.length; index++) {
      final plot = currentPlots[index];
      final job = plot.activeJob;
      if (job == null || nowUtc.isBefore(job.completesAt)) continue;

      changed = true;
      _activeFarmJobsByPlotId.remove(plot.id);
      switch (job.operation) {
        case FarmOperation.prepare:
          currentPlots[index] = plot.copyWith(
            isCultivated: true,
            clearActiveJob: true,
          );
        case FarmOperation.fertilize:
          currentPlots[index] = plot.copyWith(
            soilConditionPoints: job.soilAfter,
            clearActiveJob: true,
          );
          if (plot.id == starterPlotId) rootSoil = job.soilAfter;
        case FarmOperation.sow:
          final plantedAt = job.completesAt;
          firstPlanting ??= plantedAt;
          final effectivePlantedAt = plantedAt.isBefore(firstPlanting)
              ? firstPlanting
              : plantedAt;
          currentPlots[index] = plot.copyWith(
            activeCropId: job.cropId,
            activeCropPlantedAt: effectivePlantedAt,
            hasHarvestedActiveCrop: false,
            isCultivated: false,
            cropGrowthDurationOverrideSeconds: job.tutorialFast
                ? tutorialCropGrowthDuration.inSeconds
                : null,
            clearCropGrowthDurationOverride: !job.tutorialFast,
            clearActiveJob: true,
          );
          if (plot.id == starterPlotId) {
            rootCropId = job.cropId;
            rootCropPlantedAt = effectivePlantedAt;
            rootCropHarvested = false;
          }
        case FarmOperation.harvest:
          final cropId = job.cropId;
          final crop = cropId == null ? null : OpeningCropCatalog.byId(cropId);
          final plantedAt =
              plot.activeCropPlantedAt ??
              (plot.id == starterPlotId ? rootCropPlantedAt : null);
          final inSeason =
              crop != null &&
              plantedAt != null &&
              firstPlanting != null &&
              FarmCalendar.resolve(
                    plantedAt.toUtc().difference(firstPlanting.toUtc()),
                  ).season ==
                  crop.plantingSeason;
          final fullInSeason = job.isFullHarvest && inSeason;
          final previousFamily = plot.recentCropFamilies.isEmpty
              ? null
              : plot.recentCropFamilies.first;
          final sameFamily = crop != null && previousFamily == crop.family;
          final soilAfterHarvest = !job.isFullHarvest
              ? plot.soilConditionPoints
              : sameFamily
              ? max(0, plot.soilConditionPoints - 3)
              : min(soilConditionMaximumPoints, plot.soilConditionPoints + 1);
          final rotationHistory = job.isFullHarvest && crop != null
              ? [crop.family, ...plot.recentCropFamilies].take(3).toList()
              : plot.recentCropFamilies;
          currentPlots[index] = plot.copyWith(
            hasHarvestedActiveCrop: true,
            soilConditionPoints: soilAfterHarvest,
            recentCropFamilies: rotationHistory,
            clearCropGrowthDurationOverride: true,
            clearActiveJob: true,
          );
          if (plot.id == starterPlotId) {
            rootCropHarvested = true;
            rootSoil = soilAfterHarvest;
          }
          lifetimeEvidence += job.harvestValue;
          if (fullInSeason && cropId != null) harvestedCropIds.add(cropId);
          if (!starterTruck) fleetManager.initializeStarterFleet();
          starterTruck = true;
          if (cropId != null && job.outputQuantity > 0) {
            harvestDeposits.add((cropId: cropId, quantity: job.outputQuantity));
          }
        case FarmOperation.bale:
          currentPlots[index] = plot.copyWith(
            readyGrassBales: job.baleCount,
            nextGrassCutAt: job.completesAt.add(pastureRegrowthDuration),
            clearActiveJob: true,
          );
      }

      if (plot.id == starterPlotId && job.tutorialFast) {
        tutorialStep = switch (job.operation) {
          FarmOperation.prepare => FarmTutorialStep.fertilize,
          FarmOperation.fertilize => FarmTutorialStep.sow,
          FarmOperation.sow => FarmTutorialStep.growth,
          FarmOperation.harvest => FarmTutorialStep.warehouse,
          FarmOperation.bale => tutorialStep,
        };
      }
    }

    if (!changed) return false;
    _state = _state.copyWith(
      farmCredits: credits,
      lifetimeProductionEvidence: lifetimeEvidence,
      firstSuccessfulPlantingAt: firstPlanting,
      activeCropId: rootCropId,
      activeCropPlantedAt: rootCropPlantedAt,
      hasHarvestedActiveCrop: rootCropHarvested,
      soilConditionPoints: rootSoil,
      hasCompletedStarterTrade: completedStarterTrade,
      hasStarterTruck: starterTruck,
      fullHarvestedCropIds: harvestedCropIds,
      farmTutorialStep: tutorialStep,
      plots: currentPlots,
    );
    for (final deposit in harvestDeposits) {
      fleetManager.depositToWarehouse(deposit.cropId, deposit.quantity);
    }
    _tryAutomaticSoilCare();
    return true;
  }

  bool advanceFarmTutorial(DateTime now) {
    if (_state.farmTutorialStep != FarmTutorialStep.growth) return false;
    final snapshot = cropSnapshotForPlot(starterPlotId, now);
    if (snapshot == null || !snapshot.isHarvestable) return false;
    setFarmTutorialStep(FarmTutorialStep.harvest);
    return true;
  }

  bool sellPastureBales(int plotId) {
    if (_state.stage != OpeningStage.management) return false;
    final currentPlots = List<CropPlotState>.from(plots);
    final index = currentPlots.indexWhere((plot) => plot.id == plotId);
    if (index == -1 ||
        !currentPlots[index].isOwned ||
        currentPlots[index].use != CropPlotUse.pasture ||
        currentPlots[index].readyGrassBales <= 0) {
      return false;
    }
    final bales = currentPlots[index].readyGrassBales;
    final saleValue = bales * baleSalePrice;
    currentPlots[index] = currentPlots[index].copyWith(readyGrassBales: 0);
    _state = _state.copyWith(
      farmCredits: _state.farmCredits + saleValue,
      lifetimeProductionEvidence: _state.lifetimeProductionEvidence + saleValue,
      plots: currentPlots,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Logistics Fleet Management
  // ---------------------------------------------------------------------------

  int advanceLogistics(
    double dtSeconds, {
    DateTime? now,
    MarketPriceSimulator? marketOverride,
  }) {
    if (_state.stage != OpeningStage.management) return 0;
    final nowUtc = (now ?? DateTime.now()).toUtc();
    final activeMarket = marketOverride ?? marketPrices;
    _syncOperationalBuildings(nowUtc);
    activeMarket.stepMarket(dtSeconds / 60.0);
    if (!identical(activeMarket, marketPrices)) {
      marketPrices.stepMarket(dtSeconds / 60.0);
    }
    _advanceContractOffers(nowUtc);
    final earned = fleetManager.update(
      dtSeconds,
      unitPriceProvider: (itemId) =>
          activeMarket.getQuote(itemId, seasonAt(nowUtc)).currentPrice,
      onMarketDelivery:
          ({
            required String contractId,
            required String itemId,
            required int amount,
            required double quality,
            required int saleValue,
          }) {
            activeMarket.recordSale(itemId, amount);
            if (!identical(activeMarket, marketPrices)) {
              marketPrices.recordSale(itemId, amount);
            }
            return contractManager.recordDelivery(
              contractId: contractId,
              itemId: itemId,
              amount: amount,
              quality: quality,
              now: nowUtc,
            );
          },
    );
    if (earned > 0) {
      addCredits(earned);
      if (!_state.hasCompletedStarterTrade) {
        _state = _state.copyWith(
          hasCompletedStarterTrade: true,
          farmTutorialStep: _state.farmTutorialStep == FarmTutorialStep.delivery
              ? FarmTutorialStep.shop
              : _state.farmTutorialStep,
        );
      }
    }
    return earned;
  }

  bool startStarterMarketRoute({
    required double fieldX,
    required double fieldY,
    required String fieldName,
    String? productId,
    int? amountPerTrip,
    bool repeatRoute = false,
  }) {
    if (_state.stage != OpeningStage.management || !_state.hasStarterTruck) {
      return false;
    }
    if ((productId != null || amountPerTrip != null) && !hasResearch('L01')) {
      return false;
    }
    if (repeatRoute && !hasResearch('L04')) return false;
    final activeContract = contractManager.activeContract;
    if (activeContract != null &&
        productId != null &&
        productId != activeContract.itemId) {
      return false;
    }
    if (amountPerTrip != null &&
        (amountPerTrip <= 0 || amountPerTrip > TruckType.starter.capacity)) {
      return false;
    }
    fleetManager.initializeStarterFleet();
    final targetCropId = activeContract?.itemId ?? productId;
    final starterVehicle = fleetManager.vehicles.where(
      (vehicle) => vehicle.truckType == TruckType.starter,
    );
    if (fleetManager.totalWarehouseAmount <= 0 ||
        (targetCropId != null && warehouseAmountFor(targetCropId) <= 0) ||
        (productId != null && warehouseAmountFor(productId) <= 0) ||
        starterVehicle.isEmpty ||
        (starterVehicle.first.assignedRouteId != null &&
            starterVehicle.first.assignedRouteId != 'route_starter') ||
        starterVehicle.first.fuelLevel <= 0.01 ||
        starterVehicle.first.wearPercent >= 100) {
      return false;
    }
    fleetManager.startStarterMarketRoute(
      fieldX: fieldX,
      fieldY: fieldY,
      fieldName: fieldName,
      targetCropId: targetCropId,
      loadAmountLimit: amountPerTrip,
      isOneShot: !repeatRoute,
      contractId: activeContract?.id,
    );
    if (_state.farmTutorialStep == FarmTutorialStep.deliveryRoute) {
      _state = _state.copyWith(farmTutorialStep: FarmTutorialStep.delivery);
    }
    AudioController.instance.playEffect(SoundEffect.truckDepart);
    return true;
  }

  bool acceptDeliveryContract(String contractId, {DateTime? now}) {
    final at = (now ?? DateTime.now()).toUtc();
    if (_state.stage != OpeningStage.management ||
        !contractManager.accept(contractId, at)) {
      return false;
    }
    final active = contractManager.activeContract!;
    final routeIndex = fleetManager.routes.indexWhere(
      (route) => route.id == 'route_starter',
    );
    if (routeIndex >= 0) {
      final route = fleetManager.routes[routeIndex];
      final stops = route.stops.isEmpty
          ? route.stops
          : [
              route.stops.first.copyWith(targetCropId: active.itemId),
              ...route.stops.skip(1),
            ];
      fleetManager.routes[routeIndex] = route.copyWith(
        stops: stops,
        contractId: active.id,
      );
    }
    return true;
  }

  bool queueFleetRoute(String vehicleId, String routeId) {
    if (_state.stage != OpeningStage.management) return false;
    final vehicle = fleetManager.vehicles.where((item) => item.id == vehicleId);
    if (vehicle.isEmpty ||
        vehicle.first.fuelLevel <= 0.01 ||
        vehicle.first.wearPercent >= 100) {
      return false;
    }
    return fleetManager.enqueueRouteForVehicle(vehicleId, routeId);
  }

  bool setFleetRouteActive(String routeId, bool isActive) =>
      _state.stage == OpeningStage.management &&
      fleetManager.setRouteActive(routeId, isActive);

  bool setFleetVehiclePaused(String vehicleId, bool isPaused) =>
      _state.stage == OpeningStage.management &&
      fleetManager.setVehiclePaused(vehicleId, isPaused);

  bool cancelFleetVehicleRoutes(String vehicleId) =>
      _state.stage == OpeningStage.management &&
      fleetManager.cancelVehicleRoutes(vehicleId);

  bool cancelQueuedFleetRoute(String vehicleId, int queueIndex) =>
      _state.stage == OpeningStage.management &&
      fleetManager.cancelQueuedRoute(vehicleId, queueIndex);

  bool serviceFleetVehicle(String vehicleId) {
    if (_state.stage != OpeningStage.management) return false;
    final index = fleetManager.vehicles.indexWhere(
      (vehicle) => vehicle.id == vehicleId,
    );
    if (index < 0) return false;
    final vehicle = fleetManager.vehicles[index];
    final cost = fleetManager.serviceCostFor(vehicle);
    if (_state.farmCredits < cost || !fleetManager.serviceVehicle(vehicleId)) {
      return false;
    }
    _state = _state.copyWith(farmCredits: _state.farmCredits - cost);
    return true;
  }

  bool advanceProcessing(double dtSeconds, {DateTime? now}) {
    if (_state.stage != OpeningStage.management || dtSeconds <= 0) return false;
    final nowUtc = (now ?? DateTime.now()).toUtc();
    _syncOperationalBuildings(nowUtc);
    var changed = _advancePassiveBuildingProduction(dtSeconds, now: nowUtc);
    for (final facility in plantManager.facilities) {
      final eligibleRecipeIds = availableProcessingRecipeIds(
        facility,
        at: nowUtc,
      );
      facility.isUnlocked = eligibleRecipeIds.isNotEmpty;
      if (eligibleRecipeIds.isEmpty) continue;
      var loadedInput = false;
      for (final recipeId in eligibleRecipeIds) {
        final recipe = ProcessingRecipeCatalog.byId(recipeId);
        if (recipe == null) continue;
        final buffered = facility.inputBuffer
            .where((lot) => lot.itemId == recipe.inputCropId)
            .fold(0, (total, lot) => total + lot.amount);
        final need = min(
          max(0, recipe.inputAmount - buffered),
          facility.remainingInputCapacity,
        );
        if (need <= 0) continue;
        final withdrawn = _withdrawFromWarehouse(recipe.inputCropId, need);
        if (withdrawn > 0) {
          facility.depositInput(recipe.inputCropId, withdrawn);
          loadedInput = true;
        }
      }
      final wasProcessing = facility.status == FacilityStatus.processing;
      facility.update(dtSeconds, eligibleRecipeIds: eligibleRecipeIds.toSet());
      var transferred = false;
      for (final lot in [...facility.outputBuffer]) {
        final stored = fleetManager.depositToWarehouse(
          lot.itemId,
          lot.amount,
          ageMinutes: lot.ageMinutes,
          quality: lot.quality,
        );
        if (stored <= 0) continue;
        lot.amount -= stored;
        if (lot.amount <= 0) facility.outputBuffer.remove(lot);
        transferred = true;
      }
      changed =
          changed ||
          loadedInput ||
          transferred ||
          wasProcessing ||
          facility.status == FacilityStatus.processing;
    }
    return changed;
  }

  bool _advancePassiveBuildingProduction(
    double dtSeconds, {
    required DateTime now,
  }) {
    var changed = false;
    for (final building in _state.buildings) {
      if (!building.isOperationalAt(now)) continue;
      final product = switch (building.definitionId) {
        'greenhouse' => (
          itemId: 'greenhouse_vegetables',
          seconds: 240.0,
          amount: 4,
        ),
        'orchard' => (itemId: 'orchard_fruit', seconds: 900.0, amount: 6),
        _ => null,
      };
      if (product == null) continue;
      var progress =
          (_buildingProductionProgress[building.parcelId] ?? 0) + dtSeconds;
      while (progress >= product.seconds &&
          fleetManager.remainingWarehouseCapacity > 0) {
        final stored = fleetManager.depositToWarehouse(
          product.itemId,
          product.amount,
        );
        if (stored <= 0) break;
        progress -= product.seconds;
        changed = true;
      }
      _buildingProductionProgress[building.parcelId] = progress
          .clamp(0, product.seconds)
          .toDouble();
    }
    return changed;
  }

  bool advanceLivestock(double dtSeconds, {DateTime? now}) {
    if (_state.stage != OpeningStage.management || dtSeconds <= 0) return false;
    _syncOperationalBuildings((now ?? DateTime.now()).toUtc());
    if (!coop.isUnlocked) return false;
    final previousFeed = coop.feedStock;
    final previousEggs = coop.eggStock;
    if (coop.remainingFeedCapacity > 0 && coop.feedStock < 30) {
      var feedNeeded = min(
        coop.remainingFeedCapacity.floor(),
        (30 - coop.feedStock).ceil(),
      );
      for (final grainId in [starterWheatId, starterMaizeId]) {
        if (feedNeeded <= 0) break;
        final withdrawn = _withdrawFromWarehouse(
          grainId,
          min(feedNeeded, warehouseAmountFor(grainId)),
        );
        if (withdrawn > 0) {
          coop.addFeed(withdrawn.toDouble());
          feedNeeded -= withdrawn;
        }
      }
    }
    coop.update(dtSeconds);
    final storeCount = min(
      coop.eggStock,
      fleetManager.remainingWarehouseCapacity,
    );
    if (storeCount > 0) {
      final eggs = coop.takeEggs(storeCount);
      fleetManager.depositToWarehouse('fresh_eggs', eggs);
    }
    return previousFeed != coop.feedStock || previousEggs != coop.eggStock;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => state.toJson();

  factory OpeningSession.fromJson(Map<String, dynamic> json) {
    return OpeningSession(initialState: OpeningSessionState.fromJson(json));
  }
}
