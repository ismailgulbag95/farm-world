// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gameTitle => 'Farm World';

  @override
  String get startingField => 'A fresh start';

  @override
  String get farmCredits => 'Farm credits';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get openingScytheTitle => 'Your first bale';

  @override
  String get openingScytheBody =>
      'Push the joystick up into the meadow. Keep moving to cut grass; walk over each bale to collect it.';

  @override
  String get openingMowingProgressLabel => 'First bale progress';

  @override
  String openingMowerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# bale sales left',
      one: '# bale sale left',
    );
    return 'Mini mower: $_temp0';
  }

  @override
  String openingWorkerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# bale sales left',
      one: '# bale sale left',
    );
    return 'Worker: $_temp0';
  }

  @override
  String get baleNearbyTitle => 'A bale is ready';

  @override
  String get baleNearbyBody =>
      'Walk over it, then carry it to the wooden platform.';

  @override
  String get baleCarryTitle => 'Sell your bale';

  @override
  String baleCarryBody(Object amount) {
    return 'Take it to the receiving platform to earn $amount credits.';
  }

  @override
  String get mowerUpgradeTitle => 'Bring in a mini mower';

  @override
  String get mowerUpgradeBody =>
      'Move faster and cut a wider path through the meadow.';

  @override
  String get workerTitle => 'Hand over the mower';

  @override
  String get workerNeedClearBody =>
      'Sell every bale on the ground or in your hands before hiring a worker.';

  @override
  String workerNeedFundsBody(Object amount) {
    return 'Keep selling bales. You need $amount more credits to hire a worker.';
  }

  @override
  String get workerReadyBody =>
      'Your worker will take over the mower and unlock the first plot.';

  @override
  String get managementTitle => 'Your farm is automated';

  @override
  String get managementBody =>
      'The starting plot and one free crop seed are ready.';

  @override
  String get starterPlotReadyTitle => 'Your first field is ready';

  @override
  String get starterPlotReadyBody =>
      'Plant the free maize seed. The first crop is chosen for the guaranteed spring planting window.';

  @override
  String get plantMaize => 'Plant maize';

  @override
  String get plantWheat => 'Plant wheat';

  @override
  String get freeStarterSeed => 'Free starter seed';

  @override
  String cropGrowingTitle(String crop) {
    return '$crop is growing';
  }

  @override
  String cropGrowingBody(String percent, String minutes) {
    return '$percent% grown · about $minutes min left.';
  }

  @override
  String get cropReadyTitle => 'Time to harvest';

  @override
  String cropReadyBody(String crop) {
    return '$crop is ready for harvest.';
  }

  @override
  String firstTradeReadyBody(String crop, String amount) {
    return 'Harvest $crop to complete your first trade. You will receive the starter grain truck and $amount credits.';
  }

  @override
  String get harvestAndTrade => 'Harvest and trade';

  @override
  String get harvestCrop => 'Harvest and sell';

  @override
  String firstTradeReward(String amount) {
    return 'Truck + $amount credits';
  }

  @override
  String get starterTruckReceivedTitle => 'Your first delivery truck';

  @override
  String starterTruckReceivedBody(String amount, String seedCost) {
    return 'The starter grain truck and $amount credits are yours. Plant wheat or maize again for $seedCost credits.';
  }

  @override
  String cropSaleValue(String amount) {
    return 'Crop value: $amount credits';
  }

  @override
  String get maizeCropName => 'Maize';

  @override
  String get wheatCropName => 'Wheat';

  @override
  String get sunflowerCropName => 'Sunflower';

  @override
  String get potatoCropName => 'Potato';

  @override
  String get chickpeaCropName => 'Chickpea';

  @override
  String firstDiversityProgress(String complete, String required) {
    return 'First diversity route: $complete / $required';
  }

  @override
  String get firstDiversityHint =>
      'Harvest one full grain crop and either sunflowers or potatoes.';

  @override
  String get firstDiversityComplete => 'First diversity milestone complete.';

  @override
  String openingP2Progress(String current, String required) {
    return 'P2 production: $current / $required credits';
  }

  @override
  String get soilConditionTitle => 'Soil condition';

  @override
  String soilConditionValue(String points, String yieldPercent) {
    return '$points/100 · estimated yield $yieldPercent%';
  }

  @override
  String soilCareRule(String correction, String trigger, String cost) {
    return 'Each full harvest lowers soil by 1 point. T02 restores $correction below $trigger for $cost credits.';
  }

  @override
  String get researchSoilCare => 'Research soil care';

  @override
  String get soilCareAutomationOn => 'Auto-care: On';

  @override
  String get soilCareAutomationOff => 'Auto-care: Off';

  @override
  String get soilCareAutomationPaused => 'Automatic soil care is paused.';

  @override
  String soilCareAwaitingFunds(String amount) {
    return 'Soil care is waiting for $amount credits. Planting and harvesting continue.';
  }

  @override
  String get researchOilseedFamily => 'Unlock oilseed family';

  @override
  String get researchRootTuberFamily => 'Unlock root and tuber family';

  @override
  String get researchSunflowerCrop => 'Unlock sunflower crop';

  @override
  String get researchPotatoCrop => 'Unlock potato crop';

  @override
  String get researchLegumeFamily => 'Unlock legume family';

  @override
  String get researchChickpeaCrop => 'Unlock chickpea crop';

  @override
  String get plantSunflower => 'Plant sunflower';

  @override
  String get plantPotato => 'Plant potatoes';

  @override
  String get plantChickpeas => 'Plant chickpeas';

  @override
  String get chickpeaArtworkAccessibility => 'Chickpea growth stages';

  @override
  String get sunflowerArtworkAccessibility => 'Mature sunflower crop patch';

  @override
  String get potatoArtworkAccessibility => 'Mature potato crop patch';

  @override
  String get truckArtworkAccessibility => 'Starter grain truck';

  @override
  String get cropPlotAccessibility => 'Starter crop field';

  @override
  String get buyMower => 'Buy mini mower';

  @override
  String get hireWorker => 'Hire worker';

  @override
  String costAmount(Object amount) {
    return '$amount credits';
  }

  @override
  String get gameplayAccessibility =>
      'Farm World gameplay. Use the virtual joystick to move the worker around the field.';

  @override
  String get joystickAccessibility => 'Virtual movement joystick';

  @override
  String get workerArtworkAccessibility => 'Farm worker';

  @override
  String get mowerArtworkAccessibility => 'Mini mower';
}
