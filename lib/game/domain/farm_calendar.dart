/// Pure Dart domain model for the Farm World calendar.
///
/// Designed in accordance with settled rules in:
/// - docs/crop-calendar-model.md (Yarımküre kuralı & Temsilî takvim matrisi)
/// - docs/game-design-brief.md (Section 2, Line 87, Personal season cycle anchor)
library;

/// The four distinct seasons in Farm World, repeating cyclically in order:
/// spring, summer, autumn, and winter.
enum Season { spring, summer, autumn, winter }

/// Planetary hemisphere determining the seasonal phase offset.
enum Hemisphere { northern, southern }

/// Immutable snapshot representing the game calendar state at a specific
/// elapsed duration and hemisphere.
///
/// **Cycle Anchor & Pure Mapper Contract:**
/// The supplied [elapsed] duration is measured from the save's first successful
/// planting, as specified in `docs/game-design-brief.md:87` (the personal 18-hour
/// season cycle begins upon first successful planting and continues offline).
/// [FarmCalendar] acts strictly as a pure mapper and does not store or manage
/// the first-planting event or its timestamp; the caller must supply elapsed
/// time measured from that anchor.
///
/// **Settled Calendar Rules:**
/// - A game year lasts exactly 18 real hours.
/// - The year is split into four 4.5-hour seasons in order:
///   spring -> summer -> autumn -> winter.
/// - Northern Hemisphere elapsed time starts at spring (0h).
/// - Southern Hemisphere is shifted forward by 9 real hours (half a year),
///   placing it in autumn at elapsed instant 0h.
/// - The calendar repeats cyclically every 18 hours.
///
/// **Boundary Determinism:**
/// Season intervals are half-open: `[start, end)`. At an exact boundary
/// multiple of 4.5 hours (e.g. 0h, 4.5h, 9h, 13.5h), the calendar
/// deterministically transitions to the new season with [timeInSeason]
/// at `Duration.zero` and [seasonProgress] at `0.0`.
class FarmCalendar {
  /// Default factory constructor resolving calendar state from [elapsed]
  /// duration measured since the save's first successful planting anchor,
  /// and [hemisphere].
  factory FarmCalendar({
    required Duration elapsed,
    Hemisphere hemisphere = Hemisphere.northern,
  }) => resolve(elapsed, hemisphere: hemisphere);

  /// Explicit factory matching [resolve].
  ///
  /// [elapsed] is measured from the save's first successful planting anchor.
  factory FarmCalendar.fromElapsed({
    required Duration elapsed,
    Hemisphere hemisphere = Hemisphere.northern,
  }) => resolve(elapsed, hemisphere: hemisphere);

  /// Convenience factory resolving the calendar directly from a persisted
  /// [firstSuccessfulPlantingAt] anchor and a supplied current timestamp [now].
  ///
  /// Both timestamps are normalized to UTC to compute elapsed time.
  ///
  /// This factory is a pure mapping function and does not read the system clock;
  /// the caller is expected to provide both timestamps explicitly.
  ///
  /// Delegates directly to [resolve], throwing [ArgumentError] if [now]
  /// is before [firstSuccessfulPlantingAt].
  factory FarmCalendar.fromPlantingAnchor({
    required DateTime firstSuccessfulPlantingAt,
    required DateTime now,
    Hemisphere hemisphere = Hemisphere.northern,
  }) {
    final utcAnchor = firstSuccessfulPlantingAt.toUtc();
    final utcNow = now.toUtc();
    final elapsed = utcNow.difference(utcAnchor);
    return resolve(elapsed, hemisphere: hemisphere);
  }

  const FarmCalendar._({
    required this.elapsed,
    required this.hemisphere,
    required this.season,
    required this.timeInYear,
    required this.timeInSeason,
    required this.yearProgress,
    required this.seasonProgress,
  });

  /// Total duration of one game year (18 real hours).
  static const Duration yearDuration = Duration(hours: 18);

  /// Duration of one game season (4.5 real hours / 4 hours 30 minutes).
  static const Duration seasonDuration = Duration(hours: 4, minutes: 30);

  /// Phase shift applied to the Southern Hemisphere (9 real hours / half year).
  static const Duration southernPhaseShift = Duration(hours: 9);

  /// Alias for [southernPhaseShift].
  static const Duration southernOffset = southernPhaseShift;

  /// Number of seasons in a year.
  static const int seasonsPerYear = 4;

  /// Total elapsed game duration supplied to this calendar snapshot, measured
  /// from the save's first successful planting anchor (docs/game-design-brief.md:87).
  final Duration elapsed;

  /// Hemisphere evaluated for this calendar snapshot.
  final Hemisphere hemisphere;

  /// Current local season.
  final Season season;

  /// Local elapsed time within the 18-hour year, ranging from `Duration.zero`
  /// to `yearDuration - 1 microsecond`.
  final Duration timeInYear;

  /// Local elapsed time within the current 4.5-hour season, ranging from
  /// `Duration.zero` to `seasonDuration - 1 microsecond`.
  final Duration timeInSeason;

  /// Normalized progress within the current year, in range `[0.0, 1.0)`.
  final double yearProgress;

  /// Normalized progress within the current season, in range `[0.0, 1.0)`.
  final double seasonProgress;

  // ---------------------------------------------------------------------------
  // Ergonomic Accessors
  // ---------------------------------------------------------------------------

  Season get localSeason => season;
  Duration get localTimeInYear => timeInYear;
  Duration get localTimeInSeason => timeInSeason;
  double get localYearProgress => yearProgress;
  double get localSeasonProgress => seasonProgress;

  bool get isSpring => season == Season.spring;
  bool get isSummer => season == Season.summer;
  bool get isAutumn => season == Season.autumn;
  bool get isWinter => season == Season.winter;

  /// Resolves the calendar state deterministically for [elapsed] and [hemisphere].
  ///
  /// [elapsed] is measured from the save's first successful planting anchor
  /// (docs/game-design-brief.md:87).
  ///
  /// Throws [ArgumentError] if [elapsed] is negative.
  static FarmCalendar resolve(
    Duration elapsed, {
    Hemisphere hemisphere = Hemisphere.northern,
  }) {
    if (elapsed.isNegative) {
      throw ArgumentError.value(
        elapsed,
        'elapsed',
        'Elapsed game duration cannot be negative.',
      );
    }

    final yearMicros = yearDuration.inMicroseconds;
    final seasonMicros = seasonDuration.inMicroseconds;
    final shiftMicros = hemisphere == Hemisphere.southern
        ? southernPhaseShift.inMicroseconds
        : 0;

    final elapsedInYearMicros = elapsed.inMicroseconds % yearMicros;
    final localYearMicros = (elapsedInYearMicros + shiftMicros) % yearMicros;

    final seasonIndex = localYearMicros ~/ seasonMicros;
    final season = Season.values[seasonIndex];
    final localSeasonMicros = localYearMicros % seasonMicros;

    final timeInYear = Duration(microseconds: localYearMicros);
    final timeInSeason = Duration(microseconds: localSeasonMicros);

    final yearProgress = localYearMicros / yearMicros;
    final seasonProgress = localSeasonMicros / seasonMicros;

    return FarmCalendar._(
      elapsed: elapsed,
      hemisphere: hemisphere,
      season: season,
      timeInYear: timeInYear,
      timeInSeason: timeInSeason,
      yearProgress: yearProgress,
      seasonProgress: seasonProgress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmCalendar &&
        other.elapsed == elapsed &&
        other.hemisphere == hemisphere &&
        other.season == season &&
        other.timeInYear == timeInYear &&
        other.timeInSeason == timeInSeason &&
        other.yearProgress == yearProgress &&
        other.seasonProgress == seasonProgress;
  }

  @override
  int get hashCode => Object.hash(
    elapsed,
    hemisphere,
    season,
    timeInYear,
    timeInSeason,
    yearProgress,
    seasonProgress,
  );

  @override
  String toString() =>
      'FarmCalendar(elapsed: $elapsed, hemisphere: ${hemisphere.name}, '
      'season: ${season.name}, timeInYear: $timeInYear, '
      'timeInSeason: $timeInSeason, yearProgress: $yearProgress, '
      'seasonProgress: $seasonProgress)';
}
