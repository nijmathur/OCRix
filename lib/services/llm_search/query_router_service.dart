/// Query Router Service
/// Intelligently routes natural language queries to appropriate search methods
library;

import '../../core/base/base_service.dart';
import '../../core/interfaces/database_service_interface.dart';
import '../../models/document.dart';
import '../embedding_service.dart';
import '../vector_database_service.dart';
import 'gemma_model_service.dart';

/// Types of queries that can be processed
enum QueryType {
  /// Structured queries answerable with SQL aggregations
  /// e.g., "how much did I spend on Kroger last month"
  structured,

  /// Semantic queries requiring vector similarity search
  /// e.g., "show me medical bills"
  semantic,

  /// Complex queries requiring LLM reasoning
  /// e.g., "compare my grocery spending across months"
  complex,
}

/// Aggregation result for structured queries (e.g., totals, averages)
class AggregationResult {
  final double? totalAmount;
  final double? averageAmount;
  final int documentCount;
  final String? vendor;
  final String? category;
  final String? dateRange;

  const AggregationResult({
    this.totalAmount,
    this.averageAmount,
    required this.documentCount,
    this.vendor,
    this.category,
    this.dateRange,
  });
}

/// Result of a query processed through the router
class QueryRouterResult {
  final QueryType queryType;
  final List<Map<String, dynamic>> documents;
  final String query;
  final AggregationResult? aggregation;
  final String? analysis;
  final double? confidence;
  final List<double>? similarities;
  final Duration executionTime;
  final String? debugInfo;

  const QueryRouterResult({
    required this.queryType,
    required this.documents,
    required this.query,
    this.aggregation,
    this.analysis,
    this.confidence,
    this.similarities,
    required this.executionTime,
    this.debugInfo,
  });

  int get resultCount => documents.length;

  bool get hasAggregation => aggregation != null;

  bool get hasAnalysis => analysis != null;
}

/// Internal result class for processing
class QueryResult {
  final QueryType type;
  final List<Document> documents;
  final AggregationResult? aggregation;
  final String? analysis;
  final double? confidence;
  final List<double>? similarities;
  final Duration executionTime;
  final String? debugInfo;

  const QueryResult({
    required this.type,
    required this.documents,
    this.aggregation,
    this.analysis,
    this.confidence,
    this.similarities,
    required this.executionTime,
    this.debugInfo,
  });

  int get resultCount => documents.length;

  bool get hasAggregation => aggregation != null;

  bool get hasAnalysis => analysis != null;
}

/// Parameters extracted from natural language for SQL queries
class SQLQueryParams {
  final String? vendor;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final bool wantSum;
  final bool wantAverage;
  final bool wantCount;

  const SQLQueryParams({
    this.vendor,
    this.category,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.wantSum = false,
    this.wantAverage = false,
    this.wantCount = false,
  });

  bool get hasDateFilter => startDate != null || endDate != null;
  bool get hasAmountFilter => minAmount != null || maxAmount != null;
  bool get hasAggregation => wantSum || wantAverage || wantCount;
}

/// Service for routing queries to appropriate search methods
class QueryRouterService extends BaseService {
  final IDatabaseService _databaseService;
  final EmbeddingService _embeddingService;
  final VectorDatabaseService? _vectorDbService;
  final GemmaModelService? _gemmaService;

  QueryRouterService(
    this._databaseService, {
    EmbeddingService? embeddingService,
    VectorDatabaseService? vectorDbService,
    GemmaModelService? gemmaService,
  })  : _embeddingService = embeddingService ?? EmbeddingService(),
        _vectorDbService = vectorDbService,
        _gemmaService = gemmaService;

  @override
  String get serviceName => 'QueryRouterService';

  /// Process a natural language query and return results
  Future<QueryResult> processQuery(String query) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Classify the query type
      final queryType = classifyQuery(query);
      logInfo('Query classified as: ${queryType.name} - "$query"');

      QueryResult result;

      switch (queryType) {
        case QueryType.structured:
          result = await _handleStructuredQuery(query, stopwatch);
          break;
        case QueryType.semantic:
          result = await _handleSemanticQuery(query, stopwatch);
          break;
        case QueryType.complex:
          result = await _handleComplexQuery(query, stopwatch);
          break;
      }

      stopwatch.stop();
      logInfo('Query processed in ${stopwatch.elapsedMilliseconds}ms, found ${result.documents.length} documents');

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      logError('Query processing failed', e, stackTrace);

      // Return empty result on error
      return QueryResult(
        type: QueryType.semantic,
        documents: [],
        executionTime: stopwatch.elapsed,
        debugInfo: 'Error: $e',
      );
    }
  }

  /// Route and execute a query, returning a result suitable for the UI
  Future<QueryRouterResult> routeAndExecute(String query) async {
    final result = await processQuery(query);

    // Convert Document objects to Map for UI compatibility
    final docMaps = result.documents.map((doc) {
      return {
        'id': doc.id,
        'title': doc.title,
        'extracted_text': doc.extractedText,
        'type': doc.type.name,
        'scan_date': doc.scanDate.millisecondsSinceEpoch,
        'tags': doc.tags.join(','),
        'metadata': doc.metadata,
        'storage_provider': doc.storageProvider,
        'is_encrypted': doc.isEncrypted ? 1 : 0,
        'confidence_score': doc.confidenceScore,
        'detected_language': doc.detectedLanguage,
        'device_info': doc.deviceInfo,
        'notes': doc.notes,
        'location': doc.location,
        'created_at': doc.createdAt.millisecondsSinceEpoch,
        'updated_at': doc.updatedAt.millisecondsSinceEpoch,
        'is_synced': doc.isSynced ? 1 : 0,
        'cloud_id': doc.cloudId,
        'last_synced_at': doc.lastSyncedAt?.millisecondsSinceEpoch,
        'is_multi_page': doc.isMultiPage ? 1 : 0,
        'page_count': doc.pageCount,
        'vendor': doc.vendor,
        'amount': doc.amount,
        'transaction_date': doc.transactionDate?.millisecondsSinceEpoch,
        'category': doc.category,
        'entity_confidence': doc.entityConfidence,
        'entities_extracted_at': doc.entitiesExtractedAt?.millisecondsSinceEpoch,
        'image_data': doc.imageData,
        'thumbnail_data': doc.thumbnailData,
        'image_format': doc.imageFormat,
        'image_size': doc.imageSize,
        'image_width': doc.imageWidth,
        'image_height': doc.imageHeight,
        'image_path': doc.imagePath,
      };
    }).toList();

    return QueryRouterResult(
      queryType: result.type,
      documents: docMaps,
      query: query,
      aggregation: result.aggregation,
      analysis: result.analysis,
      confidence: result.confidence,
      similarities: result.similarities,
      executionTime: result.executionTime,
      debugInfo: result.debugInfo,
    );
  }

  /// Classify a query into its type based on patterns
  QueryType classifyQuery(String query) {
    final lower = query.toLowerCase().trim();

    // Structured query patterns (SQL-answerable with aggregations)
    final structuredPatterns = [
      RegExp(r'how much.*(spent|spend|cost|paid|pay)', caseSensitive: false),
      RegExp(r'total.*(at|from|on|for)\s+\w+', caseSensitive: false),
      RegExp(r'(sum|total|average|avg|count)\s+(of|from|at)', caseSensitive: false),
      RegExp(r'(last|this|past)\s+(week|month|year)', caseSensitive: false),
      RegExp(r'\$\s*\d+', caseSensitive: false), // Dollar amounts
      RegExp(r'(more|less|over|under|above|below)\s+than\s+\$?\d+', caseSensitive: false),
      RegExp(r'between\s+\$?\d+\s+(and|to)\s+\$?\d+', caseSensitive: false),
    ];

    for (final pattern in structuredPatterns) {
      if (pattern.hasMatch(lower)) {
        return QueryType.structured;
      }
    }

    // Also check for specific vendor + time queries
    if (_detectVendorInQuery(lower) != null && _detectTimeRange(lower) != null) {
      return QueryType.structured;
    }

    // Complex query patterns (need LLM reasoning)
    final complexPatterns = [
      'compare',
      'difference between',
      'why',
      'explain',
      'recommend',
      'what should',
      'analysis',
      'trend',
      'pattern',
      'highest',
      'lowest',
      'most',
      'least',
    ];

    for (final pattern in complexPatterns) {
      if (lower.contains(pattern)) {
        return QueryType.complex;
      }
    }

    // Default to semantic (vector search)
    return QueryType.semantic;
  }

  /// Handle structured queries using SQL
  Future<QueryResult> _handleStructuredQuery(
    String query,
    Stopwatch stopwatch,
  ) async {
    final params = _parseQueryToSQL(query);
    final db = await _databaseService.database;

    // Build SQL query
    String sql = 'SELECT * FROM documents WHERE 1=1';
    List<dynamic> args = [];

    if (params.vendor != null) {
      sql += ' AND LOWER(vendor) LIKE ?';
      args.add('%${params.vendor!.toLowerCase()}%');
    }

    if (params.category != null) {
      sql += ' AND category = ?';
      args.add(params.category);
    }

    if (params.startDate != null) {
      sql += ' AND transaction_date >= ?';
      args.add(params.startDate!.millisecondsSinceEpoch);
    }

    if (params.endDate != null) {
      sql += ' AND transaction_date <= ?';
      args.add(params.endDate!.millisecondsSinceEpoch);
    }

    if (params.minAmount != null) {
      sql += ' AND amount >= ?';
      args.add(params.minAmount);
    }

    if (params.maxAmount != null) {
      sql += ' AND amount <= ?';
      args.add(params.maxAmount);
    }

    sql += ' ORDER BY transaction_date DESC LIMIT 100';

    logInfo('SQL: $sql with args: $args');

    final results = await db.rawQuery(sql, args);
    final documents = results.map((r) => Document.fromMap(r)).toList();

    // Calculate aggregation if requested
    AggregationResult? aggregation;
    if (params.hasAggregation || query.toLowerCase().contains('how much') ||
        query.toLowerCase().contains('total')) {
      final sum = documents.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.amount ?? 0.0),
      );

      final avg = documents.isNotEmpty ? sum / documents.length : null;

      String? dateRange;
      if (params.hasDateFilter) {
        dateRange = _formatDateRange(params.startDate, params.endDate);
      }

      aggregation = AggregationResult(
        totalAmount: sum,
        averageAmount: avg,
        documentCount: documents.length,
        vendor: params.vendor,
        category: params.category,
        dateRange: dateRange,
      );
    }

    stopwatch.stop();

    return QueryResult(
      type: QueryType.structured,
      documents: documents,
      aggregation: aggregation,
      executionTime: stopwatch.elapsed,
      debugInfo: 'SQL query: $sql',
    );
  }

  /// Handle semantic queries using vector similarity
  Future<QueryResult> _handleSemanticQuery(
    String query,
    Stopwatch stopwatch,
  ) async {
    // Initialize embedding service if needed
    if (!_embeddingService.isInitialized) {
      await _embeddingService.initialize();
    }

    // Generate query embedding
    final queryEmbedding = await _embeddingService.generateEmbedding(query);

    // Search vector database
    List<Document> documents = [];
    List<double> similarities = [];

    if (_vectorDbService != null) {
      final results = await _vectorDbService.searchSimilar(
        queryText: query,
        limit: 20,
        minSimilarity: 0.3,
      );

      for (final result in results) {
        documents.add(Document.fromMap(result));
        similarities.add((result['similarity'] as double?) ?? 0.0);
      }
    } else {
      // Fallback: search all documents and compute similarity
      final db = await _databaseService.database;
      final allDocs = await db.query('documents', limit: 100);

      for (final docMap in allDocs) {
        final doc = Document.fromMap(docMap);
        final docText = '${doc.title}. ${doc.extractedText}';
        final docEmbedding = await _embeddingService.generateEmbedding(docText);
        final similarity = EmbeddingService.cosineSimilarity(queryEmbedding, docEmbedding);

        if (similarity > 0.3) {
          documents.add(doc);
          similarities.add(similarity);
        }
      }

      // Sort by similarity
      final indexed = List.generate(documents.length, (i) => i);
      indexed.sort((a, b) => similarities[b].compareTo(similarities[a]));

      documents = indexed.map((i) => documents[i]).toList();
      similarities = indexed.map((i) => similarities[i]).toList();

      // Limit to top 20
      if (documents.length > 20) {
        documents = documents.sublist(0, 20);
        similarities = similarities.sublist(0, 20);
      }
    }

    stopwatch.stop();

    return QueryResult(
      type: QueryType.semantic,
      documents: documents,
      similarities: similarities,
      executionTime: stopwatch.elapsed,
    );
  }

  /// Handle complex queries using LLM
  Future<QueryResult> _handleComplexQuery(
    String query,
    Stopwatch stopwatch,
  ) async {
    // First get relevant documents via semantic search
    final semanticResult = await _handleSemanticQuery(query, stopwatch);

    // If Gemma is available, use it for analysis
    String? analysis;
    double? confidence;

    if (_gemmaService != null && await _gemmaService!.isModelDownloaded()) {
      try {
        await _gemmaService!.initialize();

        // TODO: Use Gemma to analyze documents with proper chat session
        // For now, return a summary of what was found
        analysis = 'Based on ${semanticResult.documents.length} documents found.';
        confidence = 0.7;

        logInfo('LLM analysis completed');
      } catch (e) {
        logWarning('LLM analysis failed, returning semantic results only: $e');
      }
    }

    stopwatch.stop();

    return QueryResult(
      type: QueryType.complex,
      documents: semanticResult.documents,
      similarities: semanticResult.similarities,
      analysis: analysis,
      confidence: confidence,
      executionTime: stopwatch.elapsed,
    );
  }

  /// Parse natural language query to SQL parameters
  SQLQueryParams _parseQueryToSQL(String query) {
    final lower = query.toLowerCase();

    // Extract vendor name
    final vendor = _detectVendorInQuery(lower);

    // Extract date range
    final dateRange = _detectTimeRange(lower);

    // Extract amount filters
    double? minAmount;
    double? maxAmount;

    final overMatch = RegExp(r'(over|above|more than)\s+\$?(\d+(?:\.\d{2})?)').firstMatch(lower);
    if (overMatch != null) {
      minAmount = double.tryParse(overMatch.group(2)!);
    }

    final underMatch = RegExp(r'(under|below|less than)\s+\$?(\d+(?:\.\d{2})?)').firstMatch(lower);
    if (underMatch != null) {
      maxAmount = double.tryParse(underMatch.group(2)!);
    }

    // Detect category
    String? category;
    final categories = [
      'grocery', 'restaurant', 'medical', 'pharmacy',
      'utilities', 'fuel', 'entertainment', 'retail',
      'services', 'travel', 'financial',
    ];
    for (final cat in categories) {
      if (lower.contains(cat)) {
        category = cat;
        break;
      }
    }

    // Detect aggregation type
    final wantSum = lower.contains('total') || lower.contains('how much') || lower.contains('sum');
    final wantAverage = lower.contains('average') || lower.contains('avg');
    final wantCount = lower.contains('how many') || lower.contains('count');

    return SQLQueryParams(
      vendor: vendor,
      category: category,
      startDate: dateRange?.$1,
      endDate: dateRange?.$2,
      minAmount: minAmount,
      maxAmount: maxAmount,
      wantSum: wantSum,
      wantAverage: wantAverage,
      wantCount: wantCount,
    );
  }

  /// Detect vendor name from query
  String? _detectVendorInQuery(String query) {
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
      'cvs': 'CVS',
      'walgreens': 'Walgreens',
      'starbucks': 'Starbucks',
      'mcdonalds': 'McDonald\'s',
      'chipotle': 'Chipotle',
      'shell': 'Shell',
      'exxon': 'Exxon',
      'home depot': 'Home Depot',
      'lowes': 'Lowe\'s',
    };

    for (final entry in vendorPatterns.entries) {
      if (query.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to extract vendor after "at", "from", "on"
    final prepositionMatch = RegExp(r'(?:at|from|on)\s+([a-z\s]+?)(?:\s+(?:last|this|in|for)|$)').firstMatch(query);
    if (prepositionMatch != null) {
      final extracted = prepositionMatch.group(1)?.trim();
      if (extracted != null && extracted.length > 2 && extracted.length < 30) {
        return extracted;
      }
    }

    return null;
  }

  /// Detect time range from query
  (DateTime, DateTime)? _detectTimeRange(String query) {
    final now = DateTime.now();

    if (query.contains('last month')) {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 0, 23, 59, 59);
      return (start, end);
    }

    if (query.contains('this month')) {
      final start = DateTime(now.year, now.month, 1);
      return (start, now);
    }

    if (query.contains('last week')) {
      final start = now.subtract(const Duration(days: 7));
      return (start, now);
    }

    if (query.contains('this week')) {
      final weekday = now.weekday;
      final start = now.subtract(Duration(days: weekday - 1));
      return (DateTime(start.year, start.month, start.day), now);
    }

    if (query.contains('last year')) {
      final start = DateTime(now.year - 1, 1, 1);
      final end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
      return (start, end);
    }

    if (query.contains('this year')) {
      final start = DateTime(now.year, 1, 1);
      return (start, now);
    }

    // Check for specific year
    final yearMatch = RegExp(r'(?:in|for)\s+(20\d{2})').firstMatch(query);
    if (yearMatch != null) {
      final year = int.parse(yearMatch.group(1)!);
      return (DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59));
    }

    return null;
  }

  /// Format date range for display
  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';

    if (start != null && end != null) {
      if (start.month == end.month && start.year == end.year) {
        return '${_monthName(start.month)} ${start.year}';
      }
      return '${_formatDate(start)} - ${_formatDate(end)}';
    }

    if (start != null) return 'since ${_formatDate(start)}';
    return 'until ${_formatDate(end!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
