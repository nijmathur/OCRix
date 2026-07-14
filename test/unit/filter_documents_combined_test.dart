/// Filter documents combined (type + search query) tests.
///
/// Verifies that DocumentNotifier.filterDocuments correctly passes both
/// a type filter and a search query to the database service simultaneously.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/core/models/audit_log_level.dart';
import 'package:ocrix/models/audit_log.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/providers/audit_provider.dart';
import 'package:ocrix/providers/document_provider.dart';
import 'package:ocrix/providers/troubleshooting_logger_provider.dart';

import '../helpers/mocks.dart';

Document _makeDoc(String id, DocumentType type) => Document.create(
      title: 'Doc $id',
      extractedText: 'text $id',
      type: type,
      confidenceScore: 0.9,
      detectedLanguage: 'en',
      deviceInfo: 'test',
    ).copyWith(id: id);

void main() {
  late MockDatabaseService mockDb;
  late MockTroubleshootingLogger mockLogger;
  late MockAuditDatabaseService mockAuditDb;

  setUpAll(() {
    registerFallbackValue(_makeDoc('fallback', DocumentType.other));
    registerFallbackValue(AuditEntry.create(
      level: AuditLogLevel.info,
      action: AuditAction.create,
      resourceType: 'document',
      resourceId: 'fallback',
      userId: 'test',
    ));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockLogger = MockTroubleshootingLogger();
    mockAuditDb = MockAuditDatabaseService();

    when(
      () => mockLogger.info(any(), tag: any(named: 'tag'), metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => mockLogger.warning(any(),
          tag: any(named: 'tag'),
          error: any(named: 'error'),
          metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => mockLogger.error(any(),
          tag: any(named: 'tag'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});

    when(() => mockAuditDb.initialize()).thenAnswer((_) async {});
    when(() => mockAuditDb.getLastEntry()).thenAnswer((_) async => null);
    when(() => mockAuditDb.insertAuditEntry(any())).thenAnswer((_) async => 'id');
  });

  ProviderContainer makeContainer() {
    // Stub initial load (no filter)
    when(() => mockDb.getAllDocuments(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          type: any(named: 'type'),
          searchQuery: any(named: 'searchQuery'),
        )).thenAnswer((_) async => []);

    return ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDb),
        troubleshootingLoggerProvider.overrideWithValue(mockLogger),
        auditDatabaseServiceProvider.overrideWithValue(mockAuditDb),
      ],
    );
  }

  group('filterDocuments with type + searchQuery', () {
    test('passes both type and searchQuery to getAllDocuments', () async {
      final doc = _makeDoc('d1', DocumentType.receipt);
      final container = makeContainer();
      addTearDown(container.dispose);

      when(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: DocumentType.receipt,
            searchQuery: 'coffee',
          )).thenAnswer((_) async => [doc]);

      await container.read(documentNotifierProvider.future);

      await container
          .read(documentNotifierProvider.notifier)
          .filterDocuments(type: DocumentType.receipt, searchQuery: 'coffee');

      final state = container.read(documentNotifierProvider).value!;
      expect(state, contains(doc));

      verify(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: DocumentType.receipt,
            searchQuery: 'coffee',
          )).called(1);
    });

    test('empty searchQuery is treated as no filter (null)', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(documentNotifierProvider.future);

      await container
          .read(documentNotifierProvider.notifier)
          .filterDocuments(type: DocumentType.invoice, searchQuery: '');

      // Empty string should be converted to null in filterDocuments
      verify(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: DocumentType.invoice,
            searchQuery: null,
          )).called(1);
    });

    test('filter by type only returns correct documents', () async {
      final receipt = _makeDoc('r1', DocumentType.receipt);
      final invoice = _makeDoc('i1', DocumentType.invoice);
      final container = makeContainer();
      addTearDown(container.dispose);

      when(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: DocumentType.receipt,
            searchQuery: null,
          )).thenAnswer((_) async => [receipt]);

      await container.read(documentNotifierProvider.future);

      await container
          .read(documentNotifierProvider.notifier)
          .filterDocuments(type: DocumentType.receipt);

      final state = container.read(documentNotifierProvider).value!;
      expect(state, contains(receipt));
      expect(state, isNot(contains(invoice)));
    });

    test('filter by searchQuery only passes null type', () async {
      final doc = _makeDoc('d1', DocumentType.other);
      final container = makeContainer();
      addTearDown(container.dispose);

      when(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: null,
            searchQuery: 'invoice',
          )).thenAnswer((_) async => [doc]);

      await container.read(documentNotifierProvider.future);

      await container
          .read(documentNotifierProvider.notifier)
          .filterDocuments(searchQuery: 'invoice');

      verify(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            type: null,
            searchQuery: 'invoice',
          )).called(1);
    });

    test('filterDocuments resets page to 0', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(documentNotifierProvider.future);

      // Call filterDocuments (any args)
      await container
          .read(documentNotifierProvider.notifier)
          .filterDocuments(searchQuery: 'test');

      // Offset should be 0 (page 0)
      verify(() => mockDb.getAllDocuments(
            limit: any(named: 'limit'),
            offset: 0,
            type: any(named: 'type'),
            searchQuery: any(named: 'searchQuery'),
          )).called(greaterThanOrEqualTo(1));
    });
  });
}
