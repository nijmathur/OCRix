import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            _buildContentSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // Document image or placeholder - prefer thumbnail for performance
            if (document.thumbnailData != null)
              Center(
                child: Image.memory(
                  document.thumbnailData!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: 300, // Limit cache size for thumbnails
                  cacheHeight: 300,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to full image if thumbnail fails
                    if (document.imageData != null) {
                      return Image.memory(
                        document.imageData!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              _getDocumentTypeIcon(document.type),
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      );
                    }
                    return Center(
                      child: Icon(
                        _getDocumentTypeIcon(document.type),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              )
            else if (document.imageData != null)
              Center(
                child: Image.memory(
                  document.imageData!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: 300, // Limit cache size
                  cacheHeight: 300,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        _getDocumentTypeIcon(document.type),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Icon(
                  _getDocumentTypeIcon(document.type),
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            // Security indicator
            if (document.isEncrypted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            // Document type indicator
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  document.type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(document.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(document.confidenceScore * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                if (document.tags.isNotEmpty)
                  Icon(
                    Icons.label,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              ],
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
