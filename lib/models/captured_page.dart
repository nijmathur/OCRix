import 'dart:typed_data';
import '../core/interfaces/image_enhancement_service_interface.dart';

/// Represents a captured page during the scanning workflow
class CapturedPage {
  final String id;
  final int pageNumber;
  final String imagePath;
  Uint8List? imageBytes;
  Uint8List? enhancedImageBytes;
  ImageEnhancementOptions? enhancementOptions;
  bool isEnhanced;

  CapturedPage({
    required this.id,
    required this.pageNumber,
    required this.imagePath,
    this.imageBytes,
    this.enhancedImageBytes,
    this.enhancementOptions,
    this.isEnhanced = false,
  });

  CapturedPage copyWith({
    String? id,
    int? pageNumber,
    String? imagePath,
    Uint8List? imageBytes,
    Uint8List? enhancedImageBytes,
    ImageEnhancementOptions? enhancementOptions,
    bool? isEnhanced,
  }) {
    return CapturedPage(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      enhancedImageBytes: enhancedImageBytes ?? this.enhancedImageBytes,
      enhancementOptions: enhancementOptions ?? this.enhancementOptions,
      isEnhanced: isEnhanced ?? this.isEnhanced,
    );
  }
}
