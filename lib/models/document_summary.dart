import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'document.dart';

part 'document_summary.freezed.dart';

/// Lightweight document model for list views (without full image data)
@freezed
abstract class DocumentSummary with _$DocumentSummary {
  const DocumentSummary._();

  const factory DocumentSummary({
    required String id,
    required String title,
    Uint8List? thumbnailData,
    @Default('jpeg') String imageFormat,
    required DocumentType type,
    required DateTime scanDate,
    required List<String> tags,
    required double confidenceScore,
    required String detectedLanguage,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isEncrypted,
  }) = _DocumentSummary;

  /// Convert from full Document (for backward compatibility)
  factory DocumentSummary.fromDocument(Document document) {
    return DocumentSummary(
      id: document.id,
      title: document.title,
      thumbnailData: document.thumbnailData,
      imageFormat: document.imageFormat,
      type: document.type,
      scanDate: document.scanDate,
      tags: document.tags,
      confidenceScore: document.confidenceScore,
      detectedLanguage: document.detectedLanguage,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      isEncrypted: document.isEncrypted,
    );
  }

  /// Convert to full Document (lazy load full image data)
  Document toDocument({
    Uint8List? imageData,
    String? extractedText,
    Map<String, dynamic>? metadata,
    String? notes,
    String? location,
  }) {
    return Document(
      id: id,
      title: title,
      imageData: imageData,
      thumbnailData: thumbnailData,
      imageFormat: imageFormat,
      type: type,
      scanDate: scanDate,
      tags: tags,
      metadata: metadata ?? {},
      storageProvider: 'local',
      isEncrypted: isEncrypted,
      confidenceScore: confidenceScore,
      detectedLanguage: detectedLanguage,
      deviceInfo: '',
      extractedText: extractedText ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: false,
    );
  }
}
