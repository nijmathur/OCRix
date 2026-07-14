import 'package:flutter_test/flutter_test.dart';
import 'package:ocrix/core/models/log_entry.dart';
import 'package:ocrix/core/models/log_level.dart';
import 'package:ocrix/services/log_formatter_service.dart';

void main() {
  group('LogFormatterService', () {
    final timestamp = DateTime(2026, 1, 15, 10, 30, 45, 123);

    test('formats basic info entry', () {
      const formatter = LogFormatterService();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'Test message',
      );

      final result = formatter.format(entry);

      expect(result, contains('[2026-01-15 10:30:45.123]'));
      expect(result, contains('INFO'));
      expect(result, contains('Test message'));
    });

    test('includes emoji by default', () {
      const formatter = LogFormatterService();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.error,
        message: 'Error occurred',
      );

      final result = formatter.format(entry);
      expect(result, contains(LogLevel.error.emoji));
    });

    test('excludes emoji when disabled', () {
      const formatter = LogFormatterService(includeEmoji: false);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.error,
        message: 'Error occurred',
      );

      final result = formatter.format(entry);
      expect(result, isNot(contains(LogLevel.error.emoji)));
    });

    test('includes tag when present', () {
      const formatter = LogFormatterService();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'Tagged message',
        tag: 'MyService',
      );

      final result = formatter.format(entry);
      expect(result, contains('[MyService]'));
    });

    test('includes error when present', () {
      const formatter = LogFormatterService();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.error,
        message: 'Something failed',
        error: 'NullPointerException',
      );

      final result = formatter.format(entry);
      expect(result, contains('Error: NullPointerException'));
    });

    test('includes metadata when present and enabled', () {
      const formatter = LogFormatterService();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'With metadata',
        metadata: {'key': 'value', 'count': 42},
      );

      final result = formatter.format(entry);
      expect(result, contains('Metadata:'));
      expect(result, contains('"key"'));
      expect(result, contains('"value"'));
    });

    test('excludes metadata when disabled', () {
      const formatter = LogFormatterService(includeMetadata: false);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'With metadata',
        metadata: {'key': 'value'},
      );

      final result = formatter.format(entry);
      expect(result, isNot(contains('Metadata:')));
    });

    test('formatMultiple returns message for empty list', () {
      const formatter = LogFormatterService();
      expect(formatter.formatMultiple([]), 'No log entries');
    });

    test('formatMultiple includes all entries', () {
      const formatter = LogFormatterService();
      final entries = [
        LogEntry(
          timestamp: timestamp,
          level: LogLevel.info,
          message: 'First',
        ),
        LogEntry(
          timestamp: timestamp,
          level: LogLevel.warning,
          message: 'Second',
        ),
      ];

      final result = formatter.formatMultiple(entries);
      expect(result, contains('LOG ENTRIES (2 total)'));
      expect(result, contains('First'));
      expect(result, contains('Second'));
    });

    test('all log levels have correct names', () {
      expect(LogLevel.debug.name, 'DEBUG');
      expect(LogLevel.info.name, 'INFO');
      expect(LogLevel.warning.name, 'WARNING');
      expect(LogLevel.error.name, 'ERROR');
      expect(LogLevel.critical.name, 'CRITICAL');
    });

    test('log level priorities are ordered', () {
      expect(LogLevel.debug.priority, lessThan(LogLevel.info.priority));
      expect(LogLevel.info.priority, lessThan(LogLevel.warning.priority));
      expect(LogLevel.warning.priority, lessThan(LogLevel.error.priority));
      expect(LogLevel.error.priority, lessThan(LogLevel.critical.priority));
    });

    test('shouldLog respects minimum level', () {
      expect(LogLevel.error.shouldLog(LogLevel.warning), true);
      expect(LogLevel.debug.shouldLog(LogLevel.warning), false);
      expect(LogLevel.warning.shouldLog(LogLevel.warning), true);
    });
  });
}
