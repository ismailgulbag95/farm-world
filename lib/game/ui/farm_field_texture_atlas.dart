import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/opening_crop_catalog.dart';

/// Crop field states represented by the reusable 2×2 atlas.
enum FarmFieldTextureState {
  plowed,
  fertilized,
  growing,
  harvestReady,
  harvested,
}

/// Optional painted textures for world-map fields.
///
/// The state atlas may be absent while assets are being generated. In that
/// case the map keeps its vector soil and furrow rendering. Mature wheat and
/// maize use the existing pilot crop sheets; other crops deliberately use the
/// generic growing texture until their harvest-ready art is approved.
class FarmFieldTextureAtlas {
  static const String stateAtlasPath =
      'assets/images/map/farm-field-states-v1.png';
  static const String wheatReadyPath =
      'assets/visual-concepts/pilot/crop-wheat-mature-v1.png';
  static const String maizeReadyPath =
      'assets/visual-concepts/pilot/crop-maize-mature-v1.png';

  static ui.Image? _sharedStateAtlas;
  static ui.Image? _sharedWheatReady;
  static ui.Image? _sharedMaizeReady;
  static Future<bool>? _pendingLoad;

  ui.Image? _stateAtlas;
  ui.Image? _wheatReady;
  ui.Image? _maizeReady;
  bool _disposed = false;

  bool get hasAnyTexture =>
      _stateAtlas != null ||
      _wheatReady != null ||
      _maizeReady != null ||
      _sharedStateAtlas != null ||
      _sharedWheatReady != null ||
      _sharedMaizeReady != null;

  static Future<bool> preload() async {
    if (_sharedStateAtlas != null || _sharedWheatReady != null || _sharedMaizeReady != null) {
      return true;
    }
    if (_pendingLoad != null) return _pendingLoad!;
    _pendingLoad = () async {
      try {
        final loaded = await Future.wait([
          _staticLoadImage(stateAtlasPath),
          _staticLoadImage(wheatReadyPath),
          _staticLoadImage(maizeReadyPath),
        ]);
        _sharedStateAtlas = loaded[0];
        _sharedWheatReady = loaded[1];
        _sharedMaizeReady = loaded[2];
        return _sharedStateAtlas != null || _sharedWheatReady != null || _sharedMaizeReady != null;
      } catch (_) {
        return false;
      } finally {
        _pendingLoad = null;
      }
    }();
    return _pendingLoad!;
  }

  static Future<ui.Image?> _staticLoadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } on Object {
      return null;
    }
  }

  Future<bool> load() async {
    if (_sharedStateAtlas != null || _sharedWheatReady != null || _sharedMaizeReady != null) {
      _stateAtlas = _sharedStateAtlas;
      _wheatReady = _sharedWheatReady;
      _maizeReady = _sharedMaizeReady;
      return true;
    }
    if (hasAnyTexture) return true;
    final success = await preload();
    if (_disposed) return false;
    _stateAtlas = _sharedStateAtlas;
    _wheatReady = _sharedWheatReady;
    _maizeReady = _sharedMaizeReady;
    return success;
  }


  /// Paints a field texture inside its irregular parcel polygon.
  ///
  /// Returns false when the requested texture is unavailable so callers can
  /// retain a hand-drawn furrow fallback.
  bool drawField({
    required ui.Canvas canvas,
    required ui.Path clipPath,
    required ui.Rect bounds,
    required FarmFieldTextureState state,
    String? cropId,
    double opacity = 1,
  }) {
    final readyCrop =
        state == FarmFieldTextureState.harvestReady && cropId != null
        ? (cropId == OpeningCropCatalog.wheatId
              ? _wheatReady
              : cropId == OpeningCropCatalog.maizeId
              ? _maizeReady
              : null)
        : null;
    final image = readyCrop ?? _stateAtlas;
    if (image == null || bounds.isEmpty) return false;

    final useReadyCrop = readyCrop != null;
    final atlasIndex = switch (state) {
      FarmFieldTextureState.plowed => 0,
      FarmFieldTextureState.fertilized => 1,
      FarmFieldTextureState.growing => 2,
      FarmFieldTextureState.harvestReady => 2,
      FarmFieldTextureState.harvested => 3,
    };
    final source = useReadyCrop
        ? ui.Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          )
        : ui.Rect.fromLTWH(
            (atlasIndex % 2) * image.width / 2,
            (atlasIndex ~/ 2) * image.height / 2,
            image.width / 2,
            image.height / 2,
          );

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawImageRect(
      image,
      source,
      bounds,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..color = ui.Color.fromARGB(
          (255 * opacity.clamp(0, 1)).round(),
          255,
          255,
          255,
        ),
    );
    canvas.restore();
    return true;
  }

  void dispose() {
    _disposed = true;
    _stateAtlas?.dispose();
    _wheatReady?.dispose();
    _maizeReady?.dispose();
    _stateAtlas = null;
    _wheatReady = null;
    _maizeReady = null;
  }
}
