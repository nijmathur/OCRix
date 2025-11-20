import 'package:equatable/equatable.dart';
import 'log_level.dart';

/// Represents a single log entry
class LogEntry extends Equatable {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final String? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.metadata,
  });

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

  @override
  List<Object?> get props => [
        timestamp,
        level,
        message,
        tag,
        error,
        stackTrace,
        metadata,
      ];
}

