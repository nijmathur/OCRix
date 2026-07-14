/// DocumentPage CRUD operation tests.
///
/// Verifies that DatabaseService correctly handles:
/// 1. saveDocumentPage: persists a page linked to a document
/// 2. getDocumentPages: retrieves all pages for a document in order
/// 3. getDocumentPage: retrieves a specific page by page number
/// 4. deleteDocumentPage: removes a single page by ID
/// 5. Cascade behavior when multiple pages belong to the same document
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/models/document_page.dart';
import 'package:ocrix/services/database_service.dart';

import '../helpers/mocks.dart';

void main() {
  late DatabaseService service;
  late MockEncryptionService mockEncryption;
  late Directory tempDir;
  late String docId;

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
      (inv) async => (inv.positionalArguments[0] as String).replaceFirst('enc:', ''),
    );

    tempDir = await Directory.systemTemp.createTemp('ocrix_pages_');
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
    service.setDatabasePathOverride(tempDir.path);
    await service.initialize();

    // Insert parent document for FK requirement
    final doc = Document.create(
      title: 'Multi-page Document',
      extractedText: 'combined text',
      type: DocumentType.other,
      confidenceScore: 0.9,
      detectedLanguage: 'en',
      deviceInfo: 'test',
      isMultiPage: true,
      pageCount: 3,
    );
    docId = await service.insertDocument(doc);
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  DocumentPage _makePage(int pageNumber, {String? id}) {
    final page = DocumentPage.create(
      documentId: docId,
      pageNumber: pageNumber,
      imageData: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, pageNumber]),
      thumbnailData: Uint8List.fromList([0x89, 0x50, pageNumber]),
      extractedText: 'Page $pageNumber extracted content',
      confidenceScore: 0.85 + pageNumber * 0.01,
    );
    return id != null ? page.copyWith(id: id) : page;
  }

  group('saveDocumentPage', () {
    test('saves a page and it can be retrieved', () async {
      final page = _makePage(1);
      await service.saveDocumentPage(page);

      final pages = await service.getDocumentPages(docId);
      expect(pages.length, equals(1));
      expect(pages.first.pageNumber, equals(1));
    });

    test('saves page with correct extracted text', () async {
      final page = _makePage(2);
      await service.saveDocumentPage(page);

      final pages = await service.getDocumentPages(docId);
      expect(pages.first.extractedText, equals('Page 2 extracted content'));
    });

    test('saves page with correct confidence score', () async {
      final page = _makePage(1);
      await service.saveDocumentPage(page);

      final pages = await service.getDocumentPages(docId);
      expect(pages.first.confidenceScore, closeTo(0.86, 0.001));
    });
  });

  group('getDocumentPages', () {
    test('returns empty list when no pages exist', () async {
      final pages = await service.getDocumentPages(docId);
      expect(pages, isEmpty);
    });

    test('returns all pages in order', () async {
      await service.saveDocumentPage(_makePage(3));
      await service.saveDocumentPage(_makePage(1));
      await service.saveDocumentPage(_makePage(2));

      final pages = await service.getDocumentPages(docId);
      expect(pages.length, equals(3));
      // Pages should be ordered by page_number
      expect(pages[0].pageNumber, equals(1));
      expect(pages[1].pageNumber, equals(2));
      expect(pages[2].pageNumber, equals(3));
    });

    test('returns only pages for the specified document', () async {
      // Insert a second document and its pages
      final doc2 = Document.create(
        title: 'Other Doc',
        extractedText: 'other',
        type: DocumentType.other,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );
      final doc2Id = await service.insertDocument(doc2);

      await service.saveDocumentPage(_makePage(1)); // belongs to docId
      await service.saveDocumentPage(DocumentPage.create(
        documentId: doc2Id,
        pageNumber: 1,
        extractedText: 'other doc page',
        confidenceScore: 0.9,
      ));

      final pagesForDoc1 = await service.getDocumentPages(docId);
      expect(pagesForDoc1.length, equals(1));
      expect(pagesForDoc1.first.documentId, equals(docId));
    });
  });

  group('getDocumentPage', () {
    test('returns correct page by page number', () async {
      await service.saveDocumentPage(_makePage(1));
      await service.saveDocumentPage(_makePage(2));

      final page = await service.getDocumentPage(docId, 2);
      expect(page, isNotNull);
      expect(page!.pageNumber, equals(2));
      expect(page.extractedText, equals('Page 2 extracted content'));
    });

    test('returns null for non-existent page number', () async {
      await service.saveDocumentPage(_makePage(1));

      final page = await service.getDocumentPage(docId, 99);
      expect(page, isNull);
    });

    test('returns null for non-existent document', () async {
      final page = await service.getDocumentPage('ghost-doc', 1);
      expect(page, isNull);
    });
  });

  group('deleteDocumentPage', () {
    test('removes a specific page by ID', () async {
      final page1 = _makePage(1);
      final page2 = _makePage(2);
      await service.saveDocumentPage(page1);
      await service.saveDocumentPage(page2);

      await service.deleteDocumentPage(page1.id);

      final pages = await service.getDocumentPages(docId);
      expect(pages.length, equals(1));
      expect(pages.first.pageNumber, equals(2));
    });

    test('does not affect other pages', () async {
      final page1 = _makePage(1);
      final page2 = _makePage(2);
      final page3 = _makePage(3);
      await service.saveDocumentPage(page1);
      await service.saveDocumentPage(page2);
      await service.saveDocumentPage(page3);

      await service.deleteDocumentPage(page2.id);

      final pages = await service.getDocumentPages(docId);
      expect(pages.map((p) => p.pageNumber).toList(), equals([1, 3]));
    });

    test('does not throw when deleting non-existent page', () async {
      await expectLater(
        () => service.deleteDocumentPage('ghost-page-id'),
        returnsNormally,
      );
    });
  });

  group('DocumentPage data integrity', () {
    test('image data is preserved through save and load', () async {
      final imageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final page = DocumentPage.create(
        documentId: docId,
        pageNumber: 1,
        imageData: imageBytes,
        extractedText: 'text',
        confidenceScore: 0.9,
      );
      await service.saveDocumentPage(page);

      final loaded = await service.getDocumentPage(docId, 1);
      expect(loaded, isNotNull);
      expect(loaded!.imageData, equals(imageBytes));
    });

    test('page documentId matches parent document', () async {
      await service.saveDocumentPage(_makePage(1));

      final pages = await service.getDocumentPages(docId);
      expect(pages.first.documentId, equals(docId));
    });
  });
}
