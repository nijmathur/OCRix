import 'package:freezed_annotation/freezed_annotation.dart';

import 'log_level.dart';

part 'log_entry.freezed.dart';

/// Represents a single log entry
@freezed
abstract class LogEntry with _$LogEntry {
  const LogEntry._();

  const factory LogEntry({
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    String? tag,
    String? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) = _LogEntry;

  factory LogEntry.create({
    required LogLevel level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error?.toString(),
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }
}
