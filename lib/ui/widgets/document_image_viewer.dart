import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../models/document.dart';
import '../../models/document_page.dart';
import '../../providers/document_provider.dart';

class DocumentImageViewer extends ConsumerStatefulWidget {
  final Document document;

  const DocumentImageViewer({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentImageViewer> createState() => _DocumentImageViewerState();
}

class _DocumentImageViewerState extends ConsumerState<DocumentImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  final PageController _pageController = PageController();
  bool _isLoading = true;
  String? _error;
  Uint8List? _imageData;
  List<DocumentPage> _pages = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if this is a multi-page document
      if (widget.document.isMultiPage) {
        // Load all pages from database
        final databaseService = ref.read(databaseServiceProvider);
        final pages = await databaseService.getDocumentPages(widget.document.id);

        setState(() {
          _pages = pages;
          _isLoading = false;
        });
        return;
      }

      // Single-page document: load image data
      if (widget.document.imageData != null) {
        setState(() {
          _imageData = widget.document.imageData;
          _isLoading = false;
        });
        return;
      }

      // Fallback: if no image data, show error
      setState(() {
        _isLoading = false;
        _error = 'No image data available for this document';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading image...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImageData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Multi-page document
    if (widget.document.isMultiPage && _pages.isNotEmpty) {
      return _buildMultiPageView();
    }

    // Single-page document
    if (_imageData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No image data available',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return _buildSinglePageView(_imageData!);
  }

  Widget _buildSinglePageView(Uint8List imageData) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Image.memory(
            imageData,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The image data may be corrupted',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMultiPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final page = _pages[index];
            if (page.imageData == null) {
              return const Center(
                child: Text(
                  'No image data for this page',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Image.memory(
                    page.imageData!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
        // Page indicator
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _pages[_currentPage].isEnhanced
                      ? Icons.auto_fix_high
                      : Icons.insert_drive_file,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${_currentPage + 1} of ${_pages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Navigation buttons
        if (_currentPage > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_left, size: 40),
                color: Colors.white,
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        if (_currentPage < _pages.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_right, size: 40),
                color: Colors.white,
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
