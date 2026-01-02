/// Natural Language Processor for LLM Search
/// Uses Gemma LLM (MediaPipe) for natural language to SQL conversion
library;

import 'gemma_model_service.dart';

class NaturalLanguageProcessor {
  final GemmaModelService _gemmaService;
  bool _usePatternFallback = false;

  NaturalLanguageProcessor(this._gemmaService);

  /// Process natural language query and convert to SQL using Gemma LLM
  Future<String> processQuery(String naturalLanguage) async {
    try {
      // Try LLM-based generation first
      if (!_usePatternFallback) {
        return await _gemmaService.generateSQL(naturalLanguage);
      }
    } catch (e) {
      print('[NaturalLanguageProcessor] LLM generation failed, using fallback: $e');
      _usePatternFallback = true;
    }

    // Fallback to pattern-based generation if LLM fails
    return _generateSQLWithPatterns(naturalLanguage);
  }

  /// Pattern-based SQL generation (fallback)
  String _generateSQLWithPatterns(String naturalLanguage) {
    final lower = naturalLanguage.toLowerCase().trim();

    // Extract components from query
    final category = _extractCategory(lower);
    final dateFilter = _extractDateFilter(lower);
    final searchTerms = _extractSearchTerms(lower, category);
    final orderBy = _extractOrderBy(lower);
    final limit = _extractLimit(lower);

    // Build SQL query
    final conditions = <String>[];

    // Add category filter
    if (category != null) {
      conditions.add("category = '$category'");
    }

    // Add date filter
    if (dateFilter != null) {
      conditions.add(dateFilter);
    }

    // Add search terms
    if (searchTerms.isNotEmpty) {
      final searchConditions = searchTerms
          .map((term) =>
              "(title LIKE '%$term%' OR content LIKE '%$term%' OR tags LIKE '%$term%')")
          .toList();

      if (searchConditions.length == 1) {
        conditions.add(searchConditions.first);
      } else {
        // Check if query uses "and" or "or"
        final useOr = lower.contains(' or ');
        final operator = useOr ? ' OR ' : ' AND ';
        conditions.add('(${searchConditions.join(operator)})');
      }
    }

    // Build final SQL
    String sql = 'SELECT * FROM documents';

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    sql += ' ORDER BY $orderBy';
    sql += ' LIMIT $limit';

    return sql;
  }

  /// Extract document category from query
  String? _extractCategory(String query) {
    // Check for explicit category mentions
    if (query.contains('invoice')) return 'invoice';
    if (query.contains('receipt')) return 'receipt';
    if (query.contains('contract')) return 'contract';
    if (query.contains('letter')) return 'letter';
    if (query.contains('form')) return 'form';
    if (query.contains('tax') || query.contains('taxes')) return 'tax';
    if (query.contains('bill')) return 'bill';
    if (query.contains('statement')) return 'statement';

    return null; // No specific category
  }

  /// Extract date filter from query
  String? _extractDateFilter(String query) {
    // Relative dates
    if (query.contains('today')) {
      return "date(created_at/1000, 'unixepoch') = date('now')";
    }

    if (query.contains('yesterday')) {
      return "date(created_at/1000, 'unixepoch') = date('now', '-1 day')";
    }

    if (query.contains('last week') || query.contains('past week')) {
      return "created_at >= strftime('%s', 'now', '-7 days') * 1000";
    }

    if (query.contains('last month') || query.contains('past month')) {
      return "created_at >= strftime('%s', 'now', '-30 days') * 1000";
    }

    if (query.contains('last year') || query.contains('past year')) {
      return "created_at >= strftime('%s', 'now', '-365 days') * 1000";
    }

    if (query.contains('this week')) {
      return "created_at >= strftime('%s', 'now', 'weekday 0', '-7 days') * 1000";
    }

    if (query.contains('this month')) {
      return "created_at >= strftime('%s', 'now', 'start of month') * 1000";
    }

    if (query.contains('this year')) {
      return "created_at >= strftime('%s', 'now', 'start of year') * 1000";
    }

    // Specific year
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(query);
    if (yearMatch != null) {
      final year = yearMatch.group(1);
      return "strftime('%Y', created_at/1000, 'unixepoch') = '$year'";
    }

    // Specific month names
    const months = {
      'january': '01',
      'february': '02',
      'march': '03',
      'april': '04',
      'may': '05',
      'june': '06',
      'july': '07',
      'august': '08',
      'september': '09',
      'october': '10',
      'november': '11',
      'december': '12',
    };

    for (final entry in months.entries) {
      if (query.contains(entry.key)) {
        final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(query);
        if (yearMatch != null) {
          final year = yearMatch.group(1);
          return "strftime('%Y-%m', created_at/1000, 'unixepoch') = '$year-${entry.value}'";
        } else {
          // Current year
          return "strftime('%m', created_at/1000, 'unixepoch') = '${entry.value}' AND "
              "strftime('%Y', created_at/1000, 'unixepoch') = strftime('%Y', 'now')";
        }
      }
    }

    return null; // No date filter
  }

  /// Extract search terms from query
  List<String> _extractSearchTerms(String query, String? category) {
    // Remove common words and category from search
    final stopWords = {
      'find',
      'show',
      'search',
      'get',
      'all',
      'my',
      'the',
      'from',
      'with',
      'for',
      'in',
      'on',
      'at',
      'to',
      'and',
      'or',
      'a',
      'an',
      if (category != null) category,
      'document',
      'documents',
      'file',
      'files',
    };

    // Remove date-related words
    final dateWords = {
      'today',
      'yesterday',
      'last',
      'past',
      'this',
      'week',
      'month',
      'year',
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    };

    final words = query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where((word) => !stopWords.contains(word))
        .where((word) => !dateWords.contains(word))
        .where((word) => !RegExp(r'^\d{4}$').hasMatch(word)) // Remove years
        .toList();

    // If query mentions specific companies or amounts, keep those
    final terms = <String>[];

    // Keep quoted phrases
    final quotedPattern = RegExp(r'"([^"]+)"');
    for (final match in quotedPattern.allMatches(query)) {
      final quoted = match.group(1);
      if (quoted != null) {
        terms.add(quoted);
      }
    }

    // Keep dollar amounts
    final amountPattern = RegExp(r'\$?(\d+(?:\.\d{2})?)');
    for (final match in amountPattern.allMatches(query)) {
      final amount = match.group(1);
      if (amount != null) {
        terms.add(amount);
      }
    }

    // Add remaining significant words (>2 chars)
    terms.addAll(words.where((w) => w.length > 2));

    return terms.take(5).toList(); // Limit to 5 terms
  }

  /// Extract sort order from query
  String _extractOrderBy(String query) {
    if (query.contains('oldest first') || query.contains('earliest')) {
      return 'created_at ASC';
    }

    if (query.contains('newest first') ||
        query.contains('latest') ||
        query.contains('recent')) {
      return 'created_at DESC';
    }

    if (query.contains('alphabetical') || query.contains('a to z')) {
      return 'title ASC';
    }

    // Default: newest first
    return 'created_at DESC';
  }

  /// Extract result limit from query
  int _extractLimit(String query) {
    // Look for explicit numbers
    final numberPattern = RegExp(r'\b(\d+)\s+(result|document|file)s?\b');
    final match = numberPattern.firstMatch(query);

    if (match != null) {
      final num = int.tryParse(match.group(1)!);
      if (num != null && num > 0 && num <= 100) {
        return num;
      }
    }

    // Default limit
    return 100;
  }

  /// Get example queries for UI
  static List<String> getExampleQueries() {
    return [
      'find all invoices',
      'receipts from last month',
      'contracts from 2025',
      'invoices from Acme Corp',
      'tax documents from this year',
      'receipts over \$100',
      'documents from last week',
      'all invoices from December',
    ];
  }

  /// Check if query is likely to return results
  bool isReasonableQuery(String query) {
    final lower = query.toLowerCase();

    // Too short
    if (lower.length < 3) return false;

    // Just a single word (probably too vague)
    if (!lower.contains(' ')) return false;

    // Has some meaningful content
    final hasCategory = _extractCategory(lower) != null;
    final hasDate = _extractDateFilter(lower) != null;
    final hasSearchTerms = _extractSearchTerms(lower, null).isNotEmpty;

    return hasCategory || hasDate || hasSearchTerms;
  }
}
