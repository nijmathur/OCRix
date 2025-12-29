// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentPage _$DocumentPageFromJson(Map<String, dynamic> json) => DocumentPage(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      imageData:
          const Uint8ListConverter().fromJson(json['imageData'] as String?),
      originalImageData: const Uint8ListConverter()
          .fromJson(json['originalImageData'] as String?),
      thumbnailData:
          const Uint8ListConverter().fromJson(json['thumbnailData'] as String?),
      imageFormat: json['imageFormat'] as String? ?? 'jpeg',
      imageSize: (json['imageSize'] as num?)?.toInt(),
      imageWidth: (json['imageWidth'] as num?)?.toInt(),
      imageHeight: (json['imageHeight'] as num?)?.toInt(),
      extractedText: json['extractedText'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isEnhanced: json['isEnhanced'] as bool? ?? false,
      enhancementMetadata:
          json['enhancementMetadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$DocumentPageToJson(DocumentPage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'documentId': instance.documentId,
      'pageNumber': instance.pageNumber,
      'imageData': const Uint8ListConverter().toJson(instance.imageData),
      'originalImageData':
          const Uint8ListConverter().toJson(instance.originalImageData),
      'thumbnailData':
          const Uint8ListConverter().toJson(instance.thumbnailData),
      'imageFormat': instance.imageFormat,
      'imageSize': instance.imageSize,
      'imageWidth': instance.imageWidth,
      'imageHeight': instance.imageHeight,
      'extractedText': instance.extractedText,
      'confidenceScore': instance.confidenceScore,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isEnhanced': instance.isEnhanced,
      'enhancementMetadata': instance.enhancementMetadata,
    };
