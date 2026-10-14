import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'domain/opening_session.dart';
import 'domain/opening_crop_catalog.dart';
import 'farm_world_artwork.dart';
import 'components/grass_particle.dart';
import 'components/floating_text.dart';
import 'components/backpack_stack.dart';
import 'components/upgrade_station.dart';
import 'components/worker_ai.dart';
import 'components/crop_plot_component.dart';
import 'components/truck_component.dart';
import 'components/route_visual_component.dart';
import 'components/factory_component.dart';
import 'components/coop_component.dart';

enum ManagementMapSelection { starterPlot, farmhouse, grainBarn, toolShed }

/// Gameplay world for the hand-mowing opening and the first worker handoff.
class OpeningMowingWorld extends World {
  OpeningMowingWorld({
    OpeningSession? session,
    Rect? playArea,
    Rect? grassArea,
    Rect? saleZoneArea,
  }) : session = session ?? OpeningSession(),
       playArea = playArea ?? defaultPlayArea,
       grassArea = grassArea ?? defaultGrassArea,
       saleZoneArea = saleZoneArea ?? defaultSaleZoneArea {
    _initializeComponents();
  }

  final OpeningSession session;
  final Rect playArea;
  final Rect grassArea;
  final Rect saleZoneArea;

  static final Rect defaultPlayArea = Rect.fromCenter(
    center: Offset.zero,
    width: 900,
    height: 620,
  );
  static final Rect defaultGrassArea = Rect.fromCenter(
    center: const Offset(0, -95),
    width: 600,
    height: 364,
  );
  static final Rect defaultSaleZoneArea = Rect.fromCenter(
    center: const Offset(0, 150),
    width: 220,
    height: 80,
  );

  late final MeadowBackdropComponent meadowBackdrop = MeadowBackdropComponent();
  late final FarmGroundComponent farmGround;
  late final GrassFieldComponent grassField;
  late final SaleZoneComponent saleZone;
  late final PlayerCharacterComponent player;
  late final FarmHandComponent farmHand;
  late final StarterCropPlotComponent starterCropPlot;
  late final FarmBuildingComponent farmhouse;
  late final FarmBuildingComponent grainBarn;
  late final FarmBuildingComponent toolShed;
  FarmWorldArtwork? artwork;

  final ValueNotifier<ManagementMapSelection> selectedMapItem = ValueNotifier(
    ManagementMapSelection.starterPlot,
  );

  final List<GroundBaleComponent> groundBales = [];
  final List<Vector2> cutTrailPoints = [];
  final List<UpgradePadComponent> upgradePads = [];
  final List<InteractiveCropPlotComponent> expansionPlots = [];
  final List<TruckVehicleComponent> truckComponents = [];
  final List<FactoryBuildingComponent> factoryComponents = [];
  late final BackpackStackComponent backpackStack;
  late final AutonomousWorkerComponent autonomousWorker;
  late final RouteVisualComponent routeVisual;
  late final ChickenCoopComponent coopComponent;

  JoystickComponent? joystick;
  Vector2? movementInputOverride;

  void _initializeComponents() {
    routeVisual = RouteVisualComponent(fleetManager: session.fleetManager);
    farmGround = FarmGroundComponent(area: playArea);
    saleZone = SaleZoneComponent(area: saleZoneArea, session: session);
    grassField = GrassFieldComponent(
      area: grassArea,
      cutTrailPoints: cutTrailPoints,
      session: session,
    );
    player = PlayerCharacterComponent(
      position: Vector2(0, 50),
      session: session,
    );
    backpackStack = BackpackStackComponent(session: session);
    player.add(backpackStack);

    farmHand = FarmHandComponent(position: Vector2(0, -28));
    autonomousWorker = AutonomousWorkerComponent(
      position: Vector2(0, -28),
      session: session,
      barnPosition: Vector2(238, 38),
    );

    starterCropPlot = StarterCropPlotComponent(
      position: Vector2(-165, -175),
      size: Vector2(126, 92),
      session: session,
      selectedMapItem: selectedMapItem,
    );

    expansionPlots.clear();
    for (final plot in session.plots) {
      if (plot.id == 0) continue;
      expansionPlots.add(
        InteractiveCropPlotComponent(
          plotId: plot.id,
          position: Vector2(plot.positionX, plot.positionY),
          size: Vector2(126, 92),
          session: session,
          selectedMapItem: selectedMapItem,
        ),
      );
    }

    farmhouse = FarmBuildingComponent(
      position: Vector2(252, -226),
      size: Vector2(136, 136),
      session: session,
      selectedMapItem: selectedMapItem,
      selection: ManagementMapSelection.farmhouse,
      spriteIndex: 0,
    );
    grainBarn = FarmBuildingComponent(
      position: Vector2(238, 38),
      size: Vector2(152, 152),
      session: session,
      selectedMapItem: selectedMapItem,
      selection: ManagementMapSelection.grainBarn,
      spriteIndex: 1,
    );
    toolShed = FarmBuildingComponent(
      position: Vector2(-388, 44),
      size: Vector2(132, 132),
      session: session,
      selectedMapItem: selectedMapItem,
      selection: ManagementMapSelection.toolShed,
      spriteIndex: 2,
    );

    factoryComponents.clear();
    for (final facility in session.plantManager.facilities.where(
      (facility) => facility.isUnlocked,
    )) {
      factoryComponents.add(FactoryBuildingComponent(facility: facility));
    }

    coopComponent = ChickenCoopComponent(
      coop: session.coop,
      position: Vector2(-310, -60),
    );

    _createUpgradePads();
  }

  void _createUpgradePads() {
    upgradePads.clear();
    final padsConfig = [
      (Vector2(-190, 150), UpgradePadType.capacity),
      (Vector2(-105, 150), UpgradePadType.speed),
      (Vector2(105, 150), UpgradePadType.range),
      (Vector2(190, 150), UpgradePadType.miniMower),
      (Vector2(275, 150), UpgradePadType.worker),
    ];
    for (final cfg in padsConfig) {
      upgradePads.add(
        UpgradePadComponent(
          position: cfg.$1,
          type: cfg.$2,
          session: session,
          onPurchased: _onUpgradePurchased,
        ),
      );
    }
  }

  void _onUpgradePurchased(UpgradePadType type, Vector2 pos) {
    String message;
    switch (type) {
      case UpgradePadType.capacity:
        message = '🎒 +10 KAPASİTE!';
        break;
      case UpgradePadType.speed:
        message = '⚡ +HIZ!';
        break;
      case UpgradePadType.range:
        message = '✂️ +BIÇAK MENZİLİ!';
        break;
      case UpgradePadType.miniMower:
        message = '🚜 BİÇME MAKİNESİ!';
        break;
      case UpgradePadType.worker:
        message = '👨‍🌾 İŞÇİ DEVREDE!';
        break;
    }
    add(FloatingTextComponent(position: pos + Vector2(0, -20), text: message));
  }

  void setArtwork(FarmWorldArtwork artwork) {
    this.artwork = artwork;
    meadowBackdrop.artwork = artwork;
    farmGround.artwork = artwork;
    grassField.artwork = artwork;
    saleZone.artwork = artwork;
    player.artwork = artwork;
    farmHand.artwork = artwork;
    starterCropPlot.artwork = artwork;
    farmhouse.artwork = artwork;
    grainBarn.artwork = artwork;
    toolShed.artwork = artwork;
    backpackStack.artwork = artwork;
    autonomousWorker.artwork = artwork;
    for (final ep in expansionPlots) {
      ep.artwork = artwork;
    }
    for (final bale in groundBales) {
      bale.artwork = artwork;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(meadowBackdrop);
    add(farmGround);
    add(saleZone);
    add(grassField);
    add(player);
    for (final ep in expansionPlots) {
      add(ep);
    }
    add(farmhouse);
    add(grainBarn);
    add(toolShed);

    for (final pad in upgradePads) {
      add(pad);
    }

    while (groundBales.length < session.groundBaleCount) {
      _spawnGroundBale(spawnNearPlayer: false);
    }
    if (session.stage == OpeningStage.management) {
      add(farmHand);
      add(autonomousWorker);
      add(routeVisual);
      add(coopComponent);
      for (final f in factoryComponents) {
        add(f);
      }
      _syncTruckComponents();
    }
  }

  void startManagementView() {
    for (final bale in List<GroundBaleComponent>.from(groundBales)) {
      bale.removeFromParent();
    }
    groundBales.clear();

    if (farmHand.parent == null) {
      add(farmHand);
    }
    if (autonomousWorker.parent == null) {
      add(autonomousWorker);
    }
    if (routeVisual.parent == null) {
      add(routeVisual);
    }
    if (coopComponent.parent == null) {
      add(coopComponent);
    }
    for (final f in factoryComponents) {
      if (f.parent == null) add(f);
    }
    _syncTruckComponents();
  }

  void _syncTruckComponents() {
    final activeTrucks = session.fleetManager.vehicles;
    for (final truck in activeTrucks) {
      if (!truckComponents.any((c) => c.vehicleId == truck.id)) {
        final comp = TruckVehicleComponent(
          vehicleId: truck.id,
          fleetManager: session.fleetManager,
        );
        truckComponents.add(comp);
        add(comp);
      }
    }
  }

  void setMovementInput(Vector2? input) {
    movementInputOverride = input;
  }

  Vector2 get currentMovementInput =>
      movementInputOverride ?? joystick?.relativeDelta ?? Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0 || !dt.isFinite) {
      return;
    }

    if (session.stage == OpeningStage.management) {
      session.advanceLogistics(dt);
      session.advanceProcessing(dt);
      session.advanceLivestock(dt);
      _syncTruckComponents();
      return;
    }

    var remaining = dt;
    const maxSubStep = 0.05;
    while (remaining > 0) {
      final step = min(remaining, maxSubStep);
      _updatePhysicsStep(step);
      remaining -= step;
    }
  }

  void _updatePhysicsStep(double dt) {
    final input = currentMovementInput;
    final isMoving = input.length > 0.01;

    if (isMoving) {
      player.move(input, dt);
      _clampPlayerPosition();
      backpackStack.triggerStepWobble(input.length);

      final cuttingPoint = grassField.cuttingPointAheadAt(
        player.position,
        player.facingDirection,
      );
      final onUncutGrass = grassField.hasUncutGrassAt(cuttingPoint);
      final didMow = onUncutGrass && session.canMow && session.mow(dt);
      player.updateMowing(didMow, dt);
      if (didMow) {
        _burstGrassParticles(cuttingPoint);
        final newBales = session.groundBaleCount - groundBales.length;
        for (var i = 0; i < newBales; i++) {
          _spawnGroundBale(spawnNearPlayer: true);
        }
        _recordCutTrail(cuttingPoint);
      }
    } else {
      player.stopMoving();
    }

    for (final pad in upgradePads) {
      pad.tryInteract(player.position);
    }

    _checkBalePickup();
    _checkSaleZone(dt);
  }

  void _burstGrassParticles(Vector2 origin) {
    final rand = Random();
    final count = 2 + rand.nextInt(3);
    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final speed = 35.0 + rand.nextDouble() * 65.0;
      final vel = Vector2(cos(angle) * speed, -40.0 - rand.nextDouble() * 50.0);
      add(GrassParticleComponent(position: origin.clone(), velocity: vel));
    }
  }

  void _clampPlayerPosition() {
    const margin = 16.0;
    final clampedX = player.position.x.clamp(
      playArea.left + margin,
      playArea.right - margin,
    );
    final clampedY = player.position.y.clamp(
      playArea.top + margin,
      playArea.bottom - margin,
    );
    player.position.setValues(clampedX, clampedY);
  }

  void _spawnGroundBale({bool spawnNearPlayer = true}) {
    const baleDropDistance = 56.0;
    final spawnPos = spawnNearPlayer
        ? player.position +
              (player.facingDirection.isZero()
                  ? Vector2(0, baleDropDistance)
                  : -player.facingDirection.normalized() * baleDropDistance)
        : Vector2(-74, -20);

    final bale = GroundBaleComponent(position: spawnPos)..artwork = artwork;
    groundBales.add(bale);
    add(bale);
  }

  void _recordCutTrail(Vector2 position) {
    if (cutTrailPoints.isEmpty ||
        (cutTrailPoints.last - position).length >= 10) {
      cutTrailPoints.add(position.clone());
      if (cutTrailPoints.length > 500) {
        cutTrailPoints.removeAt(0);
      }
    }
  }

  void _checkBalePickup() {
    if (!session.canPickUpBale) return;

    for (final bale in List<GroundBaleComponent>.from(groundBales)) {
      if ((player.position - bale.position).length <= 36) {
        if (session.pickUpBale()) {
          groundBales.remove(bale);
          bale.removeFromParent();
          player.updateMowing(false, 0);
          break;
        }
      }
    }
  }

  double _saleIntervalTimer = 0.0;

  void _checkSaleZone([double dt = 0.0]) {
    if (!saleZoneArea.contains(player.position.toOffset())) {
      _saleIntervalTimer = 0.0;
      return;
    }

    _saleIntervalTimer += dt;
    if (session.carriedBaleCount > 0 && _saleIntervalTimer >= 0.08) {
      _saleIntervalTimer = 0.0;
      if (session.sellOneBale()) {
        saleZone.triggerSaleEffect();
        add(
          FloatingTextComponent(
            position: Vector2(
              saleZoneArea.center.dx + (Random().nextDouble() - 0.5) * 40,
              saleZoneArea.center.dy,
            ),
            text: '+30 ÇK',
          ),
        );
      }
    } else if (session.canSellBale && session.enterSaleZone()) {
      saleZone.triggerSaleEffect();
      add(
        FloatingTextComponent(
          position: Vector2(saleZoneArea.center.dx, saleZoneArea.center.dy),
          text: '+30 ÇK',
        ),
      );
    }
  }
}

/// Extends the meadow texture beyond the finite farm play area so the camera
/// never exposes the default black canvas around the mobile viewport.
class MeadowBackdropComponent extends PositionComponent {
  MeadowBackdropComponent()
    : super(
        position: Vector2(-2048, -2048),
        size: Vector2.all(4096),
        priority: -1,
      );

  Paint _paint = Paint()..color = const Color(0xFF70943F);

  set artwork(FarmWorldArtwork? value) {
    if (value == null) return;
    _paint = Paint()
      ..shader = ui.ImageShader(
        value.meadowGround,
        TileMode.mirror,
        TileMode.mirror,
        Float64List.fromList(const [
          0.32,
          0,
          0,
          0,
          0,
          0.32,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          1,
        ]),
      );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

class FarmGroundComponent extends PositionComponent {
  FarmGroundComponent({required this.area})
    : super(
        position: Vector2(area.left, area.top),
        size: Vector2(area.width, area.height),
        priority: 0,
      );

  final Rect area;
  FarmWorldArtwork? artwork;

  final Paint _roadPaint = Paint()
    ..color = const Color(0xFFAF8A58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _roadEdgePaint = Paint()
    ..color = const Color(0x33936E41)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 18
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _fieldEdgePaint = Paint()
    ..color = const Color(0xBFD5C18A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final art = artwork;
    if (art == null) return;

    final localRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(
      art.meadowGround,
      Rect.fromLTWH(
        0,
        0,
        art.meadowGround.width.toDouble(),
        art.meadowGround.height.toDouble(),
      ),
      localRect,
      Paint(),
    );

    final mapOffset = Offset((size.x - 460) / 2, (size.y - 620) / 2);
    _drawCropField(
      canvas,
      art.wheatField,
      Rect.fromLTWH(20, 27, 184, 105).shift(mapOffset),
      const [Offset(12, 8), Offset(170, 0), Offset(184, 92), Offset(0, 105)],
    );
    _drawCropField(
      canvas,
      art.maizeField,
      Rect.fromLTWH(256, 27, 184, 105).shift(mapOffset),
      const [Offset(16, 0), Offset(184, 15), Offset(170, 105), Offset(0, 85)],
    );

    final road = Path()
      ..moveTo(size.x * 0.5, 133 + mapOffset.dy)
      ..cubicTo(
        size.x * 0.48,
        165 + mapOffset.dy,
        size.x * 0.52,
        182 + mapOffset.dy,
        size.x * 0.5,
        198 + mapOffset.dy,
      )
      ..cubicTo(
        size.x * 0.48,
        222 + mapOffset.dy,
        size.x * 0.52,
        236 + mapOffset.dy,
        size.x * 0.5,
        256 + mapOffset.dy,
      );
    canvas.drawPath(road, _roadEdgePaint);
    canvas.drawPath(road, _roadPaint);

    final orchardTrack = Path()
      ..moveTo(mapOffset.dx, 215 + mapOffset.dy)
      ..cubicTo(
        48 + mapOffset.dx,
        232 + mapOffset.dy,
        74 + mapOffset.dx,
        223 + mapOffset.dy,
        112 + mapOffset.dx,
        239 + mapOffset.dy,
      )
      ..lineTo(130 + mapOffset.dx, 255 + mapOffset.dy);
    canvas.drawPath(orchardTrack, _roadEdgePaint);
    canvas.drawPath(orchardTrack, _roadPaint);
  }

  void _drawCropField(
    Canvas canvas,
    ui.Image image,
    Rect bounds,
    List<Offset> shapePoints,
  ) {
    final path = Path()
      ..moveTo(
        bounds.left + shapePoints.first.dx,
        bounds.top + shapePoints.first.dy,
      );
    for (final point in shapePoints.skip(1)) {
      path.lineTo(bounds.left + point.dx, bounds.top + point.dy);
    }
    path.close();

    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bounds,
      Paint(),
    );
    canvas.restore();
    canvas.drawPath(path, _fieldEdgePaint);
  }
}

class GrassFieldComponent extends PositionComponent {
  GrassFieldComponent({
    required this.area,
    required this.cutTrailPoints,
    required this.session,
  }) : super(
         position: Vector2(area.left, area.top),
         size: Vector2(area.width, area.height),
         priority: 1,
       );

  final Rect area;
  final List<Vector2> cutTrailPoints;
  final OpeningSession session;

  Paint _uncutPaint = Paint();
  Paint _cutPaint = Paint();
  final Paint _fieldEdgePaint = Paint()
    ..color = const Color(0x664A743F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  set artwork(FarmWorldArtwork? value) {
    _artwork = value;
    if (value == null) return;
    _uncutPaint = Paint();
    _cutPaint = Paint()
      ..shader = ui.ImageShader(
        value.mownMeadow,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList(const [
          0.18,
          0,
          0,
          0,
          0,
          0.18,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          1,
        ]),
      );
  }

  FarmWorldArtwork? _artwork;
  FarmWorldArtwork? get artwork => _artwork;

  Vector2 cuttingPointAheadAt(Vector2 worldPosition, Vector2 facingDirection) {
    final baseRadius = session.hasMower ? 24.0 : 17.0;
    final cutRadius = baseRadius * session.cuttingRangeMultiplier;
    final forward = facingDirection.isZero()
        ? Vector2(0, -1)
        : facingDirection.normalized();
    return worldPosition + forward * (cutRadius + 12);
  }

  bool hasUncutGrassAt(Vector2 cuttingPoint) {
    final localPosition = Offset(
      cuttingPoint.x - area.left,
      cuttingPoint.y - area.top,
    );
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    return _fieldPath(bounds).contains(localPosition) ||
        area.contains(cuttingPoint.toOffset());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage == OpeningStage.management) return;
    final art = _artwork;
    if (art == null) return;

    final localRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final fieldPath = _fieldPath(localRect);
    canvas.save();
    canvas.clipPath(fieldPath);
    canvas.drawImageRect(
      art.meadowGround,
      Rect.fromLTWH(
        0,
        0,
        art.meadowGround.width.toDouble(),
        art.meadowGround.height.toDouble(),
      ),
      localRect,
      _uncutPaint,
    );

    for (final point in cutTrailPoints) {
      final localPoint = Offset(point.x - area.left, point.y - area.top);
      final radius = session.hasMower ? 24.0 : 17.0;
      canvas.drawCircle(localPoint, radius, _cutPaint);
    }
    canvas.restore();
    canvas.drawPath(fieldPath, _fieldEdgePaint);
  }

  Path _fieldPath(Rect bounds) {
    final width = bounds.width;
    final height = bounds.height;
    return Path()
      ..moveTo(width * 0.05, height * 0.07)
      ..cubicTo(
        width * 0.17,
        height * 0.01,
        width * 0.31,
        height * 0.05,
        width * 0.45,
        height * 0.02,
      )
      ..cubicTo(
        width * 0.62,
        -height * 0.01,
        width * 0.81,
        height * 0.04,
        width * 0.94,
        height * 0.1,
      )
      ..cubicTo(
        width * 1.01,
        height * 0.23,
        width * 0.95,
        height * 0.34,
        width * 0.98,
        height * 0.49,
      )
      ..cubicTo(
        width * 1.01,
        height * 0.63,
        width * 0.95,
        height * 0.8,
        width * 0.93,
        height * 0.91,
      )
      ..cubicTo(
        width * 0.82,
        height * 1.01,
        width * 0.67,
        height * 0.95,
        width * 0.53,
        height * 0.98,
      )
      ..cubicTo(
        width * 0.38,
        height * 1.01,
        width * 0.2,
        height * 0.95,
        width * 0.08,
        height * 0.93,
      )
      ..cubicTo(
        -width * 0.01,
        height * 0.82,
        width * 0.05,
        height * 0.66,
        width * 0.02,
        height * 0.51,
      )
      ..cubicTo(
        -width * 0.01,
        height * 0.33,
        width * 0.02,
        height * 0.19,
        width * 0.05,
        height * 0.07,
      )
      ..close();
  }
}

class SaleZoneComponent extends PositionComponent {
  SaleZoneComponent({required this.area, required this.session})
    : super(
        position: Vector2(area.left, area.top),
        size: Vector2(area.width, area.height),
        priority: 2,
      );

  final Rect area;
  final OpeningSession session;
  FarmWorldArtwork? artwork;
  double _salePulseTimer = 0;

  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFE5B44C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Paint _iconPaint = Paint()
    ..color = const Color(0xFF725438)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  void triggerSaleEffect() {
    _salePulseTimer = 0.55;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _salePulseTimer = max(0, _salePulseTimer - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage == OpeningStage.management) return;
    final center = Offset(size.x / 2, size.y / 2);
    artwork?.salePlatform.render(
      canvas,
      position: Vector2(center.dx, center.dy),
      size: Vector2(size.x + 44, size.y + 62),
      anchor: Anchor.center,
    );

    final zone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.x - 24, height: size.y - 18),
      const Radius.circular(14),
    );
    canvas.drawRRect(zone, _borderPaint);

    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 16, center.dy + 3)
        ..lineTo(center.dx - 16, center.dy + 10)
        ..lineTo(center.dx + 16, center.dy + 10)
        ..lineTo(center.dx + 16, center.dy + 3),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 11),
      Offset(center.dx, center.dy + 5),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(center.dx - 5, center.dy),
      Offset(center.dx, center.dy + 5),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy),
      Offset(center.dx, center.dy + 5),
      _iconPaint,
    );

    if (_salePulseTimer > 0) {
      final progress = 1 - _salePulseTimer / 0.55;
      final pulsePaint = Paint()
        ..color = Color.fromRGBO(250, 212, 124, (1 - progress) * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 64 + progress * 58,
          height: 28 + progress * 28,
        ),
        pulsePaint,
      );
    }
  }
}

class GroundBaleComponent extends PositionComponent {
  GroundBaleComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(72, 56),
        anchor: Anchor.center,
        priority: 5,
      );

  FarmWorldArtwork? artwork;
  final Paint _shadowPaint = Paint()..color = const Color(0x442E3218);
  final Paint _bodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8D76D), Color(0xFFE2AC3E), Color(0xFFB97825)],
    ).createShader(const Rect.fromLTWH(10, 12, 52, 32));
  final Paint _bodyOutlinePaint = Paint()
    ..color = const Color(0xFF86561F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  final Paint _endFacePaint = Paint()..color = const Color(0xFFD2912E);
  final Paint _endHighlightPaint = Paint()
    ..color = const Color(0xFFFFD773)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _twinePaint = Paint()
    ..color = const Color(0xFF755027)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.7
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.14, size.y * 0.62, size.x * 0.72, size.y * 0.28),
      _shadowPaint,
    );
    artwork?.strawBale.render(canvas, position: Vector2.zero(), size: size);

    final body = Rect.fromLTWH(
      size.x * 0.15,
      size.y * 0.22,
      size.x * 0.72,
      size.y * 0.57,
    );
    final bodyShape = RRect.fromRectAndRadius(
      body,
      Radius.circular(size.y * 0.18),
    );
    canvas.drawRRect(bodyShape, _bodyPaint);
    canvas.drawRRect(bodyShape, _bodyOutlinePaint);

    final endFace = Rect.fromLTWH(
      size.x * 0.08,
      size.y * 0.24,
      size.x * 0.29,
      size.y * 0.53,
    );
    canvas.drawOval(endFace, _endFacePaint);
    canvas.drawOval(endFace.deflate(size.x * 0.045), _endHighlightPaint);
    canvas.drawLine(
      Offset(size.x * 0.45, size.y * 0.25),
      Offset(size.x * 0.45, size.y * 0.78),
      _twinePaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.69, size.y * 0.25),
      Offset(size.x * 0.69, size.y * 0.78),
      _twinePaint,
    );
  }
}

class PlayerCharacterComponent extends PositionComponent {
  PlayerCharacterComponent({required Vector2 position, required this.session})
    : super(
        position: position,
        size: Vector2(72, 72),
        anchor: Anchor.center,
        priority: 10,
      );

  final OpeningSession session;
  FarmWorldArtwork? artwork;
  Vector2 facingDirection = Vector2(0, -1);
  bool isMoving = false;
  bool isMowing = false;
  double _mowingAnimationSeconds = 0;

  static const int mowingAnimationFrameCount = 4;
  static const double mowingAnimationFramesPerSecond = 10;
  final Paint _mowingFleckPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.4;

  int get mowingAnimationFrame => isMowing
      ? (_mowingAnimationSeconds * mowingAnimationFramesPerSecond).floor() %
            mowingAnimationFrameCount
      : 0;

  void updateMowing(bool value, double dt) {
    if (value != isMowing) {
      isMowing = value;
      _mowingAnimationSeconds = 0;
    }
    if (value && dt.isFinite && dt > 0) {
      _mowingAnimationSeconds += dt;
    }
  }

  void move(Vector2 direction, double dt) {
    if (direction.length2 <= 0.0001) return;
    final normalizedDirection = direction.normalized();
    // The atlas has four overhead directions. Keep the character, sickle
    // contact point, and bale drop aligned while retaining smooth diagonals.
    facingDirection = normalizedDirection.x.abs() > normalizedDirection.y.abs()
        ? Vector2(normalizedDirection.x.isNegative ? -1 : 1, 0)
        : Vector2(0, normalizedDirection.y.isNegative ? -1 : 1);
    isMoving = true;
    final baseSpeed = session.hasMower ? 188.0 : 120.0;
    final speed = baseSpeed * session.movementSpeedMultiplier;
    final moveMag = direction.length.clamp(0.0, 1.0);
    position += normalizedDirection * (moveMag * speed * dt);
  }

  void stopMoving() {
    isMoving = false;
    updateMowing(false, 0);
  }

  int get _facingColumn {
    if (facingDirection.x.abs() > facingDirection.y.abs()) {
      return facingDirection.x < 0 ? 1 : 3;
    }
    return facingDirection.y < 0 ? 0 : 2;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage == OpeningStage.management) return;
    final art = artwork;
    if (art == null) return;

    final personOrMachine = session.hasMower
        ? art.miniMower
        : art.mowingScythe.getSprite(mowingAnimationFrame, _facingColumn);
    if (session.hasMower) {
      final angle = facingDirection.x.abs() > facingDirection.y.abs()
          ? (facingDirection.x < 0 ? pi : 0.0)
          : (facingDirection.y < 0 ? -pi / 2 : pi / 2);
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(angle);
      personOrMachine.render(
        canvas,
        position: Vector2(-size.x / 2, -size.y / 2),
        size: Vector2(size.y, size.x),
      );
      canvas.restore();
    } else {
      const frameHeightRatio = 0.75;
      final frameSize = Vector2(size.x, size.y * frameHeightRatio);
      personOrMachine.render(
        canvas,
        position: Vector2(0, (size.y - frameSize.y) / 2),
        size: frameSize,
      );
    }

    _drawMowingFlecks(canvas);

    if (session.isCarryingBale) {
      art.strawBale.render(
        canvas,
        position: Vector2(size.x * 0.43, 2),
        size: Vector2(36, 30),
      );
    }
  }

  void _drawMowingFlecks(Canvas canvas) {
    if (!isMowing) return;

    final phase = (_mowingAnimationSeconds * 1.5) % 1;
    final forward = facingDirection;
    final side = Vector2(-forward.y, forward.x);
    final center = Vector2(size.x / 2, size.y / 2);
    final cutPoint = center + forward * 31;
    const colors = [Color(0xFFFFE29A), Color(0xFFC7DD78), Color(0xFFFFD36E)];

    for (var index = 0; index < colors.length; index++) {
      final alpha = ((1 - phase) * 220).round();
      _mowingFleckPaint.color = colors[index].withAlpha(alpha);
      final spread = index - 1;
      final start = cutPoint + side * (spread * 8.0) + forward * (phase * 8.0);
      final end =
          start +
          side * (index.isEven ? 4.0 : -4.0) +
          forward * (4.0 + phase * 7.0);
      canvas.drawLine(start.toOffset(), end.toOffset(), _mowingFleckPaint);
    }
  }
}

class FarmHandComponent extends PositionComponent {
  FarmHandComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(116, 86),
        anchor: Anchor.center,
        priority: 11,
      );

  FarmWorldArtwork? artwork;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final art = artwork;
    if (art == null) return;

    art.miniMower.render(
      canvas,
      position: Vector2(42, 30),
      size: Vector2(72, 54),
    );
    art.employee
        .getSprite(0, 0)
        .render(canvas, position: Vector2(0, 3), size: Vector2(54, 78));
  }
}

class StarterCropPlotComponent extends PositionComponent with TapCallbacks {
  StarterCropPlotComponent({
    required Vector2 position,
    required Vector2 size,
    required this.session,
    required this.selectedMapItem,
  }) : super(position: position, size: size, priority: 4);

  final OpeningSession session;
  final ValueNotifier<ManagementMapSelection> selectedMapItem;
  FarmWorldArtwork? artwork;

  final Paint _soilPaint = Paint()..color = const Color(0xFF8B6340);
  final Paint _furrowPaint = Paint()
    ..color = const Color(0x55714832)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _edgePaint = Paint()
    ..color = const Color(0xFFC2A16D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void onTapDown(TapDownEvent event) {
    if (session.stage == OpeningStage.management) {
      selectedMapItem.value = ManagementMapSelection.starterPlot;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage != OpeningStage.management) return;
    final localBounds = Rect.fromLTWH(0, 0, size.x, size.y);
    final field = RRect.fromRectAndRadius(
      localBounds,
      const Radius.circular(12),
    );
    canvas.drawRRect(
      field.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x440D3118),
    );
    canvas.drawRRect(field, _soilPaint);

    final snapshot = session.cropSnapshotAt(DateTime.now());
    final art = artwork;
    if (snapshot != null && art != null) {
      final progress = snapshot.growthProgress;
      final cropImage = switch (snapshot.crop.id) {
        OpeningCropCatalog.chickpeaId => art.chickpeaStages,
        OpeningCropCatalog.sunflowerId =>
          progress < 0.34
              ? art.sunflowerEarly
              : progress < 0.72
              ? art.sunflowerMid
              : art.sunflowerField,
        OpeningCropCatalog.potatoId =>
          progress < 0.34
              ? art.potatoEarly
              : progress < 0.72
              ? art.potatoMid
              : art.potatoField,
        _ =>
          progress < 0.34
              ? art.cerealEarly
              : progress < 0.72
              ? art.cerealMid
              : snapshot.crop.id == OpeningCropCatalog.wheatId
              ? art.wheatField
              : art.maizeField,
      };
      final sourceRect = snapshot.crop.id == OpeningCropCatalog.chickpeaId
          ? Rect.fromLTWH(
              cropImage.width *
                  (progress < 0.34
                      ? 0
                      : progress < 0.72
                      ? 1
                      : 2) /
                  3,
              0,
              cropImage.width / 3,
              cropImage.height.toDouble(),
            )
          : Rect.fromLTWH(
              0,
              0,
              cropImage.width.toDouble(),
              cropImage.height.toDouble(),
            );
      canvas.save();
      canvas.clipRRect(field);
      canvas.drawImageRect(cropImage, sourceRect, localBounds, Paint());
      canvas.restore();
    } else {
      for (var row = 0; row < 5; row++) {
        final y = 13.0 + row * (size.y - 26) / 4;
        canvas.drawLine(Offset(9, y), Offset(size.x - 9, y - 5), _furrowPaint);
      }
    }

    canvas.drawRRect(field, _edgePaint);
    if (selectedMapItem.value == ManagementMapSelection.starterPlot) {
      canvas.drawRRect(
        field,
        Paint()
          ..color = const Color(0xFFD7A84B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
  }
}

class FarmBuildingComponent extends PositionComponent with TapCallbacks {
  FarmBuildingComponent({
    required Vector2 position,
    required Vector2 size,
    required this.session,
    required this.selectedMapItem,
    required this.selection,
    required this.spriteIndex,
  }) : super(position: position, size: size, priority: 3);

  final OpeningSession session;
  final ValueNotifier<ManagementMapSelection> selectedMapItem;
  final ManagementMapSelection selection;
  final int spriteIndex;
  FarmWorldArtwork? artwork;

  @override
  void onTapDown(TapDownEvent event) {
    if (session.stage == OpeningStage.management) {
      selectedMapItem.value = selection;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage != OpeningStage.management) return;
    if (artwork == null) return;

    if (selectedMapItem.value == selection) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.x * 0.08,
          size.y * 0.65,
          size.x * 0.84,
          size.y * 0.23,
        ),
        Paint()..color = const Color(0x3FD7A84B),
      );
    }
    artwork!.starterBuildings
        .getSprite(spriteIndex, 0)
        .render(canvas, position: Vector2.zero(), size: size);
  }
}
