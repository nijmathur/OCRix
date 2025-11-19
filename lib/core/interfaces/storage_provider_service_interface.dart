import '../../models/document.dart';
import '../../models/storage_provider.dart';

/// Interface for storage provider operations
abstract class IStorageProviderService {
  /// Initialize the service
  Future<void> initialize();

  /// Get available storage providers
  List<StorageProviderType> getAvailableProviders();

  /// Get current storage provider
  Future<StorageProviderType> getCurrentProvider();

  /// Set storage provider
  Future<void> setProvider(StorageProviderType provider);

  /// Upload document to storage
  Future<String> uploadDocument(Document document);

  /// Download document from storage
  Future<String> downloadDocument(String documentId, String localPath);

  /// Delete document from storage
  Future<void> deleteDocument(String documentId);

  /// List documents in storage
  Future<List<String>> listDocuments({String? prefix});

  /// Check if connected to storage
  Future<bool> isConnected();

  /// Disconnect from storage
  Future<void> disconnect();

  /// Sync local documents to cloud
  Future<void> syncToCloud();

  /// Sync cloud documents to local
  Future<void> syncFromCloud();
}
