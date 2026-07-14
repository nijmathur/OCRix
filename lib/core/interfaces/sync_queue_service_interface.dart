/// Interface for the background sync queue service
abstract interface class ISyncQueueService {
  /// Enqueue a document upload operation
  Future<void> enqueue(String documentId, String action);

  /// Process all pending items in the queue.
  /// Checks connectivity first; skips offline.
  /// Returns the number of items successfully synced.
  Future<int> processQueue();

  /// Initialize the service
  Future<void> initialize();
}
