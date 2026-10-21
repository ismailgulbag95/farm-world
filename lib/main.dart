import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'game/domain/farm_equipment.dart';
import 'game/domain/opening_session.dart';
import 'game/domain/opening_crop_catalog.dart';
import 'game/domain/market_and_offline.dart';
import 'game/domain/debug_action_controller.dart';
import 'game/farm_world_game.dart';
import 'game/opening_mowing_world.dart';
import 'game/persistence/opening_session_store.dart';
import 'game/ui/game_loading_screen.dart';
import 'game/ui/story_comic_screen.dart';
import 'game/ui/tech_tree_overlay.dart';
import 'game/ui/woodcutting_opening_screen.dart';
import 'game/ui/world_map_screen.dart';
import 'game/ui/debug_settings_button.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  final store = OpeningSessionStore();
  final loadResult = await store.load();
  final session = loadResult.session;
  session.skipToManagement(minimumCredits: 4260);
  session.grantStarterEquipmentOnce();
  final lastSavedAt = loadResult.savedAt;
  OfflineProgressReport? offlineProgressReport;
  if (lastSavedAt != null) {
    const offlineSimulator = OfflineProgressSimulator();
    offlineProgressReport = offlineSimulator.simulateCatchUp(
      session,
      DateTime.now().toUtc().difference(lastSavedAt),
      from: lastSavedAt,
    );
  }
  if (store.canSave) {
    unawaited(store.save(session.state));
  }

  runApp(
    WorldMapPrototypeApp(
      store: store,
      session: session,
      offlineProgressReport: offlineProgressReport,
      recoveredFromBackup:
          loadResult.status == SaveRecoveryStatus.recoveredFromBackup,
    ),
  );
}

enum _AppLaunchPhase { loading, woodcutting, comic, worldMap }

class WorldMapPrototypeApp extends StatefulWidget {
  const WorldMapPrototypeApp({
    super.key,
    required this.store,
    required this.session,
    this.offlineProgressReport,
    this.recoveredFromBackup = false,
  });

  final OpeningSessionStore store;
  final OpeningSession session;
  final OfflineProgressReport? offlineProgressReport;
  final bool recoveredFromBackup;

  @override
  State<WorldMapPrototypeApp> createState() => _WorldMapPrototypeAppState();
}

class _WorldMapPrototypeAppState extends State<WorldMapPrototypeApp> {
  late final OpeningSessionAutosaver _autosaver;

  _AppLaunchPhase _phase = _AppLaunchPhase.worldMap;

  @override
  void initState() {
    super.initState();
    if (!widget.session.hasCompletedWoodcuttingOpening) {
      _phase = _AppLaunchPhase.woodcutting;
    } else if (!widget.session.hasCompletedWoodcuttingStory) {
      _phase = _AppLaunchPhase.comic;
    }
    _autosaver = OpeningSessionAutosaver(
      session: widget.session,
      store: widget.store,
    )..start();
  }

  @override
  void dispose() {
    _autosaver.flush();
    _autosaver.dispose();
    super.dispose();
  }

  void _onLoadingComplete() {
    if (widget.session.tutorialStep == FarmTutorialStep.story) {
      widget.session.setFarmTutorialStep(FarmTutorialStep.prepare);
      _autosaver.flush();
    }
    setState(() {
      _phase = _AppLaunchPhase.worldMap;
    });
  }

  void _onComicComplete() {
    widget.session.completeWoodcuttingStory();
    if (widget.session.tutorialStep == FarmTutorialStep.story) {
      widget.session.setFarmTutorialStep(FarmTutorialStep.prepare);
    }
    _autosaver.flush();
    setState(() {
      _phase = _AppLaunchPhase.worldMap;
    });
  }

  void _onWoodcuttingHookCompleted() {
    widget.session.completeWoodcuttingOpening();
    _autosaver.flush();
  }

  void _onWoodcuttingReturnToFarm() {
    setState(() {
      _phase = _AppLaunchPhase.comic;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF557B49),
        surface: const Color(0xFFFFF8E9),
      ),
      fontFamily: 'Roboto',
    ),
    home: switch (_phase) {
      _AppLaunchPhase.loading => GameLoadingScreen(
        onLoadingComplete: _onLoadingComplete,
      ),
      _AppLaunchPhase.woodcutting => WoodcuttingOpeningScreen(
        session: widget.session,
        onProgressChanged: _autosaver.flush,
        onHookCompleted: _onWoodcuttingHookCompleted,
        onReadLetter: _onWoodcuttingReturnToFarm,
      ),
      _AppLaunchPhase.comic => StoryComicScreen(onComplete: _onComicComplete),
      _AppLaunchPhase.worldMap => Scaffold(
        body: WorldMapScreen(
          session: widget.session,
          onSessionChanged: () => _autosaver.flush(),
          offlineProgressReport: widget.offlineProgressReport,
          recoveredFromBackup: widget.recoveredFromBackup,
        ),
      ),
    },
  );
}

/// Retained standalone research-tree shell; the main launch enters through the
/// woodcutting opening and then continues to the world map.
class TechTreeOnlyApp extends StatefulWidget {
  const TechTreeOnlyApp({
    super.key,
    required this.store,
    required this.session,
  });

  final OpeningSessionStore store;
  final OpeningSession session;

  @override
  State<TechTreeOnlyApp> createState() => _TechTreeOnlyAppState();
}

class _TechTreeOnlyAppState extends State<TechTreeOnlyApp> {
  late final OpeningSessionAutosaver _autosaver;

  @override
  void initState() {
    super.initState();
    _autosaver = OpeningSessionAutosaver(
      session: widget.session,
      store: widget.store,
    )..start();
  }

  @override
  void dispose() {
    _autosaver.flush();
    _autosaver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B9A60),
          brightness: Brightness.dark,
          surface: const Color(0xFF080B09),
        ),
      ),
      home: TechTreeOverlay(
        session: widget.session,
        researchOnly: true,
        onNodePurchased: () => _autosaver.flush(),
      ),
    );
  }
}

class FarmWorldApp extends StatefulWidget {
  const FarmWorldApp({super.key, this.store, this.session});

  final OpeningSessionStore? store;
  final OpeningSession? session;

  @override
  State<FarmWorldApp> createState() => FarmWorldAppState();
}

class FarmWorldAppState extends State<FarmWorldApp> {
  late final OpeningSession _session;
  late final OpeningSessionStore? _store;
  late final FarmWorldGame _game;
  OpeningSessionAutosaver? _autosaver;
  Locale? _localeOverride;
  bool _showWorldMap = false;

  OpeningSession get session => _session;
  OpeningSessionStore? get store => _store;
  OpeningSessionAutosaver? get autosaver => _autosaver;
  FarmWorldGame get game => _game;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? OpeningSession();
    _store = widget.store;
    _game = FarmWorldGame(session: _session);
    _showWorldMap = false;

    _game.onManagementTransitionComplete = () {
      if (mounted) {
        setState(() {
          _showWorldMap = true;
        });
      }
    };

    final store = _store;
    if (store != null && store.canSave) {
      _autosaver = OpeningSessionAutosaver(session: _session, store: store)
        ..start();
    }
  }

  @override
  void dispose() {
    _autosaver?.dispose();
    super.dispose();
  }

  void _selectLocale(Locale locale) {
    setState(() => _localeOverride = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF557B49),
          surface: const Color(0xFFFFF8E9),
        ),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D7442),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: Stack(
              children: [
                Semantics(
                  container: true,
                  label: l10n.gameplayAccessibility,
                  child: GameWidget<FarmWorldGame>(
                    game: _game,
                    overlayBuilderMap: {
                      'openingHud': (context, game) => OpeningHudOverlay(
                        game: game,
                        onLocaleSelected: _selectLocale,
                      ),
                    },
                    initialActiveOverlays: const ['openingHud'],
                  ),
                ),
                if (_showWorldMap)
                  Positioned.fill(
                    child: WorldMapScreen(
                      session: _session,
                      onSessionChanged: () {
                        _autosaver?.flush();
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                // Geliştirici Kolaylığı: Sadece Debug modda görünen hızlı geçiş butonu
                Positioned(
                  top: 8,
                  right: 8,
                  child: SafeArea(
                    child: Opacity(
                      opacity: 0.85,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xDD1B3929),
                          foregroundColor: const Color(0xFFFFC84F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 14),
                        label: const Text(
                          'Yönetime Geç',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: () {
                          _game.skipToManagement();
                          setState(() {
                            _showWorldMap = true;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OpeningHudOverlay extends StatelessWidget {
  const OpeningHudOverlay({
    required this.game,
    required this.onLocaleSelected,
    super.key,
  });

  final FarmWorldGame game;
  final ValueChanged<Locale> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = isLandscape
              ? math.min(350.0, constraints.maxWidth - 32)
              : constraints.maxWidth - 32;

          return Stack(
            children: [
              Positioned(
                top: 12,
                left: 16,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _FarmIdentityCard(l10n: l10n)),
                    const SizedBox(width: 6),
                    _BalanceCard(game: game, l10n: l10n),
                    const SizedBox(width: 4),
                    _TechTreeButton(game: game),
                    const SizedBox(width: 4),
                    _LanguageMenu(
                      l10n: l10n,
                      onLocaleSelected: onLocaleSelected,
                    ),
                    const SizedBox(width: 4),
                    const DebugSettingsButton(),
                  ],
                ),
              ),
              Positioned(
                left: isLandscape ? null : 16,
                right: 16,
                bottom: isLandscape ? 84 : 144,
                width: isLandscape ? panelWidth : null,
                child: ValueListenableBuilder<ManagementMapSelection>(
                  valueListenable: game.world.selectedMapItem,
                  builder: (context, selectedMapItem, child) =>
                      _OpeningProgressCard(
                        game: game,
                        l10n: l10n,
                        selectedMapItem: selectedMapItem,
                      ),
                ),
              ),
              Positioned(
                left: isLandscape ? 12 : 16,
                right: isLandscape
                    ? math.min(360.0, constraints.maxWidth * 0.45)
                    : 16,
                bottom: 10,
                child: _ManagementNavigationBar(
                  game: game,
                  onOpenResearch: () => _openTechTree(context, game),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

VoidCallback _debugAction<T>(FutureOr<T> Function() action) => () {
  unawaited(DebugActionController.instance.runPlayerAction(action));
};

void _openTechTree(BuildContext context, FarmWorldGame game) {
  HapticFeedback.lightImpact();
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TechTreeOverlay(
        session: game.world.session,
        onNodePurchased: () {
          HapticFeedback.mediumImpact();
          game.sessionRevision.value++;
        },
      ),
    ),
  );
}

class _ManagementNavigationBar extends StatelessWidget {
  const _ManagementNavigationBar({
    required this.game,
    required this.onOpenResearch,
  });

  final FarmWorldGame game;
  final VoidCallback onOpenResearch;

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, VoidCallback)> actions = [
      (Icons.map_rounded, 'Harita', () => game.resetMapView()),
      (
        Icons.grass_rounded,
        'Tarlalar',
        () => game.world.selectedMapItem.value =
            ManagementMapSelection.starterPlot,
      ),
      (
        Icons.local_shipping_rounded,
        'Filo',
        () =>
            game.world.selectedMapItem.value = ManagementMapSelection.toolShed,
      ),
      (Icons.account_tree_rounded, 'Yetenek', onOpenResearch),
    ];

    return _FarmCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'Sürükle · İki parmakla yakınlaştır',
              style: TextStyle(
                color: Color(0xFF746B55),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: [
              for (final action in actions)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: action.$3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action.$1,
                            size: 19,
                            color: const Color(0xFF557B49),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF3E5234),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmIdentityCard extends StatelessWidget {
  const _FarmIdentityCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _FarmCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.gameTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3E5234),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.startingField,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF746B55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.game, required this.l10n});

  final FarmWorldGame game;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ValueListenableBuilder<int>(
      valueListenable: game.sessionRevision,
      builder: (context, revision, child) {
        final amount = NumberFormat.decimalPattern(locale)
            .format(game.world.session.farmCredits);
        return Semantics(
          label: '${l10n.farmCredits}: $amount',
          child: _FarmCard(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CoinGlyph(),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF3E5234),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.farmCredits,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF746B55),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.l10n, required this.onLocaleSelected});

  final AppLocalizations l10n;
  final ValueChanged<Locale> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l10n.changeLanguage,
      button: true,
      child: PopupMenuButton<Locale>(
        tooltip: l10n.changeLanguage,
        onSelected: onLocaleSelected,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: const Locale('en'),
            child: Text(l10n.languageEnglish),
          ),
          PopupMenuItem(
            value: const Locale('tr'),
            child: Text(l10n.languageTurkish),
          ),
          PopupMenuItem(
            value: const Locale('es'),
            child: Text(l10n.languageSpanish),
          ),
          PopupMenuItem(
            value: const Locale('de'),
            child: Text(l10n.languageGerman),
          ),
        ],
        child: _FarmCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: const Icon(
            Icons.translate_rounded,
            size: 20,
            color: Color(0xFF557B49),
          ),
        ),
      ),
    );
  }
}

class _TechTreeButton extends StatelessWidget {
  const _TechTreeButton({required this.game});

  final FarmWorldGame game;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yetenek ağacı',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openTechTree(context, game),
        child: const _FarmCard(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Icon(
            Icons.account_tree_rounded,
            size: 20,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }
}

class _OpeningProgressCard extends StatelessWidget {
  const _OpeningProgressCard({
    required this.game,
    required this.l10n,
    required this.selectedMapItem,
  });

  final FarmWorldGame game;
  final AppLocalizations l10n;
  final ManagementMapSelection selectedMapItem;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ValueListenableBuilder<int>(
      valueListenable: game.sessionRevision,
      builder: (context, revision, child) {
        final session = game.world.session;
        final numberFormat = NumberFormat.decimalPattern(locale);
        late String title;
        late String body;
        Widget? action;
        final additionalActions = <Widget>[];
        Widget? rewardArtwork;
        Widget? diversityProgress;
        Widget? soilConditionPanel;
        Widget? mowingProgress;
        Widget? milestoneProgress;
        Widget? selectedAssetSummary;

        if (session.stage == OpeningStage.scythe) {
          final mowerCreditsRemaining = math.max(
            0,
            OpeningSession.mowerCost - session.farmCredits,
          );
          if (mowerCreditsRemaining > 0) {
            final baleSalesRemaining =
                (mowerCreditsRemaining +
                    OpeningSession.baleSaleRewardCredits -
                    1) ~/
                OpeningSession.baleSaleRewardCredits;
            milestoneProgress = _OpeningMilestoneMeter(
              label: l10n.openingMowerGoalLabel(baleSalesRemaining),
              value: session.farmCredits / OpeningSession.mowerCost,
            );
          }

          if (session.isCarryingBale) {
            title = l10n.baleCarryTitle;
            body = l10n.baleCarryBody(
              numberFormat.format(OpeningSession.baleSaleRewardCredits),
            );
          } else if (session.hasGroundBale) {
            title = l10n.baleNearbyTitle;
            body = l10n.baleNearbyBody;
          } else if (session.canBuyMower) {
            title = l10n.mowerUpgradeTitle;
            body = l10n.mowerUpgradeBody;
            action = _PurchaseButton(
              label: l10n.buyMower,
              cost: l10n.costAmount(
                numberFormat.format(OpeningSession.mowerCost),
              ),
              artworkPath:
                  'assets/visual-concepts/pilot/vehicle-mini-mower-v1.png',
              artworkLabel: l10n.mowerArtworkAccessibility,
              onPressed: _debugAction(game.buyMower),
            );
          } else {
            title = l10n.openingScytheTitle;
            body = l10n.openingScytheBody;
            final progress =
                (session.mowingProgressSeconds /
                        session.baleMowingDurationSeconds)
                    .clamp(0.0, 1.0);
            mowingProgress = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.openingMowingProgressLabel,
                        style: const TextStyle(
                          color: Color(0xFF4D7442),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF4D7442),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE9DFC8),
                    color: const Color(0xFF76A34D),
                  ),
                ),
              ],
            );
          }
        } else if (session.stage == OpeningStage.mower) {
          title = l10n.workerTitle;
          final workerCreditsRemaining = math.max(
            0,
            OpeningSession.workerCost - session.farmCredits,
          );
          if (workerCreditsRemaining > 0) {
            final baleSalesRemaining =
                (workerCreditsRemaining +
                    OpeningSession.baleSaleRewardCredits -
                    1) ~/
                OpeningSession.baleSaleRewardCredits;
            milestoneProgress = _OpeningMilestoneMeter(
              label: l10n.openingWorkerGoalLabel(baleSalesRemaining),
              value: session.farmCredits / OpeningSession.workerCost,
            );
          }

          if (session.isCarryingBale || session.hasGroundBale) {
            body = l10n.workerNeedClearBody;
          } else if (session.canHireWorker) {
            body = l10n.workerReadyBody;
            action = _PurchaseButton(
              label: l10n.hireWorker,
              cost: l10n.costAmount(
                numberFormat.format(OpeningSession.workerCost),
              ),
              artworkPath: 'assets/visual-concepts/pilot/worker-employee-turnaround-v1.png',
              artworkLabel: l10n.workerArtworkAccessibility,
              onPressed: _debugAction(game.hireWorker),
            );
          } else {
            final remaining = math.max(
              0,
              OpeningSession.workerCost - session.farmCredits,
            );
            body = l10n.workerNeedFundsBody(numberFormat.format(remaining));
          }
        } else {
          final now = DateTime.now();
          final crop = session.cropSnapshotAt(now);
          if (session.hasActiveCrop && crop != null) {
            final cropName = _localizedCropName(crop.crop.id, l10n);
            final cropArtworkPath = _cropArtworkPath(
              crop.crop.id,
              growthProgress: crop.growthProgress,
            );
            if (crop.isHarvestable) {
              title = l10n.cropReadyTitle;
              if (session.hasCompletedStarterTrade) {
                body = l10n.cropReadyBody(cropName);
                action = _PurchaseButton(
                  label: l10n.harvestCrop,
                  cost: l10n.cropSaleValue(
                    numberFormat.format(crop.harvestYield.round()),
                  ),
                  artworkPath: cropArtworkPath,
                  artworkLabel: _cropArtworkAccessibility(crop.crop.id, l10n),
                  onPressed: _debugAction(game.harvestCrop),
                );
              } else {
                body = l10n.firstTradeReadyBody(
                  cropName,
                  numberFormat.format(OpeningSession.starterTradeCredits),
                );
                action = _PurchaseButton(
                  label: l10n.harvestAndTrade,
                  cost: l10n.firstTradeReward(
                    numberFormat.format(OpeningSession.starterTradeCredits),
                  ),
                  artworkPath: cropArtworkPath,
                  artworkLabel: _cropArtworkAccessibility(crop.crop.id, l10n),
                  onPressed: _debugAction(game.harvestCrop),
                );
              }
            } else {
              final remaining =
                  crop.cycle.maturityElapsed - crop.evaluationElapsed;
              final remainingSeconds = math.max(0, remaining.inSeconds);
              final remainingMinutes = (remainingSeconds + 59) ~/ 60;
              title = l10n.cropGrowingTitle(cropName);
              body = l10n.cropGrowingBody(
                numberFormat.format((crop.growthProgress * 100).round()),
                numberFormat.format(remainingMinutes),
              );
              rewardArtwork = Image.asset(
                cropArtworkPath,
                semanticLabel: _cropArtworkAccessibility(crop.crop.id, l10n),
                width: 94,
                height: 56,
                fit: BoxFit.contain,
              );
            }
          } else if (!session.hasCompletedStarterTrade) {
            title = l10n.starterPlotReadyTitle;
            body = l10n.starterPlotReadyBody;
            action = _PurchaseButton(
              label: l10n.plantMaize,
              cost: session.hasFreeInitialSeed
                  ? l10n.freeStarterSeed
                  : l10n.costAmount(
                      numberFormat.format(OpeningSession.starterCropSeedCost),
                    ),
              artworkPath:
                  'assets/visual-concepts/pilot/crop-maize-mature-v1.png',
              artworkLabel: l10n.cropPlotAccessibility,
              onPressed: session.canPlantCrop(OpeningSession.starterMaizeId)
                  ? _debugAction(
                      () => game.plantCrop(OpeningSession.starterMaizeId),
                    )
                  : null,
            );
          } else {
            title = l10n.starterTruckReceivedTitle;
            body = l10n.starterTruckReceivedBody(
              numberFormat.format(OpeningSession.starterTradeCredits),
              numberFormat.format(OpeningSession.starterCropSeedCost),
            );
            rewardArtwork = Image.asset(
              'assets/visual-concepts/pilot/vehicle-starter-grain-truck-v1.png',
              semanticLabel: l10n.truckArtworkAccessibility,
              width: 108,
              height: 62,
              fit: BoxFit.contain,
            );
            action = _PurchaseButton(
              label: l10n.plantMaize,
              cost: l10n.costAmount(
                numberFormat.format(OpeningSession.starterCropSeedCost),
              ),
              artworkPath:
                  'assets/visual-concepts/pilot/crop-maize-mature-v1.png',
              artworkLabel: l10n.cropPlotAccessibility,
              onPressed: session.canPlantCrop(OpeningSession.starterMaizeId)
                  ? _debugAction(
                      () => game.plantCrop(OpeningSession.starterMaizeId),
                    )
                  : null,
            );
            additionalActions.add(
              _PurchaseButton(
                label: l10n.plantWheat,
                cost: l10n.costAmount(
                  numberFormat.format(OpeningSession.starterCropSeedCost),
                ),
                artworkPath:
                    'assets/visual-concepts/pilot/crop-wheat-mature-v1.png',
                artworkLabel: l10n.cropPlotAccessibility,
                onPressed: session.canPlantCrop(OpeningSession.starterWheatId)
                    ? _debugAction(
                        () => game.plantCrop(OpeningSession.starterWheatId),
                      )
                    : null,
              ),
            );
            diversityProgress = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.hasCompletedV1Diversity
                      ? l10n.firstDiversityComplete
                      : l10n.firstDiversityProgress(
                          numberFormat.format(0),
                          numberFormat.format(1),
                        ),
                  style: const TextStyle(
                    color: Color(0xFF4D7442),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!session.hasCompletedV1Diversity) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.firstDiversityHint,
                    style: const TextStyle(
                      color: Color(0xFF655F50),
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  l10n.openingP2Progress(
                    numberFormat.format(session.lifetimeProductionEvidence),
                    numberFormat.format(
                      OpeningCropCatalog.p2EvidenceThresholdCredits,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF786A50),
                    fontSize: 10,
                  ),
                ),
              ],
            );
            _addDiversityBranchActions(
              additionalActions,
              game: game,
              session: session,
              l10n: l10n,
              numberFormat: numberFormat,
            );
          }
        }

        if (session.stage == OpeningStage.management) {
          soilConditionPanel = _SoilConditionPanel(
            game: game,
            session: session,
            l10n: l10n,
            numberFormat: numberFormat,
          );
          if (!session.hasPurchasedTechnology(
            OpeningSession.soilCareTechnologyId,
          )) {
            additionalActions.insert(
              0,
              _PurchaseButton(
                label: l10n.researchSoilCare,
                cost: l10n.costAmount(
                  numberFormat.format(
                    OpeningCropCatalog.c2TechnologyCostCredits,
                  ),
                ),
                artworkPath: 'assets/images/ui/soil-condition-v1.png',
                artworkLabel: l10n.soilConditionTitle,
                onPressed:
                    session.canPurchaseTechnology(
                      OpeningSession.soilCareTechnologyId,
                    )
                    ? _debugAction(
                        () => game.purchaseTechnology(
                          OpeningSession.soilCareTechnologyId,
                        ),
                      )
                    : null,
              ),
            );
          }

          if (selectedMapItem != ManagementMapSelection.starterPlot) {
            action = null;
            additionalActions.clear();
            diversityProgress = null;
            soilConditionPanel = null;
            rewardArtwork = null;
            switch (selectedMapItem) {
              case ManagementMapSelection.farmhouse:
                title = 'Çiftlik merkezi';
                body = 'Tüm operasyonlarını buradan takip et.';
                selectedAssetSummary = _ManagementFacts(
                  facts: [
                    '${session.plots.where((plot) => plot.isOwned).length} parsel',
                    '${session.fleetManager.vehicles.length} araç',
                    '${session.lifetimeProductionEvidence} ÇK üretim',
                  ],
                );
                break;
              case ManagementMapSelection.grainBarn:
                title = 'Tahıl ambarı';
                body = 'Hasadını depola ve satış rotalarına hazır tut.';
                selectedAssetSummary = _ManagementFacts(
                  facts: [
                    '${session.fleetManager.totalWarehouseAmount} / ${session.fleetManager.warehouseCapacity} birim dolu',
                    '${session.fleetManager.remainingWarehouseCapacity} birim boş alan',
                  ],
                );
                break;
              case ManagementMapSelection.toolShed:
                final deliveries = session.fleetManager.vehicles.fold<int>(
                  0,
                  (sum, vehicle) => sum + vehicle.totalDeliveriesCount,
                );
                title = 'Filo garajı';
                body = 'Araçlarını ve çiftlik içi taşıma ağını yönet.';
                selectedAssetSummary = _ManagementFacts(
                  facts: [
                    '${session.fleetManager.vehicles.length} araç',
                    '${session.fleetManager.routes.length} rota',
                    '$deliveries teslimat',
                  ],
                );
                break;
              case ManagementMapSelection.starterPlot:
                break;
            }
          }
        }

        return _FarmCard(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.min(
                340,
                MediaQuery.sizeOf(context).height * 0.45,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3E5234),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF655F50),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  if (mowingProgress != null) ...[
                    const SizedBox(height: 9),
                    mowingProgress,
                  ],
                  if (milestoneProgress != null) ...[
                    const SizedBox(height: 9),
                    milestoneProgress,
                  ],
                  if (rewardArtwork != null) ...[
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: rewardArtwork,
                    ),
                  ],
                  if (soilConditionPanel != null) ...[
                    const SizedBox(height: 8),
                    soilConditionPanel,
                  ],
                  if (selectedAssetSummary != null) ...[
                    const SizedBox(height: 9),
                    selectedAssetSummary,
                  ],
                  if (diversityProgress != null) ...[
                    const SizedBox(height: 8),
                    diversityProgress,
                  ],
                  if (action != null) ...[const SizedBox(height: 10), action],
                  for (final extraAction in additionalActions) ...[
                    const SizedBox(height: 8),
                    extraAction,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpeningMilestoneMeter extends StatelessWidget {
  const _OpeningMilestoneMeter({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF4D7442),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE9DFC8),
            color: const Color(0xFF76A34D),
          ),
        ),
      ],
    );
  }
}

class _ManagementFacts extends StatelessWidget {
  const _ManagementFacts({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final fact in facts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1E4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              fact,
              style: const TextStyle(
                color: Color(0xFF48613D),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SoilConditionPanel extends StatelessWidget {
  const _SoilConditionPanel({
    required this.game,
    required this.session,
    required this.l10n,
    required this.numberFormat,
  });

  final FarmWorldGame game;
  final OpeningSession session;
  final AppLocalizations l10n;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final soilPoints = session.soilConditionPoints;
    final yieldPercent = (session.soilYieldMultiplier * 100).round();
    final hasSoilCare = session.hasPurchasedTechnology(
      OpeningSession.soilCareTechnologyId,
    );
    final pendingMessage = soilPoints >= OpeningSession.soilCareTriggerPoints
        ? null
        : hasSoilCare && session.automaticSoilCareEnabled
        ? session.farmCredits < OpeningSession.soilCareCostCredits
              ? l10n.soilCareAwaitingFunds(
                  numberFormat.format(OpeningSession.soilCareCostCredits),
                )
              : null
        : hasSoilCare
        ? l10n.soilCareAutomationPaused
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EBD6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4D6B9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/ui/soil-condition-v1.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                semanticLabel: l10n.soilConditionTitle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.soilConditionTitle,
                      style: const TextStyle(
                        color: Color(0xFF3E5234),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.soilConditionValue(
                        numberFormat.format(soilPoints),
                        numberFormat.format(yieldPercent),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF655F50),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: soilPoints / OpeningSession.soilConditionMaximumPoints,
              minHeight: 6,
              backgroundColor: const Color(0xFFD9CCB2),
              color: soilPoints < OpeningSession.soilCareTriggerPoints
                  ? const Color(0xFFC17B3F)
                  : const Color(0xFF688552),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.soilCareRule(
              numberFormat.format(OpeningSession.soilCareRestoredPoints),
              numberFormat.format(OpeningSession.soilCareTriggerPoints),
              numberFormat.format(OpeningSession.soilCareCostCredits),
            ),
            style: const TextStyle(
              color: Color(0xFF746B55),
              fontSize: 10,
              height: 1.25,
            ),
          ),
          if (pendingMessage != null) ...[
            const SizedBox(height: 3),
            Text(
              pendingMessage,
              style: const TextStyle(
                color: Color(0xFF9A5C2D),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
          if (hasSoilCare)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _debugAction(
                  () => game.setAutomaticSoilCareEnabled(
                    !session.automaticSoilCareEnabled,
                  ),
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 17),
                label: Text(
                  session.automaticSoilCareEnabled
                      ? l10n.soilCareAutomationOn
                      : l10n.soilCareAutomationOff,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4D7442),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _addDiversityBranchActions(
  List<Widget> actions, {
  required FarmWorldGame game,
  required OpeningSession session,
  required AppLocalizations l10n,
  required NumberFormat numberFormat,
}) {
  void addBranch({
    required String familyTechnologyId,
    required String cropTechnologyId,
    required String cropId,
    required String familyLabel,
    required String cropTechnologyLabel,
    required String plantLabel,
    required String artworkPath,
    required String artworkLabel,
  }) {
    if (!session.hasPurchasedTechnology(familyTechnologyId)) {
      actions.add(
        _PurchaseButton(
          label: familyLabel,
          cost: l10n.costAmount(
            numberFormat.format(OpeningCropCatalog.c2TechnologyCostCredits),
          ),
          artworkPath: artworkPath,
          artworkLabel: artworkLabel,
          onPressed: session.canPurchaseTechnology(familyTechnologyId)
              ? _debugAction(() => game.purchaseTechnology(familyTechnologyId))
              : null,
        ),
      );
      return;
    }

    if (!session.hasPurchasedTechnology(cropTechnologyId)) {
      actions.add(
        _PurchaseButton(
          label: cropTechnologyLabel,
          cost: l10n.costAmount(
            numberFormat.format(OpeningCropCatalog.c2TechnologyCostCredits),
          ),
          artworkPath: artworkPath,
          artworkLabel: artworkLabel,
          onPressed: session.canPurchaseTechnology(cropTechnologyId)
              ? _debugAction(() => game.purchaseTechnology(cropTechnologyId))
              : null,
        ),
      );
      return;
    }

    final crop = OpeningCropCatalog.byId(cropId)!;
    actions.add(
      _PurchaseButton(
        label: plantLabel,
        cost: l10n.costAmount(numberFormat.format(crop.seedCostCredits)),
        artworkPath: artworkPath,
        artworkLabel: artworkLabel,
        onPressed: session.canPlantCrop(cropId)
            ? _debugAction(() => game.plantCrop(cropId))
            : null,
      ),
    );
  }

  addBranch(
    familyTechnologyId: OpeningCropCatalog.oilseedFamilyTechnologyId,
    cropTechnologyId: OpeningCropCatalog.sunflowerTechnologyId,
    cropId: OpeningCropCatalog.sunflowerId,
    familyLabel: l10n.researchOilseedFamily,
    cropTechnologyLabel: l10n.researchSunflowerCrop,
    plantLabel: l10n.plantSunflower,
    artworkPath: 'assets/visual-concepts/pilot/crop-sunflower-mature-v1.png',
    artworkLabel: l10n.sunflowerArtworkAccessibility,
  );
  addBranch(
    familyTechnologyId: OpeningCropCatalog.rootTuberFamilyTechnologyId,
    cropTechnologyId: OpeningCropCatalog.potatoTechnologyId,
    cropId: OpeningCropCatalog.potatoId,
    familyLabel: l10n.researchRootTuberFamily,
    cropTechnologyLabel: l10n.researchPotatoCrop,
    plantLabel: l10n.plantPotato,
    artworkPath: 'assets/visual-concepts/pilot/crop-potato-mature-v1.png',
    artworkLabel: l10n.potatoArtworkAccessibility,
  );
  addBranch(
    familyTechnologyId: OpeningCropCatalog.legumeFamilyTechnologyId,
    cropTechnologyId: OpeningCropCatalog.chickpeaTechnologyId,
    cropId: OpeningCropCatalog.chickpeaId,
    familyLabel: l10n.researchLegumeFamily,
    cropTechnologyLabel: l10n.researchChickpeaCrop,
    plantLabel: l10n.plantChickpeas,
    artworkPath: 'assets/visual-concepts/pilot/crop-chickpea-stages-v1.png',
    artworkLabel: l10n.chickpeaArtworkAccessibility,
  );
}

String _localizedCropName(String cropId, AppLocalizations l10n) =>
    switch (cropId) {
      OpeningCropCatalog.wheatId => l10n.wheatCropName,
      OpeningCropCatalog.maizeId => l10n.maizeCropName,
      OpeningCropCatalog.sunflowerId => l10n.sunflowerCropName,
      OpeningCropCatalog.potatoId => l10n.potatoCropName,
      OpeningCropCatalog.chickpeaId => l10n.chickpeaCropName,
      _ => l10n.cropPlotAccessibility,
    };

String _cropArtworkPath(String cropId, {double growthProgress = 1}) =>
    switch (cropId) {
      OpeningCropCatalog.wheatId =>
        'assets/visual-concepts/pilot/crop-wheat-mature-v1.png',
      OpeningCropCatalog.sunflowerId =>
        growthProgress < 0.34
            ? 'assets/visual-concepts/pilot/crop-sunflower-early-v1.png'
            : growthProgress < 0.72
            ? 'assets/visual-concepts/pilot/crop-sunflower-mid-v1.png'
            : 'assets/visual-concepts/pilot/crop-sunflower-mature-v1.png',
      OpeningCropCatalog.potatoId =>
        growthProgress < 0.34
            ? 'assets/visual-concepts/pilot/crop-potato-early-v1.png'
            : growthProgress < 0.72
            ? 'assets/visual-concepts/pilot/crop-potato-mid-v1.png'
            : 'assets/visual-concepts/pilot/crop-potato-mature-v1.png',
      OpeningCropCatalog.chickpeaId =>
        'assets/visual-concepts/pilot/crop-chickpea-stages-v1.png',
      _ => 'assets/visual-concepts/pilot/crop-maize-mature-v1.png',
    };

String _cropArtworkAccessibility(String cropId, AppLocalizations l10n) =>
    switch (cropId) {
      OpeningCropCatalog.sunflowerId => l10n.sunflowerArtworkAccessibility,
      OpeningCropCatalog.potatoId => l10n.potatoArtworkAccessibility,
      OpeningCropCatalog.chickpeaId => l10n.chickpeaArtworkAccessibility,
      _ => l10n.cropPlotAccessibility,
    };

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.label,
    required this.cost,
    required this.artworkPath,
    required this.artworkLabel,
    required this.onPressed,
  });

  final String label;
  final String cost;
  final String artworkPath;
  final String artworkLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Image.asset(
              artworkPath,
              semanticLabel: artworkLabel,
              width: 50,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    cost,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 19),
          ],
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3E5),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFB78D5A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330E2912),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CoinGlyph extends StatelessWidget {
  const _CoinGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2BE4B),
        border: Border.all(color: const Color(0xFFB37D21), width: 2),
      ),
      child: const Icon(Icons.spa_rounded, size: 15, color: Color(0xFF76521A)),
    );
  }
}
