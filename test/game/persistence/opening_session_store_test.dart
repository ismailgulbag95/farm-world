import 'dart:convert';
import 'dart:io';

import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/persistence/opening_session_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late OpeningSessionStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('farm_world_store_test_');
    store = OpeningSessionStore(
      directoryProvider: () async => tempDir,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('OpeningSessionStore - Missing Save', () {
    test('returns missing status and fresh session when save file does not exist', () async {
      final result = await store.load();

      expect(result.status, equals(SaveRecoveryStatus.missing));
      expect(result.canSave, isTrue);
      expect(store.canSave, isTrue);
      expect(result.state, isNull);
      expect(result.session.farmCredits, equals(0));
      expect(result.session.stage, equals(OpeningStage.scythe));
      expect(result.diagnosticLog, isNotNull);
    });

    test('permits saving after missing load', () async {
      final initialLoad = await store.load();
      expect(initialLoad.status, equals(SaveRecoveryStatus.missing));

      final saveResult = await store.save(const OpeningSessionState(farmCredits: 60));
      expect(saveResult.isSuccess, isTrue);

      final saveFile = File('${tempDir.path}/${store.fileName}');
      expect(saveFile.existsSync(), isTrue);

      final secondLoad = await store.load();
      expect(secondLoad.status, equals(SaveRecoveryStatus.valid));
      expect(secondLoad.session.farmCredits, equals(60));
    });
  });

  group('OpeningSessionStore - Round-trip State & Planting Anchor', () {
    test('roundtrips valid state including UTC first planting anchor', () async {
      final utcAnchor = DateTime.utc(2026, 10, 11, 14, 30, 0);
      const originalState = OpeningSessionState(
        farmCredits: 240,
        debt: 0,
        lifetimeProductionEvidence: 360,
        stage: OpeningStage.management,
        hasMower: true,
        hasWorker: true,
        isMowerAssignedToWorker: true,
        hasOwnedInitialPlot: true,
        freeInitialSeedsCount: 0,
        isCarryingBale: false,
        groundBaleCount: 3,
        mowingProgressSeconds: 8.5,
        baleMowingDurationSeconds: 22.5,
        firstSuccessfulPlantingAt: null,
      );

      final stateWithAnchor = originalState.copyWith(
        firstSuccessfulPlantingAt: utcAnchor,
      );

      final saveResult = await store.save(stateWithAnchor);
      expect(saveResult.isSuccess, isTrue);

      final loadResult = await store.load();
      expect(loadResult.status, equals(SaveRecoveryStatus.valid));
      expect(loadResult.canSave, isTrue);
      expect(loadResult.schemaVersion, equals(SessionSaveEnvelope.currentVersion));
      expect(loadResult.state, equals(stateWithAnchor));
      expect(loadResult.session.farmCredits, equals(240));
      expect(loadResult.session.isManagementStage, isTrue);
      expect(loadResult.session.firstSuccessfulPlantingAt, equals(utcAnchor));
      expect(loadResult.session.firstSuccessfulPlantingAt!.isUtc, isTrue);
    });
  });

  group('OpeningSessionStore - Atomic Replacement & Recoverable Backup', () {
    test('preserves previous valid save as recoverable backup on replacement', () async {
      const state1 = OpeningSessionState(farmCredits: 30);
      const state2 = OpeningSessionState(farmCredits: 90);

      // Save 1
      final save1Result = await store.save(state1);
      expect(save1Result.isSuccess, isTrue);

      final saveFile = File('${tempDir.path}/${store.fileName}');
      final backupFile = File('${tempDir.path}/${store.backupFileName}');
      final tempFile = File('${tempDir.path}/${store.tempFileName}');

      expect(saveFile.existsSync(), isTrue);
      expect(backupFile.existsSync(), isFalse);
      expect(tempFile.existsSync(), isFalse);

      // Save 2
      final save2Result = await store.save(state2);
      expect(save2Result.isSuccess, isTrue);

      expect(saveFile.existsSync(), isTrue);
      expect(backupFile.existsSync(), isTrue);
      expect(await store.hasBackup(), isTrue);
      expect(tempFile.existsSync(), isFalse);

      // Verify backup contains state 1 envelope
      final backupJson = jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;
      final backupState = OpeningSessionState.fromJson(backupJson['data'] as Map<String, dynamic>);
      expect(backupState.farmCredits, equals(30));

      // Verify primary save contains state 2 envelope
      final saveJson = jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
      final activeState = OpeningSessionState.fromJson(saveJson['data'] as Map<String, dynamic>);
      expect(activeState.farmCredits, equals(90));
    });
  });

  group('OpeningSessionStore - Recovery & No-Overwrite Protections', () {
    test('restores a verified backup and preserves it during the first save', () async {
      await store.save(const OpeningSessionState(farmCredits: 30));
      await store.save(const OpeningSessionState(farmCredits: 90));
      final saveFile = File('${tempDir.path}/${store.fileName}');
      final backupFile = File('${tempDir.path}/${store.backupFileName}');
      const corruptContent = '{broken save';
      await saveFile.writeAsString(corruptContent);

      final loadResult = await store.load();

      expect(loadResult.status, SaveRecoveryStatus.recoveredFromBackup);
      expect(loadResult.canSave, isTrue);
      expect(loadResult.session.farmCredits, 30);

      final saveResult = await store.save(
        const OpeningSessionState(farmCredits: 120),
      );

      expect(saveResult.isSuccess, isTrue);
      expect(await File('${saveFile.path}.corrupt').readAsString(), corruptContent);
      final backupJson = jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;
      expect(
        OpeningSessionState.fromJson(backupJson['data'] as Map<String, dynamic>).farmCredits,
        30,
      );
      final activeJson = jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
      expect(
        OpeningSessionState.fromJson(activeJson['data'] as Map<String, dynamic>).farmCredits,
        120,
      );
    });

    test('preserves corrupt file, disables writes, and provides diagnostic log', () async {
      final saveFile = File('${tempDir.path}/${store.fileName}');
      const corruptContent = '{"version": 1, "data": {broken_json...';
      await saveFile.writeAsString(corruptContent);

      final backupFile = File('${tempDir.path}/${store.backupFileName}');
      const existingBackup = '{"valid": true}';
      await backupFile.writeAsString(existingBackup);

      final loadResult = await store.load();

      expect(loadResult.status, equals(SaveRecoveryStatus.corrupt));
      expect(loadResult.canSave, isFalse);
      expect(store.canSave, isFalse);
      expect(store.recoveryStatus, equals(SaveRecoveryStatus.corrupt));
      expect(loadResult.diagnosticLog, isNotNull);
      expect(loadResult.session.farmCredits, equals(0)); // Fresh fallback session

      // Attempting to save must fail and refuse to overwrite corrupt data
      final attemptedSave = await store.save(const OpeningSessionState(farmCredits: 500));
      expect(attemptedSave.isSuccess, isFalse);
      expect(attemptedSave.diagnosticLog, contains('disabled'));

      // Verify disk files are preserved untouched
      expect(await saveFile.readAsString(), equals(corruptContent));
      expect(await backupFile.readAsString(), equals(existingBackup));
    });

    test('handles empty file as corrupt and disables writes', () async {
      final saveFile = File('${tempDir.path}/${store.fileName}');
      await saveFile.writeAsString('   ');

      final loadResult = await store.load();
      expect(loadResult.status, equals(SaveRecoveryStatus.corrupt));
      expect(loadResult.canSave, isFalse);
      expect(store.canSave, isFalse);
    });

    test('preserves unsupported schema version file and disables writes', () async {
      final saveFile = File('${tempDir.path}/${store.fileName}');
      final unsupportedEnvelope = {
        'version': 99,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'data': const OpeningSessionState(farmCredits: 1000).toJson(),
      };
      await saveFile.writeAsString(jsonEncode(unsupportedEnvelope));

      final loadResult = await store.load();

      expect(loadResult.status, equals(SaveRecoveryStatus.unsupportedVersion));
      expect(loadResult.schemaVersion, equals(99));
      expect(loadResult.canSave, isFalse);
      expect(store.canSave, isFalse);
      expect(loadResult.diagnosticLog, contains('99'));

      // Attempting to save must be rejected
      final saveAttempt = await store.save(const OpeningSessionState(farmCredits: 10));
      expect(saveAttempt.isSuccess, isFalse);

      // Verify file on disk is untouched
      final onDisk = jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
      expect(onDisk['version'], equals(99));
    });
  });

  group('OpeningSessionStore - Concurrent Writes Serialization', () {
    test('serializes rapid concurrent writes sequentially without corruption', () async {
      final states = List.generate(
        10,
        (i) => OpeningSessionState(farmCredits: (i + 1) * 30),
      );

      // Fire concurrent writes without awaiting each sequentially
      final results = await Future.wait(
        states.map((s) => store.save(s)),
      );

      for (final r in results) {
        expect(r.isSuccess, isTrue);
      }

      final loadResult = await store.load();
      expect(loadResult.status, equals(SaveRecoveryStatus.valid));
      // Final state should be the last queued write (300)
      expect(loadResult.session.farmCredits, equals(300));
    });
  });

  group('OpeningSessionAutosaver', () {
    test('throttles periodic writes and saves only when session state changes', () async {
      final session = OpeningSession();
      final autosaver = OpeningSessionAutosaver(
        session: session,
        store: store,
        interval: const Duration(milliseconds: 30),
      )..start();

      try {
        // Initial state: nothing has changed, file shouldn't be written yet
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final saveFile = File('${tempDir.path}/${store.fileName}');
        expect(saveFile.existsSync(), isFalse);

        // Mutate session state
        session.mow(22.5);
        session.pickUpBale();
        session.enterSaleZone();
        expect(session.farmCredits, equals(30));

        // Wait for next periodic tick to flush
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(saveFile.existsSync(), isTrue);

        final loaded = await store.load();
        expect(loaded.session.farmCredits, equals(30));
        expect(autosaver.lastSavedState.farmCredits, equals(30));
      } finally {
        autosaver.dispose();
        expect(autosaver.isDisposed, isTrue);
      }
    });

    test('flushes immediately on app lifecycle transition away from resumed', () async {
      final session = OpeningSession();
      final autosaver = OpeningSessionAutosaver(
        session: session,
        store: store,
        // Long interval to prove lifecycle flush happens before timer
        interval: const Duration(hours: 1),
      )..start();

      try {
        final saveFile = File('${tempDir.path}/${store.fileName}');
        expect(saveFile.existsSync(), isFalse);

        // Mutate session state
        session.mow(22.5);
        expect(session.groundBaleCount, equals(1));

        // Lifecycle transition away from resumed (e.g. paused)
        autosaver.didChangeAppLifecycleState(AppLifecycleState.paused);

        // Give async I/O a moment to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(saveFile.existsSync(), isTrue);

        final loaded = await store.load();
        expect(loaded.session.groundBaleCount, equals(1));

        // Transition back to resumed should not re-flush
        autosaver.didChangeAppLifecycleState(AppLifecycleState.resumed);
      } finally {
        autosaver.dispose();
      }
    });

    test('refuses to autosave when store writes are disabled', () async {
      // Create corrupt file to disable writes
      final saveFile = File('${tempDir.path}/${store.fileName}');
      await saveFile.writeAsString('corrupt data');
      await store.load();
      expect(store.canSave, isFalse);

      final session = OpeningSession();
      final autosaver = OpeningSessionAutosaver(
        session: session,
        store: store,
        interval: const Duration(milliseconds: 20),
      )..start();

      try {
        session.mow(22.5);
        await autosaver.flush();

        // Corrupt file must still be corrupt, not overwritten
        expect(await saveFile.readAsString(), equals('corrupt data'));
      } finally {
        autosaver.dispose();
      }
    });
  });
}
