// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get gameTitle => 'Farm World';

  @override
  String get startingField => 'Un nuevo comienzo';

  @override
  String get farmCredits => 'Créditos agrícolas';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get openingScytheTitle => 'Tu primer fardo';

  @override
  String get openingScytheBody =>
      'Empuja el joystick hacia arriba para entrar en la pradera. Sigue moviéndote para segar y pasa por encima de cada fardo para recogerlo.';

  @override
  String get openingMowingProgressLabel => 'Progreso del primer fardo';

  @override
  String openingMowerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# ventas de fardos',
      one: '# venta de fardo',
    );
    return 'Segadora: quedan $_temp0';
  }

  @override
  String openingWorkerGoalLabel(int bales) {
    String _temp0 = intl.Intl.pluralLogic(
      bales,
      locale: localeName,
      other: '# ventas de fardos',
      one: '# venta de fardo',
    );
    return 'Trabajador: quedan $_temp0';
  }

  @override
  String get baleNearbyTitle => 'Hay un fardo listo';

  @override
  String get baleNearbyBody =>
      'Pasa por encima para recogerlo y llévalo a la plataforma de madera.';

  @override
  String get baleCarryTitle => 'Vende tu fardo';

  @override
  String baleCarryBody(Object amount) {
    return 'Llévalo a la plataforma de entrega para ganar $amount créditos.';
  }

  @override
  String get mowerUpgradeTitle => 'Consigue una segadora pequeña';

  @override
  String get mowerUpgradeBody =>
      'Muévete más rápido y corta una franja más ancha del prado.';

  @override
  String get workerTitle => 'Delega la segadora';

  @override
  String get workerNeedClearBody =>
      'Entrega todos los fardos del suelo o que lleves antes de contratar a alguien.';

  @override
  String workerNeedFundsBody(Object amount) {
    return 'Sigue vendiendo fardos. Necesitas $amount créditos más para contratar.';
  }

  @override
  String get workerReadyBody =>
      'La persona contratada se hará cargo de la segadora y abrirá la primera parcela.';

  @override
  String get managementTitle => 'Tu granja ya está automatizada';

  @override
  String get managementBody =>
      'La parcela inicial y una semilla de cultivo gratuita están listas.';

  @override
  String get starterPlotReadyTitle => 'Tu primer campo está listo';

  @override
  String get starterPlotReadyBody =>
      'Planta la semilla de maíz gratuita. El primer cultivo aprovecha la ventana de siembra primaveral garantizada.';

  @override
  String get plantMaize => 'Plantar maíz';

  @override
  String get plantWheat => 'Plantar trigo';

  @override
  String get freeStarterSeed => 'Semilla inicial gratuita';

  @override
  String cropGrowingTitle(String crop) {
    return 'Crece el $crop';
  }

  @override
  String cropGrowingBody(String percent, String minutes) {
    return '$percent% · quedan unos $minutes min.';
  }

  @override
  String get cropReadyTitle => 'Hora de cosechar';

  @override
  String cropReadyBody(String crop) {
    return 'El $crop está listo para cosechar.';
  }

  @override
  String firstTradeReadyBody(String crop, String amount) {
    return 'Cosecha $crop para completar tu primer intercambio. Recibirás el camión de grano inicial y $amount créditos.';
  }

  @override
  String get harvestAndTrade => 'Cosechar e intercambiar';

  @override
  String get harvestCrop => 'Cosechar y vender';

  @override
  String firstTradeReward(String amount) {
    return 'Camión + $amount créditos';
  }

  @override
  String get starterTruckReceivedTitle => 'Tu primer camión de reparto';

  @override
  String starterTruckReceivedBody(String amount, String seedCost) {
    return 'Ya tienes el camión de grano inicial y $amount créditos. Planta trigo o maíz otra vez por $seedCost créditos.';
  }

  @override
  String cropSaleValue(String amount) {
    return 'Valor del cultivo: $amount créditos';
  }

  @override
  String get maizeCropName => 'Maíz';

  @override
  String get wheatCropName => 'Trigo';

  @override
  String get sunflowerCropName => 'Girasol';

  @override
  String get potatoCropName => 'Patata';

  @override
  String get chickpeaCropName => 'Garbanzo';

  @override
  String firstDiversityProgress(String complete, String required) {
    return 'Primera ruta de diversidad: $complete / $required';
  }

  @override
  String get firstDiversityHint =>
      'Cosecha un cereal completo y una cosecha completa de girasol o patata.';

  @override
  String get firstDiversityComplete => 'Primer hito de diversidad completado.';

  @override
  String openingP2Progress(String current, String required) {
    return 'Producción P2: $current / $required créditos';
  }

  @override
  String get soilConditionTitle => 'Estado del suelo';

  @override
  String soilConditionValue(String points, String yieldPercent) {
    return '$points/100 · rendimiento estimado $yieldPercent%';
  }

  @override
  String soilCareRule(String correction, String trigger, String cost) {
    return 'Cada cosecha completa reduce el suelo en 1 punto. T02 recupera $correction por debajo de $trigger a cambio de $cost créditos.';
  }

  @override
  String get researchSoilCare => 'Investigar cuidado del suelo';

  @override
  String get soilCareAutomationOn => 'Cuidado automático: activo';

  @override
  String get soilCareAutomationOff => 'Cuidado automático: inactivo';

  @override
  String get soilCareAutomationPaused =>
      'El cuidado automático del suelo está pausado.';

  @override
  String soilCareAwaitingFunds(String amount) {
    return 'El cuidado del suelo espera $amount créditos. La siembra y la cosecha continúan.';
  }

  @override
  String get researchOilseedFamily => 'Desbloquear familia oleaginosa';

  @override
  String get researchRootTuberFamily => 'Desbloquear raíces y tubérculos';

  @override
  String get researchSunflowerCrop => 'Desbloquear cultivo de girasol';

  @override
  String get researchPotatoCrop => 'Desbloquear cultivo de patata';

  @override
  String get researchLegumeFamily => 'Desbloquear familia de legumbres';

  @override
  String get researchChickpeaCrop => 'Desbloquear cultivo de garbanzo';

  @override
  String get plantSunflower => 'Plantar girasol';

  @override
  String get plantPotato => 'Plantar patatas';

  @override
  String get plantChickpeas => 'Plantar garbanzos';

  @override
  String get chickpeaArtworkAccessibility =>
      'Etapas de crecimiento del garbanzo';

  @override
  String get sunflowerArtworkAccessibility => 'Parcela madura de girasoles';

  @override
  String get potatoArtworkAccessibility => 'Parcela madura de patatas';

  @override
  String get truckArtworkAccessibility => 'Camión de grano inicial';

  @override
  String get cropPlotAccessibility => 'Campo de cultivo inicial';

  @override
  String get buyMower => 'Comprar segadora';

  @override
  String get hireWorker => 'Contratar trabajador';

  @override
  String costAmount(Object amount) {
    return '$amount créditos';
  }

  @override
  String get gameplayAccessibility =>
      'Juego Farm World. Usa el joystick virtual para moverte por el campo.';

  @override
  String get joystickAccessibility => 'Joystick virtual de movimiento';

  @override
  String get workerArtworkAccessibility => 'Trabajador agrícola';

  @override
  String get mowerArtworkAccessibility => 'Segadora pequeña';
}
