import 'dart:math';
import 'dart:ui' show Offset, Rect;

/// World-map scale. A chunk is generated independently, so camera travel does
/// not depend on a preallocated world rectangle.
const double farmWorldChunkSize = 640;

enum WorldCropType { grain, oilseed, vegetable, pasture }

enum WorldPointOfInterestType { water, village, mill, timberYard }

enum WorldMapRoadType { arterial, secondary, dirt, trail }

class WorldMapPoint {
  const WorldMapPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(WorldMapPoint other) =>
      sqrt(pow(other.x - x, 2) + pow(other.y - y, 2));
}

class WorldMapParcel {
  const WorldMapParcel({
    required this.id,
    required this.name,
    required this.center,
    required this.width,
    required this.height,
    required this.price,
    required this.fertility,
    required this.cropType,
    this.isHome = false,
    this.shape = const [],
  });

  final String id;
  final String name;
  final WorldMapPoint center;
  final double width;
  final double height;
  final int price;
  final int fertility;
  final WorldCropType cropType;
  final bool isHome;

  /// Normalized, center-relative polygon vertices. Empty means a rectangle.
  final List<WorldMapPoint> shape;

  List<WorldMapPoint> get worldVertices {
    final normalized = shape.isEmpty
        ? const [
            WorldMapPoint(-0.5, -0.5),
            WorldMapPoint(0.5, -0.5),
            WorldMapPoint(0.5, 0.5),
            WorldMapPoint(-0.5, 0.5),
          ]
        : shape;
    return [
      for (final point in normalized)
        WorldMapPoint(center.x + point.x * width, center.y + point.y * height),
    ];
  }

  /// Measures the normalized parcel polygon using its metre dimensions.
  /// World-map coordinates are metres, so the normalized polygon's area is
  /// scaled by width × height, then converted from m² to hectares.
  static double measureAreaHectares({
    required double width,
    required double height,
    required List<WorldMapPoint> shape,
  }) {
    final vertices = shape.isEmpty
        ? const [
            WorldMapPoint(-0.5, -0.5),
            WorldMapPoint(0.5, -0.5),
            WorldMapPoint(0.5, 0.5),
            WorldMapPoint(-0.5, 0.5),
          ]
        : shape;
    if (vertices.length < 3) return 0;

    var doubleArea = 0.0;
    for (var index = 0; index < vertices.length; index++) {
      final current = vertices[index];
      final next = vertices[(index + 1) % vertices.length];
      doubleArea += current.x * next.y - next.x * current.y;
    }
    return doubleArea.abs() * width.abs() * height.abs() / 20000;
  }

  double get areaHectares =>
      measureAreaHectares(width: width, height: height, shape: shape);

  bool contains(WorldMapPoint point, {double padding = 0}) {
    final vertices = worldVertices;
    var inside = false;
    for (
      var index = 0, previous = vertices.length - 1;
      index < vertices.length;
      previous = index++
    ) {
      final a = vertices[index];
      final b = vertices[previous];
      final crosses =
          (a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
      if (crosses) inside = !inside;
      if (padding > 0 && _distanceToSegment(point, a, b) <= padding) {
        return true;
      }
    }
    return inside;
  }

  static double _distanceToSegment(
    WorldMapPoint point,
    WorldMapPoint start,
    WorldMapPoint end,
  ) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) return point.distanceTo(start);
    final projection =
        (((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared)
            .clamp(0.0, 1.0);
    return point.distanceTo(
      WorldMapPoint(start.x + projection * dx, start.y + projection * dy),
    );
  }
}

class WorldMapTree {
  const WorldMapTree({
    required this.center,
    required this.radius,
    required this.tint,
  });

  final WorldMapPoint center;
  final double radius;
  final int tint;
}

class WorldMapPointOfInterest {
  const WorldMapPointOfInterest({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
  });

  final String id;
  final String name;
  final WorldPointOfInterestType type;
  final WorldMapPoint position;
}

class WorldMapChunk {
  const WorldMapChunk({
    required this.x,
    required this.y,
    required this.parcels,
    required this.trees,
    required this.pointsOfInterest,
    required this.ponds,
    required this.mountains,
    this.lakes = const [],
  });

  final int x;
  final int y;
  final List<WorldMapParcel> parcels;
  final List<WorldMapTree> trees;
  final List<WorldMapPointOfInterest> pointsOfInterest;
  final List<WorldMapPond> ponds;
  final List<WorldMapMountain> mountains;
  final List<WorldMapLake> lakes;
}

class WorldMapPond {
  const WorldMapPond({
    required this.center,
    required this.width,
    required this.height,
  });

  final WorldMapPoint center;
  final double width;
  final double height;
}

class WorldMapMountain {
  const WorldMapMountain({
    required this.center,
    required this.width,
    required this.height,
    required this.ridgeAngle,
  });

  final WorldMapPoint center;
  final double width;
  final double height;
  final double ridgeAngle;
}

class WorldMapRoad {
  const WorldMapRoad({
    required this.id,
    required this.type,
    required this.points,
  });

  final String id;
  final WorldMapRoadType type;
  final List<WorldMapPoint> points;

  double get width => switch (type) {
    WorldMapRoadType.arterial => 25,
    WorldMapRoadType.secondary => 16,
    WorldMapRoadType.dirt => 10,
    WorldMapRoadType.trail => 6,
  };
}

enum WorldMapWatercourseType { river, tributary, irrigationCanal }

/// A fixed agricultural region overlay, expressed in world-space metres.
/// Region data is descriptive and presentation-only; it does not change parcel
/// generation or saved parcel identities.
class WorldMapRegion {
  const WorldMapRegion({
    required this.id,
    required this.name,
    required this.boundary,
    required this.labelPosition,
    required this.color,
    required this.favoredCrop,
    required this.soilDescription,
    required this.waterDescription,
    this.soilColor = 0xFFB3A06A,
    this.landform = 'ova',
    this.fieldDensity = 0.5,
    this.treeDensity = 0.5,
    this.rainfall = 'ılıman yağış',
  });

  final String id;
  final String name;
  final List<WorldMapPoint> boundary;
  final WorldMapPoint labelPosition;

  /// Opaque ARGB base tint. Renderers should apply their own subdued opacity.
  final int color;
  final WorldCropType favoredCrop;
  final String soilDescription;
  final String waterDescription;

  /// Base color of the exposed soil; renderers should keep field fill subtle.
  final int soilColor;

  /// Geographic landform label, such as `ova`, `yayla`, or `yamaç`.
  final String landform;

  /// Relative suitability for large cultivated fields (0–1).
  final double fieldDensity;

  /// Relative natural tree cover (0–1), reduced around fields by clearance.
  final double treeDensity;

  /// Regional precipitation pattern shown as short map metadata.
  final String rainfall;

  bool contains(WorldMapPoint point) {
    var inside = false;
    for (
      var index = 0, previous = boundary.length - 1;
      index < boundary.length;
      previous = index++
    ) {
      final a = boundary[index];
      final b = boundary[previous];
      final crosses =
          (a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
      if (crosses) inside = !inside;
    }
    return inside;
  }
}

/// A named river, tributary, or irrigation channel drawn over the world map.
class WorldMapWatercourse {
  const WorldMapWatercourse({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    required this.width,
  });

  final String id;
  final String name;
  final WorldMapWatercourseType type;
  final List<WorldMapPoint> points;

  /// Stroke width in world-space metres.
  final double width;
}

/// An irregular inland waterbody. Shoreline vertices are world-space points.
class WorldMapLake {
  const WorldMapLake({
    required this.id,
    required this.name,
    required this.shoreline,
    required this.labelPosition,
    required this.waterColor,
  });

  final String id;
  final String name;
  final List<WorldMapPoint> shoreline;
  final WorldMapPoint labelPosition;
  final int waterColor;

  Rect get bounds {
    if (shoreline.isEmpty) return Rect.zero;
    var minX = shoreline.first.x;
    var maxX = shoreline.first.x;
    var minY = shoreline.first.y;
    var maxY = shoreline.first.y;
    for (final point in shoreline.skip(1)) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

enum WorldMapSettlementKind { city, town, village, hamlet }

/// A named settlement placed at a deterministic road junction.
class WorldMapSettlement {
  const WorldMapSettlement({
    required this.id,
    required this.name,
    required this.kind,
    required this.position,
    required this.population,
    this.roadId,
  });

  final String id;
  final String name;
  final WorldMapSettlementKind kind;
  final WorldMapPoint position;
  final int population;
  final String? roadId;
}

/// A mapped bridge deck at an actual road-to-river polyline intersection.
class WorldMapBridge {
  const WorldMapBridge({
    required this.id,
    required this.roadId,
    required this.watercourseId,
    required this.position,
    required this.angle,
    required this.width,
    required this.length,
  });

  final String id;
  final String roadId;
  final String watercourseId;
  final WorldMapPoint position;

  /// Radians, following the road centerline.
  final double angle;

  /// Deck width across the road, in world metres.
  final double width;

  /// Deck length across the watercourse, in world metres.
  final double length;
}

/// A saved connection between two owned parcels. Coordinates are stored so the
/// link remains renderable even if parcel generation rules evolve in a later build.
class WorldLogisticsLink {
  const WorldLogisticsLink({
    required this.id,
    required this.name,
    required this.fromParcelId,
    required this.toParcelId,
    required this.from,
    required this.to,
    required this.cost,
  });

  final String id;
  final String name;
  final String fromParcelId;
  final String toParcelId;
  final WorldMapPoint from;
  final WorldMapPoint to;
  final int cost;

  double get distance => from.distanceTo(to);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fromParcelId': fromParcelId,
    'toParcelId': toParcelId,
    'fromX': from.x,
    'fromY': from.y,
    'toX': to.x,
    'toY': to.y,
    'cost': cost,
  };

  factory WorldLogisticsLink.fromJson(Map<String, dynamic> json) =>
      WorldLogisticsLink(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Lojistik hattı',
        fromParcelId: json['fromParcelId'] as String,
        toParcelId: json['toParcelId'] as String,
        from: WorldMapPoint(
          (json['fromX'] as num).toDouble(),
          (json['fromY'] as num).toDouble(),
        ),
        to: WorldMapPoint(
          (json['toX'] as num).toDouble(),
          (json['toY'] as num).toDouble(),
        ),
        cost: json['cost'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is WorldLogisticsLink &&
      id == other.id &&
      name == other.name &&
      fromParcelId == other.fromParcelId &&
      toParcelId == other.toParcelId &&
      from.x == other.from.x &&
      from.y == other.from.y &&
      to.x == other.to.x &&
      to.y == other.to.y &&
      cost == other.cost;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fromParcelId,
    toParcelId,
    from.x,
    from.y,
    to.x,
    to.y,
    cost,
  );
}

/// Deterministic, practically unbounded map. Only visited chunks are generated
/// and cached; the same seed and coordinate always produce the same land offers.
class ProceduralFarmWorld {
  ProceduralFarmWorld({
    this.seed = defaultSeed,
    this.generationVersion = currentGenerationVersion,
    int? legacyGenerationVersion,
    Iterable<String> preservedParcelIds = const [],
    this.preserveHistoricalParcelGeometry = false,
  }) : preservedParcelGenerationVersion =
           legacyGenerationVersion ??
           (generationVersion >= geographicRedesignGenerationVersion
               ? clusteredMountainGenerationVersion
               : generationVersion),
       _preservedParcelIds = Set.unmodifiable(preservedParcelIds);

  static const int defaultSeed = 20270317;
  static const int legacyGenerationVersion = 1;
  static const int expandedParcelGenerationVersion = 2;
  static const int mountainFieldBlockingGenerationVersion = 2;
  static const int clusteredMountainGenerationVersion = 3;
  static const int geographicRedesignGenerationVersion = 4;
  static const int collisionSafeGenerationVersion = 5;
  static const int parcelBoundarySafeGenerationVersion = 6;
  static const int currentGenerationVersion =
      parcelBoundarySafeGenerationVersion;
  static const double _lakeFieldBankBufferMeters = 180;
  static const double _lakeRoadBankBufferMeters = 180;
  static const double _pondFieldBankBufferMeters = 110;
  static const double _watercourseFieldBankBufferMeters = 72;
  static const double _fieldRoadShoulderBufferMeters = 46;
  static const double _settlementFieldBufferMeters = 38;
  static const double _settlementRoadBufferMeters = 20;
  static const int chunksPerDistrict = 8;
  static const double districtSize = farmWorldChunkSize * chunksPerDistrict;

  /// Finite world bounds for optimized performance and memory safety.
  /// 27x27 chunks (~17.28 km x 17.28 km) provides a vast area (3x original map)
  /// for exploration, trade routes, and farm expansion.
  static const int minChunkX = -13;
  static const int maxChunkX = 13;
  static const int minChunkY = -13;
  static const int maxChunkY = 13;

  static const double worldMinX = minChunkX * farmWorldChunkSize;
  static const double worldMaxX = (maxChunkX + 1) * farmWorldChunkSize;
  static const double worldMinY = minChunkY * farmWorldChunkSize;
  static const double worldMaxY = (maxChunkY + 1) * farmWorldChunkSize;

  static const Rect worldBounds = Rect.fromLTRB(
    worldMinX,
    worldMinY,
    worldMaxX,
    worldMaxY,
  );

  /// Stable named zones for the agriculture-focused overview map. Their
  /// boundaries cover the finite world without participating in parcel rolls.
  static const List<WorldMapRegion> agriculturalRegionData = [
    WorldMapRegion(
      id: 'west_dryfields',
      name: 'Batı Kurak Ovası',
      boundary: [
        WorldMapPoint(-8320, -8320),
        WorldMapPoint(-2200, -8320),
        WorldMapPoint(-1800, -5800),
        WorldMapPoint(-2600, -3600),
        WorldMapPoint(-1300, -1700),
        WorldMapPoint(-2100, 300),
        WorldMapPoint(-1400, 2500),
        WorldMapPoint(-3100, 4800),
        WorldMapPoint(-8320, 4100),
      ],
      labelPosition: WorldMapPoint(-5450, 50),
      color: 0xFFC2A568,
      favoredCrop: WorldCropType.oilseed,
      soilDescription: 'Kireçli ve kuru, yağlı tohumlara elverişli toprak',
      waterDescription: 'Mevsimsel yağış ve seyrek kuyu suyu',
      soilColor: 0xFFC8AE79,
      landform: 'kurak ova',
      fieldDensity: 0.40,
      treeDensity: 0.22,
      rainfall: 'az yağış, uzun kuru yaz',
    ),
    WorldMapRegion(
      id: 'north_highlands',
      name: 'Kuzey Yaylaları',
      boundary: [
        WorldMapPoint(-2200, -8320),
        WorldMapPoint(8960, -8320),
        WorldMapPoint(8960, -5000),
        WorldMapPoint(6100, -4400),
        WorldMapPoint(3900, -4900),
        WorldMapPoint(1400, -3800),
        WorldMapPoint(-1800, -5800),
      ],
      labelPosition: WorldMapPoint(2200, -6700),
      color: 0xFF9AA77A,
      favoredCrop: WorldCropType.pasture,
      soilDescription: 'Taşlı, ince örtülü yayla toprağı',
      waterDescription: 'Yüksek yamaç kaynakları ve küçük dereler',
      soilColor: 0xFFAAA486,
      landform: 'yüksek yayla',
      fieldDensity: 0.16,
      treeDensity: 0.55,
      rainfall: 'serin ve yağışlı yamaçlar',
    ),
    WorldMapRegion(
      id: 'riverlands',
      name: 'Bereket Vadisi',
      boundary: [
        WorldMapPoint(-1800, -5800),
        WorldMapPoint(1400, -3800),
        WorldMapPoint(2300, 0),
        WorldMapPoint(1600, 2400),
        WorldMapPoint(-1400, 2500),
        WorldMapPoint(-2100, 300),
        WorldMapPoint(-1300, -1700),
        WorldMapPoint(-2600, -3600),
      ],
      labelPosition: WorldMapPoint(-150, -650),
      color: 0xFFB3B078,
      favoredCrop: WorldCropType.grain,
      soilDescription: 'Derin, verimli alüvyonlu tın',
      waterDescription: 'Ana nehir ve taşkın ovası',
      soilColor: 0xFF8E754C,
      landform: 'alüvyal vadi',
      fieldDensity: 0.93,
      treeDensity: 0.44,
      rainfall: 'ılıman, nehir taşkınlarıyla beslenir',
    ),
    WorldMapRegion(
      id: 'eastern_irrigated_basin',
      name: 'Doğu Sulama Havzası',
      boundary: [
        WorldMapPoint(1400, -3800),
        WorldMapPoint(3900, -4900),
        WorldMapPoint(6100, -4400),
        WorldMapPoint(8960, -5000),
        WorldMapPoint(8960, 2400),
        WorldMapPoint(6800, 3200),
        WorldMapPoint(4200, 2100),
        WorldMapPoint(2900, 3100),
        WorldMapPoint(1600, 2400),
        WorldMapPoint(2300, 0),
      ],
      labelPosition: WorldMapPoint(5700, 250),
      color: 0xFF91A978,
      favoredCrop: WorldCropType.vegetable,
      soilDescription: 'Nem tutan, koyu renkli ova toprağı',
      waterDescription: 'Sulama kanallarıyla yıl boyu su erişimi',
      soilColor: 0xFF675A3E,
      landform: 'sulanan havza',
      fieldDensity: 0.80,
      treeDensity: 0.35,
      rainfall: 'orta yağış, yazın sulama gerekir',
    ),
    WorldMapRegion(
      id: 'southern_meadows',
      name: 'Güney Meraları',
      boundary: [
        WorldMapPoint(-8320, 4100),
        WorldMapPoint(-3100, 4800),
        WorldMapPoint(-1400, 2500),
        WorldMapPoint(1600, 2400),
        WorldMapPoint(2900, 3100),
        WorldMapPoint(4200, 2100),
        WorldMapPoint(6800, 3200),
        WorldMapPoint(8960, 2400),
        WorldMapPoint(8960, 8960),
        WorldMapPoint(-8320, 8960),
      ],
      labelPosition: WorldMapPoint(1750, 6250),
      color: 0xFFA9B27A,
      favoredCrop: WorldCropType.pasture,
      soilDescription: 'Organik maddesi yüksek, yumuşak çayır toprağı',
      waterDescription: 'Mevsimlik çaylar ve sulak otlaklar',
      soilColor: 0xFF8E8059,
      landform: 'alçak çayır',
      fieldDensity: 0.59,
      treeDensity: 0.31,
      rainfall: 'mevsimlik yağış ve ilkbahar taşkınları',
    ),
  ];

  /// Named river network follows highland sources toward the southern basin.
  /// Ordered points run downstream; tributaries terminate at a main channel.
  /// The three source channels now leave their v4 lake shorelines outward.
  static const List<WorldMapWatercourse> watercourseData = [
    WorldMapWatercourse(
      id: 'greenriver',
      name: 'Yeşilırmak',
      type: WorldMapWatercourseType.river,
      width: 112,
      points: [
        WorldMapPoint(1900, -7280),
        WorldMapPoint(1450, -6650),
        WorldMapPoint(980, -5760),
        WorldMapPoint(470, -4950),
        WorldMapPoint(570, -4370),
        WorldMapPoint(960, -3740),
        WorldMapPoint(1260, -3140),
        WorldMapPoint(1690, -2500),
        WorldMapPoint(1700, -1900),
        WorldMapPoint(1510, -1320),
        WorldMapPoint(1220, -770),
        WorldMapPoint(1030, -180),
        WorldMapPoint(770, 420),
        WorldMapPoint(590, 1030),
        WorldMapPoint(810, 1640),
        WorldMapPoint(1260, 2180),
        WorldMapPoint(1940, 2860),
        WorldMapPoint(2820, 3740),
        WorldMapPoint(3890, 4740),
        WorldMapPoint(5060, 5740),
        WorldMapPoint(6320, 6760),
        WorldMapPoint(7720, 7960),
        WorldMapPoint(8500, 8840),
      ],
    ),
    WorldMapWatercourse(
      id: 'highland_tributary',
      name: 'Yayla Deresi',
      type: WorldMapWatercourseType.tributary,
      width: 50,
      points: [
        WorldMapPoint(-1100, -7150),
        WorldMapPoint(-1000, -6600),
        WorldMapPoint(-850, -5220),
        WorldMapPoint(-700, -4610),
        WorldMapPoint(-520, -3980),
        WorldMapPoint(-270, -3370),
        WorldMapPoint(120, -2860),
        WorldMapPoint(620, -2420),
        WorldMapPoint(1170, -2100),
        WorldMapPoint(1500, -1950),
        WorldMapPoint(1700, -1900),
      ],
    ),
    WorldMapWatercourse(
      id: 'eastern_creek',
      name: 'Doğu Çayı',
      type: WorldMapWatercourseType.tributary,
      width: 38,
      points: [
        WorldMapPoint(6990, -7110),
        WorldMapPoint(6400, -6550),
        WorldMapPoint(5350, -5800),
        WorldMapPoint(4680, -4800),
        WorldMapPoint(4110, -2580),
        WorldMapPoint(3500, -2380),
        WorldMapPoint(2900, -2180),
        WorldMapPoint(2310, -2030),
        WorldMapPoint(1700, -1900),
      ],
    ),
    WorldMapWatercourse(
      id: 'east_irrigation_canal',
      name: 'Doğu Ana Kanalı',
      type: WorldMapWatercourseType.irrigationCanal,
      width: 28,
      points: [
        WorldMapPoint(770, 420),
        WorldMapPoint(1540, 650),
        WorldMapPoint(2450, 820),
        WorldMapPoint(3520, 1050),
        WorldMapPoint(4690, 1290),
        WorldMapPoint(5910, 1500),
        WorldMapPoint(7090, 1780),
      ],
    ),
    WorldMapWatercourse(
      id: 'southern_irrigation_channel',
      name: 'Güney Dağıtım Kanalı',
      type: WorldMapWatercourseType.irrigationCanal,
      width: 22,
      points: [
        WorldMapPoint(1260, 2180),
        WorldMapPoint(1230, 2780),
        WorldMapPoint(1480, 3440),
        WorldMapPoint(2100, 3990),
        WorldMapPoint(2980, 4430),
        WorldMapPoint(3970, 4700),
      ],
    ),
  ];

  /// Geometry shown by existing v1–v3 saves. Keep these coordinates stable;
  /// the revised lake basins and outlet channels belong only to v4.
  static const List<WorldMapWatercourse> legacyWatercourseData = [
    WorldMapWatercourse(
      id: 'greenriver',
      name: 'Yeşilırmak',
      type: WorldMapWatercourseType.river,
      width: 112,
      points: [
        WorldMapPoint(1510, -7520),
        WorldMapPoint(1420, -7000),
        WorldMapPoint(1320, -6380),
        WorldMapPoint(980, -5760),
        WorldMapPoint(470, -4950),
        WorldMapPoint(570, -4370),
        WorldMapPoint(960, -3740),
        WorldMapPoint(1260, -3140),
        WorldMapPoint(1690, -2500),
        WorldMapPoint(1700, -1900),
        WorldMapPoint(1510, -1320),
        WorldMapPoint(1220, -770),
        WorldMapPoint(1030, -180),
        WorldMapPoint(770, 420),
        WorldMapPoint(590, 1030),
        WorldMapPoint(810, 1640),
        WorldMapPoint(1260, 2180),
        WorldMapPoint(1940, 2860),
        WorldMapPoint(2820, 3740),
        WorldMapPoint(3890, 4740),
        WorldMapPoint(5060, 5740),
        WorldMapPoint(6320, 6760),
        WorldMapPoint(7720, 7960),
        WorldMapPoint(8500, 8840),
      ],
    ),
    WorldMapWatercourse(
      id: 'highland_tributary',
      name: 'Yayla Deresi',
      type: WorldMapWatercourseType.tributary,
      width: 50,
      points: [
        WorldMapPoint(-850, -5220),
        WorldMapPoint(-700, -4610),
        WorldMapPoint(-520, -3980),
        WorldMapPoint(-270, -3370),
        WorldMapPoint(120, -2860),
        WorldMapPoint(620, -2420),
        WorldMapPoint(1170, -2100),
        WorldMapPoint(1500, -1950),
        WorldMapPoint(1700, -1900),
      ],
    ),
    WorldMapWatercourse(
      id: 'eastern_creek',
      name: 'Doğu Çayı',
      type: WorldMapWatercourseType.tributary,
      width: 38,
      points: [
        WorldMapPoint(4680, -2740),
        WorldMapPoint(4110, -2580),
        WorldMapPoint(3500, -2380),
        WorldMapPoint(2900, -2180),
        WorldMapPoint(2310, -2030),
        WorldMapPoint(1700, -1900),
      ],
    ),
    WorldMapWatercourse(
      id: 'east_irrigation_canal',
      name: 'Doğu Ana Kanalı',
      type: WorldMapWatercourseType.irrigationCanal,
      width: 28,
      points: [
        WorldMapPoint(770, 420),
        WorldMapPoint(1540, 650),
        WorldMapPoint(2450, 820),
        WorldMapPoint(3520, 1050),
        WorldMapPoint(4690, 1290),
        WorldMapPoint(5910, 1500),
        WorldMapPoint(7090, 1780),
      ],
    ),
    WorldMapWatercourse(
      id: 'southern_irrigation_channel',
      name: 'Güney Dağıtım Kanalı',
      type: WorldMapWatercourseType.irrigationCanal,
      width: 22,
      points: [
        WorldMapPoint(1260, 2180),
        WorldMapPoint(1230, 2780),
        WorldMapPoint(1480, 3440),
        WorldMapPoint(2100, 3990),
        WorldMapPoint(2980, 4430),
        WorldMapPoint(3970, 4700),
      ],
    ),
  ];

  /// V4 lake sites sit in sparse upland basins, away from the starter farmland.
  /// Their outlet vertices meet the source channels at the shore, not inland.
  /// V4 parcels use a 180 m bank exclusion; roads detour around the lake
  /// bounding envelopes with a 180 m centerline clearance.
  static const List<WorldMapLake> lakeData = [
    WorldMapLake(
      id: 'headwater_lake',
      name: 'Başkaynak Gölü',
      labelPosition: WorldMapPoint(2150, -7600),
      waterColor: 0xFF668F91,
      shoreline: [
        WorldMapPoint(1700, -7660),
        WorldMapPoint(1780, -7860),
        WorldMapPoint(1990, -8000),
        WorldMapPoint(2280, -7960),
        WorldMapPoint(2490, -7810),
        WorldMapPoint(2620, -7600),
        WorldMapPoint(2550, -7410),
        WorldMapPoint(2360, -7260),
        WorldMapPoint(2120, -7200),
        WorldMapPoint(1900, -7280),
        WorldMapPoint(1740, -7450),
      ],
    ),
    WorldMapLake(
      id: 'western_upland_lake',
      name: 'Ardıç Gölü',
      labelPosition: WorldMapPoint(-1250, -7550),
      waterColor: 0xFF66878A,
      shoreline: [
        WorldMapPoint(-1740, -7550),
        WorldMapPoint(-1680, -7760),
        WorldMapPoint(-1480, -7930),
        WorldMapPoint(-1220, -7980),
        WorldMapPoint(-980, -7870),
        WorldMapPoint(-820, -7690),
        WorldMapPoint(-770, -7450),
        WorldMapPoint(-880, -7250),
        WorldMapPoint(-1100, -7150),
        WorldMapPoint(-1360, -7180),
        WorldMapPoint(-1580, -7310),
      ],
    ),
    WorldMapLake(
      id: 'eastern_basin_lake',
      name: 'Sazlı Göl',
      labelPosition: WorldMapPoint(7000, -7550),
      waterColor: 0xFF6C9291,
      shoreline: [
        WorldMapPoint(6470, -7570),
        WorldMapPoint(6550, -7770),
        WorldMapPoint(6780, -7950),
        WorldMapPoint(7080, -7970),
        WorldMapPoint(7350, -7810),
        WorldMapPoint(7530, -7580),
        WorldMapPoint(7480, -7350),
        WorldMapPoint(7280, -7170),
        WorldMapPoint(6990, -7110),
        WorldMapPoint(6700, -7210),
        WorldMapPoint(6540, -7370),
      ],
    ),
  ];

  static const List<WorldMapLake> legacyLakeData = [
    WorldMapLake(
      id: 'headwater_lake',
      name: 'Başkaynak Gölü',
      labelPosition: WorldMapPoint(1500, -7900),
      waterColor: 0xFF668F91,
      shoreline: [
        WorldMapPoint(1110, -7990),
        WorldMapPoint(1160, -8170),
        WorldMapPoint(1380, -8290),
        WorldMapPoint(1640, -8240),
        WorldMapPoint(1840, -8120),
        WorldMapPoint(1980, -7950),
        WorldMapPoint(1940, -7780),
        WorldMapPoint(1780, -7620),
        WorldMapPoint(1530, -7560),
        WorldMapPoint(1330, -7650),
        WorldMapPoint(1160, -7790),
      ],
    ),
    WorldMapLake(
      id: 'western_upland_lake',
      name: 'Ardıç Gölü',
      labelPosition: WorldMapPoint(-1060, -5450),
      waterColor: 0xFF66878A,
      shoreline: [
        WorldMapPoint(-1450, -5480),
        WorldMapPoint(-1430, -5630),
        WorldMapPoint(-1240, -5740),
        WorldMapPoint(-1010, -5710),
        WorldMapPoint(-820, -5580),
        WorldMapPoint(-760, -5410),
        WorldMapPoint(-850, -5220),
        WorldMapPoint(-1050, -5100),
        WorldMapPoint(-1260, -5160),
        WorldMapPoint(-1400, -5300),
      ],
    ),
    WorldMapLake(
      id: 'eastern_basin_lake',
      name: 'Sazlı Göl',
      labelPosition: WorldMapPoint(5010, -3230),
      waterColor: 0xFF6C9291,
      shoreline: [
        WorldMapPoint(4560, -3290),
        WorldMapPoint(4630, -3490),
        WorldMapPoint(4870, -3610),
        WorldMapPoint(5150, -3560),
        WorldMapPoint(5380, -3410),
        WorldMapPoint(5470, -3210),
        WorldMapPoint(5360, -3010),
        WorldMapPoint(5150, -2870),
        WorldMapPoint(4870, -2900),
        WorldMapPoint(4660, -3070),
      ],
    ),
  ];

  List<WorldMapRegion> get regions => agriculturalRegionData;
  List<WorldMapLake> get _baseLakes =>
      generationVersion >= geographicRedesignGenerationVersion
      ? lakeData
      : legacyLakeData;

  List<WorldMapWatercourse> get _baseWatercourses =>
      generationVersion >= geographicRedesignGenerationVersion
      ? watercourseData
      : legacyWatercourseData;

  List<WorldMapWatercourse> get watercourses {
    final source = _baseWatercourses;
    if (preserveHistoricalParcelGeometry ||
        generationVersion < collisionSafeGenerationVersion) {
      return source;
    }
    final cached = _watercoursesCache;
    if (cached != null) return cached;
    final protectedParcels = _protectedOwnedParcels;
    _watercoursesCache = List.unmodifiable([
      for (final watercourse in source)
        ..._watercourseSegmentsClearOfParcels(watercourse, protectedParcels),
    ]);
    return _watercoursesCache!;
  }

  List<WorldMapLake> get lakes {
    final source = _baseLakes;
    if (preserveHistoricalParcelGeometry) return source;
    final cached = _lakesCache;
    if (cached != null) return cached;
    final protectedParcels = _protectedOwnedParcels;
    _lakesCache = List.unmodifiable(
      source.where(
        (lake) => protectedParcels.every(
          (parcel) => !_parcelOverlapsLake(parcel, lake),
        ),
      ),
    );
    return _lakesCache!;
  }

  List<WorldMapSettlement> get settlements {
    final cached = _settlementsCache;
    if (cached != null) return cached;
    final result = <WorldMapSettlement>[];
    final firstX = (worldMinX / districtSize).floor();
    final lastX = (worldMaxX / districtSize).floor();
    final firstY = (worldMinY / districtSize).floor();
    final lastY = (worldMaxY / districtSize).floor();
    for (var y = firstY; y <= lastY; y++) {
      for (var x = firstX; x <= lastX; x++) {
        final position = _settlementPositionForDistrict(x, y);
        if (position == null) continue;
        if (position.x < worldMinX - 500 ||
            position.x > worldMaxX + 500 ||
            position.y < worldMinY - 500 ||
            position.y > worldMaxY + 500) {
          continue;
        }
        final kind = _settlementKindForDistrict(x, y);
        final road = _nearestRoadAt(
          position,
          searchRadius: _settlementKeepoutRadius(kind) + 260,
        );
        if (generationVersion >= collisionSafeGenerationVersion &&
            road == null) {
          continue;
        }
        final isCity = x == 0 && y == 0;
        result.add(
          WorldMapSettlement(
            id: isCity ? 'settlement:market-city' : 'settlement:$x:$y',
            name: isCity ? 'Akpınar' : _settlementName(x, y, kind),
            kind: kind,
            position: position,
            population: switch (kind) {
              WorldMapSettlementKind.city => 18400,
              WorldMapSettlementKind.town => 2400,
              WorldMapSettlementKind.village => 540,
              WorldMapSettlementKind.hamlet => 120,
            },
            roadId: road?.id,
          ),
        );
      }
    }
    _settlementsCache = List.unmodifiable(result);
    return _settlementsCache!;
  }

  List<WorldMapBridge> bridgesInBounds(Rect bounds) {
    final candidateWatercourses = watercourses.where((w) {
      if (w.type == WorldMapWatercourseType.irrigationCanal) return false;
      final wBounds = _boundsOfPoints(w.points).inflate(w.width / 2 + 30);
      return wBounds.overlaps(bounds);
    }).toList();
    if (candidateWatercourses.isEmpty) return const [];

    final roads = roadSegmentsInBounds(
      bounds.left - 40,
      bounds.top - 40,
      bounds.right + 40,
      bounds.bottom + 40,
    );
    if (roads.isEmpty) return const [];

    final result = <WorldMapBridge>[];
    for (final road in roads) {
      if (road.type == WorldMapRoadType.trail) continue;
      final roadBounds = _boundsOfPoints(road.points);
      for (final watercourse in candidateWatercourses) {
        final watercourseBounds = _boundsOfPoints(watercourse.points);
        if (!roadBounds.overlaps(
          watercourseBounds.inflate(road.width / 2 + watercourse.width / 2 + 12),
        )) {
          continue;
        }
        for (
          var roadIndex = 0;
          roadIndex < road.points.length - 1;
          roadIndex++
        ) {
          final roadStart = road.points[roadIndex];
          final roadEnd = road.points[roadIndex + 1];
          for (
            var waterIndex = 0;
            waterIndex < watercourse.points.length - 1;
            waterIndex++
          ) {
            final waterStart = watercourse.points[waterIndex];
            final waterEnd = watercourse.points[waterIndex + 1];
            final intersection = _segmentIntersection(
              roadStart,
              roadEnd,
              waterStart,
              waterEnd,
            );
            if (intersection == null ||
                !bounds.inflate(30).contains(Offset(intersection.x, intersection.y)) ||
                result.any(
                  (bridge) =>
                      bridge.roadId == road.id &&
                      bridge.watercourseId == watercourse.id &&
                      bridge.position.distanceTo(intersection) < 50,
                )) {
              continue;
            }
            result.add(
              WorldMapBridge(
                id: 'bridge:${road.id}:${watercourse.id}:${result.length}',
                roadId: road.id,
                watercourseId: watercourse.id,
                position: intersection,
                angle: atan2(roadEnd.y - roadStart.y, roadEnd.x - roadStart.x),
                width: road.width + 18,
                length: watercourse.width + 56,
              ),
            );
          }
        }
      }
    }
    return result;
  }

  List<WorldMapBridge> get bridges {
    final cached = _bridgesCache;
    if (cached != null) return cached;
    final result = <WorldMapBridge>[];
    for (final watercourse in watercourses) {
      if (watercourse.type == WorldMapWatercourseType.irrigationCanal) continue;
      final wBounds = _boundsOfPoints(watercourse.points).inflate(watercourse.width + 50);
      final found = bridgesInBounds(wBounds);
      for (final b in found) {
        if (!result.any((existing) => existing.position.distanceTo(b.position) < 50)) {
          result.add(b);
        }
      }
    }
    _bridgesCache = List.unmodifiable(result);
    return _bridgesCache!;
  }

  WorldMapRegion? regionAt(WorldMapPoint point) {
    for (final region in agriculturalRegionData) {
      if (region.contains(point)) return region;
    }
    return null;
  }

  static bool isChunkInBounds(int chunkX, int chunkY) =>
      chunkX >= minChunkX &&
      chunkX <= maxChunkX &&
      chunkY >= minChunkY &&
      chunkY <= maxChunkY;

  final int seed;
  final int generationVersion;
  final int preservedParcelGenerationVersion;
  final bool preserveHistoricalParcelGeometry;
  final Set<String> _preservedParcelIds;
  final Map<String, WorldMapChunk> _chunkCache = {};
  final Map<String, List<WorldMapParcel>> _districtParcelCache = {};
  final Map<String, List<WorldMapParcel>> _rawDistrictParcelCache = {};
  final Map<String, List<WorldMapRoad>> _roadCache = {};
  final Map<String, List<WorldMapMountain>> _mountainCache = {};
  final Map<String, WorldMapPointOfInterest?> _pointOfInterestPlacementCache =
      {};
  final Map<String, WorldMapPoint> _settlementPositionCache = {};
  final Map<String, WorldMapPoint> _districtHubCache = {};
  final Set<String> _unavailableSettlementKeys = {};
  List<WorldMapSettlement>? _settlementsCache;
  List<WorldMapBridge>? _bridgesCache;
  List<WorldMapParcel>? _preservedParcelCache;
  List<WorldMapParcel>? _protectedParcelCache;
  List<WorldMapLake>? _lakesCache;
  List<WorldMapWatercourse>? _watercoursesCache;
  final Map<int, ProceduralFarmWorld> _historicalParcelWorlds = {};

  ProceduralFarmWorld _historicalWorldFor(int version) =>
      _historicalParcelWorlds.putIfAbsent(
        version,
        () => ProceduralFarmWorld(
          seed: seed,
          generationVersion: version,
          legacyGenerationVersion: version,
          preserveHistoricalParcelGeometry:
              version < geographicRedesignGenerationVersion,
        ),
      );

  List<WorldMapParcel> get _preservedLegacyParcels {
    final cached = _preservedParcelCache;
    if (cached != null) return cached;
    if (generationVersion < geographicRedesignGenerationVersion) {
      _preservedParcelCache = const [];
      return _preservedParcelCache!;
    }
    final parcels = <WorldMapParcel>[];
    for (final id in _preservedParcelIds) {
      final idVersion = RegExp(r':v(\d+)$').firstMatch(id);
      if (!id.startsWith('land:') ||
          idVersion != null &&
              int.parse(idVersion.group(1)!) >= generationVersion) {
        continue;
      }
      final world = idVersion == null
          ? _historicalWorldFor(preservedParcelGenerationVersion)
          : _historicalWorldFor(int.parse(idVersion.group(1)!));
      final parcel = world.parcelById(id);
      if (parcel != null) parcels.add(parcel);
    }
    _preservedParcelCache = List.unmodifiable(parcels);
    return _preservedParcelCache!;
  }

  List<WorldMapParcel> get _protectedOwnedParcels {
    final cached = _protectedParcelCache;
    if (cached != null) return cached;
    const home = WorldMapParcel(
      id: 'home',
      name: 'Başlangıç Çiftliği',
      center: WorldMapPoint(-150, -120),
      width: 142,
      height: 110,
      price: 0,
      fertility: 82,
      cropType: WorldCropType.grain,
      isHome: true,
    );
    _protectedParcelCache = List.unmodifiable([
      home,
      ..._preservedLegacyParcels,
    ]);
    return _protectedParcelCache!;
  }

  WorldMapChunk chunkAt(int chunkX, int chunkY) {
    if (!isChunkInBounds(chunkX, chunkY)) {
      return WorldMapChunk(
        x: chunkX,
        y: chunkY,
        parcels: const [],
        trees: const [],
        pointsOfInterest: const [],
        ponds: const [],
        mountains: const [],
      );
    }

    final key = '$chunkX:$chunkY';
    final cached = _chunkCache[key];
    if (cached != null) return cached;
    if (_chunkCache.length > 384) _chunkCache.clear();

    final random = Random(_stableHash('$seed|chunk|$chunkX|$chunkY'));
    if (generationVersion >= clusteredMountainGenerationVersion) {
      // Seed mountain exclusions before the parcel district accepts any land.
      // This makes the versioned terrain authoritative and deterministic.
      _mountainsForChunk(chunkX, chunkY);
    }
    final left = chunkX * farmWorldChunkSize;
    final top = chunkY * farmWorldChunkSize;
    final districtX = _parcelDistrictIndex(left + farmWorldChunkSize / 2);
    final districtY = _parcelDistrictIndex(top + farmWorldChunkSize / 2);
    final parcels = _parcelsForDistrict(districtX, districtY)
        .where(
          (parcel) =>
              (parcel.center.x / farmWorldChunkSize).floor() == chunkX &&
              (parcel.center.y / farmWorldChunkSize).floor() == chunkY,
        )
        .toList();

    if (chunkX == 0 && chunkY == 0) {
      parcels.insert(
        0,
        const WorldMapParcel(
          id: 'home',
          name: 'Başlangıç Çiftliği',
          center: WorldMapPoint(-150, -120),
          width: 142,
          height: 110,
          price: 0,
          fertility: 82,
          cropType: WorldCropType.grain,
          isHome: true,
        ),
      );
    }

    final trees = <WorldMapTree>[];
    final redesigned = generationVersion >= geographicRedesignGenerationVersion;
    final treeCount = redesigned
        ? 105 + random.nextInt(55)
        : 62 + random.nextInt(34);
    const canopyTints = [0xFF294E35, 0xFF35613B, 0xFF427444, 0xFF57824A];
    const obstaclePadding = 52.0;
    final nearbyRoads = roadSegmentsInBounds(
      left - obstaclePadding,
      top - obstaclePadding,
      left + farmWorldChunkSize + obstaclePadding,
      top + farmWorldChunkSize + obstaclePadding,
    );
    final nearbyPonds = [
      for (var y = chunkY - 1; y <= chunkY + 1; y++)
        for (var x = chunkX - 1; x <= chunkX + 1; x++) ..._pondsForChunk(x, y),
    ];
    final nearbyMountains =
        generationVersion >= clusteredMountainGenerationVersion
        ? [
            for (var y = chunkY - 1; y <= chunkY + 1; y++)
              for (var x = chunkX - 1; x <= chunkX + 1; x++)
                ..._mountainsForChunk(x, y),
          ]
        : _mountainsForChunk(chunkX, chunkY);
    final nearbyParcels = redesigned
        ? <WorldMapParcel>{
            ...parcels,
            for (var y = chunkY - 1; y <= chunkY + 1; y++)
              for (var x = chunkX - 1; x <= chunkX + 1; x++)
                ..._parcelsForDistrict(
                  _parcelDistrictIndex((x + 0.5) * farmWorldChunkSize),
                  _parcelDistrictIndex((y + 0.5) * farmWorldChunkSize),
                ).where(
                  (parcel) =>
                      (parcel.center.x / farmWorldChunkSize).floor() == x &&
                      (parcel.center.y / farmWorldChunkSize).floor() == y,
                ),
            if (chunkX >= -1 && chunkX <= 0 && chunkY >= -1 && chunkY <= 0)
              const WorldMapParcel(
                id: 'home',
                name: 'Başlangıç Çiftliği',
                center: WorldMapPoint(-150, -120),
                width: 142,
                height: 110,
                price: 0,
                fertility: 82,
                cropType: WorldCropType.grain,
                isHome: true,
              ),
            ..._preservedLegacyParcels,
          }.toList()
        : parcels;
    for (var index = 0; index < treeCount; index++) {
      final point = WorldMapPoint(
        left + random.nextDouble() * farmWorldChunkSize,
        top + random.nextDouble() * farmWorldChunkSize,
      );
      final radius = 13 + random.nextDouble() * 12;
      if (redesigned &&
          random.nextDouble() > (regionAt(point)?.treeDensity ?? 0.42)) {
        continue;
      }
      final fieldClearance = redesigned ? 160.0 : 13.0;
      if (nearbyParcels.any(
        (parcel) => parcel.contains(point, padding: fieldClearance),
      )) {
        continue;
      }
      if (!_treeHasRoadClearance(point, radius, nearbyRoads) ||
          _treeOverlapsPond(point, radius, nearbyPonds) ||
          _treeOverlapsMountain(point, radius, nearbyMountains) ||
          redesigned &&
              (_treeOverlapsLake(point, radius, this.lakes) ||
                  _treeOverlapsWatercourse(point, radius, watercourses) ||
                  _treeOverlapsSettlement(point, radius))) {
        continue;
      }
      trees.add(
        WorldMapTree(
          center: point,
          radius: radius,
          tint: canopyTints[random.nextInt(canopyTints.length)],
        ),
      );
    }

    final ponds = _pondsForChunk(chunkX, chunkY);
    final pointsOfInterest = _pointsOfInterestForChunk(chunkX, chunkY);
    final lakes = _lakesForChunk(chunkX, chunkY);
    final mountains = _mountainsForChunk(
      chunkX,
      chunkY,
      existingParcels: parcels,
    );

    final chunk = WorldMapChunk(
      x: chunkX,
      y: chunkY,
      parcels: List.unmodifiable(parcels),
      trees: List.unmodifiable(trees),
      pointsOfInterest: List.unmodifiable(pointsOfInterest),
      ponds: List.unmodifiable(ponds),
      mountains: List.unmodifiable(mountains),
      lakes: List.unmodifiable(lakes),
    );
    _chunkCache[key] = chunk;
    return chunk;
  }

  bool _treeHasRoadClearance(
    WorldMapPoint point,
    double treeRadius,
    List<WorldMapRoad> roads,
  ) {
    final canopyAndShadowRadius = treeRadius * 1.1 + 3;
    for (final road in roads) {
      final requiredDistance = canopyAndShadowRadius + road.width / 2;
      for (var index = 0; index < road.points.length - 1; index++) {
        final start = road.points[index];
        final end = road.points[index + 1];
        if (point.x < min(start.x, end.x) - requiredDistance ||
            point.x > max(start.x, end.x) + requiredDistance ||
            point.y < min(start.y, end.y) - requiredDistance ||
            point.y > max(start.y, end.y) + requiredDistance) {
          continue;
        }
        if (WorldMapParcel._distanceToSegment(point, start, end) <
            requiredDistance) {
          return false;
        }
      }
    }
    return true;
  }

  bool _treeOverlapsPond(
    WorldMapPoint point,
    double treeRadius,
    List<WorldMapPond> ponds,
  ) {
    final canopyAndShadowRadius = treeRadius * 1.1 + 10;
    for (final pond in ponds) {
      final expandedRadiusX = pond.width / 2 + canopyAndShadowRadius;
      final expandedRadiusY = pond.height / 2 + canopyAndShadowRadius;
      final normalizedX = (point.x - pond.center.x) / expandedRadiusX;
      final normalizedY = (point.y - pond.center.y) / expandedRadiusY;
      if (normalizedX * normalizedX + normalizedY * normalizedY <= 1) {
        return true;
      }
    }
    return false;
  }

  bool _treeOverlapsMountain(
    WorldMapPoint point,
    double treeRadius,
    List<WorldMapMountain> mountains,
  ) {
    for (final mountain in mountains) {
      final x =
          (point.x - mountain.center.x) / (mountain.width / 2 + treeRadius);
      final y =
          (point.y - mountain.center.y) / (mountain.height / 2 + treeRadius);
      if (x * x + y * y <= 1) return true;
    }
    return false;
  }

  bool _treeOverlapsSettlement(WorldMapPoint point, double treeRadius) =>
      _settlementFootprintsWithin(
        Rect.fromCircle(
          center: Offset(point.x, point.y),
          radius: treeRadius + 1,
        ),
      ).any(
        (footprint) =>
            point.distanceTo(footprint.$1) <=
            footprint.$2 + treeRadius + _settlementFieldBufferMeters,
      );

  WorldMapParcel? parcelById(String id, {int searchRadius = 1}) {
    if (id == 'home') return chunkAt(0, 0).parcels.first;
    final match = RegExp(r'^land:(-?\d+):(-?\d+):(\d+)(:v\d+)?$')
        .firstMatch(id);
    if (match == null) return null;
    if (generationVersion >= collisionSafeGenerationVersion) {
      final suffix = match.group(4);
      if (suffix == null) {
        return _historicalWorldFor(preservedParcelGenerationVersion)
            .parcelById(id, searchRadius: searchRadius);
      }
      final idVersion = int.parse(suffix.substring(2));
      if (idVersion < generationVersion) {
        return _historicalWorldFor(idVersion)
            .parcelById(id, searchRadius: searchRadius);
      }
      if (idVersion > generationVersion) return null;
    }
    final chunkX = int.parse(match.group(1)!);
    final chunkY = int.parse(match.group(2)!);
    for (var y = chunkY - searchRadius; y <= chunkY + searchRadius; y++) {
      for (var x = chunkX - searchRadius; x <= chunkX + searchRadius; x++) {
        for (final parcel in chunkAt(x, y).parcels) {
          if (parcel.id == id) return parcel;
        }
      }
    }
    return null;
  }

  List<WorldMapParcel> _parcelsForDistrict(int districtX, int districtY) {
    final key = '$districtX:$districtY';
    final cached = _districtParcelCache[key];
    if (cached != null) return cached;
    if (_districtParcelCache.length > 128) {
      _districtParcelCache.clear();
      _rawDistrictParcelCache.clear();
    }

    if (generationVersion >= parcelBoundarySafeGenerationVersion) {
      final candidates = _rawRedesignedParcelsForDistrict(districtX, districtY);
      final neighboringParcels = [
        for (var y = districtY - 1; y <= districtY + 1; y++)
          for (var x = districtX - 1; x <= districtX + 1; x++)
            if (x != districtX || y != districtY)
              if (_parcelDistrictIsVisible(x, y))
                ..._rawRedesignedParcelsForDistrict(x, y),
      ];
      final parcels = List<WorldMapParcel>.unmodifiable([
        for (final candidate in candidates)
          if (!neighboringParcels.any(
            (neighbor) =>
                _parcelConflicts(candidate, [neighbor]) &&
                _winsParcelBoundaryConflict(neighbor, candidate),
          ))
            candidate,
      ]);
      _districtParcelCache[key] = parcels;
      return parcels;
    }

    if (generationVersion >= geographicRedesignGenerationVersion) {
      final parcels = _redesignedParcelsForDistrict(districtX, districtY);
      _districtParcelCache[key] = parcels;
      return parcels;
    }

    final random = Random(_stableHash('$seed|parcel-clusters|$key'));
    final districtLeft = districtX * districtSize;
    final districtTop = districtY * districtSize;
    final clusters = <({WorldMapPoint center, double radius, int count})>[];
    final isStarterDistrict = districtX == 0 && districtY == 0;
    final mainRadius = isStarterDistrict
        ? 330 + random.nextDouble() * 100
        : 820 + random.nextDouble() * 220;
    clusters.add((
      center: _districtHub(districtX, districtY),
      radius: mainRadius,
      count: isStarterDistrict
          ? (generationVersion >= expandedParcelGenerationVersion
                ? 22 + random.nextInt(9)
                : 16 + random.nextInt(8))
          : (generationVersion >= expandedParcelGenerationVersion
                ? 46 + random.nextInt(23)
                : 29 + random.nextInt(16)),
    ));

    final satelliteCount = switch (random.nextInt(100)) {
      < 57 => 1,
      < 80 => 2,
      _ => 0,
    };
    for (var satellite = 0; satellite < satelliteCount; satellite++) {
      final radius = 430 + random.nextDouble() * 210;
      for (var attempt = 0; attempt < 28; attempt++) {
        final center = WorldMapPoint(
          districtLeft + districtSize * (0.19 + random.nextDouble() * 0.62),
          districtTop + districtSize * (0.19 + random.nextDouble() * 0.62),
        );
        final clear = clusters.every(
          (cluster) =>
              center.distanceTo(cluster.center) > radius + cluster.radius + 280,
        );
        if (!clear) continue;
        clusters.add((
          center: center,
          radius: radius,
          count: generationVersion >= expandedParcelGenerationVersion
              ? 14 + random.nextInt(11)
              : 9 + random.nextInt(10),
        ));
        break;
      }
    }

    final accepted = <WorldMapParcel>[];
    final nextIndexByChunk = <String, int>{};
    for (var clusterIndex = 0; clusterIndex < clusters.length; clusterIndex++) {
      final cluster = clusters[clusterIndex];
      final clusterRandom = Random(
        _stableHash('$seed|parcel-cluster|$key|$clusterIndex'),
      );
      var clusterAccepted = 0;
      var attempts = 0;
      while (clusterAccepted < cluster.count && attempts < cluster.count * 42) {
        attempts++;
        final angle = clusterRandom.nextDouble() * pi * 2;
        final radius = sqrt(clusterRandom.nextDouble()) * cluster.radius;
        final center = WorldMapPoint(
          cluster.center.x + cos(angle) * radius,
          cluster.center.y + sin(angle) * radius,
        );
        final dimensions = _parcelDimensions(clusterRandom);
        final width = dimensions.$1;
        final height = dimensions.$2;
        final cropType = WorldCropType
            .values[clusterRandom.nextInt(WorldCropType.values.length)];
        final shape = _parcelShape(clusterRandom);
        final density = _parcelDensity(center);
        // Preserve the historical random stream used by fertility and later
        // parcels. This draw no longer contributes to land prices.
        clusterRandom.nextInt(400);
        final ownerX = (center.x / farmWorldChunkSize).floor();
        final ownerY = (center.y / farmWorldChunkSize).floor();
        final ownerKey = '$ownerX:$ownerY';
        final index = nextIndexByChunk[ownerKey] ?? 0;
        final areaHectares = WorldMapParcel.measureAreaHectares(
          width: width,
          height: height,
          shape: shape,
        );
        final fertility = (54 + clusterRandom.nextInt(45) + density * 7)
            .round()
            .clamp(0, 100)
            .toInt();
        final candidate = WorldMapParcel(
          id: 'land:$ownerX:$ownerY:$index',
          name: _parcelName(ownerX, ownerY, index, cropType),
          center: center,
          width: width,
          height: height,
          price: _parcelPriceForArea(
            areaHectares,
            fertility: fertility,
            cropType: cropType,
          ),
          fertility: fertility,
          cropType: cropType,
          shape: shape,
        );
        if (_hasHomeClearance(candidate) ||
            _parcelConflicts(candidate, accepted) ||
            !preserveHistoricalParcelGeometry &&
                (!_hasFeatureClearance(candidate) ||
                    !_hasRoadClearance(candidate))) {
          continue;
        }
        accepted.add(candidate);
        nextIndexByChunk[ownerKey] = index + 1;
        clusterAccepted++;
      }
    }

    final result = List<WorldMapParcel>.unmodifiable(accepted);
    _districtParcelCache[key] = result;
    return result;
  }

  List<WorldMapParcel> _rawRedesignedParcelsForDistrict(
    int districtX,
    int districtY,
  ) {
    final key = '$districtX:$districtY';
    return _rawDistrictParcelCache.putIfAbsent(
      key,
      () => _redesignedParcelsForDistrict(districtX, districtY),
    );
  }

  bool _parcelDistrictIsVisible(int districtX, int districtY) {
    final minimumX = _parcelDistrictIndex(
      (minChunkX + 0.5) * farmWorldChunkSize,
    );
    final maximumX = _parcelDistrictIndex(
      (maxChunkX + 0.5) * farmWorldChunkSize,
    );
    final minimumY = _parcelDistrictIndex(
      (minChunkY + 0.5) * farmWorldChunkSize,
    );
    final maximumY = _parcelDistrictIndex(
      (maxChunkY + 0.5) * farmWorldChunkSize,
    );
    return districtX >= minimumX &&
        districtX <= maximumX &&
        districtY >= minimumY &&
        districtY <= maximumY;
  }

  List<WorldMapParcel> _redesignedParcelsForDistrict(
    int districtX,
    int districtY,
  ) {
    final key = '$districtX:$districtY';
    final random = Random(
      _stableHash('$seed|terrain-parcels|$key|v$generationVersion'),
    );
    final cellLeft = districtX * districtSize - districtSize / 2;
    final cellTop = districtY * districtSize - districtSize / 2;
    final isCoreDistrict = districtX == 0 && districtY == 0;
    final ring = max(districtX.abs(), districtY.abs());
    final clusters = <({WorldMapPoint center, double radius, int count})>[];

    if (isCoreDistrict) {
      clusters.add((
        center: const WorldMapPoint(0, 155),
        radius: 2420,
        count: 88 + random.nextInt(15),
      ));
    } else if (ring == 1) {
      final nearestX = (0.0).clamp(
        cellLeft + 360,
        cellLeft + districtSize - 360,
      );
      final nearestY = (155.0).clamp(
        cellTop + 360,
        cellTop + districtSize - 360,
      );
      final center = WorldMapPoint(
        nearestX + (random.nextDouble() - 0.5) * 340,
        nearestY + (random.nextDouble() - 0.5) * 340,
      );
      clusters.add((
        center: center,
        radius: 520 + random.nextDouble() * 260,
        count: 9 + random.nextInt(8),
      ));
    } else if (ring == 2) {
      if (random.nextInt(100) < 78) {
        final center = WorldMapPoint(
          cellLeft + districtSize * (0.28 + random.nextDouble() * 0.44),
          cellTop + districtSize * (0.28 + random.nextDouble() * 0.44),
        );
        clusters.add((
          center: center,
          radius: 390 + random.nextDouble() * 220,
          count: 4 + random.nextInt(4),
        ));
      }
    } else if (ring <= 3 && random.nextInt(100) < 48) {
      final center = WorldMapPoint(
        cellLeft + districtSize * (0.25 + random.nextDouble() * 0.5),
        cellTop + districtSize * (0.25 + random.nextDouble() * 0.5),
      );
      clusters.add((
        center: center,
        radius: 260 + random.nextDouble() * 180,
        count: 2 + random.nextInt(3),
      ));
    }

    final accepted = <WorldMapParcel>[];
    final preservedParcels = _preservedLegacyParcels;
    final nextIndexByChunk = <String, int>{};
    for (var clusterIndex = 0; clusterIndex < clusters.length; clusterIndex++) {
      final cluster = clusters[clusterIndex];
      final clusterRandom = Random(
        _stableHash(
          '$seed|terrain-cluster|$key|$clusterIndex|v$generationVersion',
        ),
      );
      var clusterAccepted = 0;
      var attempts = 0;
      while (clusterAccepted < cluster.count &&
          attempts < cluster.count * 135) {
        attempts++;
        final angle = clusterRandom.nextDouble() * pi * 2;
        final radius = sqrt(clusterRandom.nextDouble()) * cluster.radius;
        final center = WorldMapPoint(
          cluster.center.x + cos(angle) * radius,
          cluster.center.y + sin(angle) * radius,
        );
        if (center.x < cellLeft + 90 ||
            center.x > cellLeft + districtSize - 90 ||
            center.y < cellTop + 90 ||
            center.y > cellTop + districtSize - 90) {
          continue;
        }
        final region = regionAt(center);
        if (region != null && region.fieldDensity < 0.12) continue;
        if (region != null &&
            region.fieldDensity < 0.35 &&
            clusterRandom.nextDouble() > region.fieldDensity) {
          continue;
        }
        final dimensions = _redesignedParcelDimensions(clusterRandom);
        final width = dimensions.$1;
        final height = dimensions.$2;
        final regionCrop = region?.favoredCrop ?? WorldCropType.grain;
        final cropType = clusterRandom.nextDouble() < 0.64
            ? regionCrop
            : WorldCropType.values[clusterRandom.nextInt(
                WorldCropType.values.length,
              )];
        final shape = _parcelShape(clusterRandom);
        final density = _parcelDensityV4(center);
        final ownerX = (center.x / farmWorldChunkSize).floor();
        final ownerY = (center.y / farmWorldChunkSize).floor();
        final ownerKey = '$ownerX:$ownerY';
        final index = nextIndexByChunk[ownerKey] ?? 0;
        final areaHectares = WorldMapParcel.measureAreaHectares(
          width: width,
          height: height,
          shape: shape,
        );
        final fertility =
            (49 +
                    clusterRandom.nextInt(39) +
                    density * 9 +
                    (region?.fieldDensity ?? 0.45) * 8)
                .round()
                .clamp(0, 100)
                .toInt();
        final candidate = WorldMapParcel(
          id: 'land:$ownerX:$ownerY:$index:v$generationVersion',
          name: _parcelName(ownerX, ownerY, index, cropType),
          center: center,
          width: width,
          height: height,
          price: _parcelPriceForArea(
            areaHectares,
            fertility: fertility,
            cropType: cropType,
          ),
          fertility: fertility,
          cropType: cropType,
          shape: shape,
        );
        if (_hasHomeClearance(candidate) ||
            _parcelConflicts(candidate, [...accepted, ...preservedParcels]) ||
            !preserveHistoricalParcelGeometry &&
                (!_hasFeatureClearance(candidate) ||
                    !_hasRoadClearance(candidate))) {
          continue;
        }
        accepted.add(candidate);
        nextIndexByChunk[ownerKey] = index + 1;
        clusterAccepted++;
      }
    }
    return List.unmodifiable(accepted);
  }

  int _parcelPriceForArea(
    double areaHectares, {
    required int fertility,
    required WorldCropType cropType,
  }) {
    // A concave area curve makes larger parcels cost more overall while
    // lowering their per-hectare price. Fertility and crop type add modest,
    // bounded value adjustments; location does not affect the offer.
    const fixedCost = 300.0;
    const areaCost = 600.0;
    const areaExponent = 0.85;
    final nonNegativeArea = max(0.0, areaHectares);
    final fertilityMultiplier = 0.90 + fertility.clamp(0, 100) / 500;
    final cropMultiplier = switch (cropType) {
      WorldCropType.grain => 1.0,
      WorldCropType.oilseed => 1.04,
      WorldCropType.vegetable => 1.08,
      WorldCropType.pasture => 0.96,
    };
    return ((fixedCost + areaCost * pow(nonNegativeArea, areaExponent)) *
            fertilityMultiplier *
            cropMultiplier)
        .round();
  }

  (double, double) _parcelDimensions(Random random) {
    if (generationVersion >= geographicRedesignGenerationVersion) {
      return _redesignedParcelDimensions(random);
    }
    if (generationVersion >= expandedParcelGenerationVersion) {
      final width = switch (random.nextInt(100)) {
        < 58 => 48 + random.nextDouble() * 54,
        < 90 => 102 + random.nextDouble() * 73,
        < 99 => 174 + random.nextDouble() * 90,
        _ => 270 + random.nextDouble() * 135,
      };
      final height = switch (random.nextInt(100)) {
        < 58 => 42 + random.nextDouble() * 49,
        < 90 => 88 + random.nextDouble() * 66,
        < 99 => 154 + random.nextDouble() * 92,
        _ => 215 + random.nextDouble() * 125,
      };
      return (width, height);
    }
    final width = switch (random.nextInt(100)) {
      < 28 => 66 + random.nextDouble() * 48,
      < 76 => 108 + random.nextDouble() * 62,
      _ => 160 + random.nextDouble() * 50,
    };
    final height = switch (random.nextInt(100)) {
      < 30 => 52 + random.nextDouble() * 40,
      < 78 => 88 + random.nextDouble() * 48,
      _ => 126 + random.nextDouble() * 56,
    };
    return (width, height);
  }

  static (double, double) _redesignedParcelDimensions(Random random) {
    final width = switch (random.nextInt(100)) {
      < 38 => 105 + random.nextDouble() * 85,
      < 77 => 190 + random.nextDouble() * 150,
      < 96 => 340 + random.nextDouble() * 190,
      _ => 530 + random.nextDouble() * 230,
    };
    final height = switch (random.nextInt(100)) {
      < 38 => 90 + random.nextDouble() * 78,
      < 77 => 168 + random.nextDouble() * 132,
      < 96 => 300 + random.nextDouble() * 175,
      _ => 480 + random.nextDouble() * 210,
    };
    return (width, height);
  }

  bool _parcelConflicts(
    WorldMapParcel candidate,
    List<WorldMapParcel> accepted,
  ) {
    const clearance = 24.0;
    return accepted.any(
      (parcel) =>
          (candidate.center.x - parcel.center.x).abs() <
              (candidate.width + parcel.width) / 2 + clearance &&
          (candidate.center.y - parcel.center.y).abs() <
              (candidate.height + parcel.height) / 2 + clearance,
    );
  }

  bool _winsParcelBoundaryConflict(
    WorldMapParcel first,
    WorldMapParcel second,
  ) {
    final firstPriority = _stableHash(
      '$seed|parcel-boundary-priority|${first.id}',
    );
    final secondPriority = _stableHash(
      '$seed|parcel-boundary-priority|${second.id}',
    );
    if (firstPriority != secondPriority) return firstPriority < secondPriority;
    return first.id.compareTo(second.id) < 0;
  }

  bool _hasFeatureClearance(WorldMapParcel parcel) {
    final chunkX = (parcel.center.x / farmWorldChunkSize).floor();
    final chunkY = (parcel.center.y / farmWorldChunkSize).floor();
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        if (generationVersion >= mountainFieldBlockingGenerationVersion &&
            _mountainsForChunk(
              x,
              y,
            ).any((mountain) => _parcelOverlapsMountain(parcel, mountain))) {
          return false;
        }
        for (final pond in _pondsForChunk(x, y)) {
          if (_parcelOverlapsPond(parcel, pond, _pondFieldBankBufferMeters)) {
            return false;
          }
        }
        for (final poi in _pointsOfInterestForChunk(x, y)) {
          final poiRadius = switch (poi.type) {
            WorldPointOfInterestType.water => 58.0,
            WorldPointOfInterestType.village => 108.0,
            WorldPointOfInterestType.mill => 78.0,
            WorldPointOfInterestType.timberYard => 88.0,
          };
          if (_parcelIntersectsCircle(parcel, poi.position, poiRadius + 32)) {
            return false;
          }
        }
      }
    }
    if (generationVersion >= collisionSafeGenerationVersion &&
        _settlementFootprintsWithin(
          _boundsOfPoints(parcel.worldVertices).inflate(
            _settlementKeepoutRadius(WorldMapSettlementKind.city) +
                _settlementFieldBufferMeters,
          ),
        ).any(
          (footprint) => _parcelIntersectsCircle(
            parcel,
            footprint.$1,
            footprint.$2 + _settlementFieldBufferMeters,
          ),
        )) {
      return false;
    }
    if (generationVersion >= geographicRedesignGenerationVersion &&
        _baseLakes.any((lake) => _parcelOverlapsLake(parcel, lake))) {
      return false;
    }
    if (generationVersion >= geographicRedesignGenerationVersion &&
        _parcelOverlapsWatercourse(parcel)) {
      return false;
    }
    return true;
  }

  bool _parcelOverlapsMountain(
    WorldMapParcel parcel,
    WorldMapMountain mountain,
  ) {
    final parcelRadius =
        sqrt(parcel.width * parcel.width + parcel.height * parcel.height) / 2;
    final expandedX = mountain.width / 2 + parcelRadius + 18;
    final expandedY = mountain.height / 2 + parcelRadius + 18;
    final x = (parcel.center.x - mountain.center.x) / expandedX;
    final y = (parcel.center.y - mountain.center.y) / expandedY;
    return x * x + y * y <= 1;
  }

  List<WorldMapMountain> _mountainsForChunk(
    int chunkX,
    int chunkY, {
    List<WorldMapParcel>? existingParcels,
  }) {
    final key = '$chunkX:$chunkY';
    final cached = _mountainCache[key];
    if (cached != null) return cached;
    final random = Random(_stableHash('$seed|mountain|$chunkX|$chunkY'));
    final inMountainRange =
        _stableHash(
              '$seed|mountain-range|${(chunkX / 4).floor()}|${(chunkY / 4).floor()}',
            ) %
            100 <
        27;
    final mountainChance =
        generationVersion >= clusteredMountainGenerationVersion
        ? (inMountainRange ? 54 : 8)
        : 23;
    if (random.nextInt(100) >= mountainChance ||
        (chunkX >= -2 && chunkX <= 1 && chunkY >= -2 && chunkY <= 1)) {
      _mountainCache[key] = const [];
      return const [];
    }

    final left = chunkX * farmWorldChunkSize;
    final top = chunkY * farmWorldChunkSize;
    final roads = generationVersion >= geographicRedesignGenerationVersion
        ? const <WorldMapRoad>[]
        : roadSegmentsInBounds(
            left - 320,
            top - 320,
            left + farmWorldChunkSize + 320,
            top + farmWorldChunkSize + 320,
          );
    final nearbyPonds = [
      for (var y = chunkY - 1; y <= chunkY + 1; y++)
        for (var x = chunkX - 1; x <= chunkX + 1; x++) ..._pondsForChunk(x, y),
    ];
    final occupiedParcels = <WorldMapParcel>[
      ...?existingParcels,
      if (generationVersion == legacyGenerationVersion)
        for (var y = chunkY - 1; y <= chunkY + 1; y++)
          for (var x = chunkX - 1; x <= chunkX + 1; x++)
            ..._parcelsForDistrict(
              (x / chunksPerDistrict).floor(),
              (y / chunksPerDistrict).floor(),
            ).where(
              (parcel) =>
                  (parcel.center.x / farmWorldChunkSize).floor() == x &&
                  (parcel.center.y / farmWorldChunkSize).floor() == y,
            ),
    ];
    if (generationVersion >= collisionSafeGenerationVersion) {
      occupiedParcels.addAll(_protectedOwnedParcels);
    }

    for (var attempt = 0; attempt < 24; attempt++) {
      final center = WorldMapPoint(
        left + 64 + random.nextDouble() * (farmWorldChunkSize - 128),
        top + 64 + random.nextDouble() * (farmWorldChunkSize - 128),
      );
      final mountain = WorldMapMountain(
        center: center,
        width: 260 + random.nextDouble() * 190,
        height: 190 + random.nextDouble() * 150,
        ridgeAngle: (random.nextDouble() - 0.5) * 0.55,
      );
      final radius =
          sqrt(
            mountain.width * mountain.width + mountain.height * mountain.height,
          ) /
          2;
      final roadConflict = roads.any((road) {
        for (var index = 0; index < road.points.length - 1; index++) {
          if (WorldMapParcel._distanceToSegment(
                center,
                road.points[index],
                road.points[index + 1],
              ) <
              radius + road.width / 2 + 20) {
            return true;
          }
        }
        return false;
      });
      final waterConflict =
          nearbyPonds.any((pond) {
            final expandedX = mountain.width / 2 + pond.width / 2 + 18;
            final expandedY = mountain.height / 2 + pond.height / 2 + 18;
            final x = (center.x - pond.center.x) / expandedX;
            final y = (center.y - pond.center.y) / expandedY;
            return x * x + y * y <= 1;
          }) ||
          generationVersion >= geographicRedesignGenerationVersion &&
              lakes.any((lake) {
                final expanded = lake.bounds.inflate(radius + 22);
                return expanded.contains(Offset(center.x, center.y));
              }) ||
          generationVersion >= collisionSafeGenerationVersion &&
              _baseWatercourses.any((watercourse) {
                final clearance = radius + watercourse.width / 2 + 22;
                for (
                  var index = 0;
                  index < watercourse.points.length - 1;
                  index++
                ) {
                  if (WorldMapParcel._distanceToSegment(
                        center,
                        watercourse.points[index],
                        watercourse.points[index + 1],
                      ) <=
                      clearance) {
                    return true;
                  }
                }
                return false;
              });
      final parcelConflict = occupiedParcels.any((parcel) {
        final x = (parcel.center.x - center.x).abs();
        final y = (parcel.center.y - center.y).abs();
        return x < (parcel.width + mountain.width) / 2 + 24 &&
            y < (parcel.height + mountain.height) / 2 + 24;
      });
      if (roadConflict || waterConflict || parcelConflict) continue;
      final result = List<WorldMapMountain>.unmodifiable([mountain]);
      _mountainCache[key] = result;
      return result;
    }
    _mountainCache[key] = const [];
    return const [];
  }

  bool _hasRoadClearance(WorldMapParcel parcel) {
    final vertices = parcel.worldVertices;
    final parcelBounds = _boundsOfPoints(vertices);
    const maximumRoadBuffer = 25.0 / 2 + 6.5 + 46;
    final roads = roadSegmentsInBounds(
      parcelBounds.left - maximumRoadBuffer,
      parcelBounds.top - maximumRoadBuffer,
      parcelBounds.right + maximumRoadBuffer,
      parcelBounds.bottom + maximumRoadBuffer,
    );
    for (final road in roads) {
      final requiredDistance =
          road.width / 2 + 6.5 + _fieldRoadShoulderBufferMeters;
      for (var index = 0; index < road.points.length - 1; index++) {
        final start = road.points[index];
        final end = road.points[index + 1];
        final roadBounds = Rect.fromLTRB(
          min(start.x, end.x),
          min(start.y, end.y),
          max(start.x, end.x),
          max(start.y, end.y),
        ).inflate(requiredDistance);
        if (_boundsDisjoint(parcelBounds, roadBounds)) continue;
        if (_pointInPolygon(start, vertices) ||
            _pointInPolygon(end, vertices)) {
          return false;
        }
        for (var edge = 0; edge < vertices.length; edge++) {
          if (_segmentDistance(
                start,
                end,
                vertices[edge],
                vertices[(edge + 1) % vertices.length],
              ) <=
              requiredDistance) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _parcelOverlapsPond(
    WorldMapParcel parcel,
    WorldMapPond pond,
    double buffer,
  ) {
    final vertices = parcel.worldVertices;
    if (vertices.length < 3) return false;
    final radiusX = pond.width / 2 + buffer;
    final radiusY = pond.height / 2 + buffer;
    final expandedBounds = Rect.fromCenter(
      center: Offset(pond.center.x, pond.center.y),
      width: radiusX * 2,
      height: radiusY * 2,
    );
    if (_boundsDisjoint(_boundsOfPoints(vertices), expandedBounds)) {
      return false;
    }
    if (_pointInPolygon(pond.center, vertices)) return true;
    for (final point in vertices) {
      final x = (point.x - pond.center.x) / radiusX;
      final y = (point.y - pond.center.y) / radiusY;
      if (x * x + y * y <= 1) return true;
    }
    for (var index = 0; index < vertices.length; index++) {
      final start = vertices[index];
      final end = vertices[(index + 1) % vertices.length];
      final startX = (start.x - pond.center.x) / radiusX;
      final startY = (start.y - pond.center.y) / radiusY;
      final endX = (end.x - pond.center.x) / radiusX;
      final endY = (end.y - pond.center.y) / radiusY;
      final dx = endX - startX;
      final dy = endY - startY;
      final lengthSquared = dx * dx + dy * dy;
      final t = lengthSquared == 0
          ? 0.0
          : (-(startX * dx + startY * dy) / lengthSquared)
                .clamp(0.0, 1.0)
                .toDouble();
      final nearestX = startX + dx * t;
      final nearestY = startY + dy * t;
      if (nearestX * nearestX + nearestY * nearestY <= 1) return true;
    }
    return false;
  }

  List<WorldMapPond> _pondsForChunk(int chunkX, int chunkY) {
    final random = Random(_stableHash('$seed|ponds|$chunkX|$chunkY'));
    if (generationVersion >= geographicRedesignGenerationVersion) {
      final region = regionAt(
        WorldMapPoint(
          (chunkX + 0.5) * farmWorldChunkSize,
          (chunkY + 0.5) * farmWorldChunkSize,
        ),
      );
      final wetlandChance = region?.id == 'southern_meadows' ? 8 : 15;
      if (random.nextInt(wetlandChance) != 0) return const [];
    } else if (random.nextInt(7) != 0) {
      return const [];
    }
    final redesigned = generationVersion >= collisionSafeGenerationVersion;
    final attempts = redesigned ? 12 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final pond = WorldMapPond(
        center: WorldMapPoint(
          chunkX * farmWorldChunkSize + 120 + random.nextDouble() * 390,
          chunkY * farmWorldChunkSize + 120 + random.nextDouble() * 390,
        ),
        width: 70 + random.nextDouble() * 100,
        height: 48 + random.nextDouble() * 60,
      );
      if (!redesigned || !_pondConflictsWithProtectedFeatures(pond)) {
        return [pond];
      }
    }
    return const [];
  }

  bool _pondConflictsWithProtectedFeatures(WorldMapPond pond) {
    if (_protectedOwnedParcels.any(
      (parcel) => _parcelOverlapsPond(parcel, pond, _pondFieldBankBufferMeters),
    )) {
      return true;
    }
    final pondRadius = max(pond.width, pond.height) / 2;
    final searchBounds = Rect.fromCenter(
      center: Offset(pond.center.x, pond.center.y),
      width: pond.width + _pondFieldBankBufferMeters * 2,
      height: pond.height + _pondFieldBankBufferMeters * 2,
    );
    for (final (x, y) in _districtIndicesNear(searchBounds, 1600)) {
      final anchor = x == 0 && y == 0
          ? const WorldMapPoint(0, 155)
          : _rawDistrictAnchor(x, y);
      final kind = _settlementKindForDistrict(x, y);
      if (pond.center.distanceTo(anchor) <=
          _settlementKeepoutRadius(kind) + pondRadius + 80) {
        return true;
      }
    }
    for (final lake in _baseLakes) {
      if (lake.bounds.inflate(pondRadius + 40).overlaps(searchBounds)) {
        return true;
      }
    }
    for (final watercourse in _baseWatercourses) {
      final clearance = pondRadius + watercourse.width / 2 + 48;
      for (var index = 0; index < watercourse.points.length - 1; index++) {
        if (WorldMapParcel._distanceToSegment(
              pond.center,
              watercourse.points[index],
              watercourse.points[index + 1],
            ) <=
            clearance) {
          return true;
        }
      }
    }
    return false;
  }

  Iterable<(int, int)> _districtIndicesNear(Rect bounds, double padding) sync* {
    final firstX = ((bounds.left - padding) / districtSize).floor();
    final lastX = ((bounds.right + padding) / districtSize).floor();
    final firstY = ((bounds.top - padding) / districtSize).floor();
    final lastY = ((bounds.bottom + padding) / districtSize).floor();
    for (var y = firstY; y <= lastY; y++) {
      for (var x = firstX; x <= lastX; x++) {
        yield (x, y);
      }
    }
  }

  List<WorldMapLake> _lakesForChunk(int chunkX, int chunkY) {
    final chunkBounds = Rect.fromLTWH(
      chunkX * farmWorldChunkSize,
      chunkY * farmWorldChunkSize,
      farmWorldChunkSize,
      farmWorldChunkSize,
    );
    return lakes
        .where((lake) => lake.bounds.overlaps(chunkBounds))
        .toList(growable: false);
  }

  bool _treeOverlapsLake(
    WorldMapPoint point,
    double treeRadius,
    List<WorldMapLake> lakes,
  ) {
    for (final lake in lakes) {
      final bounds = lake.bounds.inflate(treeRadius + 18);
      if (bounds.contains(Offset(point.x, point.y))) return true;
    }
    return false;
  }

  bool _treeOverlapsWatercourse(
    WorldMapPoint point,
    double treeRadius,
    List<WorldMapWatercourse> watercourses,
  ) {
    for (final watercourse in watercourses) {
      final clearance = treeRadius + watercourse.width / 2 + 28;
      for (var index = 0; index < watercourse.points.length - 1; index++) {
        final start = watercourse.points[index];
        final end = watercourse.points[index + 1];
        if (point.x < min(start.x, end.x) - clearance ||
            point.x > max(start.x, end.x) + clearance ||
            point.y < min(start.y, end.y) - clearance ||
            point.y > max(start.y, end.y) + clearance) {
          continue;
        }
        if (WorldMapParcel._distanceToSegment(point, start, end) < clearance) {
          return true;
        }
      }
    }
    return false;
  }

  bool _parcelOverlapsLake(WorldMapParcel parcel, WorldMapLake lake) {
    final field = parcel.worldVertices;
    final shore = lake.shoreline;
    if (field.length < 3 || shore.length < 3) return false;
    if (_boundsDisjoint(
      _boundsOfPoints(field).inflate(_lakeFieldBankBufferMeters),
      lake.bounds,
    )) {
      return false;
    }
    if (_pointInPolygon(field.first, shore) ||
        _pointInPolygon(shore.first, field)) {
      return true;
    }

    for (var fieldIndex = 0; fieldIndex < field.length; fieldIndex++) {
      final fieldStart = field[fieldIndex];
      final fieldEnd = field[(fieldIndex + 1) % field.length];
      for (var shoreIndex = 0; shoreIndex < shore.length; shoreIndex++) {
        final shoreStart = shore[shoreIndex];
        final shoreEnd = shore[(shoreIndex + 1) % shore.length];
        if (_segmentDistance(fieldStart, fieldEnd, shoreStart, shoreEnd) <=
            _lakeFieldBankBufferMeters) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _pointInPolygon(
    WorldMapPoint point,
    List<WorldMapPoint> vertices,
  ) {
    var inside = false;
    for (
      var index = 0, previous = vertices.length - 1;
      index < vertices.length;
      previous = index++
    ) {
      final currentVertex = vertices[index];
      final previousVertex = vertices[previous];
      final crosses =
          (currentVertex.y > point.y) != (previousVertex.y > point.y) &&
          point.x <
              (previousVertex.x - currentVertex.x) *
                      (point.y - currentVertex.y) /
                      (previousVertex.y - currentVertex.y) +
                  currentVertex.x;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  static double _segmentDistance(
    WorldMapPoint firstStart,
    WorldMapPoint firstEnd,
    WorldMapPoint secondStart,
    WorldMapPoint secondEnd,
  ) {
    if (_segmentIntersection(firstStart, firstEnd, secondStart, secondEnd) !=
        null) {
      return 0;
    }
    return min(
      min(
        WorldMapParcel._distanceToSegment(firstStart, secondStart, secondEnd),
        WorldMapParcel._distanceToSegment(firstEnd, secondStart, secondEnd),
      ),
      min(
        WorldMapParcel._distanceToSegment(secondStart, firstStart, firstEnd),
        WorldMapParcel._distanceToSegment(secondEnd, firstStart, firstEnd),
      ),
    );
  }

  bool _parcelOverlapsWatercourse(
    WorldMapParcel parcel, [
    WorldMapWatercourse? onlyWatercourse,
  ]) {
    final vertices = parcel.worldVertices;
    if (vertices.length < 3) return false;
    final parcelBounds = _boundsOfPoints(vertices);
    final candidates = onlyWatercourse == null
        ? _baseWatercourses
        : [onlyWatercourse];
    for (final watercourse in candidates) {
      final clearance =
          watercourse.width / 2 + _watercourseFieldBankBufferMeters;
      if (_boundsDisjoint(
        parcelBounds.inflate(clearance),
        _boundsOfPoints(watercourse.points),
      )) {
        continue;
      }
      for (var index = 0; index < watercourse.points.length - 1; index++) {
        final start = watercourse.points[index];
        final end = watercourse.points[index + 1];
        if (_pointInPolygon(start, vertices) ||
            _pointInPolygon(end, vertices)) {
          return true;
        }
        for (final vertex in vertices) {
          if (WorldMapParcel._distanceToSegment(vertex, start, end) <=
              clearance) {
            return true;
          }
        }
        for (var edge = 0; edge < vertices.length; edge++) {
          if (_segmentDistance(
                start,
                end,
                vertices[edge],
                vertices[(edge + 1) % vertices.length],
              ) <=
              clearance) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<WorldMapWatercourse> _watercourseSegmentsClearOfParcels(
    WorldMapWatercourse watercourse,
    List<WorldMapParcel> protectedParcels,
  ) {
    if (protectedParcels.isEmpty ||
        protectedParcels.every(
          (parcel) => !_parcelOverlapsWatercourse(parcel, watercourse),
        )) {
      return [watercourse];
    }

    const maxSegmentLength = 32.0;
    final clearance = watercourse.width / 2 + _watercourseFieldBankBufferMeters;
    final visibleRuns = <List<WorldMapPoint>>[];
    final visibleRunStarts = <int>[];
    var runPoints = <WorldMapPoint>[];
    var runStartIndex = 0;
    var sourceSegmentIndex = 0;

    void finishRun() {
      if (runPoints.length >= 2 &&
          runPoints.first.distanceTo(runPoints.last) > 0.1) {
        visibleRuns.add(List.unmodifiable(runPoints));
        visibleRunStarts.add(runStartIndex);
      }
      runPoints = <WorldMapPoint>[];
    }

    for (var index = 0; index < watercourse.points.length - 1; index++) {
      final segmentStart = watercourse.points[index];
      final segmentEnd = watercourse.points[index + 1];
      final segmentLength = segmentStart.distanceTo(segmentEnd);
      if (segmentLength <= 0.001) continue;

      final subdivisions = max(
        1,
        (segmentLength / maxSegmentLength).ceil(),
      ).toInt();
      for (var subdivision = 0; subdivision < subdivisions; subdivision++) {
        final startT = subdivision / subdivisions;
        final endT = (subdivision + 1) / subdivisions;
        final start = WorldMapPoint(
          segmentStart.x + (segmentEnd.x - segmentStart.x) * startT,
          segmentStart.y + (segmentEnd.y - segmentStart.y) * startT,
        );
        final end = WorldMapPoint(
          segmentStart.x + (segmentEnd.x - segmentStart.x) * endT,
          segmentStart.y + (segmentEnd.y - segmentStart.y) * endT,
        );
        final blocked = protectedParcels.any(
          (parcel) => _watercourseSegmentConflictsWithParcel(
            start,
            end,
            parcel,
            clearance,
          ),
        );
        if (blocked) {
          finishRun();
        } else {
          if (runPoints.isEmpty) {
            runStartIndex = sourceSegmentIndex;
            runPoints.add(start);
          } else if (runPoints.last.distanceTo(start) > 0.1) {
            runPoints.add(start);
          }
          if (runPoints.last.distanceTo(end) > 0.1) runPoints.add(end);
        }
        sourceSegmentIndex++;
      }
    }
    finishRun();

    return [
      for (var index = 0; index < visibleRuns.length; index++)
        WorldMapWatercourse(
          id: visibleRunStarts[index] == 0
              ? watercourse.id
              : '${watercourse.id}:segment:${visibleRunStarts[index]}',
          name: watercourse.name,
          type: watercourse.type,
          points: visibleRuns[index],
          width: watercourse.width,
        ),
    ];
  }

  bool _watercourseSegmentConflictsWithParcel(
    WorldMapPoint start,
    WorldMapPoint end,
    WorldMapParcel parcel,
    double clearance,
  ) {
    final vertices = parcel.worldVertices;
    if (vertices.length < 3) return false;
    final segmentBounds = Rect.fromLTRB(
      min(start.x, end.x),
      min(start.y, end.y),
      max(start.x, end.x),
      max(start.y, end.y),
    ).inflate(clearance);
    if (_boundsDisjoint(segmentBounds, _boundsOfPoints(vertices))) return false;
    if (_pointInPolygon(start, vertices) || _pointInPolygon(end, vertices)) {
      return true;
    }
    for (var index = 0; index < vertices.length; index++) {
      if (_segmentDistance(
            start,
            end,
            vertices[index],
            vertices[(index + 1) % vertices.length],
          ) <=
          clearance) {
        return true;
      }
    }
    return false;
  }

  List<WorldMapPointOfInterest> _pointsOfInterestForChunk(
    int chunkX,
    int chunkY,
  ) {
    final point = _pointOfInterestPlacementForChunk(chunkX, chunkY);
    if (point == null) return const [];
    if (generationVersion >= collisionSafeGenerationVersion) {
      for (var y = chunkY - 1; y <= chunkY + 1; y++) {
        for (var x = chunkX - 1; x <= chunkX + 1; x++) {
          if (x == chunkX && y == chunkY) continue;
          final neighbor = _pointOfInterestPlacementForChunk(x, y);
          if (neighbor == null || !_pointOfInterestsOverlap(point, neighbor)) {
            continue;
          }
          if (!_pointOfInterestChunkHasPriority(chunkX, chunkY, x, y)) {
            return const [];
          }
        }
      }
    }
    return [point];
  }

  WorldMapPointOfInterest? _pointOfInterestPlacementForChunk(
    int chunkX,
    int chunkY,
  ) {
    final cacheKey = '$chunkX:$chunkY';
    if (_pointOfInterestPlacementCache.containsKey(cacheKey)) {
      return _pointOfInterestPlacementCache[cacheKey];
    }
    final random = Random(_stableHash('$seed|poi|$chunkX|$chunkY'));
    if (random.nextInt(
          generationVersion >= geographicRedesignGenerationVersion ? 8 : 5,
        ) !=
        0) {
      _pointOfInterestPlacementCache[cacheKey] = null;
      return null;
    }
    final type = generationVersion >= geographicRedesignGenerationVersion
        ? const [
            WorldPointOfInterestType.water,
            WorldPointOfInterestType.mill,
            WorldPointOfInterestType.timberYard,
          ][random.nextInt(3)]
        : WorldPointOfInterestType.values[random.nextInt(
            WorldPointOfInterestType.values.length,
          )];
    final attempts = generationVersion >= collisionSafeGenerationVersion
        ? 12
        : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final generatedPosition = WorldMapPoint(
        chunkX * farmWorldChunkSize + 140 + random.nextDouble() * 360,
        chunkY * farmWorldChunkSize + 140 + random.nextDouble() * 360,
      );
      final roadPosition =
          generationVersion >= geographicRedesignGenerationVersion
          ? _nearestRoadPosition(generatedPosition, maxDistance: 280)
          : null;
      if (generationVersion >= geographicRedesignGenerationVersion &&
          roadPosition == null) {
        continue;
      }
      WorldMapPoint position;
      if (roadPosition != null) {
        final footprint = _pointOfInterestFootprint(type);
        final road = _nearestRoadAt(roadPosition, searchRadius: 18);
        final roadWidth = road?.width ?? 20.0;
        final offsetDist = roadWidth / 2 + footprint * 0.55 + 16.0;
        final dx = generatedPosition.x - roadPosition.x;
        final dy = generatedPosition.y - roadPosition.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len > 0.001) {
          position = WorldMapPoint(
            roadPosition.x + (dx / len) * offsetDist,
            roadPosition.y + (dy / len) * offsetDist,
          );
        } else {
          position = WorldMapPoint(roadPosition.x + offsetDist, roadPosition.y);
        }
      } else {
        position = generatedPosition;
      }
      if (generationVersion >= collisionSafeGenerationVersion &&
          _pointOfInterestConflicts(position, type)) {
        continue;
      }
      final point = WorldMapPointOfInterest(
        id: 'poi:$chunkX:$chunkY',
        name: _poiName(type),
        type: type,
        position: position,
      );
      _pointOfInterestPlacementCache[cacheKey] = point;
      return point;
    }
    _pointOfInterestPlacementCache[cacheKey] = null;
    return null;
  }

  bool _pointOfInterestsOverlap(
    WorldMapPointOfInterest left,
    WorldMapPointOfInterest right,
  ) =>
      left.position.distanceTo(right.position) <
      _pointOfInterestFootprint(left.type) +
          _pointOfInterestFootprint(right.type) +
          36;

  bool _pointOfInterestChunkHasPriority(
    int chunkX,
    int chunkY,
    int otherChunkX,
    int otherChunkY,
  ) {
    final priority = _stableHash('$seed|poi-priority|$chunkX|$chunkY');
    final otherPriority = _stableHash(
      '$seed|poi-priority|$otherChunkX|$otherChunkY',
    );
    if (priority != otherPriority) return priority < otherPriority;
    if (chunkX != otherChunkX) return chunkX < otherChunkX;
    return chunkY < otherChunkY;
  }

  double _pointOfInterestFootprint(WorldPointOfInterestType type) =>
      switch (type) {
        WorldPointOfInterestType.water => 58,
        WorldPointOfInterestType.village => 108,
        WorldPointOfInterestType.mill => 78,
        WorldPointOfInterestType.timberYard => 88,
      };

  bool _pointOfInterestConflicts(
    WorldMapPoint position,
    WorldPointOfInterestType type,
  ) {
    final footprint = _pointOfInterestFootprint(type);
    final bounds = Rect.fromCircle(
      center: Offset(position.x, position.y),
      radius: footprint + 40,
    );
    if (_protectedOwnedParcels.any(
      (parcel) => _parcelIntersectsCircle(parcel, position, footprint + 32),
    )) {
      return true;
    }
    if (_settlementFootprintsWithin(bounds.inflate(260)).any(
      (settlement) =>
          position.distanceTo(settlement.$1) < footprint + settlement.$2 + 36,
    )) {
      return true;
    }
    for (final lake in lakes) {
      if (lake.bounds
          .inflate(footprint + 24)
          .contains(Offset(position.x, position.y))) {
        return true;
      }
    }
    if (_treeOverlapsWatercourse(position, footprint, watercourses)) {
      return true;
    }
    final chunkX = (position.x / farmWorldChunkSize).floor();
    final chunkY = (position.y / farmWorldChunkSize).floor();
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        if (_pondsForChunk(x, y).any(
          (pond) => _pointWithinEllipse(
            position,
            pond.center,
            pond.width / 2 + footprint + 24,
            pond.height / 2 + footprint + 24,
          ),
        )) {
          return true;
        }
        if (_mountainsForChunk(x, y).any(
          (mountain) => _pointWithinEllipse(
            position,
            mountain.center,
            mountain.width / 2 + footprint + 20,
            mountain.height / 2 + footprint + 20,
          ),
        )) {
          return true;
        }
      }
    }
    final nearbyRoads = roadSegmentsInBounds(
      position.x - footprint - 30,
      position.y - footprint - 30,
      position.x + footprint + 30,
      position.y + footprint + 30,
    );
    for (final road in nearbyRoads) {
      final reqDist = road.width / 2 + footprint * 0.5 + 6.0;
      for (var i = 0; i < road.points.length - 1; i++) {
        if (WorldMapParcel._distanceToSegment(
              position,
              road.points[i],
              road.points[i + 1],
            ) <=
            reqDist) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _pointWithinEllipse(
    WorldMapPoint point,
    WorldMapPoint center,
    double radiusX,
    double radiusY,
  ) {
    final x = (point.x - center.x) / radiusX;
    final y = (point.y - center.y) / radiusY;
    return x * x + y * y <= 1;
  }

  List<WorldMapRoad> roadSegmentsInBounds(
    double left,
    double top,
    double right,
    double bottom, {
    bool includeLocal = true,
  }) {
    if (_roadCache.length > 1536) _roadCache.clear();
    final roadsById = <String, WorldMapRoad>{};
    final firstDistrictX = (left / districtSize).floor() - 1;
    final lastDistrictX = (right / districtSize).ceil() + 1;
    final firstDistrictY = (top / districtSize).floor() - 1;
    final lastDistrictY = (bottom / districtSize).ceil() + 1;
    for (var y = firstDistrictY; y <= lastDistrictY; y++) {
      for (var x = firstDistrictX; x <= lastDistrictX; x++) {
        for (final road in _districtRoadsAt(x, y)) {
          roadsById[road.id] = road;
        }
      }
    }

    if (includeLocal) {
      final firstChunkX = (left / farmWorldChunkSize).floor() - 1;
      final lastChunkX = (right / farmWorldChunkSize).ceil() + 1;
      final firstChunkY = (top / farmWorldChunkSize).floor() - 1;
      final lastChunkY = (bottom / farmWorldChunkSize).ceil() + 1;
      for (var y = firstChunkY; y <= lastChunkY; y++) {
        for (var x = firstChunkX; x <= lastChunkX; x++) {
          for (final road in _localRoadsAt(x, y)) {
            roadsById[road.id] = road;
          }
        }
      }
    }
    return List.unmodifiable(roadsById.values);
  }

  List<WorldMapRoad> _districtRoadsAt(int x, int y) {
    final key = 'district:$x:$y';
    return _roadCache.putIfAbsent(key, () {
      final roads = <WorldMapRoad>[];
      final horizontalId = 'district:$x:$y:${x + 1}:$y';
      final horizontalVariant = _stableHash('$seed|$horizontalId|class') % 100;
      final isStarterCityNode =
          generationVersion >= geographicRedesignGenerationVersion &&
          x == 0 &&
          y == 0;
      final horizontalConnectsIsolatedHub =
          generationVersion >= geographicRedesignGenerationVersion &&
          (!_districtNodeHasBaseRoad(x, y) ||
              !_districtNodeHasBaseRoad(x + 1, y));
      if (generationVersion >= collisionSafeGenerationVersion ||
          horizontalVariant < 91 ||
          isStarterCityNode ||
          horizontalConnectsIsolatedHub) {
        final road = _makeRoad(
          horizontalId,
          _districtHub(x, y),
          _districtHub(x + 1, y),
          horizontalVariant < 56
              ? WorldMapRoadType.arterial
              : WorldMapRoadType.secondary,
          bendScale: 0.18,
        );
        if (road != null) roads.add(road);
      }
      final verticalId = 'district:$x:$y:$x:${y + 1}';
      final verticalVariant = _stableHash('$seed|$verticalId|class') % 100;
      final verticalConnectsIsolatedHub =
          generationVersion >= geographicRedesignGenerationVersion &&
          (!_districtNodeHasBaseRoad(x, y) ||
              !_districtNodeHasBaseRoad(x, y + 1));
      if (generationVersion >= collisionSafeGenerationVersion ||
          verticalVariant < 91 ||
          isStarterCityNode ||
          verticalConnectsIsolatedHub) {
        final road = _makeRoad(
          verticalId,
          _districtHub(x, y),
          _districtHub(x, y + 1),
          verticalVariant < 56
              ? WorldMapRoadType.arterial
              : WorldMapRoadType.secondary,
          bendScale: 0.18,
        );
        if (road != null) roads.add(road);
      }
      if (generationVersion >= collisionSafeGenerationVersion &&
          _settlementPositionForDistrict(x, y) != null) {
        final gate = _settlementAccessGate(x, y)!;
        final accessRoad = _makeRoad(
          'settlement-access:$x:$y',
          gate,
          _districtHub(x, y),
          WorldMapRoadType.dirt,
          bendScale: 0,
          maxBend: 0,
        );
        if (accessRoad != null) roads.add(accessRoad);
      }
      return List.unmodifiable(roads);
    });
  }

  bool _districtNodeHasBaseRoad(int x, int y) {
    final incidentRoadIds = [
      'district:$x:$y:${x + 1}:$y',
      'district:${x - 1}:$y:$x:$y',
      'district:$x:$y:$x:${y + 1}',
      'district:$x:${y - 1}:$x:$y',
    ];
    return incidentRoadIds.any(
      (id) => _stableHash('$seed|$id|class') % 100 < 91,
    );
  }

  List<WorldMapRoad> _localRoadsAt(int chunkX, int chunkY) {
    final key = 'local-chunk:$chunkX:$chunkY';
    return _roadCache.putIfAbsent(key, () {
      final left = chunkX * farmWorldChunkSize;
      final top = chunkY * farmWorldChunkSize;
      final localRandom = Random(
        _stableHash('$seed|local-node:$chunkX:$chunkY'),
      );
      var junction = WorldMapPoint(
        left + 205 + localRandom.nextDouble() * 230,
        top + 205 + localRandom.nextDouble() * 230,
      );
      final districtX = ((left + farmWorldChunkSize / 2) / districtSize)
          .floor();
      final districtY = ((top + farmWorldChunkSize / 2) / districtSize).floor();
      final districtHub = _districtHub(districtX, districtY);
      final settlementPosition = _settlementPositionForDistrict(
        districtX,
        districtY,
      );
      if (settlementPosition != null &&
          (settlementPosition.x / farmWorldChunkSize).floor() == chunkX &&
          (settlementPosition.y / farmWorldChunkSize).floor() == chunkY) {
        final gate = _settlementAccessGate(districtX, districtY);
        if (gate != null) junction = gate;
      } else if ((districtHub.x / farmWorldChunkSize).floor() == chunkX &&
          (districtHub.y / farmWorldChunkSize).floor() == chunkY) {
        junction = districtHub;
      }

      const sides = ['north', 'east', 'south', 'west'];
      final roads = <WorldMapRoad>[];
      for (final side in sides) {
        final gate = _roadGate(chunkX, chunkY, side);
        if (gate == null) continue;
        final styleRoll = _stableHash('$seed|${gate.id}|class') % 100;
        final type = styleRoll < 22
            ? WorldMapRoadType.secondary
            : styleRoll < 72
            ? WorldMapRoadType.dirt
            : WorldMapRoadType.trail;
        final road = _makeRoad(
          'local:$chunkX:$chunkY:$side',
          gate.position,
          junction,
          type,
          bendScale: 0.24,
          maxBend: 72,
        );
        if (road != null) roads.add(road);
      }
      return List.unmodifiable(roads);
    });
  }

  ({String id, WorldMapPoint position})? _roadGate(
    int chunkX,
    int chunkY,
    String side,
  ) {
    final left = chunkX * farmWorldChunkSize;
    final top = chunkY * farmWorldChunkSize;
    late final String edgeId;
    late final WorldMapPoint position;
    switch (side) {
      case 'north':
        edgeId = 'horizontal:$chunkY:$chunkX';
        final random = Random(_stableHash('$seed|gate-position:$edgeId'));
        position = WorldMapPoint(
          left + 76 + random.nextDouble() * (farmWorldChunkSize - 152),
          top,
        );
      case 'east':
        edgeId = 'vertical:${chunkX + 1}:$chunkY';
        final random = Random(_stableHash('$seed|gate-position:$edgeId'));
        position = WorldMapPoint(
          left + farmWorldChunkSize,
          top + 76 + random.nextDouble() * (farmWorldChunkSize - 152),
        );
      case 'south':
        edgeId = 'horizontal:${chunkY + 1}:$chunkX';
        final random = Random(_stableHash('$seed|gate-position:$edgeId'));
        position = WorldMapPoint(
          left + 76 + random.nextDouble() * (farmWorldChunkSize - 152),
          top + farmWorldChunkSize,
        );
      default:
        edgeId = 'vertical:$chunkX:$chunkY';
        final random = Random(_stableHash('$seed|gate-position:$edgeId'));
        position = WorldMapPoint(
          left,
          top + 76 + random.nextDouble() * (farmWorldChunkSize - 152),
        );
    }
    final gateRandom = Random(_stableHash('$seed|gate-presence:$edgeId'));
    if (gateRandom.nextDouble() > 0.57) return null;
    return (id: edgeId, position: position);
  }

  WorldMapRoad? _makeRoad(
    String id,
    WorldMapPoint start,
    WorldMapPoint end,
    WorldMapRoadType type, {
    required double bendScale,
    double? maxBend,
  }) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = sqrt(dx * dx + dy * dy);
    final roadWidth = switch (type) {
      WorldMapRoadType.arterial => 25.0,
      WorldMapRoadType.secondary => 16.0,
      WorldMapRoadType.dirt => 10.0,
      WorldMapRoadType.trail => 6.0,
    };
    final perpendicular = length == 0
        ? const WorldMapPoint(0, 0)
        : WorldMapPoint(-dy / length, dx / length);
    final random = Random(_stableHash('$seed|curve:$id'));
    final bendLimit = maxBend ?? length * bendScale;
    final bend = (random.nextDouble() * 2 - 1) * bendLimit;
    final control2Ratio = random.nextDouble() * 0.45 + 0.35;
    const sampleCount = 48;
    List<WorldMapPoint> sampleRoad(double candidateBend) {
      final control1 = WorldMapPoint(
        start.x + dx * 0.32 + perpendicular.x * candidateBend,
        start.y + dy * 0.32 + perpendicular.y * candidateBend,
      );
      final control2Bend = candidateBend * control2Ratio;
      final control2 = WorldMapPoint(
        start.x + dx * 0.68 + perpendicular.x * control2Bend,
        start.y + dy * 0.68 + perpendicular.y * control2Bend,
      );
      final points = <WorldMapPoint>[];
      for (var step = 0; step <= sampleCount; step++) {
        final t = step / sampleCount;
        final inverse = 1 - t;
        final a = inverse * inverse * inverse;
        final b = 3 * inverse * inverse * t;
        final c = 3 * inverse * t * t;
        final d = t * t * t;
        points.add(
          WorldMapPoint(
            a * start.x + b * control1.x + c * control2.x + d * end.x,
            a * start.y + b * control1.y + c * control2.y + d * end.y,
          ),
        );
      }
      return points;
    }

    var points = sampleRoad(bend);
    if (generationVersion >= geographicRedesignGenerationVersion &&
        _roadConflictsWithRelief(
          points,
          roadWidth,
          allowRiverCrossings: type != WorldMapRoadType.trail,
        )) {
      final alternativeBends = [
        -bend,
        bendLimit * 0.45,
        -bendLimit * 0.45,
        bendLimit * 0.7,
        -bendLimit * 0.7,
        bendLimit * 0.9,
        -bendLimit * 0.9,
        bendLimit * 1.35,
        -bendLimit * 1.35,
        bendLimit * 1.8,
        -bendLimit * 1.8,
        bendLimit * 2.2,
        -bendLimit * 2.2,
        bendLimit * 2.7,
        -bendLimit * 2.7,
        bendLimit * 3,
        -bendLimit * 3,
      ];
      for (final alternative in alternativeBends) {
        final detour = sampleRoad(alternative);
        if (!_roadConflictsWithRelief(
          detour,
          roadWidth,
          allowRiverCrossings: type != WorldMapRoadType.trail,
        )) {
          points = detour;
          break;
        }
      }
      if (_roadConflictsWithRelief(
        points,
        roadWidth,
        allowRiverCrossings: type != WorldMapRoadType.trail,
      )) {
        final reliefRoute = _findReliefSafeRoadPath(
          start,
          end,
          roadWidth,
          allowRiverCrossings: type != WorldMapRoadType.trail,
        );
        if (reliefRoute == null) return null;
        points = reliefRoute;
      }
    }
    if (generationVersion >= geographicRedesignGenerationVersion &&
        _roadConflictsWithRelief(
          points,
          roadWidth,
          allowRiverCrossings: type != WorldMapRoadType.trail,
        )) {
      return null;
    }
    return WorldMapRoad(id: id, type: type, points: List.unmodifiable(points));
  }

  bool _roadConflictsWithRelief(
    List<WorldMapPoint> points,
    double roadWidth, {
    required bool allowRiverCrossings,
  }) {
    if (points.isEmpty) return false;
    final clearance = roadWidth / 2 + 20;
    final bounds = _boundsOfPoints(points).inflate(420);
    final mountains = _mountainEnvelopes(_mountainsWithin(bounds), clearance);
    final lakeList = _baseLakes
        .map(
          (lake) => lake.bounds.inflate(_lakeRoadBankBufferMeters + clearance),
        )
        .toList();
    final pondList = _pondEnvelopesWithin(bounds, roadWidth / 2 + 20);
    final watercourseList = generationVersion >= collisionSafeGenerationVersion
        ? watercourses
        : const <WorldMapWatercourse>[];
    final protectedAreas = generationVersion >= collisionSafeGenerationVersion
        ? _roadProtectedAreas(bounds, roadWidth)
        : const <Rect>[];
    for (var index = 0; index < points.length - 1; index++) {
      if (_roadSegmentConflictsWithRelief(
        points[index],
        points[index + 1],
        lakeList,
        pondList,
        watercourseList,
        mountains,
        protectedAreas,
        roadWidth,
        allowRiverCrossings,
      )) {
        return true;
      }
    }
    return points.length == 1 &&
        _roadSegmentConflictsWithRelief(
          points.single,
          points.single,
          lakeList,
          pondList,
          watercourseList,
          mountains,
          protectedAreas,
          roadWidth,
          allowRiverCrossings,
        );
  }

  List<_RoadEllipseEnvelope> _pondEnvelopesWithin(
    Rect bounds,
    double clearance,
  ) {
    final firstChunkX = ((bounds.left - 400) / farmWorldChunkSize).floor();
    final lastChunkX = ((bounds.right + 400) / farmWorldChunkSize).ceil();
    final firstChunkY = ((bounds.top - 400) / farmWorldChunkSize).floor();
    final lastChunkY = ((bounds.bottom + 400) / farmWorldChunkSize).ceil();
    return [
      for (var y = firstChunkY; y <= lastChunkY; y++)
        for (var x = firstChunkX; x <= lastChunkX; x++)
          for (final pond in _pondsForChunk(x, y))
            _RoadEllipseEnvelope(
              center: pond.center,
              radiusX: pond.width / 2 + clearance,
              radiusY: pond.height / 2 + clearance,
            ),
    ];
  }

  List<Rect> _roadProtectedAreas(Rect bounds, double roadWidth) {
    final areaBounds = bounds.inflate(900);
    final settlements = _settlementFootprintsWithin(areaBounds);
    final settlementKeepouts = [
      for (final footprint in settlements)
        Rect.fromCircle(
          center: Offset(footprint.$1.x, footprint.$1.y),
          radius: footprint.$2 + _settlementRoadBufferMeters + roadWidth / 2,
        ),
    ];
    final ownedParcelKeepouts = [
      for (final parcel in _protectedOwnedParcels)
        if (!_boundsDisjoint(_boundsOfPoints(parcel.worldVertices), areaBounds))
          _boundsOfPoints(parcel.worldVertices)
              .inflate(roadWidth / 2 + _fieldRoadShoulderBufferMeters),
    ];
    return [...settlementKeepouts, ...ownedParcelKeepouts];
  }

  List<WorldMapMountain> _mountainsWithin(Rect bounds) {
    final firstChunkX = ((bounds.left - 400) / farmWorldChunkSize).floor();
    final lastChunkX = ((bounds.right + 400) / farmWorldChunkSize).ceil();
    final firstChunkY = ((bounds.top - 400) / farmWorldChunkSize).floor();
    final lastChunkY = ((bounds.bottom + 400) / farmWorldChunkSize).ceil();
    return [
      for (var y = firstChunkY; y <= lastChunkY; y++)
        for (var x = firstChunkX; x <= lastChunkX; x++)
          ..._mountainsForChunk(x, y),
    ];
  }

  bool _roadSegmentConflictsWithRelief(
    WorldMapPoint start,
    WorldMapPoint end,
    List<Rect> lakeClearances,
    List<_RoadEllipseEnvelope> ponds,
    List<WorldMapWatercourse> watercourses,
    List<_RoadEllipseEnvelope> mountains,
    List<Rect> protectedAreas,
    double roadWidth,
    bool allowRiverCrossings,
  ) {
    final segmentBounds = Rect.fromLTRB(
      min(start.x, end.x),
      min(start.y, end.y),
      max(start.x, end.x),
      max(start.y, end.y),
    ).inflate(0.001);
    for (final lake in lakeClearances) {
      if (_boundsDisjoint(segmentBounds, lake)) continue;
      if (_segmentIntersectsRect(start, end, lake)) return true;
    }
    for (final protectedArea in protectedAreas) {
      if (_boundsDisjoint(segmentBounds, protectedArea)) continue;
      if (_segmentIntersectsRect(start, end, protectedArea)) return true;
    }
    for (final pond in ponds) {
      if (_boundsDisjoint(segmentBounds, pond.bounds)) continue;
      if (_segmentIntersectsEllipse(
        start,
        end,
        pond.center,
        pond.radiusX,
        pond.radiusY,
      )) {
        return true;
      }
    }
    for (final watercourse in watercourses) {
      final crossingMayHaveBridge =
          allowRiverCrossings &&
          watercourse.type != WorldMapWatercourseType.irrigationCanal;
      final requiredDistance = roadWidth / 2 + watercourse.width / 2 + 20;
      for (var index = 0; index < watercourse.points.length - 1; index++) {
        final waterStart = watercourse.points[index];
        final waterEnd = watercourse.points[index + 1];
        final bridgeCenter = _segmentIntersection(
          start,
          end,
          waterStart,
          waterEnd,
        );
        if (bridgeCenter != null && crossingMayHaveBridge) continue;
        if (_segmentDistance(start, end, waterStart, waterEnd) <=
            requiredDistance) {
          return true;
        }
      }
    }
    for (final mountain in mountains) {
      if (_boundsDisjoint(segmentBounds, mountain.bounds)) continue;
      if (_segmentIntersectsEllipse(
        start,
        end,
        mountain.center,
        mountain.radiusX,
        mountain.radiusY,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _boundsDisjoint(Rect first, Rect second) =>
      first.right < second.left ||
      first.left > second.right ||
      first.bottom < second.top ||
      first.top > second.bottom;

  bool _segmentIntersectsRect(
    WorldMapPoint start,
    WorldMapPoint end,
    Rect rect,
  ) {
    if (rect.contains(Offset(start.x, start.y)) ||
        rect.contains(Offset(end.x, end.y))) {
      return true;
    }
    final topLeft = WorldMapPoint(rect.left, rect.top);
    final topRight = WorldMapPoint(rect.right, rect.top);
    final bottomRight = WorldMapPoint(rect.right, rect.bottom);
    final bottomLeft = WorldMapPoint(rect.left, rect.bottom);
    return _segmentIntersection(start, end, topLeft, topRight) != null ||
        _segmentIntersection(start, end, topRight, bottomRight) != null ||
        _segmentIntersection(start, end, bottomRight, bottomLeft) != null ||
        _segmentIntersection(start, end, bottomLeft, topLeft) != null;
  }

  static bool _segmentIntersectsEllipse(
    WorldMapPoint start,
    WorldMapPoint end,
    WorldMapPoint center,
    double radiusX,
    double radiusY,
  ) {
    final startX = (start.x - center.x) / radiusX;
    final startY = (start.y - center.y) / radiusY;
    final deltaX = (end.x - start.x) / radiusX;
    final deltaY = (end.y - start.y) / radiusY;
    final lengthSquared = deltaX * deltaX + deltaY * deltaY;
    final t = lengthSquared == 0
        ? 0.0
        : (-(startX * deltaX + startY * deltaY) / lengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();
    final nearestX = startX + deltaX * t;
    final nearestY = startY + deltaY * t;
    return nearestX * nearestX + nearestY * nearestY <= 1;
  }

  List<_RoadEllipseEnvelope> _mountainEnvelopes(
    List<WorldMapMountain> mountains,
    double clearance,
  ) => [
    for (final mountain in mountains)
      _RoadEllipseEnvelope(
        center: mountain.center,
        radiusX: mountain.width / 2 + clearance,
        radiusY: mountain.height / 2 + clearance,
      ),
  ];

  List<WorldMapPoint>? _findReliefSafeRoadPath(
    WorldMapPoint start,
    WorldMapPoint end,
    double roadWidth, {
    required bool allowRiverCrossings,
  }) {
    const cellSize = 120.0;
    const maximumExpandedNodes = 80000;
    final length = start.distanceTo(end);
    final margin = max(1200.0, min(3600.0, length * 0.72));
    final minColumn = ((min(start.x, end.x) - margin - start.x) / cellSize)
        .floor();
    final maxColumn = ((max(start.x, end.x) + margin - start.x) / cellSize)
        .ceil();
    final minRow = ((min(start.y, end.y) - margin - start.y) / cellSize)
        .floor();
    final maxRow = ((max(start.y, end.y) + margin - start.y) / cellSize).ceil();
    final searchBounds = Rect.fromLTRB(
      start.x + minColumn * cellSize,
      start.y + minRow * cellSize,
      start.x + maxColumn * cellSize,
      start.y + maxRow * cellSize,
    );
    final clearance = roadWidth / 2 + 16;
    final lakeList = _baseLakes
        .map(
          (lake) => lake.bounds.inflate(_lakeRoadBankBufferMeters + clearance),
        )
        .toList();
    final pondList = _pondEnvelopesWithin(searchBounds, roadWidth / 2 + 16);
    final watercourseList = generationVersion >= collisionSafeGenerationVersion
        ? watercourses
        : const <WorldMapWatercourse>[];
    final mountains = _mountainEnvelopes(
      _mountainsWithin(searchBounds),
      clearance,
    );
    final protectedAreas = generationVersion >= collisionSafeGenerationVersion
        ? _roadProtectedAreas(searchBounds, roadWidth)
        : const <Rect>[];
    bool blockedSegment(WorldMapPoint first, WorldMapPoint second) =>
        _roadSegmentConflictsWithRelief(
          first,
          second,
          lakeList,
          pondList,
          watercourseList,
          mountains,
          protectedAreas,
          roadWidth,
          allowRiverCrossings,
        );

    if (blockedSegment(start, start) || blockedSegment(end, end)) return null;

    WorldMapPoint gridPoint(int column, int row) =>
        WorldMapPoint(start.x + column * cellSize, start.y + row * cellSize);

    final startKey = (0, 0);
    final bestCost = <(int, int), double>{startKey: 0};
    final cameFrom = <(int, int), (int, int)>{};
    final frontier = _RoadRouteHeap();
    frontier.add(
      _RoadRouteCandidate(column: 0, row: 0, cost: 0, estimatedTotal: length),
    );

    const directions = [
      (-1, -1),
      (0, -1),
      (1, -1),
      (-1, 0),
      (1, 0),
      (-1, 1),
      (0, 1),
      (1, 1),
    ];
    var expandedNodes = 0;
    (int, int)? goalKey;
    while (frontier.isNotEmpty && expandedNodes < maximumExpandedNodes) {
      final current = frontier.removeFirst();
      final currentKey = (current.column, current.row);
      final currentBest = bestCost[currentKey];
      if (currentBest == null || current.cost > currentBest + 1e-7) continue;
      expandedNodes++;
      final currentPoint = gridPoint(current.column, current.row);
      if (currentPoint.distanceTo(end) <= cellSize * sqrt2 &&
          !blockedSegment(currentPoint, end)) {
        goalKey = currentKey;
        break;
      }

      for (final (deltaColumn, deltaRow) in directions) {
        final column = current.column + deltaColumn;
        final row = current.row + deltaRow;
        if (column < minColumn ||
            column > maxColumn ||
            row < minRow ||
            row > maxRow) {
          continue;
        }
        final nextPoint = gridPoint(column, row);
        if (blockedSegment(currentPoint, nextPoint)) continue;
        final stepCost = deltaColumn == 0 || deltaRow == 0
            ? cellSize
            : cellSize * sqrt2;
        final tentativeCost = current.cost + stepCost;
        final nextKey = (column, row);
        final previousCost = bestCost[nextKey];
        if (previousCost != null && tentativeCost >= previousCost - 1e-7) {
          continue;
        }
        bestCost[nextKey] = tentativeCost;
        cameFrom[nextKey] = currentKey;
        frontier.add(
          _RoadRouteCandidate(
            column: column,
            row: row,
            cost: tentativeCost,
            estimatedTotal: tentativeCost + nextPoint.distanceTo(end),
          ),
        );
      }
    }
    if (goalKey == null) return null;

    final reversedPath = <WorldMapPoint>[end];
    var cursor = goalKey;
    while (cursor != startKey) {
      reversedPath.add(gridPoint(cursor.$1, cursor.$2));
      final previous = cameFrom[cursor];
      if (previous == null) return null;
      cursor = previous;
    }
    reversedPath.add(start);
    final route = reversedPath.reversed.toList();
    final simplified = <WorldMapPoint>[route.first];
    var anchor = 0;
    while (anchor < route.length - 1) {
      var next = route.length - 1;
      while (next > anchor + 1 && blockedSegment(route[anchor], route[next])) {
        next--;
      }
      simplified.add(route[next]);
      anchor = next;
    }
    return simplified;
  }

  WorldMapPoint _districtHub(int x, int y) {
    if (generationVersion < collisionSafeGenerationVersion) {
      return _legacyDistrictHub(x, y);
    }
    final key = '$x:$y';
    final cached = _districtHubCache[key];
    if (cached != null) return cached;
    final settlement = _settlementPositionForDistrict(x, y);
    final kind = _settlementKindForDistrict(x, y);
    final origin = settlement ?? _rawDistrictAnchor(x, y);
    var directionX = origin.x;
    var directionY = origin.y - 155;
    final directionLength = sqrt(
      directionX * directionX + directionY * directionY,
    );
    if (directionLength < 1) {
      directionX = 1;
      directionY = 0;
    } else {
      directionX /= directionLength;
      directionY /= directionLength;
    }
    final startDistance = settlement == null
        ? 0.0
        : _settlementKeepoutRadius(kind) +
              _settlementRoadBufferMeters +
              13 +
              150;
    bool tryHub(WorldMapPoint candidate) {
      if (!_insideDistrictCell(candidate, x, y) ||
          _pointBlockedByRelief(candidate, margin: 80) ||
          _pointBlockedByProtectedParcel(candidate, 80) ||
          settlement != null &&
              candidate.distanceTo(settlement) <=
                  _settlementKeepoutRadius(kind) +
                      _settlementRoadBufferMeters +
                      25 / 2 +
                      20 ||
          _pointBlockedByOtherSettlement(
            candidate,
            settlement,
            25 / 2 + 20 + _settlementRoadBufferMeters,
          )) {
        return false;
      }
      _districtHubCache[key] = candidate;
      return true;
    }

    for (final distance in [
      startDistance,
      startDistance + 220,
      startDistance + 520,
      startDistance + 900,
      startDistance + 1500,
    ]) {
      for (var step = 0; step < 16; step++) {
        final angle = atan2(directionY, directionX) + step * pi / 8;
        final candidate = WorldMapPoint(
          origin.x + cos(angle) * distance,
          origin.y + sin(angle) * distance,
        );
        if (tryHub(candidate)) return candidate;
      }
    }
    const gridStep = 320.0;
    final maxDistance = settlement == null
        ? districtSize * 0.72
        : (x == 0 && y == 0 ? 6000.0 : districtSize * 0.72);
    final maxRing = (maxDistance / gridStep).ceil();
    for (var ring = 1; ring <= maxRing; ring++) {
      for (var dx = -ring; dx <= ring; dx++) {
        for (final dy in [-ring, ring]) {
          final candidate = WorldMapPoint(
            origin.x + dx * gridStep,
            origin.y + dy * gridStep,
          );
          if (candidate.distanceTo(origin) <= maxDistance &&
              tryHub(candidate)) {
            return candidate;
          }
        }
      }
      for (var dy = -ring + 1; dy < ring; dy++) {
        for (final dx in [-ring, ring]) {
          final candidate = WorldMapPoint(
            origin.x + dx * gridStep,
            origin.y + dy * gridStep,
          );
          if (candidate.distanceTo(origin) <= maxDistance &&
              tryHub(candidate)) {
            return candidate;
          }
        }
      }
    }
    // If the district is fully obstructed, road creation validates the raw
    // endpoint and suppresses edges that cannot reach it safely.
    final fallback = _rawDistrictAnchor(x, y);
    _districtHubCache[key] = fallback;
    return fallback;
  }

  WorldMapPoint _legacyDistrictHub(int x, int y) {
    if (generationVersion >= geographicRedesignGenerationVersion &&
        x == 0 &&
        y == 0) {
      return const WorldMapPoint(0, 155);
    }
    if (x == 0 && y == 0) return const WorldMapPoint(470, 450);
    final random = Random(_stableHash('$seed|district|$x|$y'));
    final point = WorldMapPoint(
      x * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
      y * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
    );
    if (generationVersion < geographicRedesignGenerationVersion ||
        !_pointBlockedByLegacyRelief(point, margin: 80)) {
      return point;
    }
    for (final offset in const [
      WorldMapPoint(700, 0),
      WorldMapPoint(-700, 0),
      WorldMapPoint(0, 700),
      WorldMapPoint(0, -700),
      WorldMapPoint(700, 700),
      WorldMapPoint(-700, 700),
      WorldMapPoint(700, -700),
      WorldMapPoint(-700, -700),
    ]) {
      final candidate = WorldMapPoint(point.x + offset.x, point.y + offset.y);
      if (candidate.x < x * districtSize - districtSize / 2 + 120 ||
          candidate.x > x * districtSize + districtSize / 2 - 120 ||
          candidate.y < y * districtSize - districtSize / 2 + 120 ||
          candidate.y > y * districtSize + districtSize / 2 - 120) {
        continue;
      }
      if (!_pointBlockedByLegacyRelief(candidate, margin: 80)) {
        return candidate;
      }
    }
    return point;
  }

  bool _pointBlockedByLegacyRelief(
    WorldMapPoint point, {
    required double margin,
  }) {
    if (_baseLakes.any(
      (lake) => lake.bounds
          .inflate(max(margin, _lakeRoadBankBufferMeters))
          .contains(Offset(point.x, point.y)),
    )) {
      return true;
    }
    final chunkX = (point.x / farmWorldChunkSize).floor();
    final chunkY = (point.y / farmWorldChunkSize).floor();
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        for (final mountain in _mountainsForChunk(x, y)) {
          final normalizedX =
              (point.x - mountain.center.x) / (mountain.width / 2 + margin);
          final normalizedY =
              (point.y - mountain.center.y) / (mountain.height / 2 + margin);
          if (normalizedX * normalizedX + normalizedY * normalizedY <= 1) {
            return true;
          }
        }
      }
    }
    return false;
  }

  WorldMapPoint? _settlementPositionForDistrict(int x, int y) {
    if (generationVersion < collisionSafeGenerationVersion) {
      return _legacyDistrictHub(x, y);
    }
    final key = '$x:$y';
    final cached = _settlementPositionCache[key];
    if (cached != null) return cached;
    if (_unavailableSettlementKeys.contains(key)) return null;
    final origin = x == 0 && y == 0
        ? const WorldMapPoint(0, 155)
        : _rawDistrictAnchor(x, y);
    final kind = _settlementKindForDistrict(x, y);
    final minimumSeparation =
        _settlementKeepoutRadius(kind) + _settlementFieldBufferMeters;
    final maxSearchDistance = x == 0 && y == 0 ? 6000.0 : districtSize * 0.72;
    bool tryCandidate(WorldMapPoint candidate) {
      if (!_insideDistrictCell(candidate, x, y) ||
          _pointBlockedByRelief(candidate, margin: minimumSeparation) ||
          _pointBlockedByProtectedParcel(candidate, minimumSeparation)) {
        return false;
      }
      _settlementPositionCache[key] = candidate;
      if (x == 0 && y == 0) {
        final hub = _districtHub(x, y);
        final gate = _settlementAccessGate(x, y)!;
        final accessRoad = _makeRoad(
          'settlement-access:$x:$y',
          gate,
          hub,
          WorldMapRoadType.dirt,
          bendScale: 0,
          maxBend: 0,
        );
        if (accessRoad == null) {
          _settlementPositionCache.remove(key);
          _districtHubCache.remove(key);
          return false;
        }
      }
      return true;
    }

    if (tryCandidate(origin)) return origin;
    for (final distance in const [760.0, 1320.0, 1980.0, 2700.0, 3600.0]) {
      if (distance > maxSearchDistance) continue;
      for (var step = 0; step < 16; step++) {
        final angle = step * pi / 8;
        final candidate = WorldMapPoint(
          origin.x + cos(angle) * distance,
          origin.y + sin(angle) * distance,
        );
        if (tryCandidate(candidate)) return candidate;
      }
    }

    // A deterministic square-ring search covers the remaining safe area. The
    // city can move farther from its original anchor than optional settlements.
    const gridStep = 320.0;
    final maxRing = (maxSearchDistance / gridStep).ceil();
    for (var ring = 1; ring <= maxRing; ring++) {
      for (var dx = -ring; dx <= ring; dx++) {
        for (final dy in [-ring, ring]) {
          final candidate = WorldMapPoint(
            origin.x + dx * gridStep,
            origin.y + dy * gridStep,
          );
          if (candidate.distanceTo(origin) > maxSearchDistance) continue;
          if (tryCandidate(candidate)) return candidate;
        }
      }
      for (var dy = -ring + 1; dy < ring; dy++) {
        for (final dx in [-ring, ring]) {
          final candidate = WorldMapPoint(
            origin.x + dx * gridStep,
            origin.y + dy * gridStep,
          );
          if (candidate.distanceTo(origin) > maxSearchDistance) continue;
          if (tryCandidate(candidate)) return candidate;
        }
      }
    }

    _unavailableSettlementKeys.add(key);
    return null;
  }

  WorldMapPoint _rawDistrictAnchor(int x, int y) {
    final random = Random(_stableHash('$seed|district|$x|$y'));
    return WorldMapPoint(
      x * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
      y * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
    );
  }

  bool _insideDistrictCell(WorldMapPoint point, int x, int y) {
    if (x == 0 &&
        y == 0 &&
        generationVersion >= collisionSafeGenerationVersion) {
      return worldBounds.inflate(500).contains(Offset(point.x, point.y));
    }
    return point.x >= x * districtSize + 80 &&
        point.x <= (x + 1) * districtSize - 80 &&
        point.y >= y * districtSize + 80 &&
        point.y <= (y + 1) * districtSize - 80;
  }

  WorldMapSettlementKind _settlementKindForDistrict(int x, int y) {
    if (x == 0 && y == 0) return WorldMapSettlementKind.city;
    final position = _rawDistrictAnchor(x, y);
    final distance = position.distanceTo(const WorldMapPoint(0, 155));
    return distance < 6500
        ? WorldMapSettlementKind.town
        : distance < 11000
        ? WorldMapSettlementKind.village
        : WorldMapSettlementKind.hamlet;
  }

  double _settlementKeepoutRadius(WorldMapSettlementKind kind) =>
      switch (kind) {
        WorldMapSettlementKind.city => 560,
        WorldMapSettlementKind.town => 390,
        WorldMapSettlementKind.village => 285,
        WorldMapSettlementKind.hamlet => 205,
      };

  WorldMapPoint? _settlementAccessGate(int x, int y) {
    final center = _settlementPositionForDistrict(x, y);
    if (center == null) return null;
    final hub = _districtHub(x, y);
    final dx = hub.x - center.x;
    final dy = hub.y - center.y;
    final length = max(1.0, sqrt(dx * dx + dy * dy));
    final kind = _settlementKindForDistrict(x, y);
    final distance =
        _settlementKeepoutRadius(kind) + _settlementRoadBufferMeters + 19;
    return WorldMapPoint(
      center.x + dx / length * distance,
      center.y + dy / length * distance,
    );
  }

  List<(WorldMapPoint, double)> _settlementFootprintsWithin(Rect bounds) {
    final searchPadding = 6500.0;
    final firstX = ((bounds.left - searchPadding) / districtSize).floor();
    final lastX = ((bounds.right + searchPadding) / districtSize).floor();
    final firstY = ((bounds.top - searchPadding) / districtSize).floor();
    final lastY = ((bounds.bottom + searchPadding) / districtSize).floor();
    final result = <(WorldMapPoint, double)>[];
    for (var y = firstY; y <= lastY; y++) {
      for (var x = firstX; x <= lastX; x++) {
        final position = _settlementPositionForDistrict(x, y);
        if (position == null) continue;
        result.add((
          position,
          _settlementKeepoutRadius(_settlementKindForDistrict(x, y)),
        ));
      }
    }
    return result;
  }

  bool _pointBlockedByOtherSettlement(
    WorldMapPoint point,
    WorldMapPoint? excluded,
    double margin,
  ) =>
      _settlementFootprintsWithin(
        Rect.fromCircle(center: Offset(point.x, point.y), radius: margin + 700),
      ).any(
        (footprint) =>
            (excluded == null || footprint.$1.distanceTo(excluded) > 1) &&
            point.distanceTo(footprint.$1) <= footprint.$2 + margin,
      );

  bool _pointBlockedByProtectedParcel(WorldMapPoint point, double radius) =>
      _protectedOwnedParcels.any(
        (parcel) => _parcelIntersectsCircle(parcel, point, radius),
      );

  bool _parcelIntersectsCircle(
    WorldMapParcel parcel,
    WorldMapPoint center,
    double radius,
  ) {
    final vertices = parcel.worldVertices;
    if (vertices.length < 3) return false;
    if (_pointInPolygon(center, vertices)) return true;
    for (var index = 0; index < vertices.length; index++) {
      final start = vertices[index];
      final end = vertices[(index + 1) % vertices.length];
      if (WorldMapParcel._distanceToSegment(center, start, end) <= radius) {
        return true;
      }
    }
    return false;
  }

  bool _pointBlockedByRelief(WorldMapPoint point, {required double margin}) {
    if (_baseLakes.any(
      (lake) => lake.bounds
          .inflate(max(margin, _lakeRoadBankBufferMeters))
          .contains(Offset(point.x, point.y)),
    )) {
      return true;
    }
    final chunkX = (point.x / farmWorldChunkSize).floor();
    final chunkY = (point.y / farmWorldChunkSize).floor();
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        for (final pond in _pondsForChunk(x, y)) {
          final radiusX = pond.width / 2 + margin;
          final radiusY = pond.height / 2 + margin;
          final normalizedX = (point.x - pond.center.x) / radiusX;
          final normalizedY = (point.y - pond.center.y) / radiusY;
          if (normalizedX * normalizedX + normalizedY * normalizedY <= 1) {
            return true;
          }
        }
      }
    }
    for (final watercourse in _baseWatercourses) {
      final clearance = margin + watercourse.width / 2;
      for (var index = 0; index < watercourse.points.length - 1; index++) {
        if (WorldMapParcel._distanceToSegment(
              point,
              watercourse.points[index],
              watercourse.points[index + 1],
            ) <=
            clearance) {
          return true;
        }
      }
    }
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        for (final mountain in _mountainsForChunk(x, y)) {
          final normalizedX =
              (point.x - mountain.center.x) / (mountain.width / 2 + margin);
          final normalizedY =
              (point.y - mountain.center.y) / (mountain.height / 2 + margin);
          if (normalizedX * normalizedX + normalizedY * normalizedY <= 1) {
            return true;
          }
        }
      }
    }
    return false;
  }

  WorldMapRoad? _nearestRoadAt(
    WorldMapPoint point, {
    required double searchRadius,
  }) {
    final roads = roadSegmentsInBounds(
      point.x - searchRadius,
      point.y - searchRadius,
      point.x + searchRadius,
      point.y + searchRadius,
    );
    WorldMapRoad? nearestRoad;
    var nearestDistance = double.infinity;
    for (final road in roads) {
      for (var index = 0; index < road.points.length - 1; index++) {
        final start = road.points[index];
        final end = road.points[index + 1];
        final distance = WorldMapParcel._distanceToSegment(point, start, end);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestRoad = road;
        }
      }
    }
    return nearestDistance <= searchRadius ? nearestRoad : null;
  }

  WorldMapPoint? _nearestRoadPosition(
    WorldMapPoint point, {
    required double maxDistance,
  }) {
    final roads = roadSegmentsInBounds(
      point.x - maxDistance,
      point.y - maxDistance,
      point.x + maxDistance,
      point.y + maxDistance,
    );
    WorldMapPoint? nearestPoint;
    var nearestDistance = double.infinity;
    for (final road in roads) {
      for (var index = 0; index < road.points.length - 1; index++) {
        final start = road.points[index];
        final end = road.points[index + 1];
        final dx = end.x - start.x;
        final dy = end.y - start.y;
        final lengthSquared = dx * dx + dy * dy;
        final t = lengthSquared == 0
            ? 0.0
            : (((point.x - start.x) * dx + (point.y - start.y) * dy) /
                      lengthSquared)
                  .clamp(0.0, 1.0)
                  .toDouble();
        final candidate = WorldMapPoint(start.x + dx * t, start.y + dy * t);
        final distance = point.distanceTo(candidate);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestPoint = candidate;
        }
      }
    }
    return nearestDistance <= maxDistance ? nearestPoint : null;
  }

  static WorldMapPoint? _segmentIntersection(
    WorldMapPoint firstStart,
    WorldMapPoint firstEnd,
    WorldMapPoint secondStart,
    WorldMapPoint secondEnd,
  ) {
    final firstX = firstEnd.x - firstStart.x;
    final firstY = firstEnd.y - firstStart.y;
    final secondX = secondEnd.x - secondStart.x;
    final secondY = secondEnd.y - secondStart.y;
    final denominator = firstX * secondY - firstY * secondX;
    if (denominator.abs() < 1e-9) return null;
    final offsetX = secondStart.x - firstStart.x;
    final offsetY = secondStart.y - firstStart.y;
    final firstT = (offsetX * secondY - offsetY * secondX) / denominator;
    final secondT = (offsetX * firstY - offsetY * firstX) / denominator;
    if (firstT < 0 || firstT > 1 || secondT < 0 || secondT > 1) return null;
    return WorldMapPoint(
      firstStart.x + firstX * firstT,
      firstStart.y + firstY * firstT,
    );
  }

  static Rect _boundsOfPoints(List<WorldMapPoint> points) {
    if (points.isEmpty) return Rect.zero;
    var minX = points.first.x;
    var maxX = points.first.x;
    var minY = points.first.y;
    var maxY = points.first.y;
    for (final point in points.skip(1)) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static String _settlementName(
    int districtX,
    int districtY,
    WorldMapSettlementKind kind,
  ) {
    const townNames = ['Güneyhisar', 'Yukarıova', 'Karaağaç', 'Akdere'];
    const villageNames = ['Çamlıbel', 'Söğütlü', 'Boztepe', 'Dereyurt'];
    const hamletNames = ['Küçükova', 'Kavaklı', 'Çiftlikköy', 'Aşağıoba'];
    final names = switch (kind) {
      WorldMapSettlementKind.city => townNames,
      WorldMapSettlementKind.town => townNames,
      WorldMapSettlementKind.village => villageNames,
      WorldMapSettlementKind.hamlet => hamletNames,
    };
    final hash = _stableHash('settlement-name:$districtX:$districtY');
    return names[hash % names.length];
  }

  double _parcelDensity(WorldMapPoint point) {
    final districtX = (point.x / districtSize).floor();
    final districtY = (point.y / districtSize).floor();
    var nearestDistance = double.infinity;
    for (var y = districtY - 1; y <= districtY + 1; y++) {
      for (var x = districtX - 1; x <= districtX + 1; x++) {
        final distance = point.distanceTo(_districtHub(x, y));
        if (distance < nearestDistance) nearestDistance = distance;
      }
    }
    return (1 - nearestDistance / 3300).clamp(0.0, 1.0);
  }

  double _parcelDensityV4(WorldMapPoint point) {
    final distanceToCity = point.distanceTo(const WorldMapPoint(0, 155));
    final cityDensity = exp(-distanceToCity / 3100);
    final regionalDensity = regionAt(point)?.fieldDensity ?? 0.42;
    return (cityDensity * 0.72 + regionalDensity * 0.28).clamp(0.0, 1.0);
  }

  int _parcelDistrictIndex(double coordinate) =>
      generationVersion >= geographicRedesignGenerationVersion
      ? ((coordinate + districtSize / 2) / districtSize).floor()
      : (coordinate / districtSize).floor();

  static bool _hasHomeClearance(WorldMapParcel parcel) {
    const homeCenter = WorldMapPoint(-150, -120);
    const homeWidth = 142.0;
    const homeHeight = 110.0;
    const clearance = 24.0;
    return (parcel.center.x - homeCenter.x).abs() <
            (parcel.width + homeWidth) / 2 + clearance &&
        (parcel.center.y - homeCenter.y).abs() <
            (parcel.height + homeHeight) / 2 + clearance;
  }

  static List<WorldMapPoint> _parcelShape(Random random) {
    const templates = <List<WorldMapPoint>>[
      [
        WorldMapPoint(-0.49, -0.26),
        WorldMapPoint(-0.22, -0.49),
        WorldMapPoint(0.34, -0.43),
        WorldMapPoint(0.49, -0.06),
        WorldMapPoint(0.28, 0.47),
        WorldMapPoint(-0.43, 0.34),
      ],
      [
        WorldMapPoint(-0.46, -0.43),
        WorldMapPoint(0.12, -0.49),
        WorldMapPoint(0.49, -0.19),
        WorldMapPoint(0.37, 0.28),
        WorldMapPoint(-0.08, 0.49),
        WorldMapPoint(-0.49, 0.14),
      ],
      [
        WorldMapPoint(-0.50, -0.16),
        WorldMapPoint(-0.31, -0.47),
        WorldMapPoint(0.21, -0.49),
        WorldMapPoint(0.49, -0.25),
        WorldMapPoint(0.45, 0.32),
        WorldMapPoint(0.10, 0.49),
        WorldMapPoint(-0.48, 0.35),
      ],
      [
        WorldMapPoint(-0.49, -0.46),
        WorldMapPoint(0.47, -0.34),
        WorldMapPoint(0.31, 0.46),
        WorldMapPoint(-0.36, 0.49),
      ],
      [
        WorldMapPoint(-0.46, -0.34),
        WorldMapPoint(-0.11, -0.49),
        WorldMapPoint(0.43, -0.42),
        WorldMapPoint(0.50, 0.03),
        WorldMapPoint(0.28, 0.43),
        WorldMapPoint(-0.12, 0.49),
        WorldMapPoint(-0.49, 0.18),
      ],
    ];
    final template = templates[random.nextInt(templates.length)];
    final angle = random.nextDouble() * pi * 2;
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    final rotated = [
      for (final point in template)
        WorldMapPoint(
          point.x * cosAngle - point.y * sinAngle,
          point.x * sinAngle + point.y * cosAngle,
        ),
    ];
    final minX = rotated.map((point) => point.x).reduce(min);
    final maxX = rotated.map((point) => point.x).reduce(max);
    final minY = rotated.map((point) => point.y).reduce(min);
    final maxY = rotated.map((point) => point.y).reduce(max);
    return List.unmodifiable([
      for (final point in rotated)
        WorldMapPoint(
          (point.x - (minX + maxX) / 2) / (maxX - minX),
          (point.y - (minY + maxY) / 2) / (maxY - minY),
        ),
    ]);
  }

  static String _parcelName(int x, int y, int index, WorldCropType type) {
    final cropName = switch (type) {
      WorldCropType.grain => 'Tahıl',
      WorldCropType.oilseed => 'Ayçiçeği',
      WorldCropType.vegetable => 'Sebze',
      WorldCropType.pasture => 'Mera',
    };
    return '$cropName · ${x.toString()},${y.toString()} / ${index + 1}';
  }

  static String _poiName(WorldPointOfInterestType type) => switch (type) {
    WorldPointOfInterestType.water => 'Su kaynağı',
    WorldPointOfInterestType.village => 'Köy merkezi',
    WorldPointOfInterestType.mill => 'Değirmen',
    WorldPointOfInterestType.timberYard => 'Orman deposu',
  };

  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _RoadEllipseEnvelope {
  _RoadEllipseEnvelope({
    required this.center,
    required this.radiusX,
    required this.radiusY,
  }) : bounds = Rect.fromCenter(
         center: Offset(center.x, center.y),
         width: radiusX * 2,
         height: radiusY * 2,
       );

  final WorldMapPoint center;
  final double radiusX;
  final double radiusY;
  final Rect bounds;
}

class _RoadRouteCandidate {
  const _RoadRouteCandidate({
    required this.column,
    required this.row,
    required this.cost,
    required this.estimatedTotal,
  });

  final int column;
  final int row;
  final double cost;
  final double estimatedTotal;
}

class _RoadRouteHeap {
  final List<_RoadRouteCandidate> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  static bool _comesBefore(
    _RoadRouteCandidate first,
    _RoadRouteCandidate second,
  ) {
    final scoreOrder = first.estimatedTotal.compareTo(second.estimatedTotal);
    if (scoreOrder != 0) return scoreOrder < 0;
    final costOrder = second.cost.compareTo(first.cost);
    if (costOrder != 0) return costOrder < 0;
    if (first.row != second.row) return first.row < second.row;
    return first.column < second.column;
  }

  void add(_RoadRouteCandidate candidate) {
    var index = _items.length;
    _items.add(candidate);
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      final parent = _items[parentIndex];
      if (!_comesBefore(candidate, parent)) break;
      _items[index] = parent;
      index = parentIndex;
    }
    _items[index] = candidate;
  }

  _RoadRouteCandidate removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isEmpty) return first;
    var index = 0;
    while (true) {
      final leftIndex = index * 2 + 1;
      if (leftIndex >= _items.length) break;
      final rightIndex = leftIndex + 1;
      final childIndex =
          rightIndex < _items.length &&
              _comesBefore(_items[rightIndex], _items[leftIndex])
          ? rightIndex
          : leftIndex;
      final child = _items[childIndex];
      if (!_comesBefore(child, last)) break;
      _items[index] = child;
      index = childIndex;
    }
    _items[index] = last;
    return first;
  }
}
