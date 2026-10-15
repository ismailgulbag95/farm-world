import 'opening_crop_catalog.dart';

/// Stable names and artwork paths for every item that can enter the warehouse.
abstract final class FarmItemCatalog {
  static const Map<String, String> _cropNames = {
    OpeningCropCatalog.wheatId: 'Buğday',
    OpeningCropCatalog.maizeId: 'Mısır',
    OpeningCropCatalog.sunflowerId: 'Ayçiçeği',
    OpeningCropCatalog.potatoId: 'Patates',
    OpeningCropCatalog.chickpeaId: 'Nohut',
  };

  static const Map<String, (String name, String asset)> _products = {
    'wheat_flour': ('Buğday unu', 'assets/images/products/wheat_flour.webp'),
    'cornmeal': ('Mısır unu', 'assets/images/products/cornmeal.webp'),
    'sunflower_oil': (
      'Ayçiçek yağı',
      'assets/images/products/sunflower_oil.webp',
    ),
    'potato_starch': (
      'Patates nişastası',
      'assets/images/products/potato_starch.webp',
    ),
    'chickpea_flour': (
      'Nohut unu',
      'assets/images/products/chickpea_flour.webp',
    ),
    'packed_potatoes': (
      'Paketlenmiş patates',
      'assets/images/products/packed_potatoes.webp',
    ),
    'fresh_eggs': ('Yumurta', 'assets/images/products/fresh_eggs.webp'),
    'fresh_milk': ('Taze Süt', 'assets/images/products/cow_milk.webp'),
    'wool_bale': ('Yün Balyası', 'assets/images/products/wool.webp'),
    'organic_fertilizer': (
      'Organik Kompost Gübre',
      'assets/images/equipment/fertilize_starter.webp',
    ),
    'grass_bale': ('Ot balyası', 'assets/images/equipment/bale_ova_1500.webp'),
    'goat_milk': ('Keçi sütü', 'assets/images/products/goat_milk.webp'),
    'honey': ('Bal', 'assets/images/products/honey.webp'),
    'wool': ('Yün', 'assets/images/products/wool.webp'),
    'cow_milk': ('Süt', 'assets/images/products/cow_milk.webp'),
    'greenhouse_vegetables': (
      'Sera sebzesi',
      'assets/images/products/greenhouse_vegetables.webp',
    ),
    'orchard_fruit': (
      'Bahçe meyvesi',
      'assets/images/products/orchard_fruit.webp',
    ),
  };

  static String nameFor(String itemId) {
    final product = _products[itemId];
    if (product != null) return product.$1;
    return _cropNames[itemId] ?? itemId;
  }

  static String? artworkFor(String itemId) {
    final product = _products[itemId];
    if (product != null) return product.$2;
    return OpeningCropCatalog.byId(itemId)?.artworkPath;
  }
}
