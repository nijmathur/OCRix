/// Sync Provider
/// Manages background sync state and workmanager scheduling.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/interfaces/sync_queue_service_interface.dart';
import 'document_provider.dart';
import 'troubleshooting_logger_provider.dart';
import '../services/sync_queue_service.dart';

part 'sync_provider.freezed.dart';

// ---- workmanager task name ----
const _syncTaskName = 'com.ocrix.app.backgroundSync';
const _syncTaskId = 'ocrix_background_sync';

// ---- Sync State ----

enum SyncPhase { idle, syncing, error }

@freezed
abstract class SyncState with _$SyncState {
  const factory SyncState({
    required SyncPhase phase,
    @Default(0) int pendingCount,
    String? lastError,
    DateTime? lastSyncedAt,
  }) = _SyncState;
}

// ---- Provider ----

final syncQueueServiceProvider = Provider<ISyncQueueService>((ref) {
  final db = ref.read(databaseServiceProvider);
  final storage = ref.read(storageProviderServiceProvider);
  final logger = ref.read(troubleshootingLoggerProvider);
  final service = SyncQueueService(db: db, storage: storage);
  service.setTroubleshootingLogger(logger);
  return service;
});

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

// ---- Notifier ----

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState(phase: SyncPhase.idle);

  /// Trigger a manual sync pass now.
  Future<void> manualSync() async {
    if (state.phase == SyncPhase.syncing) return; // already running
    state = state.copyWith(phase: SyncPhase.syncing, lastError: null);
    try {
      final service = ref.read(syncQueueServiceProvider);
      await service.processQueue();
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.error,
        lastError: e.toString(),
      );
    }
  }

  /// Called when the autoSync toggle or interval changes.
  Future<void> onAutoSyncToggled(bool enabled, int intervalMinutes) async {
    if (enabled) {
      await _registerBackgroundTask(intervalMinutes);
    } else {
      await _cancelBackgroundTask();
    }
  }

  Future<void> _registerBackgroundTask(int intervalMinutes) async {
    await Workmanager().cancelByUniqueName(_syncTaskId);
    await Workmanager().registerPeriodicTask(
      _syncTaskId,
      _syncTaskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> _cancelBackgroundTask() async {
    await Workmanager().cancelByUniqueName(_syncTaskId);
  }
}
