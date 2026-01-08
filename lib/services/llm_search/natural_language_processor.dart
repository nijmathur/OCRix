/// Natural Language Processor for LLM Search
/// Uses Gemma LLM (MediaPipe) for natural language to SQL conversion
library;

import 'gemma_model_service.dart';

class NaturalLanguageProcessor {
  final GemmaModelService _gemmaService;

  NaturalLanguageProcessor(this._gemmaService);

  /// Process natural language query and convert to SQL using Gemma LLM
  Future<String> processQuery(String naturalLanguage) async {
    return await _gemmaService.generateSQL(naturalLanguage);
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

    return true;
  }
}
