import 'dart:typed_data';

/// Options for image enhancement
class ImageEnhancementOptions {
  final bool perspectiveCorrection;
  final bool deskew;
  final bool adjustContrast;
  final bool adjustBrightness;
  final bool reduceNoise;
  final bool binarize;

  // Enhancement parameters
  final double contrastFactor; // 1.0 = no change, >1.0 = increase, <1.0 = decrease
  final double brightnessFactor; // 1.0 = no change, >1.0 = brighter, <1.0 = darker
  final int noiseReductionStrength; // 1-5, higher = more aggressive
  final int binarizationThreshold; // 0-255, for adaptive thresholding

  const ImageEnhancementOptions({
    this.perspectiveCorrection = false,
    this.deskew = false,
    this.adjustContrast = false,
    this.adjustBrightness = false,
    this.reduceNoise = false,
    this.binarize = false,
    this.contrastFactor = 1.2,
    this.brightnessFactor = 1.1,
    this.noiseReductionStrength = 2,
    this.binarizationThreshold = 128,
  });

  Map<String, dynamic> toJson() {
    return {
      'perspectiveCorrection': perspectiveCorrection,
      'deskew': deskew,
      'adjustContrast': adjustContrast,
      'adjustBrightness': adjustBrightness,
      'reduceNoise': reduceNoise,
      'binarize': binarize,
      'contrastFactor': contrastFactor,
      'brightnessFactor': brightnessFactor,
      'noiseReductionStrength': noiseReductionStrength,
      'binarizationThreshold': binarizationThreshold,
    };
  }

  factory ImageEnhancementOptions.fromJson(Map<String, dynamic> json) {
    return ImageEnhancementOptions(
      perspectiveCorrection: json['perspectiveCorrection'] ?? false,
      deskew: json['deskew'] ?? false,
      adjustContrast: json['adjustContrast'] ?? false,
      adjustBrightness: json['adjustBrightness'] ?? false,
      reduceNoise: json['reduceNoise'] ?? false,
      binarize: json['binarize'] ?? false,
      contrastFactor: json['contrastFactor'] ?? 1.2,
      brightnessFactor: json['brightnessFactor'] ?? 1.1,
      noiseReductionStrength: json['noiseReductionStrength'] ?? 2,
      binarizationThreshold: json['binarizationThreshold'] ?? 128,
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

  /// Adjust image contrast
  Future<Uint8List> adjustContrast(Uint8List imageBytes, double factor);

  /// Adjust image brightness
  Future<Uint8List> adjustBrightness(Uint8List imageBytes, double factor);

  /// Reduce image noise
  Future<Uint8List> reduceNoise(Uint8List imageBytes, int strength);

  /// Convert image to black and white (binarization)
  Future<Uint8List> binarizeImage(Uint8List imageBytes, int threshold);

  /// Auto-enhance image (apply smart defaults)
  Future<ImageEnhancementResult> autoEnhance(Uint8List imageBytes);
}
