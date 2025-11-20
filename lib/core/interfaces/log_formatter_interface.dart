import '../models/log_entry.dart';

/// Interface for formatting log entries (SOLID - Interface Segregation)
abstract class ILogFormatter {
  /// Format a log entry to string
  String format(LogEntry entry);

  /// Format multiple log entries
  String formatMultiple(List<LogEntry> entries);
}

