# OCRix Developer Guide

Complete technical documentation for the OCRix privacy-first document scanner.

---

## Table of Contents
1. [Architecture](#architecture)
2. [Data Models](#data-models)
3. [Services API](#services-api)
4. [State Management](#state-management)
5. [Database Schema](#database-schema)
6. [Security](#security)
7. [Google Drive Integration](#google-drive-integration)
8. [Build & Deployment](#build--deployment)

---

## Architecture

### Layer Overview

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│   Screens, Widgets, Navigation          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         State Management                │
│   Providers, Notifiers, States          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         Business Logic                  │
│   Services, Models, Utils               │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         Data Layer                      │
│   Database, Storage, Network            │
└─────────────────────────────────────────┘
```

### Data Flows

**Document Scanning:**
```
Camera → Image Processing → OCR → Document Creation → Encryption → Database → Search Index
```

**Search:**
```
User Query → FTS5 Index → Results → Decryption → UI Display
```

**Sync:**
```
Local Changes → Sync Queue → Encryption → Cloud Upload → Status Update
```

---

## Data Models

### Document

```dart
class Document {
  final String id;              // UUID
  final String title;
  final String imagePath;
  final String extractedText;   // OCR text
  final DocumentType type;      // receipt, contract, invoice, etc.
  final DateTime scanDate;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String storageProvider;
  final bool isEncrypted;
  final double confidenceScore; // 0.0-1.0
  final String detectedLanguage;
  final String deviceInfo;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cloudId;
  final DateTime? lastSyncedAt;
}

enum DocumentType {
  receipt, contract, manual, invoice, businessCard,
  idDocument, passport, license, certificate, other
}
```

### UserSettings

```dart
class UserSettings {
  final String metadataStorageProvider;  // 'local' or 'googleDrive'
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
  final double ocrConfidenceThreshold;
  final bool backupEnabled;
  final DateTime? lastBackupAt;
}
```

### AuditLog

```dart
class AuditLog {
  final String id;
  final AuditAction action;     // create, read, update, delete, sync, etc.
  final String resourceType;
  final String resourceId;
  final String userId;
  final DateTime timestamp;
  final String? details;
  final bool isSuccess;
  final String? errorMessage;
}
```

---

## Services API

### DatabaseService

```dart
class DatabaseService {
  // Document CRUD
  Future<String> insertDocument(Document document);
  Future<Document?> getDocument(String id);
  Future<List<Document>> getAllDocuments({int? limit, int? offset, DocumentType? type, String? searchQuery});
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);

  // Search
  Future<List<Document>> searchDocuments(String query);

  // Settings
  Future<UserSettings> getUserSettings();
  Future<void> updateUserSettings(UserSettings settings);

  // Audit
  Future<List<AuditLog>> getAuditLogs({int? limit, AuditAction? action});
}
```

### OCRService

```dart
class OCRService {
  Future<void> initialize();
  Future<OCRResult> extractTextFromImage(String imagePath);
  Future<DocumentType> categorizeDocument(String text);
  Future<void> dispose();
}

class OCRResult {
  final String text;
  final double confidence;
  final String detectedLanguage;
  final List<TextBlock> blocks;
}
```

### CameraService

```dart
class CameraService {
  List<CameraDescription> get cameras;
  CameraController? get controller;
  bool get isInitialized;

  Future<void> initialize();
  Future<String> captureImage();
  Future<void> setFlashMode(FlashMode mode);
  Future<void> dispose();
}
```

### EncryptionService

```dart
class EncryptionService {
  Future<void> initialize();

  // Text
  Future<String> encryptText(String text);
  Future<String> decryptText(String encryptedText);

  // Binary
  Future<Uint8List> encryptBytes(Uint8List data);
  Future<Uint8List> decryptBytes(Uint8List encryptedData);

  // Files
  Future<String> encryptFile(String filePath);
  Future<String> decryptFile(String encryptedFilePath);

  // Auth
  Future<bool> authenticateWithBiometrics();
  Future<bool> isBiometricAvailable();
}
```

### StorageProviderService

```dart
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

---

## State Management

### Riverpod Providers

```dart
// Service providers
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
final encryptionServiceProvider = Provider<EncryptionService>((ref) => EncryptionService());

// Data providers
final documentListProvider = FutureProvider<List<Document>>((ref) async {
  return await ref.read(databaseServiceProvider).getAllDocuments();
});

final documentSearchProvider = FutureProvider.family<List<Document>, String>((ref, query) async {
  if (query.isEmpty) return await ref.read(databaseServiceProvider).getAllDocuments();
  return await ref.read(databaseServiceProvider).searchDocuments(query);
});

// State notifiers
final documentNotifierProvider = StateNotifierProvider<DocumentNotifier, AsyncValue<List<Document>>>(...);
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>(...);
final scannerNotifierProvider = StateNotifierProvider<ScannerNotifier, ScannerState>(...);
```

### Usage in Widgets

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListProvider);

    return documents.when(
      data: (docs) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

---

## Database Schema

```sql
-- Main documents table
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  image_path TEXT NOT NULL,
  extracted_text TEXT,
  type TEXT NOT NULL,
  scan_date INTEGER NOT NULL,
  tags TEXT,                    -- JSON array
  metadata TEXT,                -- JSON object
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

-- Full-text search index
CREATE VIRTUAL TABLE search_index USING fts5(
  doc_id, title, extracted_text, tags, notes,
  content='documents', content_rowid='rowid'
);

-- User settings
CREATE TABLE user_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Audit log
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  details TEXT,
  is_success INTEGER NOT NULL,
  error_message TEXT
);

-- Sync queue
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,         -- UPLOAD, DOWNLOAD, DELETE
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  data TEXT NOT NULL,           -- JSON payload
  created_at INTEGER NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending'
);
```

---

## Security

### Encryption

- **Algorithm**: AES-256
- **Key Derivation**: PBKDF2 with 100,000 iterations
- **Salt**: Cryptographically secure random (`IV.fromSecureRandom(32)`)
- **Storage**: Keys in `flutter_secure_storage`

### Implementation

```dart
// Encryption with IV prepended
Future<Uint8List> encryptBytes(Uint8List data) async {
  final uniqueIV = IV.fromSecureRandom(16);
  final encrypted = encrypter.encryptBytes(data, iv: uniqueIV);

  final result = Uint8List(16 + encrypted.bytes.length);
  result.setRange(0, 16, uniqueIV.bytes);
  result.setRange(16, result.length, encrypted.bytes);
  return result;
}

// Decryption extracts IV from data
Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
  final ivBytes = encryptedBytes.sublist(0, 16);
  final extractedIV = IV(ivBytes);
  final encryptedData = encryptedBytes.sublist(16);
  return encrypter.decryptBytes(Encrypted(encryptedData), iv: extractedIV);
}
```

### FTS5 Query Sanitization

```dart
String _sanitizeFTS5Query(String query) {
  const maxQueryLength = 200;
  String sanitized = query.length > maxQueryLength
      ? query.substring(0, maxQueryLength) : query;

  sanitized = sanitized
      .replaceAll('"', '""')
      .replaceAll('(', '').replaceAll(')', '')
      .replaceAll('*', '').replaceAll('-', ' ');

  sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b(AND|OR|NOT)\b', caseSensitive: false), (m) => ' ');

  return '"$sanitized"';
}
```

---

## Google Drive Integration

### Setup

1. **Enable API**: https://console.developers.google.com/apis/api/drive.googleapis.com/overview
2. **Add OAuth scopes** in consent screen:
   - `https://www.googleapis.com/auth/drive.file`
   - `https://www.googleapis.com/auth/drive.appdata`

### Storage Location

Backups stored in `appDataFolder` (hidden, app-specific):
- Not visible in Google Drive UI
- Only accessible by OCRix app
- Format: `ocrix_database_backup_YYYY-MM-DD.db.enc`

### SHA-1 Fingerprint

For Google Sign-In:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

Add to Google Cloud Console > APIs & Services > Credentials > OAuth client.

---

## Build & Deployment

### Development

```bash
flutter pub get
dart run build_runner build
flutter run
```

### Debug Build

```bash
flutter build apk --debug
flutter install
```

### Release Build

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -alias ocrix-release-key -keyalg RSA -keysize 2048 -validity 10000

# Build
flutter build apk --release
flutter build appbundle  # For Play Store
```

### Keystore Security

- **Never commit** `release-keystore.jks` to git
- Store passwords in password manager or CI/CD secrets
- Verify gitignore: `git check-ignore android/app/release-keystore.jks`

### Testing

```bash
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests
flutter analyze                 # Static analysis
```

### ADB Commands

```bash
# Install
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Logs
adb logcat | grep -i flutter

# Database access (debug only)
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db"

# Clear app data
adb shell pm clear com.ocrix.app
```

---

## Requirements Summary

### Functional
- Camera capture and gallery import
- On-device OCR (ML Kit)
- Encrypted local storage (SQLite + AES-256)
- Full-text search (FTS5)
- Google Drive backup
- Privacy audit logging
- Biometric authentication

### Non-Functional
- Works fully offline
- Responsive with 1000+ documents
- No analytics or tracking
- All data encrypted at rest and in transit

### Platforms
- Android 5.0+ (API 21)
- iOS 12.0+
