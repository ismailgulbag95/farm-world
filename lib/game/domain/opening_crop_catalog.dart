import 'crop_cycle.dart';
import 'farm_calendar.dart';

/// The early crop families represented in the playable opening slice.
enum CropFamily { grain, oilseed, rootTuber, legume }

/// Localized, balance-ready crop data used by the opening farm loop.
///
/// All player-facing names remain in the localization catalog. The stable crop
/// ID is used for persistence and gameplay rules only.
class OpeningCropDefinition {
  const OpeningCropDefinition({
    required this.id,
    required this.family,
    required this.nameKey,
    required this.fullGrowthDuration,
    required this.fullHarvestValueCredits,
    required this.seedCostCredits,
    required this.plantingSeason,
    required this.artworkPath,
  });

  final String id;
  final CropFamily family;
  final String nameKey;
  final Duration fullGrowthDuration;
  final int fullHarvestValueCredits;
  final int seedCostCredits;
  final Season plantingSeason;
  final String artworkPath;

  CropDefinition toCycleDefinition() => CropDefinition(
    id: id,
    fullGrowthDuration: fullGrowthDuration,
    fullHarvestYield: fullHarvestValueCredits,
  );
}

/// Small catalog for crops that can be grown during the first diversity step.
///
/// Later catalog expansions should be sourced from
/// `docs/crop-tree-and-calendar-proposal.md` and keep the same data contract.
abstract final class OpeningCropCatalog {
  static const String maizeId = 'CR02';
  static const String wheatId = 'CR01';
  static const String sunflowerId = 'CR03';
  static const String potatoId = 'CR04';
  static const String chickpeaId = 'CR05';

  static const String oilseedFamilyTechnologyId = 'T05';
  static const String rootTuberFamilyTechnologyId = 'T06';
  static const String sunflowerTechnologyId = 'T13';
  static const String potatoTechnologyId = 'T14';
  static const String legumeFamilyTechnologyId = 'T15';
  static const String chickpeaTechnologyId = 'T16';

  static const int p2EvidenceThresholdCredits = 1000;
  static const int c2TechnologyCostCredits = 600;

  static const List<OpeningCropDefinition> all = [
    OpeningCropDefinition(
      id: wheatId,
      family: CropFamily.grain,
      nameKey: 'wheatCropName',
      fullGrowthDuration: Duration(minutes: 6),
      fullHarvestValueCredits: 1000,
      seedCostCredits: 120,
      plantingSeason: Season.winter,
      artworkPath: 'assets/visual-concepts/pilot/crop-wheat-mature-v1.png',
    ),
    OpeningCropDefinition(
      id: maizeId,
      family: CropFamily.grain,
      nameKey: 'maizeCropName',
      fullGrowthDuration: Duration(minutes: 6),
      fullHarvestValueCredits: 1000,
      seedCostCredits: 120,
      plantingSeason: Season.spring,
      artworkPath: 'assets/visual-concepts/pilot/crop-maize-mature-v1.png',
    ),
    OpeningCropDefinition(
      id: sunflowerId,
      family: CropFamily.oilseed,
      nameKey: 'sunflowerCropName',
      fullGrowthDuration: Duration(minutes: 15),
      fullHarvestValueCredits: 1650,
      seedCostCredits: 198,
      plantingSeason: Season.spring,
      artworkPath: 'assets/visual-concepts/pilot/crop-sunflower-mature-v1.png',
    ),
    OpeningCropDefinition(
      id: potatoId,
      family: CropFamily.rootTuber,
      nameKey: 'potatoCropName',
      fullGrowthDuration: Duration(minutes: 15),
      fullHarvestValueCredits: 1650,
      seedCostCredits: 198,
      plantingSeason: Season.spring,
      artworkPath: 'assets/visual-concepts/pilot/crop-potato-mature-v1.png',
    ),
    OpeningCropDefinition(
      id: chickpeaId,
      family: CropFamily.legume,
      nameKey: 'chickpeaCropName',
      fullGrowthDuration: Duration(minutes: 22),
      fullHarvestValueCredits: 2350,
      seedCostCredits: 282,
      plantingSeason: Season.winter,
      artworkPath: 'assets/visual-concepts/pilot/crop-chickpea-stages-v1.png',
    ),
  ];

  static OpeningCropDefinition? byId(String id) {
    for (final crop in all) {
      if (crop.id == id) return crop;
    }
    return null;
  }

  static CropFamily? familyFor(String id) => byId(id)?.family;
}
