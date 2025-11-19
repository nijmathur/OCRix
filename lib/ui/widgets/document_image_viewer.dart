import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../models/document.dart';

class DocumentImageViewer extends StatefulWidget {
  final Document document;

  const DocumentImageViewer({
    super.key,
    required this.document,
  });

  @override
  State<DocumentImageViewer> createState() => _DocumentImageViewerState();
}

class _DocumentImageViewerState extends State<DocumentImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isLoading = true;
  String? _error;
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First try to get image data from document
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
            _imageData!,
            fit: BoxFit.contain,
            // Don't limit cache for detail view - user wants full quality
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
}
