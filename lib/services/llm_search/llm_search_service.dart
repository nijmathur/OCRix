/// Main LLM Search Service
/// Orchestrates all security layers and natural language processing
library;

import 'dart:async';
import 'input_sanitizer.dart';
import 'sql_validator.dart';
import 'rate_limiter.dart';
import 'read_only_database_service.dart';
import 'natural_language_processor.dart';
import '../../core/interfaces/database_service_interface.dart';

class LLMSearchService {
  final IDatabaseService _databaseService;
  late final ReadOnlyDatabaseService _readOnlyDB;
  final LLMInputSanitizer _sanitizer;
  final LLMSearchRateLimiter _rateLimiter;
  final SQLQueryValidator _sqlValidator;
  final NaturalLanguageProcessor _nlpProcessor;
  final List<SearchAuditEntry> _auditLog;

  bool _isInitialized = false;

  LLMSearchService(this._databaseService)
      : _sanitizer = LLMInputSanitizer(),
        _rateLimiter = LLMSearchRateLimiter(),
        _sqlValidator = SQLQueryValidator(),
        _nlpProcessor = NaturalLanguageProcessor(),
        _auditLog = [];

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get database instance
    final db = await _databaseService.database;
    _readOnlyDB = ReadOnlyDatabaseService(db);

    // Verify read-only access
    final isReadOnly = await _readOnlyDB.verifyReadOnlyAccess();
    if (!isReadOnly) {
      throw SecurityException(
        'Database connection is not read-only! Security compromised.',
      );
    }

    _isInitialized = true;
  }

  /// Main search method with all security layers
  Future<SearchResult> searchWithNaturalLanguage(String userQuery) async {
    if (!_isInitialized) {
      throw StateError('LLMSearchService not initialized');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // ═══════════════════════════════════════════════════════════
      // LAYER 1: Input Sanitization
      // ═══════════════════════════════════════════════════════════
      final sanitizedQuery = _sanitizer.sanitizeInput(userQuery);

      // Check for suspicious patterns (log but don't block)
      if (_sanitizer.isSuspicious(sanitizedQuery)) {
        _logSuspiciousQuery(userQuery);
      }

      // ═══════════════════════════════════════════════════════════
      // LAYER 2: Rate Limiting
      // ═══════════════════════════════════════════════════════════
      if (!_rateLimiter.canSearch()) {
        throw RateLimitException('Rate limit exceeded');
      }

      // ═══════════════════════════════════════════════════════════
      // LAYER 3: Natural Language Processing
      // ═══════════════════════════════════════════════════════════
      final generatedSQL = _nlpProcessor.processQuery(sanitizedQuery);

      // ═══════════════════════════════════════════════════════════
      // LAYER 4: SQL Validation
      // ═══════════════════════════════════════════════════════════
      final validatedSQL = _sqlValidator.validateAndSanitizeSQL(generatedSQL);

      // ═══════════════════════════════════════════════════════════
      // LAYER 5: Read-Only Database Execution
      // ═══════════════════════════════════════════════════════════
      final results = await _readOnlyDB.executeReadOnlyQuery(validatedSQL);

      stopwatch.stop();

      // Record successful search
      _rateLimiter.recordSearch();

      // ═══════════════════════════════════════════════════════════
      // LAYER 6: Audit Logging
      // ═══════════════════════════════════════════════════════════
      _logSearch(
        userQuery: userQuery,
        generatedSQL: validatedSQL,
        resultCount: results.length,
        executionTime: stopwatch.elapsed,
        success: true,
      );

      return SearchResult(
        query: userQuery,
        sql: validatedSQL,
        results: results,
        resultCount: results.length,
        executionTime: stopwatch.elapsed,
        success: true,
      );
    } on SecurityException catch (e) {
      _logSecurityViolation(
        userQuery: userQuery,
        violationType: 'SecurityException',
        details: e.message,
      );
      rethrow;
    } on RateLimitException catch (e) {
      _logSecurityViolation(
        userQuery: userQuery,
        violationType: 'RateLimitException',
        details: e.message,
      );
      rethrow;
    } catch (e) {
      stopwatch.stop();
      _logSearch(
        userQuery: userQuery,
        generatedSQL: '',
        resultCount: 0,
        executionTime: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Simple keyword search (fallback)
  Future<SearchResult> simpleKeywordSearch(String keywords) async {
    if (!_isInitialized) {
      throw StateError('LLMSearchService not initialized');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final sanitized = _sanitizer.sanitizeInput(keywords);

      final results = await _readOnlyDB.searchDocuments(
        searchTerm: sanitized,
        limit: 100,
      );

      stopwatch.stop();

      return SearchResult(
        query: keywords,
        sql: 'Simple keyword search',
        results: results,
        resultCount: results.length,
        executionTime: stopwatch.elapsed,
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  /// Get audit log (for debugging/monitoring)
  List<SearchAuditEntry> getAuditLog({int limit = 100}) {
    return _auditLog.reversed.take(limit).toList();
  }

  /// Get rate limit statistics
  SearchStatistics getRateLimitStats() {
    return _rateLimiter.getStatistics();
  }

  /// Get example queries
  List<String> getExampleQueries() {
    return NaturalLanguageProcessor.getExampleQueries();
  }

  // ═══════════════════════════════════════════════════════════
  // Private Helper Methods
  // ═══════════════════════════════════════════════════════════

  void _logSearch({
    required String userQuery,
    required String generatedSQL,
    required int resultCount,
    required Duration executionTime,
    required bool success,
    String? error,
  }) {
    final entry = SearchAuditEntry(
      timestamp: DateTime.now(),
      userQuery: userQuery,
      generatedSQL: generatedSQL,
      resultCount: resultCount,
      executionTime: executionTime,
      success: success,
      error: error,
    );

    _auditLog.add(entry);

    // Keep only last 1000 entries
    if (_auditLog.length > 1000) {
      _auditLog.removeAt(0);
    }

    // Log to console in debug mode
    print('[LLM SEARCH] ${entry.toString()}');
  }

  void _logSecurityViolation({
    required String userQuery,
    required String violationType,
    required String details,
  }) {
    print('[SECURITY VIOLATION] Type: $violationType');
    print('[SECURITY VIOLATION] Query: "$userQuery"');
    print('[SECURITY VIOLATION] Details: $details');

    // In production, this would send to security monitoring system
    _logSearch(
      userQuery: userQuery,
      generatedSQL: '',
      resultCount: 0,
      executionTime: Duration.zero,
      success: false,
      error: '$violationType: $details',
    );
  }

  void _logSuspiciousQuery(String query) {
    print('[SUSPICIOUS QUERY] "$query"');
    // In production, this would send to monitoring system
  }
}

/// Result from LLM search
class SearchResult {
  final String query;
  final String sql;
  final List<Map<String, dynamic>> results;
  final int resultCount;
  final Duration executionTime;
  final bool success;
  final String? error;

  SearchResult({
    required this.query,
    required this.sql,
    required this.results,
    required this.resultCount,
    required this.executionTime,
    required this.success,
    this.error,
  });

  @override
  String toString() {
    return 'SearchResult(query: "$query", results: $resultCount, '
        'time: ${executionTime.inMilliseconds}ms, success: $success)';
  }
}

/// Audit log entry for search operations
class SearchAuditEntry {
  final DateTime timestamp;
  final String userQuery;
  final String generatedSQL;
  final int resultCount;
  final Duration executionTime;
  final bool success;
  final String? error;

  SearchAuditEntry({
    required this.timestamp,
    required this.userQuery,
    required this.generatedSQL,
    required this.resultCount,
    required this.executionTime,
    required this.success,
    this.error,
  });

  @override
  String toString() {
    final status = success ? '✓' : '✗';
    final time = executionTime.inMilliseconds;
    return '$status [${timestamp.toIso8601String()}] "$userQuery" → '
        '$resultCount results in ${time}ms${error != null ? " (Error: $error)" : ""}';
  }
}
