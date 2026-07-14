/// DocumentNotifier.scanDocument rollback tests.
///
/// Verifies that when insertDocument (or any earlier step) fails during
/// scanDocument, the state is restored to what it was before the scan started
/// (optimistic rollback pattern).
library;

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

  group('scanDocument rollback', () {
    test('state rolls back when image file does not exist', () async {
      final doc = _makeDoc('d1');
      final container = createContainer([doc]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);
      final stateBefore = container.read(documentNotifierProvider);
      expect(stateBefore.value, [doc]);

      // Attempt scan with non-existent file path
      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanDocument(imagePath: '/no/such/file.jpg'),
        throwsException,
      );

      final stateAfter = container.read(documentNotifierProvider);
      // State should be rolled back to the pre-scan loaded state
      expect(stateAfter.value, equals([doc]));
    });

    test('state has the original documents after rollback (not loading)', () async {
      final docs = [_makeDoc('a'), _makeDoc('b')];
      final container = createContainer(docs);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanDocument(imagePath: '/does/not/exist.png'),
        throwsException,
      );

      final state = container.read(documentNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.value?.length, equals(2));
    });

    test('state rolls back when initial state was empty list', () async {
      final container = createContainer([]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanDocument(imagePath: '/nonexistent.jpg'),
        throwsException,
      );

      final state = container.read(documentNotifierProvider);
      expect(state.value, isEmpty);
    });
  });
}
