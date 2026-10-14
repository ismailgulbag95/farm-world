import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';

/// Images used by the opening farm scene. Files stay in their source folders;
/// Flame is configured with the project `assets/` directory as its prefix.
class FarmWorldArtwork {
  FarmWorldArtwork._({
    required this.meadowGround,
    required this.mownMeadow,
    required this.salePlatform,
    required this.strawBale,
    required this.wheatField,
    required this.maizeField,
    required this.sunflowerField,
    required this.potatoField,
    required this.sunflowerEarly,
    required this.sunflowerMid,
    required this.potatoEarly,
    required this.potatoMid,
    required this.cerealEarly,
    required this.cerealMid,
    required this.chickpeaStages,
    required this.mowingScythe,
    required this.miniMower,
    required this.employee,
    required this.starterGrainTruck,
    required this.starterBuildings,
  });

  final ui.Image meadowGround;
  final ui.Image mownMeadow;
  final Sprite salePlatform;
  final Sprite strawBale;
  final ui.Image wheatField;
  final ui.Image maizeField;
  final ui.Image sunflowerField;
  final ui.Image potatoField;
  final ui.Image sunflowerEarly;
  final ui.Image sunflowerMid;
  final ui.Image potatoEarly;
  final ui.Image potatoMid;
  final ui.Image cerealEarly;
  final ui.Image cerealMid;
  final ui.Image chickpeaStages;
  final SpriteSheet mowingScythe;
  final Sprite miniMower;
  final SpriteSheet employee;
  final Sprite starterGrainTruck;
  final SpriteSheet starterBuildings;

  static Future<FarmWorldArtwork> load(Images images) async {
    const paths = <String>[
      'images/opening/meadow-ground-v1.png',
      'images/opening/mown-meadow-v1.png',
      'images/opening/sale-platform-v1.png',
      'images/opening/straw-bale-v1.png',
      'visual-concepts/pilot/crop-wheat-mature-v1.png',
      'visual-concepts/pilot/crop-maize-mature-v1.png',
      'visual-concepts/pilot/vehicle-mini-mower-v1.png',
      'visual-concepts/pilot/worker-employee-turnaround-v1.png',
      'visual-concepts/pilot/crop-cereal-early-v1.png',
      'visual-concepts/pilot/crop-cereal-mid-v1.png',
      'visual-concepts/pilot/vehicle-starter-grain-truck-v1.png',
      'visual-concepts/pilot/crop-sunflower-mature-v1.png',
      'visual-concepts/pilot/crop-potato-mature-v1.png',
      'visual-concepts/pilot/crop-sunflower-early-v1.png',
      'visual-concepts/pilot/crop-sunflower-mid-v1.png',
      'visual-concepts/pilot/crop-potato-early-v1.png',
      'visual-concepts/pilot/crop-potato-mid-v1.png',
      'visual-concepts/pilot/crop-chickpea-stages-v1.png',
      'visual-concepts/pilot/scythe-mowing-overhead-v1.png',
      'images/management/starter-buildings-v1.png',
    ];
    final loaded = await images.loadAll(paths);
    final byPath = <String, ui.Image>{
      for (var index = 0; index < paths.length; index++)
        paths[index]: loaded[index],
    };

    final employeeImage = byPath[paths[7]]!;
    return FarmWorldArtwork._(
      meadowGround: byPath[paths[0]]!,
      mownMeadow: byPath[paths[1]]!,
      salePlatform: Sprite(byPath[paths[2]]!),
      strawBale: Sprite(byPath[paths[3]]!),
      wheatField: byPath[paths[4]]!,
      maizeField: byPath[paths[5]]!,
      sunflowerField: byPath[paths[11]]!,
      potatoField: byPath[paths[12]]!,
      sunflowerEarly: byPath[paths[13]]!,
      sunflowerMid: byPath[paths[14]]!,
      potatoEarly: byPath[paths[15]]!,
      potatoMid: byPath[paths[16]]!,
      cerealEarly: byPath[paths[8]]!,
      cerealMid: byPath[paths[9]]!,
      chickpeaStages: byPath[paths[17]]!,
      mowingScythe: SpriteSheet.fromColumnsAndRows(
        image: byPath[paths[18]]!,
        columns: 4,
        rows: 4,
      ),
      miniMower: Sprite(byPath[paths[6]]!),
      employee: SpriteSheet.fromColumnsAndRows(
        image: employeeImage,
        columns: 2,
        rows: 2,
      ),
      starterGrainTruck: Sprite(byPath[paths[10]]!),
      starterBuildings: SpriteSheet.fromColumnsAndRows(
        image: byPath[paths[19]]!,
        columns: 3,
        rows: 1,
      ),
    );
  }
}
