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
  String get name {
    switch (this) {
      case AuditLogLevel.info:
        return 'INFO';
      case AuditLogLevel.verbose:
        return 'VERBOSE';
      case AuditLogLevel.compulsory:
        return 'COMPULSORY';
    }
  }

  /// Get numeric priority (higher = more important)
  int get priority {
    switch (this) {
      case AuditLogLevel.info:
        return 1;
      case AuditLogLevel.verbose:
        return 2;
      case AuditLogLevel.compulsory:
        return 3;
    }
  }

  /// Check if this level should be logged based on configured level
  bool shouldLog(AuditLogLevel configuredLevel) {
    return priority >= configuredLevel.priority;
  }
}
