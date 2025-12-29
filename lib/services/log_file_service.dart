import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../core/interfaces/log_file_service_interface.dart';
import '../core/interfaces/log_formatter_interface.dart';
import '../core/models/log_entry.dart';
import '../core/config/app_config.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'log_formatter_service.dart';

/// Service for log file operations (SOLID - Single Responsibility)
class LogFileService extends BaseService implements ILogFileService {
  String? _logFilePath;
  final ILogFormatter _formatter;
  final String? _logsDirectoryPathOverride;

  LogFileService({
    ILogFormatter? formatter,
    String? logsDirectoryPathOverride,
  })  : _formatter = formatter ?? const LogFormatterService(),
        _logsDirectoryPathOverride = logsDirectoryPathOverride;

  @override
  String get serviceName => 'LogFileService';

  @override
  String get currentLogFilePath {
    if (_logFilePath == null) {
      throw StateError('Log file service not initialized');
    }
    return _logFilePath!;
  }

  @override
  Future<void> initialize() async {
    try {
      logInfo('Initializing log file service...');

      Directory logsDir;
      if (_logsDirectoryPathOverride != null) {
        logsDir = Directory(_logsDirectoryPathOverride);
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        logsDir = Directory(join(documentsDir.path, AppConfig.logDirectory));
      }

      // Create logs directory if it doesn't exist
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFilePath = join(logsDir.path, AppConfig.logFileName);

      // Create log file if it doesn't exist
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        await logFile.create();
        // Write header
        await logFile.writeAsString(_getLogHeader());
      }

      logInfo('Log file service initialized: $_logFilePath');
    } catch (e) {
      logError('Failed to initialize log file service', e);
      throw StorageException(
        'Failed to initialize log file service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  String _getLogHeader() {
    final now = DateTime.now();
    return '''
${'=' * 80}
OCRix Application Log
Started: ${now.toIso8601String()}
${'=' * 80}

''';
  }

  @override
  Future<void> writeEntry(LogEntry entry) async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      final formatted = _formatter.format(entry);
      await logFile.writeAsString('$formatted\n', mode: FileMode.append);
    } catch (e) {
      // Don't throw - logging failures shouldn't break the app
      logError('Failed to write log entry', e);
    }
  }

  @override
  Future<void> writeEntries(List<LogEntry> entries) async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      final buffer = StringBuffer();
      for (final entry in entries) {
        buffer.writeln(_formatter.format(entry));
      }
      await logFile.writeAsString(buffer.toString(), mode: FileMode.append);
    } catch (e) {
      logError('Failed to write log entries', e);
    }
  }

  @override
  Future<List<LogEntry>> readEntries() async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        return [];
      }

      final content = await logFile.readAsString();
      return _parseLogEntries(content);
    } catch (e) {
      logError('Failed to read log entries', e);
      return [];
    }
  }

  @override
  Future<String> readAsString() async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        return 'Log file does not exist';
      }

      return await logFile.readAsString();
    } catch (e) {
      logError('Failed to read log file', e);
      return 'Error reading log file: $e';
    }
  }

  @override
  Future<int> getFileSize() async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        return 0;
      }

      return await logFile.length();
    } catch (e) {
      logError('Failed to get log file size', e);
      return 0;
    }
  }

  @override
  Future<void> clear() async {
    if (_logFilePath == null) {
      await initialize();
    }

    try {
      final logFile = File(_logFilePath!);
      await logFile.writeAsString(_getLogHeader());
      logInfo('Log file cleared');
    } catch (e) {
      logError('Failed to clear log file', e);
      throw StorageException(
        'Failed to clear log file: ${e.toString()}',
        originalError: e,
      );
    }
  }

  List<LogEntry> _parseLogEntries(String content) {
    // Simple parser - in production, you might want a more robust parser
    // For now, we'll just return empty list as entries are stored in memory
    // and file is for human-readable format
    return [];
  }
}
