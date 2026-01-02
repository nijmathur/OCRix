import 'dart:io';
import '../models/audit_entry.dart';
import '../core/models/audit_log_level.dart';
import '../models/audit_log.dart';
import '../core/interfaces/audit_database_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/config/app_config.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for logging audit events with level-based filtering
class AuditLoggingService extends BaseService {
  final IAuditDatabaseService _auditDatabase;
  AuditLogLevel _currentLevel = AppConfig.defaultAuditLogLevel;
  String? _currentUserId;
  String? _deviceInfo;

  AuditLoggingService(this._auditDatabase);

  @override
  String get serviceName => 'AuditLoggingService';

  /// Set the current logging level
  void setLogLevel(AuditLogLevel level) {
    _currentLevel = level;
    super.logInfo('Audit log level set to: ${level.name}');
  }

  /// Get the current logging level
  AuditLogLevel get currentLevel => _currentLevel;

  /// Set the current user ID
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Get the current user ID
  String? get currentUserId => _currentUserId;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _auditDatabase.initialize();
      _deviceInfo = Platform.operatingSystem;
      super.logInfo(
        'Audit logging service initialized with level: ${_currentLevel.name}',
      );

      // No staging processing needed - audit is in main database
    } catch (e) {
      logError('Failed to initialize audit logging service', e);
      throw DatabaseException(
        'Failed to initialize audit logging service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // Removed - no staging table needed since audit is in main database

  /// Log an audit event (if level matches current configuration)
  Future<String?> log({
    required AuditLogLevel level,
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    String? details,
    String? location,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    try {
      // Check if this level should be logged
      if (!level.shouldLog(_currentLevel)) {
        return null; // Don't log if level is below configured level
      }

      // Get last entry for chain linking
      final lastEntry = await _auditDatabase.getLastEntry();

      // Create audit entry with chain linking
      final entry = AuditEntry.create(
        level: level,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        userId: _currentUserId ?? 'unknown',
        details: details,
        location: location,
        deviceInfo: _deviceInfo,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
        previousEntryId: lastEntry?.id,
        previousChecksum: lastEntry?.checksum,
      );

      // Insert into audit database
      final entryId = await _auditDatabase.insertAuditEntry(entry);

      logDebug(
        'Audit event logged: ${level.name} - ${action.name} on $resourceType/$resourceId',
      );
      return entryId;
    } catch (e) {
      logError('Failed to log audit event', e);
      // Don't throw - audit logging failures shouldn't break the app
      return null;
    }
  }

  /// Log a COMPULSORY event (always logged)
  Future<String?> logCompulsory({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    String? details,
    String? location,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    return await log(
      level: AuditLogLevel.compulsory,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      location: location,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  /// Log an INFO event (user actions)
  Future<String?> logInfoAction({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    String? details,
    String? location,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    return await log(
      level: AuditLogLevel.info,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      location: location,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  /// Log a VERBOSE event (navigation)
  Future<String?> logVerbose({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    String? details,
    String? location,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    return await log(
      level: AuditLogLevel.verbose,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      location: location,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  /// Log database read operation (COMPULSORY)
  Future<String?> logDatabaseRead({
    required String resourceType,
    required String resourceId,
    String? details,
  }) async {
    return await logCompulsory(
      action: AuditAction.read,
      resourceType: 'database',
      resourceId: '$resourceType/$resourceId',
      details: details ?? 'Read $resourceType with ID: $resourceId',
    );
  }

  /// Log database write operation (COMPULSORY)
  Future<String?> logDatabaseWrite({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    String? details,
  }) async {
    return await logCompulsory(
      action: action,
      resourceType: 'database',
      resourceId: '$resourceType/$resourceId',
      details: details ?? '${action.name} $resourceType with ID: $resourceId',
    );
  }

  /// Log navigation event (VERBOSE)
  Future<String?> logNavigation({
    required String fromScreen,
    required String toScreen,
    String? details,
  }) async {
    return await logVerbose(
      action: AuditAction.read, // Using read for navigation
      resourceType: 'navigation',
      resourceId: '$fromScreen->$toScreen',
      details: details ?? 'Navigated from $fromScreen to $toScreen',
    );
  }

  /// Get audit entries
  Future<List<AuditEntry>> getAuditEntries({
    int? limit,
    int? offset,
    AuditLogLevel? level,
    AuditAction? action,
    String? resourceType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _auditDatabase.getAuditEntries(
      limit: limit,
      offset: offset,
      level: level,
      action: action,
      resourceType: resourceType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Verify audit database integrity
  Future<List<String>> verifyIntegrity() async {
    return await _auditDatabase.verifyIntegrity();
  }

  /// Get entry count
  Future<int> getEntryCount({AuditLogLevel? level}) async {
    return await _auditDatabase.getEntryCount(level: level);
  }
}
