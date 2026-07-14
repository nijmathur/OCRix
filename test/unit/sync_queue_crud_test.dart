/// sync_queue CRUD tests.
///
/// Verifies that DatabaseService correctly inserts, retrieves, updates,
/// and deletes sync_queue items, and marks documents as synced.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
import 'package:ocrix/models/document.dart';
import 'package:ocrix/models/sync_queue_item.dart';
import 'package:ocrix/services/database_service.dart';

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
      createdAt: DateTime(2026, 1, 1, 12),
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
  late DatabaseService service;
  late MockEncryptionService mockEncryption;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockEncryption = MockEncryptionService();
    when(() => mockEncryption.isInitialized).thenReturn(true);
    when(() => mockEncryption.initialize()).thenAnswer((_) async {});
    when(() => mockEncryption.encryptText(any()))
        .thenAnswer((inv) async => 'enc:${inv.positionalArguments[0]}');
    when(() => mockEncryption.decryptText(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments[0] as String).replaceFirst('enc:', ''),
    );

    tempDir = await Directory.systemTemp.createTemp('ocrix_syncq_');
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
    service.setDatabasePathOverride(tempDir.path);
    await service.initialize();

    // Warm up connection (sqflite_ffi macOS cold-start quirk)
    await service.insertDocument(_makeDoc('warmup'));
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  group('insertSyncQueueItem', () {
    test('inserted item is retrievable via getPendingSyncItems', () async {
      final item = _makeItem();
      await service.insertSyncQueueItem(item);

      final pending = await service.getPendingSyncItems();
      expect(pending.map((i) => i.id), contains('item-1'));
    });

    test('multiple items are returned oldest-first', () async {
      await service.insertSyncQueueItem(
        _makeItem(id: 'old', resourceId: 'doc-1').copyWith(
          createdAt: DateTime(2026, 1, 1, 10),
        ),
      );
      await service.insertSyncQueueItem(
        _makeItem(id: 'new', resourceId: 'doc-2').copyWith(
          createdAt: DateTime(2026, 1, 1, 11),
        ),
      );

      final pending = await service.getPendingSyncItems();
      // 'warmup' doc was inserted but not enqueued — only our 2 items
      final ids = pending.map((i) => i.id).toList();
      expect(ids.indexOf('old'), lessThan(ids.indexOf('new')));
    });
  });

  group('getPendingSyncItems', () {
    test('returns only pending and failed items (not completed)', () async {
      await service.insertSyncQueueItem(_makeItem(id: 'p1', status: SyncStatus.pending));
      await service.insertSyncQueueItem(_makeItem(id: 'f1', status: SyncStatus.failed, resourceId: 'doc-f'));
      await service.insertSyncQueueItem(_makeItem(id: 'c1', status: SyncStatus.completed, resourceId: 'doc-c'));

      final pending = await service.getPendingSyncItems();
      final ids = pending.map((i) => i.id).toSet();
      expect(ids, contains('p1'));
      expect(ids, contains('f1'));
      expect(ids, isNot(contains('c1')));
    });

    test('respects limit parameter', () async {
      for (var i = 0; i < 5; i++) {
        await service.insertSyncQueueItem(
          _makeItem(id: 'lim-$i', resourceId: 'doc-$i'),
        );
      }
      final pending = await service.getPendingSyncItems(limit: 3);
      expect(pending.length, lessThanOrEqualTo(3));
    });
  });

  group('updateSyncQueueItemStatus', () {
    test('updates status to processing', () async {
      await service.insertSyncQueueItem(_makeItem(id: 'upd-1'));
      await service.updateSyncQueueItemStatus('upd-1', SyncStatus.processing);

      // processing items should not appear in getPendingSyncItems
      final pending = await service.getPendingSyncItems();
      expect(pending.map((i) => i.id), isNot(contains('upd-1')));
    });

    test('increments retry count on failure', () async {
      await service.insertSyncQueueItem(_makeItem(id: 'retry-1'));
      final now = DateTime.now();
      await service.updateSyncQueueItemStatus(
        'retry-1',
        SyncStatus.pending,
        retryCount: 1,
        lastRetryAt: now,
      );

      final pending = await service.getPendingSyncItems();
      final item = pending.firstWhere((i) => i.id == 'retry-1');
      expect(item.retryCount, equals(1));
      expect(item.lastRetryAt, isNotNull);
    });
  });

  group('deleteSyncQueueItem', () {
    test('removed item no longer appears in pending', () async {
      await service.insertSyncQueueItem(_makeItem(id: 'del-1'));
      await service.deleteSyncQueueItem('del-1');

      final pending = await service.getPendingSyncItems();
      expect(pending.map((i) => i.id), isNot(contains('del-1')));
    });

    test('deleting non-existent item does not throw', () async {
      await expectLater(
        () => service.deleteSyncQueueItem('ghost-item'),
        returnsNormally,
      );
    });
  });

  group('markDocumentSynced', () {
    test('sets isSynced=true and cloudId on the document', () async {
      const docId = 'sync-doc-1';
      await service.insertDocument(_makeDoc(docId));
      await service.markDocumentSynced(docId, 'cloud-abc-123');

      final doc = await service.getDocument(docId);
      expect(doc, isNotNull);
      expect(doc!.isSynced, isTrue);
      expect(doc.cloudId, equals('cloud-abc-123'));
      expect(doc.lastSyncedAt, isNotNull);
    });
  });
}
