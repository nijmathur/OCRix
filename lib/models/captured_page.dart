import 'dart:typed_data';

/// Represents a captured page during the scanning workflow
class CapturedPage {
  final String id;
  final int pageNumber;
  final String imagePath;
  Uint8List? imageBytes;

  CapturedPage({
    required this.id,
    required this.pageNumber,
    required this.imagePath,
    this.imageBytes,
  });

  CapturedPage copyWith({
    String? id,
    int? pageNumber,
    String? imagePath,
    Uint8List? imageBytes,
  }) {
    return CapturedPage(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
