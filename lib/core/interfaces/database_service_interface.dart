import '../../models/document.dart';
import '../../models/user_settings.dart';
import '../../models/audit_log.dart';

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

  /// Insert a new document
  Future<String> insertDocument(Document document);

  /// Update an existing document
  Future<void> updateDocument(Document document);

  /// Delete a document
  Future<void> deleteDocument(String id);

  /// Search documents by query
  Future<List<Document>> searchDocuments(String query);

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
