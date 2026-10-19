import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../domain/procedural_farm_world.dart';

/// The camera uses the same world-space center and zoom scale as the 2D map.
/// The isometric yaw and pitch stay fixed so the map remains easy to navigate.
@immutable
class MapCameraPose {
  const MapCameraPose({required this.center, required this.zoom});

  final WorldMapPoint center;
  final double zoom;

  @override
  bool operator ==(Object other) =>
      other is MapCameraPose &&
      other.center.x == center.x &&
      other.center.y == center.y &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(center.x, center.y, zoom);
}

/// Projects a world point through the scene's fixed 45° yaw and 45° pitch.
/// Flutter overlays should use this helper so labels follow the exact same
/// camera basis as the ThreeJS surface.
Offset projectMapPointToScreen(
  MapCameraPose pose,
  WorldMapPoint point,
  Size viewport, {
  double elevation = 0,
}) {
  final dx = point.x - pose.center.x;
  final dy = point.y - pose.center.y;
  final scale = pose.zoom * math.sqrt(0.5);
  return Offset(
    viewport.width / 2 + (dx - dy) * scale,
    viewport.height / 2 + (dx + dy) * pose.zoom * 0.5 - elevation * scale,
  );
}

/// Keeps parent overlays and the ThreeJS camera on the same world-space pose.
MapCameraPose clampIsometricCameraPose(MapCameraPose pose, Size viewport) {
  final zoom = pose.zoom.clamp(0.12, 1.85).toDouble();
  final world = ProceduralFarmWorld.worldBounds;
  final minX = world.left - 600.0;
  final maxX = world.right + 600.0;
  final minY = world.top - 600.0;
  final maxY = world.bottom + 600.0;
  final centerX = pose.center.x.clamp(minX, maxX).toDouble();
  final centerY = pose.center.y.clamp(minY, maxY).toDouble();
  return MapCameraPose(center: WorldMapPoint(centerX, centerY), zoom: zoom);
}

Rect _projectedWorldBoundsForPose(MapCameraPose pose, Size viewport) {
  if (viewport.isEmpty) {
    return Rect.fromCenter(
      center: Offset(pose.center.x, pose.center.y),
      width: 0,
      height: 0,
    );
  }
  var minX = double.infinity;
  var maxX = double.negativeInfinity;
  var minY = double.infinity;
  var maxY = double.negativeInfinity;
  for (final corner in [
    Offset.zero,
    Offset(viewport.width, 0),
    Offset(0, viewport.height),
    Offset(viewport.width, viewport.height),
  ]) {
    final delta = _projectedWorldDeltaForScreen(corner, viewport, pose.zoom);
    minX = math.min(minX, delta.x);
    maxX = math.max(maxX, delta.x);
    minY = math.min(minY, delta.y);
    maxY = math.max(maxY, delta.y);
  }
  return Rect.fromLTRB(
    pose.center.x + minX,
    pose.center.y + minY,
    pose.center.x + maxX,
    pose.center.y + maxY,
  );
}

WorldMapPoint _projectedWorldDeltaForScreen(
  Offset screenPoint,
  Size viewport,
  double zoom,
) {
  final projectedX =
      (screenPoint.dx - viewport.width / 2) / (zoom * math.sqrt(0.5));
  final projectedY = (screenPoint.dy - viewport.height / 2) / (zoom * 0.5);
  return WorldMapPoint(
    (projectedX + projectedY) / 2,
    (projectedY - projectedX) / 2,
  );
}

enum IsometricFieldState {
  plowed,
  fertilized,
  growing,
  harvestReady,
  harvested,
}

enum IsometricMarkerKind { player, vehicle, order, farm, market, poi }

@immutable
class IsometricMapPath {
  const IsometricMapPath({
    required this.id,
    required this.points,
    this.color = 0xfff1df9b,
    this.width = 5,
  });

  final String id;
  final List<WorldMapPoint> points;
  final int color;
  final double width;
}

/// A small world-space marker for session-owned vehicles and farm structures.
/// Labels stay in Flutter so they remain sharp and localizable at every zoom.
@immutable
class IsometricMapMarker {
  const IsometricMapMarker({
    required this.id,
    required this.position,
    required this.kind,
    this.label = '',
    this.size = 30,
  });

  final String id;
  final WorldMapPoint position;
  final IsometricMarkerKind kind;
  final String label;
  final double size;
}

/// Isometric, portrait-friendly ThreeJS renderer for the finite farm world.
///
/// Pan and pinch live in the scene. The parent can control/recenter the camera
/// by passing a new [cameraPose], while preserving map interaction behavior
/// through [onWorldTap].
class IsometricWorldMapView extends StatefulWidget {
  const IsometricWorldMapView({
    super.key,
    required this.world,
    required this.ownedParcelIds,
    required this.onWorldTap,
    this.selectedParcelId,
    this.cameraPose,
    this.onCameraChanged,
    this.onMarkerTap,
    this.fieldStates = const {},
    this.fieldCropIds = const {},
    this.markers = const [],
    this.paths = const [],
    this.showParcels = true,
    this.showRoutes = true,
    this.showInfrastructure = true,
  });

  final ProceduralFarmWorld world;
  final Set<String> ownedParcelIds;
  final String? selectedParcelId;
  final MapCameraPose? cameraPose;
  final ValueChanged<MapCameraPose>? onCameraChanged;
  final void Function(WorldMapPoint point, Offset localPosition) onWorldTap;
  final void Function(String id, WorldMapPoint point, Offset localPosition)?
  onMarkerTap;
  final Map<String, IsometricFieldState> fieldStates;
  final Map<String, String> fieldCropIds;
  final List<IsometricMapMarker> markers;
  final List<IsometricMapPath> paths;
  final bool showParcels;
  final bool showRoutes;
  final bool showInfrastructure;

  @override
  State<IsometricWorldMapView> createState() => _IsometricWorldMapViewState();
}

class _ParcelSpatialFeature {
  const _ParcelSpatialFeature(this.parcel, this.bounds);

  final WorldMapParcel parcel;
  final Rect bounds;
}

class _IsometricWorldMapViewState extends State<IsometricWorldMapView> {
  static const _defaultPose = MapCameraPose(
    center: WorldMapPoint(-150, -120),
    zoom: 0.64,
  );

  static const _groundHeight = 0.0;
  static const _minZoom = 0.1;
  static const _maxZoom = 1.85;
  static const _chunkPadding = 0;

  late MapCameraPose _pose = widget.cameraPose ?? _defaultPose;
  late final three.ThreeJS _threeJs;
  late final three.Scene _scene;
  late final three.OrthographicCamera _camera;
  late final three.Raycaster _raycaster;
  late final three.Mesh _ground;
  three.Group? _terrainRoot;
  three.Group? _parcelRoot;
  three.Group? _markerRoot;
  three.Group? _pathRoot;
  three.Group? _selectionRoot;
  final Map<int, bool> _treeConflictCache = {};
  final Map<String, bool> _parcelOverlapCache = {};
  final Map<String, three.BufferGeometry> _sharedGeometryCache = {};
  final Map<String, three.Group> _cachedRoadObjects = {};
  final Map<String, three.Group> _cachedWaterObjects = {};
  final Map<String, three.Group> _cachedLakeObjects = {};
  final Map<String, three.Group> _cachedPoiObjects = {};
  final Set<three.BufferGeometry> _staticGeometryCache = {};

  static double _distanceToSegmentSq(
    double px,
    double py,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    final dx = x1 - x0;
    final dy = y1 - y0;
    final l2 = dx * dx + dy * dy;
    if (l2 <= 0.000001) {
      final ddx = px - x0;
      final ddy = py - y0;
      return ddx * ddx + ddy * ddy;
    }
    final t = (((px - x0) * dx + (py - y0) * dy) / l2).clamp(0.0, 1.0);
    final projX = x0 + t * dx;
    final projY = y0 + t * dy;
    final ddx = px - projX;
    final ddy = py - projY;
    return ddx * ddx + ddy * ddy;
  }

  three.Mesh _staticTube(
    List<WorldMapPoint> points,
    three.Material material,
    double radius,
    double height,
  ) {
    final mesh = _tube(points, material, radius, height);
    if (mesh.geometry != null) {
      _staticGeometryCache.add(mesh.geometry!);
    }
    return mesh;
  }

  three.SphereGeometry? _markerSphereGeometry;
  three.PlaneGeometry? _landmarkPlaneGeometry;
  three.SphereGeometry? _treeCanopyGeometry;
  three.CylinderGeometry? _treeTrunkGeometry;
  three.SphereGeometry? _mountainGeometry;
  three.Texture? _fieldAtlas;
  three.Texture? _landmarkAtlas;
  final Map<IsometricFieldState, three.Texture> _fieldTextures = {};
  final List<three.Texture> _landmarkTextures = [];
  final Map<IsometricFieldState, three.Material> _fieldMaterials = {};
  final Map<String, three.Texture> _matureCropTextures = {};
  final Map<String, three.Material> _matureCropMaterials = {};
  final Map<int, three.Material> _landmarkMaterials = {};
  final Map<String, three.Material> _infrastructureMaterials = {};
  final Map<IsometricMarkerKind, three.Material> _markerMaterials = {};
  final Map<int, three.Material> _pathMaterials = {};
  final Map<String, three.Material> _parcelMaterials = {};
  final Map<String, three.Material> _roadMaterials = {};
  final Map<String, three.Material> _waterMaterials = {};
  final Set<three.Material> _transientMaterials = {};
  final Set<String> _drawnParcelIds = {};
  final Map<String, three.Mesh> _markerMeshes = {};
  final Map<String, IsometricMapMarker> _visibleMarkers = {};
  final Map<String, three.Mesh> _pathMeshes = {};
  final Map<String, IsometricMapPath> _visiblePaths = {};
  WorldMapPoint? _gestureAnchorWorld;
  MapCameraPose _gestureStartPose = _defaultPose;
  Rect? _lastBuiltBounds;
  bool? _lastBuiltParcelsVisible;
  bool? _lastBuiltTreesVisible;
  bool? _lastBuiltMountainsVisible;
  bool? _lastBuiltRoadHighlightsVisible;
  DateTime? _lastCameraNotification;
  Size _lastClampedLayoutSize = Size.zero;
  bool _sceneReady = false;
  Timer? _rebuildDebounceTimer;
  three.BoxGeometry _getBoxGeometry(double width, double height, double depth) {
    final key = 'b_${width.toStringAsFixed(1)}_${height.toStringAsFixed(1)}_${depth.toStringAsFixed(1)}';
    return _sharedGeometryCache.putIfAbsent(
      key,
      () => three.BoxGeometry(width, height, depth),
    ) as three.BoxGeometry;
  }

  three.CylinderGeometry _getCylinderGeometry(
    double radiusTop,
    double radiusBottom,
    double height,
    int radialSegments,
  ) {
    final key = 'c_${radiusTop.toStringAsFixed(1)}_${radiusBottom.toStringAsFixed(1)}_${height.toStringAsFixed(1)}_$radialSegments';
    return _sharedGeometryCache.putIfAbsent(
      key,
      () => three.CylinderGeometry(radiusTop, radiusBottom, height, radialSegments),
    ) as three.CylinderGeometry;
  }

  three.ConeGeometry _getConeGeometry(
    double radius,
    double height,
    int radialSegments,
  ) {
    final key = 'cn_${radius.toStringAsFixed(1)}_${height.toStringAsFixed(1)}_$radialSegments';
    return _sharedGeometryCache.putIfAbsent(
      key,
      () => three.ConeGeometry(radius, height, radialSegments),
    ) as three.ConeGeometry;
  }

  final List<three.Object3D> _animatedWindmillRotors = [];

  void _onRenderFrame() {
    if (_animatedWindmillRotors.isEmpty) return;
    for (var i = 0; i < _animatedWindmillRotors.length; i++) {
      _animatedWindmillRotors[i].rotation.z += 0.024;
    }
  }

  @override
  void initState() {
    super.initState();
    _threeJs = three.ThreeJS(
      setup: _setupScene,
      rendererUpdate: _onRenderFrame,
      onSetupComplete: () {
        if (mounted) setState(() => _sceneReady = true);
      },
      settings: three.Settings(
        antialias: false,
        enableShadowMap: false,
        clearColor: 0xff3b5c3d,
        clearAlpha: 1,
        screenResolution: 1,
        powerPreference: three.PowerPreference.low,
      ),
    );
  }

  Future<void> _setupScene() async {
    final width = math.max(1.0, _threeJs.width);
    final height = math.max(1.0, _threeJs.height);
    _scene = three.Scene();
    _scene.background = three.Color.fromHex32(0xff3b5c3d);
    _camera = three.OrthographicCamera(
      -width / 2,
      width / 2,
      height / 2,
      -height / 2,
      1,
      60000,
    );
    _threeJs.camera = _camera;
    _threeJs.scene = _scene;
    _raycaster = three.Raycaster();
    _markerSphereGeometry = three.SphereGeometry(1, 8, 6);
    _landmarkPlaneGeometry = three.PlaneGeometry(1, 1);
    _treeCanopyGeometry = three.SphereGeometry(1, 6, 4);
    _treeTrunkGeometry = three.CylinderGeometry(0.12, 0.18, 1, 5);
    _mountainGeometry = three.SphereGeometry(1, 7, 5);

    _terrainRoot = three.Group();
    _scene.add(_terrainRoot!);

    _parcelRoot = three.Group();
    _scene.add(_parcelRoot!);

    _selectionRoot = three.Group();
    _scene.add(_selectionRoot!);

    _scene.add(three.AmbientLight(0xffffff, 1.35));
    final sun = three.DirectionalLight(0xffe4b7, 1.45);
    sun.position.setValues(-4000, 9000, -5200);
    _scene.add(sun);

    final groundMaterial = three.MeshLambertMaterial.fromMap({
      'color': 0xff64764a,
      'side': three.DoubleSide,
    });
    _ground =
        three.Mesh(
            three.PlaneGeometry(
              ProceduralFarmWorld.worldMaxX - ProceduralFarmWorld.worldMinX,
              ProceduralFarmWorld.worldMaxY - ProceduralFarmWorld.worldMinY,
            ),
            groundMaterial,
          )
          ..rotation.x = math.pi / 2
          ..position.setValues(
            (ProceduralFarmWorld.worldMinX + ProceduralFarmWorld.worldMaxX) / 2,
            _groundHeight,
            (ProceduralFarmWorld.worldMinY + ProceduralFarmWorld.worldMaxY) / 2,
          );
    _scene.add(_ground);

    _initFallbackMaterials();
    _loadTexturesInBackground();

    final initialViewport = Size(
      _threeJs.width > 10 ? _threeJs.width : 600.0,
      _threeJs.height > 10 ? _threeJs.height : 900.0,
    );
    _applyPose(_pose, rebuild: true, viewport: initialViewport);
    final visibleBounds = _visibleWorldBoundsFor(_pose, viewport: initialViewport);
    _syncMarkerLayer(visibleBounds);
    _syncPathLayer(visibleBounds);
    _syncSelectionLayer();
  }

  void _initFallbackMaterials() {
    for (final state in IsometricFieldState.values) {
      final color = switch (state) {
        IsometricFieldState.plowed => 0xff7c5132,
        IsometricFieldState.fertilized => 0xff533924,
        IsometricFieldState.growing => 0xff5a9442,
        IsometricFieldState.harvestReady => 0xffdca83f,
        IsometricFieldState.harvested => 0xffa88c5c,
      };
      _fieldMaterials[state] = three.MeshLambertMaterial.fromMap({
        'color': color,
        'side': three.DoubleSide,
      });
    }

    const landmarkColors = [0xffba6f49, 0xffbe9659, 0xff4096a6, 0xff609a5b];
    for (var i = 0; i < 4; i++) {
      _landmarkMaterials[i] = three.MeshLambertMaterial.fromMap({
        'color': landmarkColors[i],
        'transparent': true,
        'alphaTest': 0.04,
        'depthWrite': false,
        'side': three.DoubleSide,
      });
    }
  }

  Future<void> _loadTexturesInBackground() async {
    try {
      _fieldAtlas = await three.TextureLoader().fromAsset(
        'assets/images/map/farm-field-states-v1.png',
      );
      if (_fieldAtlas != null && mounted) {
        _createFieldTextures();
        if (_sceneReady) _rebuildVisibleMap(force: true);
      }
    } on Object {
      // Fallback colors already active.
    }

    try {
      _landmarkAtlas = await three.TextureLoader().fromAsset(
        'assets/images/map/farm-world-map-landmarks-v1.png',
      );
      if (_landmarkAtlas != null && mounted) {
        _createLandmarkMaterials();
        if (_sceneReady) _rebuildVisibleMap(force: true);
      }
    } on Object {
      // Fallback procedural landmarks remain visible.
    }

    for (final entry in const {
      'wheat': 'assets/visual-concepts/pilot/crop-wheat-mature-v1.png',
      'maize': 'assets/visual-concepts/pilot/crop-maize-mature-v1.png',
    }.entries) {
      try {
        final texture = await three.TextureLoader().fromAsset(entry.value);
        if (texture == null || !mounted) continue;
        _matureCropTextures[entry.key] = texture;
        _matureCropMaterials[entry.key] = three.MeshLambertMaterial.fromMap({
          'map': texture,
          'side': three.DoubleSide,
        });
      } on Object {
        // Fallback crop colors remain visible.
      }
    }
  }

  void _createFieldTextures() {
    final atlas = _fieldAtlas;
    if (atlas == null) return;
    for (final state in IsometricFieldState.values) {
      final texture = atlas.clone();
      final cell = switch (state) {
        IsometricFieldState.plowed => 0,
        IsometricFieldState.fertilized => 1,
        IsometricFieldState.growing => 2,
        IsometricFieldState.harvestReady => 2,
        IsometricFieldState.harvested => 3,
      };
      texture
        ..repeat.setValues(0.5, 0.5)
        ..offset.setValues((cell % 2) * 0.5, cell < 2 ? 0.5 : 0.0)
        ..needsUpdate = true;
      _fieldTextures[state] = texture;
      _fieldMaterials[state]?.dispose();
      _fieldMaterials[state] = three.MeshLambertMaterial.fromMap({
        'map': texture,
        'color': state == IsometricFieldState.harvestReady
            ? 0xffead89a
            : 0xfff5edcf,
        'side': three.DoubleSide,
      });
    }
  }

  void _createLandmarkMaterials() {
    final atlas = _landmarkAtlas;
    if (atlas == null) return;
    for (var cell = 0; cell < 4; cell++) {
      final texture = atlas.clone();
      texture
        ..repeat.setValues(0.5, 0.5)
        ..offset.setValues((cell % 2) * 0.5, cell < 2 ? 0.5 : 0.0)
        ..needsUpdate = true;
      _landmarkTextures.add(texture);
      _landmarkMaterials[cell]?.dispose();
      _landmarkMaterials[cell] = three.MeshLambertMaterial.fromMap({
        'map': texture,
        'transparent': true,
        'alphaTest': 0.04,
        'depthWrite': false,
        'side': three.DoubleSide,
      });
    }
  }

  @override
  void didUpdateWidget(covariant IsometricWorldMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requestedPose = widget.cameraPose;
    var cameraChanged = false;
    if (requestedPose != null && requestedPose != _pose) {
      final clampedPose = _clampCameraPose(requestedPose);
      cameraChanged = clampedPose != _pose;
      if (cameraChanged) {
        _pose = clampedPose;
        if (_sceneReady) {
          _setCameraPose(_pose);
        }
      }
    }
    if (!_sceneReady) return;

    final terrainChanged =
        oldWidget.world != widget.world ||
        oldWidget.showRoutes != widget.showRoutes ||
        oldWidget.showInfrastructure != widget.showInfrastructure;

    final parcelsChanged =
        terrainChanged ||
        oldWidget.showParcels != widget.showParcels ||
        !setEquals(oldWidget.ownedParcelIds, widget.ownedParcelIds) ||
        !mapEquals(oldWidget.fieldStates, widget.fieldStates) ||
        !mapEquals(oldWidget.fieldCropIds, widget.fieldCropIds);

    if (terrainChanged) {
      _rebuildVisibleMap(force: true);
    } else if (parcelsChanged) {
      _rebuildParcelLayer();
    } else if (cameraChanged) {
      _rebuildVisibleMap();
    }

    if (oldWidget.selectedParcelId != widget.selectedParcelId) {
      _syncSelectionLayer();
    }

    final mapChanged = terrainChanged || parcelsChanged;
    final markersChanged = !_sameMarkers(oldWidget.markers, widget.markers);
    final pathsChanged = !_samePaths(oldWidget.paths, widget.paths);
    if (mapChanged || cameraChanged || markersChanged) {
      _syncMarkerLayer(_visibleWorldBoundsFor(_pose));
    }
    if (mapChanged || cameraChanged || pathsChanged) {
      _syncPathLayer(_visibleWorldBoundsFor(_pose));
    }
  }

  void _syncSelectionLayer() {
    final root = _selectionRoot;
    if (root == null || !_sceneReady) return;
    for (final child in [...root.children]) {
      root.remove(child);
      if (child is three.Mesh) {
        child.geometry?.dispose();
      }
    }
    final selectedId = widget.selectedParcelId;
    if (selectedId == null) return;
    final parcel = widget.world.parcelById(selectedId, searchRadius: 2);
    if (parcel == null) return;
    root.add(
      _outlineMesh(
        parcel.worldVertices,
        0xffffe08a,
        5.2,
        3.2,
      ),
    );
  }

  bool _sameMarkers(List<IsometricMapMarker> a, List<IsometricMapMarker> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.id != right.id ||
          left.position.x != right.position.x ||
          left.position.y != right.position.y ||
          left.kind != right.kind ||
          left.label != right.label ||
          left.size != right.size) {
        return false;
      }
    }
    return true;
  }

  bool _samePaths(List<IsometricMapPath> a, List<IsometricMapPath> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.id != right.id ||
          left.color != right.color ||
          left.width != right.width ||
          left.points.length != right.points.length) {
        return false;
      }
      for (var pointIndex = 0; pointIndex < left.points.length; pointIndex++) {
        if (left.points[pointIndex].x != right.points[pointIndex].x ||
            left.points[pointIndex].y != right.points[pointIndex].y) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void dispose() {
    _threeJs.dispose();
    for (final texture in _fieldTextures.values) {
      texture.dispose();
    }
    for (final texture in _matureCropTextures.values) {
      texture.dispose();
    }
    for (final texture in _landmarkTextures) {
      texture.dispose();
    }
    _fieldAtlas?.dispose();
    _landmarkAtlas?.dispose();
    for (final material in _fieldMaterials.values) {
      material.dispose();
    }
    for (final material in _parcelMaterials.values) {
      material.dispose();
    }
    for (final material in _roadMaterials.values) {
      material.dispose();
    }
    for (final material in _waterMaterials.values) {
      material.dispose();
    }
    for (final material in _matureCropMaterials.values) {
      material.dispose();
    }
    for (final material in _landmarkMaterials.values) {
      material.dispose();
    }
    for (final material in _infrastructureMaterials.values) {
      material.dispose();
    }
    for (final material in _markerMaterials.values) {
      material.dispose();
    }
    for (final material in _pathMaterials.values) {
      material.dispose();
    }
    for (final mesh in _pathMeshes.values) {
      mesh.geometry?.dispose();
    }
    _markerSphereGeometry?.dispose();
    _landmarkPlaneGeometry?.dispose();
    _treeCanopyGeometry?.dispose();
    _treeTrunkGeometry?.dispose();
    _mountainGeometry?.dispose();
    for (final geom in _sharedGeometryCache.values) {
      geom.dispose();
    }
    _sharedGeometryCache.clear();
    for (final geom in _staticGeometryCache) {
      geom.dispose();
    }
    _staticGeometryCache.clear();
    _cachedRoadObjects.clear();
    _cachedWaterObjects.clear();
    _cachedLakeObjects.clear();
    _cachedPoiObjects.clear();
    _animatedWindmillRotors.clear();
    _rebuildDebounceTimer?.cancel();
    _disposeTransientMaterials();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (_sceneReady &&
          constraints.maxWidth.isFinite &&
          constraints.maxHeight.isFinite) {
        final layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (layoutSize != _lastClampedLayoutSize) {
          _lastClampedLayoutSize = layoutSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _reclampAfterLayout(layoutSize);
          });
        }
      }
      return Listener(
        onPointerSignal: _onPointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: _onTapUp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _threeJs.build(),
              if (!_sceneReady)
                const ColoredBox(
                  color: Color(0xff3b5c3d),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xffe6d9a6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _sceneReady) {
      final zoomFactor = event.scrollDelta.dy < 0 ? 1.15 : 0.87;
      final newZoom = (_pose.zoom * zoomFactor).clamp(_minZoom, _maxZoom).toDouble();
      final viewport = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
      if (viewport.isEmpty) return;
      final focal = event.localPosition;
      final anchor = _worldPointAt(focal);
      final nextCenter = anchor == null
          ? _pose.center
          : _centerKeepingWorldPointAtScreenPoint(anchor, focal, viewport, newZoom);
      _pose = _clampCameraPose(MapCameraPose(center: nextCenter, zoom: newZoom), viewport: viewport);
      _setCameraPose(_pose);
      _notifyCameraChanged();
      _debounceRebuild();
    }
  }

  void _debounceRebuild() {
    _rebuildDebounceTimer?.cancel();
    _rebuildDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted || !_sceneReady) return;
      final viewport = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
      final visibleBounds = _visibleWorldBoundsFor(_pose, viewport: viewport);
      _rebuildVisibleMap();
      _syncMarkerLayer(visibleBounds);
      _syncPathLayer(visibleBounds);
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _rebuildDebounceTimer?.cancel();
    final viewport = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
    if (viewport.isEmpty) return;
    _gestureAnchorWorld = _worldPointAt(details.localFocalPoint);
    _gestureStartPose = _pose;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_sceneReady) return;
    final focal = details.localFocalPoint;
    final anchor = _gestureAnchorWorld;
    final zoom = (_gestureStartPose.zoom * details.scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    final viewport = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
    if (viewport.isEmpty) return;
    final nextCenter = anchor == null
        ? _gestureStartPose.center
        : _centerKeepingWorldPointAtScreenPoint(anchor, focal, viewport, zoom);
    _pose = _clampCameraPose(MapCameraPose(center: nextCenter, zoom: zoom), viewport: viewport);
    _setCameraPose(_pose);
    _notifyCameraChanged();
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _gestureAnchorWorld = null;
    final viewport = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
    final visibleBounds = _visibleWorldBoundsFor(_pose, viewport: viewport);
    _rebuildVisibleMap();
    _syncMarkerLayer(visibleBounds);
    _syncPathLayer(visibleBounds);
    _notifyCameraChanged(force: true);
  }

  void _notifyCameraChanged({bool force = false}) {
    final callback = widget.onCameraChanged;
    if (callback == null || !mounted) return;
    final now = DateTime.now();
    final previous = _lastCameraNotification;
    if (!force &&
        previous != null &&
        now.difference(previous) < const Duration(milliseconds: 32)) {
      return;
    }
    _lastCameraNotification = now;
    callback(_pose);
  }

  WorldMapPoint _centerKeepingWorldPointAtScreenPoint(
    WorldMapPoint worldPoint,
    Offset screenPoint,
    Size viewport,
    double zoom,
  ) {
    final projectedX =
        (screenPoint.dx - viewport.width / 2) / (zoom * math.sqrt(0.5));
    final projectedY = (screenPoint.dy - viewport.height / 2) / (zoom * 0.5);
    final worldDx = (projectedX + projectedY) / 2;
    final worldDy = (projectedY - projectedX) / 2;
    return WorldMapPoint(worldPoint.x - worldDx, worldPoint.y - worldDy);
  }

  Rect _visibleWorldBoundsFor(MapCameraPose pose, {Size? viewport}) {
    return _projectedWorldBoundsForPose(pose, viewport ?? (_lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize));
  }

  void _updateCameraFrustum(Size size) {
    if (size.isEmpty || !_sceneReady) return;
    _camera.left = -size.width / 2;
    _camera.right = size.width / 2;
    _camera.top = size.height / 2;
    _camera.bottom = -size.height / 2;
    _camera.updateProjectionMatrix();
  }

  void _reclampAfterLayout(Size size) {
    if (size.isEmpty || !_sceneReady) return;
    _updateCameraFrustum(size);
    final clamped = _clampCameraPose(_pose, viewport: size);
    final changed = clamped != _pose;
    if (changed) {
      _pose = clamped;
      _setCameraPose(_pose);
    }
    _rebuildVisibleMap(force: changed || _lastBuiltBounds == null);
    final visibleBounds = _visibleWorldBoundsFor(_pose, viewport: size);
    _syncMarkerLayer(visibleBounds);
    _syncPathLayer(visibleBounds);
    _notifyCameraChanged(force: true);
  }

  MapCameraPose _clampCameraPose(MapCameraPose pose, {Size? viewport}) =>
      clampIsometricCameraPose(pose, viewport ?? (_lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize));

  void _ensureDynamicRoots() {
    _markerRoot ??= three.Group();
    _pathRoot ??= three.Group();
    if (!_scene.children.contains(_markerRoot)) _scene.add(_markerRoot!);
    if (!_scene.children.contains(_pathRoot)) _scene.add(_pathRoot!);
  }

  int? _landmarkCellForMarker(IsometricMarkerKind kind) => switch (kind) {
    IsometricMarkerKind.market || IsometricMarkerKind.order => 2,
    IsometricMarkerKind.farm => 3,
    IsometricMarkerKind.player ||
    IsometricMarkerKind.vehicle ||
    IsometricMarkerKind.poi => null,
  };

  three.Material _markerMaterialFor(IsometricMarkerKind kind) {
    final cell = _landmarkCellForMarker(kind);
    final landmarkMaterial = cell == null ? null : _landmarkMaterials[cell];
    if (landmarkMaterial != null) return landmarkMaterial;
    return _markerMaterials.putIfAbsent(kind, () {
      final color = switch (kind) {
        IsometricMarkerKind.player => 0xff42a9ca,
        IsometricMarkerKind.vehicle => 0xff477a47,
        IsometricMarkerKind.order => 0xffdf8f2f,
        IsometricMarkerKind.farm => 0xffd5b75a,
        IsometricMarkerKind.market => 0xffa94e38,
        IsometricMarkerKind.poi => 0xff78854c,
      };
      return three.MeshLambertMaterial.fromMap({
        'color': color,
        'side': three.DoubleSide,
      });
    });
  }

  void _syncMarkerLayer(Rect bounds) {
    _ensureDynamicRoots();
    final root = _markerRoot!;
    final visible = <String, IsometricMapMarker>{
      for (final marker in widget.markers)
        if (bounds
            .inflate(180)
            .contains(Offset(marker.position.x, marker.position.y)))
          marker.id: marker,
    };

    for (final id in _markerMeshes.keys.toList()) {
      if (visible.containsKey(id)) continue;
      root.remove(_markerMeshes.remove(id)!);
      _visibleMarkers.remove(id);
    }

    for (final entry in visible.entries) {
      final marker = entry.value;
      if (marker.id.startsWith('settlement:')) continue;
      final atlasCell = _landmarkCellForMarker(marker.kind);
      final landmark =
          atlasCell != null && _landmarkMaterials.containsKey(atlasCell);
      final geometry = landmark
          ? _landmarkPlaneGeometry
          : _markerSphereGeometry;
      if (geometry == null) continue;
      var mesh = _markerMeshes[entry.key];
      if (mesh == null) {
        mesh = three.Mesh(geometry, _markerMaterialFor(marker.kind));
        _markerMeshes[entry.key] = mesh;
        root.add(mesh);
      } else {
        if (!identical(mesh.geometry, geometry)) mesh.geometry = geometry;
        final material = _markerMaterialFor(marker.kind);
        if (!identical(mesh.material, material)) mesh.material = material;
      }

      final markerSize = landmark
          ? (marker.size * 3.1).clamp(88.0, 176.0).toDouble()
          : marker.size * 0.43;
      mesh
        ..position.setValues(
          marker.position.x,
          landmark ? markerSize * 0.49 : marker.size * 0.65,
          marker.position.y,
        )
        ..scale.setValues(markerSize, markerSize, landmark ? 1 : markerSize)
        ..userData['markerId'] = marker.id;
      if (landmark) mesh.lookAt(_camera.position);
      _visibleMarkers[entry.key] = marker;
    }
  }

  bool _samePath(IsometricMapPath a, IsometricMapPath b) {
    if (a.color != b.color ||
        a.width != b.width ||
        a.points.length != b.points.length) {
      return false;
    }
    for (var index = 0; index < a.points.length; index++) {
      if (a.points[index].x != b.points[index].x ||
          a.points[index].y != b.points[index].y) {
        return false;
      }
    }
    return true;
  }

  void _syncPathLayer(Rect bounds) {
    _ensureDynamicRoots();
    final root = _pathRoot!;
    final visible = <String, IsometricMapPath>{
      for (final path in widget.paths)
        if (path.points.length > 1 &&
            _pointsOverlapBounds(path.points, bounds, path.width))
          path.id: path,
    };

    for (final id in _pathMeshes.keys.toList()) {
      final current = visible[id];
      final previous = _visiblePaths[id];
      if (current != null && previous != null && _samePath(previous, current)) {
        continue;
      }
      final mesh = _pathMeshes.remove(id)!;
      root.remove(mesh);
      mesh.geometry?.dispose();
      _visiblePaths.remove(id);
    }

    for (final entry in visible.entries) {
      if (_pathMeshes.containsKey(entry.key)) continue;
      final path = entry.value;
      final material = _pathMaterials.putIfAbsent(
        path.color,
        () => three.MeshLambertMaterial.fromMap({'color': path.color}),
      );
      final mesh = _tube(
        path.points,
        material,
        path.width.clamp(0.5, 30).toDouble() / 2,
        5.5,
      );
      _pathMeshes[entry.key] = mesh;
      _visiblePaths[entry.key] = path;
      root.add(mesh);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_sceneReady) return;
    final point = _worldPointAt(details.localPosition);
    if (point == null) return;
    final marker = _markerAt(details.localPosition);
    if (marker != null) {
      widget.onMarkerTap?.call(
        marker.id,
        marker.position,
        details.localPosition,
      );
      return;
    }
    widget.onWorldTap(point, details.localPosition);
  }

  IsometricMapMarker? _markerAt(Offset position) {
    final size = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
    if (size.isEmpty) return null;
    
    // 1. Fast, reliable 2D screen proximity hit-testing:
    IsometricMapMarker? closestMarker;
    var minDistance = double.infinity;
    for (final marker in widget.markers) {
      final screenPos = projectMapPointToScreen(_pose, marker.position, size);
      final touchRadius = math.max(34.0, marker.size * 0.95);
      final dist = (screenPos - position).distance;
      if (dist <= touchRadius && dist < minDistance) {
        minDistance = dist;
        closestMarker = marker;
      }
    }
    if (closestMarker != null) return closestMarker;

    // 2. Three.js raycasting fallback
    final root = _markerRoot;
    if (root == null) return null;
    _raycaster.setFromCamera(
      three.Vector2(
        (position.dx / size.width) * 2 - 1,
        -((position.dy / size.height) * 2 - 1),
      ),
      _camera,
    );
    final hits = _raycaster.intersectObject(root, true);
    if (hits.isEmpty) return null;
    final hitObject = hits.first.object;
    final markerId = hitObject?.userData['markerId'] as String?;
    return markerId == null ? null : _visibleMarkers[markerId];
  }

  Size get _viewportSize => Size(_threeJs.width, _threeJs.height);

  WorldMapPoint? _worldPointAt(Offset localPosition) {
    final size = _lastClampedLayoutSize.isEmpty ? _viewportSize : _lastClampedLayoutSize;
    if (size.isEmpty) return null;

    // Direct analytical isometric unprojection: zero latency, zero raycast misses
    final delta = _projectedWorldDeltaForScreen(localPosition, size, _pose.zoom);
    final world = ProceduralFarmWorld.worldBounds;
    final clampedX = (_pose.center.x + delta.x).clamp(world.left, world.right).toDouble();
    final clampedY = (_pose.center.y + delta.y).clamp(world.top, world.bottom).toDouble();
    return WorldMapPoint(clampedX, clampedY);
  }

  void _applyPose(MapCameraPose pose, {required bool rebuild, Size? viewport}) {
    if (!_sceneReady && !identical(_threeJs.scene, _scene)) return;
    _pose = _clampCameraPose(pose, viewport: viewport);
    _setCameraPose(_pose);
    if (rebuild) _rebuildVisibleMap(force: true);
  }

  void _setCameraPose(MapCameraPose pose) {
    final center = pose.center;
    final distance = 20000.0;
    _camera
      ..zoom = pose.zoom.clamp(_minZoom, _maxZoom).toDouble()
      ..position.setValues(
        center.x + distance * 0.5,
        distance * 0.70710678118,
        center.y + distance * 0.5,
      )
      ..lookAt(three.Vector3(center.x, 0, center.y))
      ..updateProjectionMatrix();
    _camera.updateMatrixWorld(true);
  }

  void _rebuildVisibleMap({bool force = false}) {
    if (!_sceneReady && !identical(_threeJs.scene, _scene)) return;
    final visibleBounds = _visibleWorldBoundsFor(_pose);
    final parcelsVisible = widget.showParcels && _pose.zoom >= 0.22;
    final treesVisible = _pose.zoom >= 0.28;
    final mountainsVisible = _pose.zoom >= 0.24;
    final roadHighlightsVisible = _pose.zoom > 0.3;
    final lodChanged =
        _lastBuiltParcelsVisible != parcelsVisible ||
        _lastBuiltTreesVisible != treesVisible ||
        _lastBuiltMountainsVisible != mountainsVisible ||
        _lastBuiltRoadHighlightsVisible != roadHighlightsVisible;
    final previousBounds = _lastBuiltBounds;
    final visibleAreaLoaded =
        previousBounds != null &&
        previousBounds.left <= visibleBounds.left &&
        previousBounds.top <= visibleBounds.top &&
        previousBounds.right >= visibleBounds.right &&
        previousBounds.bottom >= visibleBounds.bottom;
    if (!force && visibleAreaLoaded && !lodChanged) {
      return;
    }

    final terrainRoot = _terrainRoot;
    if (terrainRoot != null) {
      _animatedWindmillRotors.clear();
      _disposeGroupGeometry(terrainRoot);
      _disposeTransientMaterials();
      for (final child in [...terrainRoot.children]) {
        terrainRoot.remove(child);
      }
    }
    final root = terrainRoot ?? three.Group();
    _terrainRoot = root;
    if (!_scene.children.contains(root)) _scene.add(root);

    final buildBounds = visibleBounds.inflate(farmWorldChunkSize * 1.0);
    _drawRegions(root, buildBounds);
    final firstChunkX =
        ((buildBounds.left / farmWorldChunkSize).floor() - _chunkPadding).clamp(
          ProceduralFarmWorld.minChunkX,
          ProceduralFarmWorld.maxChunkX,
        );
    final lastChunkX =
        ((buildBounds.right / farmWorldChunkSize).floor() + _chunkPadding)
            .clamp(
              ProceduralFarmWorld.minChunkX,
              ProceduralFarmWorld.maxChunkX,
            );
    final firstChunkY =
        ((buildBounds.top / farmWorldChunkSize).floor() - _chunkPadding).clamp(
          ProceduralFarmWorld.minChunkY,
          ProceduralFarmWorld.maxChunkY,
        );
    final lastChunkY =
        ((buildBounds.bottom / farmWorldChunkSize).floor() + _chunkPadding)
            .clamp(
              ProceduralFarmWorld.minChunkY,
              ProceduralFarmWorld.maxChunkY,
            );
    final chunks = <WorldMapChunk>[];
    for (var y = firstChunkY; y <= lastChunkY; y++) {
      for (var x = firstChunkX; x <= lastChunkX; x++) {
        if (!ProceduralFarmWorld.isChunkInBounds(x, y)) continue;
        chunks.add(widget.world.chunkAt(x, y));
      }
    }

    final featureBounds = buildBounds.inflate(140);
    final roads = widget.world.roadSegmentsInBounds(
      featureBounds.left,
      featureBounds.top,
      featureBounds.right,
      featureBounds.bottom,
    );
    final watercourses = widget.world.watercourses
        .where(
          (watercourse) => _pointsOverlapBounds(
            watercourse.points,
            featureBounds,
            watercourse.width,
          ),
        )
        .toList();
    final lakes = widget.world.lakes
        .where((lake) => lake.bounds.inflate(24).overlaps(featureBounds))
        .toList();
    final ponds = [for (final chunk in chunks) ...chunk.ponds]
        .where((pond) => _pondBounds(pond).inflate(18).overlaps(featureBounds))
        .toList();
    final bridges = widget.world.bridgesInBounds(featureBounds);

    final neighboringParcels = <_ParcelSpatialFeature>[];
    for (final chunk in chunks) {
      for (final parcel in chunk.parcels) {
        final parcelBounds = _parcelBounds(parcel);
        if (parcelBounds.inflate(112).overlaps(buildBounds)) {
          neighboringParcels.add(_ParcelSpatialFeature(parcel, parcelBounds));
        }
      }
    }
    if (treesVisible) {
      final visibleTrees = [for (final chunk in chunks) ...chunk.trees].where(
        (tree) => buildBounds
            .inflate(tree.radius + 40)
            .contains(Offset(tree.center.x, tree.center.y)),
      );
      final pois = [for (final chunk in chunks) ...chunk.pointsOfInterest];
      _drawTrees(
        root,
        visibleTrees
            .where(
              (tree) => !_treeConflicts(
                tree,
                neighboringParcels,
                roads,
                watercourses,
                lakes,
                ponds,
                widget.world.settlements,
                pois,
                bridges,
              ),
            )
            .toList(),
      );
    }
    if (mountainsVisible) {
      _drawMountains(root, [
        for (final chunk in chunks)
          ...chunk.mountains.where(
            (mountain) =>
                _mountainBounds(mountain).inflate(12).overlaps(buildBounds),
          ),
      ]);
      _drawPonds(root, ponds, buildBounds);
    }
    if (widget.showRoutes) _drawRoads(root, roads, buildBounds);
    _drawWatercourses(root, watercourses, buildBounds);
    _drawLakes(root, lakes, buildBounds);
    _drawSettlements(root, buildBounds, roads);
    if (widget.showInfrastructure) {
      _drawPointOfInterest(root, chunks, buildBounds);
    }
    _drawBridges(root, buildBounds);

    _rebuildParcelLayer(buildBounds);

    _lastBuiltBounds = Rect.fromLTRB(
      buildBounds.left,
      buildBounds.top,
      buildBounds.right,
      buildBounds.bottom,
    );
    _lastBuiltParcelsVisible = parcelsVisible;
    _lastBuiltTreesVisible = treesVisible;
    _lastBuiltMountainsVisible = mountainsVisible;
    _lastBuiltRoadHighlightsVisible = roadHighlightsVisible;
  }

  void _rebuildParcelLayer([Rect? bounds]) {
    if (!_sceneReady) return;
    final root = _parcelRoot;
    if (root == null) return;
    _disposeGroupGeometry(root);
    for (final child in [...root.children]) {
      root.remove(child);
    }
    _drawnParcelIds.clear();

    final parcelsVisible = widget.showParcels && _pose.zoom >= 0.22;
    if (!parcelsVisible) return;

    final buildBounds = bounds ?? _lastBuiltBounds ?? _visibleWorldBoundsFor(_pose).inflate(farmWorldChunkSize * 0.4);
    final firstChunkX =
        ((buildBounds.left / farmWorldChunkSize).floor() - _chunkPadding).clamp(
          ProceduralFarmWorld.minChunkX,
          ProceduralFarmWorld.maxChunkX,
        );
    final lastChunkX =
        ((buildBounds.right / farmWorldChunkSize).floor() + _chunkPadding)
            .clamp(
              ProceduralFarmWorld.minChunkX,
              ProceduralFarmWorld.maxChunkX,
            );
    final firstChunkY =
        ((buildBounds.top / farmWorldChunkSize).floor() - _chunkPadding).clamp(
          ProceduralFarmWorld.minChunkY,
          ProceduralFarmWorld.maxChunkY,
        );
    final lastChunkY =
        ((buildBounds.bottom / farmWorldChunkSize).floor() + _chunkPadding)
            .clamp(
              ProceduralFarmWorld.minChunkY,
              ProceduralFarmWorld.maxChunkY,
            );
    final chunks = <WorldMapChunk>[];
    for (var y = firstChunkY; y <= lastChunkY; y++) {
      for (var x = firstChunkX; x <= lastChunkX; x++) {
        if (!ProceduralFarmWorld.isChunkInBounds(x, y)) continue;
        chunks.add(widget.world.chunkAt(x, y));
      }
    }

    final featureBounds = buildBounds.inflate(140);
    final roads = widget.world.roadSegmentsInBounds(
      featureBounds.left,
      featureBounds.top,
      featureBounds.right,
      featureBounds.bottom,
    );
    final watercourses = widget.world.watercourses
        .where(
          (watercourse) => _pointsOverlapBounds(
            watercourse.points,
            featureBounds,
            watercourse.width,
          ),
        )
        .toList();
    final lakes = widget.world.lakes
        .where((lake) => lake.bounds.inflate(24).overlaps(featureBounds))
        .toList();
    final ponds = [for (final chunk in chunks) ...chunk.ponds]
        .where((pond) => _pondBounds(pond).inflate(18).overlaps(featureBounds))
        .toList();

    for (final chunk in chunks) {
      for (final parcel in chunk.parcels) {
        final parcelBounds = _parcelBounds(parcel);
        if (parcelBounds.inflate(48).overlaps(buildBounds) &&
            !_parcelOverlapsFeatures(
              parcel,
              parcelBounds,
              roads,
              watercourses,
              lakes,
              ponds,
            )) {
          _drawParcel(root, parcel);
        }
      }
    }
  }

  void _drawRegions(three.Group root, Rect bounds) {
    for (final region in widget.world.regions) {
      if (!_pointsOverlapBounds(region.boundary, bounds, 0)) continue;
      root.add(
        _polygonMesh(
          region.boundary,
          _transient(
            three.MeshLambertMaterial.fromMap({
              'color': region.soilColor & 0x00ffffff,
              'transparent': true,
              'opacity': 0.12,
              'side': three.DoubleSide,
            }),
          ),
          height: 0.15,
        ),
      );
    }
  }

  void _drawParcel(three.Group root, WorldMapParcel parcel) {
    if (!_drawnParcelIds.add(parcel.id)) return;
    final fieldState =
        widget.fieldStates[parcel.id] ?? _fallbackFieldState(parcel);
    final selected = widget.selectedParcelId == parcel.id;
    final cropId = widget.fieldCropIds[parcel.id]?.toLowerCase() ?? '';
    final matureMaterial = fieldState == IsometricFieldState.harvestReady
        ? _matureCropMaterials[_starterCropId(cropId)]
        : null;
    final textureMaterial = _fieldMaterials[fieldState];
    final material = selected
        ? _materialFor('selected:${parcel.cropType.index}', 0xffe5bb4e)
        : matureMaterial ??
              textureMaterial ??
              _materialFor(
                'crop:${parcel.cropType.index}',
                _cropColor(parcel.cropType),
              );
    final vertices = parcel.worldVertices;
    root.add(_polygonMesh(vertices, material, height: 0.45, normalizeUvs: true));
    if (widget.ownedParcelIds.contains(parcel.id)) {
      root.add(
        _outlineMesh(
          vertices,
          0xffe9d690,
          2.1,
          0.85,
        ),
      );
    }
  }

  String _starterCropId(String cropId) {
    if (cropId.contains('wheat')) return 'wheat';
    if (cropId.contains('maize') || cropId.contains('corn')) return 'maize';
    return '';
  }

  bool _parcelOverlapsFeatures(
    WorldMapParcel parcel,
    Rect parcelBounds,
    List<WorldMapRoad> roads,
    List<WorldMapWatercourse> watercourses,
    List<WorldMapLake> lakes,
    List<WorldMapPond> ponds,
  ) {
    final cached = _parcelOverlapCache[parcel.id];
    if (cached != null) return cached;

    for (final lake in lakes) {
      if (lake.bounds.inflate(8).overlaps(parcelBounds)) {
        _parcelOverlapCache[parcel.id] = true;
        return true;
      }
    }
    for (final pond in ponds) {
      if (_pondBounds(pond).inflate(10).overlaps(parcelBounds)) {
        _parcelOverlapCache[parcel.id] = true;
        return true;
      }
    }
    final parcelCenterX = (parcelBounds.left + parcelBounds.right) / 2;
    final parcelCenterY = (parcelBounds.top + parcelBounds.bottom) / 2;
    final parcelRadius = math.max(parcelBounds.width, parcelBounds.height) / 2;

    for (final road in roads) {
      if (!_pointsOverlapBounds(road.points, parcelBounds.inflate(16), road.width)) {
        continue;
      }
      final safeDist = parcelRadius + road.width / 2 + 3.0;
      final safeDistSq = safeDist * safeDist;
      for (var i = 0; i < road.points.length - 1; i++) {
        if (_distanceToSegmentSq(
              parcelCenterX,
              parcelCenterY,
              road.points[i].x,
              road.points[i].y,
              road.points[i + 1].x,
              road.points[i + 1].y,
            ) <=
            safeDistSq) {
          _parcelOverlapCache[parcel.id] = true;
          return true;
        }
      }
    }
    for (final watercourse in watercourses) {
      if (!_pointsOverlapBounds(watercourse.points, parcelBounds.inflate(16), watercourse.width)) {
        continue;
      }
      final safeDist = parcelRadius + watercourse.width / 2 + 3.0;
      final safeDistSq = safeDist * safeDist;
      for (var i = 0; i < watercourse.points.length - 1; i++) {
        if (_distanceToSegmentSq(
              parcelCenterX,
              parcelCenterY,
              watercourse.points[i].x,
              watercourse.points[i].y,
              watercourse.points[i + 1].x,
              watercourse.points[i + 1].y,
            ) <=
            safeDistSq) {
          _parcelOverlapCache[parcel.id] = true;
          return true;
        }
      }
    }
    _parcelOverlapCache[parcel.id] = false;
    return false;
  }

  Rect _parcelBounds(WorldMapParcel parcel) {
    final vertices = parcel.worldVertices;
    if (vertices.isEmpty) return Rect.zero;
    var minX = vertices.first.x;
    var maxX = vertices.first.x;
    var minY = vertices.first.y;
    var maxY = vertices.first.y;
    for (final point in vertices.skip(1)) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Rect _pondBounds(WorldMapPond pond) => Rect.fromCenter(
    center: Offset(pond.center.x, pond.center.y),
    width: pond.width,
    height: pond.height,
  );

  bool _treeConflicts(
    WorldMapTree tree,
    List<_ParcelSpatialFeature> parcels,
    List<WorldMapRoad> roads,
    List<WorldMapWatercourse> watercourses,
    List<WorldMapLake> lakes,
    List<WorldMapPond> ponds, [
    List<WorldMapSettlement> settlements = const [],
    List<WorldMapPointOfInterest> pois = const [],
    List<WorldMapBridge> bridges = const [],
  ]) {
    final cacheKey = Object.hash(tree.center.x.round(), tree.center.y.round());
    final cached = _treeConflictCache[cacheKey];
    if (cached != null) return cached;

    final keepout = tree.radius + 20.0;
    final treeOffset = Offset(tree.center.x, tree.center.y);

    for (final feature in parcels) {
      if (feature.bounds.inflate(keepout).contains(treeOffset)) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }
    for (final lake in lakes) {
      if (lake.bounds.inflate(keepout).contains(treeOffset)) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }
    for (final pond in ponds) {
      if (_pondBounds(pond).inflate(keepout).contains(treeOffset)) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }
    for (final settlement in settlements) {
      final keepoutRadius = switch (settlement.kind) {
        WorldMapSettlementKind.city => 195.0,
        WorldMapSettlementKind.town => 135.0,
        WorldMapSettlementKind.village => 80.0,
        WorldMapSettlementKind.hamlet => 48.0,
      };
      final dx = settlement.position.x - tree.center.x;
      final dy = settlement.position.y - tree.center.y;
      if (dx * dx + dy * dy <= keepoutRadius * keepoutRadius) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }
    for (final poi in pois) {
      final dx = poi.position.x - tree.center.x;
      final dy = poi.position.y - tree.center.y;
      final radius = 54.0 + tree.radius;
      if (dx * dx + dy * dy <= radius * radius) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }
    for (final bridge in bridges) {
      final dx = bridge.position.x - tree.center.x;
      final dy = bridge.position.y - tree.center.y;
      final radius = bridge.length / 2 + tree.radius + 12.0;
      if (dx * dx + dy * dy <= radius * radius) {
        _treeConflictCache[cacheKey] = true;
        return true;
      }
    }

    final bounds = Rect.fromCenter(
      center: treeOffset,
      width: keepout * 2,
      height: keepout * 2,
    );
    for (final road in roads) {
      if (!_pointsOverlapBounds(road.points, bounds, road.width)) continue;
      final limit = keepout + road.width / 2;
      final limitSq = limit * limit;
      for (var i = 0; i < road.points.length - 1; i++) {
        if (_distanceToSegmentSq(
              tree.center.x,
              tree.center.y,
              road.points[i].x,
              road.points[i].y,
              road.points[i + 1].x,
              road.points[i + 1].y,
            ) <=
            limitSq) {
          _treeConflictCache[cacheKey] = true;
          return true;
        }
      }
    }
    for (final watercourse in watercourses) {
      if (!_pointsOverlapBounds(watercourse.points, bounds, watercourse.width)) continue;
      final limit = keepout + watercourse.width / 2;
      final limitSq = limit * limit;
      for (var i = 0; i < watercourse.points.length - 1; i++) {
        if (_distanceToSegmentSq(
              tree.center.x,
              tree.center.y,
              watercourse.points[i].x,
              watercourse.points[i].y,
              watercourse.points[i + 1].x,
              watercourse.points[i + 1].y,
            ) <=
            limitSq) {
          _treeConflictCache[cacheKey] = true;
          return true;
        }
      }
    }
    _treeConflictCache[cacheKey] = false;
    return false;
  }



  IsometricFieldState _fallbackFieldState(WorldMapParcel parcel) {
    final hash = parcel.id.hashCode.abs();
    return IsometricFieldState.values[hash % IsometricFieldState.values.length];
  }

  int _cropColor(WorldCropType crop) => switch (crop) {
    WorldCropType.grain => 0xffc09a51,
    WorldCropType.oilseed => 0xff9b9a54,
    WorldCropType.vegetable => 0xff63804c,
    WorldCropType.pasture => 0xff88a16b,
  };

  three.Material _materialFor(String key, int color) =>
      _parcelMaterials.putIfAbsent(
        key,
        () => three.MeshLambertMaterial.fromMap({
          'color': color,
          'side': three.DoubleSide,
        }),
      );

  void _drawRoads(three.Group root, List<WorldMapRoad> roads, Rect bounds) {
    for (final road in roads) {
      if (road.points.length < 2 ||
          !_pointsOverlapBounds(road.points, bounds, road.width)) {
        continue;
      }
      var cached = _cachedRoadObjects[road.id];
      if (cached == null) {
        cached = three.Group();
        _buildRoadMeshes(cached, road);
        _cachedRoadObjects[road.id] = cached;
      }
      root.add(cached);
    }
  }

  void _buildRoadMeshes(three.Group group, WorldMapRoad road) {
    final points = road.points;
    switch (road.type) {
      case WorldMapRoadType.arterial:
        // Modern Asfalt Ana Arter:
        // 1. Dış Çakıl/Toprak Banket
        group.add(_staticTube(points, _tubeMaterial('art-shoulder', 0xff524a3e), road.width * 1.06, 1.9));
        // 2. Koyu Pürüzsüz Asfalt Yüzey
        group.add(_staticTube(points, _tubeMaterial('art-pavement', 0xff2a2c2e), road.width * 0.88, 2.4));
        // 3. Kenar Beyaz Güvenlik Çizgileri
        group.add(_staticTube(points, _tubeMaterial('art-edge-white', 0xffe4e1d7), road.width * 0.82, 2.6));
        group.add(_staticTube(points, _tubeMaterial('art-pavement-inner', 0xff2a2c2e), road.width * 0.70, 2.7));
        // 4. Kesikli Sarı Merkez Şerit Çizgisi
        _drawDashedRoadLine(group, points, 0xffebb842, width: 1.8, height: 3.0, dashLength: 22.0, gapLength: 14.0);
        break;

      case WorldMapRoadType.secondary:
        // Rustik Taş & Stabilize Köy Yolu:
        group.add(_staticTube(points, _tubeMaterial('sec-shoulder', 0xff6b5f4c), road.width * 0.98, 1.8));
        group.add(_staticTube(points, _tubeMaterial('sec-cobble', 0xff988c78), road.width * 0.80, 2.3));
        group.add(_staticTube(points, _tubeMaterial('sec-curb', 0xff7a6d59), road.width * 0.52, 2.5));
        break;

      case WorldMapRoadType.dirt:
        // Killi Toprak Çiftlik / Traktör Yolu:
        group.add(_staticTube(points, _tubeMaterial('dirt-shoulder', 0xff684c2d), road.width * 0.92, 1.7));
        group.add(_staticTube(points, _tubeMaterial('dirt-surface', 0xff8b683e), road.width * 0.74, 2.1));
        // Çift traktör tekerlek izleri (Dual Wheel Ruts):
        final rutLeft = _offsetPath(points, -road.width * 0.23);
        final rutRight = _offsetPath(points, road.width * 0.23);
        group.add(_staticTube(rutLeft, _tubeMaterial('dirt-rut', 0xff4e351b), road.width * 0.18, 2.4));
        group.add(_staticTube(rutRight, _tubeMaterial('dirt-rut', 0xff4e351b), road.width * 0.18, 2.4));
        break;

      case WorldMapRoadType.trail:
        // Organik Patika / Yürüyüş Yolu:
        group.add(_staticTube(points, _tubeMaterial('trail-edge', 0xff7a6649), road.width * 0.76, 1.6));
        group.add(_staticTube(points, _tubeMaterial('trail-path', 0xff9e845c), road.width * 0.46, 2.0));
        break;
    }
  }

  List<WorldMapPoint> _offsetPath(List<WorldMapPoint> points, double offset) {
    if (points.length < 2) return points;
    final result = <WorldMapPoint>[];
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      double dirX;
      double dirY;
      if (i == 0) {
        dirX = points[1].x - current.x;
        dirY = points[1].y - current.y;
      } else if (i == points.length - 1) {
        dirX = current.x - points[i - 1].x;
        dirY = current.y - points[i - 1].y;
      } else {
        dirX = points[i + 1].x - points[i - 1].x;
        dirY = points[i + 1].y - points[i - 1].y;
      }
      final len = math.sqrt(dirX * dirX + dirY * dirY);
      final normalX = len > 0.0001 ? -dirY / len : 0.0;
      final normalY = len > 0.0001 ? dirX / len : 1.0;
      result.add(WorldMapPoint(current.x + normalX * offset, current.y + normalY * offset));
    }
    return result;
  }

  void _drawDashedRoadLine(
    three.Group root,
    List<WorldMapPoint> points,
    int color, {
    required double width,
    required double height,
    double dashLength = 20.0,
    double gapLength = 14.0,
  }) {
    if (points.length < 2) return;
    final radius = width / 2;
    final material = _tubeMaterial('dashed-$color', color);
    var accumulated = 0.0;
    var drawing = true;
    var currentSegment = <WorldMapPoint>[];
    final allSegments = <List<WorldMapPoint>>[];

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dx = p1.x - p0.x;
      final dy = p1.y - p0.y;
      final segLen = math.sqrt(dx * dx + dy * dy);
      if (segLen <= 0.0001) continue;

      var walked = 0.0;
      while (walked < segLen) {
        final targetLimit = drawing ? dashLength : gapLength;
        final needed = targetLimit - accumulated;
        final remainInSeg = segLen - walked;
        final step = math.min(needed, remainInSeg);

        final tStart = walked / segLen;
        final startPt = WorldMapPoint(
          p0.x + dx * tStart,
          p0.y + dy * tStart,
        );
        walked += step;
        accumulated += step;
        final tEnd = walked / segLen;
        final endPt = WorldMapPoint(
          p0.x + dx * tEnd,
          p0.y + dy * tEnd,
        );

        if (drawing) {
          if (currentSegment.isEmpty) currentSegment.add(startPt);
          currentSegment.add(endPt);
        }

        if (accumulated >= targetLimit) {
          if (drawing && currentSegment.length >= 2) {
            allSegments.add(currentSegment);
            currentSegment = [];
          }
          drawing = !drawing;
          accumulated = 0.0;
        }
      }
    }
    if (drawing && currentSegment.length >= 2) {
      allSegments.add(currentSegment);
    }

    if (allSegments.isEmpty) return;

    final geometry = three.BufferGeometry();
    final vertices = <double>[];
    final indices = <int>[];
    var vertexOffset = 0;

    for (final seg in allSegments) {
      for (var i = 0; i < seg.length; i++) {
        final current = seg[i];
        double dirX;
        double dirY;
        if (i == 0) {
          dirX = seg[1].x - current.x;
          dirY = seg[1].y - current.y;
        } else if (i == seg.length - 1) {
          dirX = current.x - seg[i - 1].x;
          dirY = current.y - seg[i - 1].y;
        } else {
          dirX = seg[i + 1].x - seg[i - 1].x;
          dirY = seg[i + 1].y - seg[i - 1].y;
        }
        final len = math.sqrt(dirX * dirX + dirY * dirY);
        final normalX = len > 0.0001 ? -dirY / len : 0.0;
        final normalY = len > 0.0001 ? dirX / len : 1.0;

        final leftX = current.x + normalX * radius;
        final leftZ = current.y + normalY * radius;
        final rightX = current.x - normalX * radius;
        final rightZ = current.y - normalY * radius;

        vertices.addAll([leftX, height, leftZ]);
        vertices.addAll([rightX, height, rightZ]);

        if (i < seg.length - 1) {
          final i0 = vertexOffset;
          final i1 = vertexOffset + 1;
          final i2 = vertexOffset + 2;
          final i3 = vertexOffset + 3;
          indices.addAll([i0, i2, i1, i1, i2, i3]);
          vertexOffset += 2;
        }
      }
      vertexOffset += 2;
    }

    geometry.setAttribute(
      three.Attribute.position,
      three.Float32BufferAttribute.fromList(vertices, 3),
    );
    geometry.setIndex(indices);
    geometry.computeVertexNormals();

    _staticGeometryCache.add(geometry);
    root.add(three.Mesh(geometry, material));
  }

  three.Material _tubeMaterial(String key, int color) =>
      _roadMaterials.putIfAbsent(
        key,
        () => three.MeshLambertMaterial.fromMap({'color': color}),
      );

  three.Mesh _tube(
    List<WorldMapPoint> points,
    three.Material material,
    double radius,
    double height,
  ) {
    if (points.length < 2) {
      return three.Mesh(three.BufferGeometry(), material);
    }
    final geometry = three.BufferGeometry();
    final vertices = <double>[];
    final indices = <int>[];

    var vertexOffset = 0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      double dirX;
      double dirY;
      if (i == 0) {
        dirX = points[1].x - current.x;
        dirY = points[1].y - current.y;
      } else if (i == points.length - 1) {
        dirX = current.x - points[i - 1].x;
        dirY = current.y - points[i - 1].y;
      } else {
        dirX = points[i + 1].x - points[i - 1].x;
        dirY = points[i + 1].y - points[i - 1].y;
      }
      final len = math.sqrt(dirX * dirX + dirY * dirY);
      final normalX = len > 0.0001 ? -dirY / len : 0.0;
      final normalY = len > 0.0001 ? dirX / len : 1.0;

      final leftX = current.x + normalX * radius;
      final leftZ = current.y + normalY * radius;
      final rightX = current.x - normalX * radius;
      final rightZ = current.y - normalY * radius;

      vertices.addAll([leftX, height, leftZ]);
      vertices.addAll([rightX, height, rightZ]);

      if (i < points.length - 1) {
        final i0 = vertexOffset;
        final i1 = vertexOffset + 1;
        final i2 = vertexOffset + 2;
        final i3 = vertexOffset + 3;
        indices.addAll([i0, i2, i1, i1, i2, i3]);
        vertexOffset += 2;
      }
    }

    geometry.setAttribute(
      three.Attribute.position,
      three.Float32BufferAttribute.fromList(vertices, 3),
    );
    geometry.setIndex(indices);
    geometry.computeVertexNormals();

    return three.Mesh(geometry, material);
  }

  void _drawWatercourses(
    three.Group root,
    List<WorldMapWatercourse> watercourses,
    Rect bounds,
  ) {
    for (final watercourse in watercourses) {
      if (watercourse.points.length < 2 ||
          !_pointsOverlapBounds(
            watercourse.points,
            bounds,
            watercourse.width,
          )) {
        continue;
      }
      var cached = _cachedWaterObjects[watercourse.id];
      if (cached == null) {
        cached = three.Group();
        final canal = watercourse.type == WorldMapWatercourseType.irrigationCanal;
        final bank = _waterMaterial('bank', canal ? 0xff98855f : 0xff827a61);
        final water = _waterMaterial(
          'water:${watercourse.type.index}',
          canal ? 0xff55969a : 0xff3c8390,
        );
        cached.add(_staticTube(watercourse.points, bank, watercourse.width * 0.67, 1.1));
        cached.add(_staticTube(watercourse.points, water, watercourse.width * 0.47, 1.8));
        if (!canal) {
          cached.add(
            _staticTube(
              watercourse.points,
              _waterMaterial('water-glint', 0xff80bdba),
              2.8,
              2.1,
            ),
          );
        }
        _cachedWaterObjects[watercourse.id] = cached;
      }
      root.add(cached);
    }
  }

  three.Material _waterMaterial(String key, int color) =>
      _waterMaterials.putIfAbsent(
        key,
        () => three.MeshLambertMaterial.fromMap({'color': color}),
      );

  void _drawLakes(three.Group root, List<WorldMapLake> lakes, Rect bounds) {
    for (final lake in lakes) {
      if (!lake.bounds.inflate(10).overlaps(bounds)) continue;
      var cached = _cachedLakeObjects[lake.id];
      if (cached == null) {
        cached = three.Group();
        final bank = _expandPolygon(lake.shoreline, 1.08);
        final bankMesh = _polygonMesh(
          bank,
          _waterMaterial('lake-bank', 0xff958467),
          height: 0.9,
        );
        if (bankMesh.geometry != null) _staticGeometryCache.add(bankMesh.geometry!);
        cached.add(bankMesh);

        final waterMesh = _polygonMesh(
          lake.shoreline,
          _waterMaterial('lake:${lake.id}', lake.waterColor & 0x00ffffff),
          height: 1.5,
        );
        if (waterMesh.geometry != null) _staticGeometryCache.add(waterMesh.geometry!);
        cached.add(waterMesh);

        final outline = _outlineMesh(bank, 0xffb5b89a, 4.0, 1.7);
        if (outline.geometry != null) _staticGeometryCache.add(outline.geometry!);
        cached.add(outline);

        _cachedLakeObjects[lake.id] = cached;
      }
      root.add(cached);
    }
  }

  List<WorldMapPoint> _expandPolygon(List<WorldMapPoint> points, double scale) {
    if (points.isEmpty) return points;
    final centerX =
        points.map((point) => point.x).reduce((a, b) => a + b) / points.length;
    final centerY =
        points.map((point) => point.y).reduce((a, b) => a + b) / points.length;
    return [
      for (final point in points)
        WorldMapPoint(
          centerX + (point.x - centerX) * scale,
          centerY + (point.y - centerY) * scale,
        ),
    ];
  }

  void _drawPonds(three.Group root, List<WorldMapPond> ponds, Rect bounds) {
    for (final pond in ponds) {
      if (!_pondBounds(pond).inflate(18).overlaps(bounds)) continue;
      final points = [
        for (var i = 0; i < 20; i++)
          WorldMapPoint(
            pond.center.x + math.cos(i * math.pi / 10) * pond.width / 2,
            pond.center.y + math.sin(i * math.pi / 10) * pond.height / 2,
          ),
      ];
      final bank = [
        for (var i = 0; i < 20; i++)
          WorldMapPoint(
            pond.center.x + math.cos(i * math.pi / 10) * (pond.width / 2 + 14),
            pond.center.y + math.sin(i * math.pi / 10) * (pond.height / 2 + 14),
          ),
      ];
      root.add(
        _polygonMesh(
          bank,
          _waterMaterial('pond-bank', 0xff918568),
          height: 0.7,
        ),
      );
      root.add(
        _polygonMesh(points, _waterMaterial('pond', 0xff4b9097), height: 1.2),
      );
    }
  }

  three.Material _infraMat(String key, int color) =>
      _infrastructureMaterials.putIfAbsent(
        key,
        () => three.MeshLambertMaterial.fromMap({'color': color}),
      );

  void _drawWindmill(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final stoneMat = _infraMat('windmill-stone', 0xff998f82);
    final woodMat = _infraMat('windmill-wood', 0xff664930);
    final roofMat = _infraMat('windmill-roof', 0xff48423d);
    final bladeMat = _infraMat('windmill-blade', 0xff4a3522);
    final sailMat = _infraMat('windmill-sail', 0xfff4eee0);

    final windmillGroup = three.Group()..position.setValues(x, 0, z);

    // Taş taban gövdesi
    final baseMesh = three.Mesh(_getCylinderGeometry(15 * s, 21 * s, 32 * s, 8), stoneMat)
      ..position.y = 16 * s;
    windmillGroup.add(baseMesh);

    // Ahşap orta kule
    final midMesh = three.Mesh(_getCylinderGeometry(12 * s, 15 * s, 18 * s, 8), woodMat)
      ..position.y = 41 * s;
    windmillGroup.add(midMesh);

    // Konik kiremit çatı
    final roofMesh = three.Mesh(_getConeGeometry(13.5 * s, 15 * s, 8), roofMat)
      ..position.y = 57.5 * s;
    windmillGroup.add(roofMesh);

    // Dönen 4 kanatlı rotor grubu
    final rotor = three.Group()..position.setValues(0, 48 * s, 13.5 * s);

    // Merkez göbek
    final hub = three.Mesh(_getCylinderGeometry(2.5 * s, 2.5 * s, 3.5 * s, 8), woodMat)
      ..rotation.x = math.pi / 2;
    rotor.add(hub);

    // 4 Kanat ve Yelken Kumaşları
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final arm = three.Mesh(_getBoxGeometry(2.4 * s, 42 * s, 1.2 * s), bladeMat)
        ..rotation.z = angle
        ..position.setValues(
          math.sin(angle) * 19 * s,
          math.cos(angle) * 19 * s,
          0,
        );
      rotor.add(arm);

      final sail = three.Mesh(_getBoxGeometry(7.5 * s, 32 * s, 0.4 * s), sailMat)
        ..rotation.z = angle
        ..position.setValues(
          math.sin(angle) * 20 * s + math.cos(angle) * 4 * s,
          math.cos(angle) * 20 * s - math.sin(angle) * 4 * s,
          0.3 * s,
        );
      rotor.add(sail);
    }

    windmillGroup.userData['rotor'] = rotor;
    if (!_animatedWindmillRotors.contains(rotor)) {
      _animatedWindmillRotors.add(rotor);
    }
    windmillGroup.add(rotor);
    root.add(windmillGroup);
  }

  void _drawGrainSiloPair(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final steelMat = _infraMat('silo-steel', 0xffc4ccd2);
    final roofMat = _infraMat('silo-roof', 0xff86949e);
    final baseMat = _infraMat('silo-base', 0xff6c7379);
    final pipeMat = _infraMat('silo-pipe', 0xff4c5359);

    final siloGroup = three.Group()..position.setValues(x, 0, z);

    for (final dx in [-13.0 * s, 13.0 * s]) {
      final base = three.Mesh(_getCylinderGeometry(11 * s, 11.5 * s, 4 * s, 12), baseMat)
        ..position.setValues(dx, 2 * s, 0);
      siloGroup.add(base);

      final body = three.Mesh(_getCylinderGeometry(10 * s, 10 * s, 38 * s, 12), steelMat)
        ..position.setValues(dx, 23 * s, 0);
      siloGroup.add(body);

      final roof = three.Mesh(_getConeGeometry(10.5 * s, 9 * s, 12), roofMat)
        ..position.setValues(dx, 46.5 * s, 0);
      siloGroup.add(roof);
    }

    final pipe = three.Mesh(_getBoxGeometry(26 * s, 2.5 * s, 2.5 * s), pipeMat)
      ..position.setValues(0, 44 * s, 0);
    siloGroup.add(pipe);

    root.add(siloGroup);
  }

  void _drawRedBarn(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final redWoodMat = _infraMat('barn-red', 0xffa02c24);
    final whiteTrimMat = _infraMat('barn-white', 0xfff6f4ec);
    final roofMat = _infraMat('barn-roof', 0xff353b40);
    final stoneFoundation = _infraMat('barn-stone', 0xff7e766c);

    final barnGroup = three.Group()..position.setValues(x, 0, z);

    // Taş temel
    final foundation = three.Mesh(_getBoxGeometry(40 * s, 4 * s, 50 * s), stoneFoundation)
      ..position.y = 2 * s;
    barnGroup.add(foundation);

    // Kırmızı ahşap ana gövde
    final mainBody = three.Mesh(_getBoxGeometry(38 * s, 24 * s, 48 * s), redWoodMat)
      ..position.y = 16 * s;
    barnGroup.add(mainBody);

    // Beyaz kapı detayı
    final door = three.Mesh(_getBoxGeometry(16 * s, 18 * s, 49 * s), whiteTrimMat)
      ..position.y = 13 * s;
    barnGroup.add(door);

    // Kırma ambar çatısı (Gambrel Roof)
    final roofLower = three.Mesh(_getBoxGeometry(41 * s, 9 * s, 51 * s), roofMat)
      ..position.y = 31 * s;
    barnGroup.add(roofLower);

    final roofPeak = three.Mesh(_getBoxGeometry(26 * s, 8 * s, 51 * s), roofMat)
      ..position.y = 38 * s;
    barnGroup.add(roofPeak);

    // Havalandırma kulesi (Cupola)
    final cupola = three.Mesh(_getBoxGeometry(8 * s, 7 * s, 8 * s), whiteTrimMat)
      ..position.y = 44.5 * s;
    barnGroup.add(cupola);

    final cupolaRoof = three.Mesh(_getConeGeometry(5.5 * s, 6 * s, 4), redWoodMat)
      ..position.y = 50 * s
      ..rotation.y = math.pi / 4;
    barnGroup.add(cupolaRoof);

    root.add(barnGroup);
  }

  void _drawTownHall(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final stoneMat = _infraMat('townhall-stone', 0xffd5c49d);
    final roofMat = _infraMat('townhall-roof', 0xff9f4734);
    final copperMat = _infraMat('townhall-copper', 0xff487968);
    final clockMat = _infraMat('townhall-clock', 0xfffcfaf2);
    final goldTrim = _infraMat('townhall-gold', 0xffd8a735);

    final hallGroup = three.Group()..position.setValues(x, 0, z);

    // 2 katlı ana taş bina
    final baseBuilding = three.Mesh(_getBoxGeometry(54 * s, 26 * s, 40 * s), stoneMat)
      ..position.y = 13 * s;
    hallGroup.add(baseBuilding);

    // Ana çatı
    final roof = three.Mesh(_getBoxGeometry(57 * s, 10 * s, 43 * s), roofMat)
      ..position.y = 30 * s;
    hallGroup.add(roof);

    // Ön giriş revakı
    final portico = three.Mesh(_getBoxGeometry(24 * s, 16 * s, 8 * s), stoneMat)
      ..position.setValues(0, 8 * s, 22 * s);
    hallGroup.add(portico);

    // Yükselen Saat Kulesi
    final tower = three.Mesh(_getBoxGeometry(16 * s, 48 * s, 16 * s), stoneMat)
      ..position.setValues(0, 44 * s, 0);
    hallGroup.add(tower);

    // Kule bakır piramit çatısı
    final spire = three.Mesh(_getConeGeometry(13 * s, 22 * s, 4), copperMat)
      ..position.setValues(0, 78 * s, 0)
      ..rotation.y = math.pi / 4;
    hallGroup.add(spire);

    // Saat kadranları (Ön ve arka)
    for (final dz in [-8.2 * s, 8.2 * s]) {
      final clockRing = three.Mesh(_getCylinderGeometry(4.2 * s, 4.2 * s, 0.8 * s, 12), goldTrim)
        ..position.setValues(0, 58 * s, dz)
        ..rotation.x = math.pi / 2;
      hallGroup.add(clockRing);

      final clockFace = three.Mesh(_getCylinderGeometry(3.6 * s, 3.6 * s, 0.9 * s, 12), clockMat)
        ..position.setValues(0, 58 * s, dz)
        ..rotation.x = math.pi / 2;
      hallGroup.add(clockFace);
    }

    root.add(hallGroup);
  }

  void _drawMarketStalls(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final woodMat = _infraMat('market-wood', 0xff7b5636);
    final tentRed = _infraMat('market-tent-red', 0xffbe372b);
    final tentBlue = _infraMat('market-tent-blue', 0xff3b7396);
    final tentGold = _infraMat('market-tent-gold', 0xffd99d32);

    final stalls = [
      (dx: -16.0 * s, dz: -12.0 * s, mat: tentRed),
      (dx: 16.0 * s, dz: -10.0 * s, mat: tentBlue),
      (dx: 0.0 * s, dz: 16.0 * s, mat: tentGold),
    ];

    for (final stall in stalls) {
      final group = three.Group()..position.setValues(x + stall.dx, 0, z + stall.dz);

      final table = three.Mesh(_getBoxGeometry(16 * s, 8 * s, 10 * s), woodMat)
        ..position.y = 4 * s;
      group.add(table);

      final canopy = three.Mesh(_getConeGeometry(11 * s, 7 * s, 4), stall.mat)
        ..position.y = 15 * s
        ..rotation.y = math.pi / 4;
      group.add(canopy);

      root.add(group);
    }
  }

  void _drawSettlements(three.Group root, Rect bounds, [List<WorldMapRoad> roads = const []]) {
    if (!widget.showInfrastructure) return;
    final houses = <({double x, double z, double scale, int variation})>[];

    for (final settlement in widget.world.settlements) {
      final spread = switch (settlement.kind) {
        WorldMapSettlementKind.city => 190.0,
        WorldMapSettlementKind.town => 125.0,
        WorldMapSettlementKind.village => 72.0,
        WorldMapSettlementKind.hamlet => 42.0,
      };
      final landmarkSize = switch (settlement.kind) {
        WorldMapSettlementKind.city => 230.0,
        WorldMapSettlementKind.town => 165.0,
        WorldMapSettlementKind.village => 118.0,
        WorldMapSettlementKind.hamlet => 82.0,
      };
      if (!bounds
          .inflate(spread + landmarkSize / 2)
          .contains(Offset(settlement.position.x, settlement.position.y))) {
        continue;
      }

      // Şehir ve kasaba merkezinde Saat Kulesi ve Pazar Tezgâhları
      if (settlement.kind == WorldMapSettlementKind.city ||
          settlement.kind == WorldMapSettlementKind.town) {
        final hallScale = settlement.kind == WorldMapSettlementKind.city ? 1.2 : 0.95;
        _drawTownHall(root, settlement.position.x, settlement.position.y, scale: hallScale);
        _drawMarketStalls(root, settlement.position.x + 36 * hallScale, settlement.position.y + 18 * hallScale, scale: hallScale * 0.9);
      } else if (settlement.kind == WorldMapSettlementKind.village) {
        _drawMarketStalls(root, settlement.position.x, settlement.position.y, scale: 0.9);
      }

      final count = switch (settlement.kind) {
        WorldMapSettlementKind.city => 10,
        WorldMapSettlementKind.town => 6,
        WorldMapSettlementKind.village => 4,
        WorldMapSettlementKind.hamlet => 2,
      };
      final houseScale = switch (settlement.kind) {
        WorldMapSettlementKind.city => 1.2,
        WorldMapSettlementKind.town => 1.0,
        WorldMapSettlementKind.village => 0.86,
        WorldMapSettlementKind.hamlet => 0.75,
      };
      for (var i = 0; i < count; i++) {
        final angle = (i * 2.399963) + (settlement.position.x * 0.001);
        final distance = spread * (0.38 + 0.62 * ((i % 3) / 2));
        final x = settlement.position.x + math.cos(angle) * distance;
        final z = settlement.position.y + math.sin(angle) * distance;

        // Evlerin yolların üstüne çıkmasını önle:
        final houseClearance = 20.0 * houseScale;
        final roadCollision = roads.any((road) {
          if (!_pointsOverlapBounds(road.points, Rect.fromCircle(center: Offset(x, z), radius: 40), road.width)) {
            return false;
          }
          final limit = houseClearance + road.width / 2;
          final limitSq = limit * limit;
          for (var r = 0; r < road.points.length - 1; r++) {
            if (_distanceToSegmentSq(
                  x,
                  z,
                  road.points[r].x,
                  road.points[r].y,
                  road.points[r + 1].x,
                  road.points[r + 1].y,
                ) <=
                limitSq) {
              return true;
            }
          }
          return false;
        });
        if (!roadCollision) {
          houses.add((x: x, z: z, scale: houseScale, variation: i));
        }
      }
    }
    if (houses.isEmpty) return;

    final wallGeometry = three.BoxGeometry(1, 1, 0.82);
    final roofGeometry = three.ConeGeometry(0.86, 1, 4)..rotateY(math.pi / 4);
    final wallMaterial = _infraMat('house-walls', 0xffffffff);
    final roofMaterial = _infraMat('house-roofs', 0xffffffff);
    final walls = three.InstancedMesh(wallGeometry, wallMaterial, houses.length);
    final roofs = three.InstancedMesh(roofGeometry, roofMaterial, houses.length);

    for (var index = 0; index < houses.length; index++) {
      final house = houses[index];
      final width = 27 * house.scale;
      walls.setMatrixAt(
        index,
        three.Matrix4.identity().compose(
          three.Vector3(house.x, 11 * house.scale, house.z),
          three.Quaternion.identity(),
          three.Vector3(width, 22 * house.scale, width),
        ),
      );
      roofs.setMatrixAt(
        index,
        three.Matrix4.identity().compose(
          three.Vector3(house.x, 30 * house.scale, house.z),
          three.Quaternion.identity(),
          three.Vector3(width, 18 * house.scale, width),
        ),
      );
      walls.setColorAt(
        index,
        three.Color.fromHex32(house.variation.isEven ? 0xffd3bd91 : 0xffc9b58b),
      );
      roofs.setColorAt(
        index,
        three.Color.fromHex32(
          house.variation % 3 == 0
              ? 0xffa9543b
              : (house.variation % 3 == 1 ? 0xff4c555e : 0xffcbab63),
        ),
      );
    }
    walls.instanceMatrix!.needsUpdate = true;
    roofs.instanceMatrix!.needsUpdate = true;
    walls.instanceColor?.needsUpdate = true;
    roofs.instanceColor?.needsUpdate = true;
    root.add(walls);
    root.add(roofs);
  }

  void _drawTrees(three.Group root, List<WorldMapTree> trees) {
    final canopyGeometry = _treeCanopyGeometry;
    final trunkGeometry = _treeTrunkGeometry;
    if (trees.isEmpty ||
        _pose.zoom < 0.28 ||
        canopyGeometry == null ||
        trunkGeometry == null) {
      return;
    }
    final canopyMaterial = _infrastructureMaterials.putIfAbsent(
      'tree-canopy',
      () => three.MeshLambertMaterial.fromMap({'color': 0xff4f7847}),
    );
    final trunkMaterial = _infrastructureMaterials.putIfAbsent(
      'tree-trunk',
      () => three.MeshLambertMaterial.fromMap({'color': 0xff715333}),
    );
    final canopy = three.InstancedMesh(
      canopyGeometry,
      canopyMaterial,
      trees.length,
    );
    final trunk = three.InstancedMesh(
      trunkGeometry,
      trunkMaterial,
      trees.length,
    );
    for (var i = 0; i < trees.length; i++) {
      final tree = trees[i];
      final radius = tree.radius.clamp(5.0, 28.0).toDouble();
      final canopyMatrix = three.Matrix4.identity().compose(
        three.Vector3(tree.center.x, radius * 1.3, tree.center.y),
        three.Quaternion.identity(),
        three.Vector3(radius * 1.05, radius * 1.35, radius * 1.05),
      );
      canopy.setMatrixAt(i, canopyMatrix);
      canopy.setColorAt(i, three.Color.fromHex32(tree.tint & 0x00ffffff));
      final trunkMatrix = three.Matrix4.identity().compose(
        three.Vector3(tree.center.x, radius * 0.35, tree.center.y),
        three.Quaternion.identity(),
        three.Vector3(radius * 0.17, radius * 0.7, radius * 0.17),
      );
      trunk.setMatrixAt(i, trunkMatrix);
    }
    canopy.instanceMatrix!.needsUpdate = true;
    canopy.instanceColor?.needsUpdate = true;
    trunk.instanceMatrix!.needsUpdate = true;
    root.add(trunk);
    root.add(canopy);
  }

  void _drawMountains(three.Group root, List<WorldMapMountain> mountains) {
    final geometry = _mountainGeometry;
    if (mountains.isEmpty || geometry == null || _pose.zoom < 0.24) return;
    final material = _infrastructureMaterials.putIfAbsent(
      'mountain',
      () => three.MeshLambertMaterial.fromMap({'color': 0xff8b8063}),
    );
    final hills = three.InstancedMesh(geometry, material, mountains.length);
    for (var index = 0; index < mountains.length; index++) {
      final mountain = mountains[index];
      final rotation = three.Quaternion.identity()
        ..setFromAxisAngle(three.Vector3(0, 1, 0), -mountain.ridgeAngle);
      final matrix = three.Matrix4.identity().compose(
        three.Vector3(mountain.center.x, 24, mountain.center.y),
        rotation,
        three.Vector3(mountain.width * 0.43, 55, mountain.height * 0.42),
      );
      hills.setMatrixAt(index, matrix);
    }
    hills.instanceMatrix!.needsUpdate = true;
    root.add(hills);
  }

  Rect _mountainBounds(WorldMapMountain mountain) => Rect.fromCenter(
    center: Offset(mountain.center.x, mountain.center.y),
    width: mountain.width * 0.86,
    height: mountain.height * 0.84,
  );

  void _drawWaterWell(three.Group root, double x, double z, {double scale = 1.0}) {
    final s = scale;
    final stoneMat = _infraMat('well-stone', 0xff8c8478);
    final woodMat = _infraMat('well-wood', 0xff664930);
    final waterMat = _infraMat('well-water', 0xff3b7d87);
    final roofMat = _infraMat('well-roof', 0xff8e412e);

    final group = three.Group()..position.setValues(x, 0, z);

    final basin = three.Mesh(_getCylinderGeometry(10 * s, 11 * s, 8 * s, 10), stoneMat)
      ..position.y = 4 * s;
    group.add(basin);

    final water = three.Mesh(_getCylinderGeometry(8.5 * s, 8.5 * s, 1 * s, 10), waterMat)
      ..position.y = 6.5 * s;
    group.add(water);

    for (final dx in [-8.0 * s, 8.0 * s]) {
      final post = three.Mesh(_getBoxGeometry(2 * s, 20 * s, 2 * s), woodMat)
        ..position.setValues(dx, 14 * s, 0);
      group.add(post);
    }

    final roof = three.Mesh(_getBoxGeometry(22 * s, 6 * s, 18 * s), roofMat)
      ..position.y = 26 * s;
    group.add(roof);

    root.add(group);
  }

  void _drawPointOfInterest(
    three.Group root,
    List<WorldMapChunk> chunks,
    Rect bounds,
  ) {
    for (final chunk in chunks) {
      for (final poi in chunk.pointsOfInterest) {
        if (!bounds
            .inflate(70)
            .contains(Offset(poi.position.x, poi.position.y))) {
          continue;
        }

        var cached = _cachedPoiObjects[poi.id];
        if (cached == null) {
          cached = three.Group();
          switch (poi.type) {
            case WorldPointOfInterestType.mill:
              _drawWindmill(cached, poi.position.x, poi.position.y, scale: 1.15);
              break;
            case WorldPointOfInterestType.timberYard:
              _drawGrainSiloPair(cached, poi.position.x - 22, poi.position.y, scale: 1.05);
              _drawRedBarn(cached, poi.position.x + 26, poi.position.y, scale: 0.95);
              break;
            case WorldPointOfInterestType.village:
              _drawTownHall(cached, poi.position.x, poi.position.y, scale: 0.95);
              _drawMarketStalls(cached, poi.position.x, poi.position.y + 36, scale: 0.85);
              break;
            case WorldPointOfInterestType.water:
              _drawWaterWell(cached, poi.position.x, poi.position.y, scale: 1.1);
              break;
          }
          _cachedPoiObjects[poi.id] = cached;
        }

        final rotor = cached.userData['rotor'] as three.Object3D?;
        if (rotor != null && !_animatedWindmillRotors.contains(rotor)) {
          _animatedWindmillRotors.add(rotor);
        }
        root.add(cached);
      }
    }
  }

  void _drawBridges(three.Group root, Rect bounds) {
    if (!widget.showRoutes) return;
    for (final bridge in widget.world.bridgesInBounds(bounds)) {
      final sinAngle = math.sin(bridge.angle).abs();
      final cosAngle = math.cos(bridge.angle).abs();
      final halfX = (cosAngle * bridge.length + sinAngle * bridge.width) / 2;
      final halfY = (sinAngle * bridge.length + cosAngle * bridge.width) / 2;
      final bridgeBounds = Rect.fromCenter(
        center: Offset(bridge.position.x, bridge.position.y),
        width: halfX * 2,
        height: halfY * 2,
      );
      if (!bridgeBounds.inflate(8).overlaps(bounds)) {
        continue;
      }
      final deck =
          three.Mesh(
              three.BoxGeometry(bridge.length, 11, bridge.width),
              _transient(
                three.MeshLambertMaterial.fromMap({'color': 0xff9a7951}),
              ),
            )
            ..position.setValues(bridge.position.x, 8, bridge.position.y)
            ..rotation.y = -bridge.angle;
      root.add(deck);
    }
  }


  three.Mesh _polygonMesh(
    List<WorldMapPoint> points,
    three.Material material, {
    double height = 0,
    bool normalizeUvs = false,
  }) {
    if (points.length == 4) {
      final p0 = points[0];
      final p1 = points[1];
      final p2 = points[2];
      final p3 = points[3];
      final geometry = three.BufferGeometry();
      final vertices = <double>[
        p0.x, height, p0.y,
        p1.x, height, p1.y,
        p2.x, height, p2.y,
        p0.x, height, p0.y,
        p2.x, height, p2.y,
        p3.x, height, p3.y,
      ];
      final uvs = <double>[
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
      ];
      geometry.setAttribute(
        three.Attribute.position,
        three.Float32BufferAttribute.fromList(vertices, 3),
      );
      geometry.setAttribute(
        three.Attribute.uv,
        three.Float32BufferAttribute.fromList(uvs, 2),
      );
      geometry.computeVertexNormals();
      return three.Mesh(geometry, material);
    }

    final shape = three.Shape();
    if (points.isNotEmpty) {
      shape.moveTo(points.first.x, points.first.y);
      for (final point in points.skip(1)) {
        shape.lineTo(point.x, point.y);
      }
      shape.closePath();
    }
    final geometry = three.ShapeGeometry([shape], curveSegments: 1);
    if (normalizeUvs && points.isNotEmpty) _normalizeUvs(geometry, points);
    geometry.rotateX(math.pi / 2);
    return three.Mesh(geometry, material)..position.y = height;
  }

  void _normalizeUvs(
    three.BufferGeometry geometry,
    List<WorldMapPoint> points,
  ) {
    final uv = geometry.getAttribute(three.Attribute.uv);
    if (uv is! three.BufferAttribute) return;
    final minX = points.map((point) => point.x).reduce(math.min);
    final maxX = points.map((point) => point.x).reduce(math.max);
    final minY = points.map((point) => point.y).reduce(math.min);
    final maxY = points.map((point) => point.y).reduce(math.max);
    final width = math.max(1.0, maxX - minX);
    final height = math.max(1.0, maxY - minY);
    for (var index = 0; index < uv.count; index++) {
      final x = uv.getX(index)?.toDouble() ?? 0;
      final y = uv.getY(index)?.toDouble() ?? 0;
      uv.setXY(index, (x - minX) / width, (y - minY) / height);
    }
    uv.needsUpdate = true;
  }

  three.LineLoop _outlineMesh(
    List<WorldMapPoint> points,
    int color,
    double width,
    double height,
  ) {
    final geometry = three.BufferGeometry();
    geometry.setFromPoints([
      for (final point in points) three.Vector3(point.x, height, point.y),
    ]);
    return three.LineLoop(
      geometry,
      _transient(
        three.LineBasicMaterial.fromMap({'color': color, 'linewidth': width}),
      ),
    );
  }

  bool _pointsOverlapBounds(
    List<WorldMapPoint> points,
    Rect bounds,
    double pad,
  ) {
    if (points.isEmpty) return false;
    var minX = points.first.x;
    var maxX = points.first.x;
    var minY = points.first.y;
    var maxY = points.first.y;
    for (final point in points.skip(1)) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(pad).overlaps(bounds);
  }

  void _disposeGroupGeometry(three.Object3D object) {
    object.traverse((child) {
      if (child is three.Mesh) _disposeGeometryIfOwned(child.geometry);
      if (child is three.Line) _disposeGeometryIfOwned(child.geometry);
    });
  }

  void _disposeGeometryIfOwned(three.BufferGeometry? geometry) {
    if (geometry == null ||
        identical(geometry, _treeCanopyGeometry) ||
        identical(geometry, _treeTrunkGeometry) ||
        identical(geometry, _mountainGeometry) ||
        _staticGeometryCache.contains(geometry) ||
        _sharedGeometryCache.containsValue(geometry)) {
      return;
    }
    geometry.dispose();
  }

  T _transient<T extends three.Material>(T material) {
    _transientMaterials.add(material);
    return material;
  }

  void _disposeTransientMaterials() {
    for (final material in _transientMaterials) {
      material.dispose();
    }
    _transientMaterials.clear();
  }
}
