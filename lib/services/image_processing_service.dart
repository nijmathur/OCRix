import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/interfaces/image_processing_service_interface.dart';
import '../core/models/processed_image_result.dart';
import '../core/base/base_service.dart';
import '../core/config/app_config.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for image processing operations
class ImageProcessingService extends BaseService
    implements IImageProcessingService {
  @override
  String get serviceName => 'ImageProcessingService';

  @override
  Future<ProcessedImageResult> processImageForStorage(
      List<int> imageBytes) async {
    try {
      logInfo('Processing image for storage: ${imageBytes.length} bytes');

      // Use isolate for CPU-intensive image processing
      final result = await compute(_processImageInIsolate, imageBytes);

      logInfo(
          'Image processed: ${result.size} bytes (thumbnail: ${result.thumbnailSize} bytes), ${result.width}x${result.height}');

      return result;
    } catch (e, stackTrace) {
      logError('Failed to process image for storage', e);
      // compute() may throw the exception from isolate, but we need to wrap it
      if (e.toString().contains('Failed to decode image') ||
          e.toString().contains('ImageProcessingException')) {
        throw ImageProcessingException(
          e.toString(),
          originalError: e,
          stackTrace: stackTrace,
        );
      }
      throw ImageProcessingException(
        'Failed to process image: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Static function for isolate processing
  /// Note: Exceptions thrown here will be caught by compute() and rethrown
  static ProcessedImageResult _processImageInIsolate(List<int> imageBytes) {
    // Decode image
    final image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if too large
    img.Image processedImage = image;
    if (image.width > AppConfig.maxImageWidth ||
        image.height > AppConfig.maxImageHeight) {
      final scale = image.width > image.height
          ? AppConfig.maxImageWidth / image.width
          : AppConfig.maxImageHeight / image.height;

      processedImage = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
    }

    // Convert to JPEG with configured quality
    final processedBytes =
        img.encodeJpg(processedImage, quality: AppConfig.storageQuality);
    final processedUint8List = Uint8List.fromList(processedBytes);

    // Generate thumbnail
    final thumbnail = img.copyResize(
      processedImage,
      width: AppConfig.thumbnailWidth,
      height: AppConfig.thumbnailHeight,
    );
    final thumbnailBytes =
        img.encodeJpg(thumbnail, quality: AppConfig.thumbnailQuality);
    final thumbnailUint8List = Uint8List.fromList(thumbnailBytes);

    return ProcessedImageResult(
      imageBytes: processedBytes,
      thumbnailBytes: thumbnailBytes,
      width: processedImage.width,
      height: processedImage.height,
      size: processedUint8List.length,
      thumbnailSize: thumbnailUint8List.length,
      format: 'jpeg',
    );
  }

  @override
  Future<List<int>> resizeImageIfNeeded(
    List<int> imageBytes, {
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        throw const ImageProcessingException('Failed to decode image');
      }

      if (image.width <= maxWidth && image.height <= maxHeight) {
        return imageBytes; // No resize needed
      }

      final scale = image.width > image.height
          ? maxWidth / image.width
          : maxHeight / image.height;

      final resized = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );

      return img.encodeJpg(resized, quality: AppConfig.storageQuality);
    } catch (e) {
      logError('Failed to resize image', e);
      throw ImageProcessingException(
        'Failed to resize image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<ImageDimensions?> getImageDimensions(List<int> imageBytes) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        return null;
      }

      return ImageDimensions(
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      logError('Failed to get image dimensions', e);
      return null;
    }
  }

  @override
  Future<List<int>> compressToJpeg(
    List<int> imageBytes, {
    int quality = 85,
  }) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        throw const ImageProcessingException('Failed to decode image');
      }

      final compressed = img.encodeJpg(image, quality: quality);
      return compressed;
    } catch (e) {
      logError('Failed to compress image', e);
      throw ImageProcessingException(
        'Failed to compress image: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
