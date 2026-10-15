import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/crop_plot.dart';
import '../domain/farm_equipment.dart';
import '../domain/farm_building.dart';
import '../domain/logistics_fleet.dart';
import '../domain/farm_item_catalog.dart';
import '../domain/opening_session.dart';
import '../domain/opening_crop_catalog.dart';
import '../domain/procedural_farm_world.dart';
import '../domain/tech_tree.dart';
import 'farm_management_sheet.dart';
import 'farm_operations_sheet.dart';
import 'market_trade_sheet.dart';
import 'tech_tree_overlay.dart';
import 'story_comic_screen.dart';
import '../domain/audio_controller.dart';
import '../domain/delivery_contracts.dart';
import 'farm_companion_hud.dart';

const Color _mapInk = Color(0xFF18392A);
const Color _mapGold = Color(0xFFFFC84F);

String _itemName(String itemId) => FarmItemCatalog.nameFor(itemId);

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({
    super.key,
    required this.session,
    required this.onSessionChanged,
  });

  final OpeningSession session;
  final VoidCallback onSessionChanged;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with SingleTickerProviderStateMixin {
  late final ProceduralFarmWorld _world = ProceduralFarmWorld(
    seed: widget.session.state.worldSeed,
    generationVersion: widget.session.state.worldGenerationVersion,
  );

  Offset _cameraCenter = const Offset(-150, -120);
  double _zoom = 0.64;
  Size _viewportSize = Size.zero;
  String? _selectedParcelId;
  int? _selectedFarmPlotId;
  String? _selectedFleetVehicleId;
  String? _routeStartParcelId;
  int? _salesRouteStartPlotId;
  bool _routeMode = false;
  bool _salesRouteMode = false;
  bool _measureMode = false;
  bool _constructionPlacementMode = false;
  WorldMapPoint? _measureStart;
  WorldMapPoint? _measureEnd;
  bool _showParcels = true;
  bool _showRoutes = true;
  bool _showInfrastructure = true;
  bool _showFertility = false;
  int _mapRevision = 0;
  late final Timer _farmTicker;
  late final AnimationController _fieldMachineController;
  final Map<int, String> _selectedCropByPlot = {};
  int _farmTickCount = 0;

  static const double _minZoom = 0.10;
  static const double _maxZoom = 1.85;

  @override
  void initState() {
    super.initState();
    _selectedFarmPlotId = widget.session.starterPlotId;
    _fieldMachineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    final resumedJobs = widget.session.advanceFarmOperations(DateTime.now());
    final resumedTutorial = widget.session.advanceFarmTutorial(DateTime.now());
    final resumedBuildingBills = widget.session.advanceBuildingOperatingCosts(
      DateTime.now(),
    );
    if (resumedJobs || resumedTutorial || resumedBuildingBills) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSessionChanged();
      });
    }
    _farmTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final earned = widget.session.advanceLogistics(1);
      final processingChanged = widget.session.advanceProcessing(1);
      final livestockChanged = widget.session.advanceLivestock(1);
      final completedJob = widget.session.advanceFarmOperations(DateTime.now());
      final tutorialChanged = widget.session.advanceFarmTutorial(
        DateTime.now(),
      );
      final buildingBillsChanged = widget.session.advanceBuildingOperatingCosts(
        DateTime.now(),
      );
      _farmTickCount++;
      if (!mounted) return;
      if (earned > 0 ||
          processingChanged ||
          livestockChanged ||
          completedJob ||
          tutorialChanged ||
          buildingBillsChanged) {
        widget.onSessionChanged();
      }
      if (_farmTickCount % 2 == 0 ||
          processingChanged ||
          livestockChanged ||
          completedJob ||
          tutorialChanged ||
          buildingBillsChanged) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _farmTicker.cancel();
    _fieldMachineController.dispose();
    super.dispose();
  }

  void _openStoryComic() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => StoryComicScreen(
          onComplete: () {
            Navigator.of(context).pop();
            if (widget.session.tutorialStep == FarmTutorialStep.story) {
              widget.session.setFarmTutorialStep(FarmTutorialStep.prepare);
              widget.onSessionChanged();
              final starter = widget.session.plotById(
                widget.session.starterPlotId,
              );
              setState(() {
                if (starter != null) {
                  _selectedFarmPlotId = starter.id;
                  _cameraCenter = Offset(starter.mapX, starter.mapY);
                  _zoom = 0.9;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Offset _screenToWorld(Offset screenPoint) {
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    return _cameraCenter + (screenPoint - center) / _zoom;
  }

  Offset _clampCameraCenter(Offset center, double zoom) {
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) return center;
    final halfVisibleWidth = (_viewportSize.width / 2) / zoom;
    final halfVisibleHeight = (_viewportSize.height / 2) / zoom;

    final bounds = ProceduralFarmWorld.worldBounds;
    final minX = bounds.left + halfVisibleWidth;
    final maxX = bounds.right - halfVisibleWidth;
    final minY = bounds.top + halfVisibleHeight;
    final maxY = bounds.bottom - halfVisibleHeight;

    final double clampedX = minX > maxX
        ? bounds.center.dx
        : center.dx.clamp(minX, maxX);
    final double clampedY = minY > maxY
        ? bounds.center.dy
        : center.dy.clamp(minY, maxY);

    return Offset(clampedX, clampedY);
  }

  WorldMapParcel? _parcelAt(WorldMapPoint point) {
    final chunkX = (point.x / farmWorldChunkSize).floor();
    final chunkY = (point.y / farmWorldChunkSize).floor();
    WorldMapParcel? closest;
    var closestDistance = double.infinity;
    for (var y = chunkY - 1; y <= chunkY + 1; y++) {
      for (var x = chunkX - 1; x <= chunkX + 1; x++) {
        for (final parcel in _world.chunkAt(x, y).parcels) {
          if (!parcel.contains(point, padding: 14 / _zoom)) continue;
          final distance = parcel.center.distanceTo(point);
          if (distance < closestDistance) {
            closest = parcel;
            closestDistance = distance;
          }
        }
      }
    }
    return closest;
  }

  CropPlotState? _ownedArablePlotAt(
    WorldMapPoint point,
    WorldMapParcel? parcel,
  ) {
    for (final plot in widget.session.plots) {
      if (plot.isOwned &&
          plot.use == CropPlotUse.arable &&
          plot.containsMapPoint(point.x, point.y)) {
        return plot;
      }
    }
    if (parcel == null || !_owns(parcel)) return null;
    if (parcel.isHome) {
      final starter = widget.session.plotById(widget.session.starterPlotId);
      return starter?.isOwned == true ? starter : null;
    }
    final operational =
        widget.session.plotForWorldParcel(parcel.id) ??
        widget.session.ensureOperationalWorldPlot(parcel);
    return operational?.isOwned == true &&
            operational?.use == CropPlotUse.arable
        ? operational
        : null;
  }

  bool _beginSalesRouteDrawing() {
    if (!widget.session.hasStarterTruck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış hattı için bir kamyon gerekir.')),
      );
      return false;
    }
    if (widget.session.fleetManager.totalWarehouseAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce satılacak ürünü ambara taşı.')),
      );
      return false;
    }
    setState(() {
      _salesRouteMode = true;
      _routeMode = false;
      _measureMode = false;
      _routeStartParcelId = null;
      _salesRouteStartPlotId = null;
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
      _measureStart = null;
      _measureEnd = null;
    });
    return true;
  }

  Future<void> _confirmStarterMarketRoute(CropPlotState source) async {
    final stockAmounts = <String, int>{};
    for (final batch in widget.session.fleetManager.warehouseStock) {
      stockAmounts.update(
        batch.cropId,
        (amount) => amount + batch.amount,
        ifAbsent: () => batch.amount,
      );
    }
    final productIds = stockAmounts.keys.toList()
      ..sort(
        (a, b) =>
            FarmItemCatalog.nameFor(a).compareTo(FarmItemCatalog.nameFor(b)),
      );
    final activeContract = widget.session.contractManager.activeContract;
    if (activeContract != null && !productIds.contains(activeContract.itemId)) {
      productIds.add(activeContract.itemId);
      stockAmounts[activeContract.itemId] = 0;
    }
    final productSelectionUnlocked = widget.session.hasResearch('L01');
    final repeatUnlocked = widget.session.hasResearch('L04');
    final amountController = TextEditingController(text: '10');
    String? selectedProductId = activeContract?.itemId;
    var fillVehicle = true;
    var repeatRoute = false;
    final settings = await showDialog<_SalesRouteSettings>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E9),
        title: const Text('Satış hattını ayarla'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${source.name} → Kasaba Pazarı'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProductId ?? '__any_stock__',
                    decoration: const InputDecoration(
                      labelText: 'Satılacak ürün',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '__any_stock__',
                        child: Text('Ambar sırasındaki ürün'),
                      ),
                      for (final itemId in productIds)
                        DropdownMenuItem(
                          value: itemId,
                          child: Text(
                            '${FarmItemCatalog.nameFor(itemId)} · ${stockAmounts[itemId]}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        !productSelectionUnlocked || activeContract != null
                        ? null
                        : (value) => setDialogState(
                            () => selectedProductId = value == '__any_stock__'
                                ? null
                                : value,
                          ),
                  ),
                  if (activeContract != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Sözleşme ürünü sabitlendi: ${FarmItemCatalog.nameFor(activeContract.itemId)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF536247),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: fillVehicle,
                    title: const Text('Kamyonu kapasitesine kadar doldur'),
                    subtitle: const Text(
                      'Sefer başına en çok 20 birim yükler.',
                    ),
                    onChanged: productSelectionUnlocked
                        ? (value) => setDialogState(() => fillVehicle = value)
                        : null,
                  ),
                  if (!fillVehicle)
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'Sefer başına miktar',
                        suffixText: 'birim',
                        border: OutlineInputBorder(),
                        isDense: true,
                        counterText: '',
                      ),
                    ),
                  const SizedBox(height: 7),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: repeatRoute,
                    title: const Text('Satış hattını sürekli tekrarla'),
                    subtitle: Text(
                      repeatUnlocked
                          ? 'Kamyon pazara her ulaştığında aynı kuralla yeniden yük alır.'
                          : 'L04 · İleri filo planlama araştırmasıyla açılır.',
                    ),
                    onChanged: repeatUnlocked
                        ? (value) => setDialogState(() => repeatRoute = value)
                        : null,
                  ),
                  if (!productSelectionUnlocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Ürün ve sefer miktarı seçimi L01 · Filo lisansı araştırmasıyla açılır. Bu ilk sevkiyat tek seferliktir.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: Color(0xFF78613A),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tek seferlik hatta bir yük pazara gider. Sürekli hatta seçilen ürün her dönüşte yeniden yüklenir; sabit miktar sefer başına üst sınırdır.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF536247),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GERİ DÖN'),
          ),
          FilledButton.icon(
            onPressed: () {
              final amount = fillVehicle
                  ? null
                  : int.tryParse(amountController.text);
              if (!fillVehicle &&
                  (amount == null ||
                      amount <= 0 ||
                      amount > TruckType.starter.capacity)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Miktar 1–20 arasında olmalı; başlangıç kamyonu 20 birim taşır.',
                    ),
                  ),
                );
                return;
              }
              if (selectedProductId != null &&
                  (stockAmounts[selectedProductId] ?? 0) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seçilen ürün ambarda yok.')),
                );
                return;
              }
              Navigator.pop(
                context,
                _SalesRouteSettings(
                  productId: productSelectionUnlocked
                      ? selectedProductId
                      : null,
                  amountPerTrip: productSelectionUnlocked ? amount : null,
                  repeatRoute: repeatUnlocked && repeatRoute,
                ),
              );
            },
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('HATTI KUR'),
          ),
        ],
      ),
    );
    amountController.dispose();
    if (settings == null || !mounted) return;

    final started = widget.session.startStarterMarketRoute(
      fieldX: source.mapX,
      fieldY: source.mapY,
      fieldName: source.name,
      productId: settings.productId,
      amountPerTrip: settings.amountPerTrip,
      repeatRoute: settings.repeatRoute,
    );
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış hattı şu anda kurulamıyor.')),
      );
      return;
    }
    widget.onSessionChanged();
    AudioController.instance.playEffect(SoundEffect.drawRoute);
    setState(() {
      _salesRouteMode = false;
      _salesRouteStartPlotId = null;
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satış hattı kuruldu. Sevkiyat başladı.')),
    );
  }

  void _handleSalesRouteTap(WorldMapPoint mapPoint, WorldMapParcel? parcel) {
    final market = WorldMapPoint(starterMarketMapX, starterMarketMapY);
    final hitMarket = mapPoint.distanceTo(market) <= 38 / _zoom;
    if (hitMarket) {
      final sourceId = _salesRouteStartPlotId;
      final source = sourceId == null
          ? null
          : widget.session.plotById(sourceId);
      if (source == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önce sahip olduğun hasat tarlasını seç.'),
          ),
        );
        return;
      }
      _confirmStarterMarketRoute(source);
      return;
    }

    final source = _ownedArablePlotAt(mapPoint, parcel);
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlangıç için sahip olduğun bir ekili araziyi seç.'),
        ),
      );
      return;
    }
    setState(() {
      _salesRouteStartPlotId = source.id;
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
    });
    HapticFeedback.selectionClick();
  }

  void _handleMapTap(Offset localPosition) {
    final worldPosition = _screenToWorld(localPosition);
    if (_measureMode) {
      setState(() {
        if (_measureStart == null || _measureEnd != null) {
          _measureStart = WorldMapPoint(worldPosition.dx, worldPosition.dy);
          _measureEnd = null;
        } else {
          _measureEnd = WorldMapPoint(worldPosition.dx, worldPosition.dy);
        }
      });
      return;
    }

    final mapPoint = WorldMapPoint(worldPosition.dx, worldPosition.dy);
    final parcel = _parcelAt(mapPoint);
    if (_constructionPlacementMode) {
      if (parcel == null || parcel.isHome || !_owns(parcel)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'İnşaat için sahip olduğun, çiftlik dışındaki bir araziyi seç.',
            ),
          ),
        );
        return;
      }
      if (widget.session.buildingOnParcel(parcel.id) != null) {
        setState(() {
          _constructionPlacementMode = false;
          _selectedFarmPlotId = null;
          _selectedParcelId = parcel.id;
          _selectedFleetVehicleId = null;
        });
        return;
      }
      setState(() {
        _constructionPlacementMode = false;
        _selectedFarmPlotId = null;
        _selectedParcelId = parcel.id;
        _selectedFleetVehicleId = null;
      });
      HapticFeedback.selectionClick();
      _openConstructionMenu(parcel);
      return;
    }
    if (_salesRouteMode) {
      _handleSalesRouteTap(mapPoint, parcel);
      return;
    }
    if (_routeMode) {
      if (parcel == null || !_owns(parcel)) {
        setState(() {
          _selectedFarmPlotId = null;
          _selectedParcelId = parcel?.id;
          _selectedFleetVehicleId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hat kurmak için sahip olduğun bir parseli seç.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_routeStartParcelId == null) {
        setState(() {
          _routeStartParcelId = parcel.id;
          _selectedFarmPlotId = null;
          _selectedParcelId = parcel.id;
          _selectedFleetVehicleId = null;
        });
        HapticFeedback.selectionClick();
        return;
      }
      if (parcel.id == _routeStartParcelId) {
        setState(() => _routeStartParcelId = null);
        return;
      }
      _confirmLogisticsLink(_routeStartParcelId!, parcel);
      return;
    }

    final tappedVehicle = _fleetVehicleAtScreenPoint(localPosition);
    if (tappedVehicle != null) {
      _selectFleetVehicle(tappedVehicle);
      return;
    }

    if (mapPoint.distanceTo(
          WorldMapPoint(starterMarketMapX, starterMarketMapY),
        ) <=
        38 / _zoom) {
      _openMarketTrade();
      return;
    }

    CropPlotState? localField;
    for (final plot in widget.session.plots) {
      if (plot.mapParcelId?.startsWith('home-') == true &&
          plot.containsMapPoint(mapPoint.x, mapPoint.y)) {
        localField = plot;
        break;
      }
    }
    if (localField != null) {
      _selectFarmPlot(localField);
      return;
    }

    if (parcel?.isHome == true) {
      final starterField = widget.session.plotById(
        widget.session.starterPlotId,
      );
      if (starterField != null) _selectFarmPlot(starterField);
      return;
    }

    if (parcel != null && _owns(parcel)) {
      if (widget.session.buildingOnParcel(parcel.id) != null) {
        setState(() {
          _selectedFarmPlotId = null;
          _selectedParcelId = parcel.id;
          _selectedFleetVehicleId = null;
        });
        return;
      }
      final operationalPlot = widget.session.ensureOperationalWorldPlot(parcel);
      if (operationalPlot != null) {
        _selectFarmPlot(operationalPlot);
        return;
      }
    }

    setState(() {
      _selectedFarmPlotId = null;
      _selectedParcelId = parcel?.id;
      _selectedFleetVehicleId = null;
    });
    if (parcel != null) HapticFeedback.selectionClick();
  }

  void _selectFarmPlot(CropPlotState plot) {
    setState(() {
      _selectedFarmPlotId = plot.id;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
    });
    HapticFeedback.selectionClick();
  }

  void _selectFleetVehicle(FleetVehicleState vehicle, {bool focus = false}) {
    final point = _fleetVehicleWorldPoint(vehicle);
    setState(() {
      _selectedFleetVehicleId = vehicle.id;
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      if (focus) {
        _cameraCenter = point;
        _zoom = _zoom.clamp(0.68, _maxZoom).toDouble();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _jumpToFleetVehicle(FleetVehicleState vehicle) =>
      _selectFleetVehicle(vehicle, focus: true);

  FleetVehicleState? get _selectedFleetVehicle {
    final id = _selectedFleetVehicleId;
    if (id == null) return null;
    for (final vehicle in widget.session.fleetManager.vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  Offset _worldToScreen(Offset point) => Offset(
    (point.dx - _cameraCenter.dx) * _zoom + _viewportSize.width / 2,
    (point.dy - _cameraCenter.dy) * _zoom + _viewportSize.height / 2,
  );

  TransportRoute? _routeForFleetVehicle(FleetVehicleState vehicle) {
    final id = vehicle.assignedRouteId;
    if (id == null) return null;
    for (final route in widget.session.fleetManager.routes) {
      if (route.id == id) return route;
    }
    return null;
  }

  Offset _fleetVehicleWorldPoint(FleetVehicleState vehicle) {
    final route = _routeForFleetVehicle(vehicle);
    if (route == null || route.stops.isEmpty) {
      return const Offset(-150, -8);
    }
    final currentIndex = vehicle.currentStopIndex
        .clamp(0, route.stops.length - 1)
        .toInt();
    final start = route.stops[currentIndex];
    if (route.stops.length == 1) {
      return Offset(start.positionX, start.positionY);
    }
    final end = route.stops[route.nextStopIndex(currentIndex)];
    return Offset.lerp(
      Offset(start.positionX, start.positionY),
      Offset(end.positionX, end.positionY),
      vehicle.progressToNextStop.clamp(0.0, 1.0).toDouble(),
    )!;
  }

  double _fleetVehicleHeading(FleetVehicleState vehicle) {
    final route = _routeForFleetVehicle(vehicle);
    if (route == null || route.stops.length < 2) return math.pi / 2;
    final index = vehicle.currentStopIndex
        .clamp(0, route.stops.length - 1)
        .toInt();
    final start = route.stops[index];
    final end = route.stops[route.nextStopIndex(index)];
    return math.atan2(
          end.positionY - start.positionY,
          end.positionX - start.positionX,
        ) +
        math.pi / 2;
  }

  double get _fleetMarkerWidth => (_zoom * 56).clamp(26.0, 50.0).toDouble();
  double get _fleetMarkerLength => (_zoom * 88).clamp(36.0, 78.0).toDouble();
  double get _fieldMachineScale => _zoom.clamp(0.42, 1.12).toDouble();

  Map<String, Offset> _fleetMarkerDisplayOffsets() {
    final vehicles = [...widget.session.fleetManager.vehicles]
      ..sort((a, b) => a.id.compareTo(b.id));
    final positions = {
      for (final vehicle in vehicles)
        vehicle.id: _fleetVehicleWorldPoint(vehicle),
    };
    final offsets = {for (final vehicle in vehicles) vehicle.id: Offset.zero};
    final groupedIds = <String>{};
    final radius = (_fleetMarkerWidth * 0.42).clamp(10.0, 21.0).toDouble();

    for (final vehicle in vehicles) {
      if (!groupedIds.add(vehicle.id)) continue;
      final worldPoint = positions[vehicle.id]!;
      final overlapGroup = vehicles
          .where(
            (candidate) =>
                (positions[candidate.id]! - worldPoint).distance <= 1,
          )
          .toList(growable: false);
      groupedIds.addAll(overlapGroup.map((candidate) => candidate.id));
      if (overlapGroup.length < 2) continue;

      final heading = _fleetVehicleHeading(overlapGroup.first);
      for (var index = 0; index < overlapGroup.length; index++) {
        final angle = heading + (math.pi * 2 * index / overlapGroup.length);
        offsets[overlapGroup[index].id] = Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
      }
    }
    return offsets;
  }

  Offset _fleetMarkerScreenPoint(
    FleetVehicleState vehicle,
    Map<String, Offset> displayOffsets,
  ) =>
      _worldToScreen(_fleetVehicleWorldPoint(vehicle)) +
      (displayOffsets[vehicle.id] ?? Offset.zero);

  FleetVehicleState? _fleetVehicleAtScreenPoint(Offset point) {
    final vehicles = widget.session.fleetManager.vehicles;
    final displayOffsets = _fleetMarkerDisplayOffsets();
    FleetVehicleState? closest;
    var closestDistanceSquared = double.infinity;
    for (final vehicle in vehicles) {
      final screenPoint = _fleetMarkerScreenPoint(vehicle, displayOffsets);
      final angle = _fleetVehicleHeading(vehicle);
      final delta = point - screenPoint;
      final cosine = math.cos(-angle);
      final sine = math.sin(-angle);
      final localX = delta.dx * cosine - delta.dy * sine;
      final localY = delta.dx * sine + delta.dy * cosine;
      if (localX.abs() <= _fleetMarkerWidth / 2 + 12 &&
          localY.abs() <= _fleetMarkerLength / 2 + 12) {
        final distanceSquared = localX * localX + localY * localY;
        if (distanceSquared < closestDistanceSquared) {
          closest = vehicle;
          closestDistanceSquared = distanceSquared;
        }
      }
    }
    return closest;
  }

  bool _owns(WorldMapParcel parcel) => parcel.isHome
      ? widget.session.ownsWorldParcel(parcel.id)
      : widget.session.ownsWorldParcel(parcel.id);

  void _beginConstructionPlacement() {
    setState(() {
      _constructionPlacementMode = true;
      _routeMode = false;
      _salesRouteMode = false;
      _measureMode = false;
      _routeStartParcelId = null;
      _salesRouteStartPlotId = null;
      _measureStart = null;
      _measureEnd = null;
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'İnşaat menüsü için sahip olduğun uygun bir araziye dokun.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _openConstructionMenu(WorldMapParcel parcel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FarmConstructionMenu(
        session: widget.session,
        parcel: parcel,
        onPickAnotherParcel: _beginConstructionPlacement,
        onBuilt: () {
          widget.onSessionChanged();
          setState(() {
            _selectedParcelId = parcel.id;
            _selectedFarmPlotId = null;
            _mapRevision++;
          });
        },
      ),
    );
  }

  WorldMapParcel? get _selectedParcel {
    final id = _selectedParcelId;
    return id == null ? null : _world.parcelById(id, searchRadius: 2);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartFocal = details.localFocalPoint;
    _gestureCurrentFocal = details.localFocalPoint;
    _gestureStartCamera = _cameraCenter;
    _gestureStartZoom = _zoom;
    _gestureStartAnchor = _screenToWorld(details.localFocalPoint);
    _gestureMoved = false;
  }

  Offset _gestureStartFocal = Offset.zero;
  Offset _gestureCurrentFocal = Offset.zero;
  Offset _gestureStartCamera = Offset.zero;
  Offset _gestureStartAnchor = Offset.zero;
  double _gestureStartZoom = 1;
  bool _gestureMoved = false;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _gestureCurrentFocal = details.localFocalPoint;
    final scale = details.scale;
    final nextZoom = (_gestureStartZoom * scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    final wasDragged =
        (details.localFocalPoint - _gestureStartFocal).distance > 5;
    final wasPinched = (nextZoom - _gestureStartZoom).abs() > 0.004;
    _gestureMoved = _gestureMoved || wasDragged || wasPinched;

    setState(() {
      _zoom = nextZoom;
      if (wasPinched || scale != 1) {
        final viewportCenter = Offset(
          _viewportSize.width / 2,
          _viewportSize.height / 2,
        );
        _cameraCenter = _clampCameraCenter(
          _gestureStartAnchor -
              (details.localFocalPoint - viewportCenter) / _zoom,
          _zoom,
        );
      } else {
        _cameraCenter = _clampCameraCenter(
          _gestureStartCamera -
              (details.localFocalPoint - _gestureStartFocal) / _zoom,
          _zoom,
        );
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_gestureMoved) _handleMapTap(_gestureCurrentFocal);
  }

  Future<void> _confirmLogisticsLink(
    String fromParcelId,
    WorldMapParcel toParcel,
  ) async {
    final fromParcel = _world.parcelById(fromParcelId, searchRadius: 2);
    if (fromParcel == null) return;
    if (widget.session.hasWorldLogisticsLink(fromParcelId, toParcel.id)) {
      setState(() {
        _selectedParcelId = toParcel.id;
        _routeStartParcelId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu iki arazi zaten bağlı.')),
      );
      return;
    }

    final distance = fromParcel.center.distanceTo(toParcel.center);
    final cost = 250 + (distance * 0.018).round();
    final amount = cost.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E9),
        title: const Text('Lojistik hattı kur'),
        content: Text(
          '${fromParcel.name}\n↔ ${toParcel.name}\n\n'
          'Mesafe: ${_formatDistance(distance)}\n'
          'Kurulum bedeli: $amount ÇK\n\n'
          'Hat haritada kalıcı olarak işaretlenecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton.icon(
            onPressed: widget.session.farmCredits >= cost
                ? () => Navigator.pop(context, true)
                : null,
            icon: const Icon(Icons.add_road_rounded),
            label: const Text('HAT KUR'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (accepted != true) {
      setState(() => _routeStartParcelId = null);
      return;
    }

    final fromKey = fromParcelId.compareTo(toParcel.id) <= 0
        ? fromParcelId
        : toParcel.id;
    final toKey = fromParcelId.compareTo(toParcel.id) <= 0
        ? toParcel.id
        : fromParcelId;
    final link = WorldLogisticsLink(
      id: 'link:$fromKey|$toKey',
      name: '${_shortName(fromParcel)} – ${_shortName(toParcel)}',
      fromParcelId: fromParcel.id,
      toParcelId: toParcel.id,
      from: fromParcel.center,
      to: toParcel.center,
      cost: cost,
    );
    final purchased = widget.session.addWorldLogisticsLink(link);
    setState(() {
      if (purchased) _mapRevision++;
      _routeStartParcelId = null;
      _selectedParcelId = toParcel.id;
    });
    if (purchased) {
      HapticFeedback.mediumImpact();
      widget.onSessionChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lojistik hattı kuruldu · ${_formatDistance(distance)}',
          ),
        ),
      );
    }
  }

  String _shortName(WorldMapParcel parcel) {
    if (parcel.isHome) return 'Başlangıç';
    final type = _cropLabel(parcel.cropType);
    final coordinate = parcel.id.split(':');
    return '$type ${coordinate.length > 2 ? coordinate[1] : ''}/${coordinate.length > 3 ? coordinate[2] : ''}';
  }

  String _formatDistance(double distance) => distance >= 1000
      ? '${(distance / 1000).toStringAsFixed(1)} km'
      : '${distance.round()} m';

  void _buySelectedParcel(WorldMapParcel parcel) {
    if (widget.session.buyWorldParcel(parcel)) {
      HapticFeedback.mediumImpact();
      widget.onSessionChanged();
      final plot = widget.session.plotForWorldParcel(parcel.id);
      setState(() {
        _mapRevision++;
        _selectedParcelId = null;
        _selectedFarmPlotId = plot?.id;
        _selectedFleetVehicleId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${parcel.name} satın alındı.')));
    }
  }

  void _closeParcelCard() => setState(() {
    _selectedParcelId = null;
    _selectedFarmPlotId = null;
    _selectedFleetVehicleId = null;
  });

  String _selectedCrop(CropPlotState plot) => _selectedCropByPlot.putIfAbsent(
    plot.id,
    () => OpeningCropCatalog.all
        .firstWhere((crop) => widget.session.isCropUnlockedForFarm(crop.id))
        .id,
  );

  void _buyFarmPlot(CropPlotState plot) {
    if (!widget.session.buyPlot(plot.id)) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
    HapticFeedback.mediumImpact();
  }

  void _prepareFarmPlot(CropPlotState plot) {
    if (!widget.session.cultivatePlot(plot.id)) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _fertilizeFarmPlot(CropPlotState plot) {
    if (!widget.session.fertilizePlot(plot.id)) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _plantFarmPlot(CropPlotState plot, String cropId) {
    if (!widget.session.plantCropOnPlot(plot.id, cropId, DateTime.now())) {
      return;
    }
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _harvestFarmPlot(CropPlotState plot) {
    if (!widget.session.harvestCropOnPlot(plot.id, DateTime.now())) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _baleFarmPlot(CropPlotState plot) {
    if (!widget.session.balePasturePlot(plot.id, DateTime.now())) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _sellPastureBales(CropPlotState plot) {
    if (!widget.session.sellPastureBales(plot.id)) return;
    widget.onSessionChanged();
    setState(() => _mapRevision++);
  }

  void _jumpToPlot(CropPlotState plot) {
    setState(() {
      _selectedFarmPlotId = plot.id;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
      _cameraCenter = Offset(plot.mapX, plot.mapY);
      _zoom = _zoom.clamp(0.68, _maxZoom).toDouble();
    });
  }

  Future<void> _openManagement() async {
    if (widget.session.state.farmTutorialStep == FarmTutorialStep.management) {
      widget.session.setFarmTutorialStep(FarmTutorialStep.complete);
      widget.onSessionChanged();
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8E9),
      builder: (context) => FarmManagementSheet(
        session: widget.session,
        onSelectPlot: _jumpToPlot,
        onSelectVehicle: _jumpToFleetVehicle,
        onChanged: () {
          widget.onSessionChanged();
          if (mounted) setState(() {});
        },
      ),
    );
    widget.onSessionChanged();
    if (mounted) setState(() {});
  }

  Future<void> _openMarketTrade() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarketTradeSheet(
        session: widget.session,
        onChanged: () {
          widget.onSessionChanged();
          if (mounted) setState(() {});
        },
      ),
    );
    widget.onSessionChanged();
    if (mounted) setState(() {});
  }

  Future<void> _openFarmAnalytics() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FarmAnalyticsSheet(session: widget.session),
    );
  }

  Future<void> _openFarmOperations() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8E9),
      builder: (context) => FarmOperationsSheet(
        session: widget.session,
        onChanged: () {
          widget.onSessionChanged();
          if (mounted) setState(() {});
        },
      ),
    );
    widget.onSessionChanged();
    if (mounted) setState(() {});
  }

  Future<void> _openFarmAlmanac() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FarmAlmanacSheet(session: widget.session),
    );
  }

  Future<void> _openEquipmentStore() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8E9),
      builder: (context) => _EquipmentStoreSheet(
        session: widget.session,
        onChanged: () {
          widget.onSessionChanged();
          setState(() {});
        },
      ),
    );
    if (widget.session.state.farmTutorialStep == FarmTutorialStep.shop) {
      widget.session.setFarmTutorialStep(FarmTutorialStep.management);
      widget.onSessionChanged();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openWarehouseInventory() async {
    if (widget.session.state.farmTutorialStep == FarmTutorialStep.warehouse) {
      widget.session.setFarmTutorialStep(FarmTutorialStep.deliveryRoute);
      widget.onSessionChanged();
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8E9),
      builder: (context) => _WarehouseInventorySheet(
        session: widget.session,
        isTutorialRouteStep:
            widget.session.state.farmTutorialStep ==
            FarmTutorialStep.deliveryRoute,
        onStartDeliveryRoute: () {
          return _beginSalesRouteDrawing();
        },
      ),
    );
    if (mounted) setState(() {});
  }

  void _focusSalesPoint() {
    setState(() {
      _cameraCenter = const Offset(starterMarketMapX, starterMarketMapY);
      _zoom = math.max(_zoom, 0.72);
      _selectedFarmPlotId = null;
      _selectedParcelId = null;
      _selectedFleetVehicleId = null;
    });
    _openMarketTrade();
  }

  Future<void> _openCoordinateSearch() async {
    final xController = TextEditingController(
      text: _cameraCenter.dx.round().toString(),
    );
    final yController = TextEditingController(
      text: _cameraCenter.dy.round().toString(),
    );
    final coordinate = await showDialog<Offset>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E9),
        title: const Text('Koordinata git'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dünya koordinatları metre cinsindedir.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: xController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'X'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Y'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () {
              final x = double.tryParse(xController.text.replaceAll(',', '.'));
              final y = double.tryParse(yController.text.replaceAll(',', '.'));
              if (x == null ||
                  y == null ||
                  !x.isFinite ||
                  !y.isFinite ||
                  x.abs() > 1000000000000 ||
                  y.abs() > 1000000000000) {
                return;
              }
              Navigator.pop(context, Offset(x, y));
            },
            child: const Text('GİT'),
          ),
        ],
      ),
    );
    xController.dispose();
    yController.dispose();
    if (coordinate == null || !mounted) return;
    setState(() {
      final targetZoom = _zoom < 0.42 ? 0.42 : _zoom;
      _cameraCenter = _clampCameraCenter(coordinate, targetZoom);
      _zoom = targetZoom;
      _selectedParcelId = null;
    });
  }

  Future<void> _openLayerOptions() async {
    var parcels = _showParcels;
    var routes = _showRoutes;
    var infrastructure = _showInfrastructure;
    var fertility = _showFertility;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFF8E9),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HARİTA KATMANLARI',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _LegendItem(color: Color(0xFFCBA653), label: 'Tahıl'),
                    _LegendItem(color: Color(0xFF9DAD50), label: 'Yağlı tohum'),
                    _LegendItem(color: Color(0xFF638F4C), label: 'Sebze'),
                    _LegendItem(color: Color(0xFF8DA65C), label: 'Mera'),
                    _LegendItem(color: Color(0xFFFFF0CE), label: 'Satılık'),
                    _LegendItem(color: Color(0xFFB8E48F), label: 'Sahipli'),
                  ],
                ),
                const SizedBox(height: 8),
                _LayerSwitch(
                  icon: Icons.grid_on_rounded,
                  title: 'Tarla sınırları ve ürün türü',
                  value: parcels,
                  onChanged: (value) => setSheetState(() => parcels = value),
                ),
                _LayerSwitch(
                  icon: Icons.add_road_rounded,
                  title: 'Lojistik hatları ve ana yollar',
                  value: routes,
                  onChanged: (value) => setSheetState(() => routes = value),
                ),
                _LayerSwitch(
                  icon: Icons.water_drop_rounded,
                  title: 'Su, köy ve tesis işaretleri',
                  value: infrastructure,
                  onChanged: (value) =>
                      setSheetState(() => infrastructure = value),
                ),
                _LayerSwitch(
                  icon: Icons.terrain_rounded,
                  title: 'Verimlilik renkleri',
                  value: fertility,
                  onChanged: (value) => setSheetState(() => fertility = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _showParcels = parcels;
                        _showRoutes = routes;
                        _showInfrastructure = infrastructure;
                        _showFertility = fertility;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('KATMANLARI UYGULA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openResearch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TechTreeOverlay(
          session: widget.session,
          onNodePurchased: widget.onSessionChanged,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  List<Widget> _fleetMapMarkers() {
    final fleet = widget.session.fleetManager;
    final markers = <Widget>[];
    final displayOffsets = _fleetMarkerDisplayOffsets();
    for (final vehicle in fleet.vehicles) {
      final screenPoint = _fleetMarkerScreenPoint(vehicle, displayOffsets);
      if (screenPoint.dx < -100 ||
          screenPoint.dy < -100 ||
          screenPoint.dx > _viewportSize.width + 100 ||
          screenPoint.dy > _viewportSize.height + 100) {
        continue;
      }

      final length = _fleetMarkerLength;
      final width = _fleetMarkerWidth;
      final angle = _fleetVehicleHeading(vehicle);
      final trailer = vehicle.trailerType;
      final selected = vehicle.id == _selectedFleetVehicleId;
      markers.add(
        Positioned(
          left: screenPoint.dx - width / 2,
          top: screenPoint.dy - length / 2,
          width: width,
          height: length,
          child: Transform.rotate(
            angle: angle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? const Color(0x55FFC84F) : Colors.transparent,
                borderRadius: BorderRadius.circular(width / 2),
                border: selected
                    ? Border.all(color: const Color(0xFFE3A923), width: 2)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (trailer != null)
                    Positioned(
                      left: width * 0.06,
                      top: length * 0.43,
                      width: width * 0.88,
                      height: length * 0.56,
                      child: Image.asset(
                        trailer.imageAsset,
                        fit: BoxFit.contain,
                        cacheWidth: 160,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  Positioned(
                    left: width * 0.04,
                    top: 0,
                    width: width * 0.92,
                    height: trailer == null ? length : length * 0.58,
                    child: Image.asset(
                      vehicle.truckType.imageAsset,
                      fit: BoxFit.contain,
                      cacheWidth: 160,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tır Canlı Kargo ve Durum Rozeti
      final fuelRatio = (vehicle.fuelLevel / 100.0).clamp(0.0, 1.0);
      final wearRatio = (vehicle.wearPercent / 100.0).clamp(0.0, 1.0);
      final fuelColor = fuelRatio > 0.4
          ? const Color(0xFF4CAF50)
          : fuelRatio > 0.15
          ? const Color(0xFFFF9800)
          : const Color(0xFFF44336);
      final hasCargo = vehicle.cargoAmount > 0;

      markers.add(
        Positioned(
          left: screenPoint.dx - 55,
          top: screenPoint.dy - length / 2 - 18,
          width: 110,
          height: 18,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xDD1B3322),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? _mapGold : const Color(0x66FFFFFF),
                  width: selected ? 1.5 : 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vehicle.status == VehicleStatus.loading) ...[
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: _mapGold,
                      size: 9,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Yükleniyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (vehicle.status == VehicleStatus.unloading) ...[
                    const Icon(
                      Icons.unarchive_rounded,
                      color: _mapGold,
                      size: 9,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Boşaltılıyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (hasCargo) ...[
                    const Text('📦', style: TextStyle(fontSize: 8)),
                    const SizedBox(width: 2),
                    Text(
                      '${vehicle.cargoAmount}t',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      vehicle.id.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      // Yakıt ve Aşınma Durum Çubukları
      markers.add(
        Positioned(
          left: screenPoint.dx - 22,
          top: screenPoint.dy + length / 2 + 3,
          width: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0x88000000),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fuelRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fuelColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              if (wearRatio > 0.05) ...[
                const SizedBox(height: 1.5),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: wearRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return markers;
  }

  List<Widget> _farmBuildingMapMarkers(DateTime now) {
    final markers = <Widget>[];
    for (final building in widget.session.buildings) {
      final parcel = _world.parcelById(building.parcelId, searchRadius: 2);
      final definition = FarmBuildingCatalog.byId(building.definitionId);
      if (parcel == null || definition == null) continue;
      final point = Offset(
        (parcel.center.x - _cameraCenter.dx) * _zoom + _viewportSize.width / 2,
        (parcel.center.y - _cameraCenter.dy) * _zoom + _viewportSize.height / 2,
      );
      final extent = (math.min(parcel.width, parcel.height) * _zoom * 0.88)
          .clamp(20.0, 260.0)
          .toDouble();
      if (point.dx < -extent ||
          point.dy < -extent ||
          point.dx > _viewportSize.width + extent ||
          point.dy > _viewportSize.height + extent) {
        continue;
      }
      final complete = building.isCompleteAt(now);
      markers.add(
        Positioned(
          left: point.dx - extent / 2,
          top: point.dy - extent / 2,
          width: extent,
          height: extent,
          child: Image.asset(
            complete
                ? definition.imageAsset
                : FarmBuildingCatalog.constructionSiteAsset,
            fit: BoxFit.contain,
            cacheWidth: 384,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.session.farmCredits;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final selectedParcel = _selectedParcel;
        final selectedBuilding = selectedParcel == null
            ? null
            : widget.session.buildingOnParcel(selectedParcel.id);
        final selectedPlot = _selectedFarmPlotId == null
            ? null
            : widget.session.plotById(_selectedFarmPlotId!);
        final selectedVehicle = _selectedFleetVehicle;
        final salesRouteStartPlot = _salesRouteStartPlotId == null
            ? null
            : widget.session.plotById(_salesRouteStartPlotId!);
        final tutorialStep = widget.session.state.farmTutorialStep;
        final tutorialPlot = widget.session.plotById(
          widget.session.starterPlotId,
        );
        final fieldMachines = <Widget>[];
        for (final plot in widget.session.plotsWithActiveJobs) {
          final job = plot.activeJob;
          if (job == null) continue;
          final point = Offset(
            (plot.mapX - _cameraCenter.dx) * _zoom + _viewportSize.width / 2,
            (plot.mapY - _cameraCenter.dy) * _zoom + _viewportSize.height / 2,
          );
          if (point.dx < -80 ||
              point.dy < -80 ||
              point.dx > _viewportSize.width + 80 ||
              point.dy > _viewportSize.height + 80) {
            continue;
          }
          fieldMachines.add(
            Positioned(
              left: point.dx - 45 * _fieldMachineScale,
              top: point.dy - 36 * _fieldMachineScale,
              child: _MovingFieldMachine(
                asset:
                    FarmEquipmentCatalog.byId(job.equipmentId)?.imageAsset ??
                    job.operation.iconAsset,
                tractorAsset:
                    FarmEquipmentCatalog.byId(job.equipmentId)
                            ?.requiresTractor ==
                        true
                    ? FarmEquipmentCatalog.byId(
                        job.tractorEquipmentId ??
                            widget.session.equippedTractor?.id ??
                            '',
                      )?.imageAsset
                    : null,
                progress: _fieldMachineController,
                scale: _fieldMachineScale,
                travel: (plot.mapWidth * _zoom * 0.32).clamp(10, 42),
                label:
                    FarmEquipmentCatalog.byId(job.equipmentId)?.name ??
                    job.operation.label,
              ),
            ),
          );
        }
        final farmCenter = Offset(
          (-150 - _cameraCenter.dx) * _zoom + _viewportSize.width / 2,
          (-120 - _cameraCenter.dy) * _zoom + _viewportSize.height / 2,
        );
        final farmWidth = 218 * _zoom;
        final farmHeight = farmWidth * 0.8;
        final farmBase = Positioned(
          left: farmCenter.dx - farmWidth / 2,
          top: farmCenter.dy - farmHeight / 2,
          width: farmWidth,
          height: farmHeight,
          child: Image.asset(
            'assets/images/management/topdown-farm-base.png',
            fit: BoxFit.contain,
            cacheWidth: 512,
            filterQuality: FilterQuality.medium,
          ),
        );
        final fleetMarkers = _fleetMapMarkers();
        final buildingMarkers = _farmBuildingMapMarkers(DateTime.now());
        final playerPoint = selectedPlot == null
            ? Offset(tutorialPlot?.mapX ?? -150, tutorialPlot?.mapY ?? -120)
            : Offset(selectedPlot.mapX, selectedPlot.mapY);
        final radarTrucks = widget.session.fleetManager.vehicles
            .map(_fleetVehicleWorldPoint)
            .toList(growable: false);
        final radarFields = widget.session.plots
            .where((plot) => plot.isOwned)
            .map((plot) => Offset(plot.mapX, plot.mapY))
            .toList(growable: false);
        final radarRoutes = widget.session.fleetManager.routes
            .where((route) => route.stops.length > 1)
            .map(
              (route) => route.stops
                  .map((stop) => Offset(stop.positionX, stop.positionY))
                  .toList(growable: false),
            )
            .toList(growable: false);
        final hasMarketOrder = widget.session.contractManager.visibleContracts
            .any(
              (contract) =>
                  contract.status == DeliveryContractStatus.offered ||
                  contract.status == DeliveryContractStatus.accepted,
            );
        final radarOrders = hasMarketOrder
            ? const [Offset(starterMarketMapX, starterMarketMapY)]
            : const <Offset>[];
        final radarViewport = Rect.fromCenter(
          center: _cameraCenter,
          width: _viewportSize.width / _zoom,
          height: _viewportSize.height / _zoom,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: CustomPaint(
                painter: _WorldMapPainter(
                  world: _world,
                  session: widget.session,
                  mapRevision: _mapRevision,
                  cameraCenter: _cameraCenter,
                  zoom: _zoom,
                  selectedParcelId: _selectedParcelId,
                  selectedFarmPlotId: _selectedFarmPlotId,
                  routeStartParcelId: _routeStartParcelId,
                  salesRouteStartPlotId: _salesRouteStartPlotId,
                  salesRouteMode: _salesRouteMode,
                  salesRouteStart: salesRouteStartPlot == null
                      ? null
                      : Offset(
                          salesRouteStartPlot.mapX,
                          salesRouteStartPlot.mapY,
                        ),
                  measureStart: _measureStart,
                  measureEnd: _measureEnd,
                  showParcels: _showParcels,
                  showRoutes: _showRoutes,
                  showInfrastructure: _showInfrastructure,
                  showFertility: _showFertility,
                ),
              ),
            ),
            IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  farmBase,
                  ...buildingMarkers,
                  ...fieldMachines,
                  ...fleetMarkers,
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _TopActionBar(
                      balance: balance,
                      onOpenResearch: _openResearch,
                      onOpenEquipment: _openEquipmentStore,
                      onBeginConstruction: _beginConstructionPlacement,
                      constructionActive: _constructionPlacementMode,
                      onOpenManagement: _openManagement,
                      managementHighlighted:
                          tutorialStep == FarmTutorialStep.management,
                      onOpenWarehouse: _openWarehouseInventory,
                      warehouseHighlighted:
                          tutorialStep == FarmTutorialStep.warehouse ||
                          tutorialStep == FarmTutorialStep.deliveryRoute ||
                          tutorialStep == FarmTutorialStep.delivery,
                      warehouseStock:
                          widget.session.fleetManager.totalWarehouseAmount +
                          widget.session.fleetManager.vehicles.fold<int>(
                            0,
                            (sum, vehicle) => sum + vehicle.cargoAmount,
                          ),
                      onFocusSalesPoint: _focusSalesPoint,
                      salesHighlighted:
                          tutorialStep == FarmTutorialStep.deliveryRoute ||
                          _salesRouteMode,
                      onSearch: _openCoordinateSearch,
                      onOpenAnalytics: _openFarmAnalytics,
                      onOpenAlmanac: _openFarmAlmanac,
                      onOpenOperations: _openFarmOperations,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tutorialStep != FarmTutorialStep.complete)
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _FarmTutorialCoach(
                                step: tutorialStep,
                                plot: tutorialPlot,
                                session: widget.session,
                                onOpenComic: _openStoryComic,
                                onBegin: () {
                                  widget.session.setFarmTutorialStep(
                                    FarmTutorialStep.prepare,
                                  );
                                  widget.onSessionChanged();
                                  final starter = widget.session.plotById(
                                    widget.session.starterPlotId,
                                  );
                                  setState(() {
                                    if (starter != null) {
                                      _selectedFarmPlotId = starter.id;
                                      _cameraCenter = Offset(
                                        starter.mapX,
                                        starter.mapY,
                                      );
                                      _zoom = 0.9;
                                    }
                                  });
                                },
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!_salesRouteMode &&
                                !_routeMode &&
                                !_measureMode &&
                                !_constructionPlacementMode) ...[
                              const SizedBox(height: 5),
                              FarmRadarMiniMap(
                                home: const Offset(-150, -120),
                                player: playerPoint,
                                viewport: radarViewport,
                                trucks: radarTrucks,
                                orders: radarOrders,
                                fields: radarFields,
                                routes: radarRoutes,
                                onTap: () => setState(() {
                                  _cameraCenter = playerPoint;
                                  _zoom = math.max(_zoom, 0.72).toDouble();
                                  _selectedParcelId = null;
                                  _selectedFarmPlotId =
                                      selectedPlot?.id ??
                                      widget.session.starterPlotId;
                                  _selectedFleetVehicleId = null;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_salesRouteMode)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 54,
                left: 12,
                right: 78,
                child: _InstructionPill(
                  icon: Icons.local_shipping_rounded,
                  text: _salesRouteStartPlotId == null
                      ? 'İlk olarak sahip olduğun hasat tarlasına dokun.'
                      : 'Tarla seçildi. Şimdi haritadaki “KASABA PAZARI” işaretine dokun.',
                ),
              ),
            if (_routeMode)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 54,
                left: 12,
                right: 78,
                child: _InstructionPill(
                  icon: Icons.add_road_rounded,
                  text: _routeStartParcelId == null
                      ? 'Önce sahip olduğun başlangıç arazisine dokun.'
                      : 'Şimdi hattın bağlanacağı ikinci sahipli araziyi seç.',
                ),
              ),
            if (_measureMode)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 54,
                left: 12,
                right: 78,
                child: _InstructionPill(
                  icon: Icons.straighten_rounded,
                  text: _measureEnd == null
                      ? 'Mesafeyi başlatmak için haritaya dokun.'
                      : 'Mesafe: ${_formatDistance(_measureStart!.distanceTo(_measureEnd!))} · yeni ölçüm için tekrar dokun.',
                ),
              ),
            Positioned(
              right: 12,
              bottom: isLandscape
                  ? 20
                  : (selectedParcel == null &&
                            selectedPlot == null &&
                            selectedVehicle == null
                        ? 24
                        : 350),
              child: _ZoomControls(
                onZoomIn: () => setState(
                  () => _zoom = (_zoom * 1.24)
                      .clamp(_minZoom, _maxZoom)
                      .toDouble(),
                ),
                onZoomOut: () => setState(
                  () => _zoom = (_zoom / 1.24)
                      .clamp(_minZoom, _maxZoom)
                      .toDouble(),
                ),
                onRecenter: () => setState(() {
                  _cameraCenter = const Offset(-150, -120);
                  _zoom = 0.64;
                  _selectedParcelId = null;
                  _selectedFarmPlotId = widget.session.starterPlotId;
                  _selectedFleetVehicleId = null;
                }),
              ),
            ),
            if (_constructionPlacementMode)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 54,
                left: 12,
                right: 78,
                child: const _InstructionPill(
                  icon: Icons.construction_rounded,
                  text: 'İnşaat için sahip olduğun, çiftlik dışındaki uygun bir araziye dokun.',
                ),
              ),
            if (selectedParcel != null && selectedBuilding != null)
              Positioned(
                left: 12,
                right: isLandscape ? null : 12,
                bottom: 12,
                width: isLandscape ? 380 : null,
                child: SafeArea(
                  top: false,
                  child: _FarmBuildingInfoCard(
                    building: selectedBuilding,
                    now: DateTime.now(),
                    onClose: _closeParcelCard,
                    onResume: () {
                      final resumed = widget.session
                          .resumeBuildingAfterOperatingCost(
                            selectedBuilding.parcelId,
                          );
                      if (!resumed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'İşletme giderini karşılayacak bakiye yok.',
                            ),
                          ),
                        );
                        return;
                      }
                      widget.onSessionChanged();
                      setState(() {});
                    },
                  ),
                ),
              )
            else if (selectedParcel != null)
              Positioned(
                left: 12,
                right: isLandscape ? null : 12,
                bottom: 12,
                width: isLandscape ? 380 : null,
                child: SafeArea(
                  top: false,
                  child: _ParcelInfoCard(
                    parcel: selectedParcel,
                    owned: _owns(selectedParcel),
                    balance: balance,
                    routeMode: _routeMode,
                    routeSelected: _routeStartParcelId == selectedParcel.id,
                    onBuy: () => _buySelectedParcel(selectedParcel),
                    onClose: _closeParcelCard,
                    onSelectRoute: () => setState(() {
                      _routeMode = true;
                      _measureMode = false;
                      _routeStartParcelId = selectedParcel.id;
                    }),
                  ),
                ),
              ),
            if (selectedPlot != null)
              Positioned(
                left: 12,
                right: isLandscape ? null : 12,
                bottom: 12,
                width: isLandscape ? 380 : null,
                child: SafeArea(
                  top: false,
                  child: _FarmPlotInfoCard(
                    session: widget.session,
                    plot: selectedPlot,
                    selectedCropId: _selectedCrop(selectedPlot),
                    now: DateTime.now(),
                    onClose: _closeParcelCard,
                    onBuy: () => _buyFarmPlot(selectedPlot),
                    onSelectCrop: (cropId) => setState(
                      () => _selectedCropByPlot[selectedPlot.id] = cropId,
                    ),
                    onPrepare: () => _prepareFarmPlot(selectedPlot),
                    onFertilize: () => _fertilizeFarmPlot(selectedPlot),
                    onPlant: (cropId) => _plantFarmPlot(selectedPlot, cropId),
                    onHarvest: () => _harvestFarmPlot(selectedPlot),
                    onBale: () => _baleFarmPlot(selectedPlot),
                    onSellBales: () => _sellPastureBales(selectedPlot),
                    tutorialStep: tutorialStep,
                  ),
                ),
              ),
            if (selectedVehicle != null &&
                selectedPlot == null &&
                selectedParcel == null)
              Positioned(
                left: 12,
                right: isLandscape ? null : 12,
                bottom: 12,
                width: isLandscape ? 380 : null,
                child: SafeArea(
                  top: false,
                  child: _FleetVehicleInfoCard(
                    session: widget.session,
                    vehicle: selectedVehicle,
                    onClose: () =>
                        setState(() => _selectedFleetVehicleId = null),
                    onPause: () {
                      if (widget.session.setFleetVehiclePaused(
                        selectedVehicle.id,
                        !selectedVehicle.isIndividuallyPaused,
                      )) {
                        widget.onSessionChanged();
                        setState(() {});
                      }
                    },
                    onToggleRoute: selectedVehicle.assignedRouteId == null
                        ? null
                        : () {
                            final assignedRoute = widget
                                .session
                                .fleetManager
                                .routes
                                .where(
                                  (route) =>
                                      route.id ==
                                      selectedVehicle.assignedRouteId,
                                );
                            if (assignedRoute.isNotEmpty &&
                                widget.session.setFleetRouteActive(
                                  assignedRoute.first.id,
                                  !assignedRoute.first.isActive,
                                )) {
                              widget.onSessionChanged();
                              setState(() {});
                            }
                          },
                    onCancel: () {
                      FleetVehicleState? currentVehicle;
                      for (final vehicle
                          in widget.session.fleetManager.vehicles) {
                        if (vehicle.id == selectedVehicle.id) {
                          currentVehicle = vehicle;
                          break;
                        }
                      }
                      if (currentVehicle == null) return;
                      final carriedAmount = currentVehicle.cargoAmount;
                      final carriedProduct = currentVehicle.cargoCropId;
                      final hadCargo = currentVehicle.hasCargo;
                      if (!widget.session.cancelFleetVehicleRoutes(
                        currentVehicle.id,
                      )) {
                        return;
                      }
                      widget.onSessionChanged();
                      setState(() {});
                      final cargoMessage = hadCargo
                          ? ' Yük araçta kaldı: ${_itemName(carriedProduct!)} · $carriedAmount.'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Araç işleri iptal edildi.$cargoMessage',
                          ),
                        ),
                      );
                    },
                    onCancelQueued: (queueIndex) {
                      if (widget.session.cancelQueuedFleetRoute(
                        selectedVehicle.id,
                        queueIndex,
                      )) {
                        widget.onSessionChanged();
                        setState(() {});
                      }
                    },
                    onQueueRoute: (routeId) {
                      if (widget.session.queueFleetRoute(
                        selectedVehicle.id,
                        routeId,
                      )) {
                        widget.onSessionChanged();
                        setState(() {});
                      }
                    },
                    onService: () {
                      if (widget.session.serviceFleetVehicle(
                        selectedVehicle.id,
                      )) {
                        widget.onSessionChanged();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            if (_measureMode && _measureEnd != null)
              Positioned(
                left: 12,
                bottom:
                    selectedParcel == null &&
                        selectedPlot == null &&
                        selectedVehicle == null
                    ? 16
                    : (isLandscape ? 114 : 360),
                child: _MapStatusChip(
                  icon: Icons.straighten_rounded,
                  text: _formatDistance(
                    _measureStart!.distanceTo(_measureEnd!),
                  ),
                  onClose: () => setState(() {
                    _measureStart = null;
                    _measureEnd = null;
                  }),
                ),
              ),
            if (selectedParcel == null &&
                selectedPlot == null &&
                selectedVehicle == null)
              Positioned(
                left: 14,
                bottom: 18,
                child: _BottomMapToolsBar(
                  routeMode: _routeMode,
                  salesRouteMode: _salesRouteMode,
                  measureMode: _measureMode,
                  tutorialStep: tutorialStep,
                  onToggleRoute: () {
                    if (_salesRouteMode) {
                      setState(() {
                        _salesRouteMode = false;
                        _salesRouteStartPlotId = null;
                      });
                    } else if (tutorialStep == FarmTutorialStep.deliveryRoute) {
                      _beginSalesRouteDrawing();
                    } else {
                      setState(() {
                        _routeMode = !_routeMode;
                        _measureMode = false;
                        _routeStartParcelId = null;
                        _measureStart = null;
                        _measureEnd = null;
                      });
                    }
                  },
                  onToggleMeasure: () => setState(() {
                    _measureMode = !_measureMode;
                    _routeMode = false;
                    _routeStartParcelId = null;
                    _measureStart = null;
                    _measureEnd = null;
                  }),
                  onOpenLayers: _openLayerOptions,
                ),
              ),
            if (_zoom < 0.31)
              Positioned(
                left: 14,
                bottom:
                    selectedParcel == null &&
                        selectedPlot == null &&
                        selectedVehicle == null
                    ? 128
                    : (isLandscape ? 162 : 398),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEAF8F1DB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCFD2A4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 9, color: Color(0xFF82A85D)),
                      SizedBox(width: 6),
                      Text(
                        'Sahip olunan araziler',
                        style: TextStyle(
                          color: _mapInk,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 14,
              bottom:
                  selectedParcel == null &&
                      selectedPlot == null &&
                      selectedVehicle == null
                  ? 66
                  : (isLandscape ? 124 : 360),
              child: _MapScaleBar(zoom: _zoom),
            ),
          ],
        );
      },
    );
  }
}

class _TopActionBar extends StatelessWidget {
  const _TopActionBar({
    required this.balance,
    required this.onOpenResearch,
    required this.onOpenEquipment,
    required this.onBeginConstruction,
    required this.constructionActive,
    required this.onOpenManagement,
    required this.managementHighlighted,
    required this.onOpenWarehouse,
    required this.warehouseHighlighted,
    required this.warehouseStock,
    required this.onFocusSalesPoint,
    required this.salesHighlighted,
    required this.onSearch,
    required this.onOpenAnalytics,
    required this.onOpenAlmanac,
    required this.onOpenOperations,
  });

  final int balance;
  final VoidCallback onOpenResearch;
  final VoidCallback onOpenEquipment;
  final VoidCallback onBeginConstruction;
  final bool constructionActive;
  final VoidCallback onOpenManagement;
  final bool managementHighlighted;
  final VoidCallback onOpenWarehouse;
  final bool warehouseHighlighted;
  final int warehouseStock;
  final VoidCallback onFocusSalesPoint;
  final bool salesHighlighted;
  final VoidCallback onSearch;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenAlmanac;
  final VoidCallback onOpenOperations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BalancePill(balance: balance),
          const SizedBox(width: 6),
          _MapTopChip(
            icon: Icons.agriculture_rounded,
            label: 'İşletme',
            onTap: onOpenOperations,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.account_tree_rounded,
            label: 'Araştırma',
            onTap: onOpenResearch,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.storefront_rounded,
            label: 'Ekipman',
            onTap: onOpenEquipment,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.construction_rounded,
            label: constructionActive ? 'Arazi seç' : 'İnşaat',
            active: constructionActive,
            highlighted: constructionActive,
            onTap: onBeginConstruction,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.dashboard_customize_rounded,
            label: 'Yönetim',
            highlighted: managementHighlighted,
            onTap: onOpenManagement,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.inventory_2_rounded,
            label: 'Ambar · $warehouseStock',
            highlighted: warehouseHighlighted,
            onTap: onOpenWarehouse,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.storefront_rounded,
            label: 'Kasaba Pazarı',
            highlighted: salesHighlighted,
            onTap: onFocusSalesPoint,
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Koordinata git',
            onTap: onSearch,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.insights_rounded,
            label: 'Analitik',
            onTap: onOpenAnalytics,
          ),
          const SizedBox(width: 5),
          _MapTopChip(
            icon: Icons.auto_stories_rounded,
            label: 'Almanak',
            onTap: onOpenAlmanac,
          ),
        ],
      ),
    );
  }
}

class _MapTopChip extends StatelessWidget {
  const _MapTopChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF214D36) : const Color(0xF2FFF9E9),
      borderRadius: BorderRadius.circular(12),
      elevation: highlighted ? 6 : 2,
      shadowColor: highlighted
          ? const Color(0xFFFFC84F)
          : const Color(0x33000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFFFB02E)
                  : active
                  ? const Color(0xFF214D36)
                  : const Color(0xFFD6C99E),
              width: highlighted ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active
                    ? _mapGold
                    : (highlighted ? const Color(0xFFB57C00) : _mapInk),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : _mapInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomMapToolsBar extends StatelessWidget {
  const _BottomMapToolsBar({
    required this.routeMode,
    required this.salesRouteMode,
    required this.measureMode,
    required this.tutorialStep,
    required this.onToggleRoute,
    required this.onToggleMeasure,
    required this.onOpenLayers,
  });

  final bool routeMode;
  final bool salesRouteMode;
  final bool measureMode;
  final FarmTutorialStep tutorialStep;
  final VoidCallback onToggleRoute;
  final VoidCallback onToggleMeasure;
  final VoidCallback onOpenLayers;

  @override
  Widget build(BuildContext context) {
    final routeActive = routeMode || salesRouteMode;
    final routeHighlighted = tutorialStep == FarmTutorialStep.deliveryRoute;
    final routeLabel = salesRouteMode
        ? 'Rotayı İptal Et'
        : routeMode
        ? 'Hat Kapat'
        : tutorialStep == FarmTutorialStep.deliveryRoute
        ? 'Satış Rotası Çiz'
        : 'Hat Kur';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF9E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6C99E), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38192E1D),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockButton(
            icon: Icons.add_road_rounded,
            label: routeLabel,
            active: routeActive,
            highlighted: routeHighlighted,
            onTap: onToggleRoute,
          ),
          const SizedBox(width: 4),
          _DockButton(
            icon: Icons.straighten_rounded,
            label: measureMode ? 'Ölçümü Bitir' : 'Mesafe Ölç',
            active: measureMode,
            onTap: onToggleMeasure,
          ),
          const SizedBox(width: 4),
          _DockButton(
            icon: Icons.layers_rounded,
            label: 'Katmanlar',
            active: false,
            onTap: onOpenLayers,
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF214D36) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: highlighted
                ? Border.all(color: const Color(0xFFFFB02E), width: 1.8)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active
                    ? _mapGold
                    : (highlighted
                          ? const Color(0xFFB57C00)
                          : const Color(0xFF385E38)),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : _mapInk,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final formatted = balance.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF214D36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 17, color: _mapGold),
          const SizedBox(width: 5),
          Text(
            '$formatted ÇK',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, color: _mapInk, size: 21),
  );
}

class _InstructionPill extends StatelessWidget {
  const _InstructionPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xF2FFF8E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD6C99E)),
      boxShadow: const [BoxShadow(color: Color(0x33192E1D), blurRadius: 9)],
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF496D3C)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _mapInk,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FarmTutorialCoach extends StatelessWidget {
  const _FarmTutorialCoach({
    required this.step,
    required this.plot,
    required this.session,
    required this.onBegin,
    this.onOpenComic,
  });

  final FarmTutorialStep step;
  final CropPlotState? plot;
  final OpeningSession session;
  final VoidCallback onBegin;
  final VoidCallback? onOpenComic;

  @override
  Widget build(BuildContext context) {
    final job = plot?.activeJob;
    final snapshot = session.cropSnapshotForPlot(
      session.starterPlotId,
      DateTime.now(),
    );
    final (title, message, stepIndex) = switch (step) {
      FarmTutorialStep.story => (
        'AYLA USTA’NIN MİRASI: DEMİR MAHSUL',
        'Ayla Demirsoy ve dedenin emanetleri gün yüzüne çıktı: Takviyeli Kıyı 18 traktörü, ata tohumları ve Kuzey Tarlası hazır. Çizgi romanı incele ve vadiyi ayağa kaldır!',
        0,
      ),
      FarmTutorialStep.prepare => (
        '1 · TARLAYI HAZIRLA',
        job?.operation == FarmOperation.prepare
            ? 'Kültivatör tarlada çalışıyor. ${_formatRemaining(job!.completesAt.difference(DateTime.now()))} sonra ekim alanı hazır.'
            : 'Aşağıdaki parsel kartında “Tarlayı hazırla” düğmesine dokun. İş bitince gübreleme açılacak.',
        1,
      ),
      FarmTutorialStep.fertilize => (
        '2 · GÜBRELE',
        job?.operation == FarmOperation.fertilize
            ? 'Serpici tarlayı besliyor. İş tamamlanınca ekim adımına geçeceğiz.'
            : 'Toprağı iyileştirmek için parsel kartındaki “Gübrele” düğmesine dokun.',
        2,
      ),
      FarmTutorialStep.sow => (
        '3 · BUĞDAY EK',
        job?.operation == FarmOperation.sow
            ? 'Mibzer tohumu sıralara bırakıyor. Ekim bitince ürün büyümeye başlayacak.'
            : 'Parsel kartında buğdayı seçip “Ekim yap” düğmesine dokun. Tohum ücreti tarlanın alanına göre hesaplanır.',
        3,
      ),
      FarmTutorialStep.growth => (
        '4 · BÜYÜMEYİ İZLE',
        snapshot == null
            ? 'Ekin tarlada. Büyüme tamamlanınca hasat düğmesini göstereceğim.'
            : snapshot.isHarvestable
            ? 'Buğday olgunlaştı. Hasat için parsel kartındaki vurgulu düğmeye dokun.'
            : 'İlk öğretici ekiminde büyüme birkaç saniye sürer. Normal oyunda buğday ve mısır 6 dakikada olgunlaşır.',
        4,
      ),
      FarmTutorialStep.harvest => (
        '5 · HASAT ET',
        job?.operation == FarmOperation.harvest
            ? 'Biçerdöver çalışıyor. Ürün satılmadan ambara gidecek; satış için bir sonraki adımda hattı sen kuracaksın.'
            : 'Buğday hazır. Parsel kartındaki “Hasat et” düğmesiyle ürünü satış yapılmadan ambara gönder.',
        5,
      ),
      FarmTutorialStep.warehouse => (
        '6 · AMBARI AÇ',
        'Hasat satılmadı; ürünün ambar stoğunda bekliyor. Üstteki Ambar düğmesine dokun ve stoğu incele.',
        6,
      ),
      FarmTutorialStep.deliveryRoute => (
        '7 · SATIŞ HATTI KUR',
        'Önce Kasaba Pazarı işaretini bul. Vurgulanan “Satış rotası çiz” düğmesine dokun; sonra haritada sahip olduğun hasat tarlasını ve pazarı sırayla seçerek ilk hattı kendin oluştur.',
        7,
      ),
      FarmTutorialStep.delivery => (
        '8 · SEVKİYATI İZLE',
        'Hat çalışıyor. Kamyon ürünü pazara ulaştırınca satış bedeli bakiyene eklenecek; Ambar’dan stok ve araç yükünü izleyebilirsin.',
        8,
      ),
      FarmTutorialStep.shop => (
        '9 · EKİPMAN MAĞAZASI',
        'İlk satış tamamlandı. Üstteki vurgulu Ekipman düğmesine dokun; daha hızlı makineleri, fiyatlarını ve etkilerini incele.',
        9,
      ),
      FarmTutorialStep.management => (
        '10 · ÇİFTLİĞİ YÖNET',
        'Üstteki Yönetim düğmesi bütün tarlaların durumunu, ekili ürünü ve görevdeki araçları gösterir. Açınca rehber tamamlanır.',
        10,
      ),
      FarmTutorialStep.complete => ('', '', 10),
    };
    final totalSteps = 10;

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xF5FFF9E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: step == FarmTutorialStep.story
              ? const Color(0xFFCC9A3F)
              : const Color(0xFFD8C99A),
          width: step == FarmTutorialStep.story ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40152E20),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF214D36),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: _mapGold,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475847),
                    height: 1.2,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (step != FarmTutorialStep.story) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: stepIndex / totalSteps,
                      minHeight: 4,
                      color: const Color(0xFF6C984C),
                      backgroundColor: const Color(0xFFE6E3D5),
                    ),
                  ),
                ],
                if (step == FarmTutorialStep.story) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (onOpenComic != null)
                        SizedBox(
                          height: 32,
                          child: FilledButton.icon(
                            onPressed: onOpenComic,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: const Color(0xFFFFD166),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFFFD166),
                                width: 1.5,
                              ),
                            ),
                            icon: const Icon(Icons.auto_stories, size: 16),
                            label: const Text(
                              '📖 ÇİZGİ ROMANI OKU',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 32,
                        child: FilledButton.icon(
                          onPressed: onBegin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC84F),
                            foregroundColor: const Color(0xFF35270D),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 17),
                          label: const Text(
                            'TARLAYA GİT',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (onOpenComic != null) ...[
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onOpenComic,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.auto_stories,
                        size: 13,
                        color: Color(0xFF8A6D23),
                      ),
                      label: const Text(
                        'Ayla Usta’nın Çizgi Romanı',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFF8A6D23),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseInventorySheet extends StatelessWidget {
  const _WarehouseInventorySheet({
    required this.session,
    required this.isTutorialRouteStep,
    required this.onStartDeliveryRoute,
  });

  final OpeningSession session;
  final bool isTutorialRouteStep;
  final bool Function() onStartDeliveryRoute;

  @override
  Widget build(BuildContext context) {
    final fleet = session.fleetManager;
    final quantities = <String, int>{};
    final inTransit = <String, int>{};
    for (final batch in fleet.warehouseStock) {
      quantities.update(
        batch.cropId,
        (amount) => amount + batch.amount,
        ifAbsent: () => batch.amount,
      );
    }
    for (final vehicle in fleet.vehicles) {
      if (!vehicle.hasCargo) continue;
      quantities.update(
        vehicle.cargoCropId!,
        (amount) => amount + vehicle.cargoAmount,
        ifAbsent: () => vehicle.cargoAmount,
      );
      inTransit.update(
        vehicle.cargoCropId!,
        (amount) => amount + vehicle.cargoAmount,
        ifAbsent: () => vehicle.cargoAmount,
      );
    }
    final productIds = quantities.keys.toList()
      ..sort((left, right) => _cropName(left).compareTo(_cropName(right)));
    final totalInTransit = inTransit.values.fold<int>(0, (sum, n) => sum + n);
    final hasStock = fleet.totalWarehouseAmount > 0;
    final route = fleet.routes.where((item) => item.id == 'route_starter');
    final truckAssigned = fleet.vehicles.any(
      (item) =>
          item.truckType == TruckType.starter &&
          item.assignedRouteId == 'route_starter',
    );
    final routeReady = route.isNotEmpty && truckAssigned;
    final canConfigureRoute =
        hasStock && session.hasStarterTruck && !routeReady;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8BEA5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: _mapInk,
                    size: 24,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'AMBAR ENVANTERİ',
                      style: TextStyle(
                        color: _mapInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Text(
                    '${fleet.totalWarehouseAmount}/${fleet.warehouseCapacity} birim',
                    style: const TextStyle(
                      color: Color(0xFF536247),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fleet.warehouseCapacity <= 0
                      ? 0
                      : (fleet.totalWarehouseAmount / fleet.warehouseCapacity)
                            .clamp(0.0, 1.0),
                  minHeight: 7,
                  color: const Color(0xFF769A53),
                  backgroundColor: const Color(0xFFE3E0D3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  'Depoda ${fleet.totalWarehouseAmount} · araçlarda $totalInTransit · satılmamış ürün toplamı ${quantities.values.fold<int>(0, (sum, n) => sum + n)}',
                  style: const TextStyle(
                    color: Color(0xFF69705F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (productIds.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.grain_rounded, size: 28, color: _mapInk),
                      SizedBox(height: 5),
                      Text(
                        'Henüz satılmamış ürün yok.',
                        style: TextStyle(
                          color: _mapInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: productIds.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cropId = productIds[index];
                      final amount = quantities[cropId] ?? 0;
                      final transit = inTransit[cropId] ?? 0;
                      final unitPrice = session
                          .marketQuote(cropId)
                          .currentPrice;
                      final value =
                          (amount - transit) * unitPrice +
                          (transit * unitPrice).round();
                      final artwork = FarmItemCatalog.artworkFor(cropId);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        leading: artwork == null
                            ? const CircleAvatar(
                                backgroundColor: Color(0xFFE9E1CB),
                                child: Icon(
                                  Icons.inventory_rounded,
                                  color: _mapInk,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  artwork,
                                  width: 46,
                                  height: 42,
                                  fit: BoxFit.contain,
                                  cacheWidth: 100,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    width: 46,
                                    height: 42,
                                    child: Icon(
                                      Icons.inventory_rounded,
                                      color: _mapInk,
                                    ),
                                  ),
                                ),
                              ),
                        title: Text(
                          _cropName(cropId),
                          style: const TextStyle(
                            color: _mapInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          transit > 0
                              ? '$transit araçta · ${amount - transit} depoda'
                              : 'Depoda · tahmini değer ${_formatFarmCredits(value)} ÇK',
                          style: const TextStyle(fontSize: 9),
                        ),
                        trailing: Text(
                          '$amount',
                          style: const TextStyle(
                            color: _mapInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTutorialRouteStep
                      ? const Color(0xFFFFF0C8)
                      : const Color(0xFFEAF0E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isTutorialRouteStep
                        ? const Color(0xFFE9B949)
                        : const Color(0xFFD2DBC8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeReady ? 'SATIŞ HATTI ÇALIŞIYOR' : 'PAZARA SEVKİYAT',
                      style: const TextStyle(
                        color: _mapInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      routeReady
                          ? 'HAT PLANI · ${route.first.stops.first.name} → Kasaba Pazarı'
                          : 'HAT PLANI · Hasat tarlası → Kasaba Pazarı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF385B3E),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      routeReady
                          ? '${route.first.isOneShot ? 'Tek sevkiyat' : 'Sürekli tekrar'} · ${route.first.stops.first.targetCropId == null ? 'Ambar sırasındaki ürün' : FarmItemCatalog.nameFor(route.first.stops.first.targetCropId!)} · ${route.first.stops.first.loadAmountLimit == null ? 'araç kapasitesi kadar/sefer' : '${route.first.stops.first.loadAmountLimit} birim/sefer'}. Ürün pazara ulaştığında satılır.'
                          : 'Ürün ambarda bekliyor. Haritada satış rotasını kendin çiz: önce sahip olduğun hasat tarlasını, sonra Kasaba Pazarı işaretini seç.',
                      style: const TextStyle(
                        color: Color(0xFF536247),
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canConfigureRoute
                            ? () {
                                if (onStartDeliveryRoute()) {
                                  Navigator.of(context).pop();
                                }
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF214D36),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(42),
                        ),
                        icon: Icon(
                          routeReady
                              ? Icons.route_rounded
                              : Icons.add_road_rounded,
                          color: _mapGold,
                        ),
                        label: Text(
                          routeReady
                              ? 'HAT KURULU · SEVKİYAT SÜRÜYOR'
                              : 'HARİTADA SATIŞ ROTASI ÇİZ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (!canConfigureRoute && !routeReady)
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Hat kurmak için ambarda sevk edilecek ürün ve başlangıç kamyoneti gerekir.',
                          style: TextStyle(
                            color: Color(0xFF68715B),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovingFieldMachine extends StatelessWidget {
  const _MovingFieldMachine({
    required this.asset,
    required this.progress,
    required this.scale,
    required this.travel,
    required this.label,
    this.tractorAsset,
  });

  final String asset;
  final String? tractorAsset;
  final Animation<double> progress;
  final double scale;
  final double travel;
  final String label;

  Widget _machineView() {
    if (tractorAsset == null) {
      return Image.asset(
        asset,
        width: 82 * scale,
        height: 62 * scale,
        fit: BoxFit.contain,
        cacheWidth: 176,
        filterQuality: FilterQuality.medium,
      );
    }
    return SizedBox(
      width: 90 * scale,
      height: 72 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 23 * scale,
            child: Image.asset(
              asset,
              width: 56 * scale,
              height: 42 * scale,
              fit: BoxFit.contain,
              cacheWidth: 144,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned(
            top: 0,
            child: Image.asset(
              tractorAsset!,
              width: 54 * scale,
              height: 45 * scale,
              fit: BoxFit.contain,
              cacheWidth: 144,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Tooltip(message: label, child: _machineView());
    if (MediaQuery.of(context).disableAnimations) return child;
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final phase = progress.value * math.pi * 2;
        final point = Offset(
          math.cos(phase) * travel * 0.5,
          math.sin(phase) * travel * 0.23,
        );
        final tangent = Offset(-math.sin(phase), math.cos(phase) * 0.46);
        final heading = math.atan2(tangent.dy, tangent.dx) + math.pi / 2;
        return Transform.translate(
          offset: point,
          child: Transform.rotate(angle: heading, child: child),
        );
      },
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xF2FFF9E9),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFD6C99E)),
      boxShadow: const [BoxShadow(color: Color(0x44192E1D), blurRadius: 11)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: Icons.add_rounded,
          tooltip: 'Yakınlaştır',
          onTap: onZoomIn,
        ),
        _ZoomButton(
          icon: Icons.remove_rounded,
          tooltip: 'Uzaklaştır',
          onTap: onZoomOut,
        ),
        Container(height: 1, width: 30, color: const Color(0xFFD6C99E)),
        _ZoomButton(
          icon: Icons.my_location_rounded,
          tooltip: 'Başlangıç çiftliğine dön',
          onTap: onRecenter,
        ),
      ],
    ),
  );
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 20, color: _mapInk),
  );
}

class _ParcelInfoCard extends StatelessWidget {
  const _ParcelInfoCard({
    required this.parcel,
    required this.owned,
    required this.balance,
    required this.routeMode,
    required this.routeSelected,
    required this.onBuy,
    required this.onClose,
    required this.onSelectRoute,
  });

  final WorldMapParcel parcel;
  final bool owned;
  final int balance;
  final bool routeMode;
  final bool routeSelected;
  final VoidCallback onBuy;
  final VoidCallback onClose;
  final VoidCallback onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final typeName = _cropLabel(parcel.cropType);
    final money = parcel.price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final color = _cropColor(parcel.cropType);
    return Container(
      constraints: const BoxConstraints(maxHeight: 190),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF9FFF9EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9CAA0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55152E20),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: parcel.isHome ? const Color(0xFF28583D) : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  parcel.isHome
                      ? Icons.home_work_rounded
                      : _cropIcon(parcel.cropType),
                  size: 21,
                  color: parcel.isHome ? _mapGold : const Color(0xFF233C28),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mapInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      parcel.isHome
                          ? 'MERKEZ ÇİFTLİK'
                          : '$typeName · ${parcel.areaHectares.toStringAsFixed(1)} ha',
                      style: const TextStyle(
                        color: Color(0xFF6F765E),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: Color(0xFF819078),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ParcelStat(
                  icon: Icons.eco_rounded,
                  label: 'TOPRAK VERİMİ',
                  value: '${parcel.fertility}/100',
                ),
              ),
              Expanded(
                child: _ParcelStat(
                  icon: Icons.square_foot_rounded,
                  label: 'ALAN',
                  value: '${parcel.areaHectares.toStringAsFixed(2)} ha',
                ),
              ),
              Expanded(
                child: _ParcelStat(
                  icon: Icons.sell_rounded,
                  label: owned ? 'DURUM' : 'ARSA BEDELİ',
                  value: owned ? 'Sahipli' : '$money ÇK',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  owned
                      ? (routeMode
                            ? (routeSelected
                                  ? 'İlk nokta seçildi'
                                  : 'Lojistik hattına hazır')
                            : 'Arazi ağında kayıtlı')
                      : (balance >= parcel.price
                            ? 'Bütçen bu araziyi karşılıyor'
                            : 'Bütçeyi aşan arazi'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF626D58),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!owned)
                SizedBox(
                  height: 39,
                  child: FilledButton.icon(
                    onPressed: balance >= parcel.price ? onBuy : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC84F),
                      foregroundColor: const Color(0xFF35270D),
                      disabledBackgroundColor: const Color(0xFFDAD8CE),
                      disabledForegroundColor: const Color(0xFF77786F),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                    label: const Text(
                      'ARAZİYİ AL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
              else if (!routeMode)
                SizedBox(
                  height: 39,
                  child: OutlinedButton.icon(
                    onPressed: onSelectRoute,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF28583D),
                      side: const BorderSide(color: Color(0xFF93AA75)),
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_road_rounded, size: 16),
                    label: const Text(
                      'HAT SEÇ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF537344),
                  size: 21,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmPlotInfoCard extends StatelessWidget {
  const _FarmPlotInfoCard({
    required this.session,
    required this.plot,
    required this.selectedCropId,
    required this.now,
    required this.onClose,
    required this.onBuy,
    required this.onSelectCrop,
    required this.onPrepare,
    required this.onFertilize,
    required this.onPlant,
    required this.onHarvest,
    required this.onBale,
    required this.onSellBales,
    this.tutorialStep = FarmTutorialStep.complete,
  });

  final OpeningSession session;
  final CropPlotState plot;
  final String selectedCropId;
  final DateTime now;
  final VoidCallback onClose;
  final VoidCallback onBuy;
  final ValueChanged<String> onSelectCrop;
  final VoidCallback onPrepare;
  final VoidCallback onFertilize;
  final ValueChanged<String> onPlant;
  final VoidCallback onHarvest;
  final VoidCallback onBale;
  final VoidCallback onSellBales;
  final FarmTutorialStep tutorialStep;

  @override
  Widget build(BuildContext context) {
    final crop = OpeningCropCatalog.byId(selectedCropId)!;
    final isPasture = plot.use == CropPlotUse.pasture;
    final snapshot = session.cropSnapshotForPlot(plot.id, now);
    final seedCost = session.seedCostForPlot(plot, selectedCropId);
    final freeSeedOffset =
        plot.id == session.starterPlotId && session.freeInitialSeedsCount > 0
        ? math.min(seedCost, crop.seedCostCredits)
        : 0;
    final paidSeedCost = seedCost - freeSeedOffset;
    final preparationCost = session.scaledFieldCost(
      plot,
      OpeningSession.fieldPreparationCostPerThousandSquareMeters,
    );
    final harvestCost = session.harvestCostForPlot(plot);
    final harvestOutputQuantity = session.harvestOutputQuantityForPlot(
      plot.id,
      now,
    );
    final harvestStorageBlocked =
        session.fleetManager.remainingWarehouseCapacity < harvestOutputQuantity;
    final expectedHarvest = session.estimatedHarvestValueForPlot(
      plot.id,
      selectedCropId,
    );
    final expectedNet =
        expectedHarvest -
        paidSeedCost -
        (plot.isCultivated ? 0 : preparationCost) -
        harvestCost;
    final rotationMultiplier = plot.rotationYieldMultiplierFor(selectedCropId);
    final fertilizerCost = session.scaledFieldCost(
      plot,
      OpeningSession.fieldFertilizerCostPerThousandSquareMeters,
    );
    final harvestable = session.canHarvestCropOnPlot(plot.id, now);
    final tutorialActive =
        plot.id == session.starterPlotId &&
        tutorialStep != FarmTutorialStep.complete;
    final preparationTime = session.operationDurationFor(
      FarmOperation.prepare,
      plot.areaSquareMeters,
      tutorialFast: tutorialActive && tutorialStep == FarmTutorialStep.prepare,
    );
    final fertilizerTime = session.operationDurationFor(
      FarmOperation.fertilize,
      plot.areaSquareMeters,
      tutorialFast:
          tutorialActive && tutorialStep == FarmTutorialStep.fertilize,
    );
    final sowingTime = session.operationDurationFor(
      FarmOperation.sow,
      plot.areaSquareMeters,
      tutorialFast: tutorialActive && tutorialStep == FarmTutorialStep.sow,
    );
    final harvestTime = session.operationDurationFor(
      FarmOperation.harvest,
      plot.areaSquareMeters,
      tutorialFast: tutorialActive && tutorialStep == FarmTutorialStep.harvest,
    );
    final balingTime = session.operationDurationFor(
      FarmOperation.bale,
      plot.areaSquareMeters,
    );
    final status = _fieldStatus(session, plot, now);
    final equipmentCompatibilityIssue =
        session.equippedEquipmentCompatibilityIssue;
    final remainingGrass = plot.nextGrassCutAt == null
        ? Duration.zero
        : plot.nextGrassCutAt!.difference(now);
    final availableCrops = OpeningCropCatalog.all
        .where((item) => session.isCropUnlockedForFarm(item.id))
        .toList(growable: false);

    return Container(
      constraints: const BoxConstraints(maxHeight: 388),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xF9FFF9EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9CAA0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55152E20),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPasture
                        ? const Color(0xFF6F9E55)
                        : const Color(0xFF28583D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPasture ? Icons.grass_rounded : Icons.agriculture_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${isPasture ? 'ÇAYIR' : 'TARLA'} · $status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F765E),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _ParcelStat(
                    icon: Icons.square_foot_rounded,
                    label: 'ALAN',
                    value:
                        '${(plot.areaSquareMeters / 10000).toStringAsFixed(2)} ha',
                  ),
                ),
                Expanded(
                  child: _ParcelStat(
                    icon: Icons.terrain_rounded,
                    label: 'TOPRAK',
                    value: '${plot.soilConditionPoints}/100',
                  ),
                ),
                Expanded(
                  child: _ParcelStat(
                    icon: Icons.eco_rounded,
                    label: 'UYGUNLUK',
                    value: isPasture
                        ? 'Mera'
                        : '${(plot.suitabilityForCrop(selectedCropId) * 100).round()}%',
                  ),
                ),
              ],
            ),
            if (!isPasture) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0E2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Münavebe etkisi · ${plot.recentCropFamilies.isEmpty ? 'İlk ekim: temel verim' : plot.recentCropFamilies.take(2).map((family) => switch (family) {
                          CropFamily.grain => 'tahıl',
                          CropFamily.oilseed => 'yağlı tohum',
                          CropFamily.rootTuber => 'kök/yumru',
                          CropFamily.legume => 'baklagil',
                        }).join(' → ')} · seçili ürün verimi %${(rotationMultiplier * 100).round()}',
                  style: const TextStyle(
                    color: Color(0xFF385B3E),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            if (equipmentCompatibilityIssue != null) ...[
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8DF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2A18C)),
                ),
                child: Text(
                  equipmentCompatibilityIssue,
                  style: const TextStyle(
                    color: Color(0xFF963D2B),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!plot.isOwned)
              _FarmActionButton(
                icon: Icons.shopping_bag_rounded,
                label:
                    'ARAZİYİ AL · ${_formatFarmCredits(plot.purchaseCostCredits)} ÇK',
                enabled: session.canBuyPlot(plot.id),
                onPressed: onBuy,
              )
            else if (plot.activeJob != null) ...[
              _FarmWorkOrderPanel(plot: plot, now: now),
            ] else if (isPasture) ...[
              Text(
                plot.readyGrassBales > 0
                    ? '${plot.readyGrassBales} balya hazır · satış ${_formatFarmCredits(plot.readyGrassBales * OpeningSession.baleSalePrice)} ÇK'
                    : remainingGrass > Duration.zero
                    ? 'Ot yeniden büyüyor · ${_formatRemaining(remainingGrass)}'
                    : '${math.max(1, (plot.areaSquareMeters / 1000).floor())} balya biçmeye hazır',
                style: const TextStyle(
                  color: _mapInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (plot.readyGrassBales > 0)
                _FarmActionButton(
                  icon: Icons.sell_rounded,
                  label:
                      'BALYALARI SAT · +${_formatFarmCredits(plot.readyGrassBales * OpeningSession.baleSalePrice)} ÇK',
                  enabled: true,
                  onPressed: onSellBales,
                )
              else
                _FarmActionButton(
                  icon: Icons.grass_rounded,
                  label: remainingGrass > Duration.zero
                      ? 'OTUN BÜYÜMESİNİ BEKLE'
                      : 'BİÇ VE BALYALA · ${_formatFarmCredits(session.scaledFieldCost(plot, OpeningSession.pastureBalingCostPerThousandSquareMeters))} ÇK · ${_formatRemaining(balingTime)}',
                  enabled: session.canBalePasturePlot(plot.id, now),
                  onPressed: onBale,
                ),
            ] else if (plot.hasActiveCrop) ...[
              if (snapshot != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: snapshot.growthProgress.clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE1E4D6),
                    color: const Color(0xFF6B9D4A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  snapshot.isHarvestable
                      ? 'Hasat hazır · yaklaşık ${_formatFarmCredits(snapshot.harvestYield.round())} ÇK brüt'
                      : '${_cropName(selectedCropId)} büyüyor · ${(snapshot.growthProgress * 100).round()}% · ${_formatRemaining(Duration(microseconds: ((1 - snapshot.growthProgress) * snapshot.cycle.crop.fullGrowthDuration.inMicroseconds).round()))} kaldı · ${_formatFarmCredits(snapshot.harvestYield.round())} ÇK tahmini',
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (snapshot.isHarvestable) ...[
                  const SizedBox(height: 6),
                  _FarmActionButton(
                    icon: Icons.agriculture_rounded,
                    label: harvestable
                        ? 'HASAT ET · AMBARA GÖNDER · ${_formatFarmCredits(harvestCost)} ÇK · ${_formatRemaining(harvestTime)}'
                        : harvestStorageBlocked
                        ? 'DEPO YERİ YETERSİZ · ÖNCE SEVK ET'
                        : 'HASAT GİDERİ İÇİN BAKİYE YETERSİZ',
                    enabled: harvestable,
                    onPressed: onHarvest,
                    highlighted:
                        tutorialActive &&
                        tutorialStep == FarmTutorialStep.harvest,
                  ),
                ],
              ],
            ] else ...[
              if (plot.isCultivated) ...[
                Row(
                  children: [
                    const Icon(Icons.grain_rounded, size: 17, color: _mapInk),
                    const SizedBox(width: 7),
                    Expanded(
                      child: DropdownButton<String>(
                        value:
                            availableCrops.any(
                              (item) => item.id == selectedCropId,
                            )
                            ? selectedCropId
                            : availableCrops.first.id,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final item in availableCrops)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(_cropName(item.id)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) onSelectCrop(value);
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  'Beklenen brüt ${_formatFarmCredits(expectedHarvest)} ÇK · net yaklaşık ${_formatFarmCredits(expectedNet)} ÇK (gübre hariç)',
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Hazırlık ${_formatFarmCredits(plot.isCultivated ? 0 : preparationCost)} · gübre ${_formatFarmCredits(fertilizerCost)} · tohum ${_formatFarmCredits(paidSeedCost)} · hasat ${_formatFarmCredits(harvestCost)} ÇK',
                  style: const TextStyle(
                    color: Color(0xFF6F765E),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                _FarmActionButton(
                  icon: Icons.south_rounded,
                  label:
                      'EKİM YAP · ${_formatFarmCredits(paidSeedCost)} ÇK · ${_formatRemaining(sowingTime)}',
                  enabled: session.canPlantCropOnPlot(plot.id, selectedCropId),
                  onPressed: () => onPlant(selectedCropId),
                  highlighted:
                      tutorialActive && tutorialStep == FarmTutorialStep.sow,
                ),
              ] else ...[
                Text(
                  'Ekim öncesi tarla hazırlığı ${_formatFarmCredits(preparationCost)} ÇK. Hasatta ürün ambara gider, gelir araçla satışta oluşur.',
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                _FarmActionButton(
                  icon: Icons.agriculture_rounded,
                  label:
                      'TARLAYI HAZIRLA · ${_formatFarmCredits(preparationCost)} ÇK · ${_formatRemaining(preparationTime)}',
                  enabled: session.canCultivatePlot(plot.id),
                  onPressed: onPrepare,
                  highlighted:
                      tutorialActive &&
                      tutorialStep == FarmTutorialStep.prepare,
                ),
              ],
              if (!plot.hasActiveCrop &&
                  !plot.hasActiveJob &&
                  plot.soilConditionPoints <
                      OpeningSession.soilConditionMaximumPoints) ...[
                const SizedBox(height: 5),
                _FarmActionButton(
                  icon: Icons.water_drop_rounded,
                  label:
                      'GÜBRELE · +3 TOPRAK · ${_formatFarmCredits(session.scaledFieldCost(plot, OpeningSession.fieldFertilizerCostPerThousandSquareMeters))} ÇK · ${_formatRemaining(fertilizerTime)}',
                  enabled: session.canFertilizePlot(plot.id),
                  onPressed: onFertilize,
                  outlined: true,
                  highlighted:
                      tutorialActive &&
                      tutorialStep == FarmTutorialStep.fertilize,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FleetVehicleInfoCard extends StatelessWidget {
  const _FleetVehicleInfoCard({
    required this.session,
    required this.vehicle,
    required this.onClose,
    required this.onPause,
    required this.onToggleRoute,
    required this.onCancel,
    required this.onCancelQueued,
    required this.onQueueRoute,
    required this.onService,
  });

  final OpeningSession session;
  final FleetVehicleState vehicle;
  final VoidCallback onClose;
  final VoidCallback onPause;
  final VoidCallback? onToggleRoute;
  final VoidCallback onCancel;
  final ValueChanged<int> onCancelQueued;
  final ValueChanged<String> onQueueRoute;
  final VoidCallback onService;

  @override
  Widget build(BuildContext context) {
    final fleet = session.fleetManager;
    final route = fleet.routes.where(
      (candidate) => candidate.id == vehicle.assignedRouteId,
    );
    final routeName = route.isEmpty ? 'Atanmış rota yok' : route.first.name;
    final routePaused = route.isNotEmpty && !route.first.isActive;
    final status = routePaused
        ? 'Hat tüm araçlarda duraklatıldı'
        : switch (vehicle.status) {
            VehicleStatus.idle => 'Bekliyor',
            VehicleStatus.traveling => 'Yolda',
            VehicleStatus.paused => 'Duraklatıldı',
            VehicleStatus.loading => 'Yük alıyor',
            VehicleStatus.unloading => 'Yük boşaltıyor',
            VehicleStatus.divertingToSell => 'Satış noktasına yöneliyor',
            VehicleStatus.waitingForSpace => 'Depoda yer bekliyor',
            VehicleStatus.outOfFuel => 'Yakıtı bitti',
            VehicleStatus.serviceDue => 'Bakım gerekiyor',
          };
    final queuedRoutes = vehicle.queuedRouteIds
        .asMap()
        .entries
        .map((entry) {
          final candidates = fleet.routes.where(
            (candidate) => candidate.id == entry.value,
          );
          return (
            index: entry.key,
            name: candidates.isEmpty ? 'Silinmiş rota' : candidates.first.name,
          );
        })
        .toList(growable: false);
    final availableRoutes = fleet.routes
        .where((candidate) => candidate.stops.length >= 2)
        .toList(growable: false);
    final hasWork =
        vehicle.assignedRouteId != null || vehicle.queuedRouteIds.isNotEmpty;
    final workSummary = [
      if (vehicle.assignedRouteId != null) 'etkin rota',
      if (vehicle.queuedRouteIds.isNotEmpty)
        '${vehicle.queuedRouteIds.length} kuyruktaki sefer',
    ].join(' ve ');
    final isPaused = vehicle.isIndividuallyPaused;
    final serviceCost = fleet.serviceCostFor(vehicle);

    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xF9FFF9EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9CAA0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55152E20),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF28583D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.truckType.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$status · $routeName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F765E),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ParcelStat(
                    icon: Icons.scale_rounded,
                    label: 'KAPASİTE',
                    value: '${vehicle.effectiveCapacity} birim',
                  ),
                ),
                Expanded(
                  child: _ParcelStat(
                    icon: Icons.speed_rounded,
                    label: 'HIZ',
                    value: '${vehicle.effectiveSpeed.round()} km/sa',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _MeterRow(
              label: 'Yakıt',
              value: vehicle.fuelLevel / 100,
              trailing: '${vehicle.fuelLevel.round()}%',
            ),
            const SizedBox(height: 5),
            _MeterRow(
              label: 'Aşınma',
              value: vehicle.wearPercent / 100,
              trailing: '${vehicle.wearPercent.round()}%',
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                vehicle.hasCargo
                    ? 'Araç yükü · ${_itemName(vehicle.cargoCropId!)} · ${vehicle.cargoAmount}/${vehicle.effectiveCapacity} · %${(vehicle.cargoQuality * 100).round()} kalite'
                    : 'Araçta yük yok · ${vehicle.remainingCapacity} birim boş kapasite',
                style: const TextStyle(
                  color: Color(0xFF385B3E),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (vehicle.hasCargo) ...[
              const SizedBox(height: 4),
              const Text(
                'İş iptal edilirse yük ambara aktarılmaz; araçta kalır.',
                style: TextStyle(
                  color: Color(0xFF77613A),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (queuedRoutes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'KUYRUKTAKİ SEFERLER',
                style: TextStyle(
                  color: Color(0xFF657253),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
              for (final queued in queuedRoutes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(
                    Icons.route_rounded,
                    size: 17,
                    color: Color(0xFF28583D),
                  ),
                  title: Text(
                    queued.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Bu seferi kuyruktan çıkar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onCancelQueued(queued.index),
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
                ),
            ],
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (hasWork && !routePaused)
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 17,
                    ),
                    label: Text(isPaused ? 'Aracı sürdür' : 'Aracı duraklat'),
                  ),
                if (onToggleRoute != null)
                  OutlinedButton.icon(
                    onPressed: onToggleRoute,
                    icon: Icon(
                      routePaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 17,
                    ),
                    label: Text(
                      routePaused
                          ? 'Rotayı tüm araçlarda sürdür'
                          : 'Rotayı tüm araçlarda duraklat',
                    ),
                  ),
                if (availableRoutes.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Araca sefer ekle',
                    onSelected: onQueueRoute,
                    itemBuilder: (context) => availableRoutes
                        .map(
                          (candidate) => PopupMenuItem<String>(
                            value: candidate.id,
                            child: Text(candidate.name),
                          ),
                        )
                        .toList(growable: false),
                    child: const Chip(
                      avatar: Icon(Icons.playlist_add_rounded, size: 16),
                      label: Text('Sefer ekle'),
                    ),
                  ),
                if (vehicle.fuelLevel < 80 || vehicle.wearPercent > 20)
                  OutlinedButton.icon(
                    onPressed: session.farmCredits >= serviceCost
                        ? onService
                        : null,
                    icon: const Icon(Icons.build_circle_outlined, size: 16),
                    label: Text(
                      'Bakım · ${_formatFarmCredits(serviceCost)} ÇK',
                    ),
                  ),
                if (hasWork)
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Araç işlerini iptal et?'),
                          content: Text(
                            '$workSummary iptal edilecek. '
                            '${vehicle.hasCargo ? 'Araçtaki ${_itemName(vehicle.cargoCropId!)} yükü (${vehicle.cargoAmount}) araçta kalacak ve ambara aktarılmayacak.' : 'Araçta taşınan yük varsa araçta kalacak.'} '
                            'Bu seferleri iptal etmek istediğine emin misin?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('VAZGEÇ'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF9B3F2D),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('İŞLERİ İPTAL ET'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) onCancel();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF9B3F2D),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('İşleri iptal et'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmWorkOrderPanel extends StatelessWidget {
  const _FarmWorkOrderPanel({required this.plot, required this.now});

  final CropPlotState plot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final job = plot.activeJob!;
    final equipment = FarmEquipmentCatalog.byId(job.equipmentId);
    final remaining = job.completesAt.difference(now);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFAABD91)),
      ),
      child: Row(
        children: [
          Image.asset(
            FarmEquipmentCatalog.byId(job.equipmentId)?.imageAsset ??
                job.operation.iconAsset,
            width: 72,
            height: 60,
            fit: BoxFit.contain,
            cacheWidth: 192,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job.operation.label.toUpperCase()} SÜRÜYOR',
                  style: const TextStyle(
                    color: Color(0xFF537344),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  equipment?.name ?? 'Çiftlik makinesi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: job.progressAt(now),
                    minHeight: 6,
                    color: const Color(0xFF6C984C),
                    backgroundColor: const Color(0xFFD6DECC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining > Duration.zero
                      ? 'Tamamlanmasına ${_formatRemaining(remaining)}'
                      : 'Sonuçlar işleniyor…',
                  style: const TextStyle(
                    color: Color(0xFF4D5E48),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmActionButton extends StatelessWidget {
  const _FarmActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.outlined = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool outlined;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 38,
    child: outlined
        ? OutlinedButton.icon(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: highlighted
                    ? const Color(0xFFFFA91F)
                    : const Color(0xFF8DA47B),
                width: highlighted ? 2.5 : 1,
              ),
            ),
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          )
        : FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC84F),
              foregroundColor: const Color(0xFF35270D),
              disabledBackgroundColor: const Color(0xFFDAD8CE),
              disabledForegroundColor: const Color(0xFF77786F),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: highlighted
                  ? const BorderSide(color: Color(0xFFFFA91F), width: 2.5)
                  : null,
              elevation: highlighted ? 4 : 0,
              shadowColor: highlighted ? const Color(0xFFFFB02E) : null,
            ),
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
  );
}

enum _LogisticsStoreTab { trucks, trailers }

class _LogisticsStorePage extends StatefulWidget {
  const _LogisticsStorePage({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  State<_LogisticsStorePage> createState() => _LogisticsStorePageState();
}

class _LogisticsStorePageState extends State<_LogisticsStorePage> {
  _LogisticsStoreTab _tab = _LogisticsStoreTab.trucks;
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final fleet = widget.session.fleetManager;
    final trailerVehicles = fleet.vehicles
        .where((vehicle) => vehicle.truckType.acceptsTrailer)
        .toList(growable: false);
    final selectedVehicle = trailerVehicles.where(
      (vehicle) => vehicle.id == _selectedVehicleId,
    );
    final vehicleId = selectedVehicle.isNotEmpty
        ? _selectedVehicleId
        : trailerVehicles.isEmpty
        ? null
        : trailerVehicles.first.id;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SegmentedButton<_LogisticsStoreTab>(
            segments: const [
              ButtonSegment(
                value: _LogisticsStoreTab.trucks,
                icon: Icon(Icons.local_shipping_rounded),
                label: Text('Kamyonlar ve tırlar'),
              ),
              ButtonSegment(
                value: _LogisticsStoreTab.trailers,
                icon: Icon(Icons.rv_hookup_rounded),
                label: Text('Dorseler'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (selection) =>
                setState(() => _tab = selection.first),
          ),
        ),
        if (_tab == _LogisticsStoreTab.trailers) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 9, 15, 5),
            child: trailerVehicles.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dorse takmak için önce ağır sınıf bir tır satın al.',
                      style: TextStyle(
                        color: Color(0xFF7C5F30),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: vehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Dorse takılacak araç',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final vehicle in trailerVehicles)
                        DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(
                            '${vehicle.truckType.name} · ${vehicle.id}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedVehicleId = value),
                  ),
          ),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 18),
            itemCount: _tab == _LogisticsStoreTab.trucks
                ? TruckType.values
                      .where((type) => type != TruckType.starter)
                      .length
                : TrailerType.values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              if (_tab == _LogisticsStoreTab.trucks) {
                final types = TruckType.values
                    .where((type) => type != TruckType.starter)
                    .toList(growable: false);
                final type = types[index];
                final count = fleet.vehicles
                    .where((vehicle) => vehicle.truckType == type)
                    .length;
                final requirement = type.requiredTechnologyId;
                final missingResearch =
                    requirement != null &&
                    !widget.session.hasResearch(requirement);
                final canBuy =
                    !missingResearch &&
                    widget.session.farmCredits >= type.purchaseCostCredits;
                return _LogisticsProductCard(
                  imageAsset: type.imageAsset,
                  title: type.name,
                  category: 'FİLODA $count ARAÇ',
                  details: [
                    '${type.capacity} birim yük',
                    '${type.speed.toStringAsFixed(0)} km/sa',
                  ],
                  price: type.purchaseCostCredits,
                  actionLabel: missingResearch
                      ? 'ARAŞTIRMA GEREKLİ · $requirement'
                      : canBuy
                      ? 'SATIN AL'
                      : 'BAKİYE YETERSİZ',
                  enabled: canBuy,
                  researchLabel: missingResearch
                      ? _technologyName(requirement)
                      : null,
                  onPressed: () {
                    if (widget.session.buyTruck(type)) {
                      widget.onChanged();
                      setState(() {});
                    }
                  },
                );
              }

              final type = TrailerType.values[index];
              final vehicle = vehicleId == null
                  ? null
                  : trailerVehicles.firstWhere((item) => item.id == vehicleId);
              final attached = vehicle?.trailerType == type;
              final missing = type.requiredTechnologyIds
                  .where((id) => !widget.session.hasResearch(id))
                  .toList(growable: false);
              final compatible = vehicle != null;
              final canBuy =
                  compatible &&
                  missing.isEmpty &&
                  widget.session.canBuyTrailer(type, vehicleId!);
              return _LogisticsProductCard(
                imageAsset: type.imageAsset,
                title: type.name,
                category: attached ? 'SEÇİLİ ARACA TAKILI' : 'DORSE',
                details: [
                  '+${type.capacityBonus} birim kapasite',
                  'Hız ×${type.speedMultiplier.toStringAsFixed(2)}',
                ],
                price: type.purchaseCostCredits,
                actionLabel: attached
                    ? 'TAKILI'
                    : !compatible
                    ? 'DORSE UYUMLU TIR GEREK'
                    : missing.isNotEmpty
                    ? 'ARAŞTIRMA GEREKLİ'
                    : canBuy
                    ? 'SATIN AL VE TAK'
                    : widget.session.farmCredits < type.purchaseCostCredits
                    ? 'BAKİYE YETERSİZ'
                    : 'ZATEN TAKILI',
                enabled: canBuy,
                researchLabel: missing.isEmpty
                    ? null
                    : missing.map(_technologyName).join(' · '),
                onPressed: () {
                  if (widget.session.buyTrailer(type, vehicleId!)) {
                    widget.onChanged();
                    setState(() {});
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LogisticsProductCard extends StatelessWidget {
  const _LogisticsProductCard({
    required this.imageAsset,
    required this.title,
    required this.category,
    required this.details,
    required this.price,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
    this.researchLabel,
  });

  final String imageAsset;
  final String title;
  final String category;
  final List<String> details;
  final int price;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final String? researchLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF3),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFDDD3B6)),
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 82,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8D8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(imageAsset, fit: BoxFit.contain, cacheWidth: 160),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Color(0xFF718261),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _mapInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  for (final detail in details)
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFF596B51),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              if (researchLabel != null)
                Text(
                  'Açmak için: $researchLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9B6E29),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatFarmCredits(price)} ÇK',
                      style: const TextStyle(
                        color: _mapInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: enabled ? onPressed : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      backgroundColor: const Color(0xFFFFC84F),
                      foregroundColor: const Color(0xFF35270D),
                      disabledBackgroundColor: const Color(0xFFE2DED1),
                      disabledForegroundColor: const Color(0xFF77786F),
                      textStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _technologyName(String id) =>
    TechTreeCatalog.byId(id)?.name ?? 'Araştırma $id';

class _EquipmentStoreSheet extends StatefulWidget {
  const _EquipmentStoreSheet({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  State<_EquipmentStoreSheet> createState() => _EquipmentStoreSheetState();
}

class _EquipmentStoreSheetState extends State<_EquipmentStoreSheet> {
  _EquipmentStorePage _page = _EquipmentStorePage.vehicles;
  String _categoryId = 'tractors';
  String? _subcategory;
  String? _brand;
  _EquipmentStoreSort _sort = _EquipmentStoreSort.recommended;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FarmEquipment> _itemsForPage() {
    final catalog = FarmEquipmentCatalog.all;
    Iterable<FarmEquipment> items = catalog;
    if (_page == _EquipmentStorePage.vehicles ||
        _page == _EquipmentStorePage.used ||
        _page == _EquipmentStorePage.garage) {
      items = FarmEquipmentCatalog.forShopCategory(_categoryId);
    }
    if (_page == _EquipmentStorePage.garage) {
      items = items.where((item) => widget.session.isEquipmentOwned(item.id));
    } else if (_page == _EquipmentStorePage.used) {
      final usedIds = {
        for (var index = 0; index < catalog.length; index++)
          if (catalog[index].purchasePrice > 0 && index % 2 == 0)
            catalog[index].id,
      };
      final categoryUsed = items.where((item) => usedIds.contains(item.id));
      items = categoryUsed.isEmpty
          ? items.where((item) => item.purchasePrice > 0)
          : categoryUsed;
    }
    if (_page == _EquipmentStorePage.brands && _brand != null) {
      items = items.where((item) => item.manufacturer == _brand);
    }
    if (_subcategory != null &&
        (_page == _EquipmentStorePage.vehicles ||
            _page == _EquipmentStorePage.used ||
            _page == _EquipmentStorePage.garage)) {
      items = items.where((item) => _labelForSubcategory(item) == _subcategory);
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where(
        (item) =>
            item.name.toLowerCase().contains(query) ||
            item.manufacturer.toLowerCase().contains(query) ||
            item.subcategory.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query),
      );
    }
    final result = items.toList();
    switch (_sort) {
      case _EquipmentStoreSort.recommended:
        result.sort((a, b) {
          final aOwned = widget.session.isEquipmentOwned(a.id) ? 1 : 0;
          final bOwned = widget.session.isEquipmentOwned(b.id) ? 1 : 0;
          final owned = bOwned.compareTo(aOwned);
          return owned != 0
              ? owned
              : a.purchasePrice.compareTo(b.purchasePrice);
        });
      case _EquipmentStoreSort.priceLow:
        result.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
      case _EquipmentStoreSort.priceHigh:
        result.sort((a, b) => b.purchasePrice.compareTo(a.purchasePrice));
      case _EquipmentStoreSort.fastest:
        result.sort((a, b) => b.workRateRating.compareTo(a.workRateRating));
      case _EquipmentStoreSort.power:
        result.sort(
          (a, b) => b.displayHorsepower.compareTo(a.displayHorsepower),
        );
    }
    return result;
  }

  String _labelForSubcategory(FarmEquipment item) =>
      item.subcategory.isEmpty ? 'Kademe ${item.tier}' : item.subcategory;

  @override
  Widget build(BuildContext context) {
    final items = _page == _EquipmentStorePage.logistics
        ? const <FarmEquipment>[]
        : _itemsForPage();
    final height = MediaQuery.sizeOf(context).height * 0.94;
    final category = farmEquipmentShopCategories.firstWhere(
      (item) => item.id == _categoryId,
    );
    final categoryItems = FarmEquipmentCatalog.forShopCategory(_categoryId);
    final subcategories =
        categoryItems.map(_labelForSubcategory).toSet().toList()..sort();
    final brands =
        FarmEquipmentCatalog.all
            .map((item) => item.manufacturer)
            .toSet()
            .toList()
          ..sort();
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 7),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF315A3F),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFFFFD36A),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVA PAZARI',
                        style: TextStyle(
                          color: _mapInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        'Makine, ekipman ve lojistik filosu',
                        style: TextStyle(
                          color: Color(0xFF68725F),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5CB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_formatFarmCredits(widget.session.farmCredits)} ÇK',
                    style: const TextStyle(
                      color: _mapInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final page in _EquipmentStorePage.values) _pageChip(page),
              ],
            ),
          ),
          if (_page == _EquipmentStorePage.vehicles ||
              _page == _EquipmentStorePage.used ||
              _page == _EquipmentStorePage.garage) ...[
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                itemCount: farmEquipmentShopCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final entry = farmEquipmentShopCategories[index];
                  final count = FarmEquipmentCatalog.forShopCategory(entry.id)
                      .length;
                  return _categoryChip(entry, count);
                },
              ),
            ),
            _categoryBanner(category, categoryItems.length),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _subcategoryChip('Tümü', null),
                  for (final name in subcategories)
                    _subcategoryChip(name, name),
                ],
              ),
            ),
          ] else if (_page == _EquipmentStorePage.brands) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 3, 14, 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ÜRETİCİYE GÖRE GÖRÜNTÜLE',
                  style: TextStyle(
                    color: Color(0xFF65745D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _brandChip('Tüm üreticiler', null),
                  for (final brand in brands) _brandChip(brand, brand),
                ],
              ),
            ),
          ],
          if (_page != _EquipmentStorePage.packs &&
              _page != _EquipmentStorePage.logistics)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Makine, marka veya özellik ara',
                          hintStyle: const TextStyle(fontSize: 10),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 17,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                  ),
                                ),
                          filled: true,
                          fillColor: const Color(0xFFFFFCF4),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8CEB7),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8CEB7),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE7D6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_EquipmentStoreSort>(
                        value: _sort,
                        icon: const Icon(Icons.sort_rounded, size: 15),
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: _EquipmentStoreSort.recommended,
                            child: Text('Önerilen'),
                          ),
                          DropdownMenuItem(
                            value: _EquipmentStoreSort.priceLow,
                            child: Text('Ucuzdan'),
                          ),
                          DropdownMenuItem(
                            value: _EquipmentStoreSort.priceHigh,
                            child: Text('Pahalıdan'),
                          ),
                          DropdownMenuItem(
                            value: _EquipmentStoreSort.fastest,
                            child: Text('En hızlı'),
                          ),
                          DropdownMenuItem(
                            value: _EquipmentStoreSort.power,
                            child: Text('Güç'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _page == _EquipmentStorePage.logistics
                ? _LogisticsStorePage(
                    session: widget.session,
                    onChanged: () {
                      setState(() {});
                      widget.onChanged();
                    },
                  )
                : _page == _EquipmentStorePage.packs
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                    itemCount: _shopBundles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _EquipmentBundleCard(
                      bundle: _shopBundles[index],
                      session: widget.session,
                      onChanged: () {
                        setState(() {});
                        widget.onChanged();
                      },
                    ),
                  )
                : items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        _page == _EquipmentStorePage.garage
                            ? 'Bu kategoride henüz makinen yok.'
                            : 'Bu aramayla eşleşen makine bulunamadı.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B735F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1320
                          ? 3
                          : constraints.maxWidth >= 850
                          ? 2
                          : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 185,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _EquipmentStoreCard(
                          item: items[index],
                          session: widget.session,
                          usedOffer: _page == _EquipmentStorePage.used,
                          onChanged: () {
                            setState(() {});
                            widget.onChanged();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pageChip(_EquipmentStorePage page) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      avatar: Icon(page.icon, size: 14),
      label: Text(page.label),
      selected: _page == page,
      onSelected: (_) => setState(() {
        _page = page;
        _brand = null;
        _subcategory = null;
      }),
      labelStyle: TextStyle(
        color: _page == page ? Colors.white : _mapInk,
        fontWeight: FontWeight.w900,
        fontSize: 9,
      ),
      selectedColor: const Color(0xFF315A3F),
      backgroundColor: const Color(0xFFECE7D6),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: _page == page
            ? const Color(0xFF315A3F)
            : const Color(0xFFD6CDAE),
      ),
    ),
  );

  Widget _categoryChip(FarmEquipmentShopCategory category, int count) =>
      Padding(
        padding: const EdgeInsets.only(right: 1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _categoryId = category.id;
            _subcategory = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 116,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: _categoryId == category.id
                  ? const Color(0xFFDDE8D7)
                  : const Color(0xFFFFFCF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _categoryId == category.id
                    ? const Color(0xFF65905C)
                    : const Color(0xFFDED5BF),
                width: _categoryId == category.id ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 43,
                  height: 46,
                  child: Image.asset(
                    category.iconAsset,
                    fit: BoxFit.contain,
                    cacheWidth: 110,
                    filterQuality: FilterQuality.low,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 8,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$count model',
                        style: const TextStyle(
                          color: Color(0xFF68725F),
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _categoryBanner(FarmEquipmentShopCategory category, int count) =>
      Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF315A3F),
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF315A3F), Color(0xFF243E31)],
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 57,
              child: Image.asset(
                category.iconAsset,
                fit: BoxFit.contain,
                cacheWidth: 160,
                filterQuality: FilterQuality.medium,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.label.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFFD36A),
                      fontSize: 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    category.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE5E8DC),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$count\nMAKİNE',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _subcategoryChip(String label, String? selected) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: ChoiceChip(
      label: Text(label),
      selected: _subcategory == selected,
      onSelected: (_) => setState(() => _subcategory = selected),
      labelStyle: TextStyle(
        color: _subcategory == selected ? Colors.white : _mapInk,
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: const Color(0xFF6B8A57),
      backgroundColor: const Color(0xFFECE7D6),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: _subcategory == selected
            ? const Color(0xFF6B8A57)
            : const Color(0xFFD6CDAE),
      ),
    ),
  );

  Widget _brandChip(String label, String? brand) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: _brand == brand,
      onSelected: (_) => setState(() => _brand = brand),
      labelStyle: TextStyle(
        color: _brand == brand ? Colors.white : _mapInk,
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: const Color(0xFF6B8A57),
      backgroundColor: const Color(0xFFECE7D6),
      visualDensity: VisualDensity.compact,
    ),
  );
}

enum _EquipmentStorePage { vehicles, logistics, brands, packs, used, garage }

extension on _EquipmentStorePage {
  String get label => switch (this) {
    _EquipmentStorePage.vehicles => 'MAKİNELER',
    _EquipmentStorePage.brands => 'MARKALAR',
    _EquipmentStorePage.packs => 'PAKETLER',
    _EquipmentStorePage.used => 'İKİNCİ EL',
    _EquipmentStorePage.garage => 'GARAJIM',
    _EquipmentStorePage.logistics => 'LOJİSTİK',
  };

  IconData get icon => switch (this) {
    _EquipmentStorePage.vehicles => Icons.agriculture_rounded,
    _EquipmentStorePage.brands => Icons.factory_rounded,
    _EquipmentStorePage.packs => Icons.inventory_2_rounded,
    _EquipmentStorePage.used => Icons.local_offer_rounded,
    _EquipmentStorePage.garage => Icons.garage_rounded,
    _EquipmentStorePage.logistics => Icons.local_shipping_rounded,
  };
}

enum _EquipmentStoreSort { recommended, priceLow, priceHigh, fastest, power }

class _ShopBundle {
  const _ShopBundle({
    required this.name,
    required this.description,
    required this.equipmentIds,
    required this.iconAsset,
  });

  final String name;
  final String description;
  final List<String> equipmentIds;
  final String iconAsset;
  final double discount = 0.12;
}

const _shopBundles = <_ShopBundle>[
  _ShopBundle(
    name: 'Tahıl Verim Seti',
    description: 'Toprak hazırlığından hasada kadar dengeli orta sınıf filo.',
    equipmentIds: [
      'tractor_yamac_180',
      'prep_ova_p16',
      'sow_ekin_12',
      'fertilize_ova_1600',
      'harvest_harman_4x',
    ],
    iconAsset: 'assets/images/equipment/combine.png',
  ),
  _ShopBundle(
    name: 'Büyük Alan Paketi',
    description: 'Geniş çalışma eni ve yüksek kapasiteyle daha az geçiş.',
    equipmentIds: [
      'tractor_gunova_430',
      'prep_yayla_x12',
      'sow_gokova_air18',
      'fertilize_poyraz_4200',
      'harvest_yayla_9x',
    ],
    iconAsset: 'assets/images/equipment/field_prep.png',
  ),
  _ShopBundle(
    name: 'Çayırdan Balya Hattı',
    description: 'Çayır biçimi, toplama ve balyalama için uyumlu set.',
    equipmentIds: ['tractor_yamac_180', 'bale_yelken_r120'],
    iconAsset: 'assets/images/equipment/baler.png',
  ),
];

class _EquipmentBundleCard extends StatelessWidget {
  const _EquipmentBundleCard({
    required this.bundle,
    required this.session,
    required this.onChanged,
  });

  final _ShopBundle bundle;
  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final items = bundle.equipmentIds
        .map(FarmEquipmentCatalog.byId)
        .whereType<FarmEquipment>()
        .toList(growable: false);
    final missing = items
        .where((item) => !session.isEquipmentOwned(item.id))
        .toList(growable: false);
    final regularPrice = missing.fold<int>(
      0,
      (total, item) => total + item.purchasePrice,
    );
    final price = (regularPrice * (1 - bundle.discount)).round();
    final compatibilityIssue = session.equipmentPackCompatibilityIssue(
      bundle.equipmentIds,
    );
    final missingResearch = missing
        .where((item) => !session.canBuyEquipment(item))
        .map((item) => item.requiredResearchId)
        .whereType<String>()
        .toSet();
    final canBuy =
        missing.isNotEmpty &&
        compatibilityIssue == null &&
        missingResearch.isEmpty &&
        session.farmCredits >= price;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF3),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCD2BA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 105,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8D8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset(
              bundle.iconAsset,
              fit: BoxFit.contain,
              cacheWidth: 220,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} PARÇALI PAKET · %${(bundle.discount * 100).round()} İNDİRİM',
                  style: const TextStyle(
                    color: Color(0xFF788751),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  bundle.name,
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  bundle.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5E6958),
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (compatibilityIssue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    compatibilityIssue,
                    style: const TextStyle(
                      color: Color(0xFFB34A35),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    for (final item in items)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: session.isEquipmentOwned(item.id)
                              ? const Color(0xFFDDE8D7)
                              : const Color(0xFFECE7D6),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _mapInk,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                if (missingResearch.isNotEmpty) ...[
                  Text(
                    'Araştırma gerekli: ${missingResearch.join(' · ')}',
                    style: const TextStyle(
                      color: Color(0xFF9B6E29),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        missing.isEmpty
                            ? 'PAKET TAMAM · GARAJINDA'
                            : '${_formatFarmCredits(price)} ÇK  ·  ${missing.length} yeni makine',
                        style: const TextStyle(
                          color: Color(0xFF365640),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: canBuy
                          ? () {
                              if (session.buyEquipmentPack(
                                bundle.equipmentIds,
                                discount: bundle.discount,
                              )) {
                                onChanged();
                              }
                            }
                          : null,
                      icon: Icon(
                        missing.isEmpty
                            ? Icons.check_rounded
                            : Icons.shopping_bag_rounded,
                        size: 14,
                      ),
                      label: Text(
                        missing.isEmpty
                            ? 'ALINDI'
                            : compatibilityIssue != null
                            ? 'TRAKTÖR UYUMSUZ'
                            : missingResearch.isNotEmpty
                            ? 'ARAŞTIRMA GEREKLİ'
                            : canBuy
                            ? 'PAKETİ AL'
                            : 'BAKİYE YETERSİZ',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC84F),
                        foregroundColor: const Color(0xFF35270D),
                        textStyle: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentStoreCard extends StatelessWidget {
  const _EquipmentStoreCard({
    required this.item,
    required this.session,
    required this.usedOffer,
    required this.onChanged,
  });

  final FarmEquipment item;
  final OpeningSession session;
  final bool usedOffer;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final owned = session.isEquipmentOwned(item.id);
    final equipped = item.isTractor
        ? session.equippedTractor?.id == item.id
        : session.equippedEquipmentFor(item.operation)?.id == item.id;
    final workTime = item.isTractor
        ? null
        : item.durationFor(1000, tractor: session.equippedTractor);
    final compatibilityIssue = session.equipmentCompatibilityIssue(item);
    final canEquip = compatibilityIssue == null;
    final price = usedOffer
        ? (item.purchasePrice * 0.82).round()
        : item.purchasePrice;
    final requiredResearch = item.requiredResearchId;
    final missingResearch =
        requiredResearch != null && !session.hasResearch(requiredResearch);
    final canBuy = session.farmCredits >= price && !missingResearch;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: equipped ? const Color(0xFF83A86B) : const Color(0xFFDDD3B6),
          width: equipped ? 1.8 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x190F281B),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 94,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8D8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset(
              item.imageAsset,
              semanticLabel: item.isTractor
                  ? '${item.name}, traktör'
                  : '${item.name}, ${item.operation.label} makinesi',
              fit: BoxFit.contain,
              cacheWidth: 176,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.manufacturer.toUpperCase()} · ${item.subcategory.isEmpty ? 'KADEME ${item.tier}' : item.subcategory.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718261),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      usedOffer ? '2. EL' : 'SEVİYE ${item.tier}',
                      style: const TextStyle(
                        color: Color(0xFF9A7833),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5E6958),
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    _EquipmentMetric(
                      icon: Icons.speed_rounded,
                      text: item.isTractor || item.isSelfPropelled
                          ? 'Azami ${item.maxSpeedKph.toStringAsFixed(0)} km/sa'
                          : '${item.workingSpeedKph.toStringAsFixed(0)} km/sa çalışma',
                    ),
                    _EquipmentMetric(
                      icon: Icons.bolt_rounded,
                      text: item.isTractor
                          ? '${item.torqueCapacityNm} Nm tork'
                          : item.requiresTractor
                          ? 'Gerekli ${item.requiredTractorTorqueNm} Nm'
                          : 'Kendinden yürür',
                    ),
                    if (item.isTractor || item.isSelfPropelled)
                      _EquipmentMetric(
                        icon: Icons.electric_bolt_rounded,
                        text: '${item.displayHorsepower} hp motor',
                      ),
                    _EquipmentMetric(
                      icon: Icons.open_in_full_rounded,
                      text: item.isTractor
                          ? 'Gövde ${item.displayWidth.toStringAsFixed(1)} m'
                          : 'İş eni ${item.displayWidth.toStringAsFixed(1)} m',
                    ),
                    if (item.capacity > 0 || item.isTractor)
                      _EquipmentMetric(
                        icon: Icons.inventory_2_outlined,
                        text: item.capacityText,
                      ),
                    if (!item.isTractor && workTime != null)
                      _EquipmentMetric(
                        icon: Icons.schedule_rounded,
                        text: '${_formatRemaining(workTime)} / 1.000 m²',
                      ),
                  ],
                ),
                if (compatibilityIssue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      compatibilityIssue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB34A35),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (usedOffer)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'İkinci el ilanı · %18 indirim',
                      style: TextStyle(
                        color: Color(0xFF9C6327),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (missingResearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Araştırma gerekli: ${_technologyName(requiredResearch)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9B6E29),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 29,
                  child: owned
                      ? (equipped
                            ? FilledButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_rounded, size: 15),
                                label: const Text('KUŞANILDI'),
                                style: FilledButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: canEquip
                                    ? () {
                                        if (session.equipEquipment(item.id)) {
                                          onChanged();
                                        }
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.construction_rounded,
                                  size: 14,
                                ),
                                label: Text(
                                  canEquip ? 'KUŞAN' : 'TORK YETERSİZ',
                                ),
                                style: OutlinedButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ))
                      : FilledButton.icon(
                          onPressed: canBuy
                              ? () {
                                  if (session.buyEquipment(
                                    item.id,
                                    usedOffer: usedOffer,
                                  )) {
                                    onChanged();
                                  }
                                }
                              : null,
                          icon: const Icon(
                            Icons.shopping_cart_rounded,
                            size: 14,
                          ),
                          label: Text(
                            missingResearch
                                ? 'ARAŞTIRMA GEREKLİ · $requiredResearch'
                                : canBuy
                                ? '${usedOffer ? '2. EL AL' : 'SATIN AL'} · ${_formatFarmCredits(price)} ÇK'
                                : 'BAKİYE YETERSİZ · ${_formatFarmCredits(price)} ÇK',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC84F),
                            foregroundColor: const Color(0xFF35270D),
                            disabledBackgroundColor: const Color(0xFFE2DED1),
                            disabledForegroundColor: const Color(0xFF77786F),
                            textStyle: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentMetric extends StatelessWidget {
  const _EquipmentMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: const Color(0xFF5E7D48)),
      const SizedBox(width: 3),
      Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4C5948),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ManagementSheet extends StatefulWidget {
  const _ManagementSheet({required this.session, required this.onSelectPlot});

  final OpeningSession session;
  final ValueChanged<CropPlotState> onSelectPlot;

  @override
  State<_ManagementSheet> createState() => _ManagementSheetState();
}

class _ManagementSheetState extends State<_ManagementSheet> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownedPlots = widget.session.plots
        .where((plot) => plot.isOwned)
        .toList(growable: false);
    final vehicles = widget.session.fleetManager.vehicles;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.84,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 3, 18, 12),
              child: Row(
                children: [
                  const Icon(Icons.dashboard_rounded, color: _mapInk),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'ÇİFTLİK YÖNETİMİ',
                      style: TextStyle(
                        color: _mapInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatFarmCredits(widget.session.farmCredits)} ÇK',
                    style: const TextStyle(
                      color: _mapInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: _mapInk,
              unselectedLabelColor: Color(0xFF74806C),
              indicatorColor: Color(0xFF527345),
              tabs: [
                Tab(icon: Icon(Icons.grass_rounded), text: 'Araziler'),
                Tab(icon: Icon(Icons.local_shipping_rounded), text: 'Araçlar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  if (ownedPlots.isEmpty)
                    const Center(child: Text('Henüz yönetilen arazi yok.'))
                  else
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: ownedPlots.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final plot = ownedPlots[index];
                        return _ManagementPlotTile(
                          session: widget.session,
                          plot: plot,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelectPlot(plot);
                          },
                        );
                      },
                    ),
                  if (vehicles.isEmpty)
                    const _EmptyManagementState(
                      icon: Icons.local_shipping_outlined,
                      title: 'Henüz araç yok',
                      body: 'İlk ürün hasadında başlangıç kamyonu ve tarladan pazara rotası açılır.',
                    )
                  else
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: vehicles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => _ManagementVehicleTile(
                        fleet: widget.session.fleetManager,
                        vehicle: vehicles[index],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementPlotTile extends StatelessWidget {
  const _ManagementPlotTile({
    required this.session,
    required this.plot,
    required this.onTap,
  });

  final OpeningSession session;
  final CropPlotState plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _fieldStatus(session, plot, DateTime.now());
    final activeCrop = !plot.hasActiveCrop || plot.activeCropId == null
        ? null
        : _cropName(plot.activeCropId!);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.74),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: plot.use == CropPlotUse.pasture
              ? const Color(0xFF6F9E55)
              : _cropFamilyColor(plot.preferredCropFamily),
          child: Icon(
            plot.use == CropPlotUse.pasture
                ? Icons.grass_rounded
                : Icons.agriculture_rounded,
            color: Colors.white,
          ),
        ),
        title: Text(
          plot.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${activeCrop ?? (plot.use == CropPlotUse.pasture ? 'Çayır' : 'Ürün yok')} · $status\n'
          '${(plot.areaSquareMeters / 10000).toStringAsFixed(2)} ha · Toprak ${plot.soilConditionPoints}/100',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ManagementVehicleTile extends StatelessWidget {
  const _ManagementVehicleTile({required this.fleet, required this.vehicle});

  final LogisticsFleetManager fleet;
  final FleetVehicleState vehicle;

  @override
  Widget build(BuildContext context) {
    final routes = fleet.routes
        .where((item) => item.id == vehicle.assignedRouteId)
        .toList(growable: false);
    final route = routes.isEmpty ? null : routes.first;
    String destination = 'Atanmamış rota';
    String routeName = route?.name ?? 'Rota yok';
    if (route != null && route.stops.isNotEmpty) {
      final current = vehicle.currentStopIndex
          .clamp(0, route.stops.length - 1)
          .toInt();
      destination = route.stops[route.nextStopIndex(current)].name;
    }
    final status = switch (vehicle.status) {
      VehicleStatus.idle => 'Beklemede',
      VehicleStatus.traveling => 'Yolda · $destination yönünde',
      VehicleStatus.paused => 'Hat duraklatıldı',
      VehicleStatus.loading => 'Yük alıyor',
      VehicleStatus.unloading => 'Yük boşaltıyor',
      VehicleStatus.divertingToSell => 'Pazara yönleniyor',
      VehicleStatus.waitingForSpace => 'Depoda yer bekliyor',
      VehicleStatus.outOfFuel => 'Yakıt bitti',
      VehicleStatus.serviceDue => 'Bakım gerekli',
    };
    final cargo = vehicle.hasCargo
        ? '${_cropName(vehicle.cargoCropId!)} · ${vehicle.cargoAmount}/${vehicle.effectiveCapacity}'
        : 'Boş · ${vehicle.remainingCapacity} kapasite';
    final trailerName = vehicle.trailerType?.name ?? 'Dorsesiz';
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.74),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF28583D),
          child: Icon(Icons.local_shipping_rounded, color: Colors.white),
        ),
        title: Text(
          vehicle.truckType.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '$status\n$trailerName · Rota: $routeName · Yük: $cargo · ${vehicle.effectiveSpeed.round()} km/sa',
        ),
        isThreeLine: true,
        trailing: Text(
          vehicle.totalDeliveriesCount == 0
              ? 'Teslimat yok'
              : '${vehicle.totalDeliveriesCount} teslimat',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyManagementState extends StatelessWidget {
  const _EmptyManagementState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF7C8B71)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ParcelStat extends StatelessWidget {
  const _ParcelStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFF678451)),
      const SizedBox(width: 4),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF82816F),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _mapInk,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final isFuel = label.toLowerCase().contains('yakıt');
    final Color barColor;
    if (isFuel) {
      if (clampedValue < 0.2) {
        barColor = const Color(0xFFD9534F);
      } else if (clampedValue < 0.5) {
        barColor = const Color(0xFFF0AD4E);
      } else {
        barColor = const Color(0xFF4C8C4A);
      }
    } else {
      // Wear/Aşınma: High wear is dangerous
      if (clampedValue > 0.75) {
        barColor = const Color(0xFFD9534F);
      } else if (clampedValue > 0.4) {
        barColor = const Color(0xFFE67E22);
      } else {
        barColor = const Color(0xFF2E7D32);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDFE4D6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6650),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: clampedValue,
                minHeight: 5,
                backgroundColor: const Color(0xFFD8DDCF),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              trailing,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _mapInk,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerSwitch extends StatelessWidget {
  const _LayerSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    secondary: Icon(icon, color: const Color(0xFF527345)),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE8D7),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF837C68), width: 0.7),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _mapInk,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MapScaleBar extends StatelessWidget {
  const _MapScaleBar({required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context) {
    final distance = zoom < 0.28
        ? 1000
        : zoom < 0.6
        ? 500
        : zoom < 1.1
        ? 200
        : 100;
    final label = distance >= 1000 ? '${distance ~/ 1000} km' : '$distance m';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
        Container(
          width: (distance * zoom).clamp(38, 120).toDouble(),
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF234530), width: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({
    required this.icon,
    required this.text,
    required this.onClose,
  });

  final IconData icon;
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, right: 3, top: 4, bottom: 4),
    decoration: BoxDecoration(
      color: const Color(0xF2FFF9E9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD6C99E)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF527345)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: _mapInk,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        IconButton(
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 15),
        ),
      ],
    ),
  );
}

class _WorldMapPainter extends CustomPainter {
  const _WorldMapPainter({
    required this.world,
    required this.session,
    required this.mapRevision,
    required this.cameraCenter,
    required this.zoom,
    required this.selectedParcelId,
    required this.selectedFarmPlotId,
    required this.routeStartParcelId,
    required this.salesRouteStartPlotId,
    required this.salesRouteMode,
    required this.salesRouteStart,
    required this.measureStart,
    required this.measureEnd,
    required this.showParcels,
    required this.showRoutes,
    required this.showInfrastructure,
    required this.showFertility,
  });

  final ProceduralFarmWorld world;
  final OpeningSession session;
  final int mapRevision;
  final Offset cameraCenter;
  final double zoom;
  final String? selectedParcelId;
  final int? selectedFarmPlotId;
  final String? routeStartParcelId;
  final int? salesRouteStartPlotId;
  final bool salesRouteMode;
  final Offset? salesRouteStart;
  final WorldMapPoint? measureStart;
  final WorldMapPoint? measureEnd;
  final bool showParcels;
  final bool showRoutes;
  final bool showInfrastructure;
  final bool showFertility;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF31583A),
    );
    final visible = Rect.fromCenter(
      center: cameraCenter,
      width: size.width / zoom,
      height: size.height / zoom,
    );
    final leftChunk = ((visible.left / farmWorldChunkSize).floor() - 1).clamp(
      ProceduralFarmWorld.minChunkX,
      ProceduralFarmWorld.maxChunkX,
    );
    final rightChunk = ((visible.right / farmWorldChunkSize).floor() + 1).clamp(
      ProceduralFarmWorld.minChunkX,
      ProceduralFarmWorld.maxChunkX,
    );
    final topChunk = ((visible.top / farmWorldChunkSize).floor() - 1).clamp(
      ProceduralFarmWorld.minChunkY,
      ProceduralFarmWorld.maxChunkY,
    );
    final bottomChunk = ((visible.bottom / farmWorldChunkSize).floor() + 1)
        .clamp(ProceduralFarmWorld.minChunkY, ProceduralFarmWorld.maxChunkY);

    canvas.save();
    canvas.translate(
      size.width / 2 - cameraCenter.dx * zoom,
      size.height / 2 - cameraCenter.dy * zoom,
    );
    canvas.scale(zoom);

    final chunks = <WorldMapChunk>[];
    for (var y = topChunk; y <= bottomChunk; y++) {
      for (var x = leftChunk; x <= rightChunk; x++) {
        final chunk = world.chunkAt(x, y);
        chunks.add(chunk);
        _drawTerrain(canvas, chunk);
      }
    }
    for (final chunk in chunks) {
      _drawMountains(canvas, chunk);
    }
    if (showRoutes) _drawRoadNetwork(canvas, visible);
    for (final chunk in chunks) {
      _drawPonds(canvas, chunk);
      _drawTrees(canvas, chunk);
    }
    if (zoom < 0.31) _drawDistrictLabels(canvas, visible);
    if (showParcels) {
      for (final chunk in chunks) {
        for (final parcel in chunk.parcels) {
          _drawParcel(canvas, parcel);
        }
      }
    }
    if (showRoutes) _drawLogistics(canvas);
    if (showInfrastructure) {
      for (final chunk in chunks) {
        for (final poi in chunk.pointsOfInterest) {
          _drawPointOfInterest(canvas, poi);
        }
      }
    }
    _drawLocalFarmPlots(canvas);
    if (salesRouteMode && salesRouteStart != null) {
      _drawSalesRoutePreview(canvas, salesRouteStart!);
    }
    _drawSalesPoint(canvas, highlighted: salesRouteMode);
    _drawMeasurements(canvas);
    _drawWorldBoundaries(canvas);
    canvas.restore();

    _drawVignette(canvas, size);
  }

  void _drawTerrain(Canvas canvas, WorldMapChunk chunk) {
    final rect = Rect.fromLTWH(
      chunk.x * farmWorldChunkSize,
      chunk.y * farmWorldChunkSize,
      farmWorldChunkSize,
      farmWorldChunkSize,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF416B43));
    final seed = world.seed + chunk.x * 15485863 + chunk.y * 32452843;
    final random = math.Random(seed);
    final patchPaint = Paint()..style = PaintingStyle.fill;
    const patchColors = [0x124E773E, 0x18436A3B, 0x12598245, 0x0D8E9154];
    for (var i = 0; i < 16; i++) {
      patchPaint.color = Color(patchColors[random.nextInt(patchColors.length)]);
      final x = rect.left + random.nextDouble() * rect.width;
      final y = rect.top + random.nextDouble() * rect.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 60 + random.nextDouble() * 160,
          height: 45 + random.nextDouble() * 130,
        ),
        patchPaint,
      );
    }
    final edgePaint = Paint()
      ..color = const Color(0x14313E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, edgePaint);
  }

  void _drawMountains(Canvas canvas, WorldMapChunk chunk) {
    for (final mountain in chunk.mountains) {
      canvas.save();
      canvas.translate(mountain.center.x, mountain.center.y);
      canvas.rotate(mountain.ridgeAngle);
      final seed =
          world.seed ^
          (mountain.center.x.round() * 73856093) ^
          (mountain.center.y.round() * 19349663);
      final rings = <Path>[
        for (final fraction in const [1.0, 0.79, 0.59, 0.40, 0.22])
          _topographicContourPath(
            mountain.width,
            mountain.height,
            fraction,
            seed,
          ),
      ];
      canvas.drawPath(rings.first, Paint()..color = const Color(0x184D5A3C));

      final shownLevels = zoom < 0.31
          ? const {0, 2, 4}
          : zoom < 0.65
          ? const {0, 1, 3, 4}
          : const {0, 1, 2, 3, 4};
      for (var level = 0; level < rings.length; level++) {
        if (!shownLevels.contains(level)) continue;
        final isIndexContour = level == 4;
        canvas.drawPath(
          rings[level],
          Paint()
            ..color = isIndexContour
                ? const Color(0xB27A6240)
                : const Color(0x827B7454)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (isIndexContour ? 1.45 : 0.82) / zoom
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      canvas.restore();
    }
  }

  void _drawSalesRoutePreview(Canvas canvas, Offset start) {
    final end = const Offset(starterMarketMapX, starterMarketMapY);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2 + (end.dy - start.dy) * 0.12,
        (start.dy + end.dy) / 2 - (end.dx - start.dx) * 0.12,
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xCCFFE28B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 / zoom
        ..strokeCap = StrokeCap.round,
    );
    _drawDashPath(
      canvas,
      path,
      Paint()
        ..color = const Color(0xFF385D3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom
        ..strokeCap = StrokeCap.round,
      dash: 11 / zoom,
      gap: 8 / zoom,
    );
  }

  void _drawSalesPoint(Canvas canvas, {required bool highlighted}) {
    canvas.save();
    canvas.translate(starterMarketMapX, starterMarketMapY);
    canvas.scale(1 / zoom);
    canvas.drawCircle(
      Offset.zero,
      highlighted ? 20 : 17,
      Paint()
        ..color = highlighted
            ? const Color(0x77FFD45C)
            : const Color(0x55313E24),
    );
    canvas.drawCircle(
      Offset.zero,
      14,
      Paint()..color = const Color(0xFF234D36),
    );
    canvas.drawCircle(
      Offset.zero,
      10.5,
      Paint()..color = const Color(0xFFFFF2D0),
    );
    final shopBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6.5, -4, 13, 9.5),
      const Radius.circular(1.2),
    );
    canvas.drawRRect(shopBody, Paint()..color = const Color(0xFFB98043));
    final roof = Path()
      ..moveTo(-8, -3.5)
      ..lineTo(-5.5, -8)
      ..lineTo(5.5, -8)
      ..lineTo(8, -3.5)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8F5540));
    canvas.drawRect(
      const Rect.fromLTWH(-1.8, 0, 3.6, 5.5),
      Paint()..color = const Color(0xFFF4D896),
    );
    if (highlighted) {
      canvas.drawCircle(
        Offset.zero,
        18,
        Paint()
          ..color = const Color(0xFFFFC84F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    final painter = TextPainter(
      text: const TextSpan(
        text: 'KASABA PAZARI',
        style: TextStyle(
          color: Color(0xFF1C3828),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, 28),
        width: painter.width + 12,
        height: painter.height + 7,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(labelRect, Paint()..color = const Color(0xFFF8EDCF));
    canvas.drawRRect(
      labelRect,
      Paint()
        ..color = const Color(0xAA234D36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(-painter.width / 2, 28 - painter.height / 2));
    canvas.restore();
  }

  void _drawOwnedParcelMarker(
    Canvas canvas,
    Offset center, {
    required bool selected,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 / zoom);
    canvas.drawCircle(
      Offset.zero,
      selected ? 9 : 7.3,
      Paint()..color = const Color(0xEE173B2B),
    );
    canvas.drawCircle(
      Offset.zero,
      selected ? 6.2 : 4.8,
      Paint()
        ..color = selected ? const Color(0xFFFFC84F) : const Color(0xFFB9E38B),
    );
    canvas.drawCircle(Offset.zero, 2, Paint()..color = const Color(0xFFF8F0D7));
    canvas.restore();
  }

  Path _topographicContourPath(
    double width,
    double height,
    double scale,
    int seed,
  ) {
    const pointCount = 28;
    final phase = (seed.abs() % 100000) / 100000 * math.pi * 2;
    final points = List<Offset>.generate(pointCount, (index) {
      final angle = math.pi * 2 * index / pointCount;
      final irregularity =
          1 +
          0.035 * math.sin(angle * 3 + phase) +
          0.022 * math.sin(angle * 5 + phase * 1.7) +
          0.012 * math.sin(angle * 7 - phase * 0.8);
      return Offset(
        math.cos(angle) * width * 0.5 * scale * irregularity,
        math.sin(angle) * height * 0.5 * scale * irregularity,
      );
    }, growable: false);
    Offset midpoint(Offset first, Offset second) =>
        Offset.lerp(first, second, 0.5)!;
    final path = Path()
      ..moveTo(
        midpoint(points.last, points.first).dx,
        midpoint(points.last, points.first).dy,
      );
    for (var index = 0; index < points.length; index++) {
      final next = points[(index + 1) % points.length];
      final end = midpoint(points[index], next);
      path.quadraticBezierTo(
        points[index].dx,
        points[index].dy,
        end.dx,
        end.dy,
      );
    }
    return path..close();
  }

  void _drawDistrictLabels(Canvas canvas, Rect visible) {
    const districtNames = [
      'AKARSU OVASI',
      'KARAAĞAÇ BÖLGESİ',
      'GÖLET YAYLASI',
      'KUZEY ÇAYIRLARI',
      'MEŞE ORMANI',
      'GÜNEY TARIM KUŞAĞI',
      'YEŞİL VADİ',
    ];
    final firstX = (visible.left / ProceduralFarmWorld.districtSize).floor();
    final lastX = (visible.right / ProceduralFarmWorld.districtSize).floor();
    final firstY = (visible.top / ProceduralFarmWorld.districtSize).floor();
    final lastY = (visible.bottom / ProceduralFarmWorld.districtSize).floor();
    for (var y = firstY; y <= lastY; y++) {
      for (var x = firstX; x <= lastX; x++) {
        final index = ((x * 7 + y * 11).abs()) % districtNames.length;
        final center = Offset(
          x * ProceduralFarmWorld.districtSize +
              ProceduralFarmWorld.districtSize / 2,
          y * ProceduralFarmWorld.districtSize +
              ProceduralFarmWorld.districtSize / 2,
        );
        _drawMapLabel(canvas, districtNames[index], center, 168);
      }
    }
  }

  void _drawRoadNetwork(Canvas canvas, Rect visible) {
    final roads = world.roadSegmentsInBounds(
      visible.left,
      visible.top,
      visible.right,
      visible.bottom,
      includeLocal: zoom >= 0.3,
    );
    for (final road in roads) {
      if (road.type == WorldMapRoadType.trail && zoom < 0.62) continue;
      if (road.points.length < 2) continue;
      final path = Path()..moveTo(road.points.first.x, road.points.first.y);
      for (final point in road.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      _strokeRoad(canvas, path, road.type.index);
    }
  }

  void _strokeRoad(Canvas canvas, Path path, int style) {
    final (outerColor, innerColor, outerWidth, innerWidth) = switch (style) {
      0 => (const Color(0xDD695B43), const Color(0xFFE0C89A), 25.0, 16.0),
      1 => (const Color(0xDD65583F), const Color(0xFFD1B989), 16.0, 9.0),
      2 => (const Color(0xDD504A37), const Color(0xFFC0A779), 10.0, 5.5),
      _ => (const Color(0xCC454532), const Color(0xFF9F916A), 6.0, 2.8),
    };
    final outer = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final inner = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outer);
    canvas.drawPath(path, inner);
    if (style == 0 && zoom >= 0.34) {
      _drawDashPath(
        canvas,
        path,
        Paint()
          ..color = const Color(0x88FFF2CE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
        dash: 28,
        gap: 30,
      );
    }
  }

  void _drawPonds(Canvas canvas, WorldMapChunk chunk) {
    for (final pond in chunk.ponds) {
      final rect = Rect.fromCenter(
        center: Offset(pond.center.x, pond.center.y),
        width: pond.width,
        height: pond.height,
      );
      canvas.drawOval(
        rect.shift(const Offset(0, 7)),
        Paint()..color = const Color(0x382A3B27),
      );
      canvas.drawOval(rect, Paint()..color = const Color(0xFF3D9AA0));
      canvas.drawOval(
        rect.deflate(7),
        Paint()
          ..color = const Color(0x665BD1CF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawArc(
        rect.deflate(18),
        math.pi * 1.08,
        math.pi * 0.62,
        false,
        Paint()
          ..color = const Color(0x99E5F4CF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawTrees(Canvas canvas, WorldMapChunk chunk) {
    final skip = zoom < 0.27
        ? 3
        : zoom < 0.42
        ? 2
        : 1;
    for (var index = 0; index < chunk.trees.length; index += skip) {
      final tree = chunk.trees[index];
      final center = Offset(tree.center.x, tree.center.y);
      final radius = tree.radius;
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(radius * 0.18, radius * 0.48),
          width: radius * 2.05,
          height: radius * 1.18,
        ),
        Paint()..color = const Color(0x30223221),
      );
      if (zoom < 0.32) {
        canvas.drawCircle(
          center,
          radius * 0.72,
          Paint()..color = Color(tree.tint),
        );
      } else {
        canvas.drawCircle(
          center + Offset(radius * 0.18, radius * 0.2),
          radius * 0.82,
          Paint()..color = Color(tree.tint),
        );
        canvas.drawCircle(
          center - Offset(radius * 0.24, radius * 0.04),
          radius * 0.61,
          Paint()..color = Color(tree.tint),
        );
        canvas.drawCircle(
          center - Offset(radius * 0.19, radius * 0.3),
          radius * 0.38,
          Paint()..color = const Color(0xFF76A65E).withValues(alpha: 0.56),
        );
      }
    }
  }

  void _drawParcel(Canvas canvas, WorldMapParcel parcel) {
    if (parcel.isHome) return;
    final owned = session.ownsWorldParcel(parcel.id);
    final farmPlot = session.plotForWorldParcel(parcel.id);
    if (session.buildingOnParcel(parcel.id) != null) {
      if (zoom < 0.31 && owned) {
        _drawOwnedParcelMarker(
          canvas,
          Offset(parcel.center.x, parcel.center.y),
          selected: parcel.id == selectedParcelId,
        );
      }
      return;
    }
    final center = Offset(parcel.center.x, parcel.center.y);
    final isSelected =
        parcel.id == selectedParcelId ||
        farmPlot?.id == selectedFarmPlotId ||
        farmPlot?.id == salesRouteStartPlotId;
    final isRouteStart = parcel.id == routeStartParcelId;
    if (zoom < 0.31) {
      if (owned) {
        _drawOwnedParcelMarker(
          canvas,
          center,
          selected:
              isSelected ||
              isRouteStart ||
              farmPlot?.id == salesRouteStartPlotId,
        );
      }
      return;
    }
    final rect = Rect.fromCenter(
      center: center,
      width: parcel.width,
      height: parcel.height,
    );
    final hasGrowingCrop = farmPlot?.hasActiveCrop == true;
    final cropColor = showFertility
        ? Color.lerp(
            const Color(0xFFBD5D47),
            const Color(0xFF8EBE58),
            parcel.fertility / 100,
          )!
        : hasGrowingCrop
        ? _cropFamilyColor(
            OpeningCropCatalog.familyFor(farmPlot!.activeCropId!) ??
                farmPlot.preferredCropFamily,
          )
        : _mapCropColor(parcel.cropType);
    final path = _parcelPath(parcel);
    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()..color = const Color(0x44253823),
    );
    final fill = owned
        ? hasGrowingCrop
              ? Color.lerp(cropColor, const Color(0xFF70A256), 0.24)!
              : const Color(0xFF70A256)
        : Color.lerp(cropColor, const Color(0xFFF2E5C2), 0.38)!;
    canvas.drawPath(path, Paint()..color = fill);

    if (zoom >= 0.56) {
      canvas.save();
      canvas.clipPath(path);
      final furrowPaint = Paint()
        ..color = owned ? const Color(0x553A623D) : const Color(0x5B684F31)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var row = -3; row <= 3; row++) {
        final y = center.dy + row * rect.height / 8;
        canvas.drawLine(
          Offset(rect.left - 8, y + 7),
          Offset(rect.right + 8, y - 9),
          furrowPaint,
        );
      }
      canvas.restore();
    }

    final borderColor = isSelected
        ? const Color(0xFFFFC84F)
        : isRouteStart
        ? const Color(0xFF76E19B)
        : owned
        ? const Color(0xFFB8E48F)
        : const Color(0xFFFFF0CE);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected
            ? 6
            : owned
            ? 4
            : 3,
    );

    if (zoom >= 1.05) {
      final fencePaint = Paint()
        ..color = owned ? const Color(0xFFC8AE74) : const Color(0x99F9E7C3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      final vertices = parcel.worldVertices
          .map((point) => Offset(point.x, point.y))
          .toList(growable: false);
      var gateIndex = 0;
      var lowestEdgeY = double.negativeInfinity;
      for (var index = 0; index < vertices.length; index++) {
        final start = vertices[index];
        final end = vertices[(index + 1) % vertices.length];
        canvas.drawLine(start, end, fencePaint);
        final edgeY = (start.dy + end.dy) / 2;
        if (edgeY > lowestEdgeY) {
          lowestEdgeY = edgeY;
          gateIndex = index;
        }
      }
      final gateStart = vertices[gateIndex];
      final gateEnd = vertices[(gateIndex + 1) % vertices.length];
      final gateVector = gateEnd - gateStart;
      final gateCenter = Offset.lerp(gateStart, gateEnd, 0.5)!;
      canvas.drawLine(
        gateCenter - gateVector * 0.11,
        gateCenter + gateVector * 0.11,
        Paint()
          ..color = const Color(0xFF765A34)
          ..strokeWidth = 5,
      );
    }

    if (farmPlot != null && zoom >= 0.56) {
      _drawMapLabel(
        canvas,
        farmPlot.use == CropPlotUse.pasture
            ? 'ÇAYIR'
            : farmPlot.activeCropId == null
            ? 'EKİM BEKLİYOR'
            : _cropName(farmPlot.activeCropId!).toUpperCase(),
        center,
        8,
      );
    }

    if (zoom >= 0.8 && !parcel.isHome) {
      _drawMapLabel(
        canvas,
        _mapCropLabel(parcel.cropType),
        Offset(center.dx, rect.bottom + 12),
        13,
      );
    }
    if (isSelected && !parcel.isHome && zoom >= 0.5) {
      _drawMapLabel(
        canvas,
        '${parcel.price} ÇK · ${parcel.fertility} verim',
        Offset(center.dx, rect.top - 12),
        14,
      );
    }
  }

  void _drawLocalFarmPlots(Canvas canvas) {
    const shapeVariants = <List<Offset>>[
      [
        Offset(0.08, 0),
        Offset(0.76, 0.03),
        Offset(1, 0.27),
        Offset(0.88, 0.82),
        Offset(0.6, 1),
        Offset(0.05, 0.84),
        Offset(0, 0.35),
      ],
      [
        Offset(0.16, 0),
        Offset(0.77, 0.08),
        Offset(1, 0.42),
        Offset(0.82, 0.93),
        Offset(0.32, 1),
        Offset(0, 0.71),
        Offset(0.09, 0.24),
      ],
      [
        Offset(0, 0.14),
        Offset(0.3, 0),
        Offset(0.87, 0.08),
        Offset(1, 0.45),
        Offset(0.73, 0.57),
        Offset(0.81, 1),
        Offset(0.23, 0.9),
        Offset(0, 0.62),
      ],
      [
        Offset(0, 0.02),
        Offset(0.8, 0),
        Offset(1, 0.22),
        Offset(0.92, 0.58),
        Offset(0.75, 1),
        Offset(0.15, 0.91),
        Offset(0.02, 0.5),
      ],
      [
        Offset(0.04, 0.29),
        Offset(0.38, 0.04),
        Offset(0.96, 0.16),
        Offset(1, 0.7),
        Offset(0.63, 0.91),
        Offset(0.15, 1),
        Offset(0, 0.69),
      ],
      [
        Offset(0, 0.1),
        Offset(0.51, 0),
        Offset(0.98, 0.2),
        Offset(0.8, 0.53),
        Offset(0.92, 1),
        Offset(0.37, 0.82),
        Offset(0.05, 0.59),
      ],
      [
        Offset(0.2, 0),
        Offset(0.93, 0.05),
        Offset(1, 0.39),
        Offset(0.75, 0.84),
        Offset(0.58, 1),
        Offset(0.06, 0.73),
        Offset(0, 0.21),
      ],
      [
        Offset(0, 0.38),
        Offset(0.12, 0.08),
        Offset(0.56, 0),
        Offset(1, 0.18),
        Offset(0.89, 0.57),
        Offset(0.74, 0.96),
        Offset(0.26, 1),
        Offset(0.05, 0.74),
      ],
    ];

    for (final plot in session.plots) {
      if (plot.id == 0 && session.starterPlotId != 0) continue;
      if (plot.mapParcelId?.startsWith('home-') != true) continue;
      if (plot.mapParcelId != null &&
          session.buildingOnParcel(plot.mapParcelId!) != null) {
        continue;
      }
      final center = Offset(plot.mapX, plot.mapY);
      if (zoom < 0.30) {
        if (plot.isOwned) {
          _drawOwnedParcelMarker(
            canvas,
            center,
            selected:
                plot.id == selectedFarmPlotId ||
                plot.id == salesRouteStartPlotId,
          );
        }
        continue;
      }
      final rect = Rect.fromCenter(
        center: center,
        width: plot.mapWidth,
        height: plot.mapHeight,
      );
      final shapeRandom = math.Random(plot.id * 7919 + 104729);
      final vertices = shapeVariants[plot.id % shapeVariants.length];
      Offset mapVertex(Offset vertex) {
        final jitterX = (shapeRandom.nextDouble() - 0.5) * 0.04;
        final jitterY = (shapeRandom.nextDouble() - 0.5) * 0.04;
        final x = (vertex.dx + jitterX).clamp(0.0, 1.0).toDouble();
        final y = (vertex.dy + jitterY).clamp(0.0, 1.0).toDouble();
        return Offset(rect.left + rect.width * x, rect.top + rect.height * y);
      }

      final firstVertex = mapVertex(vertices.first);
      final path = Path()..moveTo(firstVertex.dx, firstVertex.dy);
      for (final vertex in vertices.skip(1)) {
        final point = mapVertex(vertex);
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      final selected =
          plot.id == selectedFarmPlotId || plot.id == salesRouteStartPlotId;
      final baseColor = plot.use == CropPlotUse.pasture
          ? const Color(0xFF6F9E55)
          : !plot.hasActiveCrop
          ? _cropFamilyColor(plot.preferredCropFamily)
          : _cropFamilyColor(
              OpeningCropCatalog.familyFor(plot.activeCropId!) ??
                  plot.preferredCropFamily,
            );
      final fill = plot.isOwned
          ? baseColor
          : Color.lerp(baseColor, const Color(0xFFF2E5C2), 0.48)!;
      canvas.drawPath(
        path.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x44253823),
      );
      canvas.drawPath(path, Paint()..color = fill);

      canvas.save();
      canvas.clipPath(path);
      final furrowPaint = Paint()
        ..color = plot.isOwned
            ? const Color(0x553A623D)
            : const Color(0x664F422C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var row = -2; row <= 2; row++) {
        final y = center.dy + row * rect.height / 6;
        canvas.drawLine(
          Offset(rect.left - 4, y + 4),
          Offset(rect.right + 4, y - 4),
          furrowPaint,
        );
      }
      canvas.restore();

      canvas.drawPath(
        path,
        Paint()
          ..color = selected
              ? const Color(0xFFFFC84F)
              : plot.isOwned
              ? const Color(0xFFB8E48F)
              : const Color(0xFFFFF0CE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 5 : 3,
      );

      if (zoom >= 0.48) {
        if (plot.hasActiveCrop || plot.use == CropPlotUse.pasture) {
          _drawMapLabel(
            canvas,
            plot.use == CropPlotUse.pasture
                ? 'ÇAYIR'
                : _cropName(plot.activeCropId!).toUpperCase(),
            center + Offset(0, rect.height * 0.27),
            6,
          );
        }
      }
    }
  }

  Path _parcelPath(WorldMapParcel parcel) {
    final vertices = parcel.worldVertices;
    final path = Path()..moveTo(vertices.first.x, vertices.first.y);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.x, vertex.y);
    }
    return path..close();
  }

  void _drawLogistics(Canvas canvas) {
    for (final link in session.state.worldLogisticsLinks) {
      final start = Offset(link.from.x, link.from.y);
      final end = Offset(link.to.x, link.to.y);
      final delta = end - start;
      final perpendicular = Offset(-delta.dy, delta.dx);
      final normal = perpendicular.distance == 0
          ? Offset.zero
          : perpendicular / perpendicular.distance;
      final stableBendSign =
          link.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit).isEven
          ? 1
          : -1;
      final bend =
          math.min(delta.distance * 0.12, 380).toDouble() * stableBendSign;
      final midpoint = (start + end) / 2 + normal * bend;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(midpoint.dx, midpoint.dy, end.dx, end.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF5B4127)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 17
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFD875)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
      _drawDashPath(
        canvas,
        path,
        Paint()
          ..color = const Color(0xFF84552D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1,
        dash: 13,
        gap: 11,
      );
      _drawTruckMarker(canvas, path);
    }
  }

  void _drawTruckMarker(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final tangent = metrics.first.getTangentForOffset(
      metrics.first.length * 0.53,
    );
    if (tangent == null) return;
    final center = tangent.position;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.atan2(tangent.vector.dy, tangent.vector.dx));
    final marker = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      marker.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x55332616),
    );
    canvas.drawRRect(marker, Paint()..color = const Color(0xFF28583D));
    canvas.drawRRect(
      marker,
      Paint()
        ..color = const Color(0xFFFFF4D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final wheelPaint = Paint()..color = const Color(0xFF473B2A);
    for (final x in const [-9.0, 9.0]) {
      canvas.drawCircle(Offset(x, -9), 3.1, wheelPaint);
      canvas.drawCircle(Offset(x, 9), 3.1, wheelPaint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(9, 0), width: 7, height: 13),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFFD875),
    );
    canvas.restore();
  }

  void _drawPointOfInterest(Canvas canvas, WorldMapPointOfInterest poi) {
    final center = Offset(poi.position.x, poi.position.y);
    final colors = switch (poi.type) {
      WorldPointOfInterestType.water => (
        const Color(0xFF67D2D4),
        Icons.water_drop_rounded,
      ),
      WorldPointOfInterestType.village => (
        const Color(0xFFFFD37A),
        Icons.holiday_village_rounded,
      ),
      WorldPointOfInterestType.mill => (
        const Color(0xFFF3E7C1),
        Icons.factory_rounded,
      ),
      WorldPointOfInterestType.timberYard => (
        const Color(0xFFA8CF78),
        Icons.forest_rounded,
      ),
    };
    canvas.drawCircle(
      center + const Offset(0, 3),
      20,
      Paint()..color = const Color(0x55233924),
    );
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF214D36));
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = colors.$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.7,
    );
    _drawMapIcon(canvas, colors.$2, center, 20, colors.$1);
    if (zoom > 0.62) {
      _drawMapLabel(
        canvas,
        poi.name.toUpperCase(),
        center + const Offset(0, 28),
        12,
      );
    }
  }

  void _drawMapIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: size, textDirection: TextDirection.ltr),
          )
          ..pushStyle(ui.TextStyle(color: color, fontFamily: 'MaterialIcons'))
          ..addText(String.fromCharCode(icon.codePoint));
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size * 1.5));
    canvas.drawParagraph(
      paragraph,
      center - Offset(paragraph.width / 2, paragraph.height / 2),
    );
  }

  void _drawMeasurements(Canvas canvas) {
    final start = measureStart;
    final end = measureEnd;
    if (start == null) return;
    final first = Offset(start.x, start.y);
    if (end == null) {
      canvas.drawCircle(first, 12, Paint()..color = const Color(0xFFFFC84F));
      canvas.drawCircle(first, 7, Paint()..color = const Color(0xFF214D36));
      return;
    }
    final second = Offset(end.x, end.y);
    final path = Path()
      ..moveTo(first.dx, first.dy)
      ..lineTo(second.dx, second.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xCC173B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    _drawDashPath(
      canvas,
      path,
      Paint()
        ..color = const Color(0xFFFFD25D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
      dash: 18,
      gap: 13,
    );
    for (final point in [first, second]) {
      canvas.drawCircle(point, 11, Paint()..color = const Color(0xFFFFC84F));
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF214D36));
    }
  }

  void _drawWorldBoundaries(Canvas canvas) {
    final bounds = ProceduralFarmWorld.worldBounds;

    // Sınırın dışını kaplayan yarı saydam koyu sis ve keşfedilmemiş vadi alanı (EvenOdd fill)
    final fogPaint = Paint()
      ..color = const Color(0xEB112017)
      ..style = PaintingStyle.fill;

    const outerMargin = 6000.0;
    final outerRect = bounds.inflate(outerMargin);
    final fogPath = Path()
      ..addRect(outerRect)
      ..addRect(bounds)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(fogPath, fogPaint);

    // Çiftlik dünya sınırı parıltısı
    final borderGlow = Paint()
      ..color = const Color(0x55FFC84F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawRect(bounds, borderGlow);

    // Ana sınır ahşap çit hattı
    final borderFence = Paint()
      ..color = const Color(0xFF6B4526)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawRect(bounds, borderFence);

    // İç sınır çizgisi
    final dashPaint = Paint()
      ..color = const Color(0xFFFFE2A3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(bounds.inflate(-5), dashPaint);

    // Dört köşe sınır taşları ve işaret sütunları
    final cornerStonePaint = Paint()..color = const Color(0xFF382C22);
    final cornerPillarPaint = Paint()..color = const Color(0xFFFFC84F);
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];
    for (final corner in corners) {
      canvas.drawCircle(corner, 32, cornerStonePaint);
      canvas.drawCircle(corner, 20, cornerPillarPaint);
      canvas.drawCircle(corner, 8, cornerStonePaint);
    }
  }

  void _drawMapLabel(Canvas canvas, String text, Offset center, double width) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFFF4D9),
          fontSize: width,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          shadows: const [
            Shadow(
              color: Color(0xFF1B3424),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
            Shadow(color: Color(0xFF1B3424), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 230);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0x44112B1D)],
          stops: const [0.62, 1],
        ).createShader(rect),
    );
  }

  static void _drawDashPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) =>
      world != oldDelegate.world ||
      session != oldDelegate.session ||
      mapRevision != oldDelegate.mapRevision ||
      cameraCenter != oldDelegate.cameraCenter ||
      zoom != oldDelegate.zoom ||
      selectedParcelId != oldDelegate.selectedParcelId ||
      selectedFarmPlotId != oldDelegate.selectedFarmPlotId ||
      routeStartParcelId != oldDelegate.routeStartParcelId ||
      salesRouteStartPlotId != oldDelegate.salesRouteStartPlotId ||
      salesRouteMode != oldDelegate.salesRouteMode ||
      salesRouteStart != oldDelegate.salesRouteStart ||
      measureStart != oldDelegate.measureStart ||
      measureEnd != oldDelegate.measureEnd ||
      showParcels != oldDelegate.showParcels ||
      showRoutes != oldDelegate.showRoutes ||
      showInfrastructure != oldDelegate.showInfrastructure ||
      showFertility != oldDelegate.showFertility;
}

String _cropName(String cropId) => switch (cropId) {
  OpeningCropCatalog.wheatId => 'Buğday',
  OpeningCropCatalog.maizeId => 'Mısır',
  OpeningCropCatalog.sunflowerId => 'Ayçiçeği',
  OpeningCropCatalog.potatoId => 'Patates',
  OpeningCropCatalog.chickpeaId => 'Nohut',
  _ => FarmItemCatalog.nameFor(cropId),
};

class _SalesRouteSettings {
  const _SalesRouteSettings({
    required this.productId,
    required this.amountPerTrip,
    required this.repeatRoute,
  });

  final String? productId;
  final int? amountPerTrip;
  final bool repeatRoute;
}

Color _cropFamilyColor(CropFamily family) => switch (family) {
  CropFamily.grain => const Color(0xFFCBA653),
  CropFamily.oilseed => const Color(0xFF9DAD50),
  CropFamily.rootTuber => const Color(0xFF638F4C),
  CropFamily.legume => const Color(0xFF8DA65C),
};

String _fieldStatus(OpeningSession session, CropPlotState plot, DateTime now) {
  if (!plot.isOwned) return 'Satılık';
  final job = plot.activeJob;
  if (job != null) {
    return '${job.operation.label} · ${_formatRemaining(job.completesAt.difference(now))}';
  }
  if (plot.use == CropPlotUse.pasture) {
    if (plot.readyGrassBales > 0) return '${plot.readyGrassBales} balya hazır';
    final nextCut = plot.nextGrassCutAt;
    if (nextCut != null && now.isBefore(nextCut)) {
      return 'Ot büyüyor · ${_formatRemaining(nextCut.difference(now))}';
    }
    return 'Biçime hazır';
  }
  if (plot.hasActiveCrop) {
    final snapshot = session.cropSnapshotForPlot(plot.id, now);
    if (snapshot == null) return 'Ekin ekili';
    if (snapshot.isHarvestable) return 'Hasada hazır';
    return '${_cropName(snapshot.crop.id)} · ${(snapshot.growthProgress * 100).round()}%';
  }
  if (plot.hasHarvestedActiveCrop) {
    return plot.isCultivated
        ? 'Ekim için hazır'
        : 'Hasat tamamlandı · yeniden hazırlık bekliyor';
  }
  return plot.isCultivated ? 'Ekim için hazır' : 'Sürülmemiş';
}

class _FarmConstructionMenu extends StatefulWidget {
  const _FarmConstructionMenu({
    required this.session,
    required this.parcel,
    required this.onPickAnotherParcel,
    required this.onBuilt,
  });

  final OpeningSession session;
  final WorldMapParcel parcel;
  final VoidCallback onPickAnotherParcel;
  final VoidCallback onBuilt;

  @override
  State<_FarmConstructionMenu> createState() => _FarmConstructionMenuState();
}

class _FarmConstructionMenuState extends State<_FarmConstructionMenu> {
  FarmBuildingCategory? _category;

  @override
  Widget build(BuildContext context) {
    final items = FarmBuildingCatalog.all
        .where((item) => _category == null || item.category == _category)
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8E9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 9),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6BDA1),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.construction_rounded, color: _mapInk),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'İNŞAAT ALANI',
                        style: TextStyle(
                          color: _mapInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Başka arazi seç',
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPickAnotherParcel();
                      },
                      icon: const Icon(Icons.map_outlined),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Row(
                  children: [
                    const Icon(Icons.crop_square_rounded, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${widget.parcel.name} · ${widget.parcel.areaHectares.toStringAsFixed(2)} ha · '
                        '${_formatSquareMeters(widget.parcel.areaHectares)} m²',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF59664F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _categoryChip(null, 'Tümü'),
                    for (final category in FarmBuildingCategory.values)
                      _categoryChip(category, _buildingCategoryLabel(category)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildingOption(items[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(FarmBuildingCategory? category, String label) {
    final selected = _category == category;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _category = category),
        selectedColor: const Color(0xFFDDE9C8),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? _mapInk : const Color(0xFF69745D),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(
          color: selected ? const Color(0xFF75A25A) : const Color(0xFFE2D9BF),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildingOption(FarmBuildingDefinition item) {
    final reason = _buildingBlockReason(widget.session, widget.parcel, item);
    final canBuild = reason == null;
    final requirements = item.requiredTechnologyIds
        .map((id) => TechTreeCatalog.byId(id)?.name ?? id)
        .join(' + ');
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: canBuild ? const Color(0xFFB8C99F) : const Color(0xFFE4DCC7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EDD7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Image.asset(
              item.imageAsset,
              fit: BoxFit.contain,
              cacheWidth: 160,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.factory_rounded, color: _mapInk),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.minimumAreaHectares.toStringAsFixed(2)} ha arazi · ${_formatFarmCredits(item.constructionCostCredits)} ÇK',
                  style: const TextStyle(
                    color: Color(0xFF647255),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_formatRemaining(item.constructionDuration)} inşaat · ${_formatFarmCredits(item.dailyOperatingCostCredits)} ÇK/gün işletme gideri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF647255),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  canBuild ? 'Araştırma: $requirements' : reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: canBuild
                        ? const Color(0xFF568246)
                        : const Color(0xFF9C6040),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: FilledButton(
              onPressed: canBuild
                  ? () {
                      final started = widget.session.startBuildingConstruction(
                        item.id,
                        widget.parcel,
                      );
                      if (!started) return;
                      Navigator.pop(context);
                      widget.onBuilt();
                    }
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                backgroundColor: const Color(0xFF285439),
                disabledBackgroundColor: const Color(0xFFE5E2D6),
                disabledForegroundColor: const Color(0xFF878778),
              ),
              child: Text(
                canBuild ? 'İNŞA ET' : 'KİLİTLİ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _buildingBlockReason(
  OpeningSession session,
  WorldMapParcel parcel,
  FarmBuildingDefinition definition,
) {
  if (session.state.stage != OpeningStage.management) {
    return 'Yönetim aşaması gerekli';
  }
  if (!session.ownsWorldParcel(parcel.id)) return 'Arazi sana ait değil';
  if (parcel.isHome) return 'Çiftlik merkezine inşaat yapılamaz';
  if (parcel.areaHectares < definition.minimumAreaHectares) {
    return 'Bu yapı için en az ${definition.minimumAreaHectares.toStringAsFixed(2)} ha gerekir';
  }
  if (session.buildingOnParcel(parcel.id) != null) {
    return 'Bu arazide zaten yapı var';
  }
  final plot = session.plotForWorldParcel(parcel.id);
  if (plot != null &&
      (plot.hasActiveCrop || plot.hasActiveJob || plot.readyGrassBales > 0)) {
    return 'Önce tarladaki işi ve ürünü tamamla';
  }
  final missing = definition.requiredTechnologyIds
      .where((id) => !session.hasResearch(id))
      .map((id) => TechTreeCatalog.byId(id)?.name ?? id)
      .toList(growable: false);
  if (missing.isNotEmpty) return 'Araştırma gerekli: ${missing.join(' + ')}';
  if (session.farmCredits < definition.constructionCostCredits) {
    return 'İnşaat için yeterli bakiye yok';
  }
  return null;
}

class _FarmBuildingInfoCard extends StatelessWidget {
  const _FarmBuildingInfoCard({
    required this.building,
    required this.now,
    required this.onClose,
    required this.onResume,
  });

  final FarmBuildingInstance building;
  final DateTime now;
  final VoidCallback onClose;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final definition = FarmBuildingCatalog.byId(building.definitionId);
    if (definition == null) return const SizedBox.shrink();
    final isComplete = building.isCompleteAt(now);
    final isOperational = building.isOperationalAt(now);
    final remaining = building.remainingConstructionAt(now);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xF5FFF9E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6C99E), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44192E1D),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 54,
                child: Image.asset(
                  isComplete
                      ? definition.imageAsset
                      : FarmBuildingCatalog.constructionSiteAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 144,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.name,
                      style: const TextStyle(
                        color: _mapInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      !isComplete
                          ? 'İNŞA EDİLİYOR · ${_formatRemaining(remaining)}'
                          : building.pausedForOperatingCost
                          ? 'İŞLETME GİDERİ BEKLİYOR'
                          : isOperational
                          ? 'İŞLETMEDE'
                          : 'KURULUM BEKLİYOR',
                      style: TextStyle(
                        color: !isComplete
                            ? const Color(0xFFB47722)
                            : !isOperational
                            ? const Color(0xFF9C6040)
                            : const Color(0xFF568246),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: _mapInk),
              ),
            ],
          ),
          if (!isComplete) ...[
            LinearProgressIndicator(
              value: building.constructionProgressAt(now),
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF719D51),
              backgroundColor: const Color(0xFFE2DFC9),
            ),
          ],
          const SizedBox(height: 7),
          Text(
            isComplete
                ? definition.description
                : 'Kurulum tamamlanınca işlev devreye girer: ${definition.description}',
            style: const TextStyle(
              color: Color(0xFF59664F),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: _mapInk),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'İşletme gideri · ${_formatFarmCredits(definition.dailyOperatingCostCredits)} ÇK / gün',
                  style: const TextStyle(
                    color: _mapInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (building.pausedForOperatingCost)
                TextButton(onPressed: onResume, child: const Text('SÜRDÜR')),
            ],
          ),
        ],
      ),
    );
  }
}

String _buildingCategoryLabel(FarmBuildingCategory category) =>
    switch (category) {
      FarmBuildingCategory.production => 'Üretim',
      FarmBuildingCategory.storage => 'Depolama',
      FarmBuildingCategory.livestock => 'Hayvancılık',
      FarmBuildingCategory.logistics => 'Lojistik',
      FarmBuildingCategory.land => 'Arazi',
    };

String _formatSquareMeters(double hectares) => (hectares * 10000)
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

String _formatFarmCredits(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

String _formatRemaining(Duration duration) {
  final seconds = math.max(0, duration.inSeconds);
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return minutes == 0
      ? '$remainder sn'
      : '$minutes dk ${remainder.toString().padLeft(2, '0')} sn';
}

Color _mapCropColor(WorldCropType cropType) => switch (cropType) {
  WorldCropType.grain => const Color(0xFFCBA653),
  WorldCropType.oilseed => const Color(0xFF9DAD50),
  WorldCropType.vegetable => const Color(0xFF638F4C),
  WorldCropType.pasture => const Color(0xFF8DA65C),
};

String _mapCropLabel(WorldCropType cropType) => switch (cropType) {
  WorldCropType.grain => 'TAHIL',
  WorldCropType.oilseed => 'YAĞLI TOHUM',
  WorldCropType.vegetable => 'SEBZE',
  WorldCropType.pasture => 'MERA',
};

String _cropLabel(WorldCropType cropType) => switch (cropType) {
  WorldCropType.grain => 'Tahıl tarlası',
  WorldCropType.oilseed => 'Yağlı tohum',
  WorldCropType.vegetable => 'Sebze alanı',
  WorldCropType.pasture => 'Mera',
};

Color _cropColor(WorldCropType cropType) => _mapCropColor(cropType);

IconData _cropIcon(WorldCropType cropType) => switch (cropType) {
  WorldCropType.grain => Icons.grass_rounded,
  WorldCropType.oilseed => Icons.local_florist_rounded,
  WorldCropType.vegetable => Icons.eco_rounded,
  WorldCropType.pasture => Icons.park_rounded,
};
