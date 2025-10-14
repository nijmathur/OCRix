// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
      id: json['id'] as String,
      title: json['title'] as String,
      imagePath: json['imagePath'] as String,
      extractedText: json['extractedText'] as String,
      type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
      scanDate: DateTime.parse(json['scanDate'] as String),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>,
      storageProvider: json['storageProvider'] as String,
      isEncrypted: json['isEncrypted'] as bool,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      detectedLanguage: json['detectedLanguage'] as String,
      deviceInfo: json['deviceInfo'] as String,
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool,
      cloudId: json['cloudId'] as String?,
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
    );

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imagePath': instance.imagePath,
      'extractedText': instance.extractedText,
      'type': _$DocumentTypeEnumMap[instance.type]!,
      'scanDate': instance.scanDate.toIso8601String(),
      'tags': instance.tags,
      'metadata': instance.metadata,
      'storageProvider': instance.storageProvider,
      'isEncrypted': instance.isEncrypted,
      'confidenceScore': instance.confidenceScore,
      'detectedLanguage': instance.detectedLanguage,
      'deviceInfo': instance.deviceInfo,
      'notes': instance.notes,
      'location': instance.location,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'cloudId': instance.cloudId,
      'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.receipt: 'receipt',
  DocumentType.contract: 'contract',
  DocumentType.manual: 'manual',
  DocumentType.invoice: 'invoice',
  DocumentType.businessCard: 'businessCard',
  DocumentType.id: 'id',
  DocumentType.passport: 'passport',
  DocumentType.license: 'license',
  DocumentType.certificate: 'certificate',
  DocumentType.other: 'other',
};
