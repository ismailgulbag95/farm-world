import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/opening_session.dart';

/// Versioned JSON envelope wrapping persisted session state.
class SessionSaveEnvelope {
  const SessionSaveEnvelope({
    required this.version,
    required this.savedAt,
    required this.data,
  });

  /// Current supported schema version.
  static const int currentVersion = 2;

  final int version;
  final DateTime savedAt;
  final OpeningSessionState data;

  Map<String, dynamic> toJson() => {
    'version': version,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'data': data.toJson(),
  };

  factory SessionSaveEnvelope.create(OpeningSessionState state) {
    return SessionSaveEnvelope(
      version: currentVersion,
      savedAt: DateTime.now().toUtc(),
      data: state,
    );
  }
}

/// Typed recovery and status indicators for opening session persistence.
enum SaveRecoveryStatus {
  /// Save file was loaded successfully and verified against supported schema version.
  valid,

  /// No save file exists on disk (e.g. first-time launch).
  missing,

  /// Save file exists but could not be parsed, was malformed, or content was unreadable.
  corrupt,

  /// Save file has a schema version incompatible with or newer than this app release.
  unsupportedVersion,
}

/// Structured result returned when loading an opening session from persistence.
class LoadSessionResult {
  const LoadSessionResult({
    required this.status,
    required this.session,
    this.state,
    this.savedAt,
    this.diagnosticLog,
    required this.canSave,
    this.schemaVersion,
  });

  /// The outcome of the load attempt.
  final SaveRecoveryStatus status;

  /// The playable session instance to provide to gameplay.
  ///
  /// Initialized with loaded state if [status] is [SaveRecoveryStatus.valid],
  /// or a fresh default session if missing, corrupt, or unsupported version.
  final OpeningSession session;

  /// The deserialized state if [status] is [SaveRecoveryStatus.valid], otherwise null.
  final OpeningSessionState? state;

  /// Timestamp from the persisted envelope, used to advance scheduled systems
  /// only for the interval since the last successful save.
  final DateTime? savedAt;

  /// Diagnostic detail if a corruption or unsupported version occurred.
  /// Kept non-user-facing to avoid untranslated text in UI.
  final String? diagnosticLog;

  /// Whether subsequent saves are permitted for this session.
  ///
  /// False if the file was corrupt or unsupported, preventing destructive overwrite.
  final bool canSave;

  /// Schema version parsed from the envelope, if available.
  final int? schemaVersion;
}

/// Structured result returned when attempting a write to persistence.
class SaveSessionResult {
  const SaveSessionResult({required this.isSuccess, this.diagnosticLog});

  static const SaveSessionResult success = SaveSessionResult(isSuccess: true);

  final bool isSuccess;
  final String? diagnosticLog;
}

/// Local save store managing persistent versioned JSON files for [OpeningSessionState].
class OpeningSessionStore {
  OpeningSessionStore({
    Future<Directory> Function()? directoryProvider,
    this.fileName = defaultFileName,
    this.backupFileName = defaultBackupFileName,
    this.tempFileName = defaultTempFileName,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String defaultFileName = 'opening_session.json';
  static const String defaultBackupFileName = 'opening_session.json.bak';
  static const String defaultTempFileName = 'opening_session.json.tmp';

  final Future<Directory> Function() _directoryProvider;
  final String fileName;
  final String backupFileName;
  final String tempFileName;

  bool _canSave = true;
  LoadSessionResult? _lastLoadResult;

  /// Whether saves are currently permitted.
  /// Set to false if load encountered a corrupt or unsupported-version file.
  bool get canSave => _canSave;

  /// The result of the most recent load operation, if any.
  LoadSessionResult? get lastLoadResult => _lastLoadResult;

  /// The typed recovery status from the last load operation.
  SaveRecoveryStatus? get recoveryStatus => _lastLoadResult?.status;

  /// Diagnostic log from the last load operation or failure.
  String? get diagnosticLog => _lastLoadResult?.diagnosticLog;

  /// Chained future to serialize concurrent write operations.
  Future<void> _writeQueue = Future.value();

  /// Future that completes when all queued write operations finish.
  Future<void> get pendingWrite => _writeQueue;

  /// Loads the saved session from disk.
  ///
  /// Detects missing, valid, corrupt, and unsupported-version states.
  /// If the save file is corrupt or has an unsupported version, writes are disabled
  /// for this launch to prevent destructive overwrite, and a diagnostic log is recorded.
  Future<LoadSessionResult> load() async {
    try {
      final dir = await _directoryProvider();
      final saveFile = File(_resolvePath(dir.path, fileName));

      if (!await saveFile.exists()) {
        _canSave = true;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.missing,
          session: OpeningSession(),
          canSave: true,
          diagnosticLog: 'Save file does not exist.',
        );
        _lastLoadResult = result;
        return result;
      }

      final content = await saveFile.readAsString();
      if (content.trim().isEmpty) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          diagnosticLog: 'Save file is empty.',
        );
        _lastLoadResult = result;
        return result;
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(content);
      } catch (e) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          diagnosticLog: 'Corrupt JSON syntax: $e',
        );
        _lastLoadResult = result;
        return result;
      }

      if (decoded is! Map<String, dynamic>) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          diagnosticLog: 'Root JSON object is not a Map.',
        );
        _lastLoadResult = result;
        return result;
      }

      final version = decoded['version'];
      if (version is! int) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          diagnosticLog: 'Missing or non-integer schema version.',
        );
        _lastLoadResult = result;
        return result;
      }

      if (version != 1 && version != SessionSaveEnvelope.currentVersion) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.unsupportedVersion,
          session: OpeningSession(),
          canSave: false,
          schemaVersion: version,
          diagnosticLog:
              'Unsupported schema version: $version (supported: ${SessionSaveEnvelope.currentVersion}).',
        );
        _lastLoadResult = result;
        return result;
      }

      final dataMap = decoded['data'];
      if (dataMap is! Map<String, dynamic>) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          schemaVersion: version,
          diagnosticLog: 'Envelope "data" is missing or not a Map.',
        );
        _lastLoadResult = result;
        return result;
      }

      try {
        // Version 1 stored the same gameplay fields without the newer market,
        // contract and building-operation snapshot. Missing fields default to
        // starter values, then the next save writes the current v2 envelope.
        final state = OpeningSessionState.fromJson(dataMap);
        final savedAt = decoded['savedAt'] is String
            ? DateTime.tryParse(decoded['savedAt'] as String)?.toUtc()
            : null;
        _canSave = true;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.valid,
          session: OpeningSession(initialState: state),
          state: state,
          savedAt: savedAt,
          canSave: true,
          schemaVersion: version,
        );
        _lastLoadResult = result;
        return result;
      } catch (e) {
        _canSave = false;
        final result = LoadSessionResult(
          status: SaveRecoveryStatus.corrupt,
          session: OpeningSession(),
          canSave: false,
          schemaVersion: version,
          diagnosticLog: 'Invalid session state data: $e',
        );
        _lastLoadResult = result;
        return result;
      }
    } catch (e) {
      _canSave = false;
      final result = LoadSessionResult(
        status: SaveRecoveryStatus.corrupt,
        session: OpeningSession(),
        canSave: false,
        diagnosticLog: 'File read error: $e',
      );
      _lastLoadResult = result;
      return result;
    }
  }

  /// Saves the given [state] to disk.
  ///
  /// Serializes concurrent writes to execute sequentially.
  /// Writes and flushes to a temporary file, preserves previous valid save as a backup,
  /// then replaces the save file.
  Future<SaveSessionResult> save(OpeningSessionState state) {
    final future = _writeQueue.then(
      (_) => _performSave(state),
      onError: (_) => _performSave(state),
    );
    _writeQueue = future.then((_) {}, onError: (_) {});
    return future;
  }

  Future<SaveSessionResult> _performSave(OpeningSessionState state) async {
    if (!_canSave) {
      return const SaveSessionResult(
        isSuccess: false,
        diagnosticLog:
            'Writes are disabled to preserve unrecovered or corrupt save data.',
      );
    }

    try {
      final dir = await _directoryProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final saveFile = File(_resolvePath(dir.path, fileName));
      final backupFile = File(_resolvePath(dir.path, backupFileName));
      final tempFile = File(_resolvePath(dir.path, tempFileName));

      // 1. Write envelope to temporary file in the same directory and flush to disk
      final envelope = SessionSaveEnvelope.create(state);
      final jsonString = jsonEncode(envelope.toJson());
      await tempFile.writeAsString(jsonString, flush: true);

      // 2. Preserve previous valid save as a recoverable backup before replacement
      if (await saveFile.exists()) {
        await saveFile.copy(backupFile.path);
      }

      // 3. Atomically replace save file with temp file
      await tempFile.rename(saveFile.path);

      return SaveSessionResult.success;
    } catch (e) {
      // Clean up temporary file on failure
      try {
        final dir = await _directoryProvider();
        final tempFile = File(_resolvePath(dir.path, tempFileName));
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      return SaveSessionResult(
        isSuccess: false,
        diagnosticLog: 'Write failed: $e',
      );
    }
  }

  /// Checks if a backup file exists in the directory.
  Future<bool> hasBackup() async {
    try {
      final dir = await _directoryProvider();
      final backupFile = File(_resolvePath(dir.path, backupFileName));
      return await backupFile.exists();
    } catch (_) {
      return false;
    }
  }

  static String _resolvePath(String dirPath, String fileName) {
    if (dirPath.endsWith('/') || dirPath.endsWith('\\')) {
      return '$dirPath$fileName';
    }
    return '$dirPath${Platform.pathSeparator}$fileName';
  }
}

/// Coordinates throttled periodic autosaving and app lifecycle flushing for an [OpeningSession].
class OpeningSessionAutosaver with WidgetsBindingObserver {
  OpeningSessionAutosaver({
    required this.session,
    required this.store,
    this.interval = defaultInterval,
    this.binding,
  }) : _lastSavedState = session.state;

  static const Duration defaultInterval = Duration(seconds: 5);

  final OpeningSession session;
  final OpeningSessionStore store;
  final Duration interval;
  final WidgetsBinding? binding;

  WidgetsBinding? get _effectiveBinding {
    if (binding != null) return binding;
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null;
    }
  }

  Timer? _timer;
  OpeningSessionState _lastSavedState;
  bool _isSaving = false;
  bool _isDisposed = false;
  AppLifecycleState? _lastLifecycleState = AppLifecycleState.resumed;

  OpeningSessionState get lastSavedState => _lastSavedState;
  bool get isDisposed => _isDisposed;

  /// Starts the periodic timer and registers the lifecycle observer.
  void start() {
    if (_isDisposed) return;
    _effectiveBinding?.addObserver(this);
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _onTick());
  }

  void _onTick() {
    if (_isDisposed || !store.canSave) return;
    final currentState = session.state;
    if (currentState != _lastSavedState && !_isSaving) {
      _saveCurrentState(currentState);
    }
  }

  Future<void>? _pendingFlush;

  /// Future that completes when the latest flush operation finishes.
  Future<void>? get pendingFlush => _pendingFlush;

  /// Forces an immediate flush of unsaved state if changes occurred.
  Future<void> flush() async {
    if (_isDisposed || !store.canSave) return;
    final currentState = session.state;
    if (currentState != _lastSavedState) {
      final future = _saveCurrentState(currentState);
      _pendingFlush = future;
      await future;
    }
  }

  Future<void> _saveCurrentState(OpeningSessionState stateToSave) async {
    _isSaving = true;
    try {
      final result = await store.save(stateToSave);
      if (result.isSuccess) {
        _lastSavedState = stateToSave;
      }
    } finally {
      _isSaving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    // Flush when transitioning away from resumed
    if (_lastLifecycleState == AppLifecycleState.resumed &&
        state != AppLifecycleState.resumed) {
      flush();
    }
    _lastLifecycleState = state;
  }

  /// Cleanly cancels active timers and unregisters observers.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _effectiveBinding?.removeObserver(this);
  }
}
