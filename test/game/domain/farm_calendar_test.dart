import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/farm_calendar.dart';

void main() {
  group('FarmCalendar - Constants and settled rules', () {
    test('settled calendar constants match docs/crop-calendar-model.md', () {
      expect(FarmCalendar.yearDuration, equals(const Duration(hours: 18)));
      expect(
        FarmCalendar.seasonDuration,
        equals(const Duration(hours: 4, minutes: 30)),
      );
      expect(
        FarmCalendar.southernPhaseShift,
        equals(const Duration(hours: 9)),
      );
      expect(
        FarmCalendar.southernOffset,
        equals(FarmCalendar.southernPhaseShift),
      );
      expect(FarmCalendar.seasonsPerYear, equals(4));

      expect(
        FarmCalendar.seasonDuration * FarmCalendar.seasonsPerYear,
        equals(FarmCalendar.yearDuration),
      );
      expect(
        FarmCalendar.southernPhaseShift * 2,
        equals(FarmCalendar.yearDuration),
      );
    });

    test('season enum follows strict design order: spring, summer, autumn, winter', () {
      expect(
        Season.values,
        equals([
          Season.spring,
          Season.summer,
          Season.autumn,
          Season.winter,
        ]),
      );
    });
  });

  group('FarmCalendar - Northern Hemisphere season boundaries', () {
    test('boundary 1: exact 0h starts Spring at 0.0 progress', () {
      final calendar = FarmCalendar.resolve(Duration.zero);

      expect(calendar.season, equals(Season.spring));
      expect(calendar.localSeason, equals(Season.spring));
      expect(calendar.isSpring, isTrue);
      expect(calendar.isSummer, isFalse);
      expect(calendar.isAutumn, isFalse);
      expect(calendar.isWinter, isFalse);

      expect(calendar.timeInYear, equals(Duration.zero));
      expect(calendar.localTimeInYear, equals(Duration.zero));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.localTimeInSeason, equals(Duration.zero));

      expect(calendar.yearProgress, equals(0.0));
      expect(calendar.localYearProgress, equals(0.0));
      expect(calendar.seasonProgress, equals(0.0));
      expect(calendar.localSeasonProgress, equals(0.0));
    });

    test('instant right before Summer boundary belongs to Spring', () {
      const almostSummer = Duration(
        hours: 4,
        minutes: 29,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999,
      );
      final calendar = FarmCalendar.resolve(almostSummer);

      expect(calendar.season, equals(Season.spring));
      expect(calendar.isSpring, isTrue);
      expect(calendar.timeInYear, equals(almostSummer));
      expect(calendar.timeInSeason, equals(almostSummer));
      expect(calendar.yearProgress, closeTo(0.25, 0.0001));
      expect(calendar.seasonProgress, closeTo(1.0, 0.0001));
      expect(calendar.seasonProgress, lessThan(1.0));
    });

    test('boundary 2: exact 4.5h deterministically transitions to Summer', () {
      const summerBoundary = Duration(hours: 4, minutes: 30);
      final calendar = FarmCalendar.resolve(summerBoundary);

      expect(calendar.season, equals(Season.summer));
      expect(calendar.isSummer, isTrue);
      expect(calendar.isSpring, isFalse);
      expect(calendar.timeInYear, equals(summerBoundary));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.yearProgress, equals(0.25));
      expect(calendar.seasonProgress, equals(0.0));
    });

    test('instant right before Autumn boundary belongs to Summer', () {
      const almostAutumn = Duration(
        hours: 8,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999,
      );
      final calendar = FarmCalendar.resolve(almostAutumn);

      expect(calendar.season, equals(Season.summer));
      expect(calendar.isSummer, isTrue);
      expect(calendar.timeInYear, equals(almostAutumn));
      expect(
        calendar.timeInSeason,
        equals(const Duration(
          hours: 4,
          minutes: 29,
          seconds: 59,
          milliseconds: 999,
          microseconds: 999,
        )),
      );
      expect(calendar.yearProgress, closeTo(0.5, 0.0001));
      expect(calendar.seasonProgress, closeTo(1.0, 0.0001));
      expect(calendar.seasonProgress, lessThan(1.0));
    });

    test('boundary 3: exact 9h deterministically transitions to Autumn', () {
      const autumnBoundary = Duration(hours: 9);
      final calendar = FarmCalendar.resolve(autumnBoundary);

      expect(calendar.season, equals(Season.autumn));
      expect(calendar.isAutumn, isTrue);
      expect(calendar.isSummer, isFalse);
      expect(calendar.timeInYear, equals(autumnBoundary));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.yearProgress, equals(0.5));
      expect(calendar.seasonProgress, equals(0.0));
    });

    test('instant right before Winter boundary belongs to Autumn', () {
      const almostWinter = Duration(
        hours: 13,
        minutes: 29,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999,
      );
      final calendar = FarmCalendar.resolve(almostWinter);

      expect(calendar.season, equals(Season.autumn));
      expect(calendar.isAutumn, isTrue);
      expect(calendar.timeInYear, equals(almostWinter));
      expect(
        calendar.timeInSeason,
        equals(const Duration(
          hours: 4,
          minutes: 29,
          seconds: 59,
          milliseconds: 999,
          microseconds: 999,
        )),
      );
      expect(calendar.yearProgress, closeTo(0.75, 0.0001));
      expect(calendar.seasonProgress, closeTo(1.0, 0.0001));
      expect(calendar.seasonProgress, lessThan(1.0));
    });

    test('boundary 4: exact 13.5h deterministically transitions to Winter', () {
      const winterBoundary = Duration(hours: 13, minutes: 30);
      final calendar = FarmCalendar.resolve(winterBoundary);

      expect(calendar.season, equals(Season.winter));
      expect(calendar.isWinter, isTrue);
      expect(calendar.isAutumn, isFalse);
      expect(calendar.timeInYear, equals(winterBoundary));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.yearProgress, equals(0.75));
      expect(calendar.seasonProgress, equals(0.0));
    });

    test('instant right before 18h year completion belongs to Winter', () {
      const almostYearEnd = Duration(
        hours: 17,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999,
      );
      final calendar = FarmCalendar.resolve(almostYearEnd);

      expect(calendar.season, equals(Season.winter));
      expect(calendar.isWinter, isTrue);
      expect(calendar.timeInYear, equals(almostYearEnd));
      expect(
        calendar.timeInSeason,
        equals(const Duration(
          hours: 4,
          minutes: 29,
          seconds: 59,
          milliseconds: 999,
          microseconds: 999,
        )),
      );
      expect(calendar.yearProgress, closeTo(1.0, 0.0001));
      expect(calendar.yearProgress, lessThan(1.0));
      expect(calendar.seasonProgress, closeTo(1.0, 0.0001));
      expect(calendar.seasonProgress, lessThan(1.0));
    });
  });

  group('FarmCalendar - Wraparound and cyclic repetition', () {
    test('exact 18h wraps around cleanly to Spring 0.0', () {
      final calendar = FarmCalendar.resolve(const Duration(hours: 18));

      expect(calendar.season, equals(Season.spring));
      expect(calendar.isSpring, isTrue);
      expect(calendar.timeInYear, equals(Duration.zero));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.yearProgress, equals(0.0));
      expect(calendar.seasonProgress, equals(0.0));
    });

    test('exact 36h (year 2 completion) wraps around to Spring 0.0', () {
      final calendar = FarmCalendar.resolve(const Duration(hours: 36));

      expect(calendar.season, equals(Season.spring));
      expect(calendar.timeInYear, equals(Duration.zero));
      expect(calendar.timeInSeason, equals(Duration.zero));
      expect(calendar.yearProgress, equals(0.0));
      expect(calendar.seasonProgress, equals(0.0));
    });

    test('arbitrary time into future cycle preserves intra-year progress', () {
      // 5 years (5 * 18h = 90h) + 6 hours = 96 hours.
      // 6 hours into year is 1.5 hours into Summer (Summer is 4.5h to 9h).
      final calendar = FarmCalendar.resolve(const Duration(hours: 96));

      expect(calendar.season, equals(Season.summer));
      expect(calendar.timeInYear, equals(const Duration(hours: 6)));
      expect(
        calendar.timeInSeason,
        equals(const Duration(hours: 1, minutes: 30)),
      );
      expect(calendar.yearProgress, closeTo(6.0 / 18.0, 0.00001));
      expect(calendar.seasonProgress, closeTo(1.5 / 4.5, 0.00001));
    });
  });

  group('FarmCalendar - Southern Hemisphere 9-hour phase shift', () {
    test('at elapsed 0h, Southern is shifted forward 9h into Autumn', () {
      final northern = FarmCalendar.resolve(
        Duration.zero,
        hemisphere: Hemisphere.northern,
      );
      final southern = FarmCalendar.resolve(
        Duration.zero,
        hemisphere: Hemisphere.southern,
      );

      expect(northern.season, equals(Season.spring));
      expect(southern.season, equals(Season.autumn));
      expect(southern.isAutumn, isTrue);

      expect(northern.timeInYear, equals(Duration.zero));
      expect(southern.timeInYear, equals(const Duration(hours: 9)));
      expect(southern.timeInSeason, equals(Duration.zero));
      expect(southern.yearProgress, equals(0.5));
      expect(southern.seasonProgress, equals(0.0));
    });

    test('all seasonal transitions for Southern Hemisphere are shifted by exactly 9 hours', () {
      final checkpoints = [
        (
          elapsed: Duration.zero,
          expectedNorth: Season.spring,
          expectedSouth: Season.autumn,
          southTimeInYear: const Duration(hours: 9),
        ),
        (
          elapsed: const Duration(hours: 4, minutes: 30),
          expectedNorth: Season.summer,
          expectedSouth: Season.winter,
          southTimeInYear: const Duration(hours: 13, minutes: 30),
        ),
        (
          elapsed: const Duration(hours: 9),
          expectedNorth: Season.autumn,
          expectedSouth: Season.spring,
          southTimeInYear: Duration.zero,
        ),
        (
          elapsed: const Duration(hours: 13, minutes: 30),
          expectedNorth: Season.winter,
          expectedSouth: Season.summer,
          southTimeInYear: const Duration(hours: 4, minutes: 30),
        ),
        (
          elapsed: const Duration(hours: 18),
          expectedNorth: Season.spring,
          expectedSouth: Season.autumn,
          southTimeInYear: const Duration(hours: 9),
        ),
      ];

      for (final cp in checkpoints) {
        final north = FarmCalendar.resolve(
          cp.elapsed,
          hemisphere: Hemisphere.northern,
        );
        final south = FarmCalendar.resolve(
          cp.elapsed,
          hemisphere: Hemisphere.southern,
        );

        expect(
          north.season,
          equals(cp.expectedNorth),
          reason: 'North season failed at ${cp.elapsed}',
        );
        expect(
          south.season,
          equals(cp.expectedSouth),
          reason: 'South season failed at ${cp.elapsed}',
        );
        expect(
          south.timeInYear,
          equals(cp.southTimeInYear),
          reason: 'South time in year failed at ${cp.elapsed}',
        );
        expect(
          south.timeInSeason,
          equals(Duration.zero),
          reason: 'South time in season boundary failed at ${cp.elapsed}',
        );
      }
    });

    test('southern timeInYear is always (northern + 9h) % 18h at any continuous instant', () {
      final sampleDeltas = [
        const Duration(minutes: 15),
        const Duration(hours: 2, minutes: 45),
        const Duration(hours: 7, minutes: 12),
        const Duration(hours: 11, minutes: 59),
        const Duration(hours: 16, minutes: 33),
      ];

      for (final delta in sampleDeltas) {
        final north = FarmCalendar.resolve(
          delta,
          hemisphere: Hemisphere.northern,
        );
        final south = FarmCalendar.resolve(
          delta,
          hemisphere: Hemisphere.southern,
        );

        final expectedSouthMicros =
            (north.timeInYear.inMicroseconds + const Duration(hours: 9).inMicroseconds) %
                const Duration(hours: 18).inMicroseconds;

        expect(
          south.timeInYear.inMicroseconds,
          equals(expectedSouthMicros),
          reason: 'Southern shift invariant failed at $delta',
        );
      }
    });
  });

  group('FarmCalendar - Equivalent cyclic instants', () {
    test('instants t and t + k * 18h yield identical cyclic states', () {
      final baseInstants = [
        Duration.zero,
        const Duration(hours: 1, minutes: 15),
        const Duration(hours: 4, minutes: 30),
        const Duration(hours: 8),
        const Duration(hours: 13, minutes: 30),
        const Duration(hours: 17, minutes: 45),
      ];

      final cycles = [1, 2, 5, 20, 100];

      for (final hemisphere in Hemisphere.values) {
        for (final base in baseInstants) {
          final reference = FarmCalendar.resolve(
            base,
            hemisphere: hemisphere,
          );

          for (final k in cycles) {
            final cyclicInstant = base + (const Duration(hours: 18) * k);
            final evaluated = FarmCalendar.resolve(
              cyclicInstant,
              hemisphere: hemisphere,
            );

            expect(
              evaluated.season,
              equals(reference.season),
              reason: 'Season mismatch for $base + $k cycles in $hemisphere',
            );
            expect(
              evaluated.timeInYear,
              equals(reference.timeInYear),
              reason: 'timeInYear mismatch for $base + $k cycles in $hemisphere',
            );
            expect(
              evaluated.timeInSeason,
              equals(reference.timeInSeason),
              reason: 'timeInSeason mismatch for $base + $k cycles in $hemisphere',
            );
            expect(
              evaluated.yearProgress,
              closeTo(reference.yearProgress, 0.0000001),
              reason: 'yearProgress mismatch for $base + $k cycles in $hemisphere',
            );
            expect(
              evaluated.seasonProgress,
              closeTo(reference.seasonProgress, 0.0000001),
              reason: 'seasonProgress mismatch for $base + $k cycles in $hemisphere',
            );
          }
        }
      }
    });
  });

  group('FarmCalendar - Input validation', () {
    test('negative elapsed duration throws ArgumentError', () {
      final invalidDurations = [
        const Duration(microseconds: -1),
        const Duration(milliseconds: -1),
        const Duration(seconds: -1),
        const Duration(hours: -1),
        const Duration(hours: -18),
      ];

      for (final invalid in invalidDurations) {
        expect(
          () => FarmCalendar.resolve(invalid),
          throwsArgumentError,
          reason: 'Did not throw for negative duration $invalid',
        );
        expect(
          () => FarmCalendar(elapsed: invalid),
          throwsArgumentError,
          reason: 'Factory constructor did not throw for $invalid',
        );
        expect(
          () => FarmCalendar.fromElapsed(elapsed: invalid),
          throwsArgumentError,
          reason: 'Named factory did not throw for $invalid',
        );
      }
    });

    test('non-negative elapsed durations succeed without error', () {
      expect(
        () => FarmCalendar.resolve(Duration.zero),
        returnsNormally,
      );
      expect(
        () => FarmCalendar.resolve(const Duration(microseconds: 1)),
        returnsNormally,
      );
      expect(
        () => FarmCalendar.resolve(const Duration(hours: 1000)),
        returnsNormally,
      );
    });

    test('near max signed 64-bit microsecond duration resolves deterministically without overflow', () {
      const maxDuration = Duration(microseconds: 0x7fffffffffffffff);

      expect(
        () => FarmCalendar.resolve(maxDuration, hemisphere: Hemisphere.northern),
        returnsNormally,
      );
      expect(
        () => FarmCalendar.resolve(maxDuration, hemisphere: Hemisphere.southern),
        returnsNormally,
      );

      final north = FarmCalendar.resolve(
        maxDuration,
        hemisphere: Hemisphere.northern,
      );
      final south = FarmCalendar.resolve(
        maxDuration,
        hemisphere: Hemisphere.southern,
      );

      const expectedNorthMicros = 0x7fffffffffffffff % 64800000000;
      const expectedSouthMicros =
          (expectedNorthMicros + 32400000000) % 64800000000;

      expect(north.season, equals(Season.spring));
      expect(
        north.timeInYear,
        equals(const Duration(microseconds: expectedNorthMicros)),
      );
      expect(
        north.timeInSeason,
        equals(const Duration(microseconds: expectedNorthMicros)),
      );
      expect(
        north.yearProgress,
        closeTo(expectedNorthMicros / 64800000000, 0.0000001),
      );
      expect(
        north.seasonProgress,
        closeTo(expectedNorthMicros / 16200000000, 0.0000001),
      );

      expect(south.season, equals(Season.autumn));
      expect(
        south.timeInYear,
        equals(const Duration(microseconds: expectedSouthMicros)),
      );
      expect(
        south.timeInSeason,
        equals(const Duration(microseconds: expectedNorthMicros)),
      );
      expect(
        south.yearProgress,
        closeTo(expectedSouthMicros / 64800000000, 0.0000001),
      );
      expect(
        south.seasonProgress,
        closeTo(expectedNorthMicros / 16200000000, 0.0000001),
      );
    });
  });

  group('FarmCalendar - API constructors, equality, and formatting', () {
    test('constructors and factories produce equivalent instances', () {
      const elapsed = Duration(hours: 5, minutes: 15);
      final fromDefault = FarmCalendar(elapsed: elapsed);
      final fromNamed = FarmCalendar.fromElapsed(elapsed: elapsed);
      final fromResolve = FarmCalendar.resolve(elapsed);

      expect(fromDefault, equals(fromNamed));
      expect(fromNamed, equals(fromResolve));
      expect(fromDefault.hashCode, equals(fromResolve.hashCode));
    });

    test('toString includes key diagnostic metadata', () {
      final calendar = FarmCalendar.resolve(const Duration(hours: 1));
      final text = calendar.toString();

      expect(text, contains('FarmCalendar'));
      expect(text, contains('spring'));
      expect(text, contains('northern'));
    });
  });

  group('FarmCalendar - fromPlantingAnchor convenience factory', () {
    test('resolves season boundaries directly from anchor and now timestamps', () {
      final anchor = DateTime.utc(2026, 10, 11, 8, 0);

      // Boundary 1: At anchor instant (0h) -> Spring, 0.0 progress.
      final cal0 = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: anchor,
      );
      expect(cal0.season, equals(Season.spring));
      expect(cal0.timeInYear, equals(Duration.zero));
      expect(cal0.timeInSeason, equals(Duration.zero));
      expect(cal0.yearProgress, equals(0.0));
      expect(cal0.seasonProgress, equals(0.0));

      // Boundary 2: Exactly 4.5h after anchor -> Summer start.
      final summerInstant = anchor.add(const Duration(hours: 4, minutes: 30));
      final calSummer = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: summerInstant,
      );
      expect(calSummer.season, equals(Season.summer));
      expect(calSummer.timeInYear, equals(const Duration(hours: 4, minutes: 30)));
      expect(calSummer.timeInSeason, equals(Duration.zero));
      expect(calSummer.yearProgress, equals(0.25));

      // Boundary 3: Exactly 9h after anchor -> Autumn start.
      final autumnInstant = anchor.add(const Duration(hours: 9));
      final calAutumn = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: autumnInstant,
      );
      expect(calAutumn.season, equals(Season.autumn));
      expect(calAutumn.timeInYear, equals(const Duration(hours: 9)));
      expect(calAutumn.timeInSeason, equals(Duration.zero));

      // Boundary 4: Exactly 13.5h after anchor -> Winter start.
      final winterInstant = anchor.add(const Duration(hours: 13, minutes: 30));
      final calWinter = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: winterInstant,
      );
      expect(calWinter.season, equals(Season.winter));
      expect(calWinter.timeInYear, equals(const Duration(hours: 13, minutes: 30)));
      expect(calWinter.timeInSeason, equals(Duration.zero));

      // Wraparound: Exactly 18h after anchor -> wraps to Spring.
      final wrapInstant = anchor.add(const Duration(hours: 18));
      final calWrap = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: wrapInstant,
      );
      expect(calWrap.season, equals(Season.spring));
      expect(calWrap.timeInYear, equals(Duration.zero));
    });

    test('normalizes timestamps to UTC across mixed timezones', () {
      // Local timezone anchors
      final localAnchor = DateTime(2026, 10, 11, 10, 0);
      final localNow = localAnchor.add(const Duration(hours: 4, minutes: 30));

      final cal = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: localAnchor,
        now: localNow,
      );

      expect(cal.season, equals(Season.summer));
      expect(cal.elapsed, equals(const Duration(hours: 4, minutes: 30)));
    });

    test('respects Southern Hemisphere 9-hour phase shift from anchor', () {
      final anchor = DateTime.utc(2026, 10, 11, 8, 0);

      // Instant 0h: Northern is Spring, Southern is Autumn.
      final south0 = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: anchor,
        hemisphere: Hemisphere.southern,
      );
      expect(south0.season, equals(Season.autumn));
      expect(south0.timeInYear, equals(const Duration(hours: 9)));
      expect(south0.timeInSeason, equals(Duration.zero));
      expect(south0.yearProgress, equals(0.5));

      // 4.5h: Northern is Summer, Southern is Winter.
      final south45 = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: anchor.add(const Duration(hours: 4, minutes: 30)),
        hemisphere: Hemisphere.southern,
      );
      expect(south45.season, equals(Season.winter));
      expect(south45.timeInYear, equals(const Duration(hours: 13, minutes: 30)));
      expect(south45.timeInSeason, equals(Duration.zero));

      // 9h: Northern is Autumn, Southern is Spring.
      final south9 = FarmCalendar.fromPlantingAnchor(
        firstSuccessfulPlantingAt: anchor,
        now: anchor.add(const Duration(hours: 9)),
        hemisphere: Hemisphere.southern,
      );
      expect(south9.season, equals(Season.spring));
      expect(south9.timeInYear, equals(Duration.zero));
      expect(south9.timeInSeason, equals(Duration.zero));
    });

    test('throws ArgumentError when current time is before the anchor', () {
      final anchor = DateTime.utc(2026, 10, 11, 12, 0);

      final beforeAnchorCases = [
        anchor.subtract(const Duration(microseconds: 1)),
        anchor.subtract(const Duration(seconds: 1)),
        anchor.subtract(const Duration(hours: 1)),
        anchor.subtract(const Duration(days: 30)),
      ];

      for (final pastTime in beforeAnchorCases) {
        expect(
          () => FarmCalendar.fromPlantingAnchor(
            firstSuccessfulPlantingAt: anchor,
            now: pastTime,
          ),
          throwsArgumentError,
          reason: 'Did not throw for now ($pastTime) before anchor ($anchor)',
        );
        expect(
          () => FarmCalendar.fromPlantingAnchor(
            firstSuccessfulPlantingAt: anchor,
            now: pastTime,
            hemisphere: Hemisphere.southern,
          ),
          throwsArgumentError,
          reason: 'Did not throw for Southern hemisphere before anchor',
        );
      }
    });
  });
}
