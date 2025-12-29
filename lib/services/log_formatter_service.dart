import 'dart:convert';
import '../core/interfaces/log_formatter_interface.dart';
import '../core/models/log_entry.dart';
import '../core/models/log_level.dart';

/// Service for formatting log entries (SOLID - Single Responsibility)
class LogFormatterService implements ILogFormatter {
  final bool _includeEmoji;
  final bool _includeMetadata;
  final bool _includeStackTrace;

  const LogFormatterService({
    bool includeEmoji = true,
    bool includeMetadata = true,
    bool includeStackTrace = true,
  }) : _includeEmoji = includeEmoji,
       _includeMetadata = includeMetadata,
       _includeStackTrace = includeStackTrace;

  @override
  String format(LogEntry entry) {
    final buffer = StringBuffer();

    // Timestamp
    final timestamp = _formatTimestamp(entry.timestamp);
    buffer.write('[$timestamp] ');

    // Level with emoji
    if (_includeEmoji) {
      buffer.write('${entry.level.emoji} ');
    }
    buffer.write(entry.level.name);

    // Tag
    if (entry.tag != null) {
      buffer.write(' [${entry.tag}]');
    }

    // Message
    buffer.write(': ${entry.message}');

    // Error
    if (entry.error != null) {
      buffer.write('\n  Error: ${entry.error}');
    }

    // Stack trace
    if (entry.stackTrace != null && _includeStackTrace) {
      buffer.write('\n  Stack Trace:\n${_formatStackTrace(entry.stackTrace!)}');
    }

    // Metadata
    if (entry.metadata != null &&
        entry.metadata!.isNotEmpty &&
        _includeMetadata) {
      buffer.write('\n  Metadata: ${_formatMetadata(entry.metadata!)}');
    }

    return buffer.toString();
  }

  @override
  String formatMultiple(List<LogEntry> entries) {
    if (entries.isEmpty) return 'No log entries';

    final buffer = StringBuffer();
    buffer.writeln('=' * 80);
    buffer.writeln('LOG ENTRIES (${entries.length} total)');
    buffer.writeln('=' * 80);
    buffer.writeln();

    for (final entry in entries) {
      buffer.writeln(format(entry));
      buffer.writeln('- ' * 40);
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${_pad(timestamp.month)}-${_pad(timestamp.day)} '
        '${_pad(timestamp.hour)}:${_pad(timestamp.minute)}:${_pad(timestamp.second)}.${_pad(timestamp.millisecond, 3)}';
  }

  String _pad(int value, [int length = 2]) {
    return value.toString().padLeft(length, '0');
  }

  String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    // Limit stack trace to first 20 lines for readability
    final limitedLines = lines.take(20).toList();
    return limitedLines.map((line) => '    $line').join('\n');
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    try {
      return const JsonEncoder.withIndent('  ').convert(metadata);
    } catch (e) {
      return metadata.toString();
    }
  }
}
