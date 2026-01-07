/// Vector-based LLM Search Service
/// Uses semantic embeddings for document retrieval (RAG approach)
library;

import 'dart:async';
import 'input_sanitizer.dart';
import 'rate_limiter.dart';
import 'gemma_model_service.dart';
import '../embedding_service.dart';
import '../vector_database_service.dart';
import '../../core/interfaces/database_service_interface.dart';

class VectorSearchService {
  final IDatabaseService _databaseService;
  final LLMInputSanitizer _sanitizer;
  final LLMSearchRateLimiter _rateLimiter;
  final List<SearchAuditEntry> _auditLog;

  late final EmbeddingService _embeddingService;
  late final VectorDatabaseService _vectorDB;
  late final GemmaModelService _gemmaService;

  bool _isInitialized = false;
  bool _isEmbeddingModelReady = false;
  bool _isLLMReady = false;

  VectorSearchService(this._databaseService)
    : _sanitizer = LLMInputSanitizer(),
      _rateLimiter = LLMSearchRateLimiter(),
      _auditLog = [];

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('[VectorSearchService] Initializing...');

    // Initialize embedding service
    _embeddingService = EmbeddingService();

    try {
      await _embeddingService.initialize();
      _isEmbeddingModelReady = true;
      print('[VectorSearchService] Embedding model ready');
    } catch (e) {
      print('[VectorSearchService] Embedding model failed to initialize: $e');
      _isEmbeddingModelReady = false;
    }

    // Initialize vector database
    final db = await _databaseService.database;
    _vectorDB = VectorDatabaseService(db, _embeddingService);

    // Initialize Gemma service for analysis
    _gemmaService = GemmaModelService();
    _isLLMReady = await _gemmaService.isModelDownloaded();
    if (_isLLMReady) {
      try {
        await _gemmaService.initialize();
      } catch (e) {
        print('[VectorSearchService] LLM initialization failed: $e');
        _isLLMReady = false;
      }
    }

    _isInitialized = true;
    print('[VectorSearchService] Initialization complete');
  }

  /// Check if ready for vector search
  bool get isReady => _isInitialized && _isEmbeddingModelReady;

  /// Check if LLM is available for analysis
  bool get isLLMReady => _isLLMReady;

  /// Refresh LLM readiness status (call after installing Gemma)
  Future<void> refreshLLMStatus() async {
    final wasReady = _isLLMReady;
    _isLLMReady = await _gemmaService.isModelDownloaded();

    if (!wasReady && _isLLMReady) {
      print('[VectorSearchService] LLM is now available, initializing...');
      try {
        // Initialize this service's Gemma instance
        await _gemmaService.initialize();
        print('[VectorSearchService] LLM initialized successfully');
      } catch (e) {
        print('[VectorSearchService] LLM initialization failed: $e');
        _isLLMReady = false;
      }
    }
  }

  /// Get vectorization statistics
  Future<Map<String, int>> getVectorizationStats() async {
    return await _vectorDB.getStatistics();
  }

  /// Start vectorization of all documents in background
  Future<VectorizationProgress> vectorizeAllDocuments({
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isEmbeddingModelReady) {
      throw StateError('Embedding model not ready');
    }

    return await _vectorDB.vectorizeAllDocuments(onProgress: onProgress);
  }

  /// Vectorize a single document (called when new document is added)
  Future<void> vectorizeDocument(Map<String, dynamic> document) async {
    if (!_isEmbeddingModelReady) {
      print(
        '[VectorSearchService] Embedding model not ready, skipping vectorization',
      );
      return;
    }

    await _vectorDB.vectorizeDocument(document);
  }

  /// Search using vector similarity
  Future<VectorSearchResult> search(String userQuery) async {
    if (!_isInitialized) {
      throw StateError('VectorSearchService not initialized');
    }

    if (!_isEmbeddingModelReady) {
      throw StateError('Embedding model not ready');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Sanitize input
      final sanitizedQuery = _sanitizer.sanitizeInput(userQuery);

      // Check rate limit
      if (!_rateLimiter.canSearch()) {
        throw RateLimitException('Rate limit exceeded');
      }

      // Check for suspicious patterns
      if (_sanitizer.isSuspicious(sanitizedQuery)) {
        _logSuspiciousQuery(userQuery);
      }

      // Perform vector similarity search
      final documents = await _vectorDB.searchSimilar(
        queryText: sanitizedQuery,
        limit: 10,
        minSimilarity: 0.5,
      );

      print('[VECTOR SEARCH] Found ${documents.length} similar documents');

      stopwatch.stop();
      _rateLimiter.recordSearch();

      // Check if query requires analysis
      String? analysis;
      double? confidence;

      // TEMPORARY: Disable LLM analysis due to native crashes in flutter_gemma plugin
      // TODO: Re-enable when flutter_gemma 0.12.0+ is stable or switch to different LLM backend
      if (false &&
          _isLLMReady &&
          _requiresAnalysis(sanitizedQuery) &&
          documents.isNotEmpty) {
        print('[VECTOR SEARCH] Performing LLM analysis...');
        try {
          final analysisResult = await _gemmaService
              .analyzeDocuments(userQuery: sanitizedQuery, documents: documents)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  print('[VECTOR SEARCH] Analysis timed out');
                  throw TimeoutException('Analysis took too long');
                },
              );
          analysis = analysisResult.answer;
          confidence = analysisResult.confidence;
          print('[VECTOR SEARCH] Analysis completed successfully');
        } catch (e, stackTrace) {
          print('[VECTOR SEARCH] Analysis failed: $e');
          print('[VECTOR SEARCH] Stack trace: $stackTrace');
          // Gracefully continue without analysis - just show documents
          analysis = null;
          confidence = null;
        }
      }

      _logSearch(
        userQuery: userQuery,
        resultCount: documents.length,
        executionTime: stopwatch.elapsed,
        success: true,
      );

      return VectorSearchResult(
        query: userQuery,
        results: documents,
        resultCount: documents.length,
        executionTime: stopwatch.elapsed,
        success: true,
        analysis: analysis,
        confidence: confidence,
      );
    } catch (e) {
      stopwatch.stop();
      _logSearch(
        userQuery: userQuery,
        resultCount: 0,
        executionTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );

      return VectorSearchResult(
        query: userQuery,
        results: [],
        resultCount: 0,
        executionTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if query requires LLM analysis
  bool _requiresAnalysis(String query) {
    final analyticalKeywords = [
      'how much',
      'how many',
      'total',
      'sum',
      'average',
      'count',
      'when',
      'why',
      'explain',
      'compare',
      'difference',
    ];

    final lowerQuery = query.toLowerCase();
    return analyticalKeywords.any((keyword) => lowerQuery.contains(keyword));
  }

  /// Log search for audit purposes
  void _logSearch({
    required String userQuery,
    required int resultCount,
    required Duration executionTime,
    required bool success,
    String? error,
  }) {
    _auditLog.add(
      SearchAuditEntry(
        query: userQuery,
        method: 'vector_search',
        resultCount: resultCount,
        executionTime: executionTime,
        success: success,
        timestamp: DateTime.now(),
        error: error,
      ),
    );

    // Keep audit log size manageable
    if (_auditLog.length > 100) {
      _auditLog.removeAt(0);
    }

    final statusIcon = success ? '✓' : '✗';
    print(
      '[VECTOR SEARCH] $statusIcon [${DateTime.now().toIso8601String()}] "$userQuery" → $resultCount results in ${executionTime.inMilliseconds}ms${error != null ? ' (Error: $error)' : ''}',
    );
  }

  /// Log suspicious query
  void _logSuspiciousQuery(String query) {
    print('[VECTOR SEARCH] ⚠️ Suspicious query detected: "$query"');
  }

  /// Get recent searches for debugging
  List<SearchAuditEntry> getRecentSearches({int limit = 20}) {
    return _auditLog.reversed.take(limit).toList();
  }

  /// Dispose resources
  void dispose() {
    _embeddingService.dispose();
    _gemmaService.dispose();
  }
}

/// Vector search result
class VectorSearchResult {
  final String query;
  final List<Map<String, dynamic>> results;
  final int resultCount;
  final Duration executionTime;
  final bool success;
  final String? error;
  final String? analysis;
  final double? confidence;

  VectorSearchResult({
    required this.query,
    required this.results,
    required this.resultCount,
    required this.executionTime,
    required this.success,
    this.error,
    this.analysis,
    this.confidence,
  });

  /// Check if LLM analysis is available
  bool get hasAnalysis => analysis != null && analysis!.isNotEmpty;

  @override
  String toString() {
    return 'VectorSearchResult(query: "$query", results: $resultCount, time: ${executionTime.inMilliseconds}ms, success: $success)';
  }
}

/// Audit entry for search
class SearchAuditEntry {
  final String query;
  final String method;
  final int resultCount;
  final Duration executionTime;
  final bool success;
  final DateTime timestamp;
  final String? error;

  SearchAuditEntry({
    required this.query,
    required this.method,
    required this.resultCount,
    required this.executionTime,
    required this.success,
    required this.timestamp,
    this.error,
  });
}

/// Rate limit exception
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => 'RateLimitException: $message';
}
