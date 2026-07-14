/// Sync Queue Service
/// Processes the background sync queue with retry logic and connectivity checks.
library;

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/base/base_service.dart';
import '../core/interfaces/sync_queue_service_interface.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/storage_provider_service_interface.dart';
import '../models/sync_queue_item.dart';

/// Manages the background sync queue: enqueue, retry, exponential backoff.
final class SyncQueueService extends BaseService
    implements ISyncQueueService {
  final IDatabaseService _db;
  final IStorageProviderService _storage;
  final Future<bool> Function()? _onlineChecker;

  static const int _maxRetries = 3;

  SyncQueueService({
    required IDatabaseService db,
    required IStorageProviderService storage,
    Future<bool> Function()? onlineChecker,
  })  : _db = db,
        _storage = storage,
        _onlineChecker = onlineChecker;

  @override
  String get serviceName => 'SyncQueueService';

  @override
  Future<void> initialize() async {
    logInfo('SyncQueueService initialized');
  }

  /// Enqueue a document for upload or deletion.
  @override
  Future<void> enqueue(String documentId, String action) async {
    final item = SyncQueueItem(
      id: const Uuid().v4(),
      action: action,
      resourceType: 'document',
      resourceId: documentId,
      data: jsonEncode({'documentId': documentId}),
      createdAt: DateTime.now(),
      retryCount: 0,
      status: SyncStatus.pending,
    );
    await _db.insertSyncQueueItem(item);
    logInfo('Enqueued $action for document $documentId');
  }

  /// Process the queue: skip if offline, apply exponential backoff, sync each item.
  /// Returns the count of successfully synced items.
  @override
  Future<int> processQueue() async {
    if (!await _isOnline()) {
      logInfo('Offline — skipping sync queue processing');
      return 0;
    }

    final items = await _db.getPendingSyncItems(limit: 20);
    if (items.isEmpty) {
      logInfo('Sync queue is empty');
      return 0;
    }

    int successCount = 0;

    for (final item in items) {
      // Exponential backoff: skip items that were retried too recently
      if (_shouldSkipDueToBackoff(item)) {
        logInfo(
          'Skipping ${item.resourceId} (retry ${item.retryCount}, backoff not elapsed)',
        );
        continue;
      }

      // Mark as processing
      await _db.updateSyncQueueItemStatus(item.id, SyncStatus.processing);

      try {
        await _processItem(item);
        await _db.deleteSyncQueueItem(item.id);
        successCount++;
        logInfo('Synced ${item.action} for ${item.resourceId}');
      } catch (e, st) {
        final newRetryCount = item.retryCount + 1;
        if (newRetryCount >= _maxRetries) {
          await _db.updateSyncQueueItemStatus(
            item.id,
            SyncStatus.failed,
            retryCount: newRetryCount,
            lastRetryAt: DateTime.now(),
          );
          logWarning(
            'Sync permanently failed for ${item.resourceId} after $_maxRetries attempts: $e',
          );
        } else {
          await _db.updateSyncQueueItemStatus(
            item.id,
            SyncStatus.pending,
            retryCount: newRetryCount,
            lastRetryAt: DateTime.now(),
          );
          logError(
            'Sync attempt $newRetryCount failed for ${item.resourceId}',
            e,
            st,
          );
        }
      }
    }

    logInfo('Sync queue processed: $successCount/${items.length} succeeded');
    return successCount;
  }

  // ---- Internals ----

  Future<void> _processItem(SyncQueueItem item) async {
    switch (item.action) {
      case 'upload':
        final doc = await _db.getDocument(item.resourceId);
        if (doc == null) {
          // Document deleted locally — remove from queue silently
          logInfo('Document ${item.resourceId} no longer exists, removing from queue');
          return;
        }
        final uploadedCloudId = await _storage.uploadDocument(doc);
        await _db.markDocumentSynced(item.resourceId, uploadedCloudId);

      case 'delete':
        await _storage.deleteDocument(item.resourceId);

      default:
        logWarning('Unknown sync action: ${item.action}');
    }
  }

  /// Returns true when the item should be skipped because the exponential
  /// backoff window has not yet elapsed.
  ///
  /// Backoff: 2^retryCount minutes after last retry.
  bool _shouldSkipDueToBackoff(SyncQueueItem item) {
    if (item.retryCount == 0 || item.lastRetryAt == null) return false;
    final backoffMinutes = 1 << item.retryCount; // 2^retryCount
    final nextAllowed = item.lastRetryAt!.add(Duration(minutes: backoffMinutes));
    return DateTime.now().isBefore(nextAllowed);
  }

  Future<bool> _isOnline() async {
    if (_onlineChecker != null) return _onlineChecker();
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any(
        (r) => r != ConnectivityResult.none,
      );
    } catch (_) {
      return false;
    }
  }
}
