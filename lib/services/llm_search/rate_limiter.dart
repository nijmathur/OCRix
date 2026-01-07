/// Rate Limiting Layer for LLM Search
/// Prevents abuse and resource exhaustion
library;

class LLMSearchRateLimiter {
  final List<DateTime> _searchTimestamps = [];
  final int maxSearchesPerMinute;
  final int maxSearchesPerHour;

  LLMSearchRateLimiter({
    this.maxSearchesPerMinute = 10,
    this.maxSearchesPerHour = 100,
  });

  /// Check if user can perform a search
  /// Throws [RateLimitException] if limits exceeded
  bool canSearch() {
    final now = DateTime.now();

    // Clean up old timestamps (older than 1 hour)
    _searchTimestamps.removeWhere((t) => now.difference(t).inHours >= 1);

    // Check hourly limit
    final searchesLastHour = _searchTimestamps.length;
    if (searchesLastHour >= maxSearchesPerHour) {
      throw RateLimitException(
        'Hourly search limit exceeded ($maxSearchesPerHour/hour). '
        'Please try again later.',
      );
    }

    // Check per-minute limit
    final recentSearches = _searchTimestamps
        .where((t) => now.difference(t).inMinutes < 1)
        .length;

    if (recentSearches >= maxSearchesPerMinute) {
      throw RateLimitException(
        'Too many searches. Please wait a moment before trying again.',
      );
    }

    return true;
  }

  /// Record a search (call after successful search)
  void recordSearch() {
    _searchTimestamps.add(DateTime.now());
  }

  /// Reset all limits (for testing or admin purposes)
  void reset() {
    _searchTimestamps.clear();
  }

  /// Get current search count statistics
  SearchStatistics getStatistics() {
    final now = DateTime.now();

    final searchesLastMinute = _searchTimestamps
        .where((t) => now.difference(t).inMinutes < 1)
        .length;

    final searchesLastHour = _searchTimestamps.length;

    return SearchStatistics(
      searchesLastMinute: searchesLastMinute,
      searchesLastHour: searchesLastHour,
      remainingThisMinute: maxSearchesPerMinute - searchesLastMinute,
      remainingThisHour: maxSearchesPerHour - searchesLastHour,
    );
  }
}

/// Statistics about search rate limiting
class SearchStatistics {
  final int searchesLastMinute;
  final int searchesLastHour;
  final int remainingThisMinute;
  final int remainingThisHour;

  SearchStatistics({
    required this.searchesLastMinute,
    required this.searchesLastHour,
    required this.remainingThisMinute,
    required this.remainingThisHour,
  });

  @override
  String toString() {
    return 'Searches: $searchesLastMinute/min, $searchesLastHour/hour | '
        'Remaining: $remainingThisMinute/min, $remainingThisHour/hour';
  }
}

/// Custom exception for rate limiting
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => 'RateLimitException: $message';
}
