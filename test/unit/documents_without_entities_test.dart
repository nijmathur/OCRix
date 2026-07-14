/// Tests for DocumentEntity.hasData and EntityCategory.fromString.
///
/// Verifies that the hasData predicate correctly identifies documents that
/// have no extractable entity fields, preventing unnecessary DB writes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ocrix/models/document_entity.dart';

void main() {
  group('DocumentEntity.hasData', () {
    test('empty() factory returns hasData = false', () {
      final entity = DocumentEntity.empty('doc1');
      expect(entity.hasData, isFalse);
    });

    test('entity with only documentId and confidence has no data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        confidence: 0.0,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isFalse);
    });

    test('entity with vendor has data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        vendor: 'Kroger',
        confidence: 0.6,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isTrue);
    });

    test('entity with amount has data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        amount: 25.99,
        confidence: 0.6,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isTrue);
    });

    test('entity with transactionDate has data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        transactionDate: DateTime(2024, 3, 15),
        confidence: 0.6,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isTrue);
    });

    test('entity with category has data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        category: EntityCategory.grocery,
        confidence: 0.6,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isTrue);
    });

    test('entity with all fields has data', () {
      final entity = DocumentEntity(
        documentId: 'doc1',
        vendor: 'Starbucks',
        amount: 4.50,
        transactionDate: DateTime(2024, 6, 1),
        category: EntityCategory.restaurant,
        confidence: 0.85,
        extractedAt: DateTime.now(),
      );
      expect(entity.hasData, isTrue);
    });
  });

  group('EntityCategory.fromString', () {
    test('returns correct category for exact name match', () {
      expect(EntityCategory.fromString('grocery'), EntityCategory.grocery);
      expect(EntityCategory.fromString('restaurant'), EntityCategory.restaurant);
      expect(EntityCategory.fromString('medical'), EntityCategory.medical);
      expect(EntityCategory.fromString('pharmacy'), EntityCategory.pharmacy);
      expect(EntityCategory.fromString('fuel'), EntityCategory.fuel);
      expect(EntityCategory.fromString('financial'), EntityCategory.financial);
      expect(EntityCategory.fromString('travel'), EntityCategory.travel);
      expect(EntityCategory.fromString('other'), EntityCategory.other);
    });

    test('is case-insensitive', () {
      expect(EntityCategory.fromString('GROCERY'), EntityCategory.grocery);
      expect(EntityCategory.fromString('Restaurant'), EntityCategory.restaurant);
    });

    test('returns null for unknown string', () {
      expect(EntityCategory.fromString('unknown_category'), isNull);
      expect(EntityCategory.fromString(''), isNull);
    });

    test('returns null for null input', () {
      expect(EntityCategory.fromString(null), isNull);
    });
  });

  group('DocumentEntity equality (freezed)', () {
    test('two identical empty entities are equal', () {
      final now = DateTime(2024, 1, 1);
      final a = DocumentEntity(
        documentId: 'doc1',
        confidence: 0.0,
        extractedAt: now,
      );
      final b = DocumentEntity(
        documentId: 'doc1',
        confidence: 0.0,
        extractedAt: now,
      );
      expect(a, equals(b));
    });

    test('copyWith preserves hasData correctly', () {
      final base = DocumentEntity.empty('doc1');
      expect(base.hasData, isFalse);

      final withVendor = base.copyWith(vendor: 'Amazon', confidence: 0.9);
      expect(withVendor.hasData, isTrue);
    });
  });
}
