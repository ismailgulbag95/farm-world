import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/crop_plot.dart';
import '../domain/delivery_contracts.dart';
import '../domain/farm_building.dart';
import '../domain/logistics_fleet.dart';
import '../domain/opening_crop_catalog.dart';
import '../domain/opening_session.dart';
import '../domain/processing_plant.dart';
import '../domain/market_price_simulator.dart';
import '../domain/farm_item_catalog.dart';

const Color _panelInk = Color(0xFF18392A);
const Color _panelGreen = Color(0xFF28583D);
const Color _panelGold = Color(0xFFFFC84F);

class FarmManagementSheet extends StatefulWidget {
  const FarmManagementSheet({
    super.key,
    required this.session,
    required this.onSelectPlot,
    required this.onSelectVehicle,
    required this.onChanged,
  });

  final OpeningSession session;
  final ValueChanged<CropPlotState> onSelectPlot;
  final ValueChanged<FleetVehicleState> onSelectVehicle;
  final VoidCallback onChanged;

  @override
  State<FarmManagementSheet> createState() => _FarmManagementSheetState();
}

class _FarmManagementSheetState extends State<FarmManagementSheet> {
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
    final session = widget.session;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 3, 18, 10),
              child: Row(
                children: [
                  const Icon(Icons.dashboard_rounded, color: _panelInk),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'ÇİFTLİK YÖNETİMİ',
                      style: TextStyle(
                        color: _panelInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_credits(session.farmCredits)} ÇK',
                    style: const TextStyle(
                      color: _panelInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _panelInk,
              unselectedLabelColor: const Color(0xFF74806C),
              indicatorColor: const Color(0xFF527345),
              tabs: const [
                Tab(icon: Icon(Icons.grass_rounded), text: 'Araziler'),
                Tab(icon: Icon(Icons.local_shipping_rounded), text: 'Filo'),
                Tab(icon: Icon(Icons.factory_rounded), text: 'Yapılar'),
                Tab(icon: Icon(Icons.storefront_rounded), text: 'Pazar'),
                Tab(icon: Icon(Icons.assignment_rounded), text: 'Sözleşmeler'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _FieldsPanel(
                    session: session,
                    onSelectPlot: widget.onSelectPlot,
                  ),
                  _FleetPanel(
                    session: session,
                    onSelectVehicle: widget.onSelectVehicle,
                    onChanged: _changed,
                  ),
                  _BuildingsPanel(session: session, onChanged: _changed),
                  _MarketPanel(session: session),
                  _ContractsPanel(session: session, onChanged: _changed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changed() {
    widget.onChanged();
    if (mounted) setState(() {});
  }
}

class _FieldsPanel extends StatelessWidget {
  const _FieldsPanel({required this.session, required this.onSelectPlot});

  final OpeningSession session;
  final ValueChanged<CropPlotState> onSelectPlot;

  @override
  Widget build(BuildContext context) {
    final plots = session.plots.where((plot) => plot.isOwned).toList();
    if (plots.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.grass_rounded,
        title: 'Henüz yönetilen arazi yok',
        body: 'Haritadan bir arazi satın alıp üretime açabilirsin.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: plots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final plot = plots[index];
        final recent = plot.recentCropFamilies
            .take(3)
            .map(_familyName)
            .join(' → ');
        final activeCrop = plot.activeCropId == null
            ? (plot.use == CropPlotUse.pasture ? 'Çayır' : 'Boş tarla')
            : _itemName(plot.activeCropId!);
        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.78),
          child: ListTile(
            onTap: () {
              Navigator.of(context).pop();
              onSelectPlot(plot);
            },
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEAF0E2),
              child: Icon(
                plot.use == CropPlotUse.pasture
                    ? Icons.grass_rounded
                    : Icons.agriculture_rounded,
                color: _panelGreen,
              ),
            ),
            title: Text(
              plot.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '$activeCrop · ${(plot.areaSquareMeters / 10000).toStringAsFixed(2)} ha · Toprak ${plot.soilConditionPoints}/100\n'
              'Son ekimler: ${recent.isEmpty ? 'Henüz geçmiş yok' : recent}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class _FleetPanel extends StatelessWidget {
  const _FleetPanel({
    required this.session,
    required this.onSelectVehicle,
    required this.onChanged,
  });

  final OpeningSession session;
  final ValueChanged<FleetVehicleState> onSelectVehicle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final fleet = session.fleetManager;
    if (fleet.vehicles.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.local_shipping_outlined,
        title: 'Henüz araç yok',
        body: 'İlk hasadın ardından başlangıç kamyoneti filoya katılır.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: fleet.vehicles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final vehicle = fleet.vehicles[index];
        final route = fleet.routes.where(
          (item) => item.id == vehicle.assignedRouteId,
        );
        final routeName = route.isEmpty ? 'Rota yok' : route.first.name;
        final queueNames = vehicle.queuedRouteIds
            .map((id) => fleet.routes.where((route) => route.id == id))
            .where((routes) => routes.isNotEmpty)
            .map((routes) => routes.first.name)
            .join(' · ');
        final serviceCost = fleet.serviceCostFor(vehicle);
        final status = _vehicleStatus(vehicle.status);
        final vehiclePaused = vehicle.isIndividuallyPaused;
        final routePaused = route.isNotEmpty && !route.first.isActive;
        final canToggleVehicle =
            (vehicle.assignedRouteId != null ||
                vehicle.queuedRouteIds.isNotEmpty) &&
            !routePaused;
        final visibleStatus = routePaused ? 'Hat genel duraklatıldı' : status;
        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.80),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pop();
              onSelectVehicle(vehicle);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 9, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: _panelGreen,
                        child: Icon(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$visibleStatus · $routeName',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (canToggleVehicle)
                        IconButton(
                          tooltip: vehiclePaused
                              ? 'Aracı sürdür'
                              : 'Aracı duraklat',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            if (session.setFleetVehiclePaused(
                              vehicle.id,
                              !vehiclePaused,
                            )) {
                              onChanged();
                            }
                          },
                          icon: Icon(
                            vehiclePaused
                                ? Icons.play_circle_outline_rounded
                                : Icons.pause_circle_outline_rounded,
                            color: _panelGreen,
                          ),
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'Araç ve rota işlemleri',
                        enabled: fleet.routes.isNotEmpty,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: _panelGreen,
                        ),
                        itemBuilder: (context) => [
                          if (route.isNotEmpty)
                            PopupMenuItem<String>(
                              value: 'route:${route.first.id}',
                              child: Text(
                                route.first.isActive
                                    ? 'Bu rotayı tüm araçlarda duraklat'
                                    : 'Bu rotayı tüm araçlarda sürdür',
                              ),
                            ),
                          ...fleet.routes.map(
                            (candidate) => PopupMenuItem<String>(
                              value: 'queue:${candidate.id}',
                              enabled:
                                  vehicle.fuelLevel > 0.01 &&
                                  vehicle.wearPercent < 100,
                              child: Text(
                                'Sefer ekle · ${candidate.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value.startsWith('route:')) {
                            final routeId = value.substring('route:'.length);
                            final assigned = fleet.routes.where(
                              (candidate) => candidate.id == routeId,
                            );
                            if (assigned.isNotEmpty &&
                                session.setFleetRouteActive(
                                  routeId,
                                  !assigned.first.isActive,
                                )) {
                              onChanged();
                            }
                          } else if (value.startsWith('queue:') &&
                              session.queueFleetRoute(
                                vehicle.id,
                                value.substring('queue:'.length),
                              )) {
                            onChanged();
                          }
                        },
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _panelGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${vehicle.hasCargo ? '${_itemName(vehicle.cargoCropId!)} · ${vehicle.cargoAmount}/${vehicle.effectiveCapacity}' : 'Yük yok · ${vehicle.effectiveCapacity} kapasite'} · ${vehicle.effectiveSpeed.round()} km/sa',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF536247),
                      ),
                    ),
                  ),
                  if (queueNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Sıradaki işler: $queueNames',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (vehicle.fuelLevel < 80 || vehicle.wearPercent > 20)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: session.farmCredits >= serviceCost
                            ? () {
                                if (session.serviceFleetVehicle(vehicle.id))
                                  onChanged();
                              }
                            : null,
                        icon: const Icon(Icons.build_circle_outlined, size: 17),
                        label: Text(
                          'Bakım ve yakıt · ${_credits(serviceCost)} ÇK',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuildingsPanel extends StatelessWidget {
  const _BuildingsPanel({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final buildings = session.buildings;
    if (buildings.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.factory_outlined,
        title: 'İnşa edilmiş yapı yok',
        body: 'İnşaat menüsünden araştırdığın bir tesisi uygun parsele yerleştir.',
      );
    }
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: buildings.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0E2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Günlük işletme gideri: ${_credits(session.dailyBuildingOperatingCost)} ÇK · Ambar kapasitesi: ${session.fleetManager.warehouseCapacity} birim',
              style: const TextStyle(
                color: _panelInk,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          );
        }
        final building = buildings[index - 1];
        final definition = FarmBuildingCatalog.byId(building.definitionId);
        if (definition == null) return const SizedBox.shrink();
        final complete = building.isCompleteAt(now);
        final paused = building.pausedForOperatingCost;
        final facility = session.facilityForBuilding(building);
        final status = !complete
            ? 'İnşaat sürüyor · ${building.remainingConstructionAt(now).inSeconds} sn'
            : paused
            ? 'İşletme gideri bekleniyor'
            : _facilityStatus(facility?.status);
        final input = facility?.totalInputAmount ?? 0;
        final output = facility?.totalOutputAmount ?? 0;
        final category = _buildingCategory(definition.category);
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Colors.white.withValues(alpha: 0.82),
          child: ExpansionTile(
            leading: SizedBox(
              width: 52,
              height: 48,
              child: Image.asset(
                definition.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.factory_rounded, color: _panelGreen),
              ),
            ),
            title: Text(
              definition.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            subtitle: Text(
              '$category · $status',
              style: const TextStyle(fontSize: 10),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  definition.description,
                  style: const TextStyle(fontSize: 11, height: 1.35),
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    label:
                        'İşletme gideri ${_credits(definition.dailyOperatingCostCredits)} ÇK/gün',
                  ),
                  if (definition.warehouseCapacityBonus > 0)
                    _InfoChip(
                      label: '+${definition.warehouseCapacityBonus} ambar yeri',
                    ),
                  if (definition.logisticsSpeedBonus > 0)
                    _InfoChip(
                      label:
                          '+%${(definition.logisticsSpeedBonus * 100).round()} taşıma hızı',
                    ),
                  if (definition.recipeIds.isNotEmpty)
                    _InfoChip(label: 'Girdi $input · tesis çıkışı $output'),
                  if (facility != null)
                    _InfoChip(
                      label:
                          'Toplam işlenen ${facility.totalInputProcessed} · üretilen ${facility.totalOutputProduced}',
                    ),
                  if (definition.id == 'greenhouse' ||
                      definition.id == 'orchard')
                    _InfoChip(
                      label:
                          'Ambar ürünü: ${_itemName(definition.id == 'greenhouse' ? 'greenhouse_vegetables' : 'orchard_fruit')}',
                    ),
                  if (definition.recipeIds.isEmpty &&
                      definition.warehouseCapacityBonus == 0 &&
                      definition.logisticsSpeedBonus == 0 &&
                      definition.id != 'greenhouse' &&
                      definition.id != 'orchard')
                    const _InfoChip(
                      label: 'İlgili ürün zinciri açılınca işletme etkisi etkinleşir',
                    ),
                ],
              ),
              if (!complete)
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: LinearProgressIndicator(
                    value: building.constructionProgressAt(now),
                    color: _panelGreen,
                    backgroundColor: const Color(0xFFE5E0D2),
                  ),
                ),
              if (paused)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        session.farmCredits >=
                            definition.dailyOperatingCostCredits
                        ? () {
                            if (session.resumeBuildingAfterOperatingCost(
                              building.parcelId,
                            )) {
                              onChanged();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 17),
                    label: Text(
                      'Tekrar çalıştır · ${_credits(definition.dailyOperatingCostCredits)} ÇK',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MarketPanel extends StatelessWidget {
  const _MarketPanel({required this.session});

  final OpeningSession session;

  @override
  Widget build(BuildContext context) {
    final itemIds =
        <String>{
            ...OpeningCropCatalog.all
                .where((crop) => session.isCropUnlockedForFarm(crop.id))
                .map((crop) => crop.id),
            ...session.fleetManager.warehouseStock.map((batch) => batch.cropId),
            for (final facility in session.plantManager.facilities)
              for (final recipeId in session.availableProcessingRecipeIds(
                facility,
              ))
                if (ProcessingRecipeCatalog.byId(recipeId) case final recipe?)
                  recipe.outputItemId,
            if (session.coop.isUnlocked) 'fresh_eggs',
            if (session.isBuildingOperational('greenhouse'))
              'greenhouse_vegetables',
            if (session.isBuildingOperational('orchard')) 'orchard_fruit',
          }.toList()
          ..sort((left, right) => _itemName(left).compareTo(_itemName(right)));
    final inventoryTotal = session.fleetManager.totalWarehouseAmount;
    final inventoryValue = session.fleetManager.warehouseStock
        .fold<double>(
          0,
          (total, batch) =>
              total +
              batch.amount *
                  session.marketQuote(batch.cropId).currentPrice *
                  batch.quality,
        )
        .round();
    final dailyOperatingCost = session.dailyBuildingOperatingCost;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Depoda $inventoryTotal/${session.fleetManager.warehouseCapacity} birim var. Bugünkü tahmini stok değeri ${_credits(inventoryValue)} ÇK. Yapılar ${_credits(dailyOperatingCost)} ÇK/gün işletme gideri oluşturuyor${dailyOperatingCost > 0 ? ' · mevcut bakiye yaklaşık ${session.farmCredits ~/ dailyOperatingCost} gün yeter' : ''}. Satış rotası ürünleri pazara ulaştırdığında geçerli fiyat üzerinden satar; stokta bekletmek fiyat hareketini izleme seçeneği verir.',
            style: const TextStyle(
              color: _panelInk,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 9),
        for (final itemId in itemIds)
          _MarketItemCard(session: session, itemId: itemId),
      ],
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  const _MarketItemCard({required this.session, required this.itemId});

  final OpeningSession session;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    final quote = session.marketQuote(itemId);
    final amount = session.warehouseAmountFor(itemId);
    final trend = switch (quote.trend) {
      PriceTrend.rising => (
        Icons.trending_up_rounded,
        const Color(0xFF477A3B),
        'Yükseliyor',
      ),
      PriceTrend.falling => (
        Icons.trending_down_rounded,
        const Color(0xFF9A5D36),
        'Düşüyor',
      ),
      PriceTrend.stable => (
        Icons.trending_flat_rounded,
        const Color(0xFF69705F),
        'Dengeli',
      ),
    };
    final value = amount * quote.currentPrice;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      color: Colors.white.withValues(alpha: 0.82),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            _ProductArtwork(itemId: itemId),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _itemName(itemId),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$amount birim stok · tahmini değer ${_credits(value)} ÇK',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'Taban ${quote.basePrice} · aralık ${quote.minPrice}–${quote.maxPrice} ÇK/birim',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF69705F),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${quote.currentPrice} ÇK',
                  style: const TextStyle(
                    color: _panelInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trend.$1, size: 14, color: trend.$2),
                    Text(
                      trend.$3,
                      style: TextStyle(fontSize: 9, color: trend.$2),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractsPanel extends StatelessWidget {
  const _ContractsPanel({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final contracts = session.contractManager.visibleContracts;
    final active = session.contractManager.activeContract;
    if (contracts.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.assignment_outlined,
        title: 'Yeni sözleşme bekleniyor',
        body: 'Pazar her gün teslimat hedefleri yeniler.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: contracts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0C8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Sözleşmeler normal satışın üstüne bonus verir. Bir sözleşmeyi kabul et; kurulu satış hattı ürünü otomatik seçer. Teslimat ancak pazara varınca sayılır.',
              style: TextStyle(
                color: _panelInk,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final contract = contracts[index - 1];
        final canAccept =
            contract.status == DeliveryContractStatus.offered && active == null;
        final status = switch (contract.status) {
          DeliveryContractStatus.offered => 'Teklif',
          DeliveryContractStatus.accepted => 'Aktif sözleşme',
          DeliveryContractStatus.completed => 'Tamamlandı',
          DeliveryContractStatus.expired => 'Süresi doldu',
        };
        final remaining = contract.deadline.difference(DateTime.now());
        final deadline = remaining.isNegative
            ? 'Süresi doldu'
            : '${remaining.inHours} sa ${remaining.inMinutes.remainder(60)} dk kaldı';
        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.84),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: _panelGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _itemName(contract.itemId),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: _panelGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${contract.remainingAmount}/${contract.targetAmount} birim · kalite en az %${(contract.minimumQuality * 100).round()} · $deadline',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: contract.progress.clamp(0.0, 1.0),
                  color: _panelGreen,
                  backgroundColor: const Color(0xFFE3E0D3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Teslimat bonusu ${_credits(contract.rewardCredits)} ÇK',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (contract.status == DeliveryContractStatus.offered)
                      FilledButton(
                        onPressed: canAccept
                            ? () {
                                if (session.acceptDeliveryContract(contract.id))
                                  onChanged();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _panelGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Kabul et'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 46,
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ),
      Expanded(
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          color: label == 'Aşınma' && value > 0.65
              ? const Color(0xFFB56D31)
              : _panelGreen,
          backgroundColor: const Color(0xFFE3E0D3),
        ),
      ),
      SizedBox(
        width: 35,
        child: Text(
          trailing,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0E2),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _panelInk,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
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
          Icon(icon, size: 42, color: const Color(0xFF7C8B71)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _panelInk,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF536247), fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

String _vehicleStatus(VehicleStatus status) => switch (status) {
  VehicleStatus.idle => 'Beklemede',
  VehicleStatus.traveling => 'Yolda',
  VehicleStatus.paused => 'Hat duraklatıldı',
  VehicleStatus.loading => 'Yük alıyor',
  VehicleStatus.unloading => 'Yük boşaltıyor',
  VehicleStatus.divertingToSell => 'Pazara yönleniyor',
  VehicleStatus.waitingForSpace => 'Depoda yer bekliyor',
  VehicleStatus.outOfFuel => 'Yakıt bitti',
  VehicleStatus.serviceDue => 'Bakım gerekli',
};

String _facilityStatus(FacilityStatus? status) => switch (status) {
  null => 'Hazır',
  FacilityStatus.idle => 'Beklemede',
  FacilityStatus.processing => 'Üretim yapıyor',
  FacilityStatus.starvedInput => 'Girdi bekliyor',
  FacilityStatus.blockedOutput => 'Ambar kapasitesi bekliyor',
};

String _buildingCategory(FarmBuildingCategory category) => switch (category) {
  FarmBuildingCategory.production => 'Üretim',
  FarmBuildingCategory.storage => 'Depolama',
  FarmBuildingCategory.livestock => 'Hayvancılık',
  FarmBuildingCategory.logistics => 'Lojistik',
  FarmBuildingCategory.land => 'Arazi',
};

String _familyName(CropFamily family) => switch (family) {
  CropFamily.grain => 'Tahıl',
  CropFamily.oilseed => 'Yağlı tohum',
  CropFamily.rootTuber => 'Kök/yumru',
  CropFamily.legume => 'Baklagil',
};

String _itemName(String itemId) => switch (itemId) {
  'CR01' => 'Buğday',
  'CR02' => 'Mısır',
  'CR03' => 'Ayçiçeği',
  'CR04' => 'Patates',
  'CR05' => 'Nohut',
  'wheat_flour' => 'Buğday unu',
  'cornmeal' => 'Mısır unu',
  'sunflower_oil' => 'Ayçiçek yağı',
  'potato_starch' => 'Patates nişastası',
  'chickpea_flour' => 'Nohut unu',
  'packed_potatoes' => 'Paketlenmiş patates',
  'fresh_eggs' => 'Yumurta',
  'goat_milk' => 'Keçi sütü',
  'cow_milk' => 'Süt',
  'wool' => 'Yün',
  'honey' => 'Bal',
  'greenhouse_vegetables' => 'Sera sebzesi',
  'orchard_fruit' => 'Bahçe meyvesi',
  _ => FarmItemCatalog.nameFor(itemId),
};

class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final path = FarmItemCatalog.artworkFor(itemId);
    if (path == null) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFEAF0E2),
        child: Icon(Icons.inventory_rounded, size: 18, color: _panelGreen),
      );
    }
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF0E2),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.inventory_rounded, size: 18, color: _panelGreen),
      ),
    );
  }
}

String _credits(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);
