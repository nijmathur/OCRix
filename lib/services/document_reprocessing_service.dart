/// Document Reprocessing Service
/// Batch processes existing documents to extract entities
library;

import '../core/base/base_service.dart';
import '../core/interfaces/database_service_interface.dart';
import '../models/document.dart';
import '../services/database_service.dart';
import 'entity_extraction_service.dart';

/// Result of batch reprocessing operation
class ReprocessingResult {
  final int totalDocuments;
  final int processedDocuments;
  final int skippedDocuments;
  final int errorDocuments;
  final Duration duration;

  const ReprocessingResult({
    required this.totalDocuments,
    required this.processedDocuments,
    required this.skippedDocuments,
    required this.errorDocuments,
    required this.duration,
  });

  double get progressPercent =>
      totalDocuments > 0 ? processedDocuments / totalDocuments : 0.0;

  bool get isComplete =>
      processedDocuments + skippedDocuments + errorDocuments >= totalDocuments;

  @override
  String toString() {
    return 'ReprocessingResult('
        'total: $totalDocuments, '
        'processed: $processedDocuments, '
        'skipped: $skippedDocuments, '
        'errors: $errorDocuments, '
        'duration: ${duration.inSeconds}s)';
  }
}

/// Service for batch reprocessing documents to extract entities
class DocumentReprocessingService extends BaseService {
  final IDatabaseService _databaseService;
  final EntityExtractionService _entityService;

  bool _isProcessing = false;
  bool _shouldCancel = false;

  DocumentReprocessingService(
    this._databaseService, [
    EntityExtractionService? entityService,
  ]) : _entityService = entityService ?? EntityExtractionService();

  @override
  String get serviceName => 'DocumentReprocessingService';

  /// Check if currently processing
  bool get isProcessing => _isProcessing;

  /// Cancel ongoing processing
  void cancelProcessing() {
    if (_isProcessing) {
      _shouldCancel = true;
      logInfo('Reprocessing cancellation requested');
    }
  }

  /// Reprocess all documents that haven't had entities extracted
  Future<ReprocessingResult> reprocessAllDocuments({
    Function(int current, int total)? onProgress,
    bool forceReprocess = false,
  }) async {
    if (_isProcessing) {
      throw StateError('Reprocessing already in progress');
    }

    _isProcessing = true;
    _shouldCancel = false;
    final startTime = DateTime.now();

    try {
      // Get documents to process
      final db = await _databaseService.database;
      List<Map<String, dynamic>> docMaps;

      if (forceReprocess) {
        docMaps = await db.query('documents', orderBy: 'created_at DESC');
        logInfo('Force reprocessing all ${docMaps.length} documents');
      } else {
        docMaps = await db.query(
          'documents',
          where: 'entities_extracted_at IS NULL',
          orderBy: 'created_at DESC',
        );
        logInfo('Reprocessing ${docMaps.length} documents without entities');
      }

      final total = docMaps.length;

      if (total == 0) {
        logInfo('No documents to reprocess');
        return ReprocessingResult(
          totalDocuments: 0,
          processedDocuments: 0,
          skippedDocuments: 0,
          errorDocuments: 0,
          duration: Duration.zero,
        );
      }

      int processed = 0;
      int skipped = 0;
      int errors = 0;

      for (int i = 0; i < docMaps.length; i++) {
        // Check for cancellation
        if (_shouldCancel) {
          logInfo('Reprocessing cancelled at $i of $total');
          break;
        }

        final docMap = docMaps[i];
        final doc = Document.fromMap(docMap);

        try {
          // Skip documents with empty text
          if (doc.extractedText.trim().isEmpty) {
            logInfo('Skipping document with empty text: ${doc.id}');
            skipped++;
            continue;
          }

          // Extract entities
          final entity = await _entityService.extractEntities(
            doc.id,
            doc.extractedText,
          );

          // Update database with extracted entities
          final dbService = _databaseService;
          if (dbService is DatabaseService) {
            await dbService.updateDocumentEntities(
              documentId: doc.id,
              vendor: entity.vendor,
              amount: entity.amount,
              transactionDate: entity.transactionDate,
              category: entity.category?.name,
              entityConfidence: entity.confidence,
            );
          }

          if (entity.hasData) {
            processed++;
            logInfo(
              'Extracted entities for ${doc.id}: '
              'vendor=${entity.vendor}, amount=${entity.amount}',
            );
          } else {
            skipped++;
            logInfo('No entities found for ${doc.id}');
          }
        } catch (e) {
          errors++;
          logError('Failed to process document ${doc.id}', e);
        }

        // Report progress
        onProgress?.call(i + 1, total);

        // Rate limit to avoid overwhelming the system
        if (i > 0 && i % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      final duration = DateTime.now().difference(startTime);
      logInfo(
        'Reprocessing complete: $processed processed, $skipped skipped, '
        '$errors errors in ${duration.inSeconds}s',
      );

      return ReprocessingResult(
        totalDocuments: total,
        processedDocuments: processed,
        skippedDocuments: skipped,
        errorDocuments: errors,
        duration: duration,
      );
    } finally {
      _isProcessing = false;
      _shouldCancel = false;
    }
  }

  /// Reprocess a single document
  Future<bool> reprocessDocument(String documentId) async {
    try {
      final doc = await _databaseService.getDocument(documentId);
      if (doc == null) {
        logWarning('Document not found: $documentId');
        return false;
      }

      if (doc.extractedText.trim().isEmpty) {
        logWarning('Document has empty text: $documentId');
        return false;
      }

      final entity = await _entityService.extractEntities(
        doc.id,
        doc.extractedText,
      );

      final dbService = _databaseService;
      if (dbService is DatabaseService) {
        await dbService.updateDocumentEntities(
          documentId: doc.id,
          vendor: entity.vendor,
          amount: entity.amount,
          transactionDate: entity.transactionDate,
          category: entity.category?.name,
          entityConfidence: entity.confidence,
        );
      }

      logInfo(
        'Reprocessed document $documentId: ${entity.hasData ? 'found entities' : 'no entities'}',
      );
      return entity.hasData;
    } catch (e) {
      logError('Failed to reprocess document $documentId', e);
      return false;
    }
  }

  /// Get reprocessing statistics
  Future<Map<String, int>> getReprocessingStats() async {
    try {
      final dbService = _databaseService;
      if (dbService is DatabaseService) {
        return await dbService.getEntityExtractionStats();
      }

      // Fallback if not using DatabaseService
      final db = await _databaseService.database;
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM documents',
      );
      final pendingResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM documents WHERE entities_extracted_at IS NULL',
      );

      return {
        'total_documents': (totalResult.first['count'] as int?) ?? 0,
        'pending_documents': (pendingResult.first['count'] as int?) ?? 0,
        'extracted_documents':
            ((totalResult.first['count'] as int?) ?? 0) -
            ((pendingResult.first['count'] as int?) ?? 0),
      };
    } catch (e) {
      logError('Failed to get reprocessing stats', e);
      return {
        'total_documents': 0,
        'pending_documents': 0,
        'extracted_documents': 0,
      };
    }
  }
}
