/// Result of image processing
class ProcessedImageResult {
  final List<int> imageBytes;
  final int? width;
  final int? height;
  final int size;
  final String format;

  const ProcessedImageResult({
    required this.imageBytes,
    this.width,
    this.height,
    required this.size,
    this.format = 'jpeg',
  });
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({
    required this.width,
    required this.height,
  });
}
