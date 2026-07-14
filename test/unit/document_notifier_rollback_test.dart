import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/models/audit_log.dart';
import 'package:ocrix/core/models/audit_log_level.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/providers/audit_provider.dart';
import 'package:ocrix/providers/document_provider.dart';
import 'package:ocrix/providers/troubleshooting_logger_provider.dart';

import '../helpers/mocks.dart';

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
  late MockTroubleshootingLogger mockLogger;
  late MockAuditDatabaseService mockAuditDb;

  setUpAll(() {
    registerFallbackValue(_makeDoc('fallback'));
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

    // Stub logger no-ops
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

    // Stub audit DB no-ops
    when(() => mockAuditDb.initialize()).thenAnswer((_) async {});
    when(() => mockAuditDb.getLastEntry()).thenAnswer((_) async => null);
    when(() => mockAuditDb.insertAuditEntry(any())).thenAnswer((_) async => 'id');
  });

  ProviderContainer createContainer(List<Document> initial) {
    when(() => mockDb.getAllDocuments(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          type: any(named: 'type'),
          searchQuery: any(named: 'searchQuery'),
        )).thenAnswer((_) async => initial);

    return ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDb),
        troubleshootingLoggerProvider.overrideWithValue(mockLogger),
        auditDatabaseServiceProvider.overrideWithValue(mockAuditDb),
      ],
    );
  }

  group('DocumentNotifier optimistic rollback', () {
    test('updateDocument rolls back state on DB error', () async {
      final doc = _makeDoc('d1');
      final container = createContainer([doc]);
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(documentNotifierProvider.future);
      final stateBefore = container.read(documentNotifierProvider).value!;
      expect(stateBefore.length, 1);

      // DB update fails
      when(() => mockDb.updateDocument(any())).thenThrow(Exception('DB error'));

      await container
          .read(documentNotifierProvider.notifier)
          .updateDocument(doc.copyWith(title: 'Changed'));

      final stateAfter = container.read(documentNotifierProvider).value!;
      expect(stateAfter, stateBefore);
      expect(stateAfter.first.title, 'Test d1');
    });

    test('deleteDocument rolls back state on DB error', () async {
      final doc = _makeDoc('d2');
      final container = createContainer([doc]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);
      final stateBefore = container.read(documentNotifierProvider).value!;
      expect(stateBefore.length, 1);

      when(() => mockDb.deleteDocument(any())).thenThrow(Exception('DB error'));

      await container
          .read(documentNotifierProvider.notifier)
          .deleteDocument('d2');

      final stateAfter = container.read(documentNotifierProvider).value!;
      expect(stateAfter, stateBefore);
    });

    test('updateDocument applies state optimistically on success', () async {
      final doc = _makeDoc('d3');
      final container = createContainer([doc]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      when(() => mockDb.updateDocument(any())).thenAnswer((_) async {});

      final updated = doc.copyWith(title: 'Updated');
      await container
          .read(documentNotifierProvider.notifier)
          .updateDocument(updated);

      final state = container.read(documentNotifierProvider).value!;
      expect(state.first.title, 'Updated');
    });

    test('deleteDocument removes document from state on success', () async {
      final doc = _makeDoc('d4');
      final container = createContainer([doc]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);
      when(() => mockDb.deleteDocument(any())).thenAnswer((_) async {});

      await container
          .read(documentNotifierProvider.notifier)
          .deleteDocument('d4');

      final state = container.read(documentNotifierProvider).value!;
      expect(state.isEmpty, isTrue);
    });
  });
}
