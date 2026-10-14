/// Buildable farm facilities and persistent construction work orders.
///
/// A building becomes operational when its construction deadline passes. Land
/// use, research gates and financial rules are enforced by [OpeningSession].
library;

enum FarmBuildingCategory { production, storage, livestock, logistics, land }

class FarmBuildingDefinition {
  const FarmBuildingDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageAsset,
    required this.requiredTechnologyIds,
    required this.minimumAreaHectares,
    required this.constructionCostCredits,
    required this.constructionDuration,
    required this.dailyOperatingCostCredits,
  });

  final String id;
  final String name;
  final FarmBuildingCategory category;
  final String description;
  final String imageAsset;
  final List<String> requiredTechnologyIds;
  final double minimumAreaHectares;
  final int constructionCostCredits;
  final Duration constructionDuration;
  final int dailyOperatingCostCredits;

  /// Additional shared-warehouse space granted while this building is running.
  int get warehouseCapacityBonus => switch (id) {
    'farm_warehouse' => 250,
    'seed_warehouse' => 80,
    'grain_silo' => 320,
    'cold_room' => 140,
    'controlled_store' => 220,
    'long_term_warehouse' => 500,
    _ => 0,
  };

  /// Recipes this facility can run from harvested stock in the shared depot.
  List<String> get recipeIds => switch (id) {
    'wheat_mill' => const ['rcp_wheat_flour'],
    'maize_mill' => const ['rcp_cornmeal'],
    'sunflower_press' => const ['rcp_sunflower_oil'],
    'potato_starch' || 'root_tuber_works' => const ['rcp_potato_starch'],
    'chickpea_mill' => const ['rcp_chickpea_flour'],
    'vegetable_packhouse' => const ['rcp_packed_potatoes'],
    'goat_barn' => const ['rcp_goat_milk'],
    'apiary' => const ['rcp_honey'],
    'sheep_barn' => const ['rcp_wool'],
    'dairy_barn' => const ['rcp_cow_milk'],
    _ => const [],
  };

  int get warehouseCapacityContribution => warehouseCapacityBonus;

  double get logisticsSpeedBonus => switch (id) {
    'transfer_hub' => 0.10,
    'bulk_loading' => 0.06,
    _ => 0,
  };

  double get warehouseFreshnessMultiplier => switch (id) {
    'cold_room' => 0.45,
    'controlled_store' => 0.25,
    'long_term_warehouse' => 0.70,
    'grain_silo' => 0.80,
    _ => 1.0,
  };
}

abstract final class FarmBuildingCatalog {
  static const constructionSiteAsset =
      'assets/images/management/building-construction-v1.webp';

  static const List<FarmBuildingDefinition> all = [
    FarmBuildingDefinition(
      id: 'greenhouse',
      name: 'Sera',
      category: FarmBuildingCategory.production,
      description: 'Mevsimlik ürünleri kontrollü ortamda yetiştirir. T30 araştırması sera iklim kontrolünü geliştirir.',
      imageAsset: 'assets/images/management/building-greenhouse-v1.webp',
      requiredTechnologyIds: ['T04'],
      minimumAreaHectares: 0.08,
      constructionCostCredits: 2400,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 24,
    ),
    FarmBuildingDefinition(
      id: 'orchard',
      name: 'Meyve bahçesi',
      category: FarmBuildingCategory.land,
      description: 'Kalıcı plantasyon kurulur; ilk ürün olgunlaşması uzun süreli yetişme çevrimini izler.',
      imageAsset: 'assets/images/management/building-orchard-v1.webp',
      requiredTechnologyIds: ['T09', 'T12'],
      minimumAreaHectares: 0.24,
      constructionCostCredits: 5200,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 28,
    ),
    FarmBuildingDefinition(
      id: 'maize_mill',
      name: 'Mısır unu değirmeni',
      category: FarmBuildingCategory.production,
      description:
          'Araştırılmış mısır tariflerini çalıştıracak değirmen hattını kurar.',
      imageAsset: 'assets/images/management/building-maize-mill-v1.webp',
      requiredTechnologyIds: ['PR01'],
      minimumAreaHectares: 0.12,
      constructionCostCredits: 4400,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 38,
    ),
    FarmBuildingDefinition(
      id: 'sunflower_press',
      name: 'Ayçiçeği yağı presi',
      category: FarmBuildingCategory.production,
      description:
          'Araştırılmış yağlı tohum tarifleri için pres ve tank alanı kurar.',
      imageAsset: 'assets/images/management/building-oil-press-v1.webp',
      requiredTechnologyIds: ['PR05'],
      minimumAreaHectares: 0.13,
      constructionCostCredits: 4800,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 42,
    ),
    FarmBuildingDefinition(
      id: 'potato_starch',
      name: 'Patates nişastası tesisi',
      category: FarmBuildingCategory.production,
      description: 'Patates nişastası hattını kurar; PR41 araştırması kök ve yumru tariflerini ekler.',
      imageAsset: 'assets/images/management/building-starch-works-v1.webp',
      requiredTechnologyIds: ['PR06'],
      minimumAreaHectares: 0.15,
      constructionCostCredits: 5200,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 45,
    ),
    FarmBuildingDefinition(
      id: 'chickpea_mill',
      name: 'Nohut unu tesisi',
      category: FarmBuildingCategory.production,
      description:
          'Nohut unu üretim hattını açar; ham nohut satışı devam eder.',
      imageAsset: 'assets/images/management/building-chickpea-mill-v1.webp',
      requiredTechnologyIds: ['PR12'],
      minimumAreaHectares: 0.12,
      constructionCostCredits: 4200,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 36,
    ),
    FarmBuildingDefinition(
      id: 'wheat_mill',
      name: 'Buğday değirmeni',
      category: FarmBuildingCategory.production,
      description: 'Buğdayı un hattına yönlendiren değirmeni kurar.',
      imageAsset: 'assets/images/management/building-grain-mill-v1.webp',
      requiredTechnologyIds: ['PR13'],
      minimumAreaHectares: 0.12,
      constructionCostCredits: 4400,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 38,
    ),
    FarmBuildingDefinition(
      id: 'sugar_factory',
      name: 'Şeker fabrikası',
      category: FarmBuildingCategory.production,
      description:
          'Şeker pancarı ve şeker kamışı tarifleri için işleme tesisi kurar.',
      imageAsset: 'assets/images/management/building-sugar-works-v1.webp',
      requiredTechnologyIds: ['PR19'],
      minimumAreaHectares: 0.22,
      constructionCostCredits: 6800,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 58,
    ),
    FarmBuildingDefinition(
      id: 'vegetable_packhouse',
      name: 'Sebze paketleme merkezi',
      category: FarmBuildingCategory.production,
      description: 'Sebzeleri yıkama, boylama ve paketleme hattına alır.',
      imageAsset: 'assets/images/management/building-produce-packhouse-v1.webp',
      requiredTechnologyIds: ['PR23'],
      minimumAreaHectares: 0.16,
      constructionCostCredits: 5600,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 46,
    ),
    FarmBuildingDefinition(
      id: 'root_tuber_works',
      name: 'Kök ve yumru işleme tesisi',
      category: FarmBuildingCategory.production,
      description:
          'PR41 ile açılan kök ve yumru işleme tarifleri için tesis kurar.',
      imageAsset: 'assets/images/management/building-root-tuber-works-v1.webp',
      requiredTechnologyIds: ['PR41'],
      minimumAreaHectares: 0.16,
      constructionCostCredits: 6200,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 50,
    ),
    FarmBuildingDefinition(
      id: 'tropical_works',
      name: 'Tropik ürün işleme fabrikası',
      category: FarmBuildingCategory.production,
      description: 'Avokado, hindistan cevizi ve benzeri açılmış tropik ürün tariflerini işler.',
      imageAsset: 'assets/images/management/building-tropical-works-v1.webp',
      requiredTechnologyIds: ['PR43'],
      minimumAreaHectares: 0.20,
      constructionCostCredits: 7200,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 62,
    ),
    FarmBuildingDefinition(
      id: 'farm_warehouse',
      name: 'Çiftlik deposu',
      category: FarmBuildingCategory.storage,
      description:
          'Ürünleri ve çiftlik malzemelerini işletme sahasında saklar.',
      imageAsset: 'assets/images/management/building-warehouse-v1.webp',
      requiredTechnologyIds: ['S01'],
      minimumAreaHectares: 0.06,
      constructionCostCredits: 2200,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 14,
    ),
    FarmBuildingDefinition(
      id: 'seed_warehouse',
      name: 'Tohum ambarı',
      category: FarmBuildingCategory.storage,
      description: 'Tohum stokları için ayrılmış ambar alanı açar.',
      imageAsset: 'assets/images/management/building-seed-warehouse-v1.webp',
      requiredTechnologyIds: ['S08'],
      minimumAreaHectares: 0.05,
      constructionCostCredits: 1900,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 12,
    ),
    FarmBuildingDefinition(
      id: 'grain_silo',
      name: 'Kuru tahıl silosu',
      category: FarmBuildingCategory.storage,
      description:
          'Tahıl stok kapasitesini büyütür ve parti bozulmasını yavaşlatır.',
      imageAsset: 'assets/images/management/building-grain-silo-v1.webp',
      requiredTechnologyIds: ['S10'],
      minimumAreaHectares: 0.09,
      constructionCostCredits: 3400,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 19,
    ),
    FarmBuildingDefinition(
      id: 'cold_room',
      name: 'Soğuk oda',
      category: FarmBuildingCategory.storage,
      description:
          'Yumurta, süt, taze sebze ve meyve stoklarını soğukta tutar.',
      imageAsset: 'assets/images/management/building-cold-store-v1.webp',
      requiredTechnologyIds: ['S11'],
      minimumAreaHectares: 0.08,
      constructionCostCredits: 3600,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 32,
    ),
    FarmBuildingDefinition(
      id: 'controlled_store',
      name: 'Kontrollü atmosfer deposu',
      category: FarmBuildingCategory.storage,
      description:
          'Araştırılmış hassas ürünlerde raf ömrünü belirgin biçimde uzatır.',
      imageAsset: 'assets/images/management/building-controlled-store-v1.webp',
      requiredTechnologyIds: ['S06'],
      minimumAreaHectares: 0.12,
      constructionCostCredits: 5900,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 48,
    ),
    FarmBuildingDefinition(
      id: 'long_term_warehouse',
      name: 'Uzun dönemli depo',
      category: FarmBuildingCategory.storage,
      description:
          'Geniş ürün kapasitesi ve uzun süreli parti saklama alanı sağlar.',
      imageAsset: 'assets/images/management/building-large-warehouse-v1.webp',
      requiredTechnologyIds: ['S13'],
      minimumAreaHectares: 0.22,
      constructionCostCredits: 6200,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 39,
    ),
    FarmBuildingDefinition(
      id: 'poultry_coop',
      name: 'Tavuk kümesi',
      category: FarmBuildingCategory.livestock,
      description: 'Yem tedarikiyle tavuk ve yumurta üretim işletmesini kurar.',
      imageAsset: 'assets/images/management/building-poultry-coop-v1.webp',
      requiredTechnologyIds: ['LV01'],
      minimumAreaHectares: 0.08,
      constructionCostCredits: 3200,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 27,
    ),
    FarmBuildingDefinition(
      id: 'goat_barn',
      name: 'Keçi çiftliği',
      category: FarmBuildingCategory.livestock,
      description: 'Keçi sütü üretim alanı ve yemleme düzeni kurar.',
      imageAsset: 'assets/images/management/building-livestock-barn-v1.webp',
      requiredTechnologyIds: ['LV05'],
      minimumAreaHectares: 0.14,
      constructionCostCredits: 4200,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 34,
    ),
    FarmBuildingDefinition(
      id: 'apiary',
      name: 'Arı kovanlığı',
      category: FarmBuildingCategory.livestock,
      description: 'Bal ve balmumu üretimi için kovan sahası kurar.',
      imageAsset: 'assets/images/management/building-apiary-v1.webp',
      requiredTechnologyIds: ['LV06'],
      minimumAreaHectares: 0.02,
      constructionCostCredits: 1600,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 8,
    ),
    FarmBuildingDefinition(
      id: 'sheep_barn',
      name: 'Koyun çiftliği',
      category: FarmBuildingCategory.livestock,
      description:
          'Yün ve isteğe bağlı süt üretimi için küçükbaş işletmesi kurar.',
      imageAsset: 'assets/images/management/building-sheep-barn-v1.webp',
      requiredTechnologyIds: ['LV07'],
      minimumAreaHectares: 0.16,
      constructionCostCredits: 4500,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 36,
    ),
    FarmBuildingDefinition(
      id: 'dairy_barn',
      name: 'Süt sığırı çiftliği',
      category: FarmBuildingCategory.livestock,
      description: 'Süt üretimi ve hayvan yemlemesi için ahır işletmesi kurar.',
      imageAsset: 'assets/images/management/building-dairy-barn-v1.webp',
      requiredTechnologyIds: ['LV08'],
      minimumAreaHectares: 0.20,
      constructionCostCredits: 5900,
      constructionDuration: Duration(minutes: 4),
      dailyOperatingCostCredits: 48,
    ),
    FarmBuildingDefinition(
      id: 'feed_silo',
      name: 'Yem silosu',
      category: FarmBuildingCategory.livestock,
      description: 'Kuru ve silaj yemleri için ayrı stok alanı açar.',
      imageAsset: 'assets/images/management/building-feed-silo-v1.webp',
      requiredTechnologyIds: ['LV10'],
      minimumAreaHectares: 0.07,
      constructionCostCredits: 2800,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 16,
    ),
    FarmBuildingDefinition(
      id: 'feed_mill',
      name: 'Karma yem fabrikası',
      category: FarmBuildingCategory.livestock,
      description: 'Araştırılmış iki veya üç girdili yem tarifleri için üretim alanı açar.',
      imageAsset: 'assets/images/management/building-feed-mill-v1.webp',
      requiredTechnologyIds: ['LV11'],
      minimumAreaHectares: 0.14,
      constructionCostCredits: 4900,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 41,
    ),
    FarmBuildingDefinition(
      id: 'vet_clinic',
      name: 'Veteriner kliniği',
      category: FarmBuildingCategory.livestock,
      description: 'Hayvancılık işletmelerindeki veteriner vakalarının sahada çözülmesini sağlar.',
      imageAsset: 'assets/images/management/building-vet-clinic-v1.webp',
      requiredTechnologyIds: ['LV13'],
      minimumAreaHectares: 0.05,
      constructionCostCredits: 2600,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 22,
    ),
    FarmBuildingDefinition(
      id: 'transfer_hub',
      name: 'Bölgesel aktarma merkezi',
      category: FarmBuildingCategory.logistics,
      description:
          'Parsel, depo, fabrika ve pazar arasındaki yük aktarma noktasıdır.',
      imageAsset: 'assets/images/management/building-transfer-hub-v1.webp',
      requiredTechnologyIds: ['I02'],
      minimumAreaHectares: 0.16,
      constructionCostCredits: 3900,
      constructionDuration: Duration(minutes: 3),
      dailyOperatingCostCredits: 29,
    ),
    FarmBuildingDefinition(
      id: 'bulk_loading',
      name: 'Toplu yükleme noktası',
      category: FarmBuildingCategory.logistics,
      description: 'Tahıl silosu, fabrika ve depolardaki toplu araç yüklemelerini hızlandırır.',
      imageAsset: 'assets/images/management/building-bulk-loading-v1.webp',
      requiredTechnologyIds: ['L15'],
      minimumAreaHectares: 0.10,
      constructionCostCredits: 3100,
      constructionDuration: Duration(minutes: 2),
      dailyOperatingCostCredits: 20,
    ),
  ];

  static final Map<String, FarmBuildingDefinition> _byId = {
    for (final definition in all) definition.id: definition,
  };

  static FarmBuildingDefinition? byId(String id) => _byId[id];
}

class FarmBuildingInstance {
  const FarmBuildingInstance({
    required this.definitionId,
    required this.parcelId,
    required this.constructionStartedAt,
    required this.constructionCompletesAt,
    required this.lastOperatingChargeAt,
    this.pausedForOperatingCost = false,
  });

  final String definitionId;
  final String parcelId;
  final DateTime constructionStartedAt;
  final DateTime constructionCompletesAt;
  final DateTime lastOperatingChargeAt;
  final bool pausedForOperatingCost;

  bool isCompleteAt(DateTime now) =>
      !now.toUtc().isBefore(constructionCompletesAt.toUtc());

  bool isOperationalAt(DateTime now) =>
      isCompleteAt(now) && !pausedForOperatingCost;

  double constructionProgressAt(DateTime now) {
    final total = constructionCompletesAt
        .difference(constructionStartedAt)
        .inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = now.toUtc().difference(constructionStartedAt.toUtc());
    return (elapsed.inMilliseconds / total).clamp(0.0, 1.0).toDouble();
  }

  Duration remainingConstructionAt(DateTime now) {
    final remaining = constructionCompletesAt.toUtc().difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  FarmBuildingInstance copyWith({
    DateTime? lastOperatingChargeAt,
    bool? pausedForOperatingCost,
  }) => FarmBuildingInstance(
    definitionId: definitionId,
    parcelId: parcelId,
    constructionStartedAt: constructionStartedAt,
    constructionCompletesAt: constructionCompletesAt,
    lastOperatingChargeAt: lastOperatingChargeAt ?? this.lastOperatingChargeAt,
    pausedForOperatingCost:
        pausedForOperatingCost ?? this.pausedForOperatingCost,
  );

  Map<String, dynamic> toJson() => {
    'definitionId': definitionId,
    'parcelId': parcelId,
    'constructionStartedAt': constructionStartedAt.toUtc().toIso8601String(),
    'constructionCompletesAt': constructionCompletesAt
        .toUtc()
        .toIso8601String(),
    'lastOperatingChargeAt': lastOperatingChargeAt.toUtc().toIso8601String(),
    'pausedForOperatingCost': pausedForOperatingCost,
  };

  factory FarmBuildingInstance.fromJson(Map<String, dynamic> json) =>
      FarmBuildingInstance(
        definitionId: json['definitionId'] as String,
        parcelId: json['parcelId'] as String,
        constructionStartedAt: DateTime.parse(
          json['constructionStartedAt'] as String,
        ).toUtc(),
        constructionCompletesAt: DateTime.parse(
          json['constructionCompletesAt'] as String,
        ).toUtc(),
        lastOperatingChargeAt: DateTime.parse(
          json['lastOperatingChargeAt'] as String,
        ).toUtc(),
        pausedForOperatingCost:
            json['pausedForOperatingCost'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmBuildingInstance &&
          other.definitionId == definitionId &&
          other.parcelId == parcelId &&
          other.constructionStartedAt == constructionStartedAt &&
          other.constructionCompletesAt == constructionCompletesAt &&
          other.lastOperatingChargeAt == lastOperatingChargeAt &&
          other.pausedForOperatingCost == pausedForOperatingCost;

  @override
  int get hashCode => Object.hash(
    definitionId,
    parcelId,
    constructionStartedAt,
    constructionCompletesAt,
    lastOperatingChargeAt,
    pausedForOperatingCost,
  );
}
