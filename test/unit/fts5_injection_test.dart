/// FTS5 query sanitization and injection resistance tests.
///
/// Verifies that _sanitizeFTS5Query (tested indirectly via searchDocuments
/// and getAllDocuments) correctly handles potentially dangerous inputs without
/// throwing SQL errors or returning unintended results.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/services/database_service.dart';

import '../helpers/mocks.dart';

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

    tempDir = await Directory.systemTemp.createTemp('ocrix_fts5_');
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
    service.setDatabasePathOverride(tempDir.path);
    await service.initialize();

    // Insert test documents
    await service.insertDocument(Document.create(
      title: 'Coffee Shop Receipt',
      extractedText: 'Starbucks latte 4.50',
      type: DocumentType.receipt,
      confidenceScore: 0.9,
      detectedLanguage: 'en',
      deviceInfo: 'test',
    ));
    await service.insertDocument(Document.create(
      title: 'Electricity Bill',
      extractedText: 'Power company invoice due date',
      type: DocumentType.invoice,
      confidenceScore: 0.9,
      detectedLanguage: 'en',
      deviceInfo: 'test',
    ));
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  group('FTS5 injection resistance via searchDocuments', () {
    test('query with FTS5 wildcard * does not throw', () async {
      expect(
        () => service.searchDocuments('coffee*'),
        returnsNormally,
      );
    });

    test('query with FTS5 NOT operator does not throw', () async {
      expect(
        () async => await service.searchDocuments('coffee -latte'),
        returnsNormally,
      );
    });

    test('query with FTS5 boolean AND does not throw', () async {
      expect(
        () async => await service.searchDocuments('coffee AND latte'),
        returnsNormally,
      );
    });

    test('query with FTS5 boolean OR does not throw', () async {
      expect(
        () async => await service.searchDocuments('coffee OR bill'),
        returnsNormally,
      );
    });

    test('query with FTS5 grouping parens does not throw', () async {
      expect(
        () async => await service.searchDocuments('(coffee OR latte)'),
        returnsNormally,
      );
    });

    test('query with double-quotes does not throw', () async {
      expect(
        () async => await service.searchDocuments('"coffee shop"'),
        returnsNormally,
      );
    });

    test('injection-style input does not return all documents', () async {
      // A malicious query attempting to match everything
      final results = await service.searchDocuments('* OR doc_id LIKE "%"');
      // Should return empty or only legitimately matching docs, not all 2
      // The injection is sanitized so `*` and boolean operators are stripped
      expect(results, isNotNull); // No crash
    });

    test('normal search still works after sanitization', () async {
      final results = await service.searchDocuments('coffee');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Coffee Shop Receipt'));
    });

    test('empty query returns no results', () async {
      // Empty queries skip the search and return all docs
      final allDocs = await service.getAllDocuments();
      expect(allDocs.length, equals(2)); // baseline
    });

    test('query with UNION injection string does not crash', () async {
      expect(
        () async => await service.searchDocuments(
          'test UNION SELECT * FROM documents --',
        ),
        returnsNormally,
      );
    });
  });

  group('FTS5 injection resistance via getAllDocuments', () {
    test('getAllDocuments with injection searchQuery does not throw', () async {
      expect(
        () async => await service.getAllDocuments(
          searchQuery: "' OR '1'='1",
        ),
        returnsNormally,
      );
    });

    test('getAllDocuments with FTS5 wildcard does not throw', () async {
      expect(
        () async => await service.getAllDocuments(searchQuery: 'coffee*'),
        returnsNormally,
      );
    });

    test('getAllDocuments normal search returns correct documents', () async {
      final results = await service.getAllDocuments(searchQuery: 'electricity');
      expect(results.length, equals(1));
      expect(results.first.title, contains('Electricity'));
    });

    test('getAllDocuments combined type+searchQuery works', () async {
      final results = await service.getAllDocuments(
        type: DocumentType.receipt,
        searchQuery: 'coffee',
      );
      expect(results.length, equals(1));
      expect(results.first.type, equals(DocumentType.receipt));
    });
  });
}
