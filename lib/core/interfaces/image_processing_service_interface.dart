/// Interface for image processing operations
abstract class IImageProcessingService {
  /// Process image for optimal storage in database
  /// Returns processed image bytes, dimensions, and metadata
  Future<ProcessedImageResult> processImageForStorage(List<int> imageBytes);

  /// Resize image if too large
  Future<List<int>> resizeImageIfNeeded(
    List<int> imageBytes, {
    int maxWidth = 1920,
    int maxHeight = 1920,
  });

  /// Get image dimensions
  Future<ImageDimensions?> getImageDimensions(List<int> imageBytes);

  /// Compress image to JPEG
  Future<List<int>> compressToJpeg(
    List<int> imageBytes, {
    int quality = 85,
  });
}

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

