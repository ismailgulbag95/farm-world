import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runtime setting and shared delay gate for player-triggered game actions.
class DebugActionController {
  DebugActionController._();

  static final DebugActionController instance = DebugActionController._();

  static const Duration actionDelay = Duration(seconds: 2);

  final ValueNotifier<bool> debugModeNotifier = ValueNotifier(false);
  Future<void> _queuedAction = Future<void>.value();

  bool get debugModeEnabled => debugModeNotifier.value;

  void setDebugModeEnabled(bool enabled) {
    debugModeNotifier.value = enabled;
  }

  VoidCallback actionCallback<T>(FutureOr<T> Function() action) => () {
    unawaited(runPlayerAction(action));
  };

  /// Delays an action by two seconds in debug mode and keeps delayed actions
  /// in input order. Normal gameplay runs the action immediately.
  Future<T> runPlayerAction<T>(FutureOr<T> Function() action) {
    if (!debugModeEnabled) return Future<T>.sync(action);

    final operation = _queuedAction.then((_) async {
      await Future<void>.delayed(actionDelay);
      return await action();
    });
    _queuedAction = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }
}
