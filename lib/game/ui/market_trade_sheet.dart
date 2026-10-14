import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/delivery_contracts.dart';
import '../domain/farm_item_catalog.dart';
import '../domain/logistics_fleet.dart';
import '../domain/market_price_simulator.dart';
import '../domain/opening_crop_catalog.dart';
import '../domain/opening_session.dart';
import '../domain/processing_plant.dart';

const Color _marketInk = Color(0xFF18392A);
const Color _marketGreen = Color(0xFF28583D);
const Color _marketGold = Color(0xFFFFC84F);
const Color _marketBg = Color(0xFFF7F9F5);
const Color _marketCardBg = Color(0xFFFFFFFF);

String _formatCredits(num amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K';
  }
  return amount.toStringAsFixed(0);
}

/// Kasaba Pazarı ve Emtia Borsası Yönetim Ekranı
class MarketTradeSheet extends StatefulWidget {
  const MarketTradeSheet({
    super.key,
    required this.session,
    required this.onChanged,
  });

  final OpeningSession session;
  final VoidCallback onChanged;

  static void show(BuildContext context, OpeningSession session, VoidCallback onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarketTradeSheet(session: session, onChanged: onChanged),
    );
  }

  @override
  State<MarketTradeSheet> createState() => _MarketTradeSheetState();
}

class _MarketTradeSheetState extends State<MarketTradeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Timer _ticker;
  String? _selectedDispatchItemId;
  int _dispatchAmount = 50;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _tabController.dispose();
    super.dispose();
  }

  OpeningSession get session => widget.session;

  List<String> _allTradeableItemIds() {
    final itemIds = <String>{
      ...OpeningCropCatalog.all
          .where((crop) => session.isCropUnlockedForFarm(crop.id))
          .map((crop) => crop.id),
      ...session.fleetManager.warehouseStock.map((batch) => batch.cropId),
      for (final facility in session.plantManager.facilities)
        for (final recipeId in session.availableProcessingRecipeIds(facility))
          if (ProcessingRecipeCatalog.byId(recipeId) case final recipe?)
            recipe.outputItemId,
      if (session.coop.isUnlocked) 'fresh_eggs',
      if (session.isBuildingOperational('greenhouse')) 'greenhouse_vegetables',
      if (session.isBuildingOperational('orchard')) 'orchard_fruit',
    }..removeWhere((id) => id.isEmpty);

    final list = itemIds.toList();
    list.sort((a, b) => FarmItemCatalog.nameFor(a).compareTo(FarmItemCatalog.nameFor(b)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final season = session.seasonAt(DateTime.now());
    final totalWarehouse = session.fleetManager.totalWarehouseAmount;
    final capacity = session.fleetManager.warehouseCapacity;
    final credits = session.farmCredits;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: const BoxDecoration(
        color: _marketBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _marketGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: _marketGold, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KASABA PAZARI & BORSA',
                        style: TextStyle(
                          color: _marketInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Mevsim: ${season.name.toUpperCase()} · Depo: $totalWarehouse/$capacity t',
                        style: const TextStyle(
                          color: Color(0xFF637365),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _marketGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: _marketGold, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${_formatCredits(credits)} ÇK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: _marketInk,
            unselectedLabelColor: const Color(0xFF7D8C7B),
            indicatorColor: _marketGreen,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.trending_up_rounded, size: 20), text: 'Borsa & Fiyatlar'),
              Tab(icon: Icon(Icons.local_shipping_rounded, size: 20), text: 'Sevkiyat Başlat'),
              Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 20), text: 'Sözleşmeler'),
            ],
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFDCE3D6)),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMarketPriceList(),
                _buildDispatchView(),
                _buildContractsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Borsa ve Fiyat Eğilimleri ---
  Widget _buildMarketPriceList() {
    final itemIds = _allTradeableItemIds();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: itemIds.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7D7BE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _marketGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Piyasa fiyatları mevsim döngüsüne ve kasaba arz-talep dengesine göre canlı dalgalanır. Yüksek fiyattan satmak için trendleri takip edin.',
                    style: TextStyle(
                      color: _marketInk.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final itemId = itemIds[index - 1];
        final quote = session.marketQuote(itemId);
        final stock = session.warehouseAmountFor(itemId);
        final name = FarmItemCatalog.nameFor(itemId);

        final trendIcon = switch (quote.trend) {
          PriceTrend.rising => const Icon(Icons.trending_up, color: Color(0xFF2E7D32), size: 18),
          PriceTrend.falling => const Icon(Icons.trending_down, color: Color(0xFFC62828), size: 18),
          PriceTrend.stable => const Icon(Icons.trending_flat, color: Color(0xFF616161), size: 18),
        };

        final trendLabel = switch (quote.trend) {
          PriceTrend.rising => 'Yükselişte',
          PriceTrend.falling => 'Düşüşte',
          PriceTrend.stable => 'Durgun',
        };

        final trendColor = switch (quote.trend) {
          PriceTrend.rising => const Color(0xFF2E7D32),
          PriceTrend.falling => const Color(0xFFC62828),
          PriceTrend.stable => const Color(0xFF616161),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _marketCardBg,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEDF3E8),
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '?',
                    style: const TextStyle(color: _marketGreen, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _marketInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Depo Stoku: $stock birim · Taban: ${quote.basePrice} ÇK',
                        style: const TextStyle(
                          color: Color(0xFF6B7A6A),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Aralık: ${quote.minPrice} - ${quote.maxPrice} ÇK',
                        style: const TextStyle(
                          color: Color(0xFF8B9B8A),
                          fontSize: 10,
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
                        color: _marketGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        trendIcon,
                        const SizedBox(width: 3),
                        Text(
                          trendLabel,
                          style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
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

  // --- TAB 2: Sevkiyat ve Tır Gönderim Paneli ---
  Widget _buildDispatchView() {
    final stockItems = session.fleetManager.warehouseStock
        .where((batch) => batch.amount > 0)
        .toList();

    if (stockItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF9FB09B)),
              const SizedBox(height: 12),
              const Text(
                'Ambarınızda Satılabilir Ürün Yok',
                style: TextStyle(
                  color: _marketInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tarlalarınızdan hasat yaparak veya üretim tesislerinizden işlenmiş ürün elde ederek ambara stok ekleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7A6A), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final availableItemIds = stockItems.map((b) => b.cropId).toSet().toList();
    if (_selectedDispatchItemId == null || !availableItemIds.contains(_selectedDispatchItemId)) {
      _selectedDispatchItemId = availableItemIds.first;
    }

    final currentItemStock = session.warehouseAmountFor(_selectedDispatchItemId!);
    final quote = session.marketQuote(_selectedDispatchItemId!);
    final vehicles = session.fleetManager.vehicles;

    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      _selectedVehicleId = vehicles.first.id;
    }

    final estimatedEarnings = _dispatchAmount * quote.currentPrice;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Ürün Seçimi
        const Text(
          '1. SEVK EDİLECEK ÜRÜNÜ SEÇİN',
          style: TextStyle(
            color: _marketInk,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6DEC9)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDispatchItemId,
              isExpanded: true,
              items: availableItemIds.map((id) {
                final amount = session.warehouseAmountFor(id);
                final q = session.marketQuote(id);
                return DropdownMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Text(
                        FarmItemCatalog.nameFor(id),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        '$amount birim (${q.currentPrice} ÇK)',
                        style: const TextStyle(color: Color(0xFF6B7A6A), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDispatchItemId = val;
                    final maxStock = session.warehouseAmountFor(val);
                    if (_dispatchAmount > maxStock) _dispatchAmount = maxStock;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Miktar Belirleme
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. SEVKİYAT MİKTARI',
              style: TextStyle(
                color: _marketInk,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$_dispatchAmount / $currentItemStock birim',
              style: const TextStyle(
                color: _marketGreen,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _marketGreen,
            inactiveTrackColor: const Color(0xFFD1DEC7),
            thumbColor: _marketGold,
          ),
          child: Slider(
            value: _dispatchAmount.toDouble().clamp(1.0, currentItemStock.toDouble()),
            min: 1.0,
            max: currentItemStock.toDouble() > 1.0 ? currentItemStock.toDouble() : 2.0,
            divisions: currentItemStock > 1 ? currentItemStock : 1,
            onChanged: (v) {
              setState(() {
                _dispatchAmount = v.round();
              });
            },
          ),
        ),

        const SizedBox(height: 12),

        // Araç Seçimi
        const Text(
          '3. SEVKİYAT ARACI (FİLO)',
          style: TextStyle(
            color: _marketInk,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        for (final vehicle in vehicles)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedVehicleId = vehicle.id;
              });
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: vehicle.id == _selectedVehicleId ? const Color(0xFFEAF2E5) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: vehicle.id == _selectedVehicleId ? _marketGreen : const Color(0xFFDEE5D6),
                  width: vehicle.id == _selectedVehicleId ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  vehicle.truckType == TruckType.heavyHauler
                      ? Icons.fire_truck_rounded
                      : Icons.local_shipping_rounded,
                  color: vehicle.fuelLevel < 15 ? Colors.red : _marketGreen,
                ),
                title: Text(
                  '${vehicle.truckType.name.toUpperCase()} (#${vehicle.id})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                subtitle: Text(
                  'Yakıt: %${vehicle.fuelLevel.toStringAsFixed(0)} · Aşınma: %${vehicle.wearPercent.toStringAsFixed(0)} · Durum: ${vehicle.status.name}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Icon(
                  vehicle.id == _selectedVehicleId
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: vehicle.id == _selectedVehicleId ? _marketGreen : Colors.grey,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Tahmini Gelir ve Buton
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE7EFE1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBED2B4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Birim Fiyat:',
                    style: TextStyle(color: Color(0xFF536352), fontSize: 12),
                  ),
                  Text(
                    '${quote.currentPrice} ÇK',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tahmini Brüt Kazanç:',
                    style: TextStyle(
                      color: _marketInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_formatCredits(estimatedEarnings)} ÇK',
                    style: const TextStyle(
                      color: _marketGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _marketGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.send_rounded, color: _marketGold),
            label: const Text(
              'TIRI PAZARA GÖNDER',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              final starterPlot = session.plotById(session.starterPlotId);
              final hasResearchL01 = session.hasResearch('L01');
              final started = session.startStarterMarketRoute(
                fieldX: starterPlot?.positionX.toDouble() ?? 0,
                fieldY: starterPlot?.positionY.toDouble() ?? 0,
                fieldName: 'Merkez Depo',
                productId: hasResearchL01 ? _selectedDispatchItemId : null,
                amountPerTrip: hasResearchL01
                    ? _dispatchAmount.clamp(1, TruckType.starter.capacity)
                    : null,
              );

              if (started) {
                widget.onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _marketGreen,
                    content: Text(
                      '🚚 Sevkiyat başladı: $_dispatchAmount birim ${FarmItemCatalog.nameFor(_selectedDispatchItemId!)} kasaba pazarına yola çıktı!',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'Sevkiyat başlatılamadı! Tır meşgul, yakıtı yetersiz veya ambar stoku eksik olabilir.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: Satış Sözleşmeleri ---
  Widget _buildContractsView() {
    final contracts = session.contractManager.visibleContracts;

    if (contracts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.assignment_outlined, size: 64, color: Color(0xFF9FB09B)),
              SizedBox(height: 12),
              Text(
                'Yeni Sözleşme Bekleniyor',
                style: TextStyle(color: _marketInk, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Pazar tüccarları periyodik olarak özel primli teslimat sözleşmeleri sunar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7A6A), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: contracts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final isAccepted = contract.status == DeliveryContractStatus.accepted;
        final isCompleted = contract.status == DeliveryContractStatus.completed;
        final itemName = FarmItemCatalog.nameFor(contract.itemId);
        final warehouseStock = session.warehouseAmountFor(contract.itemId);

        return Card(
          color: isCompleted
              ? const Color(0xFFE8F5E9)
              : isAccepted
                  ? const Color(0xFFFFF9C4)
                  : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isAccepted ? Colors.orangeAccent : const Color(0xFFD6DEC9),
              width: isAccepted ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isAccepted
                                ? Colors.orange
                                : _marketGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted
                            ? 'TAMAMLANDI'
                            : isAccepted
                                ? 'AKTİF SÖZLEŞME'
                                : 'TEKLİF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${_formatCredits(contract.rewardCredits)} ÇK Bonus',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  itemName,
                  style: const TextStyle(
                    color: _marketInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hedef: ${contract.targetAmount} birim · Teslim Edilen: ${contract.deliveredAmount} · Ambarda: $warehouseStock birim',
                  style: const TextStyle(color: Color(0xFF6B7A6A), fontSize: 11),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: contract.progress.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFDEE5D6),
                  color: isCompleted ? Colors.green : _marketGreen,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                if (!isAccepted && !isCompleted)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _marketGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 16),
                      label: const Text(
                        'Sözleşmeyi Kabul Et',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final ok = session.acceptDeliveryContract(contract.id);
                        if (ok) {
                          widget.onChanged();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: _marketGreen,
                              content: Text(
                                '🤝 Sözleşme kabul edildi! Rota hedefi ${FarmItemCatalog.nameFor(contract.itemId)} olarak bağlandı.',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Aynı anda yalnızca bir aktif sözleşme yönetebilirsiniz.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
