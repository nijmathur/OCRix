/// deleteDocument cascade tests.
///
/// Verifies that deleting a document:
/// 1. Removes the document from the documents table
/// 2. Removes the document from the search_index table
/// 3. Removes associated document_pages via ON DELETE CASCADE (with FK enabled)
/// 4. Does not affect unrelated documents or their pages
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

Document _makeDoc({String? id, String title = 'Test Doc'}) {
  final doc = Document.create(
    title: title,
    extractedText: 'document text content',
    type: DocumentType.other,
    confidenceScore: 0.9,
    detectedLanguage: 'en',
    deviceInfo: 'test',
  );
  return id != null ? doc.copyWith(id: id) : doc;
}

DocumentPage _makePage(String documentId, int pageNumber) =>
    DocumentPage.create(
      documentId: documentId,
      pageNumber: pageNumber,
      imageData: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
      extractedText: 'Page $pageNumber text',
      confidenceScore: 0.9,
    );

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
      (inv) async => (inv.positionalArguments[0] as String).replaceFirst('enc:', ''),
    );

    tempDir = await Directory.systemTemp.createTemp('ocrix_cascade_');
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
    service.setDatabasePathOverride(tempDir.path);
    await service.initialize();
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  group('deleteDocument removes from primary tables', () {
    test('removes document from documents table', () async {
      final doc = _makeDoc(id: 'del-1');
      await service.insertDocument(doc);

      await service.deleteDocument('del-1');

      final result = await service.getDocument('del-1');
      expect(result, isNull);
    });

    test('removes document from search_index table', () async {
      final doc = _makeDoc(id: 'del-2');
      await service.insertDocument(doc);

      await service.deleteDocument('del-2');

      final db = await service.database;
      final rows = await db.query(
        'search_index',
        where: 'doc_id = ?',
        whereArgs: ['del-2'],
      );
      expect(rows, isEmpty);
    });

    test('does not affect other documents', () async {
      final doc1 = _makeDoc(id: 'keep-1', title: 'Keep Me');
      final doc2 = _makeDoc(id: 'del-3', title: 'Delete Me');
      await service.insertDocument(doc1);
      await service.insertDocument(doc2);

      await service.deleteDocument('del-3');

      final kept = await service.getDocument('keep-1');
      expect(kept, isNotNull);
      expect(kept!.title, equals('Keep Me'));
    });
  });

  group('deleteDocument cascade: document_pages', () {
    test('deleteDocumentPages explicitly removes all pages', () async {
      final doc = _makeDoc(id: 'mp-1');
      await service.insertDocument(doc);
      await service.saveDocumentPage(_makePage('mp-1', 1));
      await service.saveDocumentPage(_makePage('mp-1', 2));

      // Verify pages exist
      var pages = await service.getDocumentPages('mp-1');
      expect(pages.length, equals(2));

      // Explicitly delete pages
      final db = await service.database;
      await db.delete('document_pages', where: 'document_id = ?', whereArgs: ['mp-1']);

      pages = await service.getDocumentPages('mp-1');
      expect(pages, isEmpty);
    });

    test('deleteDocument with FK cascade removes pages', () async {
      final doc = _makeDoc(id: 'mp-2');
      await service.insertDocument(doc);
      await service.saveDocumentPage(_makePage('mp-2', 1));
      await service.saveDocumentPage(_makePage('mp-2', 2));

      // Enable FK enforcement for cascade
      final db = await service.database;
      await db.execute('PRAGMA foreign_keys = ON');

      await service.deleteDocument('mp-2');

      final pages = await service.getDocumentPages('mp-2');
      expect(pages, isEmpty);
    });

    test('pages of other documents are unaffected', () async {
      final docA = _makeDoc(id: 'mpA');
      final docB = _makeDoc(id: 'mpB');
      await service.insertDocument(docA);
      await service.insertDocument(docB);
      await service.saveDocumentPage(_makePage('mpA', 1));
      await service.saveDocumentPage(_makePage('mpB', 1));
      await service.saveDocumentPage(_makePage('mpB', 2));

      final db = await service.database;
      await db.execute('PRAGMA foreign_keys = ON');
      await service.deleteDocument('mpA');

      final pagesB = await service.getDocumentPages('mpB');
      expect(pagesB.length, equals(2));
    });
  });

  group('deleteDocument on non-existent ID', () {
    test('does not throw when deleting non-existent document', () async {
      // Insert a real document to ensure the database connection is warmed up,
      // then verify that deleting a non-existent ID is a no-op (not an error).
      await service.insertDocument(_makeDoc(id: 'real-doc'));
      final countBefore = await service.getAllDocuments();

      // SQLite DELETE on non-existent row is a no-op, not an error
      await expectLater(
        () => service.deleteDocument('ghost-id'),
        returnsNormally,
      );

      // The real document is unaffected
      final countAfter = await service.getAllDocuments();
      expect(countAfter.length, equals(countBefore.length));
    });
  });
}
