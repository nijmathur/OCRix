import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'document.dart';

/// Lightweight document model for list views (without full image data)
class DocumentSummary extends Equatable {
  final String id;
  final String title;
  final Uint8List? thumbnailData; // Only thumbnail, not full image
  final String imageFormat;
  final DocumentType type;
  final DateTime scanDate;
  final List<String> tags;
  final double confidenceScore;
  final String detectedLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEncrypted;

  const DocumentSummary({
    required this.id,
    required this.title,
    this.thumbnailData,
    this.imageFormat = 'jpeg',
    required this.type,
    required this.scanDate,
    required this.tags,
    required this.confidenceScore,
    required this.detectedLanguage,
    required this.createdAt,
    required this.updatedAt,
    required this.isEncrypted,
  });

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

  @override
  List<Object?> get props => [
        id,
        title,
        thumbnailData,
        imageFormat,
        type,
        scanDate,
        tags,
        confidenceScore,
        detectedLanguage,
        createdAt,
        updatedAt,
        isEncrypted,
      ];
}

