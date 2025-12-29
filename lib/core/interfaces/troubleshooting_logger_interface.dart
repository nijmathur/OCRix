import '../models/log_level.dart';

/// Interface for troubleshooting logger (SOLID - Interface Segregation)
abstract class ITroubleshootingLogger {
  /// Log a debug message
  Future<void> debug(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  });

  /// Log an info message
  Future<void> info(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  });

  /// Log a warning
  Future<void> warning(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? metadata,
  });

  /// Log an error
  Future<void> error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  });

  /// Log a critical error
  Future<void> critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  });

  /// Set minimum log level
  void setMinimumLevel(LogLevel level);

  /// Get current log file content
  Future<String> getLogContent();

  /// Export logs for sending
  Future<String> exportLogs();

  /// Clear logs
  Future<void> clearLogs();

  /// Initialize the logger
  Future<void> initialize();
}
