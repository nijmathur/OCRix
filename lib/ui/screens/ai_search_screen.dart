/// AI-Powered Search Screen
/// Hybrid NLP search with entity extraction, vector search, and LLM analysis
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/llm_search/vector_search_service.dart';
import '../../services/llm_search/gemma_model_service.dart';
import '../../services/llm_search/query_router_service.dart';
import '../../services/document_reprocessing_service.dart';
import '../../core/interfaces/database_service_interface.dart';
import '../../models/document.dart';
import '../widgets/document_card.dart';
import 'document_detail_screen.dart';

class AISearchScreen extends StatefulWidget {
  final IDatabaseService databaseService;

  const AISearchScreen({super.key, required this.databaseService});

  @override
  State<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends State<AISearchScreen> {
  final _queryController = TextEditingController();
  late final VectorSearchService _searchService;
  late final GemmaModelService _gemmaService;
  late final QueryRouterService _queryRouter;
  late final DocumentReprocessingService _reprocessingService;

  bool _isInitializing = true;
  bool _isSearching = false;
  bool _isDownloadingGemmaModel = false;
  bool _isDownloadingEmbeddingModel = false;
  bool _isVectorizing = false;
  bool _isReprocessing = false;
  bool _modelFileAvailable = false;
  bool _embeddingModelJustLoaded = false;
  bool _gemmaModelJustInstalled = false;
  bool _showEmbeddingSuccess = false;
  bool _showGemmaSuccess = false;
  double _gemmaDownloadProgress = 0.0;
  double _embeddingDownloadProgress = 0.0;
  double _vectorizationProgress = 0.0;
  double _reprocessingProgress = 0.0;
  int _vectorizedCount = 0;
  int _totalDocsToVectorize = 0;
  int _reprocessedCount = 0;
  int _totalDocsToReprocess = 0;
  VectorSearchResult? _lastResult;
  QueryRouterResult? _lastRoutedResult;
  String? _error;
  List<Document> _documents = [];
  Map<String, int>? _vectorizationStats;
  Map<String, int>? _entityExtractionStats;

  @override
  void initState() {
    super.initState();
    _initializeSearchService();
  }

  Future<void> _initializeSearchService() async {
    try {
      // Initialize VectorSearchService
      _searchService = VectorSearchService(widget.databaseService);

      // Initialize DocumentReprocessingService for entity extraction
      _reprocessingService = DocumentReprocessingService(
        widget.databaseService,
      );

      // Show loading state for embedding model
      setState(() {
        _isDownloadingEmbeddingModel = true;
      });

      await _searchService.initialize();

      // Initialize QueryRouterService with VectorSearchService for intelligent query routing
      _queryRouter = QueryRouterService(
        widget.databaseService,
        vectorSearchService: _searchService,
      );

      // Check if embedding model was just loaded successfully
      final embeddingReady = _searchService.isReady;

      // Initialize Gemma service separately for model download check
      _gemmaService = GemmaModelService();
      final fileAvailable = await _gemmaService.isModelFileAvailable();

      // Get vectorization statistics
      final vectorStats = await _searchService.getVectorizationStats();

      // Get entity extraction statistics
      final entityStats = await _reprocessingService.getReprocessingStats();

      setState(() {
        _isInitializing = false;
        _isDownloadingEmbeddingModel = false;
        _modelFileAvailable = fileAvailable;
        _vectorizationStats = vectorStats;
        _entityExtractionStats = entityStats;

        // Show success banner if embedding model loaded
        if (embeddingReady) {
          _embeddingModelJustLoaded = true;
          _showEmbeddingSuccess = true;
        }
      });

      // Auto-hide embedding success banner after 5 seconds
      if (_embeddingModelJustLoaded) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showEmbeddingSuccess = false;
            });
          }
        });
      }

      // Auto-start vectorization if embedding model is ready but docs need vectorization
      if (_searchService.isReady && vectorStats['pending_documents']! > 0) {
        _startBackgroundVectorization();
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isDownloadingEmbeddingModel = false;
        _error = 'Failed to initialize search: $e';
      });
    }
  }

  Future<void> _startBackgroundVectorization() async {
    if (_isVectorizing) return;

    setState(() {
      _isVectorizing = true;
      _vectorizationProgress = 0.0;
      _vectorizedCount = 0;
      _totalDocsToVectorize = _vectorizationStats?['pending_documents'] ?? 0;
    });

    try {
      print('[AISearchScreen] Starting background vectorization...');

      final result = await _searchService.vectorizeAllDocuments(
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _vectorizedCount = current;
              _totalDocsToVectorize = total;
              _vectorizationProgress = current / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isVectorizing = false;
        });

        // Refresh stats
        final stats = await _searchService.getVectorizationStats();
        setState(() {
          _vectorizationStats = stats;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vectorization complete! ${result.vectorizedDocuments} documents indexed in ${result.duration.inSeconds}s',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVectorizing = false;
          _error = 'Vectorization failed: $e';
        });
      }
    }
  }

  Future<void> _startEntityReprocessing() async {
    if (_isReprocessing) return;

    setState(() {
      _isReprocessing = true;
      _reprocessingProgress = 0.0;
      _reprocessedCount = 0;
      _totalDocsToReprocess = _entityExtractionStats?['pending_documents'] ?? 0;
    });

    try {
      print('[AISearchScreen] Starting entity extraction reprocessing...');

      final result = await _reprocessingService.reprocessAllDocuments(
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _reprocessedCount = current;
              _totalDocsToReprocess = total;
              _reprocessingProgress = total > 0 ? current / total : 0.0;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isReprocessing = false;
        });

        // Refresh stats
        final entityStats = await _reprocessingService.getReprocessingStats();
        setState(() {
          _entityExtractionStats = entityStats;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entity extraction complete! ${result.processedDocuments} documents processed in ${result.duration.inSeconds}s',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReprocessing = false;
          _error = 'Entity extraction failed: $e';
        });
      }
    }
  }

  Future<void> _installFromPersistentStorage() async {
    setState(() {
      _isDownloadingGemmaModel = true;
      _gemmaDownloadProgress = 0.0;
      _error = null;
    });

    try {
      // Listen to installation progress
      _gemmaService.downloadProgress.listen(
        (progress) {
          if (mounted) {
            setState(() {
              _gemmaDownloadProgress = progress;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isDownloadingGemmaModel = false;
              _error = 'Installation failed: $error';
            });
          }
        },
      );

      // Install from persistent storage
      await _gemmaService.installFromPersistentStorage();

      if (mounted) {
        setState(() {
          _isDownloadingGemmaModel = false;
          _gemmaDownloadProgress = 1.0;
          _gemmaModelJustInstalled = true;
          _showGemmaSuccess = true;
        });

        // Auto-hide success banner after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showGemmaSuccess = false;
            });
          }
        });

        // Initialize the model and refresh LLM status
        try {
          await _gemmaService.initialize();
          await _searchService.refreshLLMStatus();
          setState(() {}); // Trigger rebuild to show AI + Vector badge
          print(
            '[AISearchScreen] Gemma initialized and search service refreshed',
          );
        } catch (e) {
          print(
            '[AISearchScreen] Failed to initialize Gemma after install: $e',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingGemmaModel = false;
          _error = 'Failed to install model: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _downloadModel() async {
    // Pick model file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['task'],
      dialogTitle: 'Select Gemma Model File (gemma2-2b-it.task)',
    );

    if (result == null || result.files.isEmpty) {
      // User cancelled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model selection cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access selected file'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloadingGemmaModel = true;
      _gemmaDownloadProgress = 0.0;
      _error = null;
    });

    try {
      // Listen to download progress
      _gemmaService.downloadProgress.listen(
        (progress) {
          if (mounted) {
            setState(() {
              _gemmaDownloadProgress = progress;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isDownloadingGemmaModel = false;
              _error = 'Installation failed: $error';
            });
          }
        },
      );

      // Start installation with selected file
      await _gemmaService.downloadModel(filePath);

      if (mounted) {
        setState(() {
          _isDownloadingGemmaModel = false;
          _gemmaDownloadProgress = 1.0;
          _gemmaModelJustInstalled = true;
          _showGemmaSuccess = true;
        });

        // Auto-hide success banner after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showGemmaSuccess = false;
            });
          }
        });

        // Initialize the model and refresh LLM status
        try {
          await _gemmaService.initialize();
          await _searchService.refreshLLMStatus();
          setState(() {}); // Trigger rebuild to show AI + Vector badge
          print(
            '[AISearchScreen] Gemma initialized and search service refreshed',
          );
        } catch (e) {
          print(
            '[AISearchScreen] Failed to initialize Gemma after install: $e',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingGemmaModel = false;
          _error = 'Failed to install model: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation failed: $e'),
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
    _searchService.dispose();
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

    if (!_searchService.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Embedding model not ready. Please wait for initialization.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _lastRoutedResult = null;
    });

    try {
      // Use QueryRouterService for intelligent routing
      final routedResult = await _queryRouter.routeAndExecute(query);

      // Convert results to Document objects
      final documents = routedResult.documents
          .map((row) => Document.fromMap(row))
          .toList();

      setState(() {
        _lastRoutedResult = routedResult;
        _lastResult = null; // Clear old result type
        _documents = documents;
        _isSearching = false;
      });

      // Show success message with query type
      if (mounted) {
        final queryTypeLabel = _getQueryTypeLabel(routedResult.queryType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${routedResult.documents.length} document(s) via $queryTypeLabel '
              'in ${routedResult.executionTime.inMilliseconds}ms',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
          SnackBar(content: Text(_error!), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Search failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getQueryTypeLabel(QueryType type) {
    switch (type) {
      case QueryType.structured:
        return 'SQL';
      case QueryType.semantic:
        return 'Vector';
      case QueryType.complex:
        return 'AI';
    }
  }

  Color _getQueryTypeColor(QueryType type) {
    switch (type) {
      case QueryType.structured:
        return Colors.blue;
      case QueryType.semantic:
        return Colors.purple;
      case QueryType.complex:
        return Colors.orange;
    }
  }

  IconData _getQueryTypeIcon(QueryType type) {
    switch (type) {
      case QueryType.structured:
        return Icons.table_chart;
      case QueryType.semantic:
        return Icons.hub;
      case QueryType.complex:
        return Icons.auto_awesome;
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
      resizeToAvoidBottomInset: true,
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
          // Scrollable banner section with constrained height
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Embedding Model Loading Indicator
                    if (_isDownloadingEmbeddingModel)
                      _buildEmbeddingModelLoading(),

                    // Embedding Model Success Banner
                    if (_showEmbeddingSuccess && _searchService.isReady)
                      _buildEmbeddingModelSuccess(),

                    // Gemma Model Success Banner
                    if (_showGemmaSuccess && _searchService.isLLMReady)
                      _buildGemmaModelSuccess(),

                    // Embedding Model Status Banner (if not ready and not loading)
                    if (!_searchService.isReady &&
                        !_isDownloadingEmbeddingModel)
                      _buildEmbeddingModelBanner(),

                    // Gemma Model Download Banner (optional, for analysis)
                    // Only show if no other banners are showing to reduce clutter
                    if (_searchService.isReady &&
                        !_searchService.isLLMReady &&
                        !_isDownloadingGemmaModel &&
                        !_showGemmaSuccess &&
                        !_isVectorizing &&
                        !_isReprocessing)
                      _buildGemmaModelBanner(),

                    // Download Progress (Gemma)
                    if (_isDownloadingGemmaModel) _buildGemmaDownloadProgress(),

                    // Vectorization Progress
                    if (_isVectorizing) _buildVectorizationProgress(),

                    // Entity Reprocessing Progress
                    if (_isReprocessing) _buildReprocessingProgress(),

                    // Vectorization Stats Banner (compact version)
                    if (_searchService.isReady &&
                        !_isVectorizing &&
                        _vectorizationStats != null &&
                        !_showEmbeddingSuccess)
                      _buildVectorizationStatsBanner(),

                    // Entity Extraction Stats Banner (only show if needed)
                    if (_searchService.isReady &&
                        !_isReprocessing &&
                        _entityExtractionStats != null &&
                        (_entityExtractionStats!['pending_documents'] ?? 0) > 0)
                      _buildEntityExtractionStatsBanner(),
                  ],
                ),
              ),
            ),
          ),

          // Search Input Section - Always visible
          if (_searchService.isReady) _buildSearchInput(),

          // Results Section
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildEmbeddingModelLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading embedding model...',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddingModelSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.green.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Embedding Model Ready',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vector search is now available',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.green.shade700,
            onPressed: () {
              setState(() {
                _showEmbeddingSuccess = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGemmaModelSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.green.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemma Model Installed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI analysis is now available for analytical queries',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.green.shade700,
            onPressed: () {
              setState(() {
                _showGemmaSuccess = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddingModelBanner() {
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
                child: Text(
                  'Embedding Model Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The embedding model (Universal Sentence Encoder) will be downloaded automatically on first use (~2MB)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '✓ Enables semantic vector search\n'
            '✓ Auto-downloads from TensorFlow Hub\n'
            '✓ Works 100% offline after download',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemmaModelBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Optional: Install Gemma for AI Analysis',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _modelFileAvailable
                ? 'Model found in storage - ready for quick install! Adds intelligent analysis to search results.'
                : 'Optionally install Gemma 2B (~2.6GB) for advanced query analysis.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          if (_modelFileAvailable)
            ElevatedButton.icon(
              onPressed: _installFromPersistentStorage,
              icon: const Icon(Icons.bolt),
              label: const Text('Install Gemma Model'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _downloadModel,
              icon: const Icon(Icons.install_desktop),
              label: const Text('Select Gemma Model File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGemmaDownloadProgress() {
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
                  'Installing Gemma 2B model...',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${(_gemmaDownloadProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _gemmaDownloadProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_gemmaDownloadProgress * 2.6).toStringAsFixed(2)} GB / 2.6 GB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildVectorizationProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.tertiaryContainer,
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
                  'Indexing documents for semantic search...',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              Text(
                '${(_vectorizationProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _vectorizationProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$_vectorizedCount / $_totalDocsToVectorize documents',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorizationStatsBanner() {
    final stats = _vectorizationStats!;
    final pending = stats['pending_documents'] ?? 0;
    final vectorized = stats['vectorized_documents'] ?? 0;
    final total = stats['total_documents'] ?? 0;

    if (pending == 0 && vectorized > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.green.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All $total documents indexed for semantic search',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (pending > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$pending documents pending vectorization',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ),
            TextButton.icon(
              onPressed: _startBackgroundVectorization,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Index Now'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildReprocessingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple.withOpacity(0.1),
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
                  'Extracting entities from documents...',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.deepPurple),
                ),
              ),
              Text(
                '${(_reprocessingProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _reprocessingProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.deepPurple,
            backgroundColor: Colors.deepPurple.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          Text(
            '$_reprocessedCount / $_totalDocsToReprocess documents',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityExtractionStatsBanner() {
    final stats = _entityExtractionStats!;
    final pending = stats['pending_documents'] ?? 0;
    final extracted = stats['extracted_documents'] ?? 0;
    final total = stats['total_documents'] ?? 0;

    // Don't show if no documents
    if (total == 0) {
      return const SizedBox.shrink();
    }

    // All documents have entities extracted
    if (pending == 0 && extracted > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.deepPurple.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high, color: Colors.deepPurple, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Entity data extracted from $extracted documents',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Some documents pending entity extraction
    if (pending > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.deepPurple.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high, color: Colors.deepPurple, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$pending documents need entity extraction',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.deepPurple),
              ),
            ),
            TextButton.icon(
              onPressed: _startEntityReprocessing,
              icon: const Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.deepPurple,
              ),
              label: const Text(
                'Extract Entities',
                style: TextStyle(color: Colors.deepPurple),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: TextField(
        controller: _queryController,
        decoration: InputDecoration(
          hintText: 'Search your documents...',
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
                  onPressed: _isSearching || !_searchService.isReady
                      ? null
                      : () => _performSearch(),
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: _isSearching || !_searchService.isReady
            ? null
            : (_) => _performSearch(),
        enabled: !_isSearching && _searchService.isReady,
      ),
    );
  }

  Widget _buildExampleQueries() {
    final examples = [
      'receipts from last month',
      'tax documents 2024',
      'invoices over \$100',
      'medical records',
      'contracts and agreements',
    ];

    return ExpansionTile(
      title: Text(
        'Example queries',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      leading: const Icon(Icons.lightbulb_outline, size: 20),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
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
        ),
      ],
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

    // Show routed result with aggregation
    if (_lastRoutedResult != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Query Type Badge and Info
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getQueryTypeColor(
                  _lastRoutedResult!.queryType,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getQueryTypeColor(_lastRoutedResult!.queryType),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getQueryTypeIcon(_lastRoutedResult!.queryType),
                        color: _getQueryTypeColor(_lastRoutedResult!.queryType),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getQueryTypeLabel(_lastRoutedResult!.queryType) +
                            ' Search',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _getQueryTypeColor(
                                _lastRoutedResult!.queryType,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getQueryTypeColor(
                            _lastRoutedResult!.queryType,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_lastRoutedResult!.documents.length} results',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Query: "${_lastRoutedResult!.query}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getQueryTypeColor(
                        _lastRoutedResult!.queryType,
                      ).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Aggregation Result Card (for structured queries with totals)
            if (_lastRoutedResult!.aggregation != null)
              _buildAggregationCard(_lastRoutedResult!.aggregation!),

            // Source Documents Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.article,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Documents (${_documents.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Document List
            if (_documents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No matching documents found',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  return DocumentCard(
                    document: _documents[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DocumentDetailScreen(document: _documents[index]),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      );
    }

    // Show legacy analysis result if available
    if (_lastResult != null && _lastResult!.hasAnalysis) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Analysis Answer Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (_lastResult!.confidence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(
                              _lastResult!.confidence!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_lastResult!.confidence! * 100).toInt()}% confident',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lastResult!.analysis!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on ${_lastResult!.resultCount} document(s)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Source Documents Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.article,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Source Documents (${_documents.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Document List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                return DocumentCard(
                  document: _documents[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DocumentDetailScreen(document: _documents[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    if (_lastResult == null &&
        _lastRoutedResult == null &&
        !_searchService.isReady) {
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
              'Embedding model initializing...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'The embedding model enables semantic vector search with complete privacy.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_lastResult == null && _lastRoutedResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Search using natural language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Try queries like:\n'
                '• "How much did I spend on Kroger?"\n'
                '• "Show me all medical bills"\n'
                '• "Receipts from last month"',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty && _lastResult != null) {
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
        return DocumentCard(
          document: _documents[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DocumentDetailScreen(document: _documents[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAggregationCard(AggregationResult aggregation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (aggregation.vendor != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    aggregation.vendor!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (aggregation.totalAmount != null) ...[
            const Text(
              'Total Spent',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${aggregation.totalAmount!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAggregationStat(
                'Documents',
                aggregation.documentCount.toString(),
                Icons.description,
              ),
              const SizedBox(width: 16),
              if (aggregation.averageAmount != null)
                _buildAggregationStat(
                  'Average',
                  '\$${aggregation.averageAmount!.toStringAsFixed(2)}',
                  Icons.trending_flat,
                ),
            ],
          ),
          if (aggregation.dateRange != null) ...[
            const SizedBox(height: 12),
            Text(
              'Period: ${aggregation.dateRange}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAggregationStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _showAuditLog() {
    final logs = _searchService.getRecentSearches(limit: 50);

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
                title: Text(log.query, style: const TextStyle(fontSize: 12)),
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
