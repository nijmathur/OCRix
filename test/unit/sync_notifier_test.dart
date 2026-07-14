/// SyncNotifier state transition tests.
///
/// Verifies that:
/// 1. Initial state is idle
/// 2. manualSync() transitions idle → syncing → idle on success
/// 3. manualSync() transitions idle → syncing → error on failure
/// 4. A second manualSync() call while already syncing is a no-op
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/providers/sync_provider.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/models/audit_log.dart';
import 'package:ocrix/core/models/audit_log_level.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSyncQueueService mockSyncService;
  late MockTroubleshootingLogger mockLogger;
  late MockAuditDatabaseService mockAuditDb;

  setUpAll(() {
    registerFallbackValue(AuditEntry.create(
      level: AuditLogLevel.info,
      action: AuditAction.create,
      resourceType: 'document',
      resourceId: 'fallback',
      userId: 'test',
    ));
  });

  setUp(() {
    mockSyncService = MockSyncQueueService();
    mockLogger = MockTroubleshootingLogger();
    mockAuditDb = MockAuditDatabaseService();

    when(() => mockLogger.info(any(), tag: any(named: 'tag'), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'), error: any(named: 'error'), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => mockLogger.error(any(), tag: any(named: 'tag'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => mockAuditDb.initialize()).thenAnswer((_) async {});
    when(() => mockAuditDb.getLastEntry()).thenAnswer((_) async => null);
    when(() => mockAuditDb.insertAuditEntry(any())).thenAnswer((_) async => 'id');
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        syncQueueServiceProvider.overrideWithValue(mockSyncService),
      ],
    );
  }

  group('SyncNotifier initial state', () {
    test('starts idle', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.phase, SyncPhase.idle);
      expect(state.lastError, isNull);
      expect(state.lastSyncedAt, isNull);
    });
  });

  group('SyncNotifier.manualSync()', () {
    test('transitions to idle with lastSyncedAt on success', () async {
      when(() => mockSyncService.processQueue()).thenAnswer((_) async => 2);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(syncProvider.notifier).manualSync();

      final state = container.read(syncProvider);
      expect(state.phase, SyncPhase.idle);
      expect(state.lastSyncedAt, isNotNull);
      expect(state.lastError, isNull);
    });

    test('transitions to error state when processQueue throws', () async {
      when(() => mockSyncService.processQueue())
          .thenThrow(Exception('network unreachable'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(syncProvider.notifier).manualSync();

      final state = container.read(syncProvider);
      expect(state.phase, SyncPhase.error);
      expect(state.lastError, contains('network unreachable'));
    });

    test('second call while syncing is a no-op (processQueue called once)', () async {
      // Make processQueue take long enough that we can call manualSync twice
      var callCount = 0;
      when(() => mockSyncService.processQueue()).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 0;
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      // Fire two concurrent calls
      final f1 = container.read(syncProvider.notifier).manualSync();
      final f2 = container.read(syncProvider.notifier).manualSync();
      await Future.wait([f1, f2]);

      // processQueue should only have been called once
      expect(callCount, equals(1));
    });
  });
}
