import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../domain/crop_plot.dart';
import '../domain/debug_action_controller.dart';
import '../domain/opening_crop_catalog.dart';
import '../domain/opening_session.dart';
import '../farm_world_artwork.dart';
import '../opening_mowing_world.dart';
import 'floating_text.dart';

/// Renders a crop plot on the management map, supporting purchasing,
/// growth visualization, and direct interactive tapping.
class InteractiveCropPlotComponent extends PositionComponent with TapCallbacks {
  InteractiveCropPlotComponent({
    required this.plotId,
    required Vector2 position,
    required Vector2 size,
    required this.session,
    required this.selectedMapItem,
  }) : super(position: position, size: size, priority: 4);

  final int plotId;
  final OpeningSession session;
  final ValueNotifier<ManagementMapSelection> selectedMapItem;
  FarmWorldArtwork? artwork;

  final Paint _soilPaint = Paint()..color = const Color(0xFF8B6340);
  final Paint _lockedSoilPaint = Paint()..color = const Color(0xFF5D4037);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFC2A16D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _lockedBorderPaint = Paint()
    ..color = const Color(0xFF8D6E63)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  CropPlotState get plot => session.plots.firstWhere(
    (p) => p.id == plotId,
    orElse: () => session.plots.first,
  );

  @override
  void onTapDown(TapDownEvent event) {
    if (session.stage != OpeningStage.management) return;

    unawaited(
      DebugActionController.instance.runPlayerAction<void>(() {
        if (!plot.isOwned) {
          if (session.canBuyPlot(plotId) && session.buyPlot(plotId)) {
            parent?.add(
              FloatingTextComponent(
                position: position + Vector2(size.x / 2, size.y / 2),
                text: '🌾 YENİ TARLA AÇILDI!',
                color: const Color(0xFF81C784),
              ),
            );
          }
          return;
        }

        selectedMapItem.value = ManagementMapSelection.starterPlot;

        final now = DateTime.now();
        final anchor = session.firstSuccessfulPlantingAt;
        if (anchor != null && plot.hasActiveCrop) {
          final snapshot = plot.cropSnapshotAt(now, anchor);
          if (snapshot != null && snapshot.isHarvestable) {
            if (session.harvestCropOnPlot(plotId, now)) {
              parent?.add(
                FloatingTextComponent(
                  position: position + Vector2(size.x / 2, size.y / 2),
                  text: '+${snapshot.harvestYield.round()} ÇK',
                  color: const Color(0xFFFFD54F),
                ),
              );
            }
          }
        }
      }),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (session.stage != OpeningStage.management) return;

    final currentPlot = plot;
    final isOwned = currentPlot.isOwned;

    final localBounds = Rect.fromLTWH(0, 0, size.x, size.y);
    final field = RRect.fromRectAndRadius(
      localBounds,
      const Radius.circular(12),
    );

    // Drop shadow
    canvas.drawRRect(
      field.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x440D3118),
    );

    // Soil background
    canvas.drawRRect(field, isOwned ? _soilPaint : _lockedSoilPaint);
    canvas.drawRRect(field, isOwned ? _borderPaint : _lockedBorderPaint);

    if (!isOwned) {
      // Locked plot overlay
      final tp = TextPainter(
        text: TextSpan(
          text: '🔒 ${currentPlot.name}\n${currentPlot.purchaseCostCredits} ÇK',
          style: const TextStyle(
            color: Color(0xFFFFECB3),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x - 10);

      tp.paint(
        canvas,
        Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2),
      );
      return;
    }

    // Render crop stages if planted
    final anchor = session.firstSuccessfulPlantingAt;
    if (anchor != null && currentPlot.hasActiveCrop) {
      final snapshot = currentPlot.cropSnapshotAt(DateTime.now(), anchor);
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
                : (snapshot.crop.id == OpeningSession.starterMaizeId
                      ? art.maizeField
                      : art.wheatField),
        };

        canvas.drawImageRect(
          cropImage,
          Rect.fromLTWH(
            0,
            0,
            cropImage.width.toDouble(),
            cropImage.height.toDouble(),
          ),
          Rect.fromLTWH(8, 8, size.x - 16, size.y - 16),
          Paint(),
        );

        if (snapshot.isHarvestable) {
          final harvestBadge = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.x / 2, 14),
              width: 58,
              height: 18,
            ),
            const Radius.circular(8),
          );
          canvas.drawRRect(
            harvestBadge,
            Paint()..color = const Color(0xFF2E7D32),
          );
          final htp = TextPainter(
            text: const TextSpan(
              text: 'HASAT!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          htp.paint(
            canvas,
            Offset((size.x - htp.width) / 2, 14 - htp.height / 2),
          );
        }
      }
    }
  }
}
