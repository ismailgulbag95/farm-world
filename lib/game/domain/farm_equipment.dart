/// Equipment, operation timers and opening tutorial vocabulary for the farm.
///
/// All names and visual assets in this catalogue are original to Farm World.
library;

import 'dart:math' as math;

enum FarmOperation { prepare, fertilize, sow, harvest, bale }

class FarmEquipmentShopCategory {
  const FarmEquipmentShopCategory({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.operation,
    required this.iconAsset,
  });

  final String id;
  final String label;
  final String subtitle;
  final FarmOperation? operation;
  final String iconAsset;
}

const farmEquipmentShopCategories = <FarmEquipmentShopCategory>[
  FarmEquipmentShopCategory(
    id: 'tractors',
    label: 'Traktörler',
    subtitle: 'Kompakt, orta sınıf ve ağır hizmet çekiciler',
    operation: null,
    iconAsset: 'assets/images/equipment/tractor_starter.webp',
  ),
  FarmEquipmentShopCategory(
    id: 'soil',
    label: 'Toprak işleme',
    subtitle: 'Pulluk, kültivatör ve dipkazanlar',
    operation: FarmOperation.prepare,
    iconAsset: 'assets/images/equipment/prep_starter.webp',
  ),
  FarmEquipmentShopCategory(
    id: 'seeding',
    label: 'Ekim makineleri',
    subtitle: 'Tahıl mibzeri, sıra ekici ve havalı ekim',
    operation: FarmOperation.sow,
    iconAsset: 'assets/images/equipment/sow_starter.webp',
  ),
  FarmEquipmentShopCategory(
    id: 'fertilizer',
    label: 'Gübreleme',
    subtitle: 'Diskli, hassas ve yüksek kapasiteli serpme',
    operation: FarmOperation.fertilize,
    iconAsset: 'assets/images/equipment/fertilize_starter.webp',
  ),
  FarmEquipmentShopCategory(
    id: 'harvesting',
    label: 'Tahıl hasadı',
    subtitle: 'Kompakt biçerdöverlerden yüksek kapasiteli harmana',
    operation: FarmOperation.harvest,
    iconAsset: 'assets/images/equipment/harvest_starter.webp',
  ),
  FarmEquipmentShopCategory(
    id: 'grass',
    label: 'Çayır ve balya',
    subtitle: 'Biçme, toplama ve yuvarlak ya da kare balya',
    operation: FarmOperation.bale,
    iconAsset: 'assets/images/equipment/bale_starter.webp',
  ),
];

extension FarmOperationPresentation on FarmOperation {
  String get label => switch (this) {
    FarmOperation.prepare => 'Tarla hazırlığı',
    FarmOperation.fertilize => 'Gübreleme',
    FarmOperation.sow => 'Ekim',
    FarmOperation.harvest => 'Hasat',
    FarmOperation.bale => 'Balyalama',
  };

  String get iconAsset => switch (this) {
    FarmOperation.prepare => 'assets/images/equipment/field_prep.png',
    FarmOperation.fertilize => 'assets/images/equipment/fertilizer.png',
    FarmOperation.sow => 'assets/images/equipment/seeder.png',
    FarmOperation.harvest => 'assets/images/equipment/combine.png',
    FarmOperation.bale => 'assets/images/equipment/baler.png',
  };

  Duration get standardDuration => switch (this) {
    FarmOperation.prepare => const Duration(minutes: 2, seconds: 30),
    FarmOperation.fertilize => const Duration(minutes: 2),
    FarmOperation.sow => const Duration(minutes: 3),
    FarmOperation.harvest => const Duration(minutes: 4),
    FarmOperation.bale => const Duration(minutes: 3),
  };
}

enum FarmTutorialStep {
  story,
  prepare,
  fertilize,
  sow,
  growth,
  harvest,
  warehouse,
  deliveryRoute,
  delivery,
  shop,
  management,
  complete,
}

class FarmEquipment {
  const FarmEquipment({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.operation,
    required this.purchasePrice,
    required this.timeMultiplier,
    required this.description,
    required this.tier,
    this.isTractor = false,
    this.subcategory = '',
    this.horsepower = 0,
    this.workingWidthMeters = 0,
    this.capacity = 0,
    this.capacityUnit = '',
  });

  final String id;
  final String name;
  final String manufacturer;
  final FarmOperation operation;
  final int purchasePrice;
  final double timeMultiplier;
  final String description;
  final int tier;
  final bool isTractor;
  final String subcategory;
  final int horsepower;
  final double workingWidthMeters;
  final double capacity;
  final String capacityUnit;

  /// Research permission for optional shop equipment. The starter kit remains
  /// usable immediately; research gates later purchases inside the domain too.
  String? get requiredResearchId {
    if (tier <= 1) return null;
    return operation == FarmOperation.harvest ? 'H06' : 'H03';
  }

  /// Tractor torque is separate from engine horsepower and implement capacity.
  int get torqueCapacityNm => isTractor
      ? switch (tier) {
          <= 1 => 600,
          2 => 820,
          3 => 1080,
          4 => 1400,
          5 => 1800,
          6 => 2300,
          7 => 2900,
          _ => 3600,
        }
      : 0;

  /// Implements in each tier need a stronger tractor as their size increases.
  int get requiredTractorTorqueNm => !requiresTractor
      ? 0
      : switch (tier) {
          <= 1 => 420,
          2 => 650,
          3 => 880,
          4 => 1120,
          5 => 1450,
          6 => 1850,
          7 => 2350,
          _ => 3000,
        };

  /// Combines are self-propelled; all other tools in the shop are towed.
  bool get requiresTractor => !isTractor && operation != FarmOperation.harvest;

  bool get isSelfPropelled => !isTractor && operation == FarmOperation.harvest;

  /// Top speed is a vehicle property for tractors and combines.
  double get maxSpeedKph => isTractor
      ? switch (tier) {
          <= 1 => 32,
          2 => 36,
          3 => 40,
          4 => 44,
          5 => 48,
          6 => 52,
          7 => 56,
          _ => 60,
        }
      : isSelfPropelled
      ? switch (tier) {
          <= 1 => 18,
          2 => 20,
          3 => 22,
          4 => 24,
          5 => 26,
          6 => 28,
          7 => 30,
          _ => 32,
        }
      : 0;

  /// Rated field speed for towed equipment; combines use their own top speed.
  double get workingSpeedKph => isSelfPropelled
      ? maxSpeedKph
      : switch (tier) {
          <= 1 => 6,
          2 => 7,
          3 => 8,
          4 => 9,
          5 => 10,
          6 => 11,
          7 => 12,
          _ => 13,
        };

  double get catalogueEfficiencyBonus =>
      math.pow(1 / math.max(0.25, timeMultiplier), 0.2).toDouble();

  double get workRateRating =>
      (isTractor ? maxSpeedKph : displayWidth * workingSpeedKph) *
      catalogueEfficiencyBonus;

  bool canOperateWithTractor(FarmEquipment? tractor) =>
      !requiresTractor ||
      (tractor?.isTractor == true &&
          tractor!.torqueCapacityNm >= requiredTractorTorqueNm);

  String get shopCategoryId => isTractor
      ? 'tractors'
      : switch (operation) {
          FarmOperation.prepare => 'soil',
          FarmOperation.fertilize => 'fertilizer',
          FarmOperation.sow => 'seeding',
          FarmOperation.harvest => 'harvesting',
          FarmOperation.bale => 'grass',
        };

  String get slotKey => isTractor ? 'tractor' : operation.name;

  String get imageAsset => 'assets/images/equipment/$id.webp';

  int get displayHorsepower => horsepower > 0
      ? horsepower
      : switch (tier) {
          <= 1 => 75,
          2 => 120,
          3 => 180,
          _ => 240 + (tier - 4) * 50,
        };

  double get displayWidth => workingWidthMeters > 0
      ? workingWidthMeters
      : switch (tier) {
          <= 1 => 3.0,
          2 => 5.0,
          3 => 8.0,
          _ => 9.0 + (tier - 4) * 1.5,
        };

  String get capacityText {
    if (capacity > 0 && capacityUnit.isNotEmpty) {
      final value = capacity == capacity.roundToDouble()
          ? capacity.toStringAsFixed(0)
          : capacity.toStringAsFixed(1);
      return '$value $capacityUnit';
    }
    return isTractor ? '4×4 çekiş' : 'Hızlı bağlantı';
  }

  Duration durationFor(
    int areaSquareMeters, {
    bool tutorialFast = false,
    FarmEquipment? tractor,
  }) {
    if (tutorialFast) return const Duration(seconds: 3);
    final areaScale = math.sqrt(areaSquareMeters / 1000).clamp(1.0, 3.0);
    final speedBaseline = isSelfPropelled ? 18.0 : 6.0;
    final tractorSpeedFactor = requiresTractor
        ? (tractor?.maxSpeedKph ??
                  FarmEquipmentCatalog.starterTractorSpeedKph) /
              FarmEquipmentCatalog.starterTractorSpeedKph *
              (tractor?.catalogueEfficiencyBonus ?? 1)
        : 1.0;
    final rateFactor =
        math.sqrt(
          (displayWidth / 3.0) *
              (workingSpeedKph / speedBaseline) *
              tractorSpeedFactor,
        ) *
        catalogueEfficiencyBonus;
    final seconds =
        (operation.standardDuration.inSeconds * areaScale / rateFactor)
            .round()
            .clamp(30, 60 * 12);
    return Duration(seconds: seconds);
  }
}

class FarmEquipmentCatalog {
  FarmEquipmentCatalog._();

  static const double starterTractorSpeedKph = 32;

  static final List<FarmEquipment> all = [
    FarmEquipment(
      id: 'prep_starter',
      name: 'Kıyı 18 Tarla Seti',
      manufacturer: 'Kıyı Makina',
      operation: FarmOperation.prepare,
      purchasePrice: 900,
      timeMultiplier: 1,
      description: 'Başlangıç traktörüyle kullanılan üç ayaklı kültivatör; tahıl tarlasını ekime hazırlar. Traktör ayrı ekipmandır.',
      tier: 1,
    ),
    FarmEquipment(
      id: 'prep_fieldmaster',
      name: 'Yamaç 42 Derin Sürüm',
      manufacturer: 'Yamaç Tarım',
      operation: FarmOperation.prepare,
      purchasePrice: 1450,
      timeMultiplier: 0.74,
      description:
          'Geniş kültivatör ayakları aynı geçişte daha fazla alan işler.',
      tier: 2,
    ),
    FarmEquipment(
      id: 'prep_precision',
      name: 'Ufuk P70 Kombi Set',
      manufacturer: 'Ufuk Atölye',
      operation: FarmOperation.prepare,
      purchasePrice: 2900,
      timeMultiplier: 0.55,
      description: 'Hassas derinlik ayarı ve katlanır şasiyle büyük tarlalara göre tasarlandı.',
      tier: 3,
    ),
    FarmEquipment(
      id: 'sow_starter',
      name: 'Filiz 4 Sıra Mibzer',
      manufacturer: 'Filiz Ekipman',
      operation: FarmOperation.sow,
      purchasePrice: 800,
      timeMultiplier: 1,
      description:
          'Buğday ve mısır için ayarlanabilir dört sıralı başlangıç mibzeri.',
      tier: 1,
    ),
    FarmEquipment(
      id: 'sow_eight',
      name: 'Ekin 8 Hassas Mibzer',
      manufacturer: 'Ekin Atölyeleri',
      operation: FarmOperation.sow,
      purchasePrice: 1100,
      timeMultiplier: 0.72,
      description: 'Sekiz sıra ekim ve daha tutarlı tohum aralığıyla iş süresini azaltır.',
      tier: 2,
    ),
    FarmEquipment(
      id: 'sow_air',
      name: 'Gökova 12 Havalı Mibzer',
      manufacturer: 'Gökova Makina',
      operation: FarmOperation.sow,
      purchasePrice: 2450,
      timeMultiplier: 0.54,
      description:
          'Büyük işletmeler için yüksek kapasiteli havalı ekim sistemi.',
      tier: 3,
    ),
    FarmEquipment(
      id: 'fertilize_starter',
      name: 'Toprakış 500 Serpici',
      manufacturer: 'Toprakış Tarım',
      operation: FarmOperation.fertilize,
      purchasePrice: 650,
      timeMultiplier: 1,
      description: 'Çift diskli temel gübre serpici, başlangıç tarlasının bakımını yapar.',
      tier: 1,
    ),
    FarmEquipment(
      id: 'fertilize_verim',
      name: 'Verim 1200 Çift Disk',
      manufacturer: 'Verim Makina',
      operation: FarmOperation.fertilize,
      purchasePrice: 850,
      timeMultiplier: 0.70,
      description: 'Geniş serpme tablası gübreleme geçişlerini azaltır.',
      tier: 2,
    ),
    FarmEquipment(
      id: 'fertilize_poyraz',
      name: 'Poyraz 2400 Akıllı Serpici',
      manufacturer: 'Poyraz Ekipman',
      operation: FarmOperation.fertilize,
      purchasePrice: 1950,
      timeMultiplier: 0.52,
      description: 'Bölgesel doz kontrolüyle büyük alanlarda hızlı ve dengeli gübreleme.',
      tier: 3,
    ),
    FarmEquipment(
      id: 'harvest_starter',
      name: 'Harman Mini 2 Biçerdöver',
      manufacturer: 'Harman Yöre',
      operation: FarmOperation.harvest,
      purchasePrice: 1900,
      timeMultiplier: 1,
      description: 'Buğday ve mısır hasadı için kompakt başlangıç biçerdöveri.',
      tier: 1,
    ),
    FarmEquipment(
      id: 'harvest_pro',
      name: 'Berek 6 Tahıl Biçerdöveri',
      manufacturer: 'Berek Makina',
      operation: FarmOperation.harvest,
      purchasePrice: 2400,
      timeMultiplier: 0.73,
      description:
          'Daha geniş tabla ve büyük dane deposuyla hasat süresini kısaltır.',
      tier: 2,
    ),
    FarmEquipment(
      id: 'harvest_hybrid',
      name: 'Günova 9 Hibrit Hasatçı',
      manufacturer: 'Günova Tarım',
      operation: FarmOperation.harvest,
      purchasePrice: 5400,
      timeMultiplier: 0.52,
      description: 'Yüksek kapasiteli harman tamburu ve hızlı boşaltma düzeni.',
      tier: 3,
    ),
    FarmEquipment(
      id: 'bale_starter',
      name: 'Samanlık 80 Yuvarlak Pres',
      manufacturer: 'Samanlık Ekipman',
      operation: FarmOperation.bale,
      purchasePrice: 700,
      timeMultiplier: 1,
      description:
          'Ot biçme, toplama ve yuvarlak balya sıkıştırmayı tek geçişte yapar.',
      tier: 1,
    ),
    FarmEquipment(
      id: 'bale_rotor',
      name: 'Kırpık Roto 140 Pres',
      manufacturer: 'Kırpık Tarım',
      operation: FarmOperation.bale,
      purchasePrice: 1000,
      timeMultiplier: 0.72,
      description: 'Daha geniş toplama ağzı ve hızlı bağlama düzeni.',
      tier: 2,
    ),
    FarmEquipment(
      id: 'bale_quad',
      name: 'Yayla 4X Balya Hattı',
      manufacturer: 'Yayla Makina',
      operation: FarmOperation.bale,
      purchasePrice: 2300,
      timeMultiplier: 0.53,
      description:
          'Yüksek yoğunluklu balyaları art arda çıkaran profesyonel hat.',
      tier: 3,
    ),
    ..._models(FarmOperation.prepare, _tractorModels, isTractor: true),
    ..._models(FarmOperation.prepare, _soilModels),
    ..._models(FarmOperation.sow, _seedingModels),
    ..._models(FarmOperation.fertilize, _fertilizerModels),
    ..._models(FarmOperation.harvest, _harvestModels),
    ..._models(FarmOperation.bale, _grassModels),
  ];

  static List<FarmEquipment> get starterSet => all
      .where((item) => item.tier == 1 && !item.isTractor)
      .toList(growable: false);

  static FarmEquipment? get starterTractor {
    for (final item in all) {
      if (item.isTractor && item.tier == 1) return item;
    }
    return null;
  }

  static List<FarmEquipment> forShopCategory(String categoryId) => all
      .where((item) => item.shopCategoryId == categoryId)
      .toList(growable: false);

  static FarmEquipment? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  static FarmEquipment? forOperation(FarmOperation operation, String id) {
    final item = byId(id);
    return item != null && !item.isTractor && item.operation == operation
        ? item
        : null;
  }

  static FarmTutorialStep tutorialStepFromJson(Object? value) {
    if (value is String) {
      for (final step in FarmTutorialStep.values) {
        if (step.name == value) return step;
      }
    }
    return FarmTutorialStep.story;
  }
}

class _ShopModel {
  const _ShopModel(
    this.id,
    this.name,
    this.manufacturer,
    this.purchasePrice,
    this.timeMultiplier,
    this.description,
    this.tier, {
    this.subcategory = '',
    this.horsepower = 0,
    this.width = 0,
    this.capacity = 0,
    this.capacityUnit = '',
  });

  final String id;
  final String name;
  final String manufacturer;
  final int purchasePrice;
  final double timeMultiplier;
  final String description;
  final int tier;
  final String subcategory;
  final int horsepower;
  final double width;
  final double capacity;
  final String capacityUnit;
}

List<FarmEquipment> _models(
  FarmOperation operation,
  List<_ShopModel> models, {
  bool isTractor = false,
}) => [
  for (final model in models)
    FarmEquipment(
      id: model.id,
      name: model.name,
      manufacturer: model.manufacturer,
      operation: operation,
      purchasePrice: model.purchasePrice,
      timeMultiplier: model.timeMultiplier,
      description: model.description,
      tier: model.tier,
      isTractor: isTractor,
      subcategory: model.subcategory,
      horsepower: model.horsepower,
      workingWidthMeters: model.width,
      capacity: model.capacity,
      capacityUnit: model.capacityUnit,
    ),
];

const _tractorModels = <_ShopModel>[
  _ShopModel(
    'tractor_starter',
    'Kıyı 18 Çiftlik Traktörü',
    'Kıyı Makina',
    6500,
    1,
    'Aile çiftliğinden kalan, bütün başlangıç ekipmanlarıyla uyumlu 4×4 traktör.',
    1,
    subcategory: 'Kompakt',
    horsepower: 90,
    width: 2.4,
    capacity: 115,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_ova_90',
    'Ova 90 Kompakt',
    'OvaForm',
    7800,
    0.96,
    'Dar parsellerde çevik; temel tarla işlerinde yakıt ve süre tasarrufu sağlar.',
    2,
    subcategory: 'Kompakt',
    horsepower: 105,
    width: 2.5,
    capacity: 140,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_izlek_125',
    'İzlek 125 VitesPro',
    'İzlek Motor',
    14900,
    0.92,
    'Orta güç sınıfı, ekim ve gübre ekipmanlarıyla dengeli çalışma sunar.',
    3,
    subcategory: 'Orta sınıf',
    horsepower: 125,
    width: 2.8,
    capacity: 180,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_yamac_180',
    'Yamaç 180 Çekiş+',
    'Yamaç Tarım',
    26800,
    0.88,
    'Geniş ekipmanları daha yüksek tempoda çeker; ağır toprak işlerine uygundur.',
    4,
    subcategory: 'Orta sınıf',
    horsepower: 180,
    width: 3.0,
    capacity: 240,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_verim_240',
    'Verim 240 Tarlacı',
    'Verim Makina',
    41900,
    0.84,
    'Yüksek çekiş gücüyle büyük parsellerin iş süresini düşürür.',
    5,
    subcategory: 'Ağır hizmet',
    horsepower: 240,
    width: 3.2,
    capacity: 310,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_poyraz_320',
    'Poyraz 320 Çift Turbo',
    'Poyraz Ekipman',
    62900,
    0.80,
    'Yüksek tork ve büyük depo ile uzun vardiyalarda kesintisiz çalışır.',
    6,
    subcategory: 'Ağır hizmet',
    horsepower: 320,
    width: 3.5,
    capacity: 390,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_gunova_430',
    'Günova 430 AraziPro',
    'Günova Tarım',
    89900,
    0.76,
    'Gelişmiş şanzıman her tarla operasyonuna ek hız kazandırır.',
    7,
    subcategory: 'Ağır hizmet',
    horsepower: 430,
    width: 3.8,
    capacity: 520,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'tractor_ufuk_560',
    'Ufuk 560 Büyük Tarla',
    'Ufuk Atölye',
    128000,
    0.72,
    'Filonun en güçlü çekicisi; geniş tarlalarda ekipman geçişlerini hızlandırır.',
    8,
    subcategory: 'Ağır hizmet',
    horsepower: 560,
    width: 4.1,
    capacity: 650,
    capacityUnit: 'L depo',
  ),
];

const _soilModels = <_ShopModel>[
  _ShopModel(
    'prep_ova_p16',
    'OvaForm P16 Döner Pulluk',
    'OvaForm',
    4200,
    0.48,
    'Dört gövdeli pulluk, sıkışmış toprağı derin sürümle hazırlar.',
    4,
    subcategory: 'Pulluk',
    horsepower: 110,
    width: 9.0,
  ),
  _ShopModel(
    'prep_izlek_c9',
    'İzlek C9 Katlanır Kültivatör',
    'İzlek Ekipman',
    5600,
    0.43,
    'Katlanır dokuz ayaklı şasi tek geçişte daha fazla sıra işler.',
    5,
    subcategory: 'Kültivatör',
    horsepower: 145,
    width: 11.0,
  ),
  _ShopModel(
    'prep_toprakis_d7',
    'Toprakış D7 Derin Dipkazan',
    'Toprakış Tarım',
    7200,
    0.39,
    'Derin çatalları taban taşını kırarak yeni ekim sezonuna alan açar.',
    6,
    subcategory: 'Dipkazan',
    horsepower: 190,
    width: 13.0,
  ),
  _ShopModel(
    'prep_yayla_x12',
    'Yayla X12 Diskli Tırmık',
    'Yayla Makina',
    9800,
    0.34,
    'Geniş disk takımı ve hidrolik katlama büyük tarlalarda zaman kazandırır.',
    7,
    subcategory: 'Diskli tırmık',
    horsepower: 250,
    width: 15.0,
  ),
  _ShopModel(
    'prep_verim_16m',
    'Verim 16M Kombine Tarla Hazırlayıcı',
    'Verim Makina',
    13900,
    0.29,
    'Tesviye merdanesi ve kültivatör ayakları tek geniş geçişte çalışır.',
    8,
    subcategory: 'Kombine hazırlık',
    horsepower: 340,
    width: 17.0,
  ),
];

const _seedingModels = <_ShopModel>[
  _ShopModel(
    'sow_ekin_12',
    'EkinAt 12 Sıra Tahıl Mibzeri',
    'EkinAt',
    3900,
    0.48,
    'Buğday ve arpa için pnömatik dağıtım, geniş sıra düzeni.',
    4,
    subcategory: 'Tahıl mibzeri',
    horsepower: 125,
    width: 9.0,
    capacity: 1650,
    capacityUnit: 'L tohum',
  ),
  _ShopModel(
    'sow_filizat_8',
    'Filizat 8H Hassas Sıra Ekici',
    'Filizat Tarım',
    5500,
    0.43,
    'Mısır için hassas sıra aralığı ve tek dane bırakma sistemi.',
    5,
    subcategory: 'Sıra ekici',
    horsepower: 155,
    width: 10.5,
    capacity: 1200,
    capacityUnit: 'L tohum',
  ),
  _ShopModel(
    'sow_gokova_air18',
    'Gökova Air 18 Havalı Ekim',
    'Gökova Makina',
    7600,
    0.38,
    'Merkezi tohum tankı ve hava hattı, orta ölçekli ekimi hızlandırır.',
    6,
    subcategory: 'Havalı mibzer',
    horsepower: 210,
    width: 12.5,
    capacity: 2600,
    capacityUnit: 'L tohum',
  ),
  _ShopModel(
    'sow_ova_24',
    'OvaForm 24 Çift Tanklı Kombi',
    'OvaForm',
    11800,
    0.33,
    'Tohum ve mikrogranül haznesi aynı geçişte besleme yapar.',
    7,
    subcategory: 'Kombi mibzer',
    horsepower: 310,
    width: 15.0,
    capacity: 4200,
    capacityUnit: 'L tohum',
  ),
  _ShopModel(
    'sow_yamac_precision',
    'Yamaç Precision 36 Ekim Treni',
    'Yamaç Tarım',
    17400,
    0.28,
    'Uydu kontrollü sıra kesme ve geniş tohum deposuyla büyük tarla çözümü.',
    8,
    subcategory: 'Hassas ekim treni',
    horsepower: 420,
    width: 18.0,
    capacity: 6800,
    capacityUnit: 'L tohum',
  ),
];

const _fertilizerModels = <_ShopModel>[
  _ShopModel(
    'fertilize_ova_1600',
    'OvaForm 1600 Çift Disk',
    'OvaForm',
    3200,
    0.48,
    'Dengeli çift disk ve kapalı hazneyle kuru gübre uygulaması.',
    4,
    subcategory: 'Diskli serpici',
    horsepower: 95,
    width: 18.0,
    capacity: 1600,
    capacityUnit: 'L gübre',
  ),
  _ShopModel(
    'fertilize_duruserp_2400',
    'DuruSerp 2400 Hassas',
    'DuruSerp',
    4600,
    0.43,
    'Bölgesel doz ayarı gübreyi parsel ihtiyacına göre dağıtır.',
    5,
    subcategory: 'Hassas serpici',
    horsepower: 120,
    width: 24.0,
    capacity: 2400,
    capacityUnit: 'L gübre',
  ),
  _ShopModel(
    'fertilize_poyraz_4200',
    'Poyraz 4200 Rüzgâr Korumalı',
    'Poyraz Ekipman',
    6800,
    0.38,
    'Geniş dağıtım tablası ve rüzgâr siperi daha hızlı uygulama sağlar.',
    6,
    subcategory: 'Geniş serpici',
    horsepower: 170,
    width: 32.0,
    capacity: 4200,
    capacityUnit: 'L gübre',
  ),
  _ShopModel(
    'fertilize_verim_6000',
    'Verim 6000 Akıllı Doz',
    'Verim Makina',
    9500,
    0.33,
    'Bölüm kontrollü dağıtım; boş alanlarda serpme yapmadan geçer.',
    7,
    subcategory: 'Akıllı doz',
    horsepower: 235,
    width: 36.0,
    capacity: 6000,
    capacityUnit: 'L gübre',
  ),
  _ShopModel(
    'fertilize_gunova_9000',
    'Günova 9000 Tarla Servisi',
    'Günova Tarım',
    13200,
    0.28,
    'En büyük alanlarda daha az dolum molasıyla yüksek tempo.',
    8,
    subcategory: 'Yüksek kapasiteli',
    horsepower: 330,
    width: 48.0,
    capacity: 9000,
    capacityUnit: 'L gübre',
  ),
];

const _harvestModels = <_ShopModel>[
  _ShopModel(
    'harvest_harman_4x',
    'Harman 4X Tahıl Biçerdöveri',
    'Harman Yöre',
    6900,
    0.48,
    'Kompakt dört sarsaklı harman sistemi; buğday ve mısır hasadına uygun.',
    4,
    subcategory: 'Kompakt biçerdöver',
    horsepower: 190,
    width: 9.0,
    capacity: 6500,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'harvest_berek_7x',
    'Berek 7X HarmanPlus',
    'Berek Makina',
    11200,
    0.43,
    'Daha geniş dane tablası ve yedi sarsakla orta ölçekli hasat.',
    5,
    subcategory: 'Tahıl biçerdöveri',
    horsepower: 280,
    width: 10.5,
    capacity: 9200,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'harvest_yayla_9x',
    'Yayla 9X Dane Akışı',
    'Yayla Makina',
    16800,
    0.38,
    'Yüksek verimli tambur ve hızlı boşaltma ile uzun biçim vardiyası.',
    6,
    subcategory: 'Yüksek kapasiteli',
    horsepower: 370,
    width: 12.0,
    capacity: 12500,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'harvest_gunova_12x',
    'Günova 12X Çift Tambur',
    'Günova Tarım',
    24900,
    0.33,
    'Çift ayırıcı rotor ve geniş tabla geniş arazide hasat süresini azaltır.',
    7,
    subcategory: 'Çift tamburlu',
    horsepower: 520,
    width: 13.5,
    capacity: 16000,
    capacityUnit: 'L depo',
  ),
  _ShopModel(
    'harvest_ufuk_16x',
    'Ufuk 16X Büyük Harman',
    'Ufuk Atölye',
    36500,
    0.28,
    'Amiral gemisi harman hattı; büyük parsellerde en yüksek işlem hızı.',
    8,
    subcategory: 'Büyük harman',
    horsepower: 720,
    width: 16.0,
    capacity: 22000,
    capacityUnit: 'L depo',
  ),
];

const _grassModels = <_ShopModel>[
  _ShopModel(
    'bale_yelken_r120',
    'Yelken R120 Yuvarlak Pres',
    'Yelken Balya',
    3100,
    0.48,
    'Biçme ve toplama düzeniyle çayır otunu standart yuvarlak balyaya çevirir.',
    4,
    subcategory: 'Yuvarlak balya',
    horsepower: 105,
    width: 9.0,
    capacity: 18,
    capacityUnit: 'balya/saat',
  ),
  _ShopModel(
    'bale_samanlik_xl',
    'Samanlık XL Ot Hattı',
    'Samanlık Ekipman',
    4600,
    0.43,
    'Geniş biçme tablası ve hızlı toplama rotoru tarladaki geçişleri azaltır.',
    5,
    subcategory: 'Biçme ve toplama',
    horsepower: 145,
    width: 10.5,
    capacity: 22,
    capacityUnit: 'balya/saat',
  ),
  _ShopModel(
    'bale_kirpiksq_90',
    'Kırpık SQ90 Kare Pres',
    'Kırpık Tarım',
    6500,
    0.38,
    'Kare balya bağlama kafası düzenli istif ve hızlı balyalama sunar.',
    6,
    subcategory: 'Kare balya',
    horsepower: 185,
    width: 12.0,
    capacity: 30,
    capacityUnit: 'balya/saat',
  ),
  _ShopModel(
    'bale_ova_1500',
    'OvaForm 1500 Silaj Presi',
    'OvaForm',
    8900,
    0.33,
    'Yüksek yoğunluklu silaj balyası için kesici ve sarıcı entegre edilmiştir.',
    7,
    subcategory: 'Silaj balyası',
    horsepower: 250,
    width: 13.5,
    capacity: 38,
    capacityUnit: 'balya/saat',
  ),
  _ShopModel(
    'bale_yamac_24',
    'Yamaç 24 Pro Balya Treni',
    'Yamaç Tarım',
    12400,
    0.28,
    'Otomatik bağlama ve aralıksız besleme ile geniş çayır işlerine göre.',
    8,
    subcategory: 'Profesyonel balya',
    horsepower: 340,
    width: 15.0,
    capacity: 48,
    capacityUnit: 'balya/saat',
  ),
];

class FarmOperationJob {
  const FarmOperationJob({
    required this.operation,
    required this.equipmentId,
    required this.startedAt,
    required this.completesAt,
    this.cropId,
    this.harvestValue = 0,
    this.outputQuantity = 0,
    this.isFullHarvest = false,
    this.soilAfter = 0,
    this.baleCount = 0,
    this.tutorialFast = false,
    this.tractorEquipmentId,
  });

  final FarmOperation operation;
  final String equipmentId;
  final DateTime startedAt;
  final DateTime completesAt;
  final String? cropId;
  final int harvestValue;
  final int outputQuantity;
  final bool isFullHarvest;
  final int soilAfter;
  final int baleCount;
  final bool tutorialFast;
  final String? tractorEquipmentId;

  Duration get remaining => completesAt.difference(DateTime.now().toUtc());

  double progressAt(DateTime now) {
    final total = completesAt.difference(startedAt).inMicroseconds;
    if (total <= 0) return 1;
    return (now.toUtc().difference(startedAt).inMicroseconds / total).clamp(
      0.0,
      1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'operation': operation.name,
    'equipmentId': equipmentId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completesAt': completesAt.toUtc().toIso8601String(),
    if (cropId != null) 'cropId': cropId,
    'harvestValue': harvestValue,
    'outputQuantity': outputQuantity,
    'isFullHarvest': isFullHarvest,
    'soilAfter': soilAfter,
    'baleCount': baleCount,
    'tutorialFast': tutorialFast,
    if (tractorEquipmentId != null) 'tractorEquipmentId': tractorEquipmentId,
  };

  factory FarmOperationJob.fromJson(Map<String, dynamic> json) =>
      FarmOperationJob(
        operation: FarmOperation.values.byName(json['operation'] as String),
        equipmentId: json['equipmentId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        completesAt: DateTime.parse(json['completesAt'] as String).toUtc(),
        cropId: json['cropId'] as String?,
        harvestValue: json['harvestValue'] as int? ?? 0,
        outputQuantity: json['outputQuantity'] as int? ?? 0,
        isFullHarvest: json['isFullHarvest'] as bool? ?? false,
        soilAfter: json['soilAfter'] as int? ?? 0,
        baleCount: json['baleCount'] as int? ?? 0,
        tutorialFast: json['tutorialFast'] as bool? ?? false,
        tractorEquipmentId: json['tractorEquipmentId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmOperationJob &&
          other.operation == operation &&
          other.equipmentId == equipmentId &&
          other.startedAt == startedAt &&
          other.completesAt == completesAt &&
          other.cropId == cropId &&
          other.harvestValue == harvestValue &&
          other.outputQuantity == outputQuantity &&
          other.isFullHarvest == isFullHarvest &&
          other.soilAfter == soilAfter &&
          other.baleCount == baleCount &&
          other.tutorialFast == tutorialFast &&
          other.tractorEquipmentId == tractorEquipmentId;

  @override
  int get hashCode => Object.hash(
    operation,
    equipmentId,
    startedAt,
    completesAt,
    cropId,
    harvestValue,
    outputQuantity,
    isFullHarvest,
    soilAfter,
    baleCount,
    tutorialFast,
    tractorEquipmentId,
  );
}
