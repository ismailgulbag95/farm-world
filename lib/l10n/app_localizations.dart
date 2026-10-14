import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('tr'),
  ];

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm World'**
  String get gameTitle;

  /// No description provided for @startingField.
  ///
  /// In en, this message translates to:
  /// **'A fresh start'**
  String get startingField;

  /// No description provided for @farmCredits.
  ///
  /// In en, this message translates to:
  /// **'Farm credits'**
  String get farmCredits;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @openingScytheTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first bale'**
  String get openingScytheTitle;

  /// No description provided for @openingScytheBody.
  ///
  /// In en, this message translates to:
  /// **'Push the joystick up into the meadow. Keep moving to cut grass; walk over each bale to collect it.'**
  String get openingScytheBody;

  /// No description provided for @openingMowingProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'First bale progress'**
  String get openingMowingProgressLabel;

  /// No description provided for @openingMowerGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Mini mower: {bales, plural, one{# bale sale left} other{# bale sales left}}'**
  String openingMowerGoalLabel(int bales);

  /// No description provided for @openingWorkerGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker: {bales, plural, one{# bale sale left} other{# bale sales left}}'**
  String openingWorkerGoalLabel(int bales);

  /// No description provided for @baleNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'A bale is ready'**
  String get baleNearbyTitle;

  /// No description provided for @baleNearbyBody.
  ///
  /// In en, this message translates to:
  /// **'Walk over it, then carry it to the wooden platform.'**
  String get baleNearbyBody;

  /// No description provided for @baleCarryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell your bale'**
  String get baleCarryTitle;

  /// No description provided for @baleCarryBody.
  ///
  /// In en, this message translates to:
  /// **'Take it to the receiving platform to earn {amount} credits.'**
  String baleCarryBody(Object amount);

  /// No description provided for @mowerUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring in a mini mower'**
  String get mowerUpgradeTitle;

  /// No description provided for @mowerUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Move faster and cut a wider path through the meadow.'**
  String get mowerUpgradeBody;

  /// No description provided for @workerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand over the mower'**
  String get workerTitle;

  /// No description provided for @workerNeedClearBody.
  ///
  /// In en, this message translates to:
  /// **'Sell every bale on the ground or in your hands before hiring a worker.'**
  String get workerNeedClearBody;

  /// No description provided for @workerNeedFundsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep selling bales. You need {amount} more credits to hire a worker.'**
  String workerNeedFundsBody(Object amount);

  /// No description provided for @workerReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your worker will take over the mower and unlock the first plot.'**
  String get workerReadyBody;

  /// No description provided for @managementTitle.
  ///
  /// In en, this message translates to:
  /// **'Your farm is automated'**
  String get managementTitle;

  /// No description provided for @managementBody.
  ///
  /// In en, this message translates to:
  /// **'The starting plot and one free crop seed are ready.'**
  String get managementBody;

  /// No description provided for @starterPlotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first field is ready'**
  String get starterPlotReadyTitle;

  /// No description provided for @starterPlotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Plant the free maize seed. The first crop is chosen for the guaranteed spring planting window.'**
  String get starterPlotReadyBody;

  /// No description provided for @plantMaize.
  ///
  /// In en, this message translates to:
  /// **'Plant maize'**
  String get plantMaize;

  /// No description provided for @plantWheat.
  ///
  /// In en, this message translates to:
  /// **'Plant wheat'**
  String get plantWheat;

  /// No description provided for @freeStarterSeed.
  ///
  /// In en, this message translates to:
  /// **'Free starter seed'**
  String get freeStarterSeed;

  /// No description provided for @cropGrowingTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop} is growing'**
  String cropGrowingTitle(String crop);

  /// No description provided for @cropGrowingBody.
  ///
  /// In en, this message translates to:
  /// **'{percent}% grown · about {minutes} min left.'**
  String cropGrowingBody(String percent, String minutes);

  /// No description provided for @cropReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to harvest'**
  String get cropReadyTitle;

  /// No description provided for @cropReadyBody.
  ///
  /// In en, this message translates to:
  /// **'{crop} is ready for harvest.'**
  String cropReadyBody(String crop);

  /// No description provided for @firstTradeReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Harvest {crop} to complete your first trade. You will receive the starter grain truck and {amount} credits.'**
  String firstTradeReadyBody(String crop, String amount);

  /// No description provided for @harvestAndTrade.
  ///
  /// In en, this message translates to:
  /// **'Harvest and trade'**
  String get harvestAndTrade;

  /// No description provided for @harvestCrop.
  ///
  /// In en, this message translates to:
  /// **'Harvest and sell'**
  String get harvestCrop;

  /// No description provided for @firstTradeReward.
  ///
  /// In en, this message translates to:
  /// **'Truck + {amount} credits'**
  String firstTradeReward(String amount);

  /// No description provided for @starterTruckReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first delivery truck'**
  String get starterTruckReceivedTitle;

  /// No description provided for @starterTruckReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'The starter grain truck and {amount} credits are yours. Plant wheat or maize again for {seedCost} credits.'**
  String starterTruckReceivedBody(String amount, String seedCost);

  /// No description provided for @cropSaleValue.
  ///
  /// In en, this message translates to:
  /// **'Crop value: {amount} credits'**
  String cropSaleValue(String amount);

  /// No description provided for @maizeCropName.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get maizeCropName;

  /// No description provided for @wheatCropName.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheatCropName;

  /// No description provided for @sunflowerCropName.
  ///
  /// In en, this message translates to:
  /// **'Sunflower'**
  String get sunflowerCropName;

  /// No description provided for @potatoCropName.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get potatoCropName;

  /// No description provided for @chickpeaCropName.
  ///
  /// In en, this message translates to:
  /// **'Chickpea'**
  String get chickpeaCropName;

  /// No description provided for @firstDiversityProgress.
  ///
  /// In en, this message translates to:
  /// **'First diversity route: {complete} / {required}'**
  String firstDiversityProgress(String complete, String required);

  /// No description provided for @firstDiversityHint.
  ///
  /// In en, this message translates to:
  /// **'Harvest one full grain crop and either sunflowers or potatoes.'**
  String get firstDiversityHint;

  /// No description provided for @firstDiversityComplete.
  ///
  /// In en, this message translates to:
  /// **'First diversity milestone complete.'**
  String get firstDiversityComplete;

  /// No description provided for @openingP2Progress.
  ///
  /// In en, this message translates to:
  /// **'P2 production: {current} / {required} credits'**
  String openingP2Progress(String current, String required);

  /// No description provided for @soilConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil condition'**
  String get soilConditionTitle;

  /// No description provided for @soilConditionValue.
  ///
  /// In en, this message translates to:
  /// **'{points}/100 · estimated yield {yieldPercent}%'**
  String soilConditionValue(String points, String yieldPercent);

  /// No description provided for @soilCareRule.
  ///
  /// In en, this message translates to:
  /// **'Each full harvest lowers soil by 1 point. T02 restores {correction} below {trigger} for {cost} credits.'**
  String soilCareRule(String correction, String trigger, String cost);

  /// No description provided for @researchSoilCare.
  ///
  /// In en, this message translates to:
  /// **'Research soil care'**
  String get researchSoilCare;

  /// No description provided for @soilCareAutomationOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-care: On'**
  String get soilCareAutomationOn;

  /// No description provided for @soilCareAutomationOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-care: Off'**
  String get soilCareAutomationOff;

  /// No description provided for @soilCareAutomationPaused.
  ///
  /// In en, this message translates to:
  /// **'Automatic soil care is paused.'**
  String get soilCareAutomationPaused;

  /// No description provided for @soilCareAwaitingFunds.
  ///
  /// In en, this message translates to:
  /// **'Soil care is waiting for {amount} credits. Planting and harvesting continue.'**
  String soilCareAwaitingFunds(String amount);

  /// No description provided for @researchOilseedFamily.
  ///
  /// In en, this message translates to:
  /// **'Unlock oilseed family'**
  String get researchOilseedFamily;

  /// No description provided for @researchRootTuberFamily.
  ///
  /// In en, this message translates to:
  /// **'Unlock root and tuber family'**
  String get researchRootTuberFamily;

  /// No description provided for @researchSunflowerCrop.
  ///
  /// In en, this message translates to:
  /// **'Unlock sunflower crop'**
  String get researchSunflowerCrop;

  /// No description provided for @researchPotatoCrop.
  ///
  /// In en, this message translates to:
  /// **'Unlock potato crop'**
  String get researchPotatoCrop;

  /// No description provided for @researchLegumeFamily.
  ///
  /// In en, this message translates to:
  /// **'Unlock legume family'**
  String get researchLegumeFamily;

  /// No description provided for @researchChickpeaCrop.
  ///
  /// In en, this message translates to:
  /// **'Unlock chickpea crop'**
  String get researchChickpeaCrop;

  /// No description provided for @plantSunflower.
  ///
  /// In en, this message translates to:
  /// **'Plant sunflower'**
  String get plantSunflower;

  /// No description provided for @plantPotato.
  ///
  /// In en, this message translates to:
  /// **'Plant potatoes'**
  String get plantPotato;

  /// No description provided for @plantChickpeas.
  ///
  /// In en, this message translates to:
  /// **'Plant chickpeas'**
  String get plantChickpeas;

  /// No description provided for @chickpeaArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Chickpea growth stages'**
  String get chickpeaArtworkAccessibility;

  /// No description provided for @sunflowerArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Mature sunflower crop patch'**
  String get sunflowerArtworkAccessibility;

  /// No description provided for @potatoArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Mature potato crop patch'**
  String get potatoArtworkAccessibility;

  /// No description provided for @truckArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Starter grain truck'**
  String get truckArtworkAccessibility;

  /// No description provided for @cropPlotAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Starter crop field'**
  String get cropPlotAccessibility;

  /// No description provided for @buyMower.
  ///
  /// In en, this message translates to:
  /// **'Buy mini mower'**
  String get buyMower;

  /// No description provided for @hireWorker.
  ///
  /// In en, this message translates to:
  /// **'Hire worker'**
  String get hireWorker;

  /// No description provided for @costAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} credits'**
  String costAmount(Object amount);

  /// No description provided for @gameplayAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Farm World gameplay. Use the virtual joystick to move the worker around the field.'**
  String get gameplayAccessibility;

  /// No description provided for @joystickAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Virtual movement joystick'**
  String get joystickAccessibility;

  /// No description provided for @workerArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Farm worker'**
  String get workerArtworkAccessibility;

  /// No description provided for @mowerArtworkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Mini mower'**
  String get mowerArtworkAccessibility;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
