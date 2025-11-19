import 'package:flutter/material.dart';

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
