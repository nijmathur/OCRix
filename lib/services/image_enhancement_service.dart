import 'dart:math' as math;
import 'dart:ui';
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
    // Find document corners using edge density analysis
    final width = edges.width;
    final height = edges.height;

    // Divide image into grid and find edge density in each cell
    const gridSize = 10;
    final cellWidth = width ~/ gridSize;
    final cellHeight = height ~/ gridSize;

    // Find the bounding box of the document based on edge density
    int minX = width;
    int maxX = 0;
    int minY = height;
    int maxY = 0;

    for (var gy = 0; gy < gridSize; gy++) {
      for (var gx = 0; gx < gridSize; gx++) {
        final density = _calculateEdgeDensity(
          edges,
          gx * cellWidth,
          gy * cellHeight,
          cellWidth,
          cellHeight,
        );

        // Threshold for edge detection (30% of max intensity)
        if (density > 76) {
          // 76 ≈ 30% of 255
          if (gx * cellWidth < minX) minX = gx * cellWidth;
          if ((gx + 1) * cellWidth > maxX) maxX = (gx + 1) * cellWidth;
          if (gy * cellHeight < minY) minY = gy * cellHeight;
          if ((gy + 1) * cellHeight > maxY) maxY = (gy + 1) * cellHeight;
        }
      }
    }

    // If we found a reasonable bounding box (at least 30% of image)
    final detectedWidth = maxX - minX;
    final detectedHeight = maxY - minY;
    if (detectedWidth > width * 0.3 && detectedHeight > height * 0.3) {
      // Return corners in clockwise order: top-left, top-right, bottom-right, bottom-left
      return [
        math.Point(minX, minY), // Top-left
        math.Point(maxX, minY), // Top-right
        math.Point(maxX, maxY), // Bottom-right
        math.Point(minX, maxY), // Bottom-left
      ];
    }

    // Couldn't find reliable corners
    return null;
  }

  static int _calculateEdgeDensity(
      img.Image edges, int startX, int startY, int width, int height) {
    int totalIntensity = 0;
    int pixelCount = 0;

    final endX = math.min(startX + width, edges.width);
    final endY = math.min(startY + height, edges.height);

    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final pixel = edges.getPixel(x, y);
        totalIntensity += img.getLuminance(pixel).toInt();
        pixelCount++;
      }
    }

    return pixelCount > 0 ? totalIntensity ~/ pixelCount : 0;
  }

  static img.Image _applyPerspectiveTransform(
      img.Image image, List<math.Point<int>> corners) {
    // Apply perspective correction by cropping to the document bounds
    // corners order: top-left, top-right, bottom-right, bottom-left
    if (corners.length != 4) return image;

    final topLeft = corners[0];
    final topRight = corners[1];
    final bottomRight = corners[2];
    final bottomLeft = corners[3];

    // Calculate the bounding box
    final minX = math.min(
      math.min(topLeft.x, topRight.x),
      math.min(bottomLeft.x, bottomRight.x),
    );
    final maxX = math.max(
      math.max(topLeft.x, topRight.x),
      math.max(bottomLeft.x, bottomRight.x),
    );
    final minY = math.min(
      math.min(topLeft.y, topRight.y),
      math.min(bottomLeft.y, bottomRight.y),
    );
    final maxY = math.max(
      math.max(topLeft.y, topRight.y),
      math.max(bottomLeft.y, bottomRight.y),
    );

    // Ensure bounds are within image dimensions
    final cropX = math.max(0, minX);
    final cropY = math.max(0, minY);
    final cropWidth = math.min(maxX - minX, image.width - cropX);
    final cropHeight = math.min(maxY - minY, image.height - cropY);

    // Validate crop dimensions
    if (cropWidth <= 0 || cropHeight <= 0) {
      return image; // Invalid crop, return original
    }

    // Crop the image to document bounds
    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    return cropped;
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
    // Skew detection using projection profile method
    // Convert to grayscale and binarize for edge detection
    final gray = img.grayscale(image);
    final edges = img.sobel(gray);

    // Use variance of horizontal projection to detect skew
    // Test angles from -15 to +15 degrees in 0.5 degree increments
    double bestAngle = 0.0;
    double maxVariance = 0.0;

    for (double angle = -15.0; angle <= 15.0; angle += 0.5) {
      // Rotate image by test angle
      final rotated = img.copyRotate(edges, angle: angle);

      // Calculate horizontal projection profile
      final variance = _calculateProjectionVariance(rotated);

      // The correct angle will have maximum variance in horizontal projection
      if (variance > maxVariance) {
        maxVariance = variance;
        bestAngle = angle;
      }
    }

    return bestAngle;
  }

  static double _calculateProjectionVariance(img.Image image) {
    // Calculate variance of horizontal projection profile
    // Higher variance = better text line alignment (correct skew angle)
    final projections = <int>[];

    // Sum pixel intensities for each row
    for (var y = 0; y < image.height; y++) {
      int rowSum = 0;
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rowSum += img.getLuminance(pixel).toInt();
      }
      projections.add(rowSum);
    }

    // Calculate mean
    final mean = projections.reduce((a, b) => a + b) / projections.length;

    // Calculate variance
    double variance = 0.0;
    for (final value in projections) {
      variance += math.pow(value - mean, 2);
    }
    variance /= projections.length;

    return variance;
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
  Future<ImageEnhancementResult> autoEnhance(Uint8List imageBytes) async {
    // Apply smart defaults for OCR document scanning
    const options = ImageEnhancementOptions(
      perspectiveCorrection: true, // Now implemented with edge detection
      deskew: true, // Now uses projection profile method
      reduceNoise: true,
      noiseReductionStrength: 2, // Moderate noise reduction
    );

    return enhanceImage(imageBytes, options);
  }

  @override
  Future<List<math.Point<int>>?> detectDocumentCorners(
      Uint8List imageBytes) async {
    try {
      logInfo('Detecting document corners');

      final result = await compute(
        _detectCornersInIsolate,
        imageBytes,
      );

      logInfo('Corner detection completed');
      return result;
    } catch (e, stackTrace) {
      logError('Failed to detect corners', e);
      return null; // Return null on error, caller will use default corners
    }
  }

  static List<math.Point<int>>? _detectCornersInIsolate(Uint8List imageBytes) {
    var image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // Use the existing edge detection
    final edges = _detectEdges(image);
    final corners = _findDocumentCorners(edges);

    return corners;
  }

  @override
  Future<Uint8List> applyPerspectiveTransform(
    Uint8List imageBytes,
    List<Offset> corners,
  ) async {
    try {
      logInfo('Applying perspective transform');

      final result = await compute(
        _perspectiveTransformInIsolate,
        {
          'imageBytes': imageBytes,
          'corners': corners.map((c) => {'x': c.dx, 'y': c.dy}).toList(),
        },
      );

      logInfo('Perspective transform completed');
      return result;
    } catch (e, stackTrace) {
      logError('Failed to apply perspective transform', e);
      throw ImageProcessingException(
        'Failed to apply perspective transform: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Uint8List _perspectiveTransformInIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final cornerMaps = params['corners'] as List;

    final corners = cornerMaps
        .map((c) => math.Point<int>(c['x'].toInt(), c['y'].toInt()))
        .toList();

    var image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Apply the perspective transform
    final transformed = _applyPerspectiveTransform(image, corners);

    // Encode back to bytes
    return Uint8List.fromList(img.encodeJpg(transformed, quality: 95));
  }
}
