import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../widgets/document_image_viewer.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final Document document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController.text = widget.document.title;
    _notesController.text = widget.document.notes ?? '';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareDocument();
                  break;
                case 'export':
                  _exportDocument();
                  break;
                case 'delete':
                  _deleteDocument();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Image'),
            Tab(icon: Icon(Icons.text_fields), text: 'Text'),
            Tab(icon: Icon(Icons.info), text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageTab(),
          _buildTextTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return DocumentImageViewer(
      document: widget.document,
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              widget.document.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isEditing) ...[
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
          ] else if (widget.document.notes != null &&
              widget.document.notes!.isNotEmpty) ...[
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.document.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Extracted Text',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.document.extractedText.isEmpty
                  ? 'No text extracted from this document'
                  : widget.document.extractedText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'Document Information',
            [
              _buildDetailRow('Type', widget.document.type.displayName),
              _buildDetailRow('Title', widget.document.title),
              _buildDetailRow(
                  'Created', _formatDate(widget.document.createdAt)),
              _buildDetailRow(
                  'Last Updated', _formatDate(widget.document.updatedAt)),
              _buildDetailRow(
                  'Scan Date', _formatDate(widget.document.scanDate)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'Technical Details',
            [
              _buildDetailRow('Confidence Score',
                  '${(widget.document.confidenceScore * 100).toInt()}%'),
              _buildDetailRow(
                  'Detected Language', widget.document.detectedLanguage),
              _buildDetailRow('Device Info', widget.document.deviceInfo),
              _buildDetailRow(
                  'Storage Provider', widget.document.storageProvider),
              _buildDetailRow(
                  'Encrypted', widget.document.isEncrypted ? 'Yes' : 'No'),
            ],
          ),
          if (widget.document.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Tags',
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.document.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
          if (widget.document.location != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Location',
              [
                _buildDetailRow('Location', widget.document.location!),
              ],
            ),
          ],
          if (widget.document.cloudId != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Cloud Sync',
              [
                _buildDetailRow('Cloud ID', widget.document.cloudId!),
                _buildDetailRow(
                    'Synced', widget.document.isSynced ? 'Yes' : 'No'),
                if (widget.document.lastSyncedAt != null)
                  _buildDetailRow('Last Synced',
                      _formatDate(widget.document.lastSyncedAt!)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedDocument = widget.document.copyWith(
        title: _titleController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(documentNotifierProvider.notifier)
          .updateDocument(updatedDocument);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareDocument() {
    // Implementation for sharing document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality not implemented yet'),
      ),
    );
  }

  void _exportDocument() {
    // Implementation for exporting document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality not implemented yet'),
      ),
    );
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content:
            Text('Are you sure you want to delete "${widget.document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(documentNotifierProvider.notifier)
            .deleteDocument(widget.document.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
