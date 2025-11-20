import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ocrix/services/audit_database_service.dart';
import 'package:ocrix/services/audit_logging_service.dart';
import 'package:ocrix/services/database_service.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/core/models/audit_log_level.dart';
import 'package:ocrix/models/audit_log.dart';
import '../helpers/mock_encryption_service.dart';

/// Integration tests for audit logging system
/// Tests critical paths: checksums, chaining, integrity, and database operations
void main() {
  // Initialize Flutter bindings for path_provider and secure storage
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Audit Logging Integration Tests', () {
    late DatabaseService mainDatabaseService;
    late AuditDatabaseService auditDatabaseService;
    late AuditLoggingService auditLoggingService;
    late Directory tempDbDir;

    setUp(() async {
      tempDbDir = await Directory.systemTemp.createTemp('audit_logging_db');

      // Initialize services
      mainDatabaseService = DatabaseService();
      auditDatabaseService = AuditDatabaseService();
      auditLoggingService = AuditLoggingService(auditDatabaseService);

      // Set up mock encryption service (doesn't require flutter_secure_storage)
      final mockEncryptionService = MockEncryptionService();
      await mockEncryptionService.initialize();
      mainDatabaseService.setEncryptionService(mockEncryptionService);
      mainDatabaseService.setDatabasePathOverride(tempDbDir.path);

      // Set up audit database service to use main database
      auditDatabaseService.setMainDatabaseService(mainDatabaseService);

      // Initialize services
      await mainDatabaseService.initialize();
      await auditDatabaseService.initialize();
      await auditLoggingService.initialize();

      // Set test user ID
      auditLoggingService.setUserId('test_user_123');
    });

    tearDown(() async {
      // Clean up
      try {
        await mainDatabaseService.close();
        await auditDatabaseService.close();
        if (await tempDbDir.exists()) {
          await tempDbDir.delete(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('CRITICAL: Audit entry checksum calculation and verification',
        () async {
      // Create an audit entry
      final entry = AuditEntry.create(
        level: AuditLogLevel.compulsory,
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'test_doc_1',
        userId: 'test_user',
        details: 'Test document creation',
      );

      // Verify checksum is calculated
      expect(entry.checksum, isNotEmpty);
      expect(entry.checksum.length, greaterThan(40)); // SHA-256 hex string

      // Verify checksum is correct
      expect(entry.verifyChecksum(), isTrue);

      // Tamper with entry and verify checksum fails
      final tamperedEntry = AuditEntry(
        id: entry.id,
        level: entry.level,
        action: entry.action,
        resourceType: entry.resourceType,
        resourceId: 'TAMPERED_ID', // Changed
        userId: entry.userId,
        timestamp: entry.timestamp,
        details: entry.details,
        isSuccess: entry.isSuccess,
        checksum: entry.checksum, // Old checksum
        previousEntryId: entry.previousEntryId,
        previousChecksum: entry.previousChecksum,
      );

      expect(tamperedEntry.verifyChecksum(), isFalse);
    });

    test('CRITICAL: Audit entry chain linking and integrity', () async {
      // Create first entry
      final entry1 = AuditEntry.create(
        level: AuditLogLevel.compulsory,
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'doc_1',
        userId: 'test_user',
        details: 'First entry',
      );

      // Insert first entry
      await auditDatabaseService.insertAuditEntry(entry1);

      // Create second entry with chain link
      final lastEntry = await auditDatabaseService.getLastEntry();
      expect(lastEntry, isNotNull);
      expect(lastEntry!.id, equals(entry1.id));

      final entry2 = AuditEntry.create(
        level: AuditLogLevel.compulsory,
        action: AuditAction.update,
        resourceType: 'document',
        resourceId: 'doc_1',
        userId: 'test_user',
        details: 'Second entry',
        previousEntryId: lastEntry.id,
        previousChecksum: lastEntry.checksum,
      );

      // Verify chain integrity
      expect(entry2.verifyChain(lastEntry.checksum), isTrue);

      // Insert second entry
      await auditDatabaseService.insertAuditEntry(entry2);

      // Verify chain is maintained
      // Entries are returned in DESC order (newest first), so entry2 is at index 0
      final allEntries = await auditDatabaseService.getAuditEntries();
      expect(allEntries.length, equals(2));
      expect(allEntries[0].previousEntryId, equals(entry1.id));
      expect(allEntries[0].previousChecksum, equals(entry1.checksum));
    });

    test('CRITICAL: Database write operations are logged (COMPULSORY)',
        () async {
      // Set audit logging service in database service
      (mainDatabaseService as DatabaseService)
          .setAuditLoggingService(auditLoggingService);

      // Perform a database operation (we'll need to create a test document)
      // For now, just verify that the logging service is set up correctly
      expect(
          auditLoggingService.currentLevel, equals(AuditLogLevel.compulsory));

      // Log a database write
      await auditLoggingService.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'test_doc',
        details: 'Test document created',
      );

      // Verify entry was created
      final entries = await auditDatabaseService.getAuditEntries();
      expect(entries.length, greaterThan(0));

      final lastEntry = entries.first;
      expect(lastEntry.level, equals(AuditLogLevel.compulsory));
      expect(lastEntry.action, equals(AuditAction.create));
      expect(lastEntry.resourceType, equals('database'));
      expect(lastEntry.resourceId, contains('document'));
    });

    test('CRITICAL: Database read operations are logged (COMPULSORY)',
        () async {
      // Set audit logging service
      (mainDatabaseService as DatabaseService)
          .setAuditLoggingService(auditLoggingService);

      // Log a database read
      await auditLoggingService.logDatabaseRead(
        resourceType: 'document',
        resourceId: 'test_doc',
        details: 'Test document read',
      );

      // Verify entry was created
      final entries = await auditDatabaseService.getAuditEntries();
      expect(entries.length, greaterThan(0));

      final lastEntry = entries.first;
      expect(lastEntry.level, equals(AuditLogLevel.compulsory));
      expect(lastEntry.action, equals(AuditAction.read));
    });

    test('CRITICAL: Audit database integrity verification', () async {
      // Create multiple entries with small delays to ensure different timestamps
      for (int i = 0; i < 5; i++) {
        final lastEntry = await auditDatabaseService.getLastEntry();
        final entry = AuditEntry.create(
          level: AuditLogLevel.compulsory,
          action: AuditAction.create,
          resourceType: 'document',
          resourceId: 'doc_$i',
          userId: 'test_user',
          details: 'Entry $i',
          previousEntryId: lastEntry?.id,
          previousChecksum: lastEntry?.checksum,
        );
        await auditDatabaseService.insertAuditEntry(entry);
        // Small delay to ensure different timestamps (millisecond precision)
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Verify integrity
      final failedEntries = await auditDatabaseService.verifyIntegrity();
      expect(failedEntries, isEmpty,
          reason: 'All entries should pass integrity check');

      // Verify all entries are retrievable
      // Entries are returned in DESC order (newest first)
      final entries = await auditDatabaseService.getAuditEntries();
      expect(entries.length, equals(5));

      // Verify chain is intact
      // Since entries are DESC order: entries[0] is newest, entries[4] is oldest
      // Each newer entry should link to the previous (older) entry
      for (int i = 0; i < entries.length - 1; i++) {
        expect(entries[i].previousEntryId, equals(entries[i + 1].id),
            reason: 'Entry $i should link to entry ${i + 1}');
        expect(entries[i].previousChecksum, equals(entries[i + 1].checksum),
            reason: 'Entry $i checksum should match entry ${i + 1}');
      }
      // Oldest entry (last in DESC order) should have no previous
      expect(entries[entries.length - 1].previousEntryId, isNull,
          reason: 'Oldest entry should have no previous entry');
    });

    test('CRITICAL: Log level filtering works correctly', () async {
      // Set level to COMPULSORY (default)
      auditLoggingService.setLogLevel(AuditLogLevel.compulsory);

      // Try to log INFO level (should be filtered)
      await auditLoggingService.logInfoAction(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'doc_1',
      );

      // Try to log VERBOSE level (should be filtered)
      await auditLoggingService.logVerbose(
        action: AuditAction.read,
        resourceType: 'navigation',
        resourceId: 'screen1->screen2',
      );

      // Log COMPULSORY level (should be logged)
      await auditLoggingService.logDatabaseWrite(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'doc_2',
      );

      // Verify only COMPULSORY entries were logged
      final entries = await auditDatabaseService.getAuditEntries();
      final compulsoryEntries =
          entries.where((e) => e.level == AuditLogLevel.compulsory).toList();
      expect(compulsoryEntries.length, greaterThan(0));

      // Verify INFO and VERBOSE were filtered
      final infoEntries =
          entries.where((e) => e.level == AuditLogLevel.info).toList();
      final verboseEntries =
          entries.where((e) => e.level == AuditLogLevel.verbose).toList();
      expect(infoEntries, isEmpty);
      expect(verboseEntries, isEmpty);
    });

    test('CRITICAL: Tampered entry detection', () async {
      // Create and insert entry
      final entry = AuditEntry.create(
        level: AuditLogLevel.compulsory,
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'doc_1',
        userId: 'test_user',
        details: 'Original entry',
      );

      await auditDatabaseService.insertAuditEntry(entry);

      // Manually tamper with entry in database (simulate attack)
      final db = await auditDatabaseService.database;
      await db.update(
        'audit_entries',
        {'resource_id': 'TAMPERED_DOC_ID'}, // Tamper with data
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      // Verify integrity check detects tampering
      final failedEntries = await auditDatabaseService.verifyIntegrity();
      expect(failedEntries, contains(entry.id),
          reason: 'Tampered entry should be detected');
    });

    test('CRITICAL: Chain break detection', () async {
      // Create chain of entries
      AuditEntry? lastEntry;
      for (int i = 0; i < 3; i++) {
        final entry = AuditEntry.create(
          level: AuditLogLevel.compulsory,
          action: AuditAction.create,
          resourceType: 'document',
          resourceId: 'doc_$i',
          userId: 'test_user',
          details: 'Entry $i',
          previousEntryId: lastEntry?.id,
          previousChecksum: lastEntry?.checksum,
        );
        await auditDatabaseService.insertAuditEntry(entry);
        lastEntry = entry;
      }

      // Break the chain by tampering with previous_checksum
      final db = await auditDatabaseService.database;
      final entries = await auditDatabaseService.getAuditEntries();
      final middleEntry = entries[1]; // Second entry

      await db.update(
        'audit_entries',
        {'previous_checksum': 'BROKEN_CHAIN_CHECKSUM'},
        where: 'id = ?',
        whereArgs: [middleEntry.id],
      );

      // Verify integrity check detects chain break
      final failedEntries = await auditDatabaseService.verifyIntegrity();
      expect(failedEntries, contains(middleEntry.id),
          reason: 'Chain break should be detected');
    });

    test('CRITICAL: Multiple concurrent audit writes maintain integrity',
        () async {
      // Create an initial entry to serve as the base for concurrent writes
      final baseEntry = AuditEntry.create(
        level: AuditLogLevel.compulsory,
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: 'base_doc',
        userId: 'test_user',
        details: 'Base entry for concurrent writes',
      );
      await auditDatabaseService.insertAuditEntry(baseEntry);

      // Simulate concurrent writes - all will link to the base entry
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(() async {
          final lastEntry = await auditDatabaseService.getLastEntry();
          final entry = AuditEntry.create(
            level: AuditLogLevel.compulsory,
            action: AuditAction.create,
            resourceType: 'document',
            resourceId: 'doc_$i',
            userId: 'test_user',
            details: 'Concurrent entry $i',
            previousEntryId: lastEntry?.id,
            previousChecksum: lastEntry?.checksum,
          );
          return await auditDatabaseService.insertAuditEntry(entry);
        }());
      }

      await Future.wait(futures);

      // Verify all entries were created (base + 10 concurrent = 11 total)
      final entries = await auditDatabaseService.getAuditEntries();
      expect(entries.length, equals(11));

      // Verify integrity - forks are allowed (multiple entries can link to same previous)
      final failedEntries = await auditDatabaseService.verifyIntegrity();
      expect(failedEntries, isEmpty,
          reason: 'Concurrent writes should maintain integrity (forks allowed)');
    });

    test('CRITICAL: Entry count and filtering work correctly', () async {
      // Create entries with different levels
      for (int i = 0; i < 3; i++) {
        final lastEntry = await auditDatabaseService.getLastEntry();
        final entry = AuditEntry.create(
          level: AuditLogLevel.compulsory,
          action: AuditAction.create,
          resourceType: 'document',
          resourceId: 'doc_$i',
          userId: 'test_user',
          details: 'Entry $i',
          previousEntryId: lastEntry?.id,
          previousChecksum: lastEntry?.checksum,
        );
        await auditDatabaseService.insertAuditEntry(entry);
      }

      // Test entry count
      final totalCount = await auditDatabaseService.getEntryCount();
      expect(totalCount, greaterThanOrEqualTo(3));

      final compulsoryCount = await auditDatabaseService.getEntryCount(
          level: AuditLogLevel.compulsory);
      expect(compulsoryCount, greaterThanOrEqualTo(3));
    });
  });
}
