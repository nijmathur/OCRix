/// SQL Validation Layer for LLM Search
/// Ensures only safe SELECT queries are executed
library;

import 'input_sanitizer.dart';

class SQLQueryValidator {
  static const List<String> allowedTables = [
    'documents',
    'user_settings',
  ];

  static const List<String> blockedKeywords = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'DROP',
    'ALTER',
    'CREATE',
    'TRUNCATE',
    'REPLACE',
    'EXEC',
    'EXECUTE',
    'PRAGMA',
    'ATTACH',
    'DETACH',
    'VACUUM',
    'SAVEPOINT',
    'RELEASE',
    'ROLLBACK',
    'COMMIT',
    'BEGIN',
  ];

  static const int maxResultLimit = 100;

  /// Validate and sanitize SQL query
  /// Throws [SecurityException] if query is unsafe
  String validateAndSanitizeSQL(String sql) {
    final normalized = sql.trim();

    // 1. Must be SELECT query
    if (!normalized.toUpperCase().startsWith('SELECT')) {
      throw SecurityException(
        'Only SELECT queries are allowed',
      );
    }

    // 2. Block dangerous keywords (using word boundaries)
    final upperSQL = normalized.toUpperCase();
    for (final keyword in blockedKeywords) {
      // Use word boundary regex to avoid false positives like "created_at" containing "CREATE"
      final pattern = RegExp(r'\b' + keyword + r'\b');
      if (pattern.hasMatch(upperSQL)) {
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
      throw SecurityException(
        'Nested queries are not allowed',
      );
    }

    // 6. Block UNION (could be used for injection)
    if (upperSQL.contains('UNION')) {
      throw SecurityException(
        'UNION queries are not allowed',
      );
    }

    return finalSQL;
  }

  void _validateTableNames(String sql) {
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
      final limit = int.tryParse(match.group(1)!);
      if (limit != null && limit > maxResultLimit) {
        return sql.replaceFirst(
          limitPattern,
          'LIMIT $maxResultLimit',
        );
      }
    }

    return sql;
  }

  int _countOccurrences(String text, String pattern) {
    return RegExp(pattern, caseSensitive: false).allMatches(text).length;
  }

  /// Quick validation for common SQL patterns
  bool looksLikeValidSelectQuery(String sql) {
    final upper = sql.trim().toUpperCase();

    // Must start with SELECT
    if (!upper.startsWith('SELECT')) return false;

    // Must have FROM
    if (!upper.contains('FROM')) return false;

    // Should not have dangerous keywords (using word boundaries)
    for (final keyword in blockedKeywords) {
      final pattern = RegExp(r'\b' + keyword + r'\b');
      if (pattern.hasMatch(upper)) return false;
    }

    return true;
  }
}
