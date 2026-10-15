import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Loads and draws the four painted map landmarks from the 2×2 sprite atlas.
class FarmMapLandmarkAtlas {
  static const String assetPath =
      'assets/images/map/farm-world-map-landmarks-v1.png';

  ui.Image? _image;
  bool _disposed = false;

  bool get isReady => _image != null;

  Future<bool> load() async {
    final current = _image;
    if (current != null) return true;
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      final frame = await codec.getNextFrame();
      if (_disposed) {
        frame.image.dispose();
        return false;
      }
      _image = frame.image;
      return true;
    } finally {
      codec.dispose();
    }
  }

  /// Draws an atlas entry at a stable screen-space size around a world point.
  /// Index order: village, mill, market, grain store.
  void drawAt({
    required ui.Canvas canvas,
    required int index,
    required ui.Offset worldCenter,
    required double zoom,
    required double screenWidth,
    required double screenHeight,
  }) {
    final image = _image;
    if (image == null || index < 0 || index > 3 || zoom <= 0) return;

    final cellWidth = image.width / 2;
    final cellHeight = image.height / 2;
    final source = ui.Rect.fromLTWH(
      (index % 2) * cellWidth,
      (index ~/ 2) * cellHeight,
      cellWidth,
      cellHeight,
    );

    canvas.save();
    canvas.translate(worldCenter.dx, worldCenter.dy);
    canvas.scale(1 / zoom);
    canvas.drawImageRect(
      image,
      source,
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: screenWidth,
        height: screenHeight,
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    canvas.restore();
  }

  void dispose() {
    _disposed = true;
    _image?.dispose();
    _image = null;
  }
}
