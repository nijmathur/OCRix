import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../utils/json_converters.dart';

part 'document_page.freezed.dart';
part 'document_page.g.dart';

@freezed
abstract class DocumentPage with _$DocumentPage {
  const DocumentPage._();

  const factory DocumentPage({
    required String id,
    required String documentId,
    required int pageNumber,
    @Uint8ListConverter() Uint8List? imageData,
    @Uint8ListConverter() Uint8List? thumbnailData,
    @Default('jpeg') String imageFormat,
    int? imageSize,
    int? imageWidth,
    int? imageHeight,
    required String extractedText,
    required double confidenceScore,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DocumentPage;

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

  factory DocumentPage.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageFromJson(json);
}
