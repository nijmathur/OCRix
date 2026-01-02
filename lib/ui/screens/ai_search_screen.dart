/// AI-Powered Search Screen
/// Natural language search with strict security guarantees
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/llm_search/llm_search_service.dart';
import '../../services/llm_search/input_sanitizer.dart';
import '../../services/llm_search/rate_limiter.dart';
import '../../services/database_service.dart';
import '../../models/document.dart';
import '../widgets/document_card.dart';

class AISearchScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const AISearchScreen({
    super.key,
    required this.databaseService,
  });

  @override
  State<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends State<AISearchScreen> {
  final _queryController = TextEditingController();
  late final LLMSearchService _searchService;

  bool _isInitializing = true;
  bool _isSearching = false;
  SearchResult? _lastResult;
  String? _error;
  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _initializeSearchService();
  }

  Future<void> _initializeSearchService() async {
    try {
      _searchService = LLMSearchService(widget.databaseService);
      await _searchService.initialize();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize search: $e';
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch({String? customQuery}) async {
    final query = customQuery ?? _queryController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      // Perform search with all security layers
      final result = await _searchService.searchWithNaturalLanguage(query);

      // Convert results to Document objects
      final documents = result.results
          .map((row) => Document.fromMap(row))
          .toList();

      setState(() {
        _lastResult = result;
        _documents = documents;
        _isSearching = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${result.resultCount} document(s) in '
              '${result.executionTime.inMilliseconds}ms',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on SecurityException catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Security Error: ${e.message}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on RateLimitException catch (e) {
      setState(() {
        _isSearching = false;
        _error = e.message;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Search failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing AI Search...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, size: 24),
            SizedBox(width: 8),
            Text('AI Search'),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'View Audit Log',
              onPressed: _showAuditLog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Section
          _buildSearchInput(),

          // Stats Bar
          _buildStatsBar(),

          // Example Queries (chips)
          _buildExampleQueries(),

          // Results Section
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask anything about your documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            decoration: InputDecoration(
              hintText: 'e.g., "find invoices from last month"',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isSearching ? null : () => _performSearch(),
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onSubmitted: _isSearching ? null : (_) => _performSearch(),
            enabled: !_isSearching,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    if (_lastResult == null) return const SizedBox.shrink();

    final stats = _searchService.getRateLimitStats();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Searches remaining: ${stats.remainingThisMinute}/min, '
              '${stats.remainingThisHour}/hour',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (kDebugMode && _lastResult != null)
            TextButton.icon(
              onPressed: _showSQLDialog,
              icon: const Icon(Icons.code, size: 16),
              label: const Text('View SQL'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExampleQueries() {
    final examples = _searchService.getExampleQueries();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try these examples:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return ActionChip(
                label: Text(example),
                onPressed: () {
                  _queryController.text = example;
                  _performSearch();
                },
                avatar: const Icon(Icons.lightbulb_outline, size: 16),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_lastResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter a natural language query above',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered search with 100% privacy\n(All processing happens on your device)',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            const Text('No documents found'),
            const SizedBox(height: 8),
            Text(
              'Query: "${_lastResult!.query}"',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        return DocumentCard(document: _documents[index]);
      },
    );
  }

  void _showSQLDialog() {
    if (_lastResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated SQL'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Query: "${_lastResult!.query}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Generated SQL:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _lastResult!.sql,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Results: ${_lastResult!.resultCount} documents',
              ),
              Text(
                'Time: ${_lastResult!.executionTime.inMilliseconds}ms',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAuditLog() {
    final logs = _searchService.getAuditLog(limit: 50);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Audit Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: Icon(
                  log.success ? Icons.check_circle : Icons.error,
                  color: log.success ? Colors.green : Colors.red,
                  size: 16,
                ),
                title: Text(
                  log.userQuery,
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  '${log.resultCount} results in ${log.executionTime.inMilliseconds}ms',
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Text(
                  '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
