import 'dart:math';
import 'dart:ui' show Rect;

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
  });

  final int x;
  final int y;
  final List<WorldMapParcel> parcels;
  final List<WorldMapTree> trees;
  final List<WorldMapPointOfInterest> pointsOfInterest;
  final List<WorldMapPond> ponds;
  final List<WorldMapMountain> mountains;
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
  });

  static const int defaultSeed = 20270317;
  static const int legacyGenerationVersion = 1;
  static const int expandedParcelGenerationVersion = 2;
  static const int mountainFieldBlockingGenerationVersion = 2;
  static const int clusteredMountainGenerationVersion = 3;
  static const int currentGenerationVersion =
      clusteredMountainGenerationVersion;
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

  static bool isChunkInBounds(int chunkX, int chunkY) =>
      chunkX >= minChunkX &&
      chunkX <= maxChunkX &&
      chunkY >= minChunkY &&
      chunkY <= maxChunkY;

  final int seed;
  final int generationVersion;
  final Map<String, WorldMapChunk> _chunkCache = {};
  final Map<String, List<WorldMapParcel>> _districtParcelCache = {};
  final Map<String, List<WorldMapRoad>> _roadCache = {};
  final Map<String, List<WorldMapMountain>> _mountainCache = {};

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
    final districtX = (left / districtSize).floor();
    final districtY = (top / districtSize).floor();
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
    final treeCount = 62 + random.nextInt(34);
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
    for (var index = 0; index < treeCount; index++) {
      final point = WorldMapPoint(
        left + random.nextDouble() * farmWorldChunkSize,
        top + random.nextDouble() * farmWorldChunkSize,
      );
      final radius = 13 + random.nextDouble() * 12;
      if (parcels.any((parcel) => parcel.contains(point, padding: 13))) {
        continue;
      }
      if (!_treeHasRoadClearance(point, radius, nearbyRoads) ||
          _treeOverlapsPond(point, radius, nearbyPonds) ||
          _treeOverlapsMountain(point, radius, nearbyMountains)) {
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

  WorldMapParcel? parcelById(String id, {int searchRadius = 1}) {
    if (id == 'home') return chunkAt(0, 0).parcels.first;
    final match = RegExp(r'^land:(-?\d+):(-?\d+):(\d+)$').firstMatch(id);
    if (match == null) return null;
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
    if (_districtParcelCache.length > 128) _districtParcelCache.clear();

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
            !_hasFeatureClearance(candidate) ||
            !_hasRoadClearance(candidate)) {
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
    return (
      (fixedCost + areaCost * pow(nonNegativeArea, areaExponent)) *
          fertilityMultiplier *
          cropMultiplier
    ).round();
  }

  (double, double) _parcelDimensions(Random random) {
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

  bool _hasFeatureClearance(WorldMapParcel parcel) {
    final parcelRadius =
        sqrt(parcel.width * parcel.width + parcel.height * parcel.height) / 2;
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
          final pondRadius =
              sqrt(pond.width * pond.width + pond.height * pond.height) / 2;
          if (parcel.center.distanceTo(pond.center) <
              parcelRadius + pondRadius + 28) {
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
          if (parcel.center.distanceTo(poi.position) <
              parcelRadius + poiRadius + 32) {
            return false;
          }
        }
      }
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
    final roads = roadSegmentsInBounds(
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
      final waterConflict = nearbyPonds.any((pond) {
        final expandedX = mountain.width / 2 + pond.width / 2 + 18;
        final expandedY = mountain.height / 2 + pond.height / 2 + 18;
        final x = (center.x - pond.center.x) / expandedX;
        final y = (center.y - pond.center.y) / expandedY;
        return x * x + y * y <= 1;
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
    final parcelRadius =
        sqrt(parcel.width * parcel.width + parcel.height * parcel.height) / 2;
    final clearance = parcelRadius + 42;
    final searchRadius = clearance + 25 / 2;
    final roads = roadSegmentsInBounds(
      parcel.center.x - searchRadius,
      parcel.center.y - searchRadius,
      parcel.center.x + searchRadius,
      parcel.center.y + searchRadius,
    );
    for (final road in roads) {
      final requiredDistance = clearance + road.width / 2;
      for (var index = 0; index < road.points.length - 1; index++) {
        if (WorldMapParcel._distanceToSegment(
              parcel.center,
              road.points[index],
              road.points[index + 1],
            ) <
            requiredDistance) {
          return false;
        }
      }
    }
    return true;
  }

  List<WorldMapPond> _pondsForChunk(int chunkX, int chunkY) {
    final random = Random(_stableHash('$seed|ponds|$chunkX|$chunkY'));
    if (random.nextInt(7) != 0) return const [];
    return [
      WorldMapPond(
        center: WorldMapPoint(
          chunkX * farmWorldChunkSize + 120 + random.nextDouble() * 390,
          chunkY * farmWorldChunkSize + 120 + random.nextDouble() * 390,
        ),
        width: 70 + random.nextDouble() * 100,
        height: 48 + random.nextDouble() * 60,
      ),
    ];
  }

  List<WorldMapPointOfInterest> _pointsOfInterestForChunk(
    int chunkX,
    int chunkY,
  ) {
    final random = Random(_stableHash('$seed|poi|$chunkX|$chunkY'));
    if (random.nextInt(5) != 0) return const [];
    final type = WorldPointOfInterestType
        .values[random.nextInt(WorldPointOfInterestType.values.length)];
    final position = WorldMapPoint(
      chunkX * farmWorldChunkSize + 140 + random.nextDouble() * 360,
      chunkY * farmWorldChunkSize + 140 + random.nextDouble() * 360,
    );
    return [
      WorldMapPointOfInterest(
        id: 'poi:$chunkX:$chunkY',
        name: _poiName(type),
        type: type,
        position: position,
      ),
    ];
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
      if (horizontalVariant < 91) {
        roads.add(
          _makeRoad(
            horizontalId,
            _districtHub(x, y),
            _districtHub(x + 1, y),
            horizontalVariant < 56
                ? WorldMapRoadType.arterial
                : WorldMapRoadType.secondary,
            bendScale: 0.18,
          ),
        );
      }
      final verticalId = 'district:$x:$y:$x:${y + 1}';
      final verticalVariant = _stableHash('$seed|$verticalId|class') % 100;
      if (verticalVariant < 91) {
        roads.add(
          _makeRoad(
            verticalId,
            _districtHub(x, y),
            _districtHub(x, y + 1),
            verticalVariant < 56
                ? WorldMapRoadType.arterial
                : WorldMapRoadType.secondary,
            bendScale: 0.18,
          ),
        );
      }
      return List.unmodifiable(roads);
    });
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
      if ((districtHub.x / farmWorldChunkSize).floor() == chunkX &&
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
        roads.add(
          _makeRoad(
            'local:$chunkX:$chunkY:$side',
            gate.position,
            junction,
            type,
            bendScale: 0.24,
            maxBend: 72,
          ),
        );
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

  WorldMapRoad _makeRoad(
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
    final perpendicular = length == 0
        ? const WorldMapPoint(0, 0)
        : WorldMapPoint(-dy / length, dx / length);
    final random = Random(_stableHash('$seed|curve:$id'));
    final bendLimit = maxBend ?? length * bendScale;
    final bend = (random.nextDouble() * 2 - 1) * bendLimit;
    final control1 = WorldMapPoint(
      start.x + dx * 0.32 + perpendicular.x * bend,
      start.y + dy * 0.32 + perpendicular.y * bend,
    );
    final control2Bend = bend * (random.nextDouble() * 0.45 + 0.35);
    final control2 = WorldMapPoint(
      start.x + dx * 0.68 + perpendicular.x * control2Bend,
      start.y + dy * 0.68 + perpendicular.y * control2Bend,
    );
    const sampleCount = 48;
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
    return WorldMapRoad(id: id, type: type, points: List.unmodifiable(points));
  }

  WorldMapPoint _districtHub(int x, int y) {
    if (x == 0 && y == 0) return const WorldMapPoint(470, 450);
    final random = Random(_stableHash('$seed|district|$x|$y'));
    return WorldMapPoint(
      x * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
      y * districtSize + districtSize * (0.25 + random.nextDouble() * 0.5),
    );
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
