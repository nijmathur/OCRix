import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_enhancement_service.dart';
import '../core/interfaces/image_enhancement_service_interface.dart';

/// Provider for the image enhancement service
final imageEnhancementServiceProvider =
    Provider<IImageEnhancementService>((ref) {
  final service = ImageEnhancementService();
  return service;
});
