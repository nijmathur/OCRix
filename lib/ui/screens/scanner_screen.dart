import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/document_provider.dart';
import '../../models/document.dart';
import '../widgets/camera_preview.dart';
import '../widgets/document_preview.dart';

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
          if (_capturedImagePath != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
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
