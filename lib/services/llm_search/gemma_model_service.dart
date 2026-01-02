/// Gemma Model Service for LLM Search
/// Manages Gemma model download, initialization, and inference
library;

import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaModelService {
  static const String modelUrl =
      'https://huggingface.co/litert/google-gemma-2b-it-int8-finetuned-imdb-quantized/resolve/main/google-gemma-2b-it-int8-finetuned-imdb-quantized.task';

  static const ModelType modelType = ModelType.gemmaIt;
  static const int maxTokens = 512;
  static const double temperature = 0.3; // Lower for more deterministic SQL generation

  FlutterGemmaModel? _model;
  bool _isInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  StreamController<double>? _progressController;

  /// Get download progress stream
  Stream<double> get downloadProgress async* {
    _progressController ??= StreamController<double>.broadcast();
    yield* _progressController!.stream;
  }

  /// Check if model is downloaded
  Future<bool> isModelDownloaded() async {
    try {
      final models = await FlutterGemma.getDownloadedModels();
      return models.any((m) => m.modelType == modelType);
    } catch (e) {
      print('[GemmaModelService] Error checking model: $e');
      return false;
    }
  }

  /// Download Gemma model from HuggingFace
  Future<void> downloadModel() async {
    if (_isDownloading) {
      throw StateError('Model download already in progress');
    }

    _isDownloading = true;
    _progressController ??= StreamController<double>.broadcast();

    try {
      print('[GemmaModelService] Starting model download...');

      await FlutterGemma.installModel(modelType: modelType)
          .fromNetwork(modelUrl)
          .onProgress((progress) {
            _downloadProgress = progress;
            _progressController?.add(progress);
            print('[GemmaModelService] Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          })
          .install();

      _progressController?.add(1.0);
      print('[GemmaModelService] Model downloaded successfully');
    } catch (e) {
      print('[GemmaModelService] Model download failed: $e');
      rethrow;
    } finally {
      _isDownloading = false;
    }
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
      print('[GemmaModelService] Initializing Gemma model...');

      _model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        temperature: temperature,
        topK: 10, // Lower for more focused responses
        randomSeed: 42, // Fixed seed for reproducibility
      );

      _isInitialized = true;
      print('[GemmaModelService] Model initialized successfully');
    } catch (e) {
      print('[GemmaModelService] Model initialization failed: $e');
      rethrow;
    }
  }

  /// Generate SQL query from natural language using Gemma
  Future<String> generateSQL(String naturalLanguageQuery) async {
    if (!_isInitialized || _model == null) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    try {
      final prompt = _buildPrompt(naturalLanguageQuery);
      print('[GemmaModelService] Generating SQL for: "$naturalLanguageQuery"');

      // Create chat session
      final chat = await _model!.createChat();

      // Send prompt
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      // Generate response
      final response = await chat.generateChatResponse();
      final sqlQuery = _extractSQL(response.text);

      print('[GemmaModelService] Generated SQL: $sqlQuery');
      return sqlQuery;
    } catch (e) {
      print('[GemmaModelService] SQL generation failed: $e');
      throw LLMInferenceException('Failed to generate SQL: $e');
    }
  }

  /// Build prompt for SQL generation
  String _buildPrompt(String userQuery) {
    return '''You are a SQL query generator for a document management database.

**Database Schema:**
Table: documents
Columns:
- id (TEXT, PRIMARY KEY)
- title (TEXT)
- content (TEXT) - extracted text from documents
- category (TEXT) - values: 'invoice', 'receipt', 'contract', 'letter', 'form', 'tax', 'bill', 'statement'
- tags (TEXT) - comma-separated tags
- created_at (INTEGER) - milliseconds since epoch
- scan_date (INTEGER) - milliseconds since epoch

**Important Rules:**
1. ONLY generate SELECT queries
2. NEVER use INSERT, UPDATE, DELETE, DROP, or other modifying operations
3. Use date('now') for current date comparisons
4. Use LIKE for text searches with % wildcards
5. Always ORDER BY created_at DESC
6. Always include LIMIT (max 100)
7. Return ONLY the SQL query, no explanations or markdown

**User Query:** "${userQuery}"

**SQL Query:**''';
  }

  /// Extract SQL query from LLM response
  String _extractSQL(String response) {
    // Remove markdown code blocks if present
    String sql = response.trim();

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

    // Remove any trailing explanations
    final lines = sql.split('\n');
    final sqlLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('--')) continue; // Skip SQL comments
      if (!trimmed.toUpperCase().startsWith('SELECT') &&
          !trimmed.toUpperCase().startsWith('FROM') &&
          !trimmed.toUpperCase().startsWith('WHERE') &&
          !trimmed.toUpperCase().startsWith('ORDER') &&
          !trimmed.toUpperCase().startsWith('LIMIT') &&
          !trimmed.toUpperCase().startsWith('AND') &&
          !trimmed.toUpperCase().startsWith('OR') &&
          sqlLines.isEmpty) {
        continue; // Skip non-SQL lines before query starts
      }
      sqlLines.add(line);
    }

    return sqlLines.join('\n').trim();
  }

  /// Dispose resources
  void dispose() {
    _progressController?.close();
    _progressController = null;
    _model = null;
    _isInitialized = false;
  }
}

/// Exception for LLM inference errors
class LLMInferenceException implements Exception {
  final String message;
  LLMInferenceException(this.message);

  @override
  String toString() => 'LLMInferenceException: $message';
}
