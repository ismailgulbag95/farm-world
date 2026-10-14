/// Pure Dart domain model for crop growth and harvest cycles in Farm World.
///
/// Designed in accordance with settled rules in:
/// - docs/game-design-brief.md (Section 5, Crop growth cycles & season closure)
/// - docs/crop-calendar-model.md (Ekimler ayrı büyüme/hasat çevrimleridir & kısmi hasat)
/// - docs/crop-tree-and-calendar-proposal.md (Section 1, Değişmez tasarım kuralları)
/// - docs/economy-and-progression-proposal.md (Section 1 & 4)
library;

/// Immutable definition of a crop type with balance and timing parameters.
///
/// Contains the stable crop identifier, required duration to reach full maturity,
/// and baseline full-harvest yield.
///
/// This definition is pure and receives all timing and yield values explicitly
/// without reading system clocks or hardcoding runtime catalogue defaults.
class CropDefinition {
  /// Creates a [CropDefinition] with explicit parameters.
  ///
  /// Throws [ArgumentError] if:
  /// - [id] is empty or whitespace only.
  /// - [fullGrowthDuration] is zero or negative.
  /// - [fullHarvestYield] is non-positive, NaN, or infinite.
  CropDefinition({
    required this.id,
    required this.fullGrowthDuration,
    required num fullHarvestYield,
  }) : fullHarvestYield = fullHarvestYield.toDouble() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Crop ID cannot be empty or whitespace only.',
      );
    }
    if (fullGrowthDuration <= Duration.zero) {
      throw ArgumentError.value(
        fullGrowthDuration,
        'fullGrowthDuration',
        'Full growth duration must be strictly positive.',
      );
    }
    if (this.fullHarvestYield <= 0 ||
        this.fullHarvestYield.isNaN ||
        this.fullHarvestYield.isInfinite) {
      throw ArgumentError.value(
        fullHarvestYield,
        'fullHarvestYield',
        'Full harvest yield must be strictly positive and finite.',
      );
    }
  }

  /// Stable crop identifier (e.g. 'CR01', 'CR02').
  final String id;

  /// Required duration of growth to reach full maturity.
  final Duration fullGrowthDuration;

  /// Full harvest yield awarded upon mature harvest.
  final double fullHarvestYield;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropDefinition &&
        other.id == id &&
        other.fullGrowthDuration == fullGrowthDuration &&
        other.fullHarvestYield == fullHarvestYield;
  }

  @override
  int get hashCode => Object.hash(id, fullGrowthDuration, fullHarvestYield);

  @override
  String toString() =>
      'CropDefinition(id: $id, fullGrowthDuration: $fullGrowthDuration, '
      'fullHarvestYield: $fullHarvestYield)';
}

/// Lifecycle status of an evaluated crop planting cycle snapshot.
enum CropCycleStatus {
  /// The crop is currently growing and has not yet reached maturity or harvest window closure.
  growing,

  /// The crop reached maturity at or before harvest window closure. Full harvest yield is available.
  readyForHarvest,

  /// The harvest window closed before the crop reached maturity.
  /// Final growth and yield were frozen at the closure instant.
  closedWithPartialHarvest,
}

/// Alias for [CropCycleStatus] matching stage-centric nomenclature.
typedef CropCycleStage = CropCycleStatus;

/// Alias for [CropCycleStatus].
typedef CropStatus = CropCycleStatus;

/// Pure, immutable representation of a single crop planting cycle.
///
/// Anchored relative to the game save's first successful planting calendar anchor
/// (docs/game-design-brief.md:87).
///
/// This model is deterministic, does not read wall-clock time, and does not decide
/// which season or climate windows apply; harvest window closure is supplied externally.
class CropCycle {
  /// Creates a [CropCycle] planting instance.
  ///
  /// Throws [ArgumentError] if:
  /// - [plantedElapsed] is negative.
  /// - [harvestWindowCloseElapsed] is before [plantedElapsed].
  CropCycle({
    required this.crop,
    required this.plantedElapsed,
    required this.harvestWindowCloseElapsed,
  }) {
    if (plantedElapsed.isNegative) {
      throw ArgumentError.value(
        plantedElapsed,
        'plantedElapsed',
        'Planted elapsed duration cannot be negative.',
      );
    }
    if (harvestWindowCloseElapsed < plantedElapsed) {
      throw ArgumentError.value(
        harvestWindowCloseElapsed,
        'harvestWindowCloseElapsed',
        'Harvest window closure elapsed time cannot be before planted elapsed time.',
      );
    }
  }

  /// The definition of the crop planted in this cycle.
  final CropDefinition crop;

  /// Elapsed game duration at which planting occurred, measured relative to
  /// the save's first-successful-planting calendar anchor.
  final Duration plantedElapsed;

  /// Externally computed elapsed game duration at which the harvest window closes.
  final Duration harvestWindowCloseElapsed;

  /// Ergonomic alias for [crop].
  CropDefinition get cropDefinition => crop;

  /// Ergonomic alias for [plantedElapsed].
  Duration get plantedAtElapsed => plantedElapsed;

  /// Ergonomic alias for [plantedElapsed].
  Duration get plantedAt => plantedElapsed;

  /// Ergonomic alias for [harvestWindowCloseElapsed].
  Duration get harvestWindowClosesElapsed => harvestWindowCloseElapsed;

  /// Ergonomic alias for [harvestWindowCloseElapsed].
  Duration get harvestWindowClosesAtElapsed => harvestWindowCloseElapsed;

  /// Elapsed timestamp at which the crop reaches full maturity.
  Duration get maturityElapsed => plantedElapsed + crop.fullGrowthDuration;

  /// Duration of the open harvest window starting from planting.
  Duration get harvestWindowDuration =>
      harvestWindowCloseElapsed - plantedElapsed;

  /// Evaluates the planting cycle at an explicitly supplied [currentElapsed] duration.
  ///
  /// Evaluates against the following settled rules:
  /// 1. Before maturity and before window closure: growth progress is
  ///    `elapsed growth / full duration`, clamped to `[0.0, 1.0]`, with status [CropCycleStatus.growing].
  /// 2. If the harvest window closes before maturity: final progress and yield
  ///    are calculated and frozen at the closure instant, even if evaluation happens later.
  ///    Status is [CropCycleStatus.closedWithPartialHarvest].
  /// 3. If maturity occurs at or before window closure: full yield remains available
  ///    after maturity, with status [CropCycleStatus.readyForHarvest].
  /// 4. At an exact tie where maturity equals window closure timestamp: full yield is awarded.
  ///
  /// Throws [ArgumentError] if [currentElapsed] is before [plantedElapsed].
  CropCycleSnapshot evaluate(Duration currentElapsed) {
    if (currentElapsed < plantedElapsed) {
      throw ArgumentError.value(
        currentElapsed,
        'currentElapsed',
        'Evaluation elapsed duration cannot be before planted elapsed duration.',
      );
    }

    final maturity = maturityElapsed;

    // Case 1: Maturity occurs at or before window closure (maturity <= closure).
    // Settled rule: "If maturity occurs at or before closure, full yield remains
    // available after maturity. At equal maturity/closure timestamps, use full yield."
    if (maturity <= harvestWindowCloseElapsed) {
      if (currentElapsed >= maturity) {
        return CropCycleSnapshot(
          cycle: this,
          evaluationElapsed: currentElapsed,
          status: CropCycleStatus.readyForHarvest,
          growthProgress: 1.0,
          harvestYield: crop.fullHarvestYield,
        );
      } else {
        final elapsedGrowth = currentElapsed - plantedElapsed;
        final progress =
            (elapsedGrowth.inMicroseconds /
                    crop.fullGrowthDuration.inMicroseconds)
                .clamp(0.0, 1.0);
        return CropCycleSnapshot(
          cycle: this,
          evaluationElapsed: currentElapsed,
          status: CropCycleStatus.growing,
          growthProgress: progress,
          harvestYield: 0.0,
        );
      }
    }

    // Case 2: Window closes before maturity (closure < maturity).
    // Settled rule: "If the window closes before maturity, final progress and yield
    // are calculated at the closure instant, even if evaluation happens later."
    if (currentElapsed >= harvestWindowCloseElapsed) {
      final elapsedGrowthAtClose = harvestWindowCloseElapsed - plantedElapsed;
      final progress =
          (elapsedGrowthAtClose.inMicroseconds /
                  crop.fullGrowthDuration.inMicroseconds)
              .clamp(0.0, 1.0);
      final partialYield = progress * crop.fullHarvestYield;

      return CropCycleSnapshot(
        cycle: this,
        evaluationElapsed: currentElapsed,
        status: CropCycleStatus.closedWithPartialHarvest,
        growthProgress: progress,
        harvestYield: partialYield,
      );
    } else {
      final elapsedGrowth = currentElapsed - plantedElapsed;
      final progress =
          (elapsedGrowth.inMicroseconds /
                  crop.fullGrowthDuration.inMicroseconds)
              .clamp(0.0, 1.0);
      return CropCycleSnapshot(
        cycle: this,
        evaluationElapsed: currentElapsed,
        status: CropCycleStatus.growing,
        growthProgress: progress,
        harvestYield: 0.0,
      );
    }
  }

  /// Convenience evaluation method directly from UTC/local timestamps.
  ///
  /// Normalizes both timestamps to UTC to compute elapsed time relative to
  /// [firstSuccessfulPlantingAt].
  CropCycleSnapshot evaluateAtTimestamps({
    required DateTime firstSuccessfulPlantingAt,
    required DateTime now,
  }) {
    final utcAnchor = firstSuccessfulPlantingAt.toUtc();
    final utcNow = now.toUtc();
    final elapsed = utcNow.difference(utcAnchor);
    return evaluate(elapsed);
  }

  /// Callable object syntax delegating directly to [evaluate].
  CropCycleSnapshot call(Duration currentElapsed) => evaluate(currentElapsed);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropCycle &&
        other.crop == crop &&
        other.plantedElapsed == plantedElapsed &&
        other.harvestWindowCloseElapsed == harvestWindowCloseElapsed;
  }

  @override
  int get hashCode =>
      Object.hash(crop, plantedElapsed, harvestWindowCloseElapsed);

  @override
  String toString() =>
      'CropCycle(crop: ${crop.id}, plantedElapsed: $plantedElapsed, '
      'harvestWindowCloseElapsed: $harvestWindowCloseElapsed, '
      'maturityElapsed: $maturityElapsed)';
}

/// Alias for [CropCycle] matching planting-centric terminology.
typedef CropPlanting = CropCycle;

/// Immutable evaluated snapshot of a crop cycle at a specific instant.
class CropCycleSnapshot {
  /// Creates an immutable [CropCycleSnapshot].
  const CropCycleSnapshot({
    required this.cycle,
    required this.evaluationElapsed,
    required this.status,
    required this.growthProgress,
    required this.harvestYield,
  });

  /// The parent crop cycle evaluated for this snapshot.
  final CropCycle cycle;

  /// Elapsed duration at which evaluation occurred, measured from the calendar anchor.
  final Duration evaluationElapsed;

  /// Evaluated lifecycle status of the cycle.
  final CropCycleStatus status;

  /// Growth progress normalized to range `[0.0, 1.0]`.
  final double growthProgress;

  /// Evaluated yield available for harvest.
  ///
  /// - `0.0` while growing.
  /// - `fullHarvestYield` when ready for harvest.
  /// - `growthProgress * fullHarvestYield` when closed with partial harvest.
  final double harvestYield;

  // ---------------------------------------------------------------------------
  // Ergonomic Accessors
  // ---------------------------------------------------------------------------

  /// Ergonomic alias for [growthProgress].
  double get progress => growthProgress;

  /// Ergonomic alias for [harvestYield].
  double get yield => harvestYield;

  /// Potential harvest yield if harvest yield were proportional to current progress.
  double get potentialYield => growthProgress * cycle.crop.fullHarvestYield;

  /// The crop definition from the evaluated cycle.
  CropDefinition get crop => cycle.crop;

  /// Ergonomic alias for [crop].
  CropDefinition get cropDefinition => cycle.crop;

  /// Ergonomic alias for [evaluationElapsed].
  Duration get currentElapsed => evaluationElapsed;

  /// Whether the crop is currently in the growing stage.
  bool get isGrowing => status == CropCycleStatus.growing;

  /// Whether the crop reached full maturity and is ready for full harvest.
  bool get isReadyForHarvest => status == CropCycleStatus.readyForHarvest;

  /// Alias for [isReadyForHarvest].
  bool get isReadyForFullHarvest => isReadyForHarvest;

  /// Alias for [isReadyForHarvest].
  bool get isMature => isReadyForHarvest;

  /// Whether the crop cycle closed prematurely with a partial harvest.
  bool get isClosedWithPartialHarvest =>
      status == CropCycleStatus.closedWithPartialHarvest;

  /// Alias for [isClosedWithPartialHarvest].
  bool get isClosed => isClosedWithPartialHarvest;

  /// Whether any harvest (full or partial) is available to collect.
  bool get isHarvestable => isReadyForHarvest || isClosedWithPartialHarvest;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropCycleSnapshot &&
        other.cycle == cycle &&
        other.evaluationElapsed == evaluationElapsed &&
        other.status == status &&
        other.growthProgress == growthProgress &&
        other.harvestYield == harvestYield;
  }

  @override
  int get hashCode => Object.hash(
    cycle,
    evaluationElapsed,
    status,
    growthProgress,
    harvestYield,
  );

  @override
  String toString() =>
      'CropCycleSnapshot(crop: ${crop.id}, evaluationElapsed: $evaluationElapsed, '
      'status: ${status.name}, growthProgress: $growthProgress, '
      'harvestYield: $harvestYield)';
}

/// Alias for [CropCycleSnapshot].
typedef CropSnapshot = CropCycleSnapshot;
