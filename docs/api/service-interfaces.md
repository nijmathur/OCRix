# Service Interfaces API Documentation

## Overview

This document describes the public interfaces for all services in the Privacy Document Scanner app. These interfaces define the contracts that services must implement and the methods available to other parts of the application.

## Core Services

### DatabaseService

Manages all database operations including CRUD operations, search, and audit logging.

```dart
class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  // Database access
  Future<Database> get database;

  // Document operations
  Future<String> insertDocument(Document document);
  Future<Document?> getDocument(String id);
  Future<List<Document>> getAllDocuments({
    int? limit,
    int? offset,
    DocumentType? type,
    String? searchQuery,
  });
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);

  // Search operations
  Future<List<Document>> searchDocuments(String query);

  // Settings operations
  Future<UserSettings> getUserSettings();
  Future<void> updateUserSettings(UserSettings settings);

  // Audit operations
  Future<List<AuditLog>> getAuditLogs({
    int? limit,
    int? offset,
    AuditAction? action,
    String? resourceType,
  });

  // Utility methods
  Future<void> close();
}
```

### OCRService

Handles optical character recognition and document processing.

```dart
class OCRService {
  // Singleton instance
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;

  // Initialization
  Future<void> initialize();

  // Text extraction
  Future<OCRResult> extractTextFromImage(String imagePath);
  Future<OCRResult> extractTextFromBytes(Uint8List imageBytes);

  // Document categorization
  Future<DocumentType> categorizeDocument(String text);

  // Image processing
  Future<Uint8List> preprocessImage(String imagePath);

  // Cleanup
  Future<void> dispose();
}

// OCR Result model
class OCRResult {
  final String text;
  final double confidence;
  final String detectedLanguage;
  final List<TextBlock> blocks;
}

class TextBlock {
  final String text;
  final String confidence;
  final Rect boundingBox;
}
```

### CameraService

Manages camera operations and image capture.

```dart
class CameraService {
  // Singleton instance
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;

  // Properties
  List<CameraDescription> get cameras;
  CameraController? get controller;
  bool get isInitialized;

  // Initialization
  Future<void> initialize();
  Future<void> initializeController({
    int cameraIndex = 0,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  });

  // Image capture
  Future<String> captureImage();
  Future<Uint8List> captureImageBytes();
  Future<String> processAndSaveImage(Uint8List imageBytes, {String? fileName});

  // Camera controls
  Future<void> startPreview();
  Future<void> stopPreview();
  Future<void> setFlashMode(FlashMode mode);
  Future<void> setFocusMode(FocusMode mode);
  Future<void> setExposureMode(ExposureMode mode);
  Future<void> setFocusPoint(Offset point);
  Future<void> setExposurePoint(Offset point);

  // Cleanup
  Future<void> dispose();
}
```

### EncryptionService

Handles encryption, decryption, and security operations.

```dart
class EncryptionService {
  // Singleton instance
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;

  // Properties
  bool get isInitialized;

  // Initialization
  Future<void> initialize();

  // Text encryption/decryption
  Future<String> encryptText(String text);
  Future<String> decryptText(String encryptedText);

  // Binary encryption/decryption
  Future<Uint8List> encryptBytes(Uint8List data);
  Future<Uint8List> decryptBytes(Uint8List encryptedData);

  // File encryption/decryption
  Future<String> encryptFile(String filePath);
  Future<String> decryptFile(String encryptedFilePath);

  // Authentication
  Future<bool> authenticateWithBiometrics();
  Future<bool> isBiometricAvailable();

  // Key management
  Future<void> changeEncryptionKey();
  Future<void> clearEncryptionKey();

  // Utility methods
  String generateHash(String data);
  String generateFileHash(String filePath);
  Future<bool> verifyFileIntegrity(String filePath, String expectedHash);
  Future<Map<String, dynamic>> getEncryptionInfo();
}
```

### StorageProviderService

Manages storage operations across different providers.

```dart
class StorageProviderService {
  // Singleton instance
  static final StorageProviderService _instance = StorageProviderService._internal();
  factory StorageProviderService() => _instance;

  // Initialization
  Future<void> initialize();

  // Provider management
  Future<StorageProviderInterface> getProvider(StorageProviderType type);
  Future<bool> isProviderConnected(StorageProviderType providerType);
  Future<void> disconnectProvider(StorageProviderType providerType);

  // Document operations
  Future<String> uploadDocument(Document document, StorageProviderType providerType);
  Future<String> downloadDocument(String documentId, String remotePath, String localPath, bool isEncrypted);
  Future<void> deleteDocument(String documentId, String remotePath, StorageProviderType providerType);
  Future<List<String>> listDocuments(StorageProviderType providerType, {String? prefix});

  // Cleanup
  Future<void> dispose();
}

// Storage Provider Interface
abstract class StorageProviderInterface {
  Future<bool> initialize();
  Future<String> uploadFile(String localPath, String remotePath);
  Future<String> downloadFile(String remotePath, String localPath);
  Future<void> deleteFile(String remotePath);
  Future<List<String>> listFiles(String? prefix);
  Future<bool> isConnected();
  Future<void> disconnect();
}
```

## State Management (Riverpod)

### Providers

```dart
// Service providers
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
final storageProviderServiceProvider = Provider<StorageProviderService>((ref) => StorageProviderService());
final encryptionServiceProvider = Provider<EncryptionService>((ref) => EncryptionService());

// Data providers
final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllDocuments();
});

final documentProvider = FutureProvider.family<Document?, String>((ref, documentId) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getDocument(documentId);
});

final documentSearchProvider = FutureProvider.family<List<Document>, String>((ref, query) async {
  final databaseService = ref.read(databaseServiceProvider);
  if (query.isEmpty) {
    return await databaseService.getAllDocuments();
  }
  return await databaseService.searchDocuments(query);
});
```

### Notifiers

```dart
// Document management
final documentNotifierProvider = StateNotifierProvider<DocumentNotifier, AsyncValue<List<Document>>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  final ocrService = ref.read(ocrServiceProvider);
  final cameraService = ref.read(cameraServiceProvider);
  final storageService = ref.read(storageProviderServiceProvider);
  return DocumentNotifier(databaseService, ocrService, cameraService, storageService);
});

// Settings management
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  final encryptionService = ref.read(encryptionServiceProvider);
  return SettingsNotifier(databaseService, encryptionService);
});

// Scanner management
final scannerNotifierProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final cameraService = ref.read(cameraServiceProvider);
  final ocrService = ref.read(ocrServiceProvider);
  return ScannerNotifier(cameraService, ocrService);
});

// Encryption management
final encryptionNotifierProvider = StateNotifierProvider<EncryptionNotifier, EncryptionState>((ref) {
  final encryptionService = ref.read(encryptionServiceProvider);
  return EncryptionNotifier(encryptionService);
});
```

## Data Models

### Document Model

```dart
@JsonSerializable()
class Document extends Equatable {
  final String id;
  final String title;
  final String imagePath;
  final String extractedText;
  final DocumentType type;
  final DateTime scanDate;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String storageProvider;
  final bool isEncrypted;
  final double confidenceScore;
  final String detectedLanguage;
  final String deviceInfo;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cloudId;
  final DateTime? lastSyncedAt;

  // Factory constructors
  factory Document.create({...});
  factory Document.fromJson(Map<String, dynamic> json);

  // Methods
  Map<String, dynamic> toJson();
  Document copyWith({...});
}
```

### UserSettings Model

```dart
@JsonSerializable()
class UserSettings extends Equatable {
  final String metadataStorageProvider;
  final String fileStorageProvider;
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool biometricAuth;
  final bool encryptionEnabled;
  final String defaultDocumentType;
  final List<String> defaultTags;
  final bool privacyAuditEnabled;
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool autoCategorization;
  final double ocrConfidenceThreshold;
  final bool backupEnabled;
  final DateTime? lastBackupAt;
  final Map<String, dynamic> customSettings;

  // Factory constructors
  factory UserSettings.defaultSettings();
  factory UserSettings.fromJson(Map<String, dynamic> json);

  // Methods
  Map<String, dynamic> toJson();
  UserSettings copyWith({...});
}
```

### AuditLog Model

```dart
@JsonSerializable()
class AuditLog extends Equatable {
  final String id;
  final AuditAction action;
  final String resourceType;
  final String resourceId;
  final String userId;
  final DateTime timestamp;
  final String? details;
  final String? location;
  final String? deviceInfo;
  final bool isSuccess;
  final String? errorMessage;

  // Factory constructors
  factory AuditLog.create({...});
  factory AuditLog.fromJson(Map<String, dynamic> json);

  // Methods
  Map<String, dynamic> toJson();
}

enum AuditAction {
  create, read, update, delete, sync, export, import,
  login, logout, encrypt, decrypt, backup, restore
}
```

## Error Handling

### Error Types

```dart
// Custom exception classes
class DatabaseException implements Exception {
  final String message;
  final String? code;
  DatabaseException(this.message, [this.code]);
}

class OCRException implements Exception {
  final String message;
  final String? code;
  OCRException(this.message, [this.code]);
}

class CameraException implements Exception {
  final String message;
  final String? code;
  CameraException(this.message, [this.code]);
}

class EncryptionException implements Exception {
  final String message;
  final String? code;
  EncryptionException(this.message, [this.code]);
}

class StorageException implements Exception {
  final String message;
  final String? code;
  StorageException(this.message, [this.code]);
}
```

### Error Handling Patterns

```dart
// Service method error handling pattern
Future<Result> serviceMethod() async {
  try {
    // Service logic
    return Result.success(data);
  } catch (e) {
    _logger.e('Service method failed: $e');
    return Result.error(e.toString());
  }
}

// Result wrapper class
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data) : error = null, isSuccess = true;
  Result.error(this.error) : data = null, isSuccess = false;
}
```

## Configuration

### App Configuration

```dart
class AppConfig {
  static const String appName = 'Privacy Document Scanner';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'privacy_documents.db';
  static const int databaseVersion = 1;
  static const String encryptionKeyStorageKey = 'encryption_key';
  static const int encryptionKeyLength = 32;
  static const double defaultOCRConfidenceThreshold = 0.7;
  static const int maxImageWidth = 2000;
  static const int maxImageHeight = 2000;
  static const int imageQuality = 95;
}
```

### Service Configuration

```dart
// Database configuration
class DatabaseConfig {
  static const String documentsTable = 'documents';
  static const String searchIndexTable = 'search_index';
  static const String userSettingsTable = 'user_settings';
  static const String auditLogTable = 'audit_log';
  static const String syncQueueTable = 'sync_queue';
}

// OCR configuration
class OCRConfig {
  static const double minConfidenceThreshold = 0.5;
  static const int maxTextLength = 10000;
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de'];
}

// Camera configuration
class CameraConfig {
  static const ResolutionPreset defaultResolution = ResolutionPreset.high;
  static const bool enableAudio = false;
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
}
```

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Implementation Complete
