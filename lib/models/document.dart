import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../utils/json_converters.dart';

part 'document.freezed.dart';
part 'document.g.dart';

@freezed
abstract class Document with _$Document {
  const Document._();

  const factory Document({
    required String id,
    required String title,
    @Uint8ListConverter() Uint8List? imageData,
    @Uint8ListConverter() Uint8List? thumbnailData,
    @Default('jpeg') String imageFormat,
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    String? imagePath,
    required String extractedText,
    required DocumentType type,
    required DateTime scanDate,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    required String storageProvider,
    required bool isEncrypted,
    required double confidenceScore,
    required String detectedLanguage,
    required String deviceInfo,
    String? notes,
    String? location,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isSynced,
    String? cloudId,
    DateTime? lastSyncedAt,
    @Default(false) bool isMultiPage,
    @Default(1) int pageCount,
    // Entity extraction fields (for NLP querying)
    String? vendor,
    double? amount,
    DateTime? transactionDate,
    String? category,
    @Default(0.0) double entityConfidence,
    DateTime? entitiesExtractedAt,
  }) = _Document;

  factory Document.create({
    required String title,
    String? imagePath,
    Uint8List? imageData,
    Uint8List? thumbnailData,
    String imageFormat = 'jpeg',
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    required String extractedText,
    required DocumentType type,
    required double confidenceScore,
    required String detectedLanguage,
    required String deviceInfo,
    String? notes,
    String? location,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
    String storageProvider = 'local',
    bool isEncrypted = false,
    bool isMultiPage = false,
    int pageCount = 1,
  }) {
    final now = DateTime.now();
    return Document(
      id: const Uuid().v4(),
      title: title,
      imageData: imageData,
      thumbnailData: thumbnailData,
      imageFormat: imageFormat,
      imageSize: imageSize,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imagePath: imagePath,
      extractedText: extractedText,
      type: type,
      scanDate: now,
      tags: tags,
      metadata: metadata,
      storageProvider: storageProvider,
      isEncrypted: isEncrypted,
      confidenceScore: confidenceScore,
      detectedLanguage: detectedLanguage,
      deviceInfo: deviceInfo,
      notes: notes,
      location: location,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      isMultiPage: isMultiPage,
      pageCount: pageCount,
    );
  }

  /// Create Document from database map (snake_case columns)
  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      imageData: map['image_data'] as Uint8List?,
      thumbnailData: map['thumbnail_data'] as Uint8List?,
      imageFormat: map['image_format'] ?? 'jpeg',
      imageSize: map['image_size'] as int?,
      imageWidth: map['image_width'] as int?,
      imageHeight: map['image_height'] as int?,
      imagePath: map['image_path'],
      extractedText: map['extracted_text'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scan_date']),
      tags: (map['tags'] as String?)?.split(',') ?? [],
      metadata:
          map['metadata'] != null &&
              map['metadata'] is String &&
              (map['metadata'] as String).isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'] as String))
          : const {},
      storageProvider: map['storage_provider'],
      isEncrypted: map['is_encrypted'] == 1,
      confidenceScore: map['confidence_score'],
      detectedLanguage: map['detected_language'],
      deviceInfo: map['device_info'],
      notes: map['notes'],
      location: map['location'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      cloudId: map['cloud_id'],
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_synced_at'])
          : null,
      isMultiPage: (map['is_multi_page'] ?? 0) == 1,
      pageCount: map['page_count'] ?? 1,
      // Entity extraction fields
      vendor: map['vendor'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
      transactionDate: map['transaction_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['transaction_date'] as int)
          : null,
      category: map['category'] as String?,
      entityConfidence: (map['entity_confidence'] as num?)?.toDouble() ?? 0.0,
      entitiesExtractedAt: map['entities_extracted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['entities_extracted_at'] as int,
            )
          : null,
    );
  }

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  /// Check if entity data has been extracted
  bool get hasEntityData => entitiesExtractedAt != null;

  /// Check if document has meaningful entity data
  bool get hasEntities =>
      vendor != null ||
      amount != null ||
      transactionDate != null ||
      category != null;
}

enum DocumentType {
  receipt,
  contract,
  manual,
  invoice,
  businessCard,
  id,
  passport,
  license,
  certificate,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName => switch (this) {
    DocumentType.receipt => 'Receipt',
    DocumentType.contract => 'Contract',
    DocumentType.manual => 'Manual',
    DocumentType.invoice => 'Invoice',
    DocumentType.businessCard => 'Business Card',
    DocumentType.id => 'ID Document',
    DocumentType.passport => 'Passport',
    DocumentType.license => 'License',
    DocumentType.certificate => 'Certificate',
    DocumentType.other => 'Other',
  };

  String get iconName => switch (this) {
    DocumentType.receipt => 'receipt',
    DocumentType.contract => 'description',
    DocumentType.manual => 'menu_book',
    DocumentType.invoice => 'request_quote',
    DocumentType.businessCard => 'contact_page',
    DocumentType.id => 'badge',
    DocumentType.passport => 'travel_explore',
    DocumentType.license => 'card_membership',
    DocumentType.certificate => 'workspace_premium',
    DocumentType.other => 'insert_drive_file',
  };
}
