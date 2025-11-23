import 'package:logger/logger.dart';
import '../interfaces/troubleshooting_logger_interface.dart';

/// Base class for services to reduce boilerplate
/// Integrates with troubleshooting logger for user-facing logs
abstract class BaseService {
  /// Logger instance for the service (console logging)
  final Logger logger = Logger();

  /// Troubleshooting logger (optional - for file logging)
  ITroubleshootingLogger? _troubleshootingLogger;

  /// Service name for logging
  String get serviceName;

  /// Set troubleshooting logger (dependency injection)
  void setTroubleshootingLogger(ITroubleshootingLogger? logger) {
    _troubleshootingLogger = logger;
  }

  /// Log info message
  void logInfo(String message) {
    logger.i('[$serviceName] $message');
    _troubleshootingLogger?.info(
      message,
      tag: serviceName,
      metadata: {'type': 'info'},
    );
  }

  /// Log error message
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    logger.e('[$serviceName] $message', error: error, stackTrace: stackTrace);
    _troubleshootingLogger?.error(
      message,
      tag: serviceName,
      error: error,
      stackTrace: stackTrace,
      metadata: {'type': 'error'},
    );
  }

  /// Log warning message
  void logWarning(String message) {
    logger.w('[$serviceName] $message');
    _troubleshootingLogger?.warning(
      message,
      tag: serviceName,
      metadata: {'type': 'warning'},
    );
  }

  /// Log debug message
  void logDebug(String message) {
    logger.d('[$serviceName] $message');
    _troubleshootingLogger?.debug(
      message,
      tag: serviceName,
      metadata: {'type': 'debug'},
    );
  }
}
