/// Search index atomicity tests.
///
/// Verifies that insertDocument wraps the documents table insert and the
/// search_index insert in a single transaction, so that:
/// 1. After a successful insert, both tables contain the document
/// 2. A failed insert (e.g., duplicate ID) leaves both tables unchanged
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
import 'package:ocrix/core/exceptions/app_exceptions.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/services/database_service.dart';

import '../helpers/mocks.dart';

Document _makeDoc({String? id}) {
  final doc = Document.create(
    title: 'Test Doc',
    extractedText: 'some text for search',
    type: DocumentType.other,
    confidenceScore: 0.9,
    detectedLanguage: 'en',
    deviceInfo: 'test',
  );
  return id != null ? doc.copyWith(id: id) : doc;
}

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

    tempDir = await Directory.systemTemp.createTemp('ocrix_atomicity_');
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
    service.setDatabasePathOverride(tempDir.path);
    await service.initialize();
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> countDocuments() async {
    final db = await service.database;
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM documents');
    return rows.first['c'] as int;
  }

  Future<int> countSearchIndex() async {
    final db = await service.database;
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM search_index');
    return rows.first['c'] as int;
  }

  group('Successful insert atomicity', () {
    test('insertDocument adds entry to both documents and search_index', () async {
      final doc = _makeDoc();
      await service.insertDocument(doc);

      expect(await countDocuments(), equals(1));
      expect(await countSearchIndex(), equals(1));
    });

    test('search_index entry has correct doc_id', () async {
      final doc = _makeDoc(id: 'custom-id-123');
      await service.insertDocument(doc);

      final db = await service.database;
      final rows = await db.rawQuery(
        'SELECT doc_id FROM search_index WHERE doc_id = ?',
        ['custom-id-123'],
      );
      expect(rows.length, equals(1));
    });

    test('search_index entry has correct title and extracted_text', () async {
      final doc = Document.create(
        title: 'My Invoice',
        extractedText: 'invoice payment due',
        type: DocumentType.invoice,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );
      await service.insertDocument(doc);

      final db = await service.database;
      final rows = await db.rawQuery(
        'SELECT title, extracted_text FROM search_index WHERE doc_id = ?',
        [doc.id],
      );
      expect(rows.first['title'], equals('My Invoice'));
      expect(rows.first['extracted_text'], equals('invoice payment due'));
    });

    test('multiple inserts each create matching entries in both tables', () async {
      for (var i = 0; i < 3; i++) {
        await service.insertDocument(_makeDoc(id: 'doc-$i'));
      }
      expect(await countDocuments(), equals(3));
      expect(await countSearchIndex(), equals(3));
    });
  });

  group('Failed insert atomicity (transaction rollback)', () {
    test('duplicate document ID throws DatabaseException', () async {
      final doc = _makeDoc(id: 'dup-id');
      await service.insertDocument(doc);

      await expectLater(
        () => service.insertDocument(doc.copyWith(title: 'Duplicate')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('failed insert leaves document count unchanged', () async {
      final doc = _makeDoc(id: 'dup-id-2');
      await service.insertDocument(doc);
      final countBefore = await countDocuments();

      try {
        await service.insertDocument(doc.copyWith(title: 'Dup'));
      } catch (_) {}

      expect(await countDocuments(), equals(countBefore));
    });

    test('tables remain consistent after failed insert', () async {
      // Insert doc1 successfully
      final doc1 = _makeDoc(id: 'atomic-1');
      await service.insertDocument(doc1);

      // Attempt duplicate (fails)
      try {
        await service.insertDocument(doc1.copyWith(title: 'Duplicate of 1'));
      } catch (_) {}

      // Both tables should still have exactly 1 entry for atomic-1
      final db = await service.database;
      final docRows = await db.query('documents', where: 'id = ?', whereArgs: ['atomic-1']);
      final searchRows = await db.rawQuery(
        'SELECT doc_id FROM search_index WHERE doc_id = ?',
        ['atomic-1'],
      );

      expect(docRows.length, equals(1));
      expect(searchRows.length, equals(1));
    });
  });
}
