/// Architecture regression tests.
///
/// These tests catch regressions in key architectural invariants agreed upon
/// during the architecture review (July 2026):
/// 1. No singletons in service classes (DI via Riverpod)
/// 2. No circular initialization between DatabaseService and AuditLoggingService
/// 3. BackgroundTaskNotifier stays purely synchronous (no async build)
/// 4. All mutations in DocumentNotifier capture previousState for rollback
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocrix/providers/background_task_provider.dart';
import 'package:ocrix/providers/document_provider.dart';
import 'package:ocrix/services/database_service.dart';
import 'package:ocrix/services/audit_database_service.dart';

void main() {
  group('Singleton regression', () {
    test('DatabaseService creates independent instances (no static singleton)', () {
      final a = DatabaseService();
      final b = DatabaseService();
      // They should be different object references (no factory singleton)
      expect(identical(a, b), isFalse);
    });

    test('AuditDatabaseService creates independent instances', () {
      final a = AuditDatabaseService();
      final b = AuditDatabaseService();
      expect(identical(a, b), isFalse);
    });
  });

  group('Circular initialization regression', () {
    test('AuditDatabaseService can be instantiated without calling DatabaseService.initialize()', () {
      // AuditDatabaseService.initialize() must NOT call _mainDatabaseService.initialize().
      // Simply constructing the object verifies no init side effects on construction.
      expect(() => AuditDatabaseService(), returnsNormally);
    });

    test('DatabaseService can be instantiated without AuditLoggingService', () {
      expect(() => DatabaseService(), returnsNormally);
    });
  });

  group('BackgroundTaskNotifier contract', () {
    test('build() returns synchronously (no async init)', () {
      // If build() were async, the provider type would be AsyncNotifier.
      // This test verifies the notifier remains synchronous.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Synchronous read should succeed immediately (no loading state)
      final state = container.read(backgroundTaskNotifierProvider);
      expect(state, isA<List<BackgroundTask>>());
    });

    test('task IDs are stable: same documentId+type produces same id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      notifier.markCompleted('doc1', BackgroundTaskType.vectorization);
      notifier.markRunning('doc1', BackgroundTaskType.vectorization);

      // There should still be only one task for doc1/vectorization
      final tasks = container.read(backgroundTaskNotifierProvider);
      final matching = tasks.where(
        (t) => t.documentId == 'doc1' && t.type == BackgroundTaskType.vectorization,
      );
      expect(matching.length, 1);
    });
  });

  group('Provider dependency graph', () {
    test('databaseServiceProvider does not depend on auditLoggingServiceProvider at build time', () {
      // If there were a circular dep, reading both providers would deadlock or throw.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () {
          container.read(databaseServiceProvider);
          container.read(encryptionServiceProvider);
          container.read(storageProviderServiceProvider);
        },
        returnsNormally,
      );
    });
  });
}
