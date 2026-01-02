import 'package:flutter/material.dart';
import '../../models/document.dart';
import 'document_card.dart';

class DocumentGrid extends StatelessWidget {
  final List<Document> documents;
  final Function(Document)? onDocumentTap;
  final bool showEmptyState;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const DocumentGrid({
    super.key,
    required this.documents,
    this.onDocumentTap,
    this.showEmptyState = true,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty && showEmptyState) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onTap: () => onDocumentTap?.call(document),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No documents found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by scanning your first document',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
