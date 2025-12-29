import '../../models/document.dart';
import '../../models/document_summary.dart';
import '../../models/document_page.dart';
import '../../models/user_settings.dart';
import '../../models/audit_log.dart';
import 'dart:typed_data';

/// Interface for database operations
abstract class IDatabaseService {
  /// Get a document by ID
  Future<Document?> getDocument(String id);

  /// Get all documents with optional filtering
  Future<List<Document>> getAllDocuments({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  });

  /// Get document summaries (without full image data) for list views
  Future<List<DocumentSummary>> getDocumentSummaries({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  });

  /// Lazy load full image data for a document
  Future<Uint8List?> getDocumentImageData(String documentId);

  /// Insert a new document
  Future<String> insertDocument(Document document);

  /// Update an existing document
  Future<void> updateDocument(Document document);

  /// Delete a document
  Future<void> deleteDocument(String id);

  /// Search documents by query
  Future<List<Document>> searchDocuments(String query);

  /// Save a document page
  Future<void> saveDocumentPage(DocumentPage page);

  /// Get all pages for a document
  Future<List<DocumentPage>> getDocumentPages(String documentId);

  /// Get a specific page
  Future<DocumentPage?> getDocumentPage(String documentId, int pageNumber);

  /// Update a document page
  Future<void> updateDocumentPage(DocumentPage page);

  /// Delete a document page
  Future<void> deleteDocumentPage(String pageId);

  /// Get user settings
  Future<UserSettings> getUserSettings();

  /// Update user settings
  Future<void> updateUserSettings(UserSettings settings);

  /// Get audit logs
  Future<List<AuditLog>> getAuditLogs({
    int? limit,
    int? offset,
    AuditAction? action,
    String? resourceType,
  });

  /// Initialize the database
  Future<void> initialize();
}
