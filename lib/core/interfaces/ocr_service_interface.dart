import '../../models/document.dart';
import '../models/ocr_result.dart';

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

