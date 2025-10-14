import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:camera/camera.dart';
import '../models/document.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/camera_service.dart';
import '../services/storage_provider_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final storageProviderServiceProvider = Provider<StorageProviderService>((ref) {
  return StorageProviderService();
});

final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllDocuments();
});

final documentProvider =
    FutureProvider.family<Document?, String>((ref, documentId) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getDocument(documentId);
});

final documentSearchProvider =
    FutureProvider.family<List<Document>, String>((ref, query) async {
  final databaseService = ref.read(databaseServiceProvider);
  if (query.isEmpty) {
    return await databaseService.getAllDocuments();
  }
  return await databaseService.searchDocuments(query);
});

final documentByTypeProvider =
    FutureProvider.family<List<Document>, DocumentType>((ref, type) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllDocuments(type: type);
});

class DocumentNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final DatabaseService _databaseService;
  final OCRService _ocrService;
  final Logger _logger = Logger();

  DocumentNotifier(
    this._databaseService,
    this._ocrService,
    CameraService cameraService,
    StorageProviderService storageService,
  ) : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      state = const AsyncValue.loading();
      final documents = await _databaseService.getAllDocuments();
      state = AsyncValue.data(documents);
    } catch (e, stackTrace) {
      _logger.e('Failed to load documents: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshDocuments() async {
    await _loadDocuments();
  }

  Future<String> scanDocument({
    required String imagePath,
    String? title,
    List<String> tags = const [],
    String? notes,
    String? location,
  }) async {
    try {
      state = const AsyncValue.loading();

      // Extract text using OCR
      final ocrResult = await _ocrService.extractTextFromImage(imagePath);

      // Categorize document
      final documentType = await _ocrService.categorizeDocument(ocrResult.text);

      // Create document
      final document = Document.create(
        title: title ?? _generateTitle(ocrResult.text, documentType),
        imagePath: imagePath,
        extractedText: ocrResult.text,
        type: documentType,
        confidenceScore: ocrResult.confidence,
        detectedLanguage: ocrResult.detectedLanguage,
        deviceInfo: 'Flutter App',
        notes: notes,
        location: location,
        tags: tags,
      );

      // Save to database
      final documentId = await _databaseService.insertDocument(document);

      // Reload documents
      await _loadDocuments();

      _logger.i('Document scanned and saved: $documentId');
      return documentId;
    } catch (e, stackTrace) {
      _logger.e('Failed to scan document: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      final updatedDocument = document.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateDocument(updatedDocument);
      await _loadDocuments();

      _logger.i('Document updated: ${document.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to update document: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _databaseService.deleteDocument(documentId);
      await _loadDocuments();

      _logger.i('Document deleted: $documentId');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete document: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    try {
      if (query.isEmpty) {
        return await _databaseService.getAllDocuments();
      }
      return await _databaseService.searchDocuments(query);
    } catch (e) {
      _logger.e('Failed to search documents: $e');
      return [];
    }
  }

  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    try {
      return await _databaseService.getAllDocuments(type: type);
    } catch (e) {
      _logger.e('Failed to get documents by type: $e');
      return [];
    }
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

final documentNotifierProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<List<Document>>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  final ocrService = ref.read(ocrServiceProvider);
  final cameraService = ref.read(cameraServiceProvider);
  final storageService = ref.read(storageProviderServiceProvider);

  return DocumentNotifier(
      databaseService, ocrService, cameraService, storageService);
});

class DocumentDetailNotifier extends StateNotifier<AsyncValue<Document?>> {
  final DatabaseService _databaseService;
  final Logger _logger = Logger();

  DocumentDetailNotifier(this._databaseService)
      : super(const AsyncValue.loading());

  Future<void> loadDocument(String documentId) async {
    try {
      state = const AsyncValue.loading();
      final document = await _databaseService.getDocument(documentId);
      state = AsyncValue.data(document);
    } catch (e, stackTrace) {
      _logger.e('Failed to load document: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      final updatedDocument = document.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateDocument(updatedDocument);
      state = AsyncValue.data(updatedDocument);

      _logger.i('Document updated: ${document.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to update document: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _databaseService.deleteDocument(documentId);
      state = const AsyncValue.data(null);

      _logger.i('Document deleted: $documentId');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete document: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final documentDetailNotifierProvider = StateNotifierProvider.family<
    DocumentDetailNotifier, AsyncValue<Document?>, String>((ref, documentId) {
  final databaseService = ref.read(databaseServiceProvider);
  return DocumentDetailNotifier(databaseService);
});

class ScannerNotifier extends StateNotifier<ScannerState> {
  final CameraService _cameraService;
  final OCRService _ocrService;
  final Logger _logger = Logger();

  ScannerNotifier(this._cameraService, this._ocrService)
      : super(const ScannerState.initial());

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

      _logger.i('Camera initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize camera: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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

      _logger.i('Image captured: $imagePath');
      return imagePath;
    } catch (e) {
      _logger.e('Failed to capture image: $e');
      state = state.copyWith(
        isCapturing: false,
        error: e.toString(),
      );
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

      _logger.i('Text extracted: ${ocrResult.text.length} characters');
      return ocrResult;
    } catch (e) {
      _logger.e('Failed to extract text: $e');
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void clearState() {
    state = const ScannerState.initial();
  }

  void setFlashMode(FlashMode mode) {
    _cameraService.setFlashMode(mode);
  }

  void setFocusMode(FocusMode mode) {
    _cameraService.setFocusMode(mode);
  }
}

final scannerNotifierProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final cameraService = ref.read(cameraServiceProvider);
  final ocrService = ref.read(ocrServiceProvider);
  return ScannerNotifier(cameraService, ocrService);
});

class ScannerState {
  final bool isLoading;
  final bool isInitialized;
  final bool isCapturing;
  final bool isProcessing;
  final String? error;
  final String? lastCapturedImage;
  final OCRResult? lastOCRResult;

  const ScannerState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isCapturing = false,
    this.isProcessing = false,
    this.error,
    this.lastCapturedImage,
    this.lastOCRResult,
  });

  const ScannerState.initial() : this();

  ScannerState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isCapturing,
    bool? isProcessing,
    String? error,
    String? lastCapturedImage,
    OCRResult? lastOCRResult,
  }) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isCapturing: isCapturing ?? this.isCapturing,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
      lastOCRResult: lastOCRResult ?? this.lastOCRResult,
    );
  }
}
