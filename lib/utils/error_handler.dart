import 'package:flutter/foundation.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';

/// Global error handler for Flutter errors (SOLID - Single Responsibility)
class ErrorHandler {
  static ITroubleshootingLogger? _logger;
  static FlutterExceptionHandler? _originalOnError;

  /// Initialize error handling
  static void initialize(ITroubleshootingLogger logger) {
    _logger = logger;

    // Capture Flutter framework errors
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger?.critical(
        'Flutter framework error: ${details.exception}',
        tag: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
        metadata: {
          'library': details.library,
          'context': details.context?.toString(),
          'informationCollector':
              details.informationCollector?.call().toString(),
        },
      );

      // Call original handler
      _originalOnError?.call(details);
    };

    // Capture zone errors (async errors) - handled by runZonedGuarded in main
  }

  /// Handle platform errors
  static void handlePlatformError(Object error, StackTrace stackTrace) {
    _logger?.error(
      'Platform error: $error',
      tag: 'PlatformError',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
