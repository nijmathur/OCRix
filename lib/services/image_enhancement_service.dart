import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/interfaces/image_enhancement_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for enhancing document images
class ImageEnhancementService extends BaseService
    implements IImageEnhancementService {
  @override
  String get serviceName => 'ImageEnhancementService';

  @override
  Future<ImageEnhancementResult> enhanceImage(
    Uint8List imageBytes,
    ImageEnhancementOptions options,
  ) async {
    try {
      logInfo('Enhancing image with options: ${options.toJson()}');

      final result = await compute(
        _enhanceImageInIsolate,
        {
          'imageBytes': imageBytes,
          'options': options.toJson(),
        },
      );

      logInfo('Image enhancement completed');
      return result;
    } catch (e, stackTrace) {
      logError('Failed to enhance image', e);
      throw ImageProcessingException(
        'Failed to enhance image: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static ImageEnhancementResult _enhanceImageInIsolate(
      Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final optionsJson = params['options'] as Map<String, dynamic>;
    final options = ImageEnhancementOptions.fromJson(optionsJson);

    final originalBytes = Uint8List.fromList(imageBytes);
    var image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final appliedEnhancements = <String, dynamic>{};

    // Apply enhancements in order

    // 1. Perspective correction (if enabled)
    if (options.perspectiveCorrection) {
      image = _correctPerspectiveInIsolate(image);
      appliedEnhancements['perspectiveCorrection'] = true;
    }

    // 2. Deskew (if enabled)
    if (options.deskew) {
      final angle = _detectSkewAngle(image);
      if (angle.abs() > 0.5) {
        // Only deskew if angle > 0.5 degrees
        image = img.copyRotate(image, angle: -angle);
        appliedEnhancements['deskew'] = true;
        appliedEnhancements['skewAngle'] = angle;
      }
    }

    // 3. Noise reduction (if enabled)
    if (options.reduceNoise) {
      image = _reduceNoiseInIsolate(image, options.noiseReductionStrength);
      appliedEnhancements['noiseReduction'] = true;
      appliedEnhancements['noiseStrength'] = options.noiseReductionStrength;
    }

    // 4. Contrast adjustment (if enabled)
    if (options.adjustContrast) {
      image = img.adjustColor(image, contrast: options.contrastFactor);
      appliedEnhancements['contrastAdjustment'] = true;
      appliedEnhancements['contrastFactor'] = options.contrastFactor;
    }

    // 5. Brightness adjustment (if enabled)
    if (options.adjustBrightness) {
      final brightnessValue = ((options.brightnessFactor - 1.0) * 100).round();
      image = img.adjustColor(image, brightness: brightnessValue.toDouble());
      appliedEnhancements['brightnessAdjustment'] = true;
      appliedEnhancements['brightnessFactor'] = options.brightnessFactor;
    }

    // 6. Binarization (if enabled) - should be last
    if (options.binarize) {
      image = _binarizeImageInIsolate(image, options.binarizationThreshold);
      appliedEnhancements['binarization'] = true;
      appliedEnhancements['binarizationThreshold'] =
          options.binarizationThreshold;
    }

    final enhancedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));

    return ImageEnhancementResult(
      enhancedImageBytes: enhancedBytes,
      originalImageBytes: originalBytes,
      width: image.width,
      height: image.height,
      appliedEnhancements: appliedEnhancements,
    );
  }

  @override
  Future<Uint8List> correctPerspective(Uint8List imageBytes) async {
    try {
      final result = await compute(_correctPerspectiveWrapper, imageBytes);
      return result;
    } catch (e, stackTrace) {
      logError('Failed to correct perspective', e);
      throw ImageProcessingException(
        'Failed to correct perspective: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _correctPerspectiveWrapper(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    final corrected = _correctPerspectiveInIsolate(image);
    return Uint8List.fromList(img.encodeJpg(corrected, quality: 90));
  }

  static img.Image _correctPerspectiveInIsolate(img.Image image) {
    // Simple edge detection and perspective correction
    // For a more sophisticated implementation, we would:
    // 1. Detect edges using Canny edge detection
    // 2. Find the largest quadrilateral (document boundary)
    // 3. Apply perspective transform to straighten it

    // For now, we'll do a simple implementation:
    // Detect the document corners using edge detection
    final edges = _detectEdges(image);
    final corners = _findDocumentCorners(edges);

    if (corners != null && corners.length == 4) {
      // Apply perspective transform
      return _applyPerspectiveTransform(image, corners);
    }

    // If we can't detect corners, return original
    return image;
  }

  static img.Image _detectEdges(img.Image image) {
    // Convert to grayscale
    final gray = img.grayscale(image);

    // Apply Sobel operator for edge detection
    return img.sobel(gray);
  }

  static List<math.Point<int>>? _findDocumentCorners(img.Image edges) {
    // Simplified corner detection
    // In a production app, you'd use Hough transform or contour detection
    // For now, return null to indicate we couldn't find corners reliably
    return null;
  }

  static img.Image _applyPerspectiveTransform(
      img.Image image, List<math.Point<int>> corners) {
    // This would apply a perspective transform matrix
    // For now, return the original image
    // A full implementation would use homography transformation
    return image;
  }

  @override
  Future<Uint8List> deskewImage(Uint8List imageBytes) async {
    try {
      final result = await compute(_deskewImageWrapper, imageBytes);
      return result;
    } catch (e, stackTrace) {
      logError('Failed to deskew image', e);
      throw ImageProcessingException(
        'Failed to deskew image: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _deskewImageWrapper(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final angle = _detectSkewAngle(image);
    if (angle.abs() > 0.5) {
      final rotated = img.copyRotate(image, angle: -angle);
      return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
    }

    return imageBytes; // No rotation needed
  }

  static double _detectSkewAngle(img.Image image) {
    // Simplified skew detection using projection profile method
    // Convert to grayscale and binarize
    final gray = img.grayscale(image);
    final binary = img.grayscale(gray);

    // For a production implementation, you would:
    // 1. Use Hough transform to detect lines
    // 2. Calculate dominant line angle
    // 3. Return the skew angle

    // For now, return 0 (no skew detected)
    // A real implementation would analyze horizontal projection profiles
    return 0.0;
  }

  @override
  Future<Uint8List> adjustContrast(Uint8List imageBytes, double factor) async {
    try {
      final result = await compute(
        _adjustContrastWrapper,
        {'imageBytes': imageBytes, 'factor': factor},
      );
      return result;
    } catch (e, stackTrace) {
      logError('Failed to adjust contrast', e);
      throw ImageProcessingException(
        'Failed to adjust contrast: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _adjustContrastWrapper(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final factor = params['factor'] as double;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final adjusted = img.adjustColor(image, contrast: factor);
    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 90));
  }

  @override
  Future<Uint8List> adjustBrightness(
      Uint8List imageBytes, double factor) async {
    try {
      final result = await compute(
        _adjustBrightnessWrapper,
        {'imageBytes': imageBytes, 'factor': factor},
      );
      return result;
    } catch (e, stackTrace) {
      logError('Failed to adjust brightness', e);
      throw ImageProcessingException(
        'Failed to adjust brightness: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _adjustBrightnessWrapper(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final factor = params['factor'] as double;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final brightnessValue = ((factor - 1.0) * 100).round();
    final adjusted =
        img.adjustColor(image, brightness: brightnessValue.toDouble());
    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 90));
  }

  @override
  Future<Uint8List> reduceNoise(Uint8List imageBytes, int strength) async {
    try {
      final result = await compute(
        _reduceNoiseWrapper,
        {'imageBytes': imageBytes, 'strength': strength},
      );
      return result;
    } catch (e, stackTrace) {
      logError('Failed to reduce noise', e);
      throw ImageProcessingException(
        'Failed to reduce noise: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _reduceNoiseWrapper(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final strength = params['strength'] as int;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final denoised = _reduceNoiseInIsolate(image, strength);
    return Uint8List.fromList(img.encodeJpg(denoised, quality: 90));
  }

  static img.Image _reduceNoiseInIsolate(img.Image image, int strength) {
    // Apply gaussian blur for noise reduction
    // Strength maps to blur radius (1-5)
    final radius = math.max(1, math.min(5, strength));
    return img.gaussianBlur(image, radius: radius);
  }

  @override
  Future<Uint8List> binarizeImage(Uint8List imageBytes, int threshold) async {
    try {
      final result = await compute(
        _binarizeImageWrapper,
        {'imageBytes': imageBytes, 'threshold': threshold},
      );
      return result;
    } catch (e, stackTrace) {
      logError('Failed to binarize image', e);
      throw ImageProcessingException(
        'Failed to binarize image: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _binarizeImageWrapper(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final threshold = params['threshold'] as int;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final binarized = _binarizeImageInIsolate(image, threshold);
    return Uint8List.fromList(img.encodeJpg(binarized, quality: 90));
  }

  static img.Image _binarizeImageInIsolate(img.Image image, int threshold) {
    // Convert to grayscale first
    final gray = img.grayscale(image);

    // Apply threshold
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        final newValue = luminance > threshold ? 255 : 0;
        gray.setPixelRgba(x, y, newValue, newValue, newValue, 255);
      }
    }

    return gray;
  }

  @override
  Future<ImageEnhancementResult> autoEnhance(Uint8List imageBytes) async {
    // Apply smart defaults for document scanning
    const options = ImageEnhancementOptions(
      perspectiveCorrection:
          false, // Disabled for now (needs better implementation)
      deskew: true,
      adjustContrast: true,
      adjustBrightness: true,
      reduceNoise: true,
      binarize: false, // User preference
      contrastFactor: 1.3,
      brightnessFactor: 1.1,
      noiseReductionStrength: 2,
    );

    return enhanceImage(imageBytes, options);
  }
}
