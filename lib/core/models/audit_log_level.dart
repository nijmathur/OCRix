/// Audit log levels for different types of logging
enum AuditLogLevel {
  /// INFO: All user actions (document creation, updates, deletions, etc.)
  info,

  /// VERBOSE: Navigation between features/screens
  verbose,

  /// COMPULSORY: All database reads and writes (always logged)
  compulsory,
}

extension AuditLogLevelExtension on AuditLogLevel {
  String get name => switch (this) {
    AuditLogLevel.info => 'INFO',
    AuditLogLevel.verbose => 'VERBOSE',
    AuditLogLevel.compulsory => 'COMPULSORY',
  };

  /// Get numeric priority (higher = more important)
  int get priority => switch (this) {
    AuditLogLevel.info => 1,
    AuditLogLevel.verbose => 2,
    AuditLogLevel.compulsory => 3,
  };

  /// Check if this level should be logged based on configured level
  bool shouldLog(AuditLogLevel configuredLevel) {
    return priority >= configuredLevel.priority;
  }
}
