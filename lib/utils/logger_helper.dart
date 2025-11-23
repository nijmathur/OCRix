import '../core/interfaces/troubleshooting_logger_interface.dart';

/// Helper class to bridge old Logger calls to troubleshooting logger
/// This allows gradual migration while ensuring all logs go to troubleshooting logger
class LoggerHelper {
  final ITroubleshootingLogger? _logger;

  LoggerHelper(this._logger);

  void i(String message, {String? tag}) {
    _logger?.info(message, tag: tag);
  }

  void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _logger?.error(
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void w(String message, {String? tag, Object? error}) {
    _logger?.warning(
      message,
      tag: tag,
      error: error,
    );
  }

  void d(String message, {String? tag}) {
    _logger?.debug(message, tag: tag);
  }
}
