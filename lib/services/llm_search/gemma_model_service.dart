/// Gemma Model Service for LLM Search
/// Manages Gemma model download, initialization, and inference
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class GemmaModelService {
  // Singleton pattern to prevent double-initialization crashes
  static final GemmaModelService _instance = GemmaModelService._internal();
  factory GemmaModelService() => _instance;
  GemmaModelService._internal();

  final Logger _logger = Logger();

  static const String modelFileName = 'gemma2-2b-it.task';

  static const ModelType modelType = ModelType.gemmaIt;
  static const int maxTokens = 256; // Reduced to prevent OUT_OF_RANGE errors
  static const double temperature =
      0.3; // Lower for more deterministic SQL generation
  static const int topK = 20; // Reduced for more focused output
  static const int randomSeed = 42; // Fixed seed for reproducibility

  InferenceModel? _model;
  bool _isInitialized = false;
  bool _isInstalling = false;
  double _installProgress = 0.0;

  StreamController<double>? _progressController;

  /// Get installation progress stream
  Stream<double> get downloadProgress async* {
    _progressController ??= StreamController<double>.broadcast();
    yield* _progressController!.stream;
  }

  /// Check if model is installed
  Future<bool> isModelDownloaded() async {
    try {
      return FlutterGemma.hasActiveModel();
    } catch (e) {
      _logger.i('[GemmaModelService] Error checking model: $e');
      return false;
    }
  }

  /// Check if model file exists in persistent storage
  Future<bool> isModelFileAvailable() async {
    try {
      final modelPath = await _getModelStoragePath();
      final modelFile = File(modelPath);
      final exists = await modelFile.exists();
      if (exists) {
        _logger.i('[GemmaModelService] Model file found at: $modelPath');
      }
      return exists;
    } catch (e) {
      _logger.i('[GemmaModelService] Error checking model file: $e');
      return false;
    }
  }

  /// Get the persistent storage path for the model file
  /// Uses external storage to persist across app reinstalls
  Future<String> _getModelStoragePath() async {
    // Use external storage directory that persists across reinstalls
    // This creates: /sdcard/Android/media/com.ocrix.app/models/
    final externalDirs = await getExternalStorageDirectories(
      type: StorageDirectory.documents,
    );

    if (externalDirs == null || externalDirs.isEmpty) {
      // Fallback to app documents if external storage unavailable
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, modelFileName);
    }

    // Create a persistent models directory
    final modelsDir = Directory(
      path.join(externalDirs.first.parent.parent.path, 'models'),
    );
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    return path.join(modelsDir.path, modelFileName);
  }

  /// Copy model file from source to persistent storage
  Future<String> _copyModelToStorage(String sourceFilePath) async {
    final destPath = await _getModelStoragePath();
    final sourceFile = File(sourceFilePath);
    final destFile = File(destPath);

    // Check if model already exists at destination (skip copying if so)
    if (await destFile.exists()) {
      final destSize = await destFile.length();
      final sourceSize = await sourceFile.length();

      if (destSize == sourceSize) {
        _logger.i(
          '[GemmaModelService] Model already exists at $destPath (${destSize} bytes), skipping copy',
        );
        return destPath;
      } else {
        _logger.i(
          '[GemmaModelService] Existing model size mismatch, re-copying...',
        );
      }
    }

    // Check if source file exists
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found: $sourceFilePath');
    }

    _logger.i(
      '[GemmaModelService] Copying model from $sourceFilePath to $destPath',
    );

    // Copy file with progress tracking
    final sourceLength = await sourceFile.length();
    final sourceSink = sourceFile.openRead();
    final destSink = destFile.openWrite();

    int bytesWritten = 0;
    await for (final chunk in sourceSink) {
      destSink.add(chunk);
      bytesWritten += chunk.length;
      final progress = bytesWritten / sourceLength;
      _progressController?.add(progress * 0.5); // First 50% for copying
      _logger.i(
        '[GemmaModelService] Copy progress: ${(progress * 100).toStringAsFixed(1)}%',
      );
    }

    await destSink.flush();
    await destSink.close();

    _logger.i('[GemmaModelService] Model copied successfully to: $destPath');
    return destPath;
  }

  /// Install Gemma model from selected file
  Future<void> downloadModel(String sourceFilePath) async {
    if (_isInstalling) {
      throw StateError('Model installation already in progress');
    }

    _isInstalling = true;
    _progressController ??= StreamController<double>.broadcast();

    try {
      // Copy file to persistent storage (skips if already exists)
      final modelPath = await _copyModelToStorage(sourceFilePath);

      await _installModelFromPath(modelPath);
    } catch (e) {
      _logger.i('[GemmaModelService] Model installation failed: $e');
      rethrow;
    } finally {
      _isInstalling = false;
    }
  }

  /// Install model from persistent storage (without file picker)
  Future<void> installFromPersistentStorage() async {
    if (_isInstalling) {
      throw StateError('Model installation already in progress');
    }

    final modelPath = await _getModelStoragePath();
    final modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      throw Exception('Model file not found in persistent storage: $modelPath');
    }

    _isInstalling = true;
    _progressController ??= StreamController<double>.broadcast();

    try {
      _logger.i(
        '[GemmaModelService] Installing model from persistent storage: $modelPath',
      );
      await _installModelFromPath(modelPath, skipCopyProgress: true);
    } catch (e) {
      _logger.i('[GemmaModelService] Model installation failed: $e');
      rethrow;
    } finally {
      _isInstalling = false;
    }
  }

  /// Internal method to install model from a given path
  Future<void> _installModelFromPath(
    String modelPath, {
    bool skipCopyProgress = false,
  }) async {
    _logger.i(
      '[GemmaModelService] Starting model installation from file: $modelPath',
    );

    await FlutterGemma.installModel(
      modelType: modelType,
    ).fromFile(modelPath).withProgress((progress) {
      // Adjust progress based on whether we skipped copy
      if (skipCopyProgress) {
        _installProgress = progress / 100.0;
      } else {
        // Second 50% for installation (first 50% was copy)
        _installProgress = 0.5 + (progress / 100.0 * 0.5);
      }
      _progressController?.add(_installProgress);
      _logger.i(
        '[GemmaModelService] Installation progress: ${progress.toStringAsFixed(1)}%',
      );
    }).install();

    _progressController?.add(1.0);
    _logger.i('[GemmaModelService] Model installed successfully');
  }

  /// Initialize Gemma model for inference
  Future<void> initialize() async {
    if (_isInitialized && _model != null) {
      return;
    }

    // Check if model is downloaded
    final isDownloaded = await isModelDownloaded();
    if (!isDownloaded) {
      throw StateError('Model not downloaded. Call downloadModel() first.');
    }

    try {
      _logger.i('[GemmaModelService] Initializing Gemma model...');

      _model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);

      _isInitialized = true;
      _logger.i('[GemmaModelService] Model initialized successfully');
    } catch (e) {
      _logger.i('[GemmaModelService] Model initialization failed: $e');
      rethrow;
    }
  }

  /// Generate SQL query from natural language using Gemma
  Future<String> generateSQL(
    String naturalLanguageQuery, {
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    if (!_isInitialized || _model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    try {
      final prompt = _buildPrompt(naturalLanguageQuery);
      _logger.i(
        '[GemmaModelService] Generating SQL for: "$naturalLanguageQuery" (attempt ${retryCount + 1}/$maxRetries)',
      );

      // Create chat session with parameters
      final chat = await _model!.createChat(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      // Send prompt
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      // Generate response
      final response = await chat.generateChatResponse();

      // Extract text from ModelResponse (TextResponse has token property)
      String responseText = '';
      if (response is TextResponse) {
        responseText = response.token;
      } else {
        throw LLMInferenceException(
          'Unexpected response type: ${response.runtimeType}',
        );
      }

      _logger.i(
        '[GemmaModelService] Raw response (length: ${responseText.length}): "$responseText"',
      );

      if (responseText.isEmpty) {
        // Try to reinitialize and retry if we get empty responses
        if (retryCount < maxRetries - 1) {
          _logger.i(
            '[GemmaModelService] Empty response detected, reinitializing model and retrying...',
          );
          await _reinitializeModel();
          // Retry with incremented counter
          return await generateSQL(
            naturalLanguageQuery,
            retryCount: retryCount + 1,
          );
        } else {
          _logger.i(
            '[GemmaModelService] Empty response after $maxRetries attempts, giving up',
          );
          throw LLMInferenceException(
            'Model generated empty response after $maxRetries attempts',
          );
        }
      }

      final sqlQuery = _extractSQL(responseText);

      _logger.i('[GemmaModelService] Generated SQL: $sqlQuery');
      return sqlQuery;
    } catch (e) {
      _logger.i('[GemmaModelService] SQL generation failed: $e');
      throw LLMInferenceException('Failed to generate SQL: $e');
    }
  }

  /// Reinitialize the model to fix stuck states
  Future<void> _reinitializeModel() async {
    try {
      _logger.i('[GemmaModelService] Reinitializing model...');
      _model?.close();
      _model = null;
      _isInitialized = false;

      await initialize();
      _logger.i('[GemmaModelService] Model reinitialized successfully');
    } catch (e) {
      _logger.i('[GemmaModelService] Model reinitialization failed: $e');
    }
  }

  /// Categorize document using LLM (for hybrid ML Kit + LLM approach)
  Future<DocumentCategorizationResult> categorizeDocument(
    String extractedText,
  ) async {
    if (!_isInitialized || _model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    try {
      // Limit text to prevent token overflow (first 500 chars usually enough for categorization)
      final textSample = extractedText.length > 500
          ? extractedText.substring(0, 500)
          : extractedText;

      final prompt =
          '''Analyze this document and extract information.

Document text:
"""
$textSample
"""

Provide:
1. Category (ONE of: invoice, receipt, contract, manual, businessCard, id, passport, license, certificate, other)
2. Tags (3-5 relevant keywords: vendor/company name, type, amount if visible, date if visible, etc.)

Format:
Category: [category]
Tags: tag1, tag2, tag3

Example:
Category: receipt
Tags: Walmart, groceries, \$45.67, 2024-01-02''';

      _logger.i('[GemmaModelService] Categorizing document...');

      final chat = await _model!.createChat(
        temperature: 0.1, // Low temperature for consistent categorization
        randomSeed: randomSeed,
        topK: 10,
      );

      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();

      String responseText = '';
      if (response is TextResponse) {
        responseText = response.token.trim().toLowerCase();
      }

      if (responseText.isEmpty) {
        await _reinitializeModel();
        throw LLMInferenceException('Model generated empty response - retry');
      }

      // Parse response to extract category and tags
      final parsedResult = _parseCategoryAndTags(responseText);
      final category = parsedResult['category'] as String;
      final tags = parsedResult['tags'] as List<String>;

      _logger.i('[GemmaModelService] Categorized as: $category with tags: $tags');

      return DocumentCategorizationResult(
        type: category,
        tags: tags,
        confidence: 0.9, // LLM-based is generally high confidence
        rawResponse: responseText,
      );
    } catch (e) {
      _logger.i('[GemmaModelService] Categorization failed: $e');
      throw LLMInferenceException('Failed to categorize document: $e');
    }
  }

  /// Parse LLM response to extract category and tags
  Map<String, dynamic> _parseCategoryAndTags(String response) {
    String category = 'other';
    List<String> tags = [];

    try {
      // Parse structured response
      final lines = response.split('\n');

      for (final line in lines) {
        final trimmed = line.trim().toLowerCase();

        // Extract category
        if (trimmed.startsWith('category:')) {
          final categoryText = trimmed.substring('category:'.length).trim();
          category = _parseCategory(categoryText);
        }

        // Extract tags
        if (trimmed.startsWith('tags:')) {
          final tagsText = line
              .substring(line.toLowerCase().indexOf('tags:') + 'tags:'.length)
              .trim();
          tags = tagsText
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .take(5) // Limit to 5 tags
              .toList();
        }
      }
    } catch (e) {
      _logger.i('[GemmaModelService] Failed to parse structured response: $e');
      // Fallback: try to extract category from anywhere in response
      category = _parseCategory(response);
    }

    return {'category': category, 'tags': tags};
  }

  /// Parse category text to DocumentType
  String _parseCategory(String categoryText) {
    // Clean up response
    final cleaned = categoryText
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('.', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim()
        .toLowerCase();

    // Map to valid document types
    final validTypes = [
      'invoice',
      'receipt',
      'contract',
      'manual',
      'businesscard',
      'id',
      'passport',
      'license',
      'certificate',
      'other',
    ];

    // Direct match
    if (validTypes.contains(cleaned)) {
      return cleaned == 'businesscard' ? 'businessCard' : cleaned;
    }

    // Fuzzy matching for common variations
    if (cleaned.contains('invoice')) return 'invoice';
    if (cleaned.contains('receipt')) return 'receipt';
    if (cleaned.contains('contract')) return 'contract';
    if (cleaned.contains('manual') || cleaned.contains('guide'))
      return 'manual';
    if (cleaned.contains('business') && cleaned.contains('card'))
      return 'businessCard';
    if (cleaned.contains('id') || cleaned.contains('identification'))
      return 'id';
    if (cleaned.contains('passport')) return 'passport';
    if (cleaned.contains('license') || cleaned.contains('licence'))
      return 'license';
    if (cleaned.contains('certificate')) return 'certificate';

    // Default fallback
    return 'other';
  }

  /// Analyze documents to answer analytical questions (Stage 2 of RAG)
  Future<DocumentAnalysis> analyzeDocuments({
    required String userQuery,
    required List<Map<String, dynamic>> documents,
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    if (!_isInitialized || _model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    try {
      final prompt = _buildAnalysisPrompt(userQuery, documents);
      _logger.i(
        '[GemmaModelService] Analyzing ${documents.length} documents for: "$userQuery" (attempt ${retryCount + 1}/$maxRetries)',
      );

      // Create chat session with higher temperature for analysis
      final chat = await _model!.createChat(
        temperature: 0.5, // Balanced between creativity and accuracy
        randomSeed: randomSeed,
        topK: topK,
      );

      // Send analysis prompt
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      // Generate analysis
      final response = await chat.generateChatResponse();

      String responseText = '';
      if (response is TextResponse) {
        responseText = response.token;
      } else {
        throw LLMInferenceException(
          'Unexpected response type: ${response.runtimeType}',
        );
      }

      if (responseText.isEmpty) {
        // Try to reinitialize and retry if we get empty responses
        if (retryCount < maxRetries - 1) {
          _logger.i(
            '[GemmaModelService] Empty analysis response detected, reinitializing model and retrying...',
          );
          await _reinitializeModel();
          // Retry with incremented counter
          return await analyzeDocuments(
            userQuery: userQuery,
            documents: documents,
            retryCount: retryCount + 1,
          );
        } else {
          _logger.i(
            '[GemmaModelService] Empty analysis response after $maxRetries attempts, giving up',
          );
          throw LLMInferenceException(
            'Model generated empty analysis after $maxRetries attempts',
          );
        }
      }

      final analysis = _parseAnalysis(responseText);

      _logger.i('[GemmaModelService] Analysis complete: ${analysis.answer}');
      return analysis;
    } catch (e) {
      _logger.i('[GemmaModelService] Document analysis failed: $e');
      throw LLMInferenceException('Failed to analyze documents: $e');
    }
  }

  /// Build prompt for SQL generation
  String _buildPrompt(String userQuery) {
    // Simple, direct prompt to avoid token overflow
    return '''Write SQL for: $userQuery

Table: documents(id, title, extracted_text, type, scan_date, tags)

SELECT * FROM documents WHERE type = 'invoice' LIMIT 100
SELECT * FROM documents WHERE extracted_text LIKE '%coffee%' LIMIT 100

SQL:''';
  }

  /// Build prompt for document analysis (Stage 2)
  String _buildAnalysisPrompt(
    String userQuery,
    List<Map<String, dynamic>> documents,
  ) {
    // Limit documents to prevent token overflow (max 10 docs)
    final limitedDocs = documents.take(10).toList();

    final docTexts = StringBuffer();
    for (var i = 0; i < limitedDocs.length; i++) {
      final doc = limitedDocs[i];
      final title = doc['title'] ?? 'Untitled';
      final text = doc['extracted_text'] ?? '';
      final type = doc['type'] ?? 'unknown';

      // Truncate text to first 300 characters to fit in token budget
      final truncatedText = text.length > 300
          ? '${text.substring(0, 300)}...'
          : text;

      docTexts.writeln('--- Document ${i + 1} ($type: $title) ---');
      docTexts.writeln(truncatedText);
      docTexts.writeln();
    }

    return '''Answer the user's question by analyzing the provided documents.

User Question: "$userQuery"

Documents:
$docTexts

Instructions:
1. Read all documents carefully
2. Extract relevant information
3. Perform calculations if needed (sum, average, count, etc.)
4. Provide a clear, concise answer
5. If you cannot answer from the documents, say "I cannot determine this from the provided documents"

Answer:''';
  }

  /// Parse analysis response into structured format
  DocumentAnalysis _parseAnalysis(String response) {
    final answer = response.trim();

    // Simple confidence heuristic
    final confidence = answer.toLowerCase().contains('cannot determine')
        ? 0.3
        : 0.8;

    return DocumentAnalysis(answer: answer, confidence: confidence);
  }

  /// Extract SQL query from LLM response
  String _extractSQL(String response) {
    // Clean up response
    String sql = response.trim();

    // Handle empty response
    if (sql.isEmpty) {
      throw LLMInferenceException('Model generated empty response');
    }

    // Remove markdown code blocks if present
    if (sql.contains('```sql')) {
      final start = sql.indexOf('```sql') + 6;
      final end = sql.indexOf('```', start);
      if (end > start) {
        sql = sql.substring(start, end).trim();
      }
    } else if (sql.contains('```')) {
      final start = sql.indexOf('```') + 3;
      final end = sql.indexOf('```', start);
      if (end > start) {
        sql = sql.substring(start, end).trim();
      }
    }

    // Try to extract complete SQL statement (SELECT ... FROM ... WHERE/LIMIT)
    // Look for a line that contains SELECT and has substantial content
    final lines = sql.split('\n');
    String? bestMatch;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toUpperCase().startsWith('SELECT') && trimmed.length > 10) {
        // If this line contains FROM, it's likely a complete query
        if (trimmed.toUpperCase().contains('FROM')) {
          sql = trimmed;
          bestMatch = trimmed;
          break;
        } else if (bestMatch == null) {
          // Save first SELECT as fallback
          bestMatch = trimmed;
        }
      }
    }

    // Use best match if we found one
    if (bestMatch != null && bestMatch != sql) {
      sql = bestMatch;
    }

    // Validate basic SQL structure
    if (!sql.toUpperCase().startsWith('SELECT')) {
      throw LLMInferenceException(
        'Generated query does not start with SELECT: $sql',
      );
    }

    // Auto-complete incomplete queries by adding FROM documents
    if (!sql.toUpperCase().contains('FROM')) {
      _logger.i(
        '[GemmaModelService] Incomplete query detected (no FROM clause): $sql',
      );
      // Insert "FROM documents" after SELECT clause
      final selectMatch = RegExp(
        r'SELECT\s+(.+)',
        caseSensitive: false,
      ).firstMatch(sql);
      if (selectMatch != null) {
        final selectPart = selectMatch.group(0)!;
        sql = '$selectPart FROM documents';
        _logger.i('[GemmaModelService] Auto-completed query: $sql');
      } else {
        throw LLMInferenceException(
          'Generated query is incomplete and cannot be auto-completed: $sql',
        );
      }
    }

    // Ensure LIMIT clause for safety
    if (!sql.toUpperCase().contains('LIMIT')) {
      sql = '$sql LIMIT 100';
    }

    return sql.trim();
  }

  /// Dispose resources
  void dispose() {
    _progressController?.close();
    _progressController = null;
    _model?.close();
    _model = null;
    _isInitialized = false;
  }
}

/// Document analysis result from Stage 2 RAG
class DocumentAnalysis {
  final String answer;
  final double confidence; // 0.0 to 1.0

  DocumentAnalysis({required this.answer, required this.confidence});

  @override
  String toString() =>
      'DocumentAnalysis(answer: "$answer", confidence: $confidence)';
}

/// Result from LLM document categorization
class DocumentCategorizationResult {
  final String type; // DocumentType as string
  final List<String> tags; // Extracted tags from document
  final double confidence;
  final String rawResponse;

  DocumentCategorizationResult({
    required this.type,
    required this.tags,
    required this.confidence,
    required this.rawResponse,
  });

  @override
  String toString() =>
      'DocumentCategorizationResult(type: $type, tags: $tags, confidence: $confidence)';
}

/// Exception for LLM inference errors
class LLMInferenceException implements Exception {
  final String message;
  LLMInferenceException(this.message);

  @override
  String toString() => 'LLMInferenceException: $message';
}
