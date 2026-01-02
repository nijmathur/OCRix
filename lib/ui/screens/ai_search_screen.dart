/// AI-Powered Search Screen
/// Natural language search with strict security guarantees
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/llm_search/llm_search_service.dart';
import '../../services/llm_search/input_sanitizer.dart';
import '../../services/llm_search/rate_limiter.dart';
import '../../core/interfaces/database_service_interface.dart';
import '../../models/document.dart';
import '../widgets/document_card.dart';

class AISearchScreen extends StatefulWidget {
  final IDatabaseService databaseService;

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
  bool _isDownloadingModel = false;
  double _downloadProgress = 0.0;
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

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloadingModel = true;
      _downloadProgress = 0.0;
      _error = null;
    });

    try {
      // Listen to download progress
      _searchService.modelDownloadProgress.listen(
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isDownloadingModel = false;
              _error = 'Download failed: $error';
            });
          }
        },
      );

      // Start download
      await _searchService.downloadAndInitializeModel();

      if (mounted) {
        setState(() {
          _isDownloadingModel = false;
          _downloadProgress = 1.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemma model downloaded and ready!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingModel = false;
          _error = 'Failed to download model: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
          // Model Status Banner
          if (!_searchService.isModelReady && !_isDownloadingModel)
            _buildModelDownloadBanner(),

          // Download Progress
          if (_isDownloadingModel)
            _buildDownloadProgress(),

          // Search Input Section
          if (_searchService.isModelReady || _isDownloadingModel)
            _buildSearchInput(),

          // Stats Bar
          if (_searchService.isModelReady)
            _buildStatsBar(),

          // Example Queries (chips)
          if (_searchService.isModelReady)
            _buildExampleQueries(),

          // Results Section
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildModelDownloadBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download Gemma 2B model (~1.5GB) for AI-powered search',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download),
                  label: const Text('Download AI Model'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '✓ 100% on-device processing\n'
            '✓ Complete privacy (no cloud)\n'
            '✓ Works offline',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Downloading Gemma 2B model...',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _downloadProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_downloadProgress * 1500).toStringAsFixed(0)} MB / 1500 MB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _searchService.isModelReady
                      ? 'Ask anything about your documents'
                      : 'Preparing AI model...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_searchService.isModelReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'AI Ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
                      onPressed: _isSearching || !_searchService.isModelReady
                          ? null
                          : () => _performSearch(),
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onSubmitted: _isSearching || !_searchService.isModelReady
                ? null
                : (_) => _performSearch(),
            enabled: !_isSearching && _searchService.isModelReady,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_lastResult == null && !_searchService.isModelReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_for_offline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Download AI model to start searching',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'The Gemma 2B model enables natural language search with complete privacy.',
                textAlign: TextAlign.center,
              ),
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
