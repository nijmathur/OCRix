import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ocrix/models/document.dart';

void main() {
  // Initialize FFI for testing (allows running on desktop/CI without device)
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Cleanup FFI after all tests
  tearDownAll(() async {
    // Close any remaining database connections
    // FFI cleanup is handled automatically
  });

  group('Database Image Storage Integration Tests', () {
    late Database testDatabase;

    setUp(() async {
      // Create an in-memory database for testing
      testDatabase = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onCreate: (db, version) async {
          // Create documents table matching the schema
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              image_data BLOB,
              image_format TEXT DEFAULT 'jpeg',
              image_size INTEGER,
              image_width INTEGER,
              image_height INTEGER,
              image_path TEXT,
              extracted_text TEXT,
              type TEXT NOT NULL,
              scan_date INTEGER NOT NULL,
              tags TEXT,
              metadata TEXT,
              storage_provider TEXT NOT NULL,
              is_encrypted INTEGER NOT NULL DEFAULT 0,
              confidence_score REAL NOT NULL,
              detected_language TEXT NOT NULL,
              device_info TEXT NOT NULL,
              notes TEXT,
              location TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_synced INTEGER NOT NULL DEFAULT 0,
              cloud_id TEXT,
              last_synced_at INTEGER
            )
          ''');

          // Create search_index table
          await db.execute('''
            CREATE TABLE search_index (
              doc_id TEXT PRIMARY KEY,
              title TEXT,
              extracted_text TEXT,
              tags TEXT,
              notes TEXT,
              FOREIGN KEY (doc_id) REFERENCES documents (id)
            )
          ''');
        },
      );
    });

    tearDown(() async {
      await testDatabase.close();
    });

    test('should store document with image data as BLOB', () async {
      // Create test image data (simulated JPEG bytes)
      final testImageData = Uint8List.fromList([
        // Minimal JPEG header
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
        // Some dummy data
        ...List.generate(100, (i) => i % 256),
      ]);

      // Create a document with image data
      final document = Document.create(
        title: 'Test Document with Image',
        imageData: testImageData,
        imageFormat: 'jpeg',
        imageSize: testImageData.length,
        imageWidth: 100,
        imageHeight: 100,
        extractedText: 'Sample extracted text',
        type: DocumentType.receipt,
        confidenceScore: 0.95,
        detectedLanguage: 'en',
        deviceInfo: 'test',
        isEncrypted: false,
      );

      // Insert document into database
      await testDatabase.transaction((txn) async {
        await txn.insert('documents', {
          'id': document.id,
          'title': document.title,
          'image_data': document.imageData,
          'image_format': document.imageFormat,
          'image_size': document.imageSize,
          'image_width': document.imageWidth,
          'image_height': document.imageHeight,
          'image_path': document.imagePath,
          'extracted_text': document.extractedText,
          'type': document.type.name,
          'scan_date': document.scanDate.millisecondsSinceEpoch,
          'tags': document.tags.join(','),
          'metadata': document.metadata.toString(),
          'storage_provider': document.storageProvider,
          'is_encrypted': document.isEncrypted ? 1 : 0,
          'confidence_score': document.confidenceScore,
          'detected_language': document.detectedLanguage,
          'device_info': document.deviceInfo,
          'notes': document.notes,
          'location': document.location,
          'created_at': document.createdAt.millisecondsSinceEpoch,
          'updated_at': document.updatedAt.millisecondsSinceEpoch,
          'is_synced': document.isSynced ? 1 : 0,
          'cloud_id': document.cloudId,
          'last_synced_at': document.lastSyncedAt?.millisecondsSinceEpoch,
        });

        await txn.insert('search_index', {
          'doc_id': document.id,
          'title': document.title,
          'extracted_text': document.extractedText,
          'tags': document.tags.join(' '),
          'notes': document.notes ?? '',
        });
      });

      // Retrieve document from database
      final maps = await testDatabase.query(
        'documents',
        where: 'id = ?',
        whereArgs: [document.id],
        limit: 1,
      );

      expect(maps.length, equals(1));
      final map = maps.first;

      // Verify image data was stored correctly
      expect(map['image_data'], isNotNull);
      final retrievedImageData = map['image_data'] as Uint8List;
      expect(retrievedImageData.length, equals(testImageData.length));
      expect(retrievedImageData, equals(testImageData));
      expect(map['image_format'], equals('jpeg'));
      expect(map['image_size'], equals(testImageData.length));
      expect(map['image_width'], equals(100));
      expect(map['image_height'], equals(100));
    });

    test('should handle document with both imageData and imagePath', () async {
      final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final document = Document.create(
        title: 'Document with both',
        imageData: testImageData,
        imagePath: '/path/to/original/image.jpg',
        imageFormat: 'jpeg',
        imageSize: testImageData.length,
        extractedText: 'Text',
        type: DocumentType.invoice,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );

      await testDatabase.insert('documents', {
        'id': document.id,
        'title': document.title,
        'image_data': document.imageData,
        'image_format': document.imageFormat,
        'image_size': document.imageSize,
        'image_path': document.imagePath,
        'extracted_text': document.extractedText,
        'type': document.type.name,
        'scan_date': document.scanDate.millisecondsSinceEpoch,
        'tags': document.tags.join(','),
        'metadata': document.metadata.toString(),
        'storage_provider': document.storageProvider,
        'is_encrypted': document.isEncrypted ? 1 : 0,
        'confidence_score': document.confidenceScore,
        'detected_language': document.detectedLanguage,
        'device_info': document.deviceInfo,
        'notes': document.notes,
        'location': document.location,
        'created_at': document.createdAt.millisecondsSinceEpoch,
        'updated_at': document.updatedAt.millisecondsSinceEpoch,
        'is_synced': document.isSynced ? 1 : 0,
        'cloud_id': document.cloudId,
        'last_synced_at': document.lastSyncedAt?.millisecondsSinceEpoch,
      });

      final maps = await testDatabase.query(
        'documents',
        where: 'id = ?',
        whereArgs: [document.id],
      );

      expect(maps.length, equals(1));
      final map = maps.first;
      expect(map['image_data'], isNotNull);
      expect(map['image_path'], equals('/path/to/original/image.jpg'));
    });

    test('should handle document without image data (backward compatibility)',
        () async {
      final document = Document.create(
        title: 'Document without image data',
        imagePath: '/path/to/image.jpg',
        extractedText: 'Text',
        type: DocumentType.receipt,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );

      await testDatabase.insert('documents', {
        'id': document.id,
        'title': document.title,
        'image_data': document.imageData,
        'image_format': document.imageFormat,
        'image_path': document.imagePath,
        'extracted_text': document.extractedText,
        'type': document.type.name,
        'scan_date': document.scanDate.millisecondsSinceEpoch,
        'tags': document.tags.join(','),
        'metadata': document.metadata.toString(),
        'storage_provider': document.storageProvider,
        'is_encrypted': document.isEncrypted ? 1 : 0,
        'confidence_score': document.confidenceScore,
        'detected_language': document.detectedLanguage,
        'device_info': document.deviceInfo,
        'notes': document.notes,
        'location': document.location,
        'created_at': document.createdAt.millisecondsSinceEpoch,
        'updated_at': document.updatedAt.millisecondsSinceEpoch,
        'is_synced': document.isSynced ? 1 : 0,
        'cloud_id': document.cloudId,
        'last_synced_at': document.lastSyncedAt?.millisecondsSinceEpoch,
      });

      final maps = await testDatabase.query(
        'documents',
        where: 'id = ?',
        whereArgs: [document.id],
      );

      expect(maps.length, equals(1));
      final map = maps.first;
      expect(map['image_data'], isNull);
      expect(map['image_path'], equals('/path/to/image.jpg'));
    });

    test('should update document image data', () async {
      final initialImageData = Uint8List.fromList([1, 2, 3]);
      final document = Document.create(
        title: 'Document to update',
        imageData: initialImageData,
        imageFormat: 'jpeg',
        imageSize: initialImageData.length,
        extractedText: 'Text',
        type: DocumentType.receipt,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );

      await testDatabase.insert('documents', {
        'id': document.id,
        'title': document.title,
        'image_data': document.imageData,
        'image_format': document.imageFormat,
        'image_size': document.imageSize,
        'image_width': document.imageWidth,
        'image_height': document.imageHeight,
        'extracted_text': document.extractedText,
        'type': document.type.name,
        'scan_date': document.scanDate.millisecondsSinceEpoch,
        'tags': document.tags.join(','),
        'metadata': document.metadata.toString(),
        'storage_provider': document.storageProvider,
        'is_encrypted': document.isEncrypted ? 1 : 0,
        'confidence_score': document.confidenceScore,
        'detected_language': document.detectedLanguage,
        'device_info': document.deviceInfo,
        'notes': document.notes,
        'location': document.location,
        'created_at': document.createdAt.millisecondsSinceEpoch,
        'updated_at': document.updatedAt.millisecondsSinceEpoch,
        'is_synced': document.isSynced ? 1 : 0,
        'cloud_id': document.cloudId,
        'last_synced_at': document.lastSyncedAt?.millisecondsSinceEpoch,
      });

      // Update with new image data
      final newImageData = Uint8List.fromList([4, 5, 6, 7, 8]);
      await testDatabase.update(
        'documents',
        {
          'image_data': newImageData,
          'image_size': newImageData.length,
          'image_width': 200,
          'image_height': 200,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [document.id],
      );

      final maps = await testDatabase.query(
        'documents',
        where: 'id = ?',
        whereArgs: [document.id],
      );

      expect(maps.length, equals(1));
      final map = maps.first;
      final retrievedImageData = map['image_data'] as Uint8List;
      expect(retrievedImageData, equals(newImageData));
      expect(map['image_size'], equals(newImageData.length));
      expect(map['image_width'], equals(200));
      expect(map['image_height'], equals(200));
    });

    test('should handle large image data', () async {
      final largeImageData = Uint8List.fromList(
        List.generate(1024 * 100, (i) => i % 256), // 100KB
      );

      final document = Document.create(
        title: 'Document with large image',
        imageData: largeImageData,
        imageFormat: 'jpeg',
        imageSize: largeImageData.length,
        imageWidth: 1920,
        imageHeight: 1080,
        extractedText: 'Text',
        type: DocumentType.receipt,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );

      await testDatabase.insert('documents', {
        'id': document.id,
        'title': document.title,
        'image_data': document.imageData,
        'image_format': document.imageFormat,
        'image_size': document.imageSize,
        'image_width': document.imageWidth,
        'image_height': document.imageHeight,
        'extracted_text': document.extractedText,
        'type': document.type.name,
        'scan_date': document.scanDate.millisecondsSinceEpoch,
        'tags': document.tags.join(','),
        'metadata': document.metadata.toString(),
        'storage_provider': document.storageProvider,
        'is_encrypted': document.isEncrypted ? 1 : 0,
        'confidence_score': document.confidenceScore,
        'detected_language': document.detectedLanguage,
        'device_info': document.deviceInfo,
        'notes': document.notes,
        'location': document.location,
        'created_at': document.createdAt.millisecondsSinceEpoch,
        'updated_at': document.updatedAt.millisecondsSinceEpoch,
        'is_synced': document.isSynced ? 1 : 0,
        'cloud_id': document.cloudId,
        'last_synced_at': document.lastSyncedAt?.millisecondsSinceEpoch,
      });

      final maps = await testDatabase.query(
        'documents',
        where: 'id = ?',
        whereArgs: [document.id],
      );

      expect(maps.length, equals(1));
      final map = maps.first;
      final retrievedImageData = map['image_data'] as Uint8List;
      expect(retrievedImageData.length, equals(largeImageData.length));
      expect(map['image_size'], equals(largeImageData.length));
      expect(map['image_width'], equals(1920));
      expect(map['image_height'], equals(1080));
    });
  });
}
