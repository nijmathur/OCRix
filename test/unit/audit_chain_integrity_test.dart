/// Audit chain integrity tests.
///
/// Verifies that AuditEntry:
/// 1. Produces a valid SHA-256 checksum on creation
/// 2. Detects tampered fields via checksum mismatch
/// 3. Links entries in a verifiable chain (previousEntryId + previousChecksum)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ocrix/models/audit_entry.dart';
import 'package:ocrix/models/audit_log.dart';
import 'package:ocrix/core/models/audit_log_level.dart';

AuditEntry _makeEntry({
  String resourceId = 'doc1',
  String? previousEntryId,
  String? previousChecksum,
}) =>
    AuditEntry.create(
      level: AuditLogLevel.info,
      action: AuditAction.create,
      resourceType: 'document',
      resourceId: resourceId,
      userId: 'user1',
      details: 'test entry',
      previousEntryId: previousEntryId,
      previousChecksum: previousChecksum,
    );

void main() {
  group('AuditEntry checksum', () {
    test('create() produces a passing verifyChecksum()', () {
      final entry = _makeEntry();
      expect(entry.verifyChecksum(), isTrue);
    });

    test('checksum is non-empty', () {
      final entry = _makeEntry();
      expect(entry.checksum, isNotEmpty);
    });

    test('two entries created independently have different checksums', () {
      final a = _makeEntry(resourceId: 'doc1');
      final b = _makeEntry(resourceId: 'doc2');
      expect(a.checksum, isNot(b.checksum));
    });

    test('mutating details invalidates checksum', () {
      final entry = _makeEntry();
      final tampered = entry.copyWith(details: 'hacked payload');
      expect(tampered.verifyChecksum(), isFalse);
    });

    test('mutating userId invalidates checksum', () {
      final entry = _makeEntry();
      final tampered = entry.copyWith(userId: 'attacker');
      expect(tampered.verifyChecksum(), isFalse);
    });

    test('mutating action invalidates checksum', () {
      final entry = _makeEntry();
      final tampered = entry.copyWith(action: AuditAction.delete);
      expect(tampered.verifyChecksum(), isFalse);
    });

    test('mutating isSuccess invalidates checksum', () {
      final entry = _makeEntry();
      final tampered = entry.copyWith(isSuccess: false);
      expect(tampered.verifyChecksum(), isFalse);
    });
  });

  group('AuditEntry chain linking', () {
    test('first entry (no previous) passes verifyChain with null', () {
      final entry = _makeEntry();
      expect(entry.previousEntryId, isNull);
      expect(entry.verifyChain(null), isTrue);
    });

    test('first entry passes verifyChain with any string (no previous to compare)', () {
      final entry = _makeEntry();
      expect(entry.verifyChain('any_checksum'), isTrue);
    });

    test('chained entry passes verifyChain with correct previous checksum', () {
      final first = _makeEntry(resourceId: 'doc1');
      final second = _makeEntry(
        resourceId: 'doc2',
        previousEntryId: first.id,
        previousChecksum: first.checksum,
      );
      expect(second.verifyChain(first.checksum), isTrue);
    });

    test('chained entry fails verifyChain when previous checksum is wrong', () {
      final first = _makeEntry(resourceId: 'doc1');
      final second = _makeEntry(
        resourceId: 'doc2',
        previousEntryId: first.id,
        previousChecksum: first.checksum,
      );
      expect(second.verifyChain('wrong_checksum'), isFalse);
    });

    test('three-entry chain: all links verify correctly', () {
      final e1 = _makeEntry(resourceId: 'r1');
      final e2 = _makeEntry(
        resourceId: 'r2',
        previousEntryId: e1.id,
        previousChecksum: e1.checksum,
      );
      final e3 = _makeEntry(
        resourceId: 'r3',
        previousEntryId: e2.id,
        previousChecksum: e2.checksum,
      );

      expect(e1.verifyChecksum(), isTrue);
      expect(e2.verifyChecksum(), isTrue);
      expect(e3.verifyChecksum(), isTrue);

      expect(e2.verifyChain(e1.checksum), isTrue);
      expect(e3.verifyChain(e2.checksum), isTrue);
    });

    test('attacker replacing e1 checksum breaks chain verification of second', () {
      final e1 = _makeEntry(resourceId: 'r1');
      final e2 = _makeEntry(
        resourceId: 'r2',
        previousEntryId: e1.id,
        previousChecksum: e1.checksum,
      );

      // An attacker tampers e1 data and must replace its checksum.
      // The replacement checksum differs from e1.checksum, so
      // e2.verifyChain(attackerChecksum) → false.
      const attackerChecksum =
          'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
      expect(e2.verifyChain(attackerChecksum), isFalse);
    });

    test('copyWith without recalculating checksum is detectable via verifyChecksum', () {
      // An attacker who uses copyWith to mutate a field without recalculating
      // the checksum leaves stale checksum data — detectable via verifyChecksum().
      final e1 = _makeEntry(resourceId: 'r1');
      final tamperedE1 = e1.copyWith(details: 'hacked payload');
      expect(tamperedE1.verifyChecksum(), isFalse);
    });
  });
}
