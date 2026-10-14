import 'crop_cycle.dart';
import 'farm_equipment.dart';
import 'farm_calendar.dart';
import 'opening_crop_catalog.dart';

enum CropPlotUse { arable, pasture }

/// State representation of a single farming plot on the management map.
class CropPlotState {
  const CropPlotState({
    required this.id,
    required this.name,
    this.isOwned = false,
    this.purchaseCostCredits = 1000,
    this.soilConditionPoints = 80,
    this.activeCropId,
    this.activeCropPlantedAt,
    this.hasHarvestedActiveCrop = false,
    this.positionX = 0,
    this.positionY = 0,
    this.areaSquareMeters = 1000,
    this.mapX = 0,
    this.mapY = 0,
    this.mapWidth = 64,
    this.mapHeight = 48,
    this.mapParcelId,
    this.use = CropPlotUse.arable,
    this.preferredCropFamily = CropFamily.grain,
    this.recentCropFamilies = const <CropFamily>[],
    this.isCultivated = false,
    this.readyGrassBales = 0,
    this.nextGrassCutAt,
    this.activeJob,
    this.cropGrowthDurationOverrideSeconds,
  });

  final int id;
  final String name;
  final bool isOwned;
  final int purchaseCostCredits;
  final int soilConditionPoints;
  final String? activeCropId;
  final DateTime? activeCropPlantedAt;
  final bool hasHarvestedActiveCrop;
  final double positionX;
  final double positionY;
  final int areaSquareMeters;
  final double mapX;
  final double mapY;
  final double mapWidth;
  final double mapHeight;
  final String? mapParcelId;
  final CropPlotUse use;
  final CropFamily preferredCropFamily;
  final List<CropFamily> recentCropFamilies;
  final bool isCultivated;
  final int readyGrassBales;
  final DateTime? nextGrassCutAt;
  final FarmOperationJob? activeJob;
  final int? cropGrowthDurationOverrideSeconds;

  bool get hasActiveCrop =>
      activeCropId != null &&
      activeCropPlantedAt != null &&
      !hasHarvestedActiveCrop;

  bool get hasActiveJob => activeJob != null;

  double get soilYieldMultiplier =>
      0.90 + (soilConditionPoints.clamp(0, 100) / 1000.0);

  double suitabilityForCrop(String cropId) {
    if (use == CropPlotUse.pasture) return 0.80;
    final family = OpeningCropCatalog.familyFor(cropId);
    final preference = family == preferredCropFamily ? 1.08 : 0.94;
    final soilBias = (soilConditionPoints.clamp(0, 100) - 80) / 2000.0;
    return (preference + soilBias).clamp(0.80, 1.15).toDouble();
  }

  double rotationYieldMultiplierFor(String cropId) {
    final family = OpeningCropCatalog.familyFor(cropId);
    if (family == null || recentCropFamilies.isEmpty) return 1.0;
    final recent = recentCropFamilies.take(3).toList(growable: false);
    if (recent.first == family) return 0.84;
    if (recent.contains(family)) return 0.93;
    return family == CropFamily.legume ? 1.08 : 1.04;
  }

  bool containsMapPoint(double x, double y) =>
      (x - mapX).abs() <= mapWidth / 2 && (y - mapY).abs() <= mapHeight / 2;

  CropPlotState copyWith({
    int? id,
    String? name,
    bool? isOwned,
    int? purchaseCostCredits,
    int? soilConditionPoints,
    String? activeCropId,
    DateTime? activeCropPlantedAt,
    bool? hasHarvestedActiveCrop,
    double? positionX,
    double? positionY,
    int? areaSquareMeters,
    double? mapX,
    double? mapY,
    double? mapWidth,
    double? mapHeight,
    String? mapParcelId,
    CropPlotUse? use,
    CropFamily? preferredCropFamily,
    List<CropFamily>? recentCropFamilies,
    bool? isCultivated,
    int? readyGrassBales,
    DateTime? nextGrassCutAt,
    FarmOperationJob? activeJob,
    bool clearActiveJob = false,
    int? cropGrowthDurationOverrideSeconds,
    bool clearCropGrowthDurationOverride = false,
  }) {
    return CropPlotState(
      id: id ?? this.id,
      name: name ?? this.name,
      isOwned: isOwned ?? this.isOwned,
      purchaseCostCredits: purchaseCostCredits ?? this.purchaseCostCredits,
      soilConditionPoints: soilConditionPoints ?? this.soilConditionPoints,
      activeCropId: activeCropId ?? this.activeCropId,
      activeCropPlantedAt: activeCropPlantedAt ?? this.activeCropPlantedAt,
      hasHarvestedActiveCrop:
          hasHarvestedActiveCrop ?? this.hasHarvestedActiveCrop,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      areaSquareMeters: areaSquareMeters ?? this.areaSquareMeters,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      mapWidth: mapWidth ?? this.mapWidth,
      mapHeight: mapHeight ?? this.mapHeight,
      mapParcelId: mapParcelId ?? this.mapParcelId,
      use: use ?? this.use,
      preferredCropFamily: preferredCropFamily ?? this.preferredCropFamily,
      recentCropFamilies: recentCropFamilies ?? this.recentCropFamilies,
      isCultivated: isCultivated ?? this.isCultivated,
      readyGrassBales: readyGrassBales ?? this.readyGrassBales,
      nextGrassCutAt: nextGrassCutAt ?? this.nextGrassCutAt,
      activeJob: clearActiveJob ? null : activeJob ?? this.activeJob,
      cropGrowthDurationOverrideSeconds: clearCropGrowthDurationOverride
          ? null
          : cropGrowthDurationOverrideSeconds ??
                this.cropGrowthDurationOverrideSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isOwned': isOwned,
    'purchaseCostCredits': purchaseCostCredits,
    'soilConditionPoints': soilConditionPoints,
    'activeCropId': activeCropId,
    if (activeCropPlantedAt != null)
      'activeCropPlantedAt': activeCropPlantedAt!.toUtc().toIso8601String(),
    'hasHarvestedActiveCrop': hasHarvestedActiveCrop,
    'positionX': positionX,
    'positionY': positionY,
    'areaSquareMeters': areaSquareMeters,
    'mapX': mapX,
    'mapY': mapY,
    'mapWidth': mapWidth,
    'mapHeight': mapHeight,
    if (mapParcelId != null) 'mapParcelId': mapParcelId,
    'use': use.name,
    'preferredCropFamily': preferredCropFamily.name,
    'recentCropFamilies': recentCropFamilies
        .map((family) => family.name)
        .toList(),
    'isCultivated': isCultivated,
    'readyGrassBales': readyGrassBales,
    if (nextGrassCutAt != null)
      'nextGrassCutAt': nextGrassCutAt!.toUtc().toIso8601String(),
    if (activeJob != null) 'activeJob': activeJob!.toJson(),
    if (cropGrowthDurationOverrideSeconds != null)
      'cropGrowthDurationOverrideSeconds': cropGrowthDurationOverrideSeconds,
  };

  factory CropPlotState.fromJson(Map<String, dynamic> json) {
    return CropPlotState(
      id: json['id'] as int,
      name: json['name'] as String,
      isOwned: json['isOwned'] as bool? ?? false,
      purchaseCostCredits: json['purchaseCostCredits'] as int? ?? 1000,
      soilConditionPoints: json['soilConditionPoints'] as int? ?? 80,
      activeCropId: json['activeCropId'] as String?,
      activeCropPlantedAt: json['activeCropPlantedAt'] != null
          ? DateTime.parse(json['activeCropPlantedAt'] as String).toUtc()
          : null,
      hasHarvestedActiveCrop: json['hasHarvestedActiveCrop'] as bool? ?? false,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      areaSquareMeters: json['areaSquareMeters'] as int? ?? 1000,
      mapX: (json['mapX'] as num?)?.toDouble() ?? 0.0,
      mapY: (json['mapY'] as num?)?.toDouble() ?? 0.0,
      mapWidth: (json['mapWidth'] as num?)?.toDouble() ?? 64.0,
      mapHeight: (json['mapHeight'] as num?)?.toDouble() ?? 48.0,
      mapParcelId: json['mapParcelId'] as String?,
      use: CropPlotUse.values.byName(
        json['use'] as String? ?? CropPlotUse.arable.name,
      ),
      preferredCropFamily: CropFamily.values.byName(
        json['preferredCropFamily'] as String? ?? CropFamily.grain.name,
      ),
      recentCropFamilies:
          (json['recentCropFamilies'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map(CropFamily.values.byName)
              .toList(growable: false),
      isCultivated: json['isCultivated'] as bool? ?? false,
      readyGrassBales: json['readyGrassBales'] as int? ?? 0,
      nextGrassCutAt: json['nextGrassCutAt'] != null
          ? DateTime.parse(json['nextGrassCutAt'] as String).toUtc()
          : null,
      activeJob: json['activeJob'] is Map<String, dynamic>
          ? FarmOperationJob.fromJson(json['activeJob'] as Map<String, dynamic>)
          : null,
      cropGrowthDurationOverrideSeconds:
          json['cropGrowthDurationOverrideSeconds'] as int?,
    );
  }

  CropCycleSnapshot? cropSnapshotAt(DateTime now, DateTime anchor) {
    if (!hasActiveCrop) return null;
    final planted = activeCropPlantedAt;
    final cropDef = OpeningCropCatalog.byId(activeCropId!);
    if (planted == null || cropDef == null) return null;

    final anchorUtc = anchor.toUtc();
    final plantedElapsed = planted.toUtc().difference(anchorUtc);
    final validPlanted = plantedElapsed.isNegative
        ? Duration.zero
        : plantedElapsed;
    final elapsedFromAnchor = now.toUtc().difference(anchorUtc);
    final elapsed = elapsedFromAnchor < validPlanted
        ? validPlanted
        : elapsedFromAnchor;

    final plantingCalendar = FarmCalendar.resolve(validPlanted);
    final seasonEndElapsed =
        validPlanted -
        plantingCalendar.timeInSeason +
        FarmCalendar.seasonDuration;

    final cycleCrop = cropGrowthDurationOverrideSeconds == null
        ? cropDef.toCycleDefinition()
        : CropDefinition(
            id: cropDef.id,
            fullGrowthDuration: Duration(
              seconds: cropGrowthDurationOverrideSeconds!,
            ),
            fullHarvestYield: cropDef.toCycleDefinition().fullHarvestYield,
          );
    final cycle = CropCycle(
      crop: cycleCrop,
      plantedElapsed: validPlanted,
      harvestWindowCloseElapsed: seasonEndElapsed,
    );
    final snapshot = cycle.evaluate(elapsed);
    final seasonalYieldMultiplier =
        plantingCalendar.season == cropDef.plantingSeason ? 1.0 : 0.75;

    return CropCycleSnapshot(
      cycle: snapshot.cycle,
      evaluationElapsed: snapshot.evaluationElapsed,
      status: snapshot.status,
      growthProgress: snapshot.growthProgress,
      harvestYield:
          snapshot.harvestYield *
          (areaSquareMeters / 1000.0) *
          soilYieldMultiplier *
          suitabilityForCrop(activeCropId!) *
          rotationYieldMultiplierFor(activeCropId!) *
          seasonalYieldMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropPlotState &&
          other.id == id &&
          other.name == name &&
          other.isOwned == isOwned &&
          other.purchaseCostCredits == purchaseCostCredits &&
          other.soilConditionPoints == soilConditionPoints &&
          other.activeCropId == activeCropId &&
          other.activeCropPlantedAt == activeCropPlantedAt &&
          other.hasHarvestedActiveCrop == hasHarvestedActiveCrop &&
          other.positionX == positionX &&
          other.positionY == positionY &&
          other.areaSquareMeters == areaSquareMeters &&
          other.mapX == mapX &&
          other.mapY == mapY &&
          other.mapWidth == mapWidth &&
          other.mapHeight == mapHeight &&
          other.mapParcelId == mapParcelId &&
          other.use == use &&
          other.preferredCropFamily == preferredCropFamily &&
          _cropFamilyListsEqual(other.recentCropFamilies, recentCropFamilies) &&
          other.isCultivated == isCultivated &&
          other.readyGrassBales == readyGrassBales &&
          other.nextGrassCutAt == nextGrassCutAt &&
          other.activeJob == activeJob &&
          other.cropGrowthDurationOverrideSeconds ==
              cropGrowthDurationOverrideSeconds;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    isOwned,
    purchaseCostCredits,
    soilConditionPoints,
    activeCropId,
    activeCropPlantedAt,
    hasHarvestedActiveCrop,
    positionX,
    positionY,
    areaSquareMeters,
    mapX,
    mapY,
    mapWidth,
    mapHeight,
    mapParcelId,
    use,
    preferredCropFamily,
    Object.hashAll(recentCropFamilies),
    isCultivated,
    readyGrassBales,
    nextGrassCutAt,
    activeJob,
    cropGrowthDurationOverrideSeconds,
  ]);
}

bool _cropFamilyListsEqual(List<CropFamily> left, List<CropFamily> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
