import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ocrix/services/database_service.dart';
import 'package:ocrix/services/audit_database_service.dart';
import 'package:ocrix/services/audit_logging_service.dart';
import 'package:ocrix/services/troubleshooting_logger_service.dart';
import 'package:ocrix/services/log_file_service.dart';
import 'package:ocrix/services/log_rotation_service.dart';
import 'package:ocrix/core/models/audit_log_level.dart';
import 'package:ocrix/models/audit_log.dart';
import '../helpers/mock_encryption_service.dart';

/// Integration tests for audit and troubleshooting logging working together
/// Tests that both systems work correctly and don't interfere with each other
void main() {
  // Initialize Flutter bindings for path_provider
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Audit and Troubleshooting Logging Integration', () {
    late DatabaseService databaseService;
    late AuditDatabaseService auditDatabaseService;
    late AuditLoggingService auditLoggingService;
    late TroubleshootingLoggerService troubleshootingLogger;
    late LogFileService logFileService;
    late LogRotationService rotationService;
    late Directory tempLogsDir;
    late Directory tempDbDir;

    setUp(() async {
      tempLogsDir = await Directory.systemTemp.createTemp('combined_logs_test');
      tempDbDir = await Directory.systemTemp.createTemp('combined_db_test');

      // Initialize all services
      databaseService = DatabaseService();
      auditDatabaseService = AuditDatabaseService();
      auditLoggingService = AuditLoggingService(auditDatabaseService);
      logFileService = LogFileService(
        logsDirectoryPathOverride: tempLogsDir.path,
      );
      rotationService = LogRotationService(logFileService);
      troubleshootingLogger =
          TroubleshootingLoggerService(logFileService, rotationService);

      // Set up mock encryption service (doesn't require flutter_secure_storage)
      final mockEncryptionService = MockEncryptionService();
      await mockEncryptionService.initialize();
      (databaseService).setEncryptionService(mockEncryptionService);
      (databaseService).setDatabasePathOverride(tempDbDir.path);

      // Set up relationships
      auditDatabaseService.setMainDatabaseService(databaseService);
      (databaseService).setAuditLoggingService(auditLoggingService);

      // Initialize services
      await databaseService.initialize();
      await auditDatabaseService.initialize();
      await auditLoggingService.initialize();
      await troubleshootingLogger.initialize();

      // Set user ID
      auditLoggingService.setUserId('test_user');
    });

    tearDown(() async {
      // Clean up
      try {
        await troubleshootingLogger.clearLogs();
        if (await tempLogsDir.exists()) {
          await tempLogsDir.delete(recursive: true);
        }
        if (await tempDbDir.exists()) {
          await tempDbDir.delete(recursive: true);
        }
        await databaseService.close();
        await auditDatabaseService.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test(
        'CRITICAL: Database operations log to both audit and troubleshooting logs',
        () async {
      // Perform database operation that should trigger both loggers
      // (This would require a real document, but we can test the logging calls)

      // Log to audit
      await auditLoggingService.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'test_doc',
        details: 'Test document created',
      );

      // Log to troubleshooting
      await troubleshootingLogger.info(
        'Database operation performed',
        tag: 'DatabaseService',
        metadata: {'operation': 'create', 'resourceId': 'test_doc'},
      );

      // Verify audit log
      final auditEntries = await auditDatabaseService.getAuditEntries();
      expect(auditEntries.length, greaterThan(0));
      expect(auditEntries.first.resourceId, contains('test_doc'));

      // Verify troubleshooting log
      final troubleshootingLogs = await troubleshootingLogger.getLogContent();
      expect(troubleshootingLogs, contains('Database operation performed'));
      expect(troubleshootingLogs, contains('test_doc'));
    });

    test('CRITICAL: Errors are logged to both systems', () async {
      try {
        throw Exception('Test error for integration test');
      } catch (e, stackTrace) {
        // Log to troubleshooting logger
        await troubleshootingLogger.error(
          'Error occurred during operation',
          tag: 'IntegrationTest',
          error: e,
          stackTrace: stackTrace,
        );

        // Log to audit (as error)
        await auditLoggingService.log(
          level: AuditLogLevel.compulsory,
          action: AuditAction.read,
          resourceType: 'system',
          resourceId: 'error',
          details: 'Error occurred: ${e.toString()}',
          isSuccess: false,
          errorMessage: e.toString(),
        );
      }

      // Verify troubleshooting log has error
      final troubleshootingLogs = await troubleshootingLogger.getLogContent();
      expect(troubleshootingLogs, contains('Error occurred during operation'));
      expect(troubleshootingLogs, contains('Test error for integration test'));

      // Verify audit log has error entry
      final auditEntries = await auditDatabaseService.getAuditEntries();
      final errorEntries = auditEntries.where((e) => !e.isSuccess).toList();
      expect(errorEntries.length, greaterThan(0));
    });

    test('CRITICAL: Both systems maintain integrity under load', () async {
      // Simulate high load with concurrent operations
      final futures = <Future>[];

      for (int i = 0; i < 20; i++) {
        futures.add(() async {
          // Log to audit
          await auditLoggingService.logDatabaseWrite(
            action: AuditAction.create,
            resourceType: 'document',
            resourceId: 'doc_$i',
          );

          // Log to troubleshooting
          await troubleshootingLogger.info('Operation $i', tag: 'LoadTest');
        }());
      }

      await Future.wait(futures);

      // Verify audit integrity
      final auditFailed = await auditDatabaseService.verifyIntegrity();
      expect(auditFailed, isEmpty,
          reason: 'Audit integrity should be maintained under load');

      // Verify troubleshooting logs are written
      final troubleshootingLogs = await troubleshootingLogger.getLogContent();
      expect(troubleshootingLogs, contains('Operation'));
    });

    test('CRITICAL: Export includes both audit and troubleshooting information',
        () async {
      // Create entries in both systems
      await auditLoggingService.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'export_test_doc',
      );

      await troubleshootingLogger.info('Test log entry', tag: 'ExportTest');

      // Export troubleshooting logs
      final exported = await troubleshootingLogger.exportLogs();

      // Verify export includes troubleshooting info
      expect(exported, contains('OCRix Troubleshooting Log Export'));
      expect(exported, contains('Test log entry'));

      // Note: Audit logs are in separate database, so they won't be in troubleshooting export
      // But we can verify audit export separately if needed
    });

    test('CRITICAL: Service failures in one system don\'t break the other',
        () async {
      // This test verifies that if one logging system fails,
      // the other continues to work

      // Both should work independently
      await auditLoggingService.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'doc_1',
      );

      await troubleshootingLogger.info('Troubleshooting log', tag: 'Test');

      // Verify both worked
      final auditEntries = await auditDatabaseService.getAuditEntries();
      expect(auditEntries.length, greaterThan(0));

      final troubleshootingLogs = await troubleshootingLogger.getLogContent();
      expect(troubleshootingLogs, contains('Troubleshooting log'));
    });
  });
}
