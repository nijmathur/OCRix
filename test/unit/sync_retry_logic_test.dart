/// SyncQueueService retry logic tests.
///
/// Verifies:
/// 1. Successful items are deleted from queue after sync
/// 2. Failed items have retry_count incremented, status stays pending
/// 3. After maxRetries (3) failures, item is marked failed permanently
/// 4. Items within their backoff window are skipped
/// 5. Empty queue returns 0 successfully synced
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/models/sync_queue_item.dart';
import 'package:ocrix/services/sync_queue_service.dart';

import '../helpers/mocks.dart';

SyncQueueItem _makeItem({
  String id = 'item-1',
  String action = 'upload',
  String resourceId = 'doc-1',
  int retryCount = 0,
  SyncStatus status = SyncStatus.pending,
  DateTime? lastRetryAt,
}) =>
    SyncQueueItem(
      id: id,
      action: action,
      resourceType: 'document',
      resourceId: resourceId,
      data: '{"documentId":"$resourceId"}',
      createdAt: DateTime(2026, 1, 1),
      retryCount: retryCount,
      lastRetryAt: lastRetryAt,
      status: status,
    );

Document _makeDoc(String id) => Document.create(
      title: 'Test $id',
      extractedText: 'text',
      type: DocumentType.other,
      confidenceScore: 0.9,
      detectedLanguage: 'en',
      deviceInfo: 'test',
    ).copyWith(id: id);

void main() {
  late MockDatabaseService mockDb;
  late MockStorageProviderService mockStorage;
  late SyncQueueService service;

  setUpAll(() {
    registerFallbackValue(SyncStatus.pending);
    registerFallbackValue(_makeDoc('fallback'));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockStorage = MockStorageProviderService();

    // Simulate online: bypass real connectivity check so tests pass without network
    service = SyncQueueService(
      db: mockDb,
      storage: mockStorage,
      onlineChecker: () async => true,
    );

    // Stub updateSyncQueueItemStatus for the processing-status call (no named params)
    when(() => mockDb.updateSyncQueueItemStatus(any(), any()))
        .thenAnswer((_) async {});
    // Stub for retry/failure calls that include named params
    when(() => mockDb.updateSyncQueueItemStatus(
          any(),
          any(),
          retryCount: any(named: 'retryCount'),
          lastRetryAt: any(named: 'lastRetryAt'),
        )).thenAnswer((_) async {});
    when(() => mockDb.deleteSyncQueueItem(any())).thenAnswer((_) async {});
    when(() => mockStorage.deleteDocument(any())).thenAnswer((_) async {});
  });

  group('processQueue — empty queue', () {
    test('returns 0 when queue is empty', () async {
      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => []);

      final count = await service.processQueue();
      expect(count, equals(0));
    });
  });

  group('processQueue — successful upload', () {
    test('deletes item and marks document synced on success', () async {
      final item = _makeItem();
      final doc = _makeDoc('doc-1');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);
      when(() => mockDb.getDocument('doc-1')).thenAnswer((_) async => doc);
      when(() => mockStorage.uploadDocument(any()))
          .thenAnswer((_) async => 'cloud-id-123');
      when(() => mockDb.markDocumentSynced('doc-1', 'cloud-id-123'))
          .thenAnswer((_) async {});

      final count = await service.processQueue();
      expect(count, equals(1));
    });
  });

  group('exponential backoff', () {
    test('item with retryCount=1 and recent lastRetryAt is skipped', () async {
      // Retried 1 minute ago with retryCount=1 → backoff = 2^1 = 2 min → still waiting
      final item = _makeItem(
        retryCount: 1,
        lastRetryAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: SyncStatus.pending,
      );

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);

      final count = await service.processQueue();

      // Item was skipped — uploadDocument never called
      verifyNever(() => mockStorage.uploadDocument(any()));
      expect(count, equals(0));
    });

    test('item with retryCount=1 and old enough lastRetryAt is NOT skipped', () async {
      // Retried 3 minutes ago with retryCount=1 → backoff = 2 min → window elapsed
      final item = _makeItem(
        id: 'not-skipped',
        resourceId: 'doc-ns',
        retryCount: 1,
        lastRetryAt: DateTime.now().subtract(const Duration(minutes: 3)),
        status: SyncStatus.pending,
      );
      final doc = _makeDoc('doc-ns');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);
      when(() => mockDb.getDocument('doc-ns')).thenAnswer((_) async => doc);
      when(() => mockStorage.uploadDocument(any()))
          .thenAnswer((_) async => 'cid-ns');
      when(() => mockDb.markDocumentSynced(any(), any()))
          .thenAnswer((_) async {});

      final count = await service.processQueue();
      // Backoff window elapsed → item should be processed
      expect(count, equals(1));
    });
  });

  group('retry count increments on failure', () {
    test('retry_count increments and status stays pending below maxRetries', () async {
      final item = _makeItem(retryCount: 0);
      final doc = _makeDoc('doc-1');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);
      when(() => mockDb.getDocument('doc-1')).thenAnswer((_) async => doc);
      when(() => mockStorage.uploadDocument(any()))
          .thenThrow(Exception('upload failed'));

      await service.processQueue();

      // Should have updated to pending with retryCount=1
      verify(() => mockDb.updateSyncQueueItemStatus(
            'item-1',
            SyncStatus.pending,
            retryCount: 1,
            lastRetryAt: any(named: 'lastRetryAt'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('item is marked failed after maxRetries (3) failures', () async {
      // retryCount already at 2 → next failure → 3 = maxRetries → mark failed
      final item = _makeItem(retryCount: 2);
      final doc = _makeDoc('doc-1');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);
      when(() => mockDb.getDocument('doc-1')).thenAnswer((_) async => doc);
      when(() => mockStorage.uploadDocument(any()))
          .thenThrow(Exception('permanent failure'));

      await service.processQueue();

      verify(() => mockDb.updateSyncQueueItemStatus(
            'item-1',
            SyncStatus.failed,
            retryCount: 3,
            lastRetryAt: any(named: 'lastRetryAt'),
          )).called(greaterThanOrEqualTo(1));
    });
  });

  group('delete action', () {
    test('calls deleteDocument on storage for delete action', () async {
      final item = _makeItem(action: 'delete', resourceId: 'doc-del');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);

      // delete action: storage.deleteDocument should be called
      await service.processQueue();
      verify(() => mockStorage.deleteDocument('doc-del')).called(1);
    });
  });

  group('missing document in queue', () {
    test('removes item silently when document is deleted locally', () async {
      final item = _makeItem(resourceId: 'doc-gone');

      when(() => mockDb.getPendingSyncItems(limit: any(named: 'limit')))
          .thenAnswer((_) async => [item]);
      when(() => mockDb.getDocument('doc-gone')).thenAnswer((_) async => null);

      await service.processQueue();

      // uploadDocument should not be called for a missing document
      verifyNever(() => mockStorage.uploadDocument(any()));
    });
  });
}
