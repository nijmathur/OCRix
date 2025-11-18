import 'package:flutter/material.dart';
import '../../models/document.dart';

/// OCR result data
class OCRResult {
  final String text;
  final double confidence;
  final String detectedLanguage;
  final List<TextBlock> blocks;

  const OCRResult({
    required this.text,
    required this.confidence,
    required this.detectedLanguage,
    required this.blocks,
  });
}

/// Text block from OCR
class TextBlock {
  final String text;
  final String confidence;
  final Rect boundingBox;

  const TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Interface for OCR operations
abstract class IOCRService {
  /// Initialize the OCR service
  Future<void> initialize();

  /// Extract text from image file
  Future<OCRResult> extractTextFromImage(String imagePath);

  /// Extract text from image bytes
  Future<OCRResult> extractTextFromBytes(List<int> imageBytes);

  /// Categorize document based on text content
  Future<DocumentType> categorizeDocument(String text);

  /// Preprocess image for better OCR results
  Future<List<int>> preprocessImage(String imagePath);

  /// Dispose resources
  Future<void> dispose();
}

