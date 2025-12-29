import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../providers/document_provider.dart';
import '../../providers/image_enhancement_provider.dart';
import '../../models/document.dart';
import '../../models/captured_page.dart';
import '../../models/document_page.dart';
import '../../core/interfaces/image_enhancement_service_interface.dart';
import '../widgets/camera_preview.dart';
import '../widgets/document_preview.dart';
import '../widgets/image_enhancement_dialog.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<String> _selectedTags = [];
  DocumentType _selectedType = DocumentType.other;
  String? _capturedImagePath;
  bool _isProcessing = false;

  // Multi-page support
  bool _isMultiPageMode = false;
  final List<CapturedPage> _capturedPages = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerNotifierProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_capturedImagePath != null && !_isMultiPageMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
            ),
          if (_isMultiPageMode && _capturedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMultiPageDocument,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
            Tab(icon: Icon(Icons.edit), text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCameraTab(scannerState),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildCameraTab(ScannerState scannerState) {
    if (scannerState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (scannerState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              scannerState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(scannerNotifierProvider.notifier).initializeCamera();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Build the main content with mode selector
    return Column(
      children: [
        // Prominent mode selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.document_scanner, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Scan Mode:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Single Page'),
                      icon: Icon(Icons.insert_drive_file, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Multi-Page'),
                      icon: Icon(Icons.content_copy, size: 18),
                    ),
                  ],
                  selected: {_isMultiPageMode},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _isMultiPageMode = selection.first;
                      // Clear captured data when switching modes
                      if (_isMultiPageMode) {
                        _capturedImagePath = null;
                      } else {
                        _capturedPages.clear();
                      }
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main camera/preview content
        Expanded(
          child: _buildCameraContent(scannerState),
        ),
      ],
    );
  }

  Widget _buildCameraContent(ScannerState scannerState) {
    // Multi-page mode: show page grid and camera
    if (_isMultiPageMode) {
      return Column(
        children: [
          if (_capturedPages.isNotEmpty) _buildPageGrid(),
          Expanded(
            child: CameraPreviewWidget(
              onCapture: _captureMultiPageImage,
              onImageSelected: _handleMultiPageImageSelected,
              isCapturing: scannerState.isCapturing,
            ),
          ),
        ],
      );
    }

    // Single-page mode
    if (_capturedImagePath != null) {
      return DocumentPreview(
        imagePath: _capturedImagePath!,
        onRetake: () {
          setState(() {
            _capturedImagePath = null;
          });
        },
        onContinue: () {
          _tabController.animateTo(1);
        },
      );
    }

    return CameraPreviewWidget(
      onCapture: _captureImage,
      onImageSelected: _handleImageSelected,
      isCapturing: scannerState.isCapturing,
    );
  }

  Widget _buildDetailsTab() {
    if (_capturedImagePath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Capture an image first',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePreview(),
          const SizedBox(height: 24),
          _buildDocumentTypeSelector(),
          const SizedBox(height: 16),
          _buildTitleField(),
          const SizedBox(height: 16),
          _buildTagsField(),
          const SizedBox(height: 16),
          _buildNotesField(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            'assets/images/placeholder.png', // You'll need to add this
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DocumentType>(
          value: _selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: DocumentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getDocumentTypeIcon(type)),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
        hintText: 'Enter document title',
      ),
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _selectedTags.remove(tag);
                    });
                  },
                )),
            ActionChip(
              label: const Text('+ Add Tag'),
              onPressed: _showAddTagDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
        hintText: 'Add any additional notes...',
      ),
      maxLines: 3,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _capturedImagePath = null;
              });
              _tabController.animateTo(0);
            },
            child: const Text('Retake Photo'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _saveDocument,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Document'),
          ),
        ),
      ],
    );
  }

  Future<void> _captureImage() async {
    final imagePath =
        await ref.read(scannerNotifierProvider.notifier).captureImage();
    if (imagePath != null) {
      setState(() {
        _capturedImagePath = imagePath;
      });
    }
  }

  void _handleImageSelected(String imagePath) {
    setState(() {
      _capturedImagePath = imagePath;
    });
    // Switch to details tab to show the selected image
    _tabController.animateTo(1);
  }

  Widget _buildPageGrid() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedPages.length,
        itemBuilder: (context, index) {
          final page = _capturedPages[index];
          return _buildPageThumbnail(page, index);
        },
      ),
    );
  }

  Widget _buildPageThumbnail(CapturedPage page, int index) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(
                      File(page.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Page ${page.pageNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (page.isEnhanced)
                    const Icon(Icons.auto_fix_high,
                        size: 12, color: Colors.blue),
                ],
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              children: [
                // Enhancement button
                GestureDetector(
                  onTap: () => _showEnhancementDialog(page),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                GestureDetector(
                  onTap: () => _deletePageFromMultiPage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureMultiPageImage() async {
    final imagePath =
        await ref.read(scannerNotifierProvider.notifier).captureImage();
    if (imagePath != null) {
      final page = CapturedPage(
        id: _uuid.v4(),
        pageNumber: _capturedPages.length + 1,
        imagePath: imagePath,
      );
      setState(() {
        _capturedPages.add(page);
      });
    }
  }

  void _handleMultiPageImageSelected(String imagePath) {
    final page = CapturedPage(
      id: _uuid.v4(),
      pageNumber: _capturedPages.length + 1,
      imagePath: imagePath,
    );
    setState(() {
      _capturedPages.add(page);
    });
  }

  void _deletePageFromMultiPage(int index) {
    setState(() {
      _capturedPages.removeAt(index);
      // Renumber remaining pages
      for (int i = index; i < _capturedPages.length; i++) {
        _capturedPages[i] = _capturedPages[i].copyWith(pageNumber: i + 1);
      }
    });
  }

  Future<void> _showEnhancementDialog(CapturedPage page) async {
    // Load image bytes if not already loaded
    if (page.imageBytes == null) {
      final file = File(page.imagePath);
      page.imageBytes = await file.readAsBytes();
    }

    if (!mounted) return;

    final result = await showDialog<ImageEnhancementOptions>(
      context: context,
      builder: (context) => ImageEnhancementDialog(
        imageBytes: page.imageBytes!,
        onEnhance: (enhancedImage, metadata) {
          // This callback is not used anymore - we get the result from showDialog
        },
      ),
    );

    if (result != null) {
      // Apply enhancement
      final enhancementService = ref.read(imageEnhancementServiceProvider);
      final enhancementResult =
          await enhancementService.enhanceImage(page.imageBytes!, result);

      setState(() {
        final index = _capturedPages.indexOf(page);
        _capturedPages[index] = page.copyWith(
          enhancedImageBytes: enhancementResult.enhancedImageBytes,
          isEnhanced: true,
          enhancementOptions: result,
        );
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref.read(documentNotifierProvider.notifier).scanDocument(
            imagePath: _capturedImagePath!,
            title:
                _titleController.text.isNotEmpty ? _titleController.text : null,
            tags: _selectedTags,
            notes:
                _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveMultiPageDocument() async {
    if (_capturedPages.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process all pages: OCR and create DocumentPage objects
      final documentPages = <DocumentPage>[];

      for (int i = 0; i < _capturedPages.length; i++) {
        final capturedPage = _capturedPages[i];

        try {
          // Verify image file exists
          final file = File(capturedPage.imagePath);
          if (!await file.exists()) {
            throw Exception('Image file not found: ${capturedPage.imagePath}');
          }

          // Load image bytes for storage
          if (capturedPage.imageBytes == null) {
            capturedPage.imageBytes = await file.readAsBytes();
          }

          // Validate image bytes
          if (capturedPage.imageBytes == null ||
              capturedPage.imageBytes!.isEmpty) {
            throw Exception(
                'Image bytes are empty for page ${capturedPage.pageNumber}');
          }

          // Use enhanced image if available, otherwise original
          final imageToProcess =
              capturedPage.enhancedImageBytes ?? capturedPage.imageBytes!;

          // Perform OCR using file path (more reliable than bytes)
          final ocrService = ref.read(ocrServiceProvider);
          final ocrResult =
              await ocrService.extractTextFromImage(capturedPage.imagePath);

          // Create DocumentPage
          final documentPage = DocumentPage.create(
            documentId: '', // Will be set when document is created
            pageNumber: capturedPage.pageNumber,
            imageData: imageToProcess,
            originalImageData: capturedPage.enhancedImageBytes != null
                ? capturedPage.imageBytes
                : null,
            thumbnailData: null, // Will be generated by service
            extractedText: ocrResult.text,
            confidenceScore: ocrResult.confidence,
            isEnhanced: capturedPage.isEnhanced,
            enhancementMetadata:
                capturedPage.enhancementOptions?.toJson() ?? {},
          );

          documentPages.add(documentPage);
        } catch (pageError) {
          // Log the error but continue with other pages
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Warning: Page ${capturedPage.pageNumber} failed OCR: $pageError'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Add page without OCR text
          final documentPage = DocumentPage.create(
            documentId: '',
            pageNumber: capturedPage.pageNumber,
            imageData: capturedPage.imageBytes ?? Uint8List(0),
            originalImageData: capturedPage.enhancedImageBytes != null
                ? capturedPage.imageBytes
                : null,
            thumbnailData: null,
            extractedText: '[OCR failed: ${pageError.toString()}]',
            confidenceScore: 0.0,
            isEnhanced: capturedPage.isEnhanced,
            enhancementMetadata:
                capturedPage.enhancementOptions?.toJson() ?? {},
          );
          documentPages.add(documentPage);
        }
      }

      // Save multi-page document
      await ref.read(documentNotifierProvider.notifier).scanMultiPageDocument(
            pages: documentPages,
            title:
                _titleController.text.isNotEmpty ? _titleController.text : null,
            tags: _selectedTags,
            notes:
                _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Multi-page document saved successfully! (${_capturedPages.length} pages)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving multi-page document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                setState(() {
                  _selectedTags.add(tag);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.manual:
        return Icons.menu_book;
      case DocumentType.invoice:
        return Icons.request_quote;
      case DocumentType.businessCard:
        return Icons.contact_page;
      case DocumentType.id:
        return Icons.badge;
      case DocumentType.passport:
        return Icons.travel_explore;
      case DocumentType.license:
        return Icons.card_membership;
      case DocumentType.certificate:
        return Icons.workspace_premium;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }
}
