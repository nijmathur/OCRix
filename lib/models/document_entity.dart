/// Document Entity Model
/// Represents extracted structured data from document OCR text
library;

import 'package:equatable/equatable.dart';

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
class DocumentEntity extends Equatable {
  /// The document ID this entity belongs to
  final String documentId;

  /// Extracted vendor/merchant name (e.g., "Kroger", "CVS Pharmacy")
  final String? vendor;

  /// Extracted monetary amount (e.g., 47.52)
  final double? amount;

  /// Extracted transaction date
  final DateTime? transactionDate;

  /// Inferred category based on content
  final EntityCategory? category;

  /// Confidence score of the extraction (0.0 - 1.0)
  final double confidence;

  /// When the entity was extracted
  final DateTime extractedAt;

  const DocumentEntity({
    required this.documentId,
    this.vendor,
    this.amount,
    this.transactionDate,
    this.category,
    required this.confidence,
    required this.extractedAt,
  });

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

  /// Create a copy with updated fields
  DocumentEntity copyWith({
    String? documentId,
    String? vendor,
    double? amount,
    DateTime? transactionDate,
    EntityCategory? category,
    double? confidence,
    DateTime? extractedAt,
  }) {
    return DocumentEntity(
      documentId: documentId ?? this.documentId,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      extractedAt: extractedAt ?? this.extractedAt,
    );
  }

  @override
  List<Object?> get props => [
    documentId,
    vendor,
    amount,
    transactionDate,
    category,
    confidence,
    extractedAt,
  ];

  @override
  String toString() {
    return 'DocumentEntity('
        'documentId: $documentId, '
        'vendor: $vendor, '
        'amount: $amount, '
        'transactionDate: $transactionDate, '
        'category: ${category?.name}, '
        'confidence: $confidence)';
  }
}
