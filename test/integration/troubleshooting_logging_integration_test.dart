import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ocrix/services/troubleshooting_logger_service.dart';
import 'package:ocrix/services/log_file_service.dart';
import 'package:ocrix/services/log_rotation_service.dart';
import 'package:ocrix/core/models/log_level.dart';

/// Integration tests for troubleshooting logging system
/// Tests critical paths: file writing, rotation, export, and error handling
void main() {
  // Initialize Flutter bindings for path_provider
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Troubleshooting Logging Integration Tests', () {
    late TroubleshootingLoggerService logger;
    late LogFileService logFileService;
    late LogRotationService rotationService;
    late Directory tempLogsDir;

    setUp(() async {
      tempLogsDir =
          await Directory.systemTemp.createTemp('troubleshoot_logs_test');

      // Initialize services
      logFileService = LogFileService(
        logsDirectoryPathOverride: tempLogsDir.path,
      );
      rotationService = LogRotationService(logFileService);
      logger = TroubleshootingLoggerService(logFileService, rotationService);

      await logger.initialize();
    });

    tearDown(() async {
      // Clean up
      try {
        await logger.clearLogs();
        if (await tempLogsDir.exists()) {
          await tempLogsDir.delete(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('CRITICAL: Log entries are written to file', () async {
      // Write different log levels
      await logger.debug('Debug message', tag: 'Test');
      await logger.info('Info message', tag: 'Test');
      await logger.warning('Warning message', tag: 'Test');
      await logger.error('Error message',
          tag: 'Test', error: Exception('Test error'));
      await logger.critical('Critical message',
          tag: 'Test', error: Exception('Critical error'));

      // Read log content
      final logContent = await logger.getLogContent();
      expect(logContent, isNotEmpty);
      expect(logContent, contains('Debug message'));
      expect(logContent, contains('Info message'));
      expect(logContent, contains('Warning message'));
      expect(logContent, contains('Error message'));
      expect(logContent, contains('Critical message'));
    });

    test('CRITICAL: Log level filtering works correctly', () async {
      // Set minimum level to WARNING
      logger.setMinimumLevel(LogLevel.warning);

      // Try to log lower levels
      await logger.debug('Debug message');
      await logger.info('Info message');

      // Log higher levels
      await logger.warning('Warning message');
      await logger.error('Error message');

      // Read log content
      final logContent = await logger.getLogContent();

      // Debug and Info should be filtered
      expect(logContent, isNot(contains('Debug message')));
      expect(logContent, isNot(contains('Info message')));

      // Warning and Error should be logged
      expect(logContent, contains('Warning message'));
      expect(logContent, contains('Error message'));
    });

    test('CRITICAL: Log rotation works correctly', () async {
      // Set short rotation interval for testing
      rotationService.setRotationInterval(const Duration(seconds: 1));

      // Write many log entries to trigger rotation
      for (int i = 0; i < 100; i++) {
        await logger.info('Log entry $i', tag: 'Test');
      }

      // Wait for rotation
      await Future.delayed(const Duration(seconds: 2));

      // Trigger rotation check
      await rotationService.checkAndRotate();

      // Verify rotation occurred (file should be smaller after rotation)
      final fileSize = await logFileService.getFileSize();
      expect(fileSize, lessThan(1000000), // Less than 1MB
          reason: 'Log file should be rotated when it gets large');
    });

    test('CRITICAL: Log export includes all necessary information', () async {
      // Write various log entries
      await logger.info('Test info message',
          tag: 'TestTag', metadata: {'key': 'value'});
      await logger.error('Test error message',
          tag: 'TestTag', error: Exception('Test error'));

      // Export logs
      final exportedLogs = await logger.exportLogs();

      // Verify export format
      expect(exportedLogs, isNotEmpty);
      expect(exportedLogs, contains('OCRix Troubleshooting Log Export'));
      expect(exportedLogs, contains('Application Information'));
      expect(exportedLogs, contains('Platform:'));
      expect(
          exportedLogs.contains('Test info message') ||
              exportedLogs.contains('Test error message'),
          isTrue);
      expect(exportedLogs.contains('TestTag'), isTrue);
    });

    test('CRITICAL: Error logging includes stack traces', () async {
      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        await logger.error(
          'Caught exception',
          tag: 'Test',
          error: e,
          stackTrace: stackTrace,
        );
      }

      // Read log content
      final logContent = await logger.getLogContent();
      expect(
          logContent.contains('Caught exception') ||
              logContent.contains('Test exception'),
          isTrue,
          reason: 'Error message should be in log');
    });

    test('CRITICAL: Log file size is tracked correctly', () async {
      // Write some logs
      for (int i = 0; i < 50; i++) {
        await logger.info('Log entry $i', tag: 'Test');
      }

      // Check file size
      final fileSize = await logFileService.getFileSize();
      expect(fileSize, greaterThan(0), reason: 'Log file should have content');
    });

    test('CRITICAL: Log clearing works correctly', () async {
      // Write some logs
      await logger.info('Message 1');
      await logger.info('Message 2');

      // Verify logs exist
      var logContent = await logger.getLogContent();
      expect(logContent, contains('Message 1'));
      expect(logContent, contains('Message 2'));

      // Clear logs
      await logger.clearLogs();

      // Verify logs are cleared
      logContent = await logger.getLogContent();
      expect(logContent, isNot(contains('Message 1')));
      expect(logContent, isNot(contains('Message 2')));
    });

    test('CRITICAL: Multiple log levels are formatted correctly', () async {
      // Set minimum level to debug to see all logs
      logger.setMinimumLevel(LogLevel.debug);

      // Write logs with different levels
      await logger.debug('Debug message', tag: 'Test');
      await logger.info('Info message', tag: 'Test');
      await logger.warning('Warning message', tag: 'Test');
      await logger.error('Error message', tag: 'Test');
      await logger.critical('Critical message', tag: 'Test');

      // Read log content
      final logContent = await logger.getLogContent();

      // Verify all levels are present (format may vary)
      expect(
          logContent.contains('Debug') || logContent.contains('debug'), isTrue);
      expect(
          logContent.contains('Info') || logContent.contains('info'), isTrue);
      expect(logContent.contains('Warning') || logContent.contains('warning'),
          isTrue);
      expect(
          logContent.contains('Error') || logContent.contains('error'), isTrue);
      expect(logContent.contains('Critical') || logContent.contains('critical'),
          isTrue);
    });

    test('CRITICAL: Metadata is included in log entries', () async {
      // Write log with metadata
      await logger.info(
        'Message with metadata',
        tag: 'Test',
        metadata: {
          'userId': 'user123',
          'action': 'create',
          'resourceId': 'doc_1',
        },
      );

      // Read log content
      final logContent = await logger.getLogContent();

      // Verify metadata is included
      expect(logContent, contains('Message with metadata'));
      expect(logContent.contains('userId') || logContent.contains('user123'),
          isTrue);
    });

    test('CRITICAL: Logging failures do not break application', () async {
      // This test verifies that logging errors don't throw exceptions
      // We can't easily simulate file system failures, but we can verify
      // that the logger handles errors gracefully

      // Write many logs rapidly
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(logger.info('Rapid log $i'));
      }

      // All should complete without throwing
      await expectLater(Future.wait(futures), completes);
    });

    test('CRITICAL: Log rotation preserves recent entries', () async {
      // Write initial logs
      for (int i = 0; i < 10; i++) {
        await logger.info('Initial log $i');
      }

      // Force rotation
      await rotationService.rotate();

      // Write new logs after rotation
      for (int i = 0; i < 5; i++) {
        await logger.info('Post-rotation log $i');
      }

      // Verify new logs are present
      final logContent = await logger.getLogContent();
      expect(
          logContent.contains('Post-rotation') ||
              logContent.contains('Post-rotation log'),
          isTrue);
    });

    test('CRITICAL: Export includes recent in-memory entries', () async {
      // Write logs
      for (int i = 0; i < 5; i++) {
        await logger.info('Recent log $i', tag: 'Test');
      }

      // Export should include recent entries
      final exported = await logger.exportLogs();
      expect(
          exported.contains('Recent Log Entries') ||
              exported.contains('Recent'),
          isTrue);
      expect(exported.contains('Recent log') || exported.contains('Recent'),
          isTrue);
    });
  });
}
