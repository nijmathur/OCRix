/// Log levels for troubleshooting and debugging
enum LogLevel {
  /// Debug information (verbose)
  debug,

  /// Informational messages
  info,

  /// Warning messages
  warning,

  /// Error messages
  error,

  /// Critical errors that need immediate attention
  critical,
}

extension LogLevelExtension on LogLevel {
  String get name => switch (this) {
    LogLevel.debug => 'DEBUG',
    LogLevel.info => 'INFO',
    LogLevel.warning => 'WARNING',
    LogLevel.error => 'ERROR',
    LogLevel.critical => 'CRITICAL',
  };

  /// Get numeric priority (higher = more important)
  int get priority => switch (this) {
    LogLevel.debug => 1,
    LogLevel.info => 2,
    LogLevel.warning => 3,
    LogLevel.error => 4,
    LogLevel.critical => 5,
  };

  /// Check if this level should be logged based on configured minimum level
  bool shouldLog(LogLevel minimumLevel) {
    return priority >= minimumLevel.priority;
  }

  /// Get emoji representation for readability
  String get emoji => switch (this) {
    LogLevel.debug => '🔍',
    LogLevel.info => 'ℹ️',
    LogLevel.warning => '⚠️',
    LogLevel.error => '❌',
    LogLevel.critical => '🚨',
  };
}
