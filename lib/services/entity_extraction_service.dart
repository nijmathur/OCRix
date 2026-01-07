/// Entity Extraction Service
/// Uses Gemma LLM to extract structured entities from document OCR text
library;

import 'package:flutter_gemma/flutter_gemma.dart';
import '../core/base/base_service.dart';
import '../models/document_entity.dart';
import 'llm_search/gemma_model_service.dart';

/// Service for extracting structured entities from document text using LLM
class EntityExtractionService extends BaseService {
  final GemmaModelService _gemmaService;

  // Extraction settings
  static const int _maxTextLength = 1500; // Max chars to send to LLM
  static const double _extractionTemperature =
      0.1; // Low for deterministic output
  static const int _extractionTopK = 10;

  EntityExtractionService([GemmaModelService? gemmaService])
    : _gemmaService = gemmaService ?? GemmaModelService();

  @override
  String get serviceName => 'EntityExtractionService';

  /// Check if Gemma is available for extraction
  Future<bool> isAvailable() async {
    try {
      return await _gemmaService.isModelDownloaded();
    } catch (e) {
      logWarning('Failed to check Gemma availability: $e');
      return false;
    }
  }

  /// Extract entities from document OCR text
  /// Returns DocumentEntity with extracted fields or empty entity if extraction fails
  Future<DocumentEntity> extractEntities(
    String documentId,
    String ocrText,
  ) async {
    if (ocrText.trim().isEmpty) {
      logInfo('Empty OCR text, skipping extraction for document: $documentId');
      return DocumentEntity.empty(documentId);
    }

    // Check if Gemma is available
    if (!await isAvailable()) {
      logInfo('Gemma not available, skipping LLM extraction for: $documentId');
      // Fall back to regex-based extraction
      return _extractWithRegex(documentId, ocrText);
    }

    try {
      // Initialize Gemma if needed
      await _gemmaService.initialize();

      // Build extraction prompt
      final prompt = _buildExtractionPrompt(ocrText);

      // Get Gemma model and create chat
      final model = await FlutterGemma.getActiveModel(maxTokens: 150);
      final chat = await model.createChat(
        temperature: _extractionTemperature,
        topK: _extractionTopK,
        randomSeed: 42,
      );

      // Send prompt and get response
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();

      String responseText = '';
      if (response is TextResponse) {
        responseText = response.token;
      }

      logInfo('Gemma extraction response for $documentId: $responseText');

      // Parse the response
      final entity = _parseExtractionResponse(documentId, responseText);

      // If LLM extraction failed, fall back to regex
      if (!entity.hasData) {
        logInfo('LLM extraction found no data, trying regex for: $documentId');
        return _extractWithRegex(documentId, ocrText);
      }

      return entity;
    } catch (e, stackTrace) {
      logError('LLM entity extraction failed for $documentId', e, stackTrace);
      // Fall back to regex-based extraction
      return _extractWithRegex(documentId, ocrText);
    }
  }

  /// Build the extraction prompt for Gemma
  String _buildExtractionPrompt(String text) {
    // Truncate text to avoid token limits
    final truncatedText = text.length > _maxTextLength
        ? text.substring(0, _maxTextLength)
        : text;

    return '''Extract information from this receipt/document. Only respond with the extracted data in the exact format shown.

Document text:
"""
$truncatedText
"""

Extract these fields (use NONE if not found):
VENDOR: [store or company name]
AMOUNT: [total amount as number only, no currency symbol]
DATE: [date in YYYY-MM-DD format]
CATEGORY: [one of: grocery, restaurant, medical, pharmacy, utilities, fuel, entertainment, retail, services, travel, financial, other]

Response:''';
  }

  /// Parse Gemma's extraction response
  DocumentEntity _parseExtractionResponse(String documentId, String response) {
    String? vendor;
    double? amount;
    DateTime? transactionDate;
    EntityCategory? category;

    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      final upperLine = trimmed.toUpperCase();

      // Parse VENDOR
      if (upperLine.startsWith('VENDOR:')) {
        final value = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (value.toUpperCase() != 'NONE' &&
            value.isNotEmpty &&
            value.length < 100) {
          vendor = _cleanVendorName(value);
        }
      }

      // Parse AMOUNT
      if (upperLine.startsWith('AMOUNT:')) {
        final value = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (value.toUpperCase() != 'NONE') {
          // Extract number from string
          final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
          amount = double.tryParse(cleaned);
        }
      }

      // Parse DATE
      if (upperLine.startsWith('DATE:')) {
        final value = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (value.toUpperCase() != 'NONE') {
          transactionDate = _parseDate(value);
        }
      }

      // Parse CATEGORY
      if (upperLine.startsWith('CATEGORY:')) {
        final value = trimmed
            .substring(trimmed.indexOf(':') + 1)
            .trim()
            .toLowerCase();
        category = EntityCategory.fromString(value);
      }
    }

    final hasData =
        vendor != null ||
        amount != null ||
        transactionDate != null ||
        category != null;

    return DocumentEntity(
      documentId: documentId,
      vendor: vendor,
      amount: amount,
      transactionDate: transactionDate,
      category: category,
      confidence: hasData ? 0.85 : 0.0, // LLM extraction has high confidence
      extractedAt: DateTime.now(),
    );
  }

  /// Fallback: Extract entities using regex patterns
  DocumentEntity _extractWithRegex(String documentId, String text) {
    final lowerText = text.toLowerCase();

    // Extract amount using regex
    double? amount;
    final amountMatches = RegExp(
      r'\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)',
    ).allMatches(text).toList();
    if (amountMatches.isNotEmpty) {
      // Use the largest amount as the total
      for (final match in amountMatches) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amountStr);
        if (parsed != null && (amount == null || parsed > amount)) {
          amount = parsed;
        }
      }
    }

    // Extract date using regex
    DateTime? transactionDate;
    final datePatterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2})'), // MM/DD/YY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY-MM-DD
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        transactionDate = _parseDateFromMatch(match);
        if (transactionDate != null) break;
      }
    }

    // Detect vendor from known patterns
    String? vendor = _detectVendor(lowerText);

    // Detect category from keywords
    EntityCategory? category = _detectCategory(lowerText);

    final hasData =
        vendor != null ||
        amount != null ||
        transactionDate != null ||
        category != null;

    return DocumentEntity(
      documentId: documentId,
      vendor: vendor,
      amount: amount,
      transactionDate: transactionDate,
      category: category,
      confidence: hasData ? 0.6 : 0.0, // Regex extraction has lower confidence
      extractedAt: DateTime.now(),
    );
  }

  /// Detect vendor from known patterns
  String? _detectVendor(String text) {
    const vendorPatterns = {
      'kroger': 'Kroger',
      'walmart': 'Walmart',
      'target': 'Target',
      'costco': 'Costco',
      'amazon': 'Amazon',
      'whole foods': 'Whole Foods',
      'trader joe': 'Trader Joe\'s',
      'safeway': 'Safeway',
      'publix': 'Publix',
      'aldi': 'Aldi',
      'cvs': 'CVS Pharmacy',
      'walgreens': 'Walgreens',
      'rite aid': 'Rite Aid',
      'starbucks': 'Starbucks',
      'mcdonalds': 'McDonald\'s',
      'mcdonald\'s': 'McDonald\'s',
      'chipotle': 'Chipotle',
      'subway': 'Subway',
      'shell': 'Shell',
      'exxon': 'Exxon',
      'chevron': 'Chevron',
      'bp ': 'BP',
      'speedway': 'Speedway',
      'home depot': 'Home Depot',
      'lowes': 'Lowe\'s',
      'lowe\'s': 'Lowe\'s',
      'best buy': 'Best Buy',
      'apple store': 'Apple Store',
    };

    for (final entry in vendorPatterns.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Detect category from keywords
  EntityCategory? _detectCategory(String text) {
    const categoryKeywords = {
      EntityCategory.grocery: [
        'grocery',
        'produce',
        'dairy',
        'meat',
        'bakery',
        'deli',
        'kroger',
        'walmart',
        'safeway',
        'publix',
        'aldi',
        'trader joe',
        'whole foods',
      ],
      EntityCategory.restaurant: [
        'restaurant',
        'cafe',
        'diner',
        'pizza',
        'burger',
        'coffee',
        'starbucks',
        'mcdonalds',
        'chipotle',
        'subway',
        'tip',
        'server',
        'gratuity',
      ],
      EntityCategory.medical: [
        'medical',
        'doctor',
        'hospital',
        'clinic',
        'patient',
        'diagnosis',
        'treatment',
        'prescription',
        'copay',
        'insurance',
      ],
      EntityCategory.pharmacy: [
        'pharmacy',
        'rx',
        'prescription',
        'cvs',
        'walgreens',
        'rite aid',
        'medication',
        'drug',
      ],
      EntityCategory.utilities: [
        'utility',
        'electric',
        'water',
        'internet',
        'phone',
        'cable',
        'bill',
        'account number',
        'due date',
      ],
      EntityCategory.fuel: [
        'gas',
        'fuel',
        'gasoline',
        'diesel',
        'gallon',
        'pump',
        'shell',
        'exxon',
        'chevron',
        'bp',
        'speedway',
      ],
      EntityCategory.entertainment: [
        'movie',
        'theater',
        'concert',
        'ticket',
        'admission',
        'entertainment',
        'netflix',
        'spotify',
      ],
      EntityCategory.retail: [
        'store',
        'purchase',
        'item',
        'product',
        'return',
        'target',
        'amazon',
        'best buy',
        'home depot',
      ],
      EntityCategory.financial: [
        'bank',
        'credit',
        'debit',
        'transaction',
        'deposit',
        'withdrawal',
        'balance',
        'statement',
        'fee',
        'interest',
      ],
      EntityCategory.travel: [
        'airline',
        'flight',
        'hotel',
        'rental',
        'travel',
        'booking',
        'reservation',
        'airport',
      ],
    };

    int maxMatches = 0;
    EntityCategory? bestCategory;

    for (final entry in categoryKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = entry.key;
      }
    }

    return maxMatches > 0 ? bestCategory : EntityCategory.other;
  }

  /// Parse date from string
  DateTime? _parseDate(String value) {
    // Try ISO format first (YYYY-MM-DD)
    final isoMatch = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(value);
    if (isoMatch != null) {
      try {
        return DateTime(
          int.parse(isoMatch.group(1)!),
          int.parse(isoMatch.group(2)!),
          int.parse(isoMatch.group(3)!),
        );
      } catch (_) {}
    }

    // Try US format (MM/DD/YYYY)
    final usMatch = RegExp(
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
    ).firstMatch(value);
    if (usMatch != null) {
      try {
        return DateTime(
          int.parse(usMatch.group(3)!),
          int.parse(usMatch.group(1)!),
          int.parse(usMatch.group(2)!),
        );
      } catch (_) {}
    }

    return null;
  }

  /// Parse date from regex match
  DateTime? _parseDateFromMatch(RegExpMatch match) {
    try {
      final groups = match.groups([1, 2, 3]);
      if (groups.every((g) => g != null)) {
        final g1 = int.parse(groups[0]!);
        final g2 = int.parse(groups[1]!);
        final g3 = int.parse(groups[2]!);

        // Determine format
        if (g1 > 1000) {
          // YYYY-MM-DD
          return DateTime(g1, g2, g3);
        } else if (g3 > 1000) {
          // MM/DD/YYYY
          return DateTime(g3, g1, g2);
        } else {
          // MM/DD/YY - assume 2000s
          final year = g3 < 50 ? 2000 + g3 : 1900 + g3;
          return DateTime(year, g1, g2);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Clean and normalize vendor name
  String _cleanVendorName(String name) {
    // Remove common suffixes and clean up
    return name
        .replaceAll(RegExp(r'#\d+'), '') // Remove store numbers
        .replaceAll(RegExp(r'\d{5,}'), '') // Remove long numbers
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
