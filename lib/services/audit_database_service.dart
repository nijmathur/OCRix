import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../models/audit_entry.dart';
import '../core/models/audit_log_level.dart';
import '../models/audit_log.dart';
import '../core/interfaces/audit_database_service_interface.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

/// Tamper-proof audit database service
/// Stores audit logs in the main database with integrity checks (checksums, chaining)
class AuditDatabaseService extends BaseService
    implements IAuditDatabaseService {
  static final AuditDatabaseService _instance =
      AuditDatabaseService._internal();
  factory AuditDatabaseService() => _instance;
  AuditDatabaseService._internal();

  IDatabaseService? _mainDatabaseService;
  bool _isInitialized = false;
  String? _lastEntryId;
  String? _lastChecksum;

  @override
  String get serviceName => 'AuditDatabaseService';

  /// Set main database service (uses same database as documents)
  void setMainDatabaseService(IDatabaseService databaseService) {
    _mainDatabaseService = databaseService;
  }

  Future<Database> get database async {
    if (_mainDatabaseService == null) {
      throw StateError('Main database service not set');
    }
    // Access database through main database service
    return await (_mainDatabaseService as dynamic).database;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (_mainDatabaseService == null) {
      throw StateError(
          'Main database service must be set before initialization');
    }

    try {
      logInfo('Initializing audit database (using main database)...');

      // Ensure main database is initialized (audit_entries table will be created there)
      await _mainDatabaseService!.initialize();

      // Load last entry for chain linking
      await _loadLastEntry();

      _isInitialized = true;
      logInfo('Audit database initialized successfully');
    } catch (e) {
      logError('Failed to initialize audit database', e);
      throw DatabaseException(
        'Failed to initialize audit database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // Note: Table creation is handled by DatabaseService._onCreate
  // This service just uses the audit_entries table in the main database

  Future<void> _loadLastEntry() async {
    try {
      final db = await database;
      final maps = await db.query(
        'audit_entries',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final entry = _mapToAuditEntry(maps.first);
        _lastEntryId = entry.id;
        _lastChecksum = entry.checksum;
      }
    } catch (e) {
      logWarning('Failed to load last entry: $e');
    }
  }

  @override
  Future<String> insertAuditEntry(AuditEntry entry) async {
    final db = await database;
    try {
      // Verify entry checksum before inserting
      if (!entry.verifyChecksum()) {
        throw DatabaseException('Audit entry checksum verification failed');
      }

      // Verify chain integrity if not first entry
      if (_lastEntryId != null && !entry.verifyChain(_lastChecksum)) {
        throw DatabaseException('Audit entry chain verification failed');
      }

      // Insert entry
      await db.insert('audit_entries', _auditEntryToMap(entry));

      // Update last entry tracking
      _lastEntryId = entry.id;
      _lastChecksum = entry.checksum;

      logInfo('Audit entry inserted: ${entry.id} (${entry.level.name})');
      return entry.id;
    } catch (e) {
      logError('Failed to insert audit entry', e);
      throw DatabaseException(
        'Failed to insert audit entry: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditEntry>> getAuditEntries({
    int? limit,
    int? offset,
    AuditLogLevel? level,
    AuditAction? action,
    String? resourceType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (level != null) {
        whereClause += 'level = ?';
        whereArgs.add(level.name);
      }

      if (action != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'action = ?';
        whereArgs.add(action.name);
      }

      if (resourceType != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'resource_type = ?';
        whereArgs.add(resourceType);
      }

      if (startDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final maps = await db.query(
        'audit_entries',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => _mapToAuditEntry(map)).toList();
    } catch (e) {
      logError('Failed to get audit entries', e);
      throw DatabaseException(
        'Failed to get audit entries: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<String>> verifyIntegrity() async {
    final db = await database;
    final failedEntries = <String>[];

    try {
      // Get all entries in chronological order (use id as tiebreaker for deterministic ordering)
      final maps = await db.query(
        'audit_entries',
        orderBy: 'timestamp ASC, id ASC',
      );

      // Build a map of entry IDs to entries for quick lookup
      final entryMap = <String, AuditEntry>{};
      for (final map in maps) {
        final entry = _mapToAuditEntry(map);
        entryMap[entry.id] = entry;
      }

      // Verify each entry
      for (final entry in entryMap.values) {
        // Verify entry checksum
        if (!entry.verifyChecksum()) {
          failedEntries.add(entry.id);
          logError('Checksum verification failed for entry: ${entry.id}');
          continue;
        }

        // Verify chain integrity - check if previous entry exists and checksum matches
        if (entry.previousEntryId != null) {
          final previousEntry = entryMap[entry.previousEntryId];
          if (previousEntry == null) {
            failedEntries.add(entry.id);
            logError('Previous entry not found for entry: ${entry.id}');
          } else if (!entry.verifyChain(previousEntry.checksum)) {
            failedEntries.add(entry.id);
            logError('Chain verification failed for entry: ${entry.id}');
          }
        }
      }

      if (failedEntries.isEmpty) {
        logInfo('Audit database integrity verification passed');
      } else {
        logWarning(
            'Audit database integrity verification found ${failedEntries.length} failed entries');
      }

      return failedEntries;
    } catch (e) {
      logError('Failed to verify audit database integrity', e);
      throw DatabaseException(
        'Failed to verify integrity: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<AuditEntry?> getLastEntry() async {
    try {
      final db = await database;
      final maps = await db.query(
        'audit_entries',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToAuditEntry(maps.first);
      }
      return null;
    } catch (e) {
      logError('Failed to get last audit entry', e);
      return null;
    }
  }

  @override
  Future<int> getEntryCount({AuditLogLevel? level}) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        level != null
            ? 'SELECT COUNT(*) as count FROM audit_entries WHERE level = ?'
            : 'SELECT COUNT(*) as count FROM audit_entries',
        level != null ? [level.name] : null,
      );

      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      logError('Failed to get entry count', e);
      return 0;
    }
  }

  @override
  Future<void> close() async {
    // Don't close the database - it's shared with main database service
    _isInitialized = false;
    _lastEntryId = null;
    _lastChecksum = null;
  }

  // Helper methods
  Map<String, dynamic> _auditEntryToMap(AuditEntry entry) {
    return {
      'id': entry.id,
      'level': entry.level.name,
      'action': entry.action.name,
      'resource_type': entry.resourceType,
      'resource_id': entry.resourceId,
      'user_id': entry.userId,
      'timestamp': entry.timestamp.millisecondsSinceEpoch,
      'details': entry.details,
      'location': entry.location,
      'device_info': entry.deviceInfo,
      'is_success': entry.isSuccess ? 1 : 0,
      'error_message': entry.errorMessage,
      'checksum': entry.checksum,
      'previous_entry_id': entry.previousEntryId,
      'previous_checksum': entry.previousChecksum,
      'created_at': entry.timestamp.millisecondsSinceEpoch,
    };
  }

  AuditEntry _mapToAuditEntry(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'],
      level: AuditLogLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['level'] as String).toLowerCase(),
        orElse: () => AuditLogLevel.compulsory,
      ),
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
      checksum: map['checksum'],
      previousEntryId: map['previous_entry_id'],
      previousChecksum: map['previous_checksum'],
    );
  }
}
