import 'package:logger/logger.dart';

/// Base class for services to reduce boilerplate
abstract class BaseService {
  /// Logger instance for the service
  final Logger logger = Logger();

  /// Service name for logging
  String get serviceName;

  /// Log info message
  void logInfo(String message) {
    logger.i('[$serviceName] $message');
  }

  /// Log error message
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    logger.e('[$serviceName] $message', error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void logWarning(String message) {
    logger.w('[$serviceName] $message');
  }

  /// Log debug message
  void logDebug(String message) {
    logger.d('[$serviceName] $message');
  }
}
