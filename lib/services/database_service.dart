import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';
import '../models/user_settings.dart';
import '../models/audit_log.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/config/app_config.dart';
import '../core/exceptions/app_exceptions.dart';
import 'encryption_service.dart';

class DatabaseService extends BaseService implements IDatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Encryption service - will be refactored to use interface next
  // For now, use concrete class directly
  late final EncryptionService _encryptionServiceInstance = EncryptionService();

  // Dependency injection - can be set for testing
  IEncryptionService? _encryptionService;

  // For backward compatibility, allow setting encryption service
  // In production, this will be injected via Riverpod
  void setEncryptionService(IEncryptionService encryptionService) {
    _encryptionService = encryptionService;
  }

  // Get encryption service - uses concrete class for now
  // Will be refactored when EncryptionService implements IEncryptionService
  dynamic get encryptionService {
    if (_encryptionService != null) {
      return _encryptionService!;
    }
    // Temporary: use concrete class until EncryptionService implements interface
    return _EncryptionServiceAdapter(_encryptionServiceInstance);
  }

  static Database? _database;
  bool _isInitialized = false;

  @override
  String get serviceName => 'DatabaseService';

  /// Database getter for backward compatibility
  /// Use initialize() instead for new code
  Future<Database> get database async {
    if (!_isInitialized) {
      await initialize();
    }
    return _database!;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized && _database != null) {
      return;
    }

    try {
      logInfo('Initializing database...');

      // Initialize encryption service if needed
      if (!encryptionService.isInitialized) {
        await encryptionService.initialize();
      }

      // Mobile/Desktop platforms
      final documentsDir = await getApplicationDocumentsDirectory();
      final path = join(documentsDir.path, AppConfig.databaseName);

      _database = await openDatabase(
        path,
        version: AppConfig.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _isInitialized = true;
      logInfo('Database initialized successfully');
    } catch (e) {
      logError('Failed to initialize database', e);
      throw DatabaseException(
        'Failed to initialize database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create documents table
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
        logInfo('FTS5 search index created successfully');
      } catch (e) {
        logWarning('FTS5 not available, creating fallback search table: $e');
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
        logInfo('Fallback search table created');
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

      logInfo('Database created successfully');
    } catch (e) {
      logError('Failed to create database', e);
      throw DatabaseException(
        'Failed to create database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    logInfo('Database upgraded from version $oldVersion to $newVersion');

    if (oldVersion < 3) {
      // Drop and recreate search_index table with correct schema
      try {
        await db.execute('DROP TABLE IF EXISTS search_index');
        logInfo('Dropped old search_index table');
      } catch (e) {
        logWarning('Error dropping search_index table: $e');
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
        logInfo('Recreated search_index table with correct schema');
      } catch (e) {
        logError('Error recreating search_index table', e);
      }
    }

    if (oldVersion < 4) {
      // Add image BLOB columns to documents table
      try {
        await db.execute('ALTER TABLE documents ADD COLUMN image_data BLOB');
        await db.execute(
            'ALTER TABLE documents ADD COLUMN image_format TEXT DEFAULT "jpeg"');
        await db.execute('ALTER TABLE documents ADD COLUMN image_size INTEGER');
        await db
            .execute('ALTER TABLE documents ADD COLUMN image_width INTEGER');
        await db
            .execute('ALTER TABLE documents ADD COLUMN image_height INTEGER');
        logInfo('Added image BLOB columns to documents table');
      } catch (e) {
        logError('Error adding image BLOB columns', e);
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

      logInfo('Document inserted: ${document.id}');
      return document.id;
    } catch (e) {
      logError('Failed to insert document', e);
      throw DatabaseException(
        'Failed to insert document: ${e.toString()}',
        originalError: e,
      );
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
      logError('Failed to get document', e);
      throw DatabaseException(
        'Failed to get document: ${e.toString()}',
        originalError: e,
      );
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
      logError('Failed to get documents', e);
      throw DatabaseException(
        'Failed to get documents: ${e.toString()}',
        originalError: e,
      );
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

      logInfo('Document updated: ${document.id}');
    } catch (e) {
      logError('Failed to update document', e);
      throw DatabaseException(
        'Failed to update document: ${e.toString()}',
        originalError: e,
      );
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

      logInfo('Document deleted: $id');
    } catch (e) {
      logError('Failed to delete document', e);
      throw DatabaseException(
        'Failed to delete document: ${e.toString()}',
        originalError: e,
      );
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
      logError('Failed to get user settings', e);
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

      logInfo('User settings updated');
    } catch (e) {
      logError('Failed to update user settings', e);
      throw DatabaseException(
        'Failed to update user settings: ${e.toString()}',
        originalError: e,
      );
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
      logError('Failed to log audit', e);
      // Don't throw - audit logging failures shouldn't break the app
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
      logError('Failed to get audit logs', e);
      throw DatabaseException(
        'Failed to get audit logs: ${e.toString()}',
        originalError: e,
      );
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
        logWarning('FTS5 search failed, using fallback: $e');
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
      logError('Failed to search documents', e);
      throw DatabaseException(
        'Failed to search documents: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // Helper methods
  Map<String, dynamic> _documentToMap(Document document) {
    return {
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
    };
  }

  Document _mapToDocument(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      imageData: map['image_data'] as Uint8List?,
      imageFormat: map['image_format'] ?? 'jpeg',
      imageSize: map['image_size'] as int?,
      imageWidth: map['image_width'] as int?,
      imageHeight: map['image_height'] as int?,
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

  // Encryption helpers - now use EncryptionService
  // These methods are kept for backward compatibility but delegate to EncryptionService
  Future<String?> encryptData(String data) async {
    try {
      if (!encryptionService.isInitialized) {
        await encryptionService.initialize();
      }
      return await encryptionService.encryptText(data);
    } catch (e) {
      logError('Failed to encrypt data', e);
      return data; // Return original on failure for backward compatibility
    }
  }

  Future<String?> decryptData(String encryptedData) async {
    try {
      if (!encryptionService.isInitialized) {
        await encryptionService.initialize();
      }
      return await encryptionService.decryptText(encryptedData);
    } catch (e) {
      logError('Failed to decrypt data', e);
      return encryptedData; // Return original on failure for backward compatibility
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

// Temporary adapter until EncryptionService implements IEncryptionService
class _EncryptionServiceAdapter implements IEncryptionService {
  final EncryptionService _service;

  _EncryptionServiceAdapter(this._service);

  @override
  bool get isInitialized => _service.isInitialized;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<String> encryptText(String text) => _service.encryptText(text);

  @override
  Future<String> decryptText(String encryptedText) =>
      _service.decryptText(encryptedText);

  @override
  Future<String> encryptFile(String filePath) => _service.encryptFile(filePath);

  @override
  Future<String> decryptFile(String encryptedFilePath) =>
      _service.decryptFile(encryptedFilePath);

  @override
  Future<List<int>> encryptBytes(List<int> bytes) =>
      _service.encryptBytes(Uint8List.fromList(bytes)).then((b) => b.toList());

  @override
  Future<List<int>> decryptBytes(List<int> encryptedBytes) => _service
      .decryptBytes(Uint8List.fromList(encryptedBytes))
      .then((b) => b.toList());

  @override
  Future<bool> isBiometricAvailable() => _service.isBiometricAvailable();

  @override
  Future<bool> authenticateWithBiometrics({String? reason}) =>
      _service.authenticateWithBiometrics();

  @override
  Future<void> changeEncryptionKey() => _service.changeEncryptionKey();

  @override
  Future<void> clearEncryptionKey() => _service.clearEncryptionKey();

  @override
  Future<Map<String, dynamic>> getEncryptionInfo() =>
      _service.getEncryptionInfo();
}
