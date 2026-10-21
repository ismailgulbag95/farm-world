import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../domain/debug_action_controller.dart';
import '../domain/opening_session.dart';
import 'debug_settings_button.dart';

/// Native Flutter port of the opening loop in the Orman Rotası prototype.
///
/// The player drives through the South Forest, sells two loads, buys equipment,
/// and finishes a short shift before returning to the inherited farm.
class WoodcuttingOpeningScreen extends StatefulWidget {
  const WoodcuttingOpeningScreen({
    super.key,
    required this.session,
    required this.onProgressChanged,
    required this.onHookCompleted,
    required this.onReadLetter,
  });

  final OpeningSession session;
  final VoidCallback onProgressChanged;
  final VoidCallback onHookCompleted;
  final VoidCallback onReadLetter;

  @override
  State<WoodcuttingOpeningScreen> createState() =>
      _WoodcuttingOpeningScreenState();
}

class _WoodcuttingOpeningScreenState extends State<WoodcuttingOpeningScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final _WoodcuttingWorld _world;
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final Set<LogicalKeyboardKey> _pendingPressedKeys = {};
  Duration _previousElapsed = Duration.zero;
  Offset _joystickInput = Offset.zero;
  double _lastSavedActiveSeconds = 0;
  bool _hasStarted = false;
  bool _isPlaying = false;
  bool _showUpgradeShop = false;
  bool _completionReported = false;
  bool _startActionPending = false;
  bool _pauseActionPending = false;
  bool _upgradeActionPending = false;
  bool _joystickDelayPending = false;
  bool _keyboardDelayPending = false;
  int _joystickGestureSequence = 0;
  int _keyboardGestureSequence = 0;
  Offset _pendingJoystickInput = Offset.zero;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _world = _WoodcuttingWorld(widget.session.woodcuttingOpeningProgress);
    _lastSavedActiveSeconds = _world.activeSeconds;
    _showUpgradeShop = _world.deliveryCount > 0 && _world.upgradeCount == 0;
    _ticker = createTicker(_advance);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    if (_startActionPending || _hasStarted) return;
    _startActionPending = true;
    unawaited(
      DebugActionController.instance
          .runPlayerAction<void>(() {
            if (!mounted) return;
            setState(() {
              _hasStarted = true;
              _isPlaying = true;
              _previousElapsed = Duration.zero;
            });
            _ticker.start();
          })
          .whenComplete(() => _startActionPending = false),
    );
  }

  void _togglePause() {
    if (_pauseActionPending) return;
    _pauseActionPending = true;
    unawaited(
      DebugActionController.instance
          .runPlayerAction<void>(() {
            if (!mounted || !_hasStarted || _world.isComplete) return;
            if (_isPlaying) {
              _ticker.stop();
              _joystickGestureSequence++;
              _keyboardGestureSequence++;
              _joystickDelayPending = false;
              _keyboardDelayPending = false;
              _pendingJoystickInput = Offset.zero;
              _pendingPressedKeys.clear();
              setState(() {
                _isPlaying = false;
                _joystickInput = Offset.zero;
                _pressedKeys.clear();
              });
            } else {
              setState(() {
                _isPlaying = true;
                _previousElapsed = Duration.zero;
              });
              _ticker.start();
            }
          })
          .whenComplete(() => _pauseActionPending = false),
    );
  }

  void _advance(Duration elapsed) {
    if (!_isPlaying || !mounted) return;
    final delta = (elapsed - _previousElapsed).inMicroseconds / 1000000;
    _previousElapsed = elapsed;
    final previousDeliveryCount = _world.deliveryCount;
    _world.update(
      delta.clamp(0.0, 0.05).toDouble(),
      _movementInput,
      viewport: _viewportSize,
    );
    if (_world.deliveryCount > previousDeliveryCount) {
      _showUpgradeShop = true;
      _persistProgress();
    } else if (_world.activeSeconds - _lastSavedActiveSeconds >= 5) {
      _persistProgress();
    }
    if (_world.isComplete && !_completionReported) {
      _persistProgress();
      _completionReported = true;
      _isPlaying = false;
      _ticker.stop();
      widget.onHookCompleted();
    }
    setState(() {});
  }

  void _persistProgress() {
    widget.session.updateWoodcuttingOpeningProgress(_world.toProgress());
    _lastSavedActiveSeconds = _world.activeSeconds;
    widget.onProgressChanged();
  }

  void _purchaseUpgrade(_WoodcuttingUpgrade upgrade) {
    if (_upgradeActionPending) return;
    _upgradeActionPending = true;
    unawaited(
      DebugActionController.instance
          .runPlayerAction<void>(() {
            if (!mounted ||
                !_showUpgradeShop ||
                !_world.purchaseUpgrade(upgrade)) {
              return;
            }
            _persistProgress();
            setState(() => _showUpgradeShop = false);
          })
          .whenComplete(() => _upgradeActionPending = false),
    );
  }

  Offset get _movementInput {
    if (_joystickInput.distance > 0.05) return _joystickInput;
    var x = 0.0;
    var y = 0.0;
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }
    final direction = Offset(x, y);
    if (direction.distance <= 1) return direction;
    return direction / direction.distance;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isMovementKey = <LogicalKeyboardKey>{
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
    }.contains(key);
    if (!isMovementKey) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
      _pendingPressedKeys.remove(key);
      if (_pendingPressedKeys.isEmpty && _keyboardDelayPending) {
        _keyboardGestureSequence++;
        _keyboardDelayPending = false;
      }
    } else {
      final controller = DebugActionController.instance;
      if (!controller.debugModeEnabled ||
          _pressedKeys.isNotEmpty ||
          _joystickInput.distance > 0.05) {
        _pressedKeys.add(key);
        return KeyEventResult.handled;
      }

      _pendingPressedKeys.add(key);
      if (!_keyboardDelayPending) {
        _keyboardDelayPending = true;
        final gestureSequence = ++_keyboardGestureSequence;
        unawaited(
          controller.runPlayerAction<void>(() {
            if (!mounted ||
                !_keyboardDelayPending ||
                gestureSequence != _keyboardGestureSequence) {
              return;
            }
            setState(() => _pressedKeys.addAll(_pendingPressedKeys));
            _pendingPressedKeys.clear();
            _keyboardDelayPending = false;
          }),
        );
      }
    }
    return KeyEventResult.handled;
  }

  void _updateJoystick(Offset localPosition, Size size) {
    final delta = localPosition - Offset(size.width / 2, size.height / 2);
    final distance = delta.distance;
    if (distance < 5) {
      _joystickGestureSequence++;
      _joystickDelayPending = false;
      _pendingJoystickInput = Offset.zero;
      setState(() => _joystickInput = Offset.zero);
      return;
    }
    final direction = delta / distance;
    final controller = DebugActionController.instance;
    if (!controller.debugModeEnabled || _joystickInput.distance > 0.05) {
      _joystickGestureSequence++;
      _joystickDelayPending = false;
      _pendingJoystickInput = Offset.zero;
      setState(() => _joystickInput = direction);
      return;
    }

    _pendingJoystickInput = direction;
    if (_joystickDelayPending) return;

    _joystickDelayPending = true;
    final gestureSequence = ++_joystickGestureSequence;
    unawaited(
      controller.runPlayerAction<void>(() {
        if (!mounted ||
            !_joystickDelayPending ||
            gestureSequence != _joystickGestureSequence) {
          return;
        }
        setState(() => _joystickInput = _pendingJoystickInput);
        _joystickDelayPending = false;
      }),
    );
  }

  void _releaseJoystick() {
    _joystickGestureSequence++;
    _joystickDelayPending = false;
    _pendingJoystickInput = Offset.zero;
    setState(() => _joystickInput = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF587950),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
              _world.setViewport(_viewportSize);
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _ForestPainter(_world)),
                  _buildHud(),
                  if (_hasStarted && !_world.isComplete) _buildControls(),
                  if (_world.toast case final message?) _buildToast(message),
                  if (!_hasStarted) _buildWelcomeCard(),
                  if (_hasStarted && !_isPlaying && !_world.isComplete)
                    _buildPauseCard(),
                  if (_world.isComplete) _buildCompletionCard(),
                  if (_showUpgradeShop && !_world.isComplete)
                    _buildUpgradeShop(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHud() => Positioned(
    top: 12,
    left: 14,
    right: 14,
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xE81B3025),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330D1B12),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0C66B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.forest_rounded,
                    color: Color(0xFF31533A),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GÜNEY ORMANI',
                        style: TextStyle(
                          color: Color(0xFFF7EBCB),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFFEFC66E),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_world.logsDelivered + _world.wood} / ${_WoodcuttingWorld.totalLogGoal} tomruk',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₺${_formatCash(_world.cash)}',
                            style: const TextStyle(
                              color: Color(0xFFF0CD77),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_hasStarted && !_world.isComplete) ...[
                  if (_world.deliveryCount > 0) ...[
                    const SizedBox(width: 7),
                    Material(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        onTap: () => setState(() => _showUpgradeShop = true),
                        borderRadius: BorderRadius.circular(11),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.build_rounded,
                            color: Color(0xFFF0C66B),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 7),
                  Material(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: _togglePause,
                      borderRadius: BorderRadius.circular(11),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        const DebugSettingsButton(iconColor: Color(0xFFF0C66B)),
      ],
    ),
  );

  Widget _buildControls() => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      padding: const EdgeInsets.fromLTRB(17, 25, 17, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00132018), Color(0xD916281D), Color(0xF216281D)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: GestureDetector(
              onPanStart: (details) =>
                  _updateJoystick(details.localPosition, const Size(88, 88)),
              onPanUpdate: (details) =>
                  _updateJoystick(details.localPosition, const Size(88, 88)),
              onPanEnd: (_) => _releaseJoystick(),
              onPanCancel: _releaseJoystick,
              child: CustomPaint(
                painter: _JoystickPainter(_joystickInput),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xE8F7F1DF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330D1B12),
                    blurRadius: 16,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _world.wood > 0
                        ? 'TOMRUKLARI TESLİM ET'
                        : _world.deliveryCount == 0
                        ? 'AĞAÇLARA SÜR'
                        : _world.upgradeCount == 0
                        ? 'İLK SATIŞINI YATIRIMA ÇEVİR'
                        : 'İKİNCİ YÜKÜ TOPLA',
                    style: const TextStyle(
                      color: Color(0xFF406246),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.75,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _world.wood > 0
                        ? 'Tomrukları yükle, sonra sahaya teslim et.'
                        : _world.deliveryCount == 0
                        ? 'Ağaca değince kesilir. Tomrukların üstünden geçip yükle.'
                        : _world.upgradeCount == 0
                        ? 'İlk teslimatından sonra açılan geliştirme dükkânını aç.'
                        : 'İkinci teslimat ve vardiya süresi tamamlanınca eve döneceksin.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF28382C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value:
                          ((_world.logsDelivered + _world.wood) /
                                  _WoodcuttingWorld.totalLogGoal)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFD5D0BE),
                      color: const Color(0xFF6C8D4D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildToast(String message) => Positioned(
    left: 24,
    right: 24,
    bottom: 132,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xED24392B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x66F2D17B)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFF4D9),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildWelcomeCard() => _buildOverlayCard(
    eyebrow: 'AKPINAR’DAN UZAKTA',
    title: 'Ormanda son\nvardiyan.',
    body: 'Genç bir oduncusun. İlk yükünü Kereste Sahası’na teslim et; ardından Akpınar’dan gelen mektubun peşinden eve dön.',
    buttonLabel: 'VARDİYAYA BAŞLA',
    buttonIcon: Icons.arrow_forward_rounded,
    onPressed: _start,
    footer: 'Sürmek için sol çubuğu kullan',
  );

  Widget _buildPauseCard() => _buildOverlayCard(
    eyebrow: 'VARDİYA DURAKLATILDI',
    title: 'Bir soluklan.',
    body: 'Orman ve yarım kalan yükün seni bekliyor.',
    buttonLabel: 'VARDİYAYA DÖN',
    buttonIcon: Icons.play_arrow_rounded,
    onPressed: _togglePause,
    footer: 'WASD veya ok tuşlarıyla da sürebilirsin',
  );

  Widget _buildCompletionCard() => _buildOverlayCard(
    eyebrow: 'VARDİYA TAMAMLANDI',
    title: 'Şimdi eve\ndönme vakti.',
    body: 'İki yük teslim ettin ve vardiyadan kazandığınla ekipmanını geliştirdin. Kereste sahasından çıkarken postacı sana Akpınar’dan gelen bir zarf uzatıyor.',
    buttonLabel: 'MEKTUBU OKU',
    buttonIcon: Icons.mail_outline_rounded,
    onPressed: DebugActionController.instance.actionCallback<void>(
      widget.onReadLetter,
    ),
    footer:
        'Teslimat: ${_world.deliveryCount} · Geliştirme: ${_world.upgradeCount} · Aktif süre: ${_world.activeSeconds.floor()} sn',
  );

  Widget _buildUpgradeShop() => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xA6102017),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3E5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE3D7BA), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x550C1B11),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'KERESTE SAHASI · EKİPMANCI',
                          style: TextStyle(
                            color: Color(0xFF70806F),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showUpgradeShop = false),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        color: const Color(0xFF6C786B),
                      ),
                    ],
                  ),
                  const Text(
                    'İlk satışınla\nbiraz güçlen.',
                    style: TextStyle(
                      color: Color(0xFF23392B),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'En az bir geliştirme al. Sonra ikinci yükü de teslim et; vardiya tamamlanınca Akpınar’a dönebilirsin.',
                    style: TextStyle(
                      color: Color(0xFF657364),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bakiye  ₺${_formatCash(_world.cash)}',
                    style: const TextStyle(
                      color: Color(0xFF315B3F),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final upgrade in _WoodcuttingUpgrade.values) ...[
                    _buildUpgradeOption(upgrade),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Vardiya hedefi: 2 teslimat · 2,5 dakika aktif oyun · en az 1 geliştirme',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF879184),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => setState(() => _showUpgradeShop = false),
                    child: Text(
                      _world.upgradeCount > 0 ? 'ORMANA DÖN' : 'ŞİMDİ DEĞİL',
                      style: const TextStyle(
                        color: Color(0xFF315B3F),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildUpgradeOption(_WoodcuttingUpgrade upgrade) {
    final owned = _world.isUpgradePurchased(upgrade);
    final canBuy =
        !owned && _world.deliveryCount > 0 && _world.cash >= upgrade.cost;
    return SizedBox(
      height: 70,
      child: FilledButton(
        onPressed: canBuy ? () => _purchaseUpgrade(upgrade) : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF315B3F),
          foregroundColor: const Color(0xFFFFF8E9),
          disabledBackgroundColor: const Color(0xFFE2E5DC),
          disabledForegroundColor: const Color(0xFF627063),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          children: [
            Icon(upgrade.icon, size: 22),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    upgrade.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              owned ? 'ALINDI' : '₺${upgrade.cost}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayCard({
    required String eyebrow,
    required String title,
    required String body,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
    required String footer,
  }) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0x8C102017),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 21),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3E5),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x550C1B11),
                    blurRadius: 35,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF345940),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      _world.isComplete
                          ? Icons.mail_rounded
                          : Icons.forest_rounded,
                      color: const Color(0xFFF0C66B),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    eyebrow,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF70806F),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF23392B),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF657364),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 19),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF315B3F),
                        foregroundColor: const Color(0xFFFFF8E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Icon(buttonIcon, size: 19),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    footer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF879184),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static String _formatCash(double amount) => amount
      .toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1)
      .replaceAll('.', ',');
}

enum _WoodcuttingUpgrade {
  sharpChain(
    cost: 55,
    title: 'Keskin zincir',
    description: 'Her ağaçtan bir tomruk fazla al.',
    icon: Icons.content_cut_rounded,
  ),
  engine(
    cost: 75,
    title: 'Traktör motoru',
    description: 'Ormanda daha hızlı yol al.',
    icon: Icons.speed_rounded,
  );

  const _WoodcuttingUpgrade({
    required this.cost,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int cost;
  final String title;
  final String description;
  final IconData icon;
}

class _WoodcuttingWorld {
  static const double width = 2180;
  static const double height = 1420;
  static const int loadGoal = 8;
  static const int totalLogGoal =
      loadGoal * WoodcuttingOpeningProgress.minimumDeliveryCount;
  static const Offset yardCenter = Offset(252, 1162);
  static const double yardRadius = 118;
  static const double playerSpeed = 246;

  _WoodcuttingWorld(WoodcuttingOpeningProgress progress)
    : activeSeconds = progress.activeSeconds,
      cash = progress.cash,
      wood = progress.carriedLogs,
      logsDelivered = progress.logsDelivered,
      deliveryCount = progress.deliveryCount,
      hasSharpChainUpgrade = progress.hasSharpChainUpgrade,
      hasEngineUpgrade = progress.hasEngineUpgrade;

  final List<_ForestTree> trees = _createForest();
  final List<_FallenLog> logs = [];
  Offset player = const Offset(580, 920);
  double heading = -math.pi / 2;
  int wood;
  int logsDelivered;
  int deliveryCount;
  double cash;
  double activeSeconds;
  bool hasSharpChainUpgrade;
  bool hasEngineUpgrade;
  double cameraX = 0;
  double cameraY = 0;
  bool _cameraInitialized = false;
  double toastSeconds = 0;
  String? toast;
  bool isComplete = false;

  int get upgradeCount =>
      (hasSharpChainUpgrade ? 1 : 0) + (hasEngineUpgrade ? 1 : 0);

  WoodcuttingOpeningProgress toProgress() => WoodcuttingOpeningProgress(
    activeSeconds: activeSeconds,
    cash: cash,
    carriedLogs: wood,
    logsDelivered: logsDelivered,
    deliveryCount: deliveryCount,
    hasSharpChainUpgrade: hasSharpChainUpgrade,
    hasEngineUpgrade: hasEngineUpgrade,
  );

  bool isUpgradePurchased(_WoodcuttingUpgrade upgrade) => switch (upgrade) {
    _WoodcuttingUpgrade.sharpChain => hasSharpChainUpgrade,
    _WoodcuttingUpgrade.engine => hasEngineUpgrade,
  };

  bool purchaseUpgrade(_WoodcuttingUpgrade upgrade) {
    if (deliveryCount == 0 ||
        cash < upgrade.cost ||
        isUpgradePurchased(upgrade)) {
      return false;
    }
    cash -= upgrade.cost;
    switch (upgrade) {
      case _WoodcuttingUpgrade.sharpChain:
        hasSharpChainUpgrade = true;
      case _WoodcuttingUpgrade.engine:
        hasEngineUpgrade = true;
    }
    return true;
  }

  Offset cameraFor(Size viewport) {
    if (!_cameraInitialized) return _cameraTarget(viewport);
    return Offset(
      cameraX.clamp(0.0, math.max(0.0, width - viewport.width)).toDouble(),
      cameraY.clamp(0.0, math.max(0.0, height - viewport.height)).toDouble(),
    );
  }

  void update(double delta, Offset direction, {required Size viewport}) {
    if (isComplete) return;
    toastSeconds = math.max(0.0, toastSeconds - delta).toDouble();
    if (toastSeconds == 0) toast = null;

    if (direction.distance > 0.05) activeSeconds += delta;
    if (direction.distance > 0.01) {
      final normalized = direction / direction.distance;
      heading = math.atan2(normalized.dy, normalized.dx);
      final oldPosition = player;
      final effectivePlayerSpeed = playerSpeed * (hasEngineUpgrade ? 1.3 : 1.0);
      var x = (player.dx + normalized.dx * effectivePlayerSpeed * delta)
          .clamp(24.0, width - 24)
          .toDouble();
      var y = (player.dy + normalized.dy * effectivePlayerSpeed * delta)
          .clamp(24.0, height - 24)
          .toDouble();
      if (x > 1280 - 24) {
        x = oldPosition.dx;
        y = oldPosition.dy;
      }
      player = Offset(x, y);

      _ForestTree? contactedTree;
      var nearest = double.infinity;
      for (final tree in trees) {
        if (!tree.isStanding) continue;
        final distance = (tree.position - player).distance;
        final contactRadius =
            24 + tree.radius * (hasSharpChainUpgrade ? 0.7 : 0.45);
        if (distance <= contactRadius && distance < nearest) {
          nearest = distance;
          contactedTree = tree;
        }
      }
      if (contactedTree != null) _fellTree(contactedTree);
    }

    for (var index = logs.length - 1; index >= 0; index--) {
      final log = logs[index];
      if ((log.position - player).distance <= 42 && wood < 200) {
        logs.removeAt(index);
        wood++;
      }
    }

    final isAtYard = (player - yardCenter).distance <= yardRadius;
    if (isAtYard && wood >= loadGoal) {
      final delivered = wood;
      logsDelivered += delivered;
      deliveryCount++;
      cash += delivered * 0.8;
      wood = 0;
      toast =
          '$delivered tomruk teslim edildi · +₺${_formatCash(delivered * 0.8)}';
      toastSeconds = 2.0;
    } else if (isAtYard && wood > 0 && toastSeconds == 0) {
      toast = 'Teslimat için en az $loadGoal tomruk yükle';
      toastSeconds = 2.0;
    }

    isComplete =
        activeSeconds >= WoodcuttingOpeningProgress.minimumActiveSeconds &&
        deliveryCount >= WoodcuttingOpeningProgress.minimumDeliveryCount &&
        upgradeCount >= WoodcuttingOpeningProgress.minimumUpgradeCount;

    final target = _cameraTarget(viewport);
    if (!_cameraInitialized) {
      cameraX = target.dx;
      cameraY = target.dy;
      _cameraInitialized = true;
    } else {
      final follow = math.min(1.0, delta * 4.2).toDouble();
      cameraX += (target.dx - cameraX) * follow;
      cameraY += (target.dy - cameraY) * follow;
    }
  }

  Offset _cameraTarget(Size viewport) => Offset(
    (player.dx - viewport.width / 2)
        .clamp(0.0, math.max(0.0, width - viewport.width))
        .toDouble(),
    (player.dy - viewport.height / 2)
        .clamp(0.0, math.max(0.0, height - viewport.height))
        .toDouble(),
  );

  void setViewport(Size viewport) {
    if (_cameraInitialized) return;
    final target = _cameraTarget(viewport);
    cameraX = target.dx;
    cameraY = target.dy;
    _cameraInitialized = true;
  }

  void _fellTree(_ForestTree tree) {
    tree.isStanding = false;
    final logCount = hasSharpChainUpgrade ? 5 : 4;
    for (var index = 0; index < logCount; index++) {
      final angle = (math.pi * 2 * index) / logCount + tree.seed * 2;
      final spread = (19 + (index.isEven ? 0 : 8)).toDouble();
      logs.add(
        _FallenLog(
          position:
              tree.position + Offset(math.cos(angle), math.sin(angle)) * spread,
          rotation: angle + 0.3,
        ),
      );
    }
    toast = 'Ağaç devrildi · Tomrukları topla';
    toastSeconds = 1.8;
  }

  static List<_ForestTree> _createForest() {
    final result = <_ForestTree>[];
    void addArea({
      required double left,
      required double top,
      required double areaWidth,
      required double areaHeight,
      required int seed,
    }) {
      final random = math.Random(seed);
      for (var row = 0; row < 20; row++) {
        for (var column = 0; column < 22; column++) {
          final x =
              (left +
                      column * (areaWidth / 21) +
                      (random.nextDouble() - 0.5) * 24)
                  .toDouble();
          final y =
              (top + row * (areaHeight / 19) + (random.nextDouble() - 0.5) * 24)
                  .toDouble();
          if (x < 560 && y > 815) continue;
          if (x < 435 && y > 700 && y < 1000) continue;
          result.add(
            _ForestTree(
              position: Offset(x, y),
              radius: (22 + random.nextDouble() * 5).toDouble(),
              hue: random.nextInt(3),
              seed: random.nextDouble(),
            ),
          );
        }
      }
    }

    addArea(left: 350, top: 175, areaWidth: 830, areaHeight: 840, seed: 421);
    addArea(left: 1390, top: 170, areaWidth: 660, areaHeight: 880, seed: 982);
    return result;
  }

  static String _formatCash(double amount) => amount
      .toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1)
      .replaceAll('.', ',');
}

class _ForestTree {
  _ForestTree({
    required this.position,
    required this.radius,
    required this.hue,
    required this.seed,
  });

  final Offset position;
  final double radius;
  final int hue;
  final double seed;
  bool isStanding = true;
}

class _FallenLog {
  const _FallenLog({required this.position, required this.rotation});

  final Offset position;
  final double rotation;
}

class _ForestPainter extends CustomPainter {
  const _ForestPainter(this.world);

  final _WoodcuttingWorld world;
  static final List<Offset> _groundMarks = _createGroundMarks();
  static const List<List<Color>> _treeColors = [
    [Color(0xFF315D3D), Color(0xFF4D7749), Color(0xFF688A52)],
    [Color(0xFF375F40), Color(0xFF567D49), Color(0xFF739257)],
    [Color(0xFF38573C), Color(0xFF4C714A), Color(0xFF739054)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final camera = world.cameraFor(size);
    final worldRect = const Rect.fromLTWH(
      0,
      0,
      _WoodcuttingWorld.width,
      _WoodcuttingWorld.height,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF6D925F),
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-camera.dx, -camera.dy);
    canvas.drawRect(
      worldRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7E9D69), Color(0xFF6D925E), Color(0xFF567C54)],
        ).createShader(worldRect),
    );
    _drawGroundMarks(canvas, camera, size);
    _drawRoads(canvas);
    _drawYard(canvas);
    _drawLockedArea(canvas);
    _drawTrees(canvas, camera, size);
    _drawLogs(canvas, camera, size);
    _drawLabels(canvas);
    _drawTractor(canvas);
    canvas.restore();
    _drawYardGuide(canvas, size, camera);
  }

  void _drawGroundMarks(Canvas canvas, Offset camera, Size size) {
    final visible = Rect.fromLTWH(
      camera.dx,
      camera.dy,
      size.width,
      size.height,
    );
    for (var index = 0; index < _groundMarks.length; index++) {
      final mark = _groundMarks[index];
      if (!visible.inflate(70).contains(mark)) continue;
      final radius = (14 + (index % 9) * 6.5).toDouble();
      canvas.drawOval(
        Rect.fromCenter(
          center: mark,
          width: radius * 2.7,
          height: radius * 1.3,
        ),
        Paint()
          ..color = index % 3 == 0
              ? const Color(0x149EB17A)
              : const Color(0x13355438),
      );
    }
  }

  void _drawRoads(Canvas canvas) {
    final road = Path()
      ..moveTo(258, 1160)
      ..cubicTo(370, 1145, 370, 985, 475, 949)
      ..cubicTo(590, 906, 664, 950, 725, 838)
      ..cubicTo(815, 678, 876, 722, 1014, 658)
      ..cubicTo(1128, 602, 1190, 674, 1280, 720);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x4434472F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 104
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFC8B486)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 78
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x55F1E5C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawYard(Canvas canvas) {
    final yard = RRect.fromRectAndRadius(
      const Rect.fromLTWH(65, 1010, 405, 315),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      yard.shift(const Offset(-1, 8)),
      Paint()..color = const Color(0x44334732),
    );
    canvas.drawRRect(yard, Paint()..color = const Color(0xFFD1C097));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(77, 1022, 381, 291),
        const Radius.circular(16),
      ),
      Paint()
        ..color = const Color(0x66927E55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(90, 1033, 174, 110),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFF385B3E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(99, 1044, 156, 91),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF233B2C),
    );
    canvas.drawRect(
      const Rect.fromLTWH(99, 1094, 156, 41),
      Paint()..color = const Color(0xFFD3AC60),
    );
    _drawText(
      canvas,
      'ORMAN ROTASI',
      const Offset(177, 1073),
      fontSize: 11,
      color: const Color(0xFFFFF3D4),
      weight: FontWeight.w900,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(288, 1032, 150, 64),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF304B39),
    );
    _drawText(
      canvas,
      'TOMRUK TESLİM',
      const Offset(363, 1057),
      fontSize: 9,
      color: const Color(0xFFF4E9CA),
      weight: FontWeight.w900,
    );
    _drawText(
      canvas,
      'YÜKÜNÜ BOŞALT',
      const Offset(363, 1076),
      fontSize: 8,
      color: const Color(0xFFD7D0B6),
      weight: FontWeight.w600,
    );
    canvas.drawCircle(
      _WoodcuttingWorld.yardCenter,
      _WoodcuttingWorld.yardRadius,
      Paint()
        ..color = const Color(0x99F6D986)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var index = 0; index < 5; index++) {
      final x = (296 + (index % 3) * 35.0).toDouble();
      final y = (1142 + (index ~/ 3) * 34.0).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 35, 12),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF805C3D),
      );
      canvas.drawCircle(
        Offset(x + 31, y + 6),
        4.5,
        Paint()..color = const Color(0xFFD0A364),
      );
    }
  }

  void _drawLockedArea(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(1280, 0, 900, _WoodcuttingWorld.height),
      Paint()..color = const Color(0x4D183923),
    );
    final fencePaint = Paint()
      ..color = const Color(0xFF584B34)
      ..strokeWidth = 6;
    for (var y = 0.0; y < _WoodcuttingWorld.height; y += 76) {
      if ((y - 720).abs() < 98) continue;
      canvas.drawLine(Offset(1280, y), Offset(1280, y + 76), fencePaint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1259, 677, 42, 86),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF644D31),
    );
    canvas.drawRect(
      const Rect.fromLTWH(1265, 716, 30, 8),
      Paint()..color = const Color(0xFFE0BD69),
    );
  }

  void _drawTrees(Canvas canvas, Offset camera, Size size) {
    final visible = Rect.fromLTWH(
      camera.dx,
      camera.dy,
      size.width,
      size.height,
    ).inflate(70);
    for (final tree in world.trees) {
      if (tree.position.dx >= 1280) continue;
      if (!visible.contains(tree.position)) continue;
      _drawTree(canvas, tree);
    }
  }

  void _drawTree(Canvas canvas, _ForestTree tree) {
    final x = tree.position.dx;
    final y = tree.position.dy;
    final radius = tree.radius;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + 8, y + 13),
        width: radius * 2.3,
        height: radius * 1.25,
      ),
      Paint()..color = const Color(0x3930442E),
    );
    if (!tree.isStanding) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y + 2), width: 21, height: 14),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF77553A),
      );
      canvas.drawCircle(
        Offset(x + 3, y + 2),
        4,
        Paint()..color = const Color(0xFFD0A56C),
      );
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 5, y - 5, 11, 30),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF705238),
    );
    final colors = _treeColors[tree.hue];
    canvas.drawCircle(
      Offset(x - 3, y - 17),
      radius * 0.78,
      Paint()..color = colors[0],
    );
    canvas.drawCircle(
      Offset(x + 10, y - 22),
      radius * 0.61,
      Paint()..color = colors[1],
    );
    canvas.drawCircle(
      Offset(x - 12, y - 28),
      radius * 0.47,
      Paint()..color = colors[2],
    );
    canvas.drawCircle(
      Offset(x - 15, y - 32),
      radius * 0.16,
      Paint()..color = const Color(0x447FC27B),
    );
  }

  void _drawLogs(Canvas canvas, Offset camera, Size size) {
    final visible = Rect.fromLTWH(
      camera.dx,
      camera.dy,
      size.width,
      size.height,
    ).inflate(45);
    for (final log in world.logs) {
      if (!visible.contains(log.position)) continue;
      canvas.save();
      canvas.translate(log.position.dx, log.position.dy);
      canvas.rotate(log.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-13, -1, 31, 11),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0x44302F23),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-15, -8, 30, 10),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF8C613B),
      );
      canvas.drawOval(
        const Rect.fromLTWH(11, -8, 9, 10),
        Paint()..color = const Color(0xFFD2A365),
      );
      canvas.drawOval(
        const Rect.fromLTWH(14, -6, 4, 5),
        Paint()
          ..color = const Color(0xFF725033)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  void _drawLabels(Canvas canvas) {
    _drawText(
      canvas,
      'GÜNEY ORMANI',
      const Offset(770, 165),
      fontSize: 12,
      color: const Color(0xA8F8F0DA),
      weight: FontWeight.w900,
    );
    _drawText(
      canvas,
      'KUZEY KORUSU',
      const Offset(1660, 165),
      fontSize: 12,
      color: const Color(0x75F8F0DA),
      weight: FontWeight.w900,
    );
  }

  void _drawTractor(Canvas canvas) {
    canvas.save();
    canvas.translate(world.player.dx, world.player.dy);
    canvas.rotate(world.heading);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-28, -18, 62, 38),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0x55323826),
    );
    final wheel = Paint()..color = const Color(0xFF273A2D);
    for (final position in const [
      Offset(-14, -21),
      Offset(15, -21),
      Offset(-14, 15),
      Offset(15, 15),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: position, width: 18, height: 11),
          const Radius.circular(4),
        ),
        wheel,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -17, 43, 34),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFFD6A749),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -12, 21, 24),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF4D7550),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -10, 15, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFB9CDAA),
    );
    canvas.drawRect(
      const Rect.fromLTWH(17, -9, 4, 7),
      Paint()..color = const Color(0xFFE3EBCF),
    );
    canvas.drawRect(
      const Rect.fromLTWH(17, 3, 4, 7),
      Paint()..color = const Color(0xFFE3EBCF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, -6, 13, 12),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF714E2E),
    );
    canvas.drawCircle(
      const Offset(44, 0),
      12,
      Paint()..color = const Color(0xFFBFC9B4),
    );
    canvas.drawCircle(
      const Offset(44, 0),
      9,
      Paint()
        ..color = const Color(0xFF677265)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  void _drawYardGuide(Canvas canvas, Size size, Offset camera) {
    if (world.wood == 0) return;
    final yardOnScreen = _WoodcuttingWorld.yardCenter - camera;
    final safeRect = Rect.fromLTRB(28, 78, size.width - 28, size.height - 126);
    if (safeRect.contains(yardOnScreen)) return;

    final center = Offset(size.width / 2, size.height / 2);
    final direction = yardOnScreen - center;
    if (direction.distance == 0) return;
    final horizontalLimit = math.max(1.0, size.width / 2 - 38).toDouble();
    final verticalLimit = math.max(1.0, size.height / 2 - 104).toDouble();
    final scale = math
        .min(
          direction.dx == 0
              ? double.infinity
              : horizontalLimit / direction.dx.abs(),
          direction.dy == 0
              ? double.infinity
              : verticalLimit / direction.dy.abs(),
        )
        .toDouble();
    final marker = center + direction * scale;

    canvas.drawCircle(marker, 19, Paint()..color = const Color(0xDD243B2D));
    canvas.drawCircle(
      marker,
      19,
      Paint()
        ..color = const Color(0xFFF0C66B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.save();
    canvas.translate(marker.dx, marker.dy - 1);
    canvas.rotate(direction.direction + math.pi / 2);
    final arrow = Path()
      ..moveTo(0, -10)
      ..lineTo(-7, 7)
      ..lineTo(0, 4)
      ..lineTo(7, 7)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFFE7A7));
    canvas.restore();
    _drawText(
      canvas,
      'SAHA',
      marker + const Offset(0, 30),
      fontSize: 8,
      color: const Color(0xFFFFF2CE),
      weight: FontWeight.w900,
    );
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  static List<Offset> _createGroundMarks() {
    final random = math.Random(553);
    return List.generate(
      280,
      (_) => Offset(
        random.nextDouble() * _WoodcuttingWorld.width,
        random.nextDouble() * _WoodcuttingWorld.height,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ForestPainter oldDelegate) => true;
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter(this.input);

  final Offset input;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 42, Paint()..color = const Color(0xA821392C));
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..color = const Color(0x88F2E9D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    final knobCenter = center + input * 22;
    canvas.drawCircle(knobCenter, 17, Paint()..color = const Color(0xFFF0C66B));
    canvas.drawCircle(
      knobCenter,
      17,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.input != input;
}
