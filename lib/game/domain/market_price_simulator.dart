import 'dart:math';

import 'farm_calendar.dart';
import 'opening_crop_catalog.dart';

enum PriceTrend { rising, stable, falling }

class ItemPriceQuote {
  const ItemPriceQuote({
    required this.itemId,
    required this.currentPrice,
    required this.basePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.trend,
  });

  final String itemId;
  final int currentPrice;
  final int basePrice;
  final int minPrice;
  final int maxPrice;
  final PriceTrend trend;
}

/// Persisted seasonal supply simulator with a small, deterministic price cycle.
class MarketPriceSimulator {
  MarketPriceSimulator({
    Map<String, int>? recentSalesVolume,
    this.marketClockMinutes = 0,
    this.supplyDecayProgressMinutes = 0,
  }) : _salesVolume = recentSalesVolume ?? {};

  final Map<String, int> _salesVolume;
  double marketClockMinutes;
  double supplyDecayProgressMinutes;

  int getBasePrice(String itemId) {
    final crop = OpeningCropCatalog.byId(itemId);
    if (crop != null) {
      return (crop.fullHarvestValueCredits / 10).round().clamp(20, 300).toInt();
    }
    return switch (itemId) {
      'wheat_flour' => 85,
      'cornmeal' => 95,
      'sunflower_oil' => 175,
      'potato_starch' => 190,
      'chickpea_flour' => 155,
      'packed_potatoes' => 105,
      'fresh_eggs' => 45,
      'goat_milk' => 75,
      'cow_milk' => 82,
      'wool' => 115,
      'honey' => 125,
      'greenhouse_vegetables' => 92,
      'orchard_fruit' => 128,
      _ => 30,
    };
  }

  int calculatePrice(
    String itemId,
    Season season, {
    double randomVariance = 0.0,
  }) {
    final base = getBasePrice(itemId);
    final minPrice = (base * 0.60).round();
    final maxPrice = (base * 1.80).round();
    var seasonFactor = 1.0;
    final crop = OpeningCropCatalog.byId(itemId);
    if (crop != null) {
      seasonFactor = season != crop.plantingSeason ? 1.25 : 0.90;
    }
    final sold = _salesVolume[itemId] ?? 0;
    final supplyDiscount = (sold * 0.002).clamp(0.0, 0.35);
    final rawPrice =
        (base * seasonFactor * (1.0 - supplyDiscount) * (1.0 + randomVariance))
            .round();
    return rawPrice.clamp(minPrice, maxPrice).toInt();
  }

  void recordSale(String itemId, int amount) {
    if (amount <= 0) return;
    _salesVolume[itemId] = (_salesVolume[itemId] ?? 0) + amount;
  }

  void stepMarket(double deltaMinutes) {
    if (deltaMinutes <= 0) return;
    marketClockMinutes += deltaMinutes;
    supplyDecayProgressMinutes += deltaMinutes * 0.1;
    final decay = supplyDecayProgressMinutes.floor();
    if (decay <= 0) return;
    supplyDecayProgressMinutes -= decay;
    for (final key in _salesVolume.keys.toList()) {
      _salesVolume[key] = max(0, _salesVolume[key]! - decay);
    }
  }

  double _cycleVariance(String itemId) {
    final seed = itemId.codeUnits.fold<int>(
      17,
      (value, code) => (value * 31 + code) % 2147483647,
    );
    final phase = marketClockMinutes / 240.0 + seed * 0.013;
    return sin(phase) * 0.10;
  }

  ItemPriceQuote getQuote(String itemId, Season season) {
    final base = getBasePrice(itemId);
    final current = calculatePrice(
      itemId,
      season,
      randomVariance: _cycleVariance(itemId),
    );
    final previous = calculatePrice(
      itemId,
      season,
      randomVariance: _cycleVariance(itemId) - 0.01,
    );
    final trend = current > previous
        ? PriceTrend.rising
        : current < previous
        ? PriceTrend.falling
        : PriceTrend.stable;
    return ItemPriceQuote(
      itemId: itemId,
      currentPrice: current,
      basePrice: base,
      minPrice: (base * 0.60).round(),
      maxPrice: (base * 1.80).round(),
      trend: trend,
    );
  }

  Map<String, dynamic> toJson() => {
    'marketClockMinutes': marketClockMinutes,
    'supplyDecayProgressMinutes': supplyDecayProgressMinutes,
    'recentSalesVolume': _salesVolume,
  };

  factory MarketPriceSimulator.fromJson(Map<String, dynamic> json) =>
      MarketPriceSimulator(
        marketClockMinutes:
            (json['marketClockMinutes'] as num?)?.toDouble() ?? 0,
        supplyDecayProgressMinutes:
            (json['supplyDecayProgressMinutes'] as num?)?.toDouble() ?? 0,
        recentSalesVolume:
            (json['recentSalesVolume'] as Map<String, dynamic>? ?? const {})
                .map((key, value) => MapEntry(key, (value as num).toInt())),
      );
}
