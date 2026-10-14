import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart' show ScaleStartInfo, ScaleUpdateInfo;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';

import 'domain/opening_session.dart';
import 'farm_world_artwork.dart';
import 'opening_mowing_world.dart';

/// Flame game instance running the shared farm management map.
class FarmWorldGame extends FlameGame<OpeningMowingWorld> with ScaleDetector {
  FarmWorldGame({OpeningSession? session, OpeningMowingWorld? world})
    : super(
        world:
            world ?? OpeningMowingWorld(session: session ?? OpeningSession()),
      ) {
    images = Images(prefix: 'assets/');
  }

  late final JoystickComponent joystick;
  late final PositionComponent balanceIndicator = PositionComponent(
    size: Vector2(96, 38),
    anchor: Anchor.topRight,
  );
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);
  OpeningSessionState? _observedState;
  OpeningStage? _observedStage;
  bool _isHudInitialized = false;
  double _activeCropHudTimer = 0;
  double _mowingHudTimer = 0;
  double _managementFitZoom = 0.5;
  double _gestureStartZoom = 0.5;
  Vector2 _lastGameSize = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final artwork = await FarmWorldArtwork.load(images);
    world.setArtwork(artwork);
    await super.onLoad();

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 23,
        paint: Paint()..color = const Color(0xD9685132),
      ),
      background: CircleComponent(
        radius: 53,
        paint: Paint()..color = const Color(0x556B8054),
      ),
      anchor: Anchor.center,
    );

    world.joystick = joystick;
    if (world.session.stage == OpeningStage.management) {
      world.startManagementView();
      camera.stop();
      camera.viewfinder.position = Vector2.zero();
    } else {
      camera.viewport.add(joystick);
      camera.follow(world.player);
    }

    _observedState = world.session.state;
    _observedStage = world.session.stage;
    _isHudInitialized = true;
    if (hasLayout) {
      _updateLayout(size);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final currentState = world.session.state;
    final previousState = _observedState;
    if (previousState == null ||
        currentState.farmCredits != previousState.farmCredits ||
        currentState.stage != previousState.stage ||
        currentState.hasMower != previousState.hasMower ||
        currentState.hasWorker != previousState.hasWorker ||
        currentState.isCarryingBale != previousState.isCarryingBale ||
        currentState.groundBaleCount != previousState.groundBaleCount ||
        currentState.soilConditionPoints != previousState.soilConditionPoints ||
        currentState.automaticSoilCareEnabled !=
            previousState.automaticSoilCareEnabled) {
      sessionRevision.value++;
    }
    _observedState = currentState;

    if (world.session.hasActiveCrop) {
      _activeCropHudTimer += dt;
      if (_activeCropHudTimer >= 1) {
        _activeCropHudTimer %= 1;
        sessionRevision.value++;
      }
    } else {
      _activeCropHudTimer = 0;
    }

    if (world.session.stage == OpeningStage.scythe && world.player.isMowing) {
      _mowingHudTimer += dt;
      if (_mowingHudTimer >= 0.1) {
        _mowingHudTimer %= 0.1;
        sessionRevision.value++;
      }
    } else {
      _mowingHudTimer = 0;
    }

    if (world.session.stage != _observedStage) {
      _observedStage = world.session.stage;
      if (world.session.stage == OpeningStage.management) {
        world.startManagementView();
        joystick.removeFromParent();
        camera.stop();
        camera.viewfinder.position = Vector2.zero();
        _updateLayout(canvasSize);
      }
    }
  }

  bool buyMower() {
    final purchased = world.session.buyMower();
    if (purchased) sessionRevision.value++;
    return purchased;
  }

  bool hireWorker() {
    final hired = world.session.hireWorker();
    if (hired) {
      world.startManagementView();
      joystick.removeFromParent();
      camera.stop();
      camera.viewfinder.position = Vector2.zero();
      _observedState = world.session.state;
      _observedStage = world.session.stage;
      sessionRevision.value++;
      if (hasLayout) _updateLayout(canvasSize);
    }
    return hired;
  }

  void skipToManagement() {
    world.session.skipToManagement();
    world.startManagementView();
    if (joystick.isMounted) {
      joystick.removeFromParent();
    }
    camera.stop();
    camera.viewfinder.position = Vector2.zero();
    _observedState = world.session.state;
    _observedStage = world.session.stage;
    sessionRevision.value++;
    if (hasLayout) _updateLayout(canvasSize);
  }

  bool purchaseTechnology(String technologyId) {
    final purchased = world.session.purchaseTechnology(technologyId);
    if (purchased) sessionRevision.value++;
    return purchased;
  }

  bool setAutomaticSoilCareEnabled(bool enabled) {
    final changed = world.session.setAutomaticSoilCareEnabled(enabled);
    if (changed) sessionRevision.value++;
    return changed;
  }

  bool plantCrop(String cropId) {
    final planted = world.session.plantCrop(cropId, DateTime.now());
    if (planted) sessionRevision.value++;
    return planted;
  }

  bool harvestCrop() {
    final harvested = world.session.harvestCrop(DateTime.now());
    if (harvested) sessionRevision.value++;
    return harvested;
  }

  /// Returns the management map to its full-farm overview.
  void resetMapView() {
    if (world.session.stage != OpeningStage.management) return;
    camera.stop();
    camera.viewfinder.position = Vector2.zero();
    camera.viewfinder.zoom = _managementFitZoom;
    _clampManagementCameraPosition();
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    if (world.session.stage == OpeningStage.management) {
      _gestureStartZoom = camera.viewfinder.zoom;
    }
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    if (world.session.stage != OpeningStage.management) return;

    final focusPoint = info.eventPosition.widget;
    if (info.pointerCount > 1) {
      final focusBeforeZoom = camera.globalToLocal(focusPoint);
      final minZoom = (_managementFitZoom * 0.72).clamp(0.24, 0.8).toDouble();
      final nextZoom = (_gestureStartZoom * info.raw.scale)
          .clamp(minZoom, 1.8)
          .toDouble();
      camera.viewfinder.zoom = nextZoom;
      final focusAfterZoom = camera.globalToLocal(focusPoint);
      camera.viewfinder.position =
          camera.viewfinder.position + focusBeforeZoom - focusAfterZoom;
    } else {
      camera.viewfinder.position =
          camera.viewfinder.position -
          (info.delta.global / camera.viewfinder.zoom);
    }

    _clampManagementCameraPosition();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isHudInitialized) {
      _updateLayout(size);
    }
  }

  void _updateLayout(Vector2 screenSize) {
    if (screenSize.x <= 0 || screenSize.y <= 0) return;
    _lastGameSize = screenSize.clone();

    if (world.session.stage == OpeningStage.management) {
      final mapFitZoom = min(screenSize.x / 900.0, screenSize.y / 620.0);
      _managementFitZoom = (mapFitZoom * 0.94).clamp(0.36, 0.9).toDouble();
      camera.viewfinder.zoom = _managementFitZoom;
      _clampManagementCameraPosition();
      return;
    }

    final isLandscape = screenSize.x > screenSize.y;
    final bottomMargin = isLandscape ? 54.0 : 72.0;
    final leftMargin = isLandscape ? 64.0 : 68.0;

    joystick.position = Vector2(leftMargin, screenSize.y - bottomMargin);
    balanceIndicator.position = Vector2(screenSize.x - 20, 24);

    // Keep the player and meadow readable on both supported orientations.
    final minDimension = min(screenSize.x, screenSize.y);
    camera.viewfinder.zoom = (minDimension / 390.0).clamp(0.85, 1.35);
  }

  void _clampManagementCameraPosition() {
    if (_lastGameSize.x <= 0 || _lastGameSize.y <= 0) return;

    final zoom = camera.viewfinder.zoom;
    final halfVisibleWidth = _lastGameSize.x / (2 * zoom);
    final halfVisibleHeight = _lastGameSize.y / (2 * zoom);
    final minX = -450.0 + halfVisibleWidth;
    final maxX = 450.0 - halfVisibleWidth;
    final minY = -310.0 + halfVisibleHeight;
    final maxY = 310.0 - halfVisibleHeight;
    final position = camera.viewfinder.position;

    camera.viewfinder.position = Vector2(
      minX > maxX ? 0 : position.x.clamp(minX, maxX).toDouble(),
      minY > maxY ? 0 : position.y.clamp(minY, maxY).toDouble(),
    );
  }

  @override
  void onDispose() {
    sessionRevision.dispose();
    world.selectedMapItem.dispose();
    super.onDispose();
  }
}
