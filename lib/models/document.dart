import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:convert';

part 'document.g.dart';

class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return Uint8List.fromList(base64Decode(json));
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return base64Encode(object);
  }
}

@JsonSerializable()
class Document extends Equatable {
  final String id;
  final String title;
  @Uint8ListConverter()
  final Uint8List? imageData;
  @Uint8ListConverter()
  final Uint8List? thumbnailData;
  final String imageFormat;
  final int? imageSize;
  final int? imageWidth;
  final int? imageHeight;
  final String? imagePath; // Keep for backward compatibility
  final String extractedText;
  final DocumentType type;
  final DateTime scanDate;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String storageProvider;
  final bool isEncrypted;
  final double confidenceScore;
  final String detectedLanguage;
  final String deviceInfo;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cloudId;
  final DateTime? lastSyncedAt;
  final bool isMultiPage;
  final int pageCount;

  // Entity extraction fields (for NLP querying)
  final String? vendor;
  final double? amount;
  final DateTime? transactionDate;
  final String? category;
  final double entityConfidence;
  final DateTime? entitiesExtractedAt;

  const Document({
    required this.id,
    required this.title,
    this.imageData,
    this.thumbnailData,
    this.imageFormat = 'jpeg',
    this.imageSize,
    this.imageWidth,
    this.imageHeight,
    this.imagePath,
    required this.extractedText,
    required this.type,
    required this.scanDate,
    required this.tags,
    required this.metadata,
    required this.storageProvider,
    required this.isEncrypted,
    required this.confidenceScore,
    required this.detectedLanguage,
    required this.deviceInfo,
    this.notes,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.cloudId,
    this.lastSyncedAt,
    this.isMultiPage = false,
    this.pageCount = 1,
    this.vendor,
    this.amount,
    this.transactionDate,
    this.category,
    this.entityConfidence = 0.0,
    this.entitiesExtractedAt,
  });

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
    bool isEncrypted = false, // Changed to false since we're storing in DB now
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

  Document copyWith({
    String? id,
    String? title,
    Uint8List? imageData,
    Uint8List? thumbnailData,
    String? imageFormat,
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    String? imagePath,
    String? extractedText,
    DocumentType? type,
    DateTime? scanDate,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? storageProvider,
    bool? isEncrypted,
    double? confidenceScore,
    String? detectedLanguage,
    String? deviceInfo,
    String? notes,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? cloudId,
    DateTime? lastSyncedAt,
    bool? isMultiPage,
    int? pageCount,
    String? vendor,
    double? amount,
    DateTime? transactionDate,
    String? category,
    double? entityConfidence,
    DateTime? entitiesExtractedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      imageData: imageData ?? this.imageData,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      imageFormat: imageFormat ?? this.imageFormat,
      imageSize: imageSize ?? this.imageSize,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      type: type ?? this.type,
      scanDate: scanDate ?? this.scanDate,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      storageProvider: storageProvider ?? this.storageProvider,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cloudId: cloudId ?? this.cloudId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isMultiPage: isMultiPage ?? this.isMultiPage,
      pageCount: pageCount ?? this.pageCount,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      entityConfidence: entityConfidence ?? this.entityConfidence,
      entitiesExtractedAt: entitiesExtractedAt ?? this.entitiesExtractedAt,
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
      metadata: map['metadata'] != null &&
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
          ? DateTime.fromMillisecondsSinceEpoch(map['entities_extracted_at'] as int)
          : null,
    );
  }

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    imageData,
    thumbnailData,
    imageFormat,
    imageSize,
    imageWidth,
    imageHeight,
    imagePath,
    extractedText,
    type,
    scanDate,
    tags,
    metadata,
    storageProvider,
    isEncrypted,
    confidenceScore,
    detectedLanguage,
    deviceInfo,
    notes,
    location,
    createdAt,
    updatedAt,
    isSynced,
    cloudId,
    lastSyncedAt,
    isMultiPage,
    pageCount,
    vendor,
    amount,
    transactionDate,
    category,
    entityConfidence,
    entitiesExtractedAt,
  ];

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
  String get displayName {
    switch (this) {
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.contract:
        return 'Contract';
      case DocumentType.manual:
        return 'Manual';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.businessCard:
        return 'Business Card';
      case DocumentType.id:
        return 'ID Document';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.license:
        return 'License';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case DocumentType.receipt:
        return 'receipt';
      case DocumentType.contract:
        return 'description';
      case DocumentType.manual:
        return 'menu_book';
      case DocumentType.invoice:
        return 'request_quote';
      case DocumentType.businessCard:
        return 'contact_page';
      case DocumentType.id:
        return 'badge';
      case DocumentType.passport:
        return 'travel_explore';
      case DocumentType.license:
        return 'card_membership';
      case DocumentType.certificate:
        return 'workspace_premium';
      case DocumentType.other:
        return 'insert_drive_file';
    }
  }
}
