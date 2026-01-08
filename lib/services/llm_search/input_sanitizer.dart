/// Input Sanitization Layer for LLM Search
/// Prevents SQL injection and validates user input
library;

class LLMInputSanitizer {
  static const int maxQueryLength = 500;
  static const List<String> dangerousPatterns = [
    '--',
    ';',
    '/*',
    '*/',
    'xp_',
    'sp_',
    'exec',
    'execute',
    'eval',
    'script',
    '\x00', // Null byte
  ];

  /// Sanitize user input before processing
  /// Throws [SecurityException] if input is malicious
  String sanitizeInput(String userQuery) {
    // 1. Trim and normalize whitespace
    final normalized = userQuery.trim().replaceAll(RegExp(r'\s+'), ' ');

    // 2. Length validation
    if (normalized.length > maxQueryLength) {
      throw SecurityException(
        'Query too long (max $maxQueryLength characters)',
      );
    }

    // 3. Empty check
    if (normalized.isEmpty) {
      throw ValidationException('Query cannot be empty');
    }

    // 4. Dangerous pattern detection
    final lowerQuery = normalized.toLowerCase();
    for (final pattern in dangerousPatterns) {
      if (lowerQuery.contains(pattern.toLowerCase())) {
        throw SecurityException('Invalid characters detected in query');
      }
    }

    // 5. Character whitelist (letters, numbers, spaces, basic punctuation)
    // Allow: a-z, A-Z, 0-9, space, . , - ? ! ' " $ ( )
    final allowedCharsPattern = RegExp(r'''^[a-zA-Z0-9\s.,\-?!()'"\$]+$''');
    if (!allowedCharsPattern.hasMatch(normalized)) {
      throw SecurityException('Query contains invalid characters');
    }

    return normalized;
  }

  /// Check if query looks suspicious (for logging/monitoring)
  bool isSuspicious(String query) {
    final lower = query.toLowerCase();

    // Check for SQL keywords that shouldn't appear in natural language
    final suspiciousKeywords = [
      'drop table',
      'delete from',
      'update set',
      'insert into',
      'create table',
      'alter table',
      'truncate',
    ];

    for (final keyword in suspiciousKeywords) {
      if (lower.contains(keyword)) {
        return true;
      }
    }

    return false;
  }
}

/// Custom exception for security violations
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
