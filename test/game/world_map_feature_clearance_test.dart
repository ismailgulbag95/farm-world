import 'package:farm_world/game/domain/procedural_farm_world.dart';
import 'package:flutter_test/flutter_test.dart';

bool _parcelFootprintsHaveClearance(
  WorldMapParcel first,
  WorldMapParcel second, {
  double clearance = 24,
}) {
  final firstLeft = first.center.x - first.width / 2;
  final firstRight = first.center.x + first.width / 2;
  final firstTop = first.center.y - first.height / 2;
  final firstBottom = first.center.y + first.height / 2;
  final secondLeft = second.center.x - second.width / 2;
  final secondRight = second.center.x + second.width / 2;
  final secondTop = second.center.y - second.height / 2;
  final secondBottom = second.center.y + second.height / 2;

  return firstRight + clearance <= secondLeft ||
      secondRight + clearance <= firstLeft ||
      firstBottom + clearance <= secondTop ||
      secondBottom + clearance <= firstTop;
}

void main() {
  test('roadside landmarks stay clear of terrain and owned land', () {
    final world = ProceduralFarmWorld();
    var landmarks = 0;
    for (var y = -2; y <= 2; y++) {
      for (var x = -2; x <= 2; x++) {
        final chunk = world.chunkAt(x, y);
        for (final landmark in chunk.pointsOfInterest) {
          landmarks++;
          final point = landmark.position;
          for (final pond in chunk.ponds) {
            final dx = (point.x - pond.center.x) / (pond.width / 2 + 58);
            final dy = (point.y - pond.center.y) / (pond.height / 2 + 58);
            expect(dx * dx + dy * dy, greaterThan(1));
          }
          for (final mountain in chunk.mountains) {
            final dx =
                (point.x - mountain.center.x) / (mountain.width / 2 + 58);
            final dy =
                (point.y - mountain.center.y) / (mountain.height / 2 + 58);
            expect(dx * dx + dy * dy, greaterThan(1));
          }
          for (final lake in world.lakes) {
            expect(
              lake.bounds.inflate(58).contains(Offset(point.x, point.y)),
              isFalse,
            );
          }
          for (final parcel in chunk.parcels) {
            expect(parcel.contains(point, padding: 58), isFalse);
          }
        }
      }
    }
    expect(landmarks, greaterThan(0));
  });

  test('nearby roadside landmarks do not overlap each other', () {
    double footprint(WorldPointOfInterestType type) => switch (type) {
      WorldPointOfInterestType.water => 58,
      WorldPointOfInterestType.village => 108,
      WorldPointOfInterestType.mill => 78,
      WorldPointOfInterestType.timberYard => 88,
    };

    for (final seed in [ProceduralFarmWorld.defaultSeed, 17, 42, 2026]) {
      final world = ProceduralFarmWorld(seed: seed);
      final landmarks = [
        for (var y = -5; y <= 5; y++)
          for (var x = -5; x <= 5; x++) ...world.chunkAt(x, y).pointsOfInterest,
      ];
      for (var left = 0; left < landmarks.length; left++) {
        for (var right = left + 1; right < landmarks.length; right++) {
          final first = landmarks[left];
          final second = landmarks[right];
          expect(
            first.position.distanceTo(second.position),
            greaterThanOrEqualTo(
              footprint(first.type) + footprint(second.type) + 24,
            ),
            reason: 'seed=$seed: ${first.id} overlaps ${second.id}',
          );
        }
      }
    }
  });

  test('farm parcel boundaries keep a clear gap across map district seams', () {
    for (final seed in [ProceduralFarmWorld.defaultSeed, 42, 2026]) {
      final world = ProceduralFarmWorld(seed: seed);
      final parcelsById = <String, WorldMapParcel>{};
      for (var y = -6; y <= 5; y++) {
        for (var x = -6; x <= 5; x++) {
          for (final parcel in world.chunkAt(x, y).parcels) {
            parcelsById[parcel.id] = parcel;
          }
        }
      }

      final parcels = parcelsById.values.toList();
      for (var first = 0; first < parcels.length; first++) {
        for (var second = first + 1; second < parcels.length; second++) {
          expect(
            _parcelFootprintsHaveClearance(parcels[first], parcels[second]),
            isTrue,
            reason:
                'seed=$seed: ${parcels[first].id} overlaps ${parcels[second].id}',
          );
        }
      }
    }
  });

  test('farm parcel seam resolution is independent of chunk load order', () {
    const coordinates = [(3, 3), (4, 3), (3, 4), (4, 4)];
    final firstWorld = ProceduralFarmWorld(seed: 42);
    final secondWorld = ProceduralFarmWorld(seed: 42);

    List<String> parcelGeometry(
      ProceduralFarmWorld world,
      Iterable<(int, int)> chunkOrder,
    ) {
      final geometry = [
        for (final (x, y) in chunkOrder)
          for (final parcel in world.chunkAt(x, y).parcels)
            '${parcel.id}:${parcel.center.x}:${parcel.center.y}',
      ]..sort();
      return geometry;
    }

    expect(
      parcelGeometry(firstWorld, coordinates),
      equals(parcelGeometry(secondWorld, coordinates.toList().reversed)),
    );
  });

  test('upgrading the map preserves purchased parcels and clears new land', () {
    const seed = ProceduralFarmWorld.defaultSeed;
    final previousWorld = ProceduralFarmWorld(
      seed: seed,
      generationVersion: ProceduralFarmWorld.collisionSafeGenerationVersion,
    );
    WorldMapParcel? purchasedParcel;
    for (var y = -6; y <= 5 && purchasedParcel == null; y++) {
      for (var x = -6; x <= 5 && purchasedParcel == null; x++) {
        purchasedParcel = previousWorld
            .chunkAt(x, y)
            .parcels
            .where((parcel) => !parcel.isHome)
            .firstOrNull;
      }
    }
    expect(purchasedParcel, isNotNull);

    final updatedWorld = ProceduralFarmWorld(
      seed: seed,
      preservedParcelIds: [purchasedParcel!.id],
    );
    final restoredParcel = updatedWorld.parcelById(purchasedParcel.id);
    expect(restoredParcel, isNotNull);
    expect(restoredParcel!.center.x, purchasedParcel.center.x);
    expect(restoredParcel.center.y, purchasedParcel.center.y);
    expect(restoredParcel.width, purchasedParcel.width);
    expect(restoredParcel.height, purchasedParcel.height);

    final ownerX = (purchasedParcel.center.x / farmWorldChunkSize).floor();
    final ownerY = (purchasedParcel.center.y / farmWorldChunkSize).floor();
    for (var y = ownerY - 2; y <= ownerY + 2; y++) {
      for (var x = ownerX - 2; x <= ownerX + 2; x++) {
        for (final parcel in updatedWorld.chunkAt(x, y).parcels) {
          expect(
            _parcelFootprintsHaveClearance(restoredParcel, parcel),
            isTrue,
            reason:
                'purchased ${restoredParcel.id} conflicts with ${parcel.id}',
          );
        }
      }
    }
  });
}
