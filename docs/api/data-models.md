# Data Models API Documentation

## Overview

This document provides comprehensive documentation for all data models used in the Privacy Document Scanner app. These models define the structure and behavior of data throughout the application.

## Core Models

### Document Model

The primary model representing a scanned document with all its metadata and content.

```dart
@JsonSerializable()
class Document extends Equatable {
  final String id;                    // Unique identifier (UUID)
  final String title;                 // User-defined or auto-generated title
  final String imagePath;             // Local or remote path to image
  final String extractedText;         // OCR extracted text content
  final DocumentType type;            // Document type classification
  final DateTime scanDate;            // When document was scanned
  final List<String> tags;            // User-defined tags
  final Map<String, dynamic> metadata; // Additional metadata
  final String storageProvider;       // Storage provider identifier
  final bool isEncrypted;             // Encryption status
  final double confidenceScore;       // OCR confidence (0.0-1.0)
  final String detectedLanguage;      // Detected language code
  final String deviceInfo;            // Device information
  final String? notes;                // User notes
  final String? location;             // GPS or user-defined location
  final DateTime createdAt;           // Creation timestamp
  final DateTime updatedAt;           // Last update timestamp
  final bool isSynced;                // Sync status
  final String? cloudId;              // Remote provider ID
  final DateTime? lastSyncedAt;       // Last sync timestamp

  const Document({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.extractedText,
    required this.type,
    required this.scanDate,
    required this.tags,
    required this.metadata,
    required this.storageProvider,
    required this.isEncrypted,
    required this.confidenceScore,
    required this.detectedLanguage,
    required this.deviceInfo,
    this.notes,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.cloudId,
    this.lastSyncedAt,
  });

  // Factory constructor for creating new documents
  factory Document.create({
    required String title,
    required String imagePath,
    required String extractedText,
    required DocumentType type,
    required String storageProvider,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? notes,
    String? location,
    double confidenceScore = 0.0,
    String detectedLanguage = 'en',
    String? deviceInfo,
  }) {
    final now = DateTime.now();
    return Document(
      id: const Uuid().v4(),
      title: title,
      imagePath: imagePath,
      extractedText: extractedText,
      type: type,
      scanDate: now,
      tags: tags ?? [],
      metadata: metadata ?? {},
      storageProvider: storageProvider,
      isEncrypted: true,
      confidenceScore: confidenceScore,
      detectedLanguage: detectedLanguage,
      deviceInfo: deviceInfo ?? 'Unknown Device',
      notes: notes,
      location: location,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  // JSON serialization
  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  // Copy with method for immutable updates
  Document copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? extractedText,
    DocumentType? type,
    DateTime? scanDate,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? storageProvider,
    bool? isEncrypted,
    double? confidenceScore,
    String? detectedLanguage,
    String? deviceInfo,
    String? notes,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? cloudId,
    DateTime? lastSyncedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      type: type ?? this.type,
      scanDate: scanDate ?? this.scanDate,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      storageProvider: storageProvider ?? this.storageProvider,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cloudId: cloudId ?? this.cloudId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, title, imagePath, extractedText, type, scanDate, tags, metadata,
    storageProvider, isEncrypted, confidenceScore, detectedLanguage,
    deviceInfo, notes, location, createdAt, updatedAt, isSynced, cloudId, lastSyncedAt
  ];
}
```

### DocumentType Enum

Enumeration of supported document types with display names and icons.

```dart
enum DocumentType {
  receipt,
  contract,
  manual,
  invoice,
  businessCard,
  idDocument,
  passport,
  license,
  certificate,
  other;

  String get displayName {
    switch (this) {
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.contract:
        return 'Contract';
      case DocumentType.manual:
        return 'Manual';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.businessCard:
        return 'Business Card';
      case DocumentType.idDocument:
        return 'ID Document';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.license:
        return 'License';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.manual:
        return Icons.menu_book;
      case DocumentType.invoice:
        return Icons.request_quote;
      case DocumentType.businessCard:
        return Icons.business;
      case DocumentType.idDocument:
        return Icons.badge;
      case DocumentType.passport:
        return Icons.airplane_ticket;
      case DocumentType.license:
        return Icons.card_membership;
      case DocumentType.certificate:
        return Icons.workspace_premium;
      case DocumentType.other:
        return Icons.description;
    }
  }
}
```

### UserSettings Model

Model for storing user preferences and application settings.

```dart
@JsonSerializable()
class UserSettings extends Equatable {
  final String metadataStorageProvider;    // Storage provider for metadata
  final String fileStorageProvider;        // Storage provider for files
  final bool autoSync;                     // Auto-sync enabled
  final int syncIntervalMinutes;           // Sync interval in minutes
  final bool biometricAuth;                // Biometric authentication enabled
  final bool encryptionEnabled;            // Encryption enabled
  final String defaultDocumentType;        // Default document type
  final List<String> defaultTags;          // Default tags for new documents
  final bool privacyAuditEnabled;          // Privacy audit logging enabled
  final String language;                   // App language
  final String theme;                      // App theme
  final bool notificationsEnabled;         // Notifications enabled
  final bool autoCategorization;           // Auto-categorization enabled
  final double ocrConfidenceThreshold;     // OCR confidence threshold
  final bool backupEnabled;                // Backup enabled
  final DateTime? lastBackupAt;            // Last backup timestamp
  final Map<String, dynamic> customSettings; // Custom settings

  const UserSettings({
    required this.metadataStorageProvider,
    required this.fileStorageProvider,
    required this.autoSync,
    required this.syncIntervalMinutes,
    required this.biometricAuth,
    required this.encryptionEnabled,
    required this.defaultDocumentType,
    required this.defaultTags,
    required this.privacyAuditEnabled,
    required this.language,
    required this.theme,
    required this.notificationsEnabled,
    required this.autoCategorization,
    required this.ocrConfidenceThreshold,
    required this.backupEnabled,
    this.lastBackupAt,
    required this.customSettings,
  });

  // Factory constructor for default settings
  factory UserSettings.defaultSettings() {
    return const UserSettings(
      metadataStorageProvider: 'local',
      fileStorageProvider: 'local',
      autoSync: false,
      syncIntervalMinutes: 60,
      biometricAuth: false,
      encryptionEnabled: true,
      defaultDocumentType: 'other',
      defaultTags: [],
      privacyAuditEnabled: true,
      language: 'en',
      theme: 'system',
      notificationsEnabled: true,
      autoCategorization: true,
      ocrConfidenceThreshold: 0.7,
      backupEnabled: false,
      customSettings: {},
    );
  }

  // JSON serialization
  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  // Copy with method
  UserSettings copyWith({
    String? metadataStorageProvider,
    String? fileStorageProvider,
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? biometricAuth,
    bool? encryptionEnabled,
    String? defaultDocumentType,
    List<String>? defaultTags,
    bool? privacyAuditEnabled,
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? autoCategorization,
    double? ocrConfidenceThreshold,
    bool? backupEnabled,
    DateTime? lastBackupAt,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      metadataStorageProvider: metadataStorageProvider ?? this.metadataStorageProvider,
      fileStorageProvider: fileStorageProvider ?? this.fileStorageProvider,
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      defaultDocumentType: defaultDocumentType ?? this.defaultDocumentType,
      defaultTags: defaultTags ?? this.defaultTags,
      privacyAuditEnabled: privacyAuditEnabled ?? this.privacyAuditEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoCategorization: autoCategorization ?? this.autoCategorization,
      ocrConfidenceThreshold: ocrConfidenceThreshold ?? this.ocrConfidenceThreshold,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
    metadataStorageProvider, fileStorageProvider, autoSync, syncIntervalMinutes,
    biometricAuth, encryptionEnabled, defaultDocumentType, defaultTags,
    privacyAuditEnabled, language, theme, notificationsEnabled, autoCategorization,
    ocrConfidenceThreshold, backupEnabled, lastBackupAt, customSettings
  ];
}
```

### AuditLog Model

Model for tracking user actions and system operations for privacy auditing.

```dart
@JsonSerializable()
class AuditLog extends Equatable {
  final String id;                    // Unique identifier
  final AuditAction action;           // Action performed
  final String resourceType;          // Type of resource affected
  final String resourceId;            // ID of resource affected
  final String userId;                // User who performed action
  final DateTime timestamp;           // When action occurred
  final String? details;              // Additional details
  final String? location;             // GPS coordinates if available
  final String? deviceInfo;           // Device information
  final bool isSuccess;               // Whether action was successful
  final String? errorMessage;         // Error message if failed

  const AuditLog({
    required this.id,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.userId,
    required this.timestamp,
    this.details,
    this.location,
    this.deviceInfo,
    required this.isSuccess,
    this.errorMessage,
  });

  // Factory constructor for creating audit logs
  factory AuditLog.create({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    required String userId,
    String? details,
    String? location,
    String? deviceInfo,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    return AuditLog(
      id: const Uuid().v4(),
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
      location: location,
      deviceInfo: deviceInfo,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  // JSON serialization
  factory AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);
  Map<String, dynamic> toJson() => _$AuditLogToJson(this);

  @override
  List<Object?> get props => [
    id, action, resourceType, resourceId, userId, timestamp,
    details, location, deviceInfo, isSuccess, errorMessage
  ];
}

enum AuditAction {
  create, read, update, delete, sync, export, import,
  login, logout, encrypt, decrypt, backup, restore;

  String get displayName {
    switch (this) {
      case AuditAction.create:
        return 'Create';
      case AuditAction.read:
        return 'Read';
      case AuditAction.update:
        return 'Update';
      case AuditAction.delete:
        return 'Delete';
      case AuditAction.sync:
        return 'Sync';
      case AuditAction.export:
        return 'Export';
      case AuditAction.import:
        return 'Import';
      case AuditAction.login:
        return 'Login';
      case AuditAction.logout:
        return 'Logout';
      case AuditAction.encrypt:
        return 'Encrypt';
      case AuditAction.decrypt:
        return 'Decrypt';
      case AuditAction.backup:
        return 'Backup';
      case AuditAction.restore:
        return 'Restore';
    }
  }
}
```

### StorageProvider Model

Model for managing different storage providers and their configurations.

```dart
@JsonSerializable()
class StorageProvider extends Equatable {
  final String id;                    // Provider identifier
  final String name;                  // Display name
  final StorageProviderType type;     // Provider type
  final bool isConnected;             // Connection status
  final Map<String, dynamic> config;  // Provider configuration
  final DateTime? lastConnectedAt;    // Last connection timestamp
  final String? errorMessage;         // Last error message

  const StorageProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.isConnected,
    required this.config,
    this.lastConnectedAt,
    this.errorMessage,
  });

  // JSON serialization
  factory StorageProvider.fromJson(Map<String, dynamic> json) => _$StorageProviderFromJson(json);
  Map<String, dynamic> toJson() => _$StorageProviderToJson(this);

  @override
  List<Object?> get props => [id, name, type, isConnected, config, lastConnectedAt, errorMessage];
}

enum StorageProviderType {
  local,
  googleDrive,
  oneDrive,
  dropbox,
  box;

  String get displayName {
    switch (this) {
      case StorageProviderType.local:
        return 'Local Storage';
      case StorageProviderType.googleDrive:
        return 'Google Drive';
      case StorageProviderType.oneDrive:
        return 'OneDrive';
      case StorageProviderType.dropbox:
        return 'Dropbox';
      case StorageProviderType.box:
        return 'Box';
    }
  }

  IconData get icon {
    switch (this) {
      case StorageProviderType.local:
        return Icons.storage;
      case StorageProviderType.googleDrive:
        return Icons.cloud;
      case StorageProviderType.oneDrive:
        return Icons.cloud;
      case StorageProviderType.dropbox:
        return Icons.cloud;
      case StorageProviderType.box:
        return Icons.cloud;
    }
  }

  bool get isCloudProvider {
    return this != StorageProviderType.local;
  }
}
```

## Service Models

### OCRResult Model

Model for OCR processing results.

```dart
class OCRResult {
  final String text;                  // Extracted text
  final double confidence;            // Confidence score (0.0-1.0)
  final String detectedLanguage;      // Detected language code
  final List<TextBlock> blocks;       // Text blocks with positioning

  const OCRResult({
    required this.text,
    required this.confidence,
    required this.detectedLanguage,
    required this.blocks,
  });
}

class TextBlock {
  final String text;                  // Block text content
  final String confidence;            // Block confidence
  final Rect boundingBox;             // Bounding box coordinates

  const TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}
```

### SyncStatus Model

Model for tracking synchronization status.

```dart
@JsonSerializable()
class SyncStatus extends Equatable {
  final String documentId;            // Document ID
  final String providerType;          // Storage provider type
  final SyncState state;              // Current sync state
  final DateTime? lastSyncAt;         // Last sync timestamp
  final String? errorMessage;         // Error message if failed
  final int retryCount;               // Number of retry attempts

  const SyncStatus({
    required this.documentId,
    required this.providerType,
    required this.state,
    this.lastSyncAt,
    this.errorMessage,
    required this.retryCount,
  });

  // JSON serialization
  factory SyncStatus.fromJson(Map<String, dynamic> json) => _$SyncStatusFromJson(json);
  Map<String, dynamic> toJson() => _$SyncStatusToJson(this);

  @override
  List<Object?> get props => [documentId, providerType, state, lastSyncAt, errorMessage, retryCount];
}

enum SyncState {
  pending, processing, completed, failed, cancelled;

  String get displayName {
    switch (this) {
      case SyncState.pending:
        return 'Pending';
      case SyncState.processing:
        return 'Processing';
      case SyncState.completed:
        return 'Completed';
      case SyncState.failed:
        return 'Failed';
      case SyncState.cancelled:
        return 'Cancelled';
    }
  }
}
```

## Validation and Constraints

### Document Validation

```dart
class DocumentValidator {
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Title is required';
    }
    if (title.length > 255) {
      return 'Title must be less than 255 characters';
    }
    return null;
  }

  static String? validateImagePath(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return 'Image path is required';
    }
    return null;
  }

  static String? validateConfidenceScore(double? score) {
    if (score == null) {
      return 'Confidence score is required';
    }
    if (score < 0.0 || score > 1.0) {
      return 'Confidence score must be between 0.0 and 1.0';
    }
    return null;
  }
}
```

### Settings Validation

```dart
class SettingsValidator {
  static String? validateSyncInterval(int? interval) {
    if (interval == null) {
      return 'Sync interval is required';
    }
    if (interval < 1 || interval > 1440) {
      return 'Sync interval must be between 1 and 1440 minutes';
    }
    return null;
  }

  static String? validateOCRThreshold(double? threshold) {
    if (threshold == null) {
      return 'OCR threshold is required';
    }
    if (threshold < 0.0 || threshold > 1.0) {
      return 'OCR threshold must be between 0.0 and 1.0';
    }
    return null;
  }
}
```

## Database Schema

### Documents Table

```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  image_path TEXT NOT NULL,
  extracted_text TEXT,
  type TEXT NOT NULL,
  scan_date INTEGER NOT NULL,
  tags TEXT,
  metadata TEXT,
  storage_provider TEXT NOT NULL,
  is_encrypted INTEGER NOT NULL DEFAULT 1,
  confidence_score REAL NOT NULL,
  detected_language TEXT NOT NULL,
  device_info TEXT NOT NULL,
  notes TEXT,
  location TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  cloud_id TEXT,
  last_synced_at INTEGER
);
```

### Search Index Table (FTS5)

```sql
CREATE VIRTUAL TABLE search_index USING fts5(
  doc_id,
  title,
  extracted_text,
  tags,
  notes,
  content='documents',
  content_rowid='rowid'
);
```

### User Settings Table

```sql
CREATE TABLE user_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Audit Log Table

```sql
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  details TEXT,
  location TEXT,
  device_info TEXT,
  is_success INTEGER NOT NULL,
  error_message TEXT
);
```

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Complete
