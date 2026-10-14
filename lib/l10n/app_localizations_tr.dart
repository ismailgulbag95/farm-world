// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get gameTitle => 'Farm World';

  @override
  String get startingField => 'Yeni bir başlangıç';

  @override
  String get farmCredits => 'Çiftlik kredisi';

  @override
  String get changeLanguage => 'Dili değiştir';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get openingScytheTitle => 'İlk balyan';

  @override
  String get openingScytheBody =>
      'Joystick\'i yukarı itip çayıra ilerle. Çimi biçmek için hareket et; balya çıkınca üzerinden geçip al.';

  @override
  String get openingMowingProgressLabel => 'İlk balya ilerlemesi';

  @override
  String openingMowerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# balya satışı kaldı',
    );
    return 'Mini makine için $_temp0';
  }

  @override
  String openingWorkerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# balya satışı kaldı',
    );
    return 'İşçi için $_temp0';
  }

  @override
  String get baleNearbyTitle => 'Bir balya hazır';

  @override
  String get baleNearbyBody =>
      'Üzerinden geçip al, sonra ahşap platforma taşı.';

  @override
  String get baleCarryTitle => 'Balyanı sat';

  @override
  String baleCarryBody(Object amount) {
    return '$amount kredi kazanmak için teslim platformuna götür.';
  }

  @override
  String get mowerUpgradeTitle => 'Mini çim biçme makinesi al';

  @override
  String get mowerUpgradeBody =>
      'Daha hızlı ilerle ve çayırda daha geniş bir alanı biç.';

  @override
  String get workerTitle => 'Makineyi devret';

  @override
  String get workerNeedClearBody =>
      'İşçi almadan önce yerdeki ve elindeki tüm balyaları teslim et.';

  @override
  String workerNeedFundsBody(Object amount) {
    return 'Balyaları satmaya devam et. İşçi almak için $amount kredi daha gerekiyor.';
  }

  @override
  String get workerReadyBody =>
      'İşçi makineyi devralacak ve ilk parseli açacak.';

  @override
  String get managementTitle => 'Çiftliğin otomasyona geçti';

  @override
  String get managementBody =>
      'Başlangıç parseli ve bir ücretsiz ekim tohumu hazır.';

  @override
  String get starterPlotReadyTitle => 'İlk tarlan hazır';

  @override
  String get starterPlotReadyBody =>
      'Ücretsiz mısır tohumunu ek. İlk ürün, garantili ilkbahar ekim dönemine göre seçildi.';

  @override
  String get plantMaize => 'Mısır ek';

  @override
  String get plantWheat => 'Buğday ek';

  @override
  String get freeStarterSeed => 'Ücretsiz başlangıç tohumu';

  @override
  String cropGrowingTitle(String crop) {
    return '$crop büyüyor';
  }

  @override
  String cropGrowingBody(String percent, String minutes) {
    return '$percent% büyüdü · yaklaşık $minutes dk kaldı.';
  }

  @override
  String get cropReadyTitle => 'Hasat zamanı';

  @override
  String cropReadyBody(String crop) {
    return '$crop hasada hazır.';
  }

  @override
  String firstTradeReadyBody(String crop, String amount) {
    return 'İlk takası tamamlamak için $crop ürününü hasat et. Başlangıç tahıl kamyonunu ve $amount kredi alacaksın.';
  }

  @override
  String get harvestAndTrade => 'Hasat et ve takas yap';

  @override
  String get harvestCrop => 'Hasat et ve sat';

  @override
  String firstTradeReward(String amount) {
    return 'Kamyon + $amount kredi';
  }

  @override
  String get starterTruckReceivedTitle => 'İlk teslimat kamyonun';

  @override
  String starterTruckReceivedBody(String amount, String seedCost) {
    return 'Başlangıç tahıl kamyonu ve $amount kredi senin. $seedCost krediye yeniden buğday veya mısır ekebilirsin.';
  }

  @override
  String cropSaleValue(String amount) {
    return 'Ürün değeri: $amount kredi';
  }

  @override
  String get maizeCropName => 'Mısır';

  @override
  String get wheatCropName => 'Buğday';

  @override
  String get sunflowerCropName => 'Ayçiçeği';

  @override
  String get potatoCropName => 'Patates';

  @override
  String get chickpeaCropName => 'Nohut';

  @override
  String firstDiversityProgress(String complete, String required) {
    return 'İlk çeşitlilik rotası: $complete / $required';
  }

  @override
  String get firstDiversityHint =>
      'Bir tam tahıl hasadı ve ayçiçeği ya da patatesten bir tam hasat al.';

  @override
  String get firstDiversityComplete =>
      'İlk çeşitlilik kilometre taşı tamamlandı.';

  @override
  String openingP2Progress(String current, String required) {
    return 'P2 üretim kanıtı: $current / $required ÇK';
  }

  @override
  String get soilConditionTitle => 'Toprak durumu';

  @override
  String soilConditionValue(String points, String yieldPercent) {
    return '$points/100 · tahmini verim %$yieldPercent';
  }

  @override
  String soilCareRule(String correction, String trigger, String cost) {
    return 'Her tam hasat toprağı 1 puan düşürür. T02, $trigger puanın altında $cost ÇK karşılığında $correction puan ekler.';
  }

  @override
  String get researchSoilCare => 'Toprak bakımını araştır';

  @override
  String get soilCareAutomationOn => 'Otomatik bakım: açık';

  @override
  String get soilCareAutomationOff => 'Otomatik bakım: kapalı';

  @override
  String get soilCareAutomationPaused => 'Otomatik toprak bakımı duraklatıldı.';

  @override
  String soilCareAwaitingFunds(String amount) {
    return 'Toprak bakımı için $amount ÇK bekleniyor. Ekim ve hasat sürer.';
  }

  @override
  String get researchOilseedFamily => 'Yağlı tohum ailesini aç';

  @override
  String get researchRootTuberFamily => 'Kök ve yumru ailesini aç';

  @override
  String get researchSunflowerCrop => 'Ayçiçeği ekimini aç';

  @override
  String get researchPotatoCrop => 'Patates ekimini aç';

  @override
  String get researchLegumeFamily => 'Baklagil ailesini aç';

  @override
  String get researchChickpeaCrop => 'Nohut ekimini aç';

  @override
  String get plantSunflower => 'Ayçiçeği ek';

  @override
  String get plantPotato => 'Patates ek';

  @override
  String get plantChickpeas => 'Nohut ek';

  @override
  String get chickpeaArtworkAccessibility => 'Nohut gelişim aşamaları';

  @override
  String get sunflowerArtworkAccessibility => 'Olgun ayçiçeği tarlası';

  @override
  String get potatoArtworkAccessibility => 'Olgun patates tarlası';

  @override
  String get truckArtworkAccessibility => 'Başlangıç tahıl kamyonu';

  @override
  String get cropPlotAccessibility => 'Başlangıç ürün tarlası';

  @override
  String get buyMower => 'Mini makineyi al';

  @override
  String get hireWorker => 'İşçi al';

  @override
  String costAmount(Object amount) {
    return '$amount kredi';
  }

  @override
  String get gameplayAccessibility =>
      'Farm World oyunu. Tarlada hareket etmek için sanal kontrol çubuğunu kullan.';

  @override
  String get joystickAccessibility => 'Sanal hareket kontrol çubuğu';

  @override
  String get workerArtworkAccessibility => 'Çiftlik işçisi';

  @override
  String get mowerArtworkAccessibility => 'Mini çim biçme makinesi';
}
