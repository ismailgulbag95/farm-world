// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get gameTitle => 'Farm World';

  @override
  String get startingField => 'Ein neuer Anfang';

  @override
  String get farmCredits => 'Hofguthaben';

  @override
  String get changeLanguage => 'Sprache ändern';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get openingScytheTitle => 'Dein erster Ballen';

  @override
  String get openingScytheBody =>
      'Schiebe den Steuerknüppel nach oben auf die Wiese. Bleib in Bewegung und laufe über jeden Ballen, um ihn aufzuheben.';

  @override
  String get openingMowingProgressLabel => 'Fortschritt zum ersten Ballen';

  @override
  String openingMowerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# Ballenverkäufe',
      one: '# Ballenverkauf',
    );
    return 'Mäher: noch $_temp0';
  }

  @override
  String openingWorkerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# Ballenverkäufe',
      one: '# Ballenverkauf',
    );
    return 'Arbeitskraft: noch $_temp0';
  }

  @override
  String get baleNearbyTitle => 'Ein Ballen ist fertig';

  @override
  String get baleNearbyBody =>
      'Lauf darüber, nimm ihn auf und bring ihn zur Holzplattform.';

  @override
  String get baleCarryTitle => 'Verkaufe deinen Ballen';

  @override
  String baleCarryBody(Object amount) {
    return 'Bring ihn zur Abladeplattform und erhalte $amount Hofguthaben.';
  }

  @override
  String get mowerUpgradeTitle => 'Kaufe einen kleinen Mäher';

  @override
  String get mowerUpgradeBody =>
      'Bewege dich schneller und mähe eine breitere Spur durch die Wiese.';

  @override
  String get workerTitle => 'Übergib den Mäher';

  @override
  String get workerNeedClearBody =>
      'Verkaufe alle Ballen am Boden oder in deinen Händen, bevor du jemanden einstellst.';

  @override
  String workerNeedFundsBody(Object amount) {
    return 'Verkaufe weitere Ballen. Für die Einstellung fehlen noch $amount Hofguthaben.';
  }

  @override
  String get workerReadyBody =>
      'Die Arbeitskraft übernimmt den Mäher und schaltet das erste Feld frei.';

  @override
  String get managementTitle => 'Dein Hof läuft automatisch';

  @override
  String get managementBody =>
      'Das Startfeld und ein kostenloser Pflanzensamen sind bereit.';

  @override
  String get starterPlotReadyTitle => 'Dein erstes Feld ist bereit';

  @override
  String get starterPlotReadyBody =>
      'Pflanze den kostenlosen Maissamen. Die erste Kultur nutzt das garantierte Frühjahrs-Aussaatfenster.';

  @override
  String get plantMaize => 'Mais pflanzen';

  @override
  String get plantWheat => 'Weizen pflanzen';

  @override
  String get freeStarterSeed => 'Kostenloses Start-Saatgut';

  @override
  String cropGrowingTitle(String crop) {
    return '$crop wächst';
  }

  @override
  String cropGrowingBody(String percent, String minutes) {
    return '$percent% gewachsen · noch etwa $minutes Min.';
  }

  @override
  String get cropReadyTitle => 'Erntezeit';

  @override
  String cropReadyBody(String crop) {
    return '$crop ist erntereif.';
  }

  @override
  String firstTradeReadyBody(String crop, String amount) {
    return 'Ernte $crop, um deinen ersten Tausch abzuschließen. Du erhältst den kleinen Getreidelaster und $amount Hofguthaben.';
  }

  @override
  String get harvestAndTrade => 'Ernten und tauschen';

  @override
  String get harvestCrop => 'Ernten und verkaufen';

  @override
  String firstTradeReward(String amount) {
    return 'Laster + $amount Guthaben';
  }

  @override
  String get starterTruckReceivedTitle => 'Dein erster Lieferwagen';

  @override
  String starterTruckReceivedBody(String amount, String seedCost) {
    return 'Der kleine Getreidelaster und $amount Hofguthaben gehören dir. Pflanze Weizen oder Mais erneut für $seedCost Guthaben.';
  }

  @override
  String cropSaleValue(String amount) {
    return 'Erntewert: $amount Guthaben';
  }

  @override
  String get maizeCropName => 'Mais';

  @override
  String get wheatCropName => 'Weizen';

  @override
  String get sunflowerCropName => 'Sonnenblume';

  @override
  String get potatoCropName => 'Kartoffel';

  @override
  String get chickpeaCropName => 'Kichererbse';

  @override
  String firstDiversityProgress(String complete, String required) {
    return 'Erste Vielfalt: $complete / $required Produktionswege';
  }

  @override
  String get firstDiversityHint =>
      'Ernte ein Getreidefeld vollständig und entweder Sonnenblumen oder Kartoffeln.';

  @override
  String get firstDiversityComplete =>
      'Der erste Vielfalt-Meilenstein ist erreicht.';

  @override
  String openingP2Progress(String current, String required) {
    return 'P2-Produktion: $current / $required Farm-Credits';
  }

  @override
  String get soilConditionTitle => 'Bodenzustand';

  @override
  String soilConditionValue(String points, String yieldPercent) {
    return '$points/100 · geschätzter Ertrag $yieldPercent%';
  }

  @override
  String soilCareRule(String correction, String trigger, String cost) {
    return 'Jede volle Ernte senkt den Bodenwert um 1 Punkt. T02 stellt unter $trigger für $cost Credits $correction Punkte wieder her.';
  }

  @override
  String get researchSoilCare => 'Bodenpflege erforschen';

  @override
  String get soilCareAutomationOn => 'Automatische Pflege: an';

  @override
  String get soilCareAutomationOff => 'Automatische Pflege: aus';

  @override
  String get soilCareAutomationPaused =>
      'Die automatische Bodenpflege ist pausiert.';

  @override
  String soilCareAwaitingFunds(String amount) {
    return 'Die Bodenpflege wartet auf $amount Credits. Aussaat und Ernte laufen weiter.';
  }

  @override
  String get researchOilseedFamily => 'Ölsaatenfamilie freischalten';

  @override
  String get researchRootTuberFamily =>
      'Wurzel- und Knollenfamilie freischalten';

  @override
  String get researchSunflowerCrop => 'Sonnenblumen freischalten';

  @override
  String get researchPotatoCrop => 'Kartoffeln freischalten';

  @override
  String get researchLegumeFamily => 'Hülsenfruchtfamilie freischalten';

  @override
  String get researchChickpeaCrop => 'Kichererbsenanbau freischalten';

  @override
  String get plantSunflower => 'Sonnenblumen säen';

  @override
  String get plantPotato => 'Kartoffeln pflanzen';

  @override
  String get plantChickpeas => 'Kichererbsen säen';

  @override
  String get chickpeaArtworkAccessibility => 'Wachstumsphasen der Kichererbse';

  @override
  String get sunflowerArtworkAccessibility => 'Reifes Sonnenblumenfeld';

  @override
  String get potatoArtworkAccessibility => 'Reifes Kartoffelfeld';

  @override
  String get truckArtworkAccessibility => 'Kleiner Getreidelaster';

  @override
  String get cropPlotAccessibility => 'Erstes Anbaufeld';

  @override
  String get buyMower => 'Kleinmäher kaufen';

  @override
  String get hireWorker => 'Arbeitskraft einstellen';

  @override
  String costAmount(Object amount) {
    return '$amount Hofguthaben';
  }

  @override
  String get gameplayAccessibility =>
      'Farm-World-Spiel. Bewege die Figur mit dem virtuellen Steuerknüppel über das Feld.';

  @override
  String get joystickAccessibility => 'Virtueller Bewegungssteuerknüppel';

  @override
  String get workerArtworkAccessibility => 'Landwirtschaftliche Arbeitskraft';

  @override
  String get mowerArtworkAccessibility => 'Kleinmäher';
}
