/// Read-Only Database Service for LLM Search
/// Executes validated queries with strict safety guarantees
library;

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'sql_validator.dart';
import 'input_sanitizer.dart';

class ReadOnlyDatabaseService {
  final Database _database;
  final Duration queryTimeout;
  final SQLQueryValidator _validator;

  ReadOnlyDatabaseService(
    this._database, {
    this.queryTimeout = const Duration(seconds: 5),
  }) : _validator = SQLQueryValidator();

  /// Execute a read-only query with full validation
  /// Throws various exceptions for security/validation failures
  Future<List<Map<String, dynamic>>> executeReadOnlyQuery(
    String sql, {
    List<Object?>? arguments,
  }) async {
    // Final validation before execution
    final validatedSQL = _validator.validateAndSanitizeSQL(sql);

    try {
      // Execute with timeout protection
      final results = await _database
          .rawQuery(validatedSQL, arguments)
          .timeout(
            queryTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Query took too long to execute (>${queryTimeout.inSeconds}s)',
              );
            },
          );

      return results;
    } on DatabaseException catch (e) {
      // Log and re-throw with safe message (don't expose DB internals)
      throw DatabaseQueryException(
        'Failed to execute search query',
        originalError: e,
      );
    } catch (e) {
      if (e is TimeoutException || e is SecurityException) {
        rethrow;
      }
      throw DatabaseQueryException(
        'Unexpected error during query execution',
        originalError: e,
      );
    }
  }

  /// Execute a simplified search (for keyword-based fallback)
  Future<List<Map<String, dynamic>>> searchDocuments({
    String? searchTerm,
    String? category,
    DateTime? afterDate,
    DateTime? beforeDate,
    List<String>? tags,
    int limit = 100,
  }) async {
    final conditions = <String>[];
    final arguments = <dynamic>[];

    // Build WHERE clause
    if (searchTerm != null && searchTerm.isNotEmpty) {
      conditions.add(
        '(title LIKE ? OR content LIKE ? OR tags LIKE ?)',
      );
      final term = '%$searchTerm%';
      arguments.addAll([term, term, term]);
    }

    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      arguments.add(category);
    }

    if (afterDate != null) {
      conditions.add('created_at >= ?');
      arguments.add(afterDate.toIso8601String());
    }

    if (beforeDate != null) {
      conditions.add('created_at <= ?');
      arguments.add(beforeDate.toIso8601String());
    }

    if (tags != null && tags.isNotEmpty) {
      // Search for tags in JSON array
      for (final tag in tags) {
        conditions.add('tags LIKE ?');
        arguments.add('%"$tag"%');
      }
    }

    // Build final query
    String sql = 'SELECT * FROM documents';
    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    sql += ' ORDER BY created_at DESC LIMIT $limit';

    // Validate and execute
    final validatedSQL = _validator.validateAndSanitizeSQL(sql);
    return await _database.rawQuery(validatedSQL, arguments);
  }

  /// Get document count for a query (for pagination)
  Future<int> countDocuments(String whereClause, List<dynamic> arguments) async {
    final sql = 'SELECT COUNT(*) as count FROM documents WHERE $whereClause';
    final validatedSQL = _validator.validateAndSanitizeSQL(sql);

    final results = await _database.rawQuery(validatedSQL, arguments);
    return results.first['count'] as int? ?? 0;
  }

  /// Verify database connection is truly read-only (safety check)
  Future<bool> verifyReadOnlyAccess() async {
    try {
      // Try to execute a write operation
      await _database.execute('CREATE TABLE __test_write_check (id INTEGER)');

      // If we got here, connection is NOT read-only (security issue!)
      return false;
    } catch (e) {
      // Expected: write operations should fail
      // This confirms read-only access
      return true;
    }
  }
}

/// Custom exception for database query errors
class DatabaseQueryException implements Exception {
  final String message;
  final Object? originalError;

  DatabaseQueryException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'DatabaseQueryException: $message (Original: $originalError)';
    }
    return 'DatabaseQueryException: $message';
  }
}
