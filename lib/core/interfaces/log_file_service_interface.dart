import '../models/log_entry.dart';

/// Interface for log file operations (SOLID - Interface Segregation)
abstract class ILogFileService {
  /// Write a log entry to file
  Future<void> writeEntry(LogEntry entry);

  /// Write multiple log entries to file
  Future<void> writeEntries(List<LogEntry> entries);

  /// Read all log entries from file
  Future<List<LogEntry>> readEntries();

  /// Read log entries as formatted string
  Future<String> readAsString();

  /// Get current log file path
  String get currentLogFilePath;

  /// Get log file size in bytes
  Future<int> getFileSize();

  /// Clear log file
  Future<void> clear();

  /// Initialize the service
  Future<void> initialize();
}
