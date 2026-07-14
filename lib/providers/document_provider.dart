import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/document.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/camera_service.dart';
import '../services/storage_provider_service.dart';
import '../services/encryption_service.dart';
import '../services/image_processing_service.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/ocr_service_interface.dart';
import '../core/interfaces/camera_service_interface.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/interfaces/storage_provider_service_interface.dart';
import '../core/interfaces/image_processing_service_interface.dart';
import '../core/models/ocr_result.dart';
import '../core/config/app_config.dart';
import '../services/audit_logging_service.dart';
import '../models/audit_log.dart';
import 'audit_provider.dart';
import 'troubleshooting_logger_provider.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';
import '../models/document_page.dart';
import '../services/llm_search/gemma_model_service.dart';
import '../services/llm_search/vector_search_service.dart';
import '../services/entity_extraction_service.dart';
import 'background_task_provider.dart';

part 'document_provider.freezed.dart';

// Service providers - using interfaces for dependency inversion
final databaseServiceProvider = Provider<IDatabaseService>((ref) {
  final service = DatabaseService();
  service.setTroubleshootingLogger(ref.read(troubleshootingLoggerProvider));
  return service;
});

final ocrServiceProvider = Provider<IOCRService>((ref) {
  final service = OCRService();
  service.setTroubleshootingLogger(ref.read(troubleshootingLoggerProvider));
  return service;
});

final cameraServiceProvider = ChangeNotifierProvider<CameraService>((ref) {
  final service = CameraService();
  service.setTroubleshootingLogger(ref.read(troubleshootingLoggerProvider));
  return service;
});

final encryptionServiceProvider = Provider<IEncryptionService>((ref) {
  final service = EncryptionService();
  service.setTroubleshootingLogger(ref.read(troubleshootingLoggerProvider));
  return service;
});

final storageProviderServiceProvider = Provider<IStorageProviderService>((ref) {
  final service = StorageProviderService();
  service.setEncryptionService(ref.read(encryptionServiceProvider));
  service.setTroubleshootingLogger(ref.read(troubleshootingLoggerProvider));
  service.setDatabaseService(ref.read(databaseServiceProvider));
  return service;
});

/// Provider for VectorSearchService (semantic document search)
/// Note: VectorSearchService uses debugPrint directly, not BaseService logging
final vectorSearchServiceProvider = Provider<VectorSearchService>((ref) {
  return VectorSearchService(ref.read(databaseServiceProvider));
});

final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getAllDocuments();
});

final documentProvider = FutureProvider.family<Document?, String>((
  ref,
  documentId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return databaseService.getDocument(documentId);
});

final documentSearchProvider = FutureProvider.family<List<Document>, String>((
  ref,
  query,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  if (query.isEmpty) {
    return databaseService.getAllDocuments();
  }
  return databaseService.searchDocuments(query);
});

final documentByTypeProvider =
    FutureProvider.family<List<Document>, DocumentType>((ref, type) async {
      final databaseService = ref.read(databaseServiceProvider);
      return databaseService.getAllDocuments(type: type);
    });

class DocumentNotifier extends AsyncNotifier<List<Document>> {
  int _currentPage = 0;
  bool _hasMore = true;
  DocumentType? _currentTypeFilter;
  String? _currentSearchQuery;

  IDatabaseService get _databaseService => ref.read(databaseServiceProvider);
  IOCRService get _ocrService => ref.read(ocrServiceProvider);
  IImageProcessingService get _imageProcessingService =>
      ref.read(imageProcessingServiceProvider);
  AuditLoggingService get _auditLoggingService =>
      ref.read(auditLoggingServiceProvider);
  ITroubleshootingLogger get _troubleshootingLogger =>
      ref.read(troubleshootingLoggerProvider);
  EntityExtractionService get _entityExtractionService =>
      EntityExtractionService();

  @override
  Future<List<Document>> build() async {
    final documents = await _databaseService.getAllDocuments(
      limit: AppConfig.documentsPerPage,
      offset: 0,
    );
    _hasMore = documents.length >= AppConfig.documentsPerPage;
    return documents;
  }

  Future<void> _loadDocuments({
    int? page,
    DocumentType? type,
    String? searchQuery,
    bool append = false,
  }) async {
    try {
      if (!append) {
        state = const AsyncValue.loading();
        _currentPage = page ?? 0;
        _currentTypeFilter = type;
        _currentSearchQuery = searchQuery;
      } else {
        _currentPage = page ?? _currentPage;
        _currentTypeFilter = type ?? _currentTypeFilter;
        _currentSearchQuery = searchQuery ?? _currentSearchQuery;
      }

      const limit = AppConfig.documentsPerPage;
      final offset = _currentPage * limit;

      final documents = await _databaseService.getAllDocuments(
        limit: limit,
        offset: offset,
        type: _currentTypeFilter,
        searchQuery: _currentSearchQuery,
      );

      if (documents.length < limit) {
        _hasMore = false;
      } else {
        _hasMore = true;
      }

      if (append && state.hasValue) {
        final currentDocs = state.value ?? [];
        state = AsyncValue.data([...currentDocs, ...documents]);
      } else {
        state = AsyncValue.data(documents);
      }
    } catch (e, stackTrace) {
      await _troubleshootingLogger.error(
        'Failed to load documents',
        tag: 'DocumentNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshDocuments() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadDocuments(append: false);
  }

  Future<void> loadMoreDocuments() async {
    if (!_hasMore || state.isLoading) return;

    _currentPage++;
    await _loadDocuments(page: _currentPage, append: true);
  }

  Future<void> filterDocuments({
    DocumentType? type,
    String? searchQuery,
  }) async {
    _currentPage = 0;
    _hasMore = true;
    await _loadDocuments(
      page: 0,
      type: type,
      searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
      append: false,
    );
  }

  bool get hasMore => _hasMore;

  Future<String> scanDocument({
    required String imagePath,
    String? title,
    List<String> tags = const [],
    String? notes,
    String? location,
  }) async {
    final previousState = state;
    try {
      state = const AsyncValue.loading();

      // Read and process image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      // Process image for optimal storage using ImageProcessingService
      final processedResult = await _imageProcessingService
          .processImageForStorage(imageBytes.toList());

      // Extract text using OCR from original image
      final ocrResult = await _ocrService.extractTextFromImage(imagePath);

      // Categorize document - use LLM if enabled, otherwise use ML Kit
      DocumentType documentType;
      List<String> extractedTags = [];
      bool useLLM = false;

      try {
        final settings = await _databaseService.getUserSettings();
        useLLM = settings.useLLMCategorization;
      } catch (e) {
        await _troubleshootingLogger.warning(
          'Failed to load settings, using default categorization',
          tag: 'DocumentNotifier',
          error: e,
        );
      }

      try {
        if (useLLM) {
          // Use LLM categorization (smarter but slower)
          await _troubleshootingLogger.info(
            'Using LLM categorization',
            tag: 'DocumentNotifier',
          );
          final gemmaService = GemmaModelService();
          await gemmaService.initialize();
          final result = await gemmaService.categorizeDocument(ocrResult.text);
          documentType = DocumentType.values.firstWhere(
            (e) => e.name == result.type,
            orElse: () => DocumentType.other,
          );
          extractedTags = result.tags;
          await _troubleshootingLogger.info(
            'LLM categorized as: $documentType (confidence: ${result.confidence}, tags: $extractedTags)',
            tag: 'DocumentNotifier',
          );
        } else {
          // Use keyword-based categorization (faster)
          documentType = await _ocrService.categorizeDocument(ocrResult.text);
        }
      } catch (e) {
        await _troubleshootingLogger.warning(
          'Categorization failed, falling back to keyword-based',
          tag: 'DocumentNotifier',
          error: e,
        );
        // Fallback to keyword-based categorization
        documentType = await _ocrService.categorizeDocument(ocrResult.text);
      }

      // Merge user-provided tags with LLM-extracted tags
      final allTags = <String>{...tags, ...extractedTags}.toList();

      // Create document with image data and thumbnail
      final document = Document.create(
        title: title ?? _generateTitle(ocrResult.text, documentType),
        imageData: Uint8List.fromList(processedResult.imageBytes),
        thumbnailData: processedResult.thumbnailBytes != null
            ? Uint8List.fromList(processedResult.thumbnailBytes!)
            : null,
        imageFormat: processedResult.format,
        imageSize: processedResult.size,
        imageWidth: processedResult.width,
        imageHeight: processedResult.height,
        imagePath: imagePath, // Keep for backward compatibility
        extractedText: ocrResult.text,
        type: documentType,
        confidenceScore: ocrResult.confidence,
        detectedLanguage: ocrResult.detectedLanguage,
        deviceInfo: 'Flutter App',
        notes: notes,
        location: location,
        tags: allTags,
      );

      // Save to database
      final documentId = await _databaseService.insertDocument(document);

      // Vectorize document in background (non-blocking)
      _vectorizeDocumentAsync(document);

      // Extract entities in background (non-blocking)
      _extractEntitiesAsync(document);

      // Clean up file system image after storing in database
      // Since we store processed images and thumbnails in DB, we don't need the file
      try {
        if (await imageFile.exists()) {
          await imageFile.delete();
          await _troubleshootingLogger.info(
            'Cleaned up temporary image file: $imagePath',
            tag: 'DocumentNotifier',
          );
        }
      } catch (e) {
        // Log but don't fail if cleanup fails
        await _troubleshootingLogger.warning(
          'Failed to cleanup image file',
          tag: 'DocumentNotifier',
          error: e,
        );
      }

      // Log user action (INFO level)
      await _auditLoggingService.logInfoAction(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: documentId,
        details: 'User scanned and created document: ${document.title}',
      );

      // Optimistic update: add new document to state without full reload
      if (state.hasValue) {
        final currentDocs = state.value ?? [];
        state = AsyncValue.data([document, ...currentDocs]);
      } else {
        await refreshDocuments();
      }

      await _troubleshootingLogger.info(
        'Document scanned and saved: $documentId',
        tag: 'DocumentNotifier',
      );
      return documentId;
    } catch (e, stackTrace) {
      await _troubleshootingLogger.error(
        'Failed to scan document',
        tag: 'DocumentNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      // Rollback optimistic update
      if (state != previousState) state = previousState;
      rethrow;
    }
  }

  Future<String> scanMultiPageDocument({
    required List<DocumentPage> pages,
    String? title,
    List<String> tags = const [],
    String? notes,
    String? location,
  }) async {
    final previousState = state;
    try {
      state = const AsyncValue.loading();

      if (pages.isEmpty) {
        throw Exception('No pages provided for multi-page document');
      }

      // Combine extracted text from all pages
      final combinedText = pages
          .map((p) => p.extractedText)
          .join('\n\n--- Page Break ---\n\n');

      // Use the first page's confidence score as overall confidence
      final avgConfidence =
          pages.fold<double>(0.0, (sum, page) => sum + page.confidenceScore) /
          pages.length;

      // Categorize document based on combined text
      final documentType = await _ocrService.categorizeDocument(combinedText);

      // Get first page's image for thumbnail
      final firstPage = pages.first;

      // Create multi-page document
      final document = Document.create(
        title: title ?? _generateTitle(combinedText, documentType),
        imageData: firstPage.imageData!,
        thumbnailData: firstPage.thumbnailData,
        imageFormat: 'jpg', // Default format
        imageSize: firstPage.imageData!.length,
        imageWidth: 0, // Will be calculated if needed
        imageHeight: 0,
        imagePath: '', // Not needed for multi-page
        extractedText: combinedText,
        type: documentType,
        confidenceScore: avgConfidence,
        detectedLanguage: '', // Could detect from combined text
        deviceInfo: 'Flutter App',
        notes: notes,
        location: location,
        tags: tags,
        isMultiPage: true,
        pageCount: pages.length,
      );

      // Save document to database
      final documentId = await _databaseService.insertDocument(document);

      // Update pages with document ID and save them
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i].copyWith(documentId: documentId);
        await _databaseService.saveDocumentPage(page);
      }

      // Vectorize document in background (non-blocking)
      _vectorizeDocumentAsync(document);

      // Extract entities in background (non-blocking)
      _extractEntitiesAsync(document);

      // Log user action (INFO level)
      await _auditLoggingService.logInfoAction(
        action: AuditAction.create,
        resourceType: 'document',
        resourceId: documentId,
        details:
            'User scanned and created multi-page document: ${document.title} (${pages.length} pages)',
      );

      // Optimistic update: add new document to state without full reload
      if (state.hasValue) {
        final currentDocs = state.value ?? [];
        state = AsyncValue.data([document, ...currentDocs]);
      } else {
        await refreshDocuments();
      }

      await _troubleshootingLogger.info(
        'Multi-page document scanned and saved: $documentId (${pages.length} pages)',
        tag: 'DocumentNotifier',
      );
      return documentId;
    } catch (e, stackTrace) {
      await _troubleshootingLogger.error(
        'Failed to scan multi-page document',
        tag: 'DocumentNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = previousState; // Rollback
      rethrow;
    }
  }

  Future<void> updateDocument(Document document) async {
    final previousState = state;
    try {
      final updatedDocument = document.copyWith(updatedAt: DateTime.now());

      await _databaseService.updateDocument(updatedDocument);

      // Log user action (INFO level)
      await _auditLoggingService.logInfoAction(
        action: AuditAction.update,
        resourceType: 'document',
        resourceId: document.id,
        details: 'User updated document: ${document.title}',
      );

      // Optimistic update: update document in state directly
      if (state.hasValue) {
        final docs = state.value ?? [];
        final index = docs.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          state = AsyncValue.data([
            ...docs.sublist(0, index),
            updatedDocument,
            ...docs.sublist(index + 1),
          ]);
        } else {
          // If not found, refresh
          await refreshDocuments();
        }
      } else {
        await refreshDocuments();
      }

      await _troubleshootingLogger.info(
        'Document updated: ${document.id}',
        tag: 'DocumentNotifier',
      );
    } catch (e, stackTrace) {
      await _troubleshootingLogger.error(
        'Failed to update document',
        tag: 'DocumentNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = previousState; // Rollback
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final previousState = state;
    try {
      await _databaseService.deleteDocument(documentId);

      // Log user action (INFO level)
      await _auditLoggingService.logInfoAction(
        action: AuditAction.delete,
        resourceType: 'document',
        resourceId: documentId,
        details: 'User deleted document',
      );

      // Optimistic update: remove document from state directly
      if (state.hasValue) {
        final docs = state.value ?? [];
        state = AsyncValue.data(docs.where((d) => d.id != documentId).toList());
      } else {
        await refreshDocuments();
      }

      await _troubleshootingLogger.info(
        'Document deleted: $documentId',
        tag: 'DocumentNotifier',
      );
    } catch (e, stackTrace) {
      await _troubleshootingLogger.error(
        'Failed to delete document',
        tag: 'DocumentNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = previousState; // Rollback
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    try {
      await filterDocuments(searchQuery: query);
      return state.value ?? [];
    } catch (e) {
      await _troubleshootingLogger.error(
        'Failed to search documents',
        tag: 'DocumentNotifier',
        error: e,
      );
      return [];
    }
  }

  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    try {
      await filterDocuments(type: type);
      return state.value ?? [];
    } catch (e) {
      await _troubleshootingLogger.error(
        'Failed to get documents by type',
        tag: 'DocumentNotifier',
        error: e,
      );
      return [];
    }
  }

  /// Vectorize document asynchronously in the background (non-blocking)
  void _vectorizeDocumentAsync(Document document) {
    final vectorService = ref.read(vectorSearchServiceProvider);
    if (!vectorService.isReady) {
      return; // Embedding model not loaded; task skipped (not an error)
    }

    final taskNotifier = ref.read(backgroundTaskNotifierProvider.notifier);
    taskNotifier.markRunning(document.id, BackgroundTaskType.vectorization);

    Future.microtask(() async {
      try {
        final documentMap = {
          'id': document.id,
          'title': document.title,
          'extracted_text': document.extractedText,
        };
        await vectorService.vectorizeDocument(documentMap);
        taskNotifier.markCompleted(document.id, BackgroundTaskType.vectorization);
        await _troubleshootingLogger.info(
          'Document vectorized: ${document.id}',
          tag: 'DocumentNotifier',
        );
      } catch (e) {
        taskNotifier.markFailed(document.id, BackgroundTaskType.vectorization, e);
        await _troubleshootingLogger.warning(
          'Vectorization failed for ${document.id}',
          tag: 'DocumentNotifier',
          error: e,
        );
      }
    });
  }

  /// Extract entities from document asynchronously in the background (non-blocking)
  void _extractEntitiesAsync(Document document) {
    // Skip if document has empty text
    if (document.extractedText.trim().isEmpty) {
      return;
    }

    final taskNotifier = ref.read(backgroundTaskNotifierProvider.notifier);
    taskNotifier.markRunning(document.id, BackgroundTaskType.entityExtraction);

    // Run entity extraction in background without blocking
    Future.microtask(() async {
      try {
        final entity = await _entityExtractionService.extractEntities(
          document.id,
          document.extractedText,
        );

        // Only update if meaningful entities were found
        if (entity.hasData) {
          await _databaseService.updateDocumentEntities(
            documentId: document.id,
            vendor: entity.vendor,
            amount: entity.amount,
            transactionDate: entity.transactionDate,
            category: entity.category?.name,
            entityConfidence: entity.confidence,
          );

          await _troubleshootingLogger.info(
            'Entities extracted for ${document.id}: '
            'vendor=${entity.vendor}, amount=${entity.amount}, '
            'category=${entity.category?.name}',
            tag: 'DocumentNotifier',
          );
        } else {
          await _troubleshootingLogger.info(
            'No entities found for document: ${document.id}',
            tag: 'DocumentNotifier',
          );
        }
        taskNotifier.markCompleted(document.id, BackgroundTaskType.entityExtraction);
      } catch (e) {
        taskNotifier.markFailed(document.id, BackgroundTaskType.entityExtraction, e);
        await _troubleshootingLogger.warning(
          'Failed to extract entities from document: ${document.id}',
          tag: 'DocumentNotifier',
          error: e,
        );
      }
    });
  }

  String _generateTitle(String text, DocumentType type) {
    if (text.isEmpty) {
      return '${type.displayName} - ${DateTime.now().toString().split(' ')[0]}';
    }

    // Take first line or first 50 characters
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length > 50) {
      return '${firstLine.substring(0, 50)}...';
    }
    return firstLine.isNotEmpty
        ? firstLine
        : '${type.displayName} - ${DateTime.now().toString().split(' ')[0]}';
  }
}

final imageProcessingServiceProvider = Provider<IImageProcessingService>((ref) {
  return ImageProcessingService();
});

final documentNotifierProvider =
    AsyncNotifierProvider<DocumentNotifier, List<Document>>(
      DocumentNotifier.new,
    );

class DocumentDetailNotifier extends FamilyAsyncNotifier<Document?, String> {
  @override
  Future<Document?> build(String arg) async {
    final databaseService = ref.read(databaseServiceProvider);
    return databaseService.getDocument(arg);
  }

  Future<void> updateDocument(Document document) async {
    final databaseService = ref.read(databaseServiceProvider);
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      final updatedDocument = document.copyWith(updatedAt: DateTime.now());
      await databaseService.updateDocument(updatedDocument);
      state = AsyncValue.data(updatedDocument);
      await logger.info(
        'Document updated: ${document.id}',
        tag: 'DocumentDetailNotifier',
      );
    } catch (e, stackTrace) {
      await logger.error(
        'Failed to update document',
        tag: 'DocumentDetailNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final databaseService = ref.read(databaseServiceProvider);
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      await databaseService.deleteDocument(documentId);
      state = const AsyncValue.data(null);
      await logger.info(
        'Document deleted: $documentId',
        tag: 'DocumentDetailNotifier',
      );
    } catch (e, stackTrace) {
      await logger.error(
        'Failed to delete document',
        tag: 'DocumentDetailNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final documentDetailNotifierProvider =
    AsyncNotifierProvider.family<DocumentDetailNotifier, Document?, String>(
      DocumentDetailNotifier.new,
    );

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  ICameraService get _cameraService => ref.read(cameraServiceProvider);
  IOCRService get _ocrService => ref.read(ocrServiceProvider);
  ITroubleshootingLogger get _troubleshootingLogger =>
      ref.read(troubleshootingLoggerProvider);

  Future<void> initializeCamera() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _cameraService.initialize();
      await _cameraService.initializeController();

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: null,
      );

      await _troubleshootingLogger.info(
        'Camera initialized successfully',
        tag: 'ScannerNotifier',
      );
    } catch (e) {
      await _troubleshootingLogger.error(
        'Failed to initialize camera',
        tag: 'ScannerNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> captureImage() async {
    try {
      state = state.copyWith(isCapturing: true, error: null);

      final imagePath = await _cameraService.captureImage();

      state = state.copyWith(
        isCapturing: false,
        lastCapturedImage: imagePath,
        error: null,
      );

      await _troubleshootingLogger.info(
        'Image captured: $imagePath',
        tag: 'ScannerNotifier',
      );
      return imagePath;
    } catch (e) {
      await _troubleshootingLogger.error(
        'Failed to capture image',
        tag: 'ScannerNotifier',
        error: e,
      );
      state = state.copyWith(isCapturing: false, error: e.toString());
      return null;
    }
  }

  Future<OCRResult?> extractText(String imagePath) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final ocrResult = await _ocrService.extractTextFromImage(imagePath);

      state = state.copyWith(
        isProcessing: false,
        lastOCRResult: ocrResult,
        error: null,
      );

      await _troubleshootingLogger.info(
        'Text extracted: ${ocrResult.text.length} characters',
        tag: 'ScannerNotifier',
      );
      return ocrResult;
    } catch (e) {
      await _troubleshootingLogger.error(
        'Failed to extract text',
        tag: 'ScannerNotifier',
        error: e,
      );
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  void clearState() {
    state = const ScannerState();
  }

  void setFlashMode(FlashMode mode) {
    _cameraService.setFlashMode(mode);
  }

  void setFocusMode(FocusMode mode) {
    _cameraService.setFocusMode(mode);
  }
}

final scannerNotifierProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);

@freezed
abstract class ScannerState with _$ScannerState {
  const factory ScannerState({
    @Default(false) bool isLoading,
    @Default(false) bool isInitialized,
    @Default(false) bool isCapturing,
    @Default(false) bool isProcessing,
    String? error,
    String? lastCapturedImage,
    OCRResult? lastOCRResult,
  }) = _ScannerState;
}
