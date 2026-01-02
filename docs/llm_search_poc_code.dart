/// Proof of Concept: LLM-Powered Search with Security Layers
/// This file demonstrates the security architecture for OCRix LLM search

import 'dart:async';
import 'package:sqflite/sqflite.dart';

// ============================================================================
// LAYER 1: Input Sanitization
// ============================================================================

class LLMQuerySanitizer {
  static const int maxQueryLength = 500;
  static const List<String> dangerousPatterns = [
    '--', ';', '/*', '*/', 'xp_', 'sp_',
    'exec', 'execute', 'eval', 'script'
  ];

  /// Sanitize user input before sending to LLM
  String sanitizeInput(String userQuery) {
    // 1. Trim and normalize whitespace
    final normalized = userQuery.trim().replaceAll(RegExp(r'\s+'), ' ');

    // 2. Length validation
    if (normalized.length > maxQueryLength) {
      throw SecurityException(
        'Query too long (max $maxQueryLength chars)',
      );
    }

    // 3. Empty check
    if (normalized.isEmpty) {
      throw ValidationException('Query cannot be empty');
    }

    // 4. Dangerous pattern detection
    final lowerQuery = normalized.toLowerCase();
    for (final pattern in dangerousPatterns) {
      if (lowerQuery.contains(pattern)) {
        throw SecurityException(
          'Invalid characters in query: "$pattern"',
        );
      }
    }

    // 5. Character whitelist (letters, numbers, spaces, basic punctuation)
    if (!RegExp(r'^[a-zA-Z0-9\s\.,\-\?\!\'\"]+$').hasMatch(normalized)) {
      throw SecurityException('Query contains invalid characters');
    }

    return normalized;
  }
}

// ============================================================================
// LAYER 2: Rate Limiting
// ============================================================================

class LLMSearchRateLimiter {
  final List<DateTime> _searchTimestamps = [];
  final int maxSearchesPerMinute;
  final int maxSearchesPerHour;

  LLMSearchRateLimiter({
    this.maxSearchesPerMinute = 10,
    this.maxSearchesPerHour = 100,
  });

  bool canSearch() {
    final now = DateTime.now();

    // Clean up old timestamps
    _searchTimestamps.removeWhere(
      (t) => now.difference(t).inHours >= 1,
    );

    // Check hourly limit
    final searchesLastHour = _searchTimestamps.length;
    if (searchesLastHour >= maxSearchesPerHour) {
      throw RateLimitException('Hourly search limit exceeded');
    }

    // Check per-minute limit
    final recentSearches = _searchTimestamps
        .where((t) => now.difference(t).inMinutes < 1)
        .length;

    if (recentSearches >= maxSearchesPerMinute) {
      throw RateLimitException('Too many searches. Please wait a moment.');
    }

    return true;
  }

  void recordSearch() {
    _searchTimestamps.add(DateTime.now());
  }

  void reset() {
    _searchTimestamps.clear();
  }
}

// ============================================================================
// LAYER 3: SQL Validation
// ============================================================================

class SQLQueryValidator {
  static const List<String> allowedTables = [
    'documents',
    'user_settings', // For search preferences
  ];

  static const List<String> blockedKeywords = [
    'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER',
    'CREATE', 'TRUNCATE', 'REPLACE', 'EXEC',
    'PRAGMA', 'ATTACH', 'DETACH', 'VACUUM'
  ];

  static const int maxResultLimit = 100;

  /// Validate LLM-generated SQL query
  String validateAndSanitizeSQL(String sql) {
    final normalized = sql.trim();

    // 1. Must be SELECT query
    if (!normalized.toUpperCase().startsWith('SELECT')) {
      throw SecurityException(
        'Only SELECT queries are allowed. Got: ${normalized.substring(0, 20)}...',
      );
    }

    // 2. Block dangerous keywords
    final upperSQL = normalized.toUpperCase();
    for (final keyword in blockedKeywords) {
      if (upperSQL.contains(keyword)) {
        throw SecurityException(
          'Query contains blocked keyword: $keyword',
        );
      }
    }

    // 3. Validate table names
    _validateTableNames(normalized);

    // 4. Ensure LIMIT clause exists and is reasonable
    String finalSQL = normalized;
    if (!upperSQL.contains('LIMIT')) {
      finalSQL += ' LIMIT $maxResultLimit';
    } else {
      finalSQL = _enforceLimitClause(finalSQL);
    }

    // 5. Block nested queries (simple check)
    if (_countOccurrences(upperSQL, 'SELECT') > 1) {
      throw SecurityException('Nested queries are not allowed');
    }

    return finalSQL;
  }

  void _validateTableNames(String sql) {
    final upperSQL = sql.toUpperCase();

    // Extract table names after FROM and JOIN keywords
    final fromPattern = RegExp(r'FROM\s+(\w+)', caseSensitive: false);
    final joinPattern = RegExp(r'JOIN\s+(\w+)', caseSensitive: false);

    final fromMatches = fromPattern.allMatches(sql);
    final joinMatches = joinPattern.allMatches(sql);

    for (final match in [...fromMatches, ...joinMatches]) {
      final tableName = match.group(1)?.toLowerCase();
      if (tableName != null && !allowedTables.contains(tableName)) {
        throw SecurityException(
          'Access to table "$tableName" is not allowed',
        );
      }
    }
  }

  String _enforceLimitClause(String sql) {
    final limitPattern = RegExp(r'LIMIT\s+(\d+)', caseSensitive: false);
    final match = limitPattern.firstMatch(sql);

    if (match != null) {
      final limit = int.parse(match.group(1)!);
      if (limit > maxResultLimit) {
        return sql.replaceFirst(
          limitPattern,
          'LIMIT $maxResultLimit',
        );
      }
    }

    return sql;
  }

  int _countOccurrences(String text, String pattern) {
    return pattern.allMatches(text).length;
  }
}

// ============================================================================
// LAYER 4: Read-Only Database Service
// ============================================================================

class ReadOnlyDatabaseService {
  final Database _database;
  final Duration queryTimeout;

  ReadOnlyDatabaseService(
    this._database, {
    this.queryTimeout = const Duration(seconds: 5),
  });

  /// Execute read-only query with strict validation
  Future<List<Map<String, dynamic>>> executeReadOnlyQuery(
    String sql, {
    List<Object?>? arguments,
  }) async {
    // Final validation before execution
    final validator = SQLQueryValidator();
    final validatedSQL = validator.validateAndSanitizeSQL(sql);

    try {
      // Execute with timeout
      return await _database
          .rawQuery(validatedSQL, arguments)
          .timeout(
            queryTimeout,
            onTimeout: () {
              throw TimeoutException('Query took too long to execute');
            },
          );
    } catch (e) {
      if (e is DatabaseException) {
        // Log and re-throw with safe message
        throw DatabaseQueryException(
          'Failed to execute query: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  /// Verify database connection is read-only (safety check)
  Future<bool> verifyReadOnly() async {
    try {
      // Try to execute a write operation
      await _database.execute('CREATE TABLE __test_write (id INTEGER)');
      // If we got here, the connection is NOT read-only
      return false;
    } catch (e) {
      // Expected: write operations should fail
      return true;
    }
  }
}

// ============================================================================
// LAYER 5: Audit Logging
// ============================================================================

class LLMSearchAuditLogger {
  final List<AuditLogEntry> _logs = [];

  void logSearch({
    required String userQuery,
    required String generatedSQL,
    required int resultCount,
    required Duration executionTime,
  }) {
    final entry = AuditLogEntry(
      timestamp: DateTime.now(),
      userQuery: userQuery,
      generatedSQL: generatedSQL,
      resultCount: resultCount,
      executionTime: executionTime,
    );

    _logs.add(entry);

    // Keep only last 1000 entries
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    // Log to console in debug mode
    print('[LLM SEARCH AUDIT] ${entry.toString()}');
  }

  void logSecurityViolation({
    required String userQuery,
    required String violationType,
    required String details,
  }) {
    print('[SECURITY VIOLATION] Type: $violationType');
    print('[SECURITY VIOLATION] Query: $userQuery');
    print('[SECURITY VIOLATION] Details: $details');

    // In production, this would send to security monitoring system
  }

  List<AuditLogEntry> getRecentLogs({int limit = 100}) {
    return _logs.reversed.take(limit).toList();
  }
}

class AuditLogEntry {
  final DateTime timestamp;
  final String userQuery;
  final String generatedSQL;
  final int resultCount;
  final Duration executionTime;

  AuditLogEntry({
    required this.timestamp,
    required this.userQuery,
    required this.generatedSQL,
    required this.resultCount,
    required this.executionTime,
  });

  @override
  String toString() {
    return 'Search at ${timestamp.toIso8601String()}: '
        '"$userQuery" → $resultCount results in ${executionTime.inMilliseconds}ms';
  }
}

// ============================================================================
// ORCHESTRATOR: Putting It All Together
// ============================================================================

class LLMSearchService {
  final ReadOnlyDatabaseService _database;
  final LLMQuerySanitizer _sanitizer;
  final LLMSearchRateLimiter _rateLimiter;
  final SQLQueryValidator _sqlValidator;
  final LLMSearchAuditLogger _auditLogger;
  final LLMInferenceService _llmService; // Platform-specific LLM

  LLMSearchService({
    required ReadOnlyDatabaseService database,
    required LLMInferenceService llmService,
  })  : _database = database,
        _llmService = llmService,
        _sanitizer = LLMQuerySanitizer(),
        _rateLimiter = LLMSearchRateLimiter(),
        _sqlValidator = SQLQueryValidator(),
        _auditLogger = LLMSearchAuditLogger();

  /// Main search method with all security layers
  Future<SearchResult> searchWithNaturalLanguage(String userQuery) async {
    final stopwatch = Stopwatch()..start();

    try {
      // LAYER 1: Input Sanitization
      final sanitizedQuery = _sanitizer.sanitizeInput(userQuery);

      // LAYER 2: Rate Limiting
      if (!_rateLimiter.canSearch()) {
        throw RateLimitException('Rate limit exceeded');
      }
      _rateLimiter.recordSearch();

      // LAYER 3: LLM Inference (isolated, no database access)
      final generatedSQL = await _llmService.generateSQLFromNaturalLanguage(
        sanitizedQuery,
      );

      // LAYER 4: SQL Validation
      final validatedSQL = _sqlValidator.validateAndSanitizeSQL(generatedSQL);

      // LAYER 5: Read-Only Database Execution
      final results = await _database.executeReadOnlyQuery(validatedSQL);

      stopwatch.stop();

      // LAYER 6: Audit Logging
      _auditLogger.logSearch(
        userQuery: userQuery,
        generatedSQL: validatedSQL,
        resultCount: results.length,
        executionTime: stopwatch.elapsed,
      );

      return SearchResult(
        query: userQuery,
        sql: validatedSQL,
        results: results,
        executionTime: stopwatch.elapsed,
      );
    } on SecurityException catch (e) {
      _auditLogger.logSecurityViolation(
        userQuery: userQuery,
        violationType: 'SecurityException',
        details: e.message,
      );
      rethrow;
    } catch (e) {
      _auditLogger.logSecurityViolation(
        userQuery: userQuery,
        violationType: e.runtimeType.toString(),
        details: e.toString(),
      );
      rethrow;
    }
  }
}

// ============================================================================
// MOCK LLM Service (Platform-specific implementation)
// ============================================================================

abstract class LLMInferenceService {
  Future<String> generateSQLFromNaturalLanguage(String query);
}

class GeminiNanoService implements LLMInferenceService {
  @override
  Future<String> generateSQLFromNaturalLanguage(String query) async {
    // Implementation using AICore/Gemini Nano
    // This would be in platform-specific code (Kotlin)
    throw UnimplementedError('Use platform channel for Gemini Nano');
  }
}

class Phi3Service implements LLMInferenceService {
  @override
  Future<String> generateSQLFromNaturalLanguage(String query) async {
    // Implementation using ONNX Runtime
    throw UnimplementedError('Use ONNX Runtime for Phi-3');
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class SearchResult {
  final String query;
  final String sql;
  final List<Map<String, dynamic>> results;
  final Duration executionTime;

  SearchResult({
    required this.query,
    required this.sql,
    required this.results,
    required this.executionTime,
  });
}

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => 'RateLimitException: $message';
}

class DatabaseQueryException implements Exception {
  final String message;
  DatabaseQueryException(this.message);
  @override
  String toString() => 'DatabaseQueryException: $message';
}

// ============================================================================
// EXAMPLE USAGE
// ============================================================================

void main() async {
  // Initialize services (pseudo-code)
  final database = await openDatabase('documents.db', readOnly: true);
  final readOnlyDB = ReadOnlyDatabaseService(database);
  final llmService = GeminiNanoService(); // or Phi3Service()

  final searchService = LLMSearchService(
    database: readOnlyDB,
    llmService: llmService,
  );

  // Example 1: Successful search
  try {
    final result = await searchService.searchWithNaturalLanguage(
      'find all invoices from last month',
    );
    print('Found ${result.results.length} documents');
    print('SQL: ${result.sql}');
    print('Time: ${result.executionTime.inMilliseconds}ms');
  } catch (e) {
    print('Search failed: $e');
  }

  // Example 2: Blocked malicious input
  try {
    await searchService.searchWithNaturalLanguage(
      '\'; DROP TABLE documents; --',
    );
  } on SecurityException catch (e) {
    print('✅ Security worked: ${e.message}');
  }

  // Example 3: Rate limiting
  try {
    for (var i = 0; i < 15; i++) {
      await searchService.searchWithNaturalLanguage('test query $i');
    }
  } on RateLimitException catch (e) {
    print('✅ Rate limiting worked: ${e.message}');
  }
}
