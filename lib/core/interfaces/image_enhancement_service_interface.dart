import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Options for image enhancement
class ImageEnhancementOptions {
  final bool perspectiveCorrection;
  final bool deskew;
  final bool reduceNoise;

  // Enhancement parameters
  final int noiseReductionStrength; // 1-5, higher = more aggressive

  const ImageEnhancementOptions({
    this.perspectiveCorrection = false,
    this.deskew = false,
    this.reduceNoise = false,
    this.noiseReductionStrength = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'perspectiveCorrection': perspectiveCorrection,
      'deskew': deskew,
      'reduceNoise': reduceNoise,
      'noiseReductionStrength': noiseReductionStrength,
    };
  }

  factory ImageEnhancementOptions.fromJson(Map<String, dynamic> json) {
    return ImageEnhancementOptions(
      perspectiveCorrection: json['perspectiveCorrection'] ?? false,
      deskew: json['deskew'] ?? false,
      reduceNoise: json['reduceNoise'] ?? false,
      noiseReductionStrength: json['noiseReductionStrength'] ?? 2,
    );
  }
}

/// Result of image enhancement
class ImageEnhancementResult {
  final Uint8List enhancedImageBytes;
  final Uint8List originalImageBytes;
  final int width;
  final int height;
  final Map<String, dynamic> appliedEnhancements;

  ImageEnhancementResult({
    required this.enhancedImageBytes,
    required this.originalImageBytes,
    required this.width,
    required this.height,
    required this.appliedEnhancements,
  });
}

/// Interface for image enhancement operations
abstract class IImageEnhancementService {
  /// Enhance an image with the specified options
  Future<ImageEnhancementResult> enhanceImage(
    Uint8List imageBytes,
    ImageEnhancementOptions options,
  );

  /// Detect and correct perspective distortion
  Future<Uint8List> correctPerspective(Uint8List imageBytes);

  /// Detect and correct skew (rotation)
  Future<Uint8List> deskewImage(Uint8List imageBytes);

  /// Reduce image noise
  Future<Uint8List> reduceNoise(Uint8List imageBytes, int strength);

  /// Auto-enhance image (apply smart defaults)
  Future<ImageEnhancementResult> autoEnhance(Uint8List imageBytes);

  /// Detect document corners in an image
  /// Returns null if corners cannot be detected reliably
  Future<List<math.Point<int>>?> detectDocumentCorners(Uint8List imageBytes);

  /// Apply perspective transformation based on corner points
  /// Corners should be in order: top-left, top-right, bottom-right, bottom-left
  Future<Uint8List> applyPerspectiveTransform(
    Uint8List imageBytes,
    List<Offset> corners,
  );
}
