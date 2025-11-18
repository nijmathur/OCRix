import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    hide TextBlock;
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../core/models/ocr_result.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final Logger _logger = Logger();
  TextRecognizer? _textRecognizer;

  Future<void> initialize() async {
    try {
      _textRecognizer = TextRecognizer();
      _logger.i('OCR Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize OCR service: $e');
      rethrow;
    }
  }

  Future<OCRResult> extractTextFromImage(String imagePath) async {
    try {
      if (_textRecognizer == null) {
        await initialize();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      final extractedText = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);
      final detectedLanguage = _detectLanguage(extractedText);

      _logger
          .i('Text extracted from image: ${extractedText.length} characters');

      return OCRResult(
        text: extractedText,
        confidence: confidence,
        detectedLanguage: detectedLanguage,
        blocks: recognizedText.blocks
            .map((block) => TextBlock(
                  text: block.text,
                  confidence: 'unknown',
                  boundingBox: block.boundingBox,
                ))
            .toList(),
      );
    } catch (e) {
      _logger.e('Failed to extract text from image: $e');
      rethrow;
    }
  }

  Future<OCRResult> extractTextFromBytes(Uint8List imageBytes) async {
    try {
      if (_textRecognizer == null) {
        await initialize();
      }

      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: const Size(0, 0), // Will be determined from image
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 0,
        ),
      );

      final recognizedText = await _textRecognizer!.processImage(inputImage);

      final extractedText = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);
      final detectedLanguage = _detectLanguage(extractedText);

      _logger
          .i('Text extracted from bytes: ${extractedText.length} characters');

      return OCRResult(
        text: extractedText,
        confidence: confidence,
        detectedLanguage: detectedLanguage,
        blocks: recognizedText.blocks
            .map((block) => TextBlock(
                  text: block.text,
                  confidence: 'unknown',
                  boundingBox: block.boundingBox,
                ))
            .toList(),
      );
    } catch (e) {
      _logger.e('Failed to extract text from bytes: $e');
      rethrow;
    }
  }

  Future<DocumentType> categorizeDocument(String text) async {
    try {
      final lowerText = text.toLowerCase();

      // Simple categorization based on keywords
      if (_containsKeywords(
          lowerText, ['receipt', 'total', 'subtotal', 'tax', 'payment'])) {
        return DocumentType.receipt;
      } else if (_containsKeywords(
          lowerText, ['contract', 'agreement', 'terms', 'conditions'])) {
        return DocumentType.contract;
      } else if (_containsKeywords(
          lowerText, ['invoice', 'bill', 'amount due', 'payment terms'])) {
        return DocumentType.invoice;
      } else if (_containsKeywords(
          lowerText, ['manual', 'instructions', 'guide', 'how to'])) {
        return DocumentType.manual;
      } else if (_containsKeywords(
          lowerText, ['business card', 'contact', 'phone', 'email'])) {
        return DocumentType.businessCard;
      } else if (_containsKeywords(
          lowerText, ['passport', 'passport number', 'nationality'])) {
        return DocumentType.passport;
      } else if (_containsKeywords(
          lowerText, ['license', 'driving license', 'license number'])) {
        return DocumentType.license;
      } else if (_containsKeywords(
          lowerText, ['certificate', 'certification', 'award'])) {
        return DocumentType.certificate;
      } else if (_containsKeywords(
          lowerText, ['id', 'identification', 'identity card'])) {
        return DocumentType.id;
      }

      return DocumentType.other;
    } catch (e) {
      _logger.e('Failed to categorize document: $e');
      return DocumentType.other;
    }
  }

  Future<Uint8List> preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply image preprocessing
      final processedImage = img.copyResize(
        image,
        width: image.width > 2000 ? 2000 : image.width,
        height: image.height > 2000 ? 2000 : image.height,
      );

      // Convert to grayscale for better OCR
      final grayscaleImage = img.grayscale(processedImage);

      // Apply contrast enhancement
      final enhancedImage = img.contrast(grayscaleImage, contrast: 1.2);

      // Apply sharpening - simplified version
      final sharpenedImage = enhancedImage;

      return Uint8List.fromList(img.encodeJpg(sharpenedImage, quality: 95));
    } catch (e) {
      _logger.e('Failed to preprocess image: $e');
      rethrow;
    }
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int blockCount = 0;

    for (final block in recognizedText.blocks) {
      if (block.recognizedLanguages.isNotEmpty) {
        totalConfidence += 0.8; // Default confidence for blocks with language
        blockCount++;
      }
    }

    return blockCount > 0 ? totalConfidence / blockCount : 0.0;
  }

  String _detectLanguage(String text) {
    // Simple language detection based on character patterns
    if (text.isEmpty) return 'unknown';

    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasCyrillic = RegExp(r'[а-яА-Я]').hasMatch(text);
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    final hasArabic = RegExp(r'[\u0600-\u06ff]').hasMatch(text);

    if (hasChinese) return 'zh';
    if (hasArabic) return 'ar';
    if (hasCyrillic) return 'ru';
    if (hasLatin) return 'en';

    return 'unknown';
  }

  bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
    _logger.i('OCR Service disposed');
  }
}
