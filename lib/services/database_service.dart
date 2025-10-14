import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/document.dart';
import '../models/user_settings.dart';
import '../models/audit_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Initialize encryption
      await _initializeEncryption();

      // Mobile/Desktop platforms
      final documentsDir = await getApplicationDocumentsDirectory();
      final path = join(documentsDir.path, 'privacy_documents.db');

      return await openDatabase(
        path,
        version: 3, // Increment to force recreation with correct schema
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.e('Failed to initialize database: $e');
      rethrow;
    }
  }

  Future<void> _initializeEncryption() async {
    try {
      // Get or create encryption key
      String? keyString = await _secureStorage.read(key: 'encryption_key');
      if (keyString == null) {
        final key = encrypt.Key.fromSecureRandom(32);
        keyString = key.base64;
        await _secureStorage.write(key: 'encryption_key', value: keyString);
      }

      final key = encrypt.Key.fromBase64(keyString);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _iv = encrypt.IV.fromSecureRandom(16);
    } catch (e) {
      _logger.e('Failed to initialize encryption: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create documents table
      await db.execute('''
        CREATE TABLE documents (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          image_path TEXT NOT NULL,
          extracted_text TEXT,
          type TEXT NOT NULL,
          scan_date INTEGER NOT NULL,
          tags TEXT,
          metadata TEXT,
          storage_provider TEXT NOT NULL,
          is_encrypted INTEGER NOT NULL DEFAULT 1,
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

      // Create search index table with FTS5 (if available)
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE search_index USING fts5(
            doc_id,
            title,
            extracted_text,
            tags,
            notes,
            content='documents',
            content_rowid='rowid'
          )
        ''');
        _logger.i('FTS5 search index created successfully');
      } catch (e) {
        _logger.w('FTS5 not available, creating fallback search table: $e');
        // Create a regular table for search fallback
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
        _logger.i('Fallback search table created');
      }

      // Create user settings table
      await db.execute('''
        CREATE TABLE user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create audit log table
      await db.execute('''
        CREATE TABLE audit_log (
          id TEXT PRIMARY KEY,
          action TEXT NOT NULL,
          resource_type TEXT NOT NULL,
          resource_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          details TEXT,
          location TEXT,
          device_info TEXT,
          is_success INTEGER NOT NULL,
          error_message TEXT
        )
      ''');

      // Create sync queue table
      await db.execute('''
        CREATE TABLE sync_queue (
          id TEXT PRIMARY KEY,
          action TEXT NOT NULL,
          resource_type TEXT NOT NULL,
          resource_id TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_retry_at INTEGER,
          status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      // Insert default settings
      final defaultSettings = UserSettings.defaultSettings();
      await _insertUserSettings(db, defaultSettings);

      _logger.i('Database created successfully');
    } catch (e) {
      _logger.e('Failed to create database: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    _logger.i('Database upgraded from version $oldVersion to $newVersion');

    if (oldVersion < 3) {
      // Drop and recreate search_index table with correct schema
      try {
        await db.execute('DROP TABLE IF EXISTS search_index');
        _logger.i('Dropped old search_index table');
      } catch (e) {
        _logger.w('Error dropping search_index table: $e');
      }

      // Recreate with correct schema
      try {
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
        _logger.i('Recreated search_index table with correct schema');
      } catch (e) {
        _logger.e('Error recreating search_index table: $e');
      }
    }
  }

  // Document operations
  Future<String> insertDocument(Document document) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Insert document
        await txn.insert('documents', _documentToMap(document));

        // Insert into search index
        await txn.insert('search_index', {
          'doc_id': document.id,
          'title': document.title,
          'extracted_text': document.extractedText,
          'tags': document.tags.join(' '),
          'notes': document.notes ?? '',
        });
      });

      // Log audit
      await _logAudit(
          AuditAction.create, 'document', document.id, 'Document created');

      _logger.i('Document inserted: ${document.id}');
      return document.id;
    } catch (e) {
      _logger.e('Failed to insert document: $e');
      rethrow;
    }
  }

  Future<Document?> getDocument(String id) async {
    final db = await database;
    try {
      final maps = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToDocument(maps.first);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get document: $e');
      rethrow;
    }
  }

  Future<List<Document>> getAllDocuments({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  }) async {
    final db = await database;
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (type != null) {
        whereClause += 'type = ?';
        whereArgs.add(type.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause +=
            'id IN (SELECT doc_id FROM search_index WHERE search_index MATCH ?)';
        whereArgs.add(searchQuery);
      }

      final maps = await db.query(
        'documents',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      _logger.e('Failed to get documents: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(Document document) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Update document
        await txn.update(
          'documents',
          _documentToMap(document),
          where: 'id = ?',
          whereArgs: [document.id],
        );

        // Update search index
        await txn.update(
          'search_index',
          {
            'title': document.title,
            'extracted_text': document.extractedText,
            'tags': document.tags.join(' '),
            'notes': document.notes ?? '',
          },
          where: 'doc_id = ?',
          whereArgs: [document.id],
        );
      });

      // Log audit
      await _logAudit(
          AuditAction.update, 'document', document.id, 'Document updated');

      _logger.i('Document updated: ${document.id}');
    } catch (e) {
      _logger.e('Failed to update document: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Delete from search index
        await txn.delete('search_index', where: 'doc_id = ?', whereArgs: [id]);

        // Delete document
        await txn.delete('documents', where: 'id = ?', whereArgs: [id]);
      });

      // Log audit
      await _logAudit(AuditAction.delete, 'document', id, 'Document deleted');

      _logger.i('Document deleted: $id');
    } catch (e) {
      _logger.e('Failed to delete document: $e');
      rethrow;
    }
  }

  // User settings operations
  Future<void> _insertUserSettings(Database db, UserSettings settings) async {
    final settingsMap = settings.toJson();
    for (final entry in settingsMap.entries) {
      await db.insert('user_settings', {
        'key': entry.key,
        'value': entry.value.toString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<UserSettings> getUserSettings() async {
    final db = await database;
    try {
      final maps = await db.query('user_settings');
      final settingsMap = <String, dynamic>{};

      for (final map in maps) {
        final key = map['key'] as String;
        final value = map['value'] as String;

        // Parse different data types
        if (value == 'true' || value == 'false') {
          settingsMap[key] = value == 'true';
        } else if (value.contains('.')) {
          settingsMap[key] = double.tryParse(value);
        } else {
          settingsMap[key] = int.tryParse(value) ?? value;
        }
      }

      return UserSettings.fromJson(settingsMap);
    } catch (e) {
      _logger.e('Failed to get user settings: $e');
      return UserSettings.defaultSettings();
    }
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final settingsMap = settings.toJson();
        for (final entry in settingsMap.entries) {
          await txn.insert(
            'user_settings',
            {
              'key': entry.key,
              'value': entry.value.toString(),
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      // Log audit
      await _logAudit(
          AuditAction.update, 'user_settings', 'global', 'Settings updated');

      _logger.i('User settings updated');
    } catch (e) {
      _logger.e('Failed to update user settings: $e');
      rethrow;
    }
  }

  // Audit log operations
  Future<void> _logAudit(AuditAction action, String resourceType,
      String resourceId, String? details) async {
    try {
      final auditLog = AuditLog.create(
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        userId: 'current_user', // TODO: Get actual user ID
        details: details,
        deviceInfo: Platform.operatingSystem,
      );

      final db = await database;
      await db.insert('audit_log', _auditLogToMap(auditLog));
    } catch (e) {
      _logger.e('Failed to log audit: $e');
    }
  }

  Future<List<AuditLog>> getAuditLogs({
    int? limit,
    int? offset,
    AuditAction? action,
    String? resourceType,
  }) async {
    final db = await database;
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (action != null) {
        whereClause += 'action = ?';
        whereArgs.add(action.name);
      }

      if (resourceType != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'resource_type = ?';
        whereArgs.add(resourceType);
      }

      final maps = await db.query(
        'audit_log',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => _mapToAuditLog(map)).toList();
    } catch (e) {
      _logger.e('Failed to get audit logs: $e');
      rethrow;
    }
  }

  // Search operations
  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    try {
      // Try FTS5 search first
      try {
        final maps = await db.rawQuery('''
          SELECT d.* FROM documents d
          JOIN search_index s ON d.id = s.doc_id
          WHERE search_index MATCH ?
          ORDER BY rank
        ''', [query]);
        return maps.map((map) => _mapToDocument(map)).toList();
      } catch (e) {
        _logger.w('FTS5 search failed, using fallback: $e');
        // Fallback to LIKE search
        final searchTerm = '%$query%';
        final maps = await db.rawQuery('''
          SELECT d.* FROM documents d
          JOIN search_index s ON d.id = s.doc_id
          WHERE s.title LIKE ? OR s.extracted_text LIKE ? OR s.tags LIKE ? OR s.notes LIKE ?
          ORDER BY d.scan_date DESC
        ''', [searchTerm, searchTerm, searchTerm, searchTerm]);
        return maps.map((map) => _mapToDocument(map)).toList();
      }
    } catch (e) {
      _logger.e('Failed to search documents: $e');
      rethrow;
    }
  }

  // Helper methods
  Map<String, dynamic> _documentToMap(Document document) {
    return {
      'id': document.id,
      'title': document.title,
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
    };
  }

  Document _mapToDocument(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      imagePath: map['image_path'],
      extractedText: map['extracted_text'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scan_date']),
      tags: (map['tags'] as String?)?.split(',') ?? [],
      metadata: {}, // TODO: Parse metadata JSON
      storageProvider: map['storage_provider'],
      isEncrypted: map['is_encrypted'] == 1,
      confidenceScore: map['confidence_score'],
      detectedLanguage: map['detected_language'],
      deviceInfo: map['device_info'],
      notes: map['notes'],
      location: map['location'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      cloudId: map['cloud_id'],
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_synced_at'])
          : null,
    );
  }

  Map<String, dynamic> _auditLogToMap(AuditLog auditLog) {
    return {
      'id': auditLog.id,
      'action': auditLog.action.name,
      'resource_type': auditLog.resourceType,
      'resource_id': auditLog.resourceId,
      'user_id': auditLog.userId,
      'timestamp': auditLog.timestamp.millisecondsSinceEpoch,
      'details': auditLog.details,
      'location': auditLog.location,
      'device_info': auditLog.deviceInfo,
      'is_success': auditLog.isSuccess ? 1 : 0,
      'error_message': auditLog.errorMessage,
    };
  }

  AuditLog _mapToAuditLog(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      action: AuditAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => AuditAction.read,
      ),
      resourceType: map['resource_type'],
      resourceId: map['resource_id'],
      userId: map['user_id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      details: map['details'],
      location: map['location'],
      deviceInfo: map['device_info'],
      isSuccess: map['is_success'] == 1,
      errorMessage: map['error_message'],
    );
  }

  // Encryption helpers
  String? encryptData(String data) {
    if (_encrypter == null || _iv == null) return data;
    try {
      return _encrypter!.encrypt(data, iv: _iv!).base64;
    } catch (e) {
      _logger.e('Failed to encrypt data: $e');
      return data;
    }
  }

  String? decryptData(String encryptedData) {
    if (_encrypter == null || _iv == null) return encryptedData;
    try {
      return _encrypter!
          .decrypt(encrypt.Encrypted.fromBase64(encryptedData), iv: _iv!);
    } catch (e) {
      _logger.e('Failed to decrypt data: $e');
      return encryptedData;
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
