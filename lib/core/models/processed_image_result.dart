/// Result of image processing
class ProcessedImageResult {
  final List<int> imageBytes;
  final List<int>? thumbnailBytes;
  final int? width;
  final int? height;
  final int size;
  final int? thumbnailSize;
  final String format;

  const ProcessedImageResult({
    required this.imageBytes,
    this.thumbnailBytes,
    this.width,
    this.height,
    required this.size,
    this.thumbnailSize,
    this.format = 'jpeg',
  });
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({required this.width, required this.height});
}
