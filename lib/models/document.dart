import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

part 'document.g.dart';

@JsonSerializable()
class Document extends Equatable {
  final String id;
  final String title;
  final String imagePath;
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

  const Document({
    required this.id,
    required this.title,
    required this.imagePath,
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
  });

  factory Document.create({
    required String title,
    required String imagePath,
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
    bool isEncrypted = true,
  }) {
    final now = DateTime.now();
    return Document(
      id: const Uuid().v4(),
      title: title,
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
    );
  }

  Document copyWith({
    String? id,
    String? title,
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
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
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
    );
  }

  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
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
      ];
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
