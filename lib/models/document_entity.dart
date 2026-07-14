/// Document Entity Model
/// Represents extracted structured data from document OCR text
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_entity.freezed.dart';

/// Entity categories for document classification
enum EntityCategory {
  grocery,
  restaurant,
  medical,
  pharmacy,
  utilities,
  fuel,
  entertainment,
  retail,
  services,
  travel,
  financial,
  other;

  static EntityCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return EntityCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Represents extracted entity data from a document
@freezed
abstract class DocumentEntity with _$DocumentEntity {
  const DocumentEntity._();

  const factory DocumentEntity({
    required String documentId,
    String? vendor,
    double? amount,
    DateTime? transactionDate,
    EntityCategory? category,
    required double confidence,
    required DateTime extractedAt,
  }) = _DocumentEntity;

  /// Create an empty entity for documents where extraction failed
  factory DocumentEntity.empty(String documentId) {
    return DocumentEntity(
      documentId: documentId,
      confidence: 0.0,
      extractedAt: DateTime.now(),
    );
  }

  /// Create from database map
  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      documentId: map['document_id'] as String? ?? map['id'] as String,
      vendor: map['vendor'] as String?,
      amount: map['amount'] as double?,
      transactionDate: map['transaction_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['transaction_date'] as int)
          : null,
      category: EntityCategory.fromString(map['category'] as String?),
      confidence: (map['entity_confidence'] as num?)?.toDouble() ?? 0.0,
      extractedAt: map['entities_extracted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['entities_extracted_at'] as int,
            )
          : DateTime.now(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'vendor': vendor,
      'amount': amount,
      'transaction_date': transactionDate?.millisecondsSinceEpoch,
      'category': category?.name,
      'entity_confidence': confidence,
      'entities_extracted_at': extractedAt.millisecondsSinceEpoch,
    };
  }

  /// Check if entity has any meaningful data
  bool get hasData =>
      vendor != null ||
      amount != null ||
      transactionDate != null ||
      category != null;
}
