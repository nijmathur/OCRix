import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';
import '../core/interfaces/log_file_service_interface.dart';
import '../core/interfaces/log_rotation_service_interface.dart';
import '../core/models/log_entry.dart';
import '../core/models/log_level.dart';
import '../core/config/app_config.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'log_formatter_service.dart';

/// Main troubleshooting logger service (SOLID - Open/Closed, Dependency Inversion)
class TroubleshootingLoggerService extends BaseService
    implements ITroubleshootingLogger {
  final ILogFileService _logFileService;
  final ILogRotationService _rotationService;
  LogLevel _minimumLevel = AppConfig.defaultLogLevel;
  final List<LogEntry> _inMemoryBuffer = [];
  static const int _bufferSize = 100; // Keep last 100 entries in memory

  TroubleshootingLoggerService(
    this._logFileService,
    this._rotationService,
  );

  @override
  String get serviceName => 'TroubleshootingLoggerService';

  @override
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
    super.logInfo('Minimum log level set to: ${level.name}');
  }

  LogLevel get minimumLevel => _minimumLevel;

  @override
  Future<void> initialize() async {
    try {
      await _logFileService.initialize();
      await _rotationService.checkAndRotate();
      super.logInfo('Troubleshooting logger initialized');
    } catch (e) {
      super.logError('Failed to initialize troubleshooting logger', e);
      // Don't throw - logger initialization failure shouldn't break app
    }
  }

  @override
  Future<void> debug(String message, {String? tag, Map<String, dynamic>? metadata}) async {
    await _log(LogLevel.debug, message, tag: tag, metadata: metadata);
  }

  @override
  Future<void> info(String message, {String? tag, Map<String, dynamic>? metadata}) async {
    await _log(LogLevel.info, message, tag: tag, metadata: metadata);
  }

  @override
  Future<void> warning(String message, {String? tag, Object? error, Map<String, dynamic>? metadata}) async {
    await _log(LogLevel.warning, message, tag: tag, error: error, metadata: metadata);
  }

  @override
  Future<void> error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) async {
    await _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  @override
  Future<void> critical(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) async {
    await _log(LogLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  Future<void> _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if this level should be logged
      if (!level.shouldLog(_minimumLevel)) {
        return;
      }

      // Create log entry
      final entry = LogEntry.create(
        level: level,
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );

      // Add to in-memory buffer
      _inMemoryBuffer.add(entry);
      if (_inMemoryBuffer.length > _bufferSize) {
        _inMemoryBuffer.removeAt(0); // Remove oldest
      }

      // Write to file (async, non-blocking)
      await _logFileService.writeEntry(entry);

      // Also log to console for development
      _logToConsole(entry);

      // Check rotation periodically (every 100 entries or on errors)
      if (level.priority >= LogLevel.error.priority || _inMemoryBuffer.length % 100 == 0) {
        await _rotationService.checkAndRotate();
      }
    } catch (e) {
      // Don't throw - logging failures shouldn't break the app
      // Just log to console as fallback
      // Fallback to console if troubleshooting logger itself fails
      debugPrint('Failed to log entry: $e');
    }
  }

  void _logToConsole(LogEntry entry) {
    // Only log errors and critical to console to avoid spam
    if (entry.level.priority >= LogLevel.error.priority) {
      debugPrint('[${entry.level.name}] ${entry.tag != null ? "[${entry.tag}] " : ""}${entry.message}');
      if (entry.error != null) {
        debugPrint('  Error: ${entry.error}');
      }
    }
  }

  @override
  Future<String> getLogContent() async {
    try {
      return await _logFileService.readAsString();
    } catch (e) {
      return 'Error reading log content: $e';
    }
  }

  @override
  Future<String> exportLogs() async {
    try {
      final buffer = StringBuffer();

      // Header
      buffer.writeln('=' * 80);
      buffer.writeln('OCRix Troubleshooting Log Export');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('=' * 80);
      buffer.writeln();

      // App info
      buffer.writeln('Application Information:');
      buffer.writeln('  Platform: ${Platform.operatingSystem}');
      buffer.writeln('  OS Version: ${Platform.operatingSystemVersion}');
      buffer.writeln('  Log Level: ${_minimumLevel.name}');
      buffer.writeln();

      // Recent in-memory entries (most recent)
      if (_inMemoryBuffer.isNotEmpty) {
        buffer.writeln('Recent Log Entries (Last ${_inMemoryBuffer.length}):');
        buffer.writeln('-' * 80);
        final formatter = LogFormatterService();
        for (final entry in _inMemoryBuffer.reversed) {
          buffer.writeln(formatter.format(entry));
          buffer.writeln();
        }
        buffer.writeln();
      }

      // File log content
      buffer.writeln('Full Log File Content:');
      buffer.writeln('-' * 80);
      final fileContent = await _logFileService.readAsString();
      buffer.writeln(fileContent);

      return buffer.toString();
    } catch (e) {
      return 'Error exporting logs: $e';
    }
  }

  @override
  Future<void> clearLogs() async {
    try {
      await _logFileService.clear();
      _inMemoryBuffer.clear();
      super.logInfo('Logs cleared');
    } catch (e) {
      super.logError('Failed to clear logs', e);
      throw StorageException(
        'Failed to clear logs: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

