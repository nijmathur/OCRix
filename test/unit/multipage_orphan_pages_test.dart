/// Multi-page document scan rollback tests.
///
/// Verifies that when saveDocumentPage fails mid-loop during
/// scanMultiPageDocument, the state is rolled back to its pre-scan value,
/// preventing the UI from showing a document that was only partially saved.
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/core/models/audit_log_level.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/models/audit_log.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/models/document_page.dart';
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

DocumentPage _makePage(int number) => DocumentPage.create(
      documentId: '',
      pageNumber: number,
      imageData: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]), // minimal JPEG header
      extractedText: 'Page $number text',
      confidenceScore: 0.9,
    );

void main() {
  late MockDatabaseService mockDb;
  late MockTroubleshootingLogger mockLogger;
  late MockAuditDatabaseService mockAuditDb;
  late MockOCRService mockOcr;

  setUpAll(() {
    registerFallbackValue(_makeDoc('fallback'));
    registerFallbackValue(_makePage(0));
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
    mockOcr = MockOCRService();

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

    // OCR categorization returns 'other'
    when(() => mockOcr.categorizeDocument(any()))
        .thenAnswer((_) async => DocumentType.other);
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
        ocrServiceProvider.overrideWithValue(mockOcr),
        troubleshootingLoggerProvider.overrideWithValue(mockLogger),
        auditDatabaseServiceProvider.overrideWithValue(mockAuditDb),
      ],
    );
  }

  group('scanMultiPageDocument page-save failure', () {
    test('rolls back state when first saveDocumentPage throws', () async {
      final existing = _makeDoc('existing');
      final container = createContainer([existing]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);
      final stateBefore = container.read(documentNotifierProvider).value!;

      // insertDocument succeeds
      when(() => mockDb.insertDocument(any())).thenAnswer((_) async => 'new_id');
      // saveDocumentPage always throws
      when(() => mockDb.saveDocumentPage(any()))
          .thenThrow(Exception('page save failed'));

      final pages = [_makePage(1), _makePage(2)];
      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanMultiPageDocument(pages: pages),
        throwsException,
      );

      final stateAfter = container.read(documentNotifierProvider).value!;
      expect(stateAfter, equals(stateBefore));
      expect(stateAfter.length, equals(1));
    });

    test('rolls back state when second saveDocumentPage throws', () async {
      final existing = _makeDoc('existing');
      final container = createContainer([existing]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);
      final stateBefore = container.read(documentNotifierProvider).value!;

      when(() => mockDb.insertDocument(any())).thenAnswer((_) async => 'new_id');

      var pageSaveCalls = 0;
      when(() => mockDb.saveDocumentPage(any())).thenAnswer((_) async {
        pageSaveCalls++;
        if (pageSaveCalls > 1) {
          throw Exception('disk full');
        }
      });

      final pages = [_makePage(1), _makePage(2), _makePage(3)];
      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanMultiPageDocument(pages: pages),
        throwsException,
      );

      final stateAfter = container.read(documentNotifierProvider).value!;
      expect(stateAfter, equals(stateBefore));
    });

    test('does not add new document to state on rollback', () async {
      final container = createContainer([]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      when(() => mockDb.insertDocument(any())).thenAnswer((_) async => 'new_id');
      when(() => mockDb.saveDocumentPage(any()))
          .thenThrow(Exception('save failed'));

      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanMultiPageDocument(pages: [_makePage(1)]),
        throwsException,
      );

      final state = container.read(documentNotifierProvider).value!;
      expect(state, isEmpty);
    });

    test('state is not loading after rollback', () async {
      final container = createContainer([]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      when(() => mockDb.insertDocument(any())).thenAnswer((_) async => 'new_id');
      when(() => mockDb.saveDocumentPage(any()))
          .thenThrow(Exception('io error'));

      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanMultiPageDocument(pages: [_makePage(1), _makePage(2)]),
        throwsException,
      );

      expect(container.read(documentNotifierProvider).isLoading, isFalse);
    });

    test('empty pages list throws and state remains unchanged', () async {
      final existing = _makeDoc('d1');
      final container = createContainer([existing]);
      addTearDown(container.dispose);

      await container.read(documentNotifierProvider.future);

      await expectLater(
        () => container
            .read(documentNotifierProvider.notifier)
            .scanMultiPageDocument(pages: []),
        throwsException,
      );

      final state = container.read(documentNotifierProvider).value!;
      expect(state, equals([existing]));
    });
  });
}
