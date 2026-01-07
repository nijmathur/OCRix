import 'dart:typed_data';
import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';
import '../models/document_page.dart';
import '../models/document_summary.dart';
import '../models/user_settings.dart';
import '../models/audit_log.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/config/app_config.dart';
import '../core/exceptions/app_exceptions.dart';
import '../services/audit_logging_service.dart';
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

  // Audit logging service (optional - for COMPULSORY level logging)
  AuditLoggingService? _auditLoggingService;

  String? _databasePathOverride;

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

  // Set audit logging service for COMPULSORY level logging
  void setAuditLoggingService(AuditLoggingService? auditLoggingService) {
    _auditLoggingService = auditLoggingService;
  }

  /// Set custom database path (useful for testing environments without path_provider)
  void setDatabasePathOverride(String path) {
    _databasePathOverride = path;
  }

  /// Set current user ID for SQLite triggers
  /// Triggers use this to identify the user performing database operations
  Future<void> setCurrentUserIdForTriggers(String userId) async {
    try {
      final db = await database;
      await db.insert('user_settings', {
        'key': 'current_user_id',
        'value': userId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logError('Failed to set current user ID for triggers', e);
      // Don't throw - this is not critical
    }
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
      final documentsPath =
          _databasePathOverride ??
          (await getApplicationDocumentsDirectory()).path;
      final path = join(documentsPath, AppConfig.databaseName);

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
          thumbnail_data BLOB,
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
          last_synced_at INTEGER,
          is_multi_page INTEGER NOT NULL DEFAULT 0,
          page_count INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Create document_pages table for multi-page document support
      await db.execute('''
        CREATE TABLE document_pages (
          id TEXT PRIMARY KEY,
          document_id TEXT NOT NULL,
          page_number INTEGER NOT NULL,
          image_data BLOB,
          thumbnail_data BLOB,
          image_format TEXT DEFAULT 'jpeg',
          image_size INTEGER,
          image_width INTEGER,
          image_height INTEGER,
          extracted_text TEXT NOT NULL,
          confidence_score REAL NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
        )
      ''');

      // Create index for efficient page lookup
      await db.execute('''
        CREATE INDEX idx_document_pages_doc_id ON document_pages(document_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_document_pages_page_num ON document_pages(document_id, page_number)
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

      // Create audit_entries table with tamper-proof fields (checksums, chaining)
      await db.execute('''
        CREATE TABLE audit_entries (
          id TEXT PRIMARY KEY,
          level TEXT NOT NULL,
          action TEXT NOT NULL,
          resource_type TEXT NOT NULL,
          resource_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          details TEXT,
          location TEXT,
          device_info TEXT,
          is_success INTEGER NOT NULL DEFAULT 1,
          error_message TEXT,
          checksum TEXT NOT NULL,
          previous_entry_id TEXT,
          previous_checksum TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // Create indexes for performance
      await db.execute('''
        CREATE INDEX idx_audit_timestamp ON audit_entries(timestamp DESC)
      ''');
      await db.execute('''
        CREATE INDEX idx_audit_level ON audit_entries(level)
      ''');
      await db.execute('''
        CREATE INDEX idx_audit_action ON audit_entries(action)
      ''');
      await db.execute('''
        CREATE INDEX idx_audit_resource ON audit_entries(resource_type, resource_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_audit_chain ON audit_entries(previous_entry_id)
      ''');

      // Audit entries are written via application code to ensure proper
      // checksum calculation and chain linking for tamper-proofing
      // Note: SQLite triggers can't easily calculate checksums or maintain chains,
      // so we use application-level logging which is more reliable

      // Create document_embeddings table for vector semantic search
      await db.execute('''
        CREATE TABLE document_embeddings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_id TEXT NOT NULL UNIQUE,
          embedding BLOB NOT NULL,
          text_hash TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_document_embeddings_doc_id
        ON document_embeddings(document_id)
      ''');
      logInfo('Created document_embeddings table for vector search');

      // Insert default settings
      final defaultSettings = UserSettings.defaultSettings();
      await _insertUserSettings(db, defaultSettings);

      logInfo('Database created successfully with all tables including vector search');
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
          'ALTER TABLE documents ADD COLUMN image_format TEXT DEFAULT "jpeg"',
        );
        await db.execute('ALTER TABLE documents ADD COLUMN image_size INTEGER');
        await db.execute(
          'ALTER TABLE documents ADD COLUMN image_width INTEGER',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN image_height INTEGER',
        );
        logInfo('Added image BLOB columns to documents table');
      } catch (e) {
        logError('Error adding image BLOB columns', e);
      }
    }

    if (oldVersion < 5) {
      // Add thumbnail_data column for performance optimization
      try {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN thumbnail_data BLOB',
        );
        logInfo('Added thumbnail_data column to documents table');
      } catch (e) {
        logError('Error adding thumbnail_data column', e);
      }
    }

    if (oldVersion < 6) {
      // Add audit_entries table for tamper-proof audit logging
      try {
        // Create audit_entries table with tamper-proof fields
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audit_entries (
            id TEXT PRIMARY KEY,
            level TEXT NOT NULL,
            action TEXT NOT NULL,
            resource_type TEXT NOT NULL,
            resource_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            details TEXT,
            location TEXT,
            device_info TEXT,
            is_success INTEGER NOT NULL DEFAULT 1,
            error_message TEXT,
            checksum TEXT NOT NULL,
            previous_entry_id TEXT,
            previous_checksum TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        // Create indexes
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_entries(timestamp DESC)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_audit_level ON audit_entries(level)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_entries(action)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_entries(resource_type, resource_id)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_audit_chain ON audit_entries(previous_entry_id)
        ''');

        logInfo('Added audit_entries table to main database');
      } catch (e) {
        logError('Error adding audit_entries table', e);
      }
    }

    if (oldVersion < 7) {
      // Add multi-page document support and image enhancement
      try {
        // Add new columns to documents table
        await db.execute(
          'ALTER TABLE documents ADD COLUMN is_multi_page INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN page_count INTEGER NOT NULL DEFAULT 1',
        );
        logInfo('Added multi-page columns to documents table');

        // Create document_pages table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS document_pages (
            id TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            image_data BLOB,
            thumbnail_data BLOB,
            image_format TEXT DEFAULT 'jpeg',
            image_size INTEGER,
            image_width INTEGER,
            image_height INTEGER,
            extracted_text TEXT NOT NULL,
            confidence_score REAL NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        logInfo('Created document_pages table');

        // Create indexes for document_pages
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_document_pages_doc_id ON document_pages(document_id)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_document_pages_page_num ON document_pages(document_id, page_number)
        ''');
        logInfo('Created indexes for document_pages table');
      } catch (e) {
        logError('Error adding multi-page support', e);
      }
    }

    if (oldVersion < 8) {
      // Add vector embeddings support for semantic search
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS document_embeddings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL UNIQUE,
            embedding BLOB NOT NULL,
            text_hash TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
          )
        ''');
        logInfo('Created document_embeddings table');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_document_embeddings_doc_id
          ON document_embeddings(document_id)
        ''');
        logInfo('Created indexes for document_embeddings table');
      } catch (e) {
        logError('Error adding vector embeddings support', e);
      }
    }

    if (oldVersion < 9) {
      // Ensure document_embeddings table exists (fix for databases that were already at v8)
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS document_embeddings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL UNIQUE,
            embedding BLOB NOT NULL,
            text_hash TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
          )
        ''');
        logInfo('Ensured document_embeddings table exists');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_document_embeddings_doc_id
          ON document_embeddings(document_id)
        ''');
        logInfo('Ensured indexes for document_embeddings table exist');
      } catch (e) {
        logError('Error ensuring vector embeddings support', e);
      }
    }

    if (oldVersion < 10) {
      // Add entity extraction columns for NLP querying
      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN vendor TEXT
        ''');
        logInfo('Added vendor column to documents table');
      } catch (e) {
        logWarning('Vendor column may already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN amount REAL
        ''');
        logInfo('Added amount column to documents table');
      } catch (e) {
        logWarning('Amount column may already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN transaction_date INTEGER
        ''');
        logInfo('Added transaction_date column to documents table');
      } catch (e) {
        logWarning('Transaction_date column may already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN category TEXT
        ''');
        logInfo('Added category column to documents table');
      } catch (e) {
        logWarning('Category column may already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN entity_confidence REAL DEFAULT 0.0
        ''');
        logInfo('Added entity_confidence column to documents table');
      } catch (e) {
        logWarning('Entity_confidence column may already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE documents ADD COLUMN entities_extracted_at INTEGER
        ''');
        logInfo('Added entities_extracted_at column to documents table');
      } catch (e) {
        logWarning('Entities_extracted_at column may already exist: $e');
      }

      // Create indexes for efficient entity queries
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_documents_vendor ON documents(vendor)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_documents_amount ON documents(amount)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_documents_transaction_date ON documents(transaction_date)
        ''');
        logInfo('Created entity column indexes');
      } catch (e) {
        logError('Error creating entity column indexes', e);
      }

      logInfo('Database upgraded to version 10 with entity extraction columns');
    }
  }

  /// Create SQLite triggers for automatic audit logging
  /// Note: Triggers write basic audit info, but checksums are calculated in app code
  /// This ensures tamper-proofing while keeping it simple
  Future<void> _createAuditTriggers(Database db) async {
    try {
      // Drop existing triggers if they exist (for migrations)
      await db.execute('DROP TRIGGER IF EXISTS audit_documents_insert');
      await db.execute('DROP TRIGGER IF EXISTS audit_documents_update');
      await db.execute('DROP TRIGGER IF EXISTS audit_documents_delete');

      // Note: We're not using triggers for now because:
      // 1. Checksums need to be calculated in app code (requires crypto)
      // 2. Chain linking requires reading last entry
      // 3. SQLite triggers can't easily do this
      //
      // Instead, we rely on application-level logging which is more reliable
      // and can properly implement tamper-proofing with checksums and chaining

      logInfo(
        'Audit triggers skipped - using application-level logging for tamper-proofing',
      );
    } catch (e) {
      logError('Failed to create audit triggers', e);
      // Don't throw - triggers are nice-to-have, not critical
    }
  }

  // Document operations
  @override
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

      // Log to audit database (COMPULSORY level)
      await _auditLoggingService?.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: document.id,
        details: 'Document created: ${document.title}',
      );

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

  @override
  Future<Document?> getDocument(String id) async {
    final db = await database;
    try {
      // Log database read (COMPULSORY level)
      await _auditLoggingService?.logDatabaseRead(
        resourceType: 'document',
        resourceId: id,
        details: 'Read document by ID',
      );

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

  @override
  Future<List<Document>> getAllDocuments({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  }) async {
    final db = await database;
    try {
      // Log database read (COMPULSORY level)
      await _auditLoggingService?.logDatabaseRead(
        resourceType: 'documents',
        resourceId: 'list',
        details:
            'Read documents list (type: ${type?.name ?? 'all'}, limit: $limit)',
      );
      // If there's a search query, use JOIN with search_index (FTS5)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        try {
          // Sanitize the query to prevent FTS5 injection
          final sanitizedQuery = _sanitizeFTS5Query(searchQuery);

          // Try FTS5 search with JOIN
          String query = '''
            SELECT DISTINCT d.* FROM documents d
            JOIN search_index s ON d.id = s.doc_id
            WHERE search_index MATCH ?
          ''';
          List<dynamic> queryArgs = [sanitizedQuery];

          if (type != null) {
            query += ' AND d.type = ?';
            queryArgs.add(type.name);
          }

          query += ' ORDER BY d.created_at DESC';

          if (limit != null) {
            query += ' LIMIT ?';
            queryArgs.add(limit);
          }

          if (offset != null) {
            query += ' OFFSET ?';
            queryArgs.add(offset);
          }

          final maps = await db.rawQuery(query, queryArgs);
          return maps.map((map) => _mapToDocument(map)).toList();
        } catch (e) {
          logWarning('FTS5 search failed, using fallback: $e');
          // Fallback to LIKE search
          String query = '''
            SELECT DISTINCT d.* FROM documents d
            JOIN search_index s ON d.id = s.doc_id
            WHERE (s.title LIKE ? OR s.extracted_text LIKE ? OR s.tags LIKE ? OR s.notes LIKE ?)
          ''';
          final searchTerm = '%$searchQuery%';
          List<dynamic> queryArgs = [
            searchTerm,
            searchTerm,
            searchTerm,
            searchTerm,
          ];

          if (type != null) {
            query += ' AND d.type = ?';
            queryArgs.add(type.name);
          }

          query += ' ORDER BY d.created_at DESC';

          if (limit != null) {
            query += ' LIMIT ?';
            queryArgs.add(limit);
          }

          if (offset != null) {
            query += ' OFFSET ?';
            queryArgs.add(offset);
          }

          final maps = await db.rawQuery(query, queryArgs);
          return maps.map((map) => _mapToDocument(map)).toList();
        }
      }

      // No search query - use regular query
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (type != null) {
        whereClause += 'type = ?';
        whereArgs.add(type.name);
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

  @override
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

      // Log to audit database (COMPULSORY level)
      await _auditLoggingService?.logDatabaseWrite(
        action: AuditAction.update,
        resourceType: 'document',
        resourceId: document.id,
        details: 'Document updated: ${document.title}',
      );

      logInfo('Document updated: ${document.id}');
    } catch (e) {
      logError('Failed to update document', e);
      throw DatabaseException(
        'Failed to update document: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update only the entity extraction fields for a document
  /// Used by EntityExtractionService to update extracted entities without
  /// modifying other document fields
  Future<void> updateDocumentEntities({
    required String documentId,
    String? vendor,
    double? amount,
    DateTime? transactionDate,
    String? category,
    required double entityConfidence,
  }) async {
    final db = await database;
    try {
      await db.update(
        'documents',
        {
          'vendor': vendor,
          'amount': amount,
          'transaction_date': transactionDate?.millisecondsSinceEpoch,
          'category': category,
          'entity_confidence': entityConfidence,
          'entities_extracted_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [documentId],
      );

      logInfo('Document entities updated: $documentId (vendor: $vendor, amount: $amount, category: $category)');
    } catch (e) {
      logError('Failed to update document entities', e);
      throw DatabaseException(
        'Failed to update document entities: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get documents that haven't had entities extracted yet
  Future<List<Document>> getDocumentsWithoutEntities({int? limit}) async {
    final db = await database;
    try {
      final maps = await db.query(
        'documents',
        where: 'entities_extracted_at IS NULL',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      logError('Failed to get documents without entities', e);
      throw DatabaseException(
        'Failed to get documents without entities: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get entity extraction statistics
  Future<Map<String, int>> getEntityExtractionStats() async {
    final db = await database;
    try {
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
      final extractedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM documents WHERE entities_extracted_at IS NOT NULL');
      final withVendorResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM documents WHERE vendor IS NOT NULL');
      final withAmountResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM documents WHERE amount IS NOT NULL');

      return {
        'total_documents': (totalResult.first['count'] as int?) ?? 0,
        'extracted_documents': (extractedResult.first['count'] as int?) ?? 0,
        'pending_documents': ((totalResult.first['count'] as int?) ?? 0) -
            ((extractedResult.first['count'] as int?) ?? 0),
        'documents_with_vendor': (withVendorResult.first['count'] as int?) ?? 0,
        'documents_with_amount': (withAmountResult.first['count'] as int?) ?? 0,
      };
    } catch (e) {
      logError('Failed to get entity extraction stats', e);
      return {
        'total_documents': 0,
        'extracted_documents': 0,
        'pending_documents': 0,
        'documents_with_vendor': 0,
        'documents_with_amount': 0,
      };
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Delete from search index
        await txn.delete('search_index', where: 'doc_id = ?', whereArgs: [id]);

        // Delete document
        await txn.delete('documents', where: 'id = ?', whereArgs: [id]);
      });

      // Log to audit database (COMPULSORY level)
      await _auditLoggingService?.logDatabaseWrite(
        action: AuditAction.delete,
        resourceType: 'document',
        resourceId: id,
        details: 'Document deleted',
      );

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

  @override
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
        } else if (value.startsWith('[') || value.startsWith('{')) {
          // Try to parse as JSON (for lists and maps)
          try {
            settingsMap[key] = jsonDecode(value);
          } catch (_) {
            settingsMap[key] = value;
          }
        } else if (value.contains('.')) {
          settingsMap[key] = double.tryParse(value) ?? value;
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

  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final settingsMap = settings.toJson();
        for (final entry in settingsMap.entries) {
          await txn.insert('user_settings', {
            'key': entry.key,
            'value': entry.value.toString(),
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

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
  // Deprecated: _logAudit method removed - use _auditLoggingService instead
  // The AuditLoggingService properly tracks user IDs via setUserId()
  // and provides level-based logging (COMPULSORY, DISCRETIONARY, etc.)

  @override
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

  /// Sanitize FTS5 query to prevent injection attacks
  /// Escapes special FTS5 characters and limits query length
  String _sanitizeFTS5Query(String query) {
    // Limit query length to prevent DoS
    const maxQueryLength = 200;
    String sanitized = query.length > maxQueryLength
        ? query.substring(0, maxQueryLength)
        : query;

    // Remove or escape FTS5 special characters
    // FTS5 special chars: " - ( ) * AND OR NOT
    sanitized = sanitized
        .replaceAll('"', '""') // Escape quotes by doubling them
        .replaceAll('(', '') // Remove grouping operators
        .replaceAll(')', '')
        .replaceAll('*', '') // Remove wildcard operators
        .replaceAll('-', ' '); // Replace NOT operator with space

    // Remove FTS5 boolean operators (case-insensitive)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b(AND|OR|NOT)\b', caseSensitive: false),
      (match) => ' ',
    );

    // Trim and collapse multiple spaces
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Wrap the sanitized query in quotes for exact phrase matching
    // This prevents FTS5 syntax interpretation
    return '"$sanitized"';
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    try {
      // Sanitize the query to prevent FTS5 injection
      final sanitizedQuery = _sanitizeFTS5Query(query);

      // Try FTS5 search first
      try {
        final maps = await db.rawQuery(
          '''
          SELECT d.* FROM documents d
          JOIN search_index s ON d.id = s.doc_id
          WHERE search_index MATCH ?
          ORDER BY rank
        ''',
          [sanitizedQuery],
        );
        return maps.map((map) => _mapToDocument(map)).toList();
      } catch (e) {
        logWarning('FTS5 search failed, using fallback: $e');
        // Fallback to LIKE search
        final searchTerm = '%$query%';
        final maps = await db.rawQuery(
          '''
          SELECT d.* FROM documents d
          JOIN search_index s ON d.id = s.doc_id
          WHERE s.title LIKE ? OR s.extracted_text LIKE ? OR s.tags LIKE ? OR s.notes LIKE ?
          ORDER BY d.scan_date DESC
        ''',
          [searchTerm, searchTerm, searchTerm, searchTerm],
        );
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

  @override
  Future<List<DocumentSummary>> getDocumentSummaries({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  }) async {
    final db = await database;
    try {
      // Query only metadata and thumbnails, not full image data
      String query = '''
        SELECT 
          id, title, thumbnail_data, image_format, type, scan_date, 
          tags, confidence_score, detected_language, created_at, 
          updated_at, is_encrypted
        FROM documents
      ''';
      List<dynamic> queryArgs = [];

      // Handle search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        try {
          // Sanitize the query to prevent FTS5 injection
          final sanitizedQuery = _sanitizeFTS5Query(searchQuery);

          // Try FTS5 search with JOIN
          query = '''
            SELECT DISTINCT
              d.id, d.title, d.thumbnail_data, d.image_format, d.type,
              d.scan_date, d.tags, d.confidence_score, d.detected_language,
              d.created_at, d.updated_at, d.is_encrypted
            FROM documents d
            JOIN search_index s ON d.id = s.doc_id
            WHERE search_index MATCH ?
          ''';
          queryArgs = [sanitizedQuery];

          if (type != null) {
            query += ' AND d.type = ?';
            queryArgs.add(type.name);
          }
        } catch (e) {
          logWarning('FTS5 search failed, using fallback: $e');
          // Fallback to LIKE search
          query = '''
            SELECT DISTINCT 
              d.id, d.title, d.thumbnail_data, d.image_format, d.type, 
              d.scan_date, d.tags, d.confidence_score, d.detected_language, 
              d.created_at, d.updated_at, d.is_encrypted
            FROM documents d
            JOIN search_index s ON d.id = s.doc_id
            WHERE (s.title LIKE ? OR s.extracted_text LIKE ? OR s.tags LIKE ? OR s.notes LIKE ?)
          ''';
          final searchTerm = '%$searchQuery%';
          queryArgs = [searchTerm, searchTerm, searchTerm, searchTerm];

          if (type != null) {
            query += ' AND d.type = ?';
            queryArgs.add(type.name);
          }
        }
      } else if (type != null) {
        query += ' WHERE type = ?';
        queryArgs.add(type.name);
      }

      query += ' ORDER BY created_at DESC';

      if (limit != null) {
        query += ' LIMIT ?';
        queryArgs.add(limit);
      }

      if (offset != null) {
        query += ' OFFSET ?';
        queryArgs.add(offset);
      }

      final maps = await db.rawQuery(query, queryArgs);
      return maps.map((map) => _mapToDocumentSummary(map)).toList();
    } catch (e) {
      logError('Failed to get document summaries', e);
      throw DatabaseException(
        'Failed to get document summaries: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Uint8List?> getDocumentImageData(String documentId) async {
    final db = await database;
    try {
      final maps = await db.query(
        'documents',
        columns: ['image_data'],
        where: 'id = ?',
        whereArgs: [documentId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first['image_data'] as Uint8List?;
      }
      return null;
    } catch (e) {
      logError('Failed to get document image data', e);
      throw DatabaseException(
        'Failed to get document image data: ${e.toString()}',
        originalError: e,
      );
    }
  }

  DocumentSummary _mapToDocumentSummary(Map<String, dynamic> map) {
    return DocumentSummary(
      id: map['id'],
      title: map['title'],
      thumbnailData: map['thumbnail_data'] as Uint8List?,
      imageFormat: map['image_format'] ?? 'jpeg',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scan_date']),
      tags: (map['tags'] as String?)?.split(',') ?? [],
      confidenceScore: map['confidence_score'],
      detectedLanguage: map['detected_language'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isEncrypted: map['is_encrypted'] == 1,
    );
  }

  // Helper methods
  Map<String, dynamic> _documentToMap(Document document) {
    return {
      'id': document.id,
      'title': document.title,
      'image_data': document.imageData,
      'thumbnail_data': document.thumbnailData,
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
      'is_multi_page': document.isMultiPage ? 1 : 0,
      'page_count': document.pageCount,
    };
  }

  Document _mapToDocument(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      imageData: map['image_data'] as Uint8List?,
      thumbnailData: map['thumbnail_data'] as Uint8List?,
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
      metadata:
          map['metadata'] != null &&
              map['metadata'] is String &&
              (map['metadata'] as String).isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'] as String))
          : const {},
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
      isMultiPage: (map['is_multi_page'] ?? 0) == 1,
      pageCount: map['page_count'] ?? 1,
    );
  }

  // Removed _auditLogToMap - no longer needed after deprecating old audit system

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
      _isInitialized = false;
    }
  }

  /// Public method to log audit entries (for use by other services)
  /// DEPRECATED: Use AuditLoggingService instead
  @Deprecated('Use AuditLoggingService for proper user tracking')
  Future<void> logAudit(
    AuditAction action,
    String resourceType,
    String resourceId,
    String? details,
  ) async {
    // No-op: This method is deprecated
    // Use _auditLoggingService instead for proper user ID tracking
  }

  // ============================================================================
  // Document Pages Methods (Multi-page document support)
  // ============================================================================

  /// Save a document page
  @override
  Future<void> saveDocumentPage(DocumentPage page) async {
    try {
      final db = await database;
      await db.insert('document_pages', {
        'id': page.id,
        'document_id': page.documentId,
        'page_number': page.pageNumber,
        'image_data': page.imageData,
        'thumbnail_data': page.thumbnailData,
        'image_format': page.imageFormat,
        'image_size': page.imageSize,
        'image_width': page.imageWidth,
        'image_height': page.imageHeight,
        'extracted_text': page.extractedText,
        'confidence_score': page.confidenceScore,
        'created_at': page.createdAt.millisecondsSinceEpoch,
        'updated_at': page.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logError('Failed to save document page', e);
      throw DatabaseException(
        'Failed to save document page: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get all pages for a document
  @override
  Future<List<DocumentPage>> getDocumentPages(String documentId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'document_pages',
        where: 'document_id = ?',
        whereArgs: [documentId],
        orderBy: 'page_number ASC',
      );

      return List.generate(maps.length, (i) => _documentPageFromMap(maps[i]));
    } catch (e) {
      logError('Failed to get document pages', e);
      throw DatabaseException(
        'Failed to get document pages: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get a specific page by page number
  @override
  Future<DocumentPage?> getDocumentPage(
    String documentId,
    int pageNumber,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'document_pages',
        where: 'document_id = ? AND page_number = ?',
        whereArgs: [documentId, pageNumber],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return _documentPageFromMap(maps.first);
    } catch (e) {
      logError('Failed to get document page', e);
      throw DatabaseException(
        'Failed to get document page: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update a document page
  @override
  Future<void> updateDocumentPage(DocumentPage page) async {
    try {
      final db = await database;
      await db.update(
        'document_pages',
        {
          'image_data': page.imageData,
          'thumbnail_data': page.thumbnailData,
          'image_format': page.imageFormat,
          'image_size': page.imageSize,
          'image_width': page.imageWidth,
          'image_height': page.imageHeight,
          'extracted_text': page.extractedText,
          'confidence_score': page.confidenceScore,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [page.id],
      );
    } catch (e) {
      logError('Failed to update document page', e);
      throw DatabaseException(
        'Failed to update document page: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete a document page
  @override
  Future<void> deleteDocumentPage(String pageId) async {
    try {
      final db = await database;
      await db.delete('document_pages', where: 'id = ?', whereArgs: [pageId]);
    } catch (e) {
      logError('Failed to delete document page', e);
      throw DatabaseException(
        'Failed to delete document page: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete all pages for a document
  Future<void> deleteDocumentPages(String documentId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'document_pages',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      logError('Failed to delete document pages', e);
      throw DatabaseException(
        'Failed to delete document pages: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Helper method to convert database map to DocumentPage
  DocumentPage _documentPageFromMap(Map<String, dynamic> map) {
    return DocumentPage(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      pageNumber: map['page_number'] as int,
      imageData: map['image_data'] as Uint8List?,
      thumbnailData: map['thumbnail_data'] as Uint8List?,
      imageFormat: map['image_format'] as String? ?? 'jpeg',
      imageSize: map['image_size'] as int?,
      imageWidth: map['image_width'] as int?,
      imageHeight: map['image_height'] as int?,
      extractedText: map['extracted_text'] as String,
      confidenceScore: map['confidence_score'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
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
  Future<String> encryptFileWithPassword(String filePath, String password) =>
      _service.encryptFileWithPassword(filePath, password);

  @override
  Future<String> decryptFileWithPassword(
    String encryptedFilePath,
    String password,
  ) => _service.decryptFileWithPassword(encryptedFilePath, password);

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
