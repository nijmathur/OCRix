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
  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  /// Get numeric priority (higher = more important)
  int get priority {
    switch (this) {
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
      case LogLevel.critical:
        return 5;
    }
  }

  /// Check if this level should be logged based on configured minimum level
  bool shouldLog(LogLevel minimumLevel) {
    return priority >= minimumLevel.priority;
  }

  /// Get emoji representation for readability
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

