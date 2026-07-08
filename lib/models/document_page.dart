import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

import '../utils/json_converters.dart';

part 'document_page.g.dart';

@JsonSerializable()
class DocumentPage extends Equatable {
  final String id;
  final String documentId;
  final int pageNumber;
  @Uint8ListConverter()
  final Uint8List? imageData;
  @Uint8ListConverter()
  final Uint8List? thumbnailData;
  final String imageFormat;
  final int? imageSize;
  final int? imageWidth;
  final int? imageHeight;
  final String extractedText;
  final double confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentPage({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    this.imageData,
    this.thumbnailData,
    this.imageFormat = 'jpeg',
    this.imageSize,
    this.imageWidth,
    this.imageHeight,
    required this.extractedText,
    required this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentPage.create({
    required String documentId,
    required int pageNumber,
    Uint8List? imageData,
    Uint8List? thumbnailData,
    String imageFormat = 'jpeg',
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    required String extractedText,
    required double confidenceScore,
  }) {
    final now = DateTime.now();
    return DocumentPage(
      id: const Uuid().v4(),
      documentId: documentId,
      pageNumber: pageNumber,
      imageData: imageData,
      thumbnailData: thumbnailData,
      imageFormat: imageFormat,
      imageSize: imageSize,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      extractedText: extractedText,
      confidenceScore: confidenceScore,
      createdAt: now,
      updatedAt: now,
    );
  }

  DocumentPage copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    Uint8List? imageData,
    Uint8List? thumbnailData,
    String? imageFormat,
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    String? extractedText,
    double? confidenceScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageData: imageData ?? this.imageData,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      imageFormat: imageFormat ?? this.imageFormat,
      imageSize: imageSize ?? this.imageSize,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      extractedText: extractedText ?? this.extractedText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DocumentPage.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentPageToJson(this);

  @override
  List<Object?> get props => [
    id,
    documentId,
    pageNumber,
    imageData,
    thumbnailData,
    imageFormat,
    imageSize,
    imageWidth,
    imageHeight,
    extractedText,
    confidenceScore,
    createdAt,
    updatedAt,
  ];
}
