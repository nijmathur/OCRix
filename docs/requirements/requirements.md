# Requirements Document: OCRix - Privacy-First Document Scanner & Search App (Flutter/Dart)

## 1. Project Overview

Design and implement a cross-platform document scanner and organizer app in Flutter/Dart. The app must extract text from images via on-device OCR, store documents and metadata with flexible provider selection, and enable ultra-fast local or remote search. Users will have granular control over where metadata and files are stored (local/offline or cloud providers like Google Drive, OneDrive). Privacy and security are foundational; users can operate completely offline or enable selective sync.

## 2. Functional Requirements

### 2.1. Document Capture and OCR

-   Ability to capture images via camera or import from gallery/files.
-   Perform on-device OCR (using ML Kit on Android, Vision on iOS) to extract text from documents.
-   Preview scanned docs and allow user edits to the extracted text before saving.

### 2.2. Metadata Extraction and Editing

-   Automatically record scan date, device, confidence score, detected language.
-   Allow users to categorize docs (type: e.g., receipt, contract, manual, invoice) and add custom tags.
-   Store additional editable metadata (notes, location, etc.).

### 2.3. Storage Provider Selection (Per-Type)

-   User selects preferred storage for metadata (Local SQLite, Google Drive, OneDrive, future extensibility).
-   User selects preferred storage for files (images/PDFs): same options.
-   Mix-and-match: E.g., metadata local, files on Google Drive, etc.
-   User can change providers at any time; support migration/export/import of data between providers.

### 2.4. Synchronization Logic

-   Offline mode: All core functionality (scan, browse, search) works without network or cloud.
-   If sync enabled, only selected data and documents are synced.
-   Background sync manager tracks unsynced items and uploads/downloads as permitted.
-   User can choose auto/manual sync intervals.
-   Provide feedback/status in UI for sync: last synced, pending, success/error.

### 2.5. Search and Browse

-   Powerful full-text search (local FTS SQLite and/or cloud provider cache when offline).
-   Search and filter by metadata (date, type, tags), keywords in extracted text, or combinations.
-   Fast response time: Instant/near-instant for local, reasonable for remote.
-   Browse scanned documents by folder/category/type.

### 2.6. Security and Privacy

-   Encryption at rest for all local data and files (AES-256).
-   Encryption in transit for all network/cloud sync.
-   OAuth2 for connecting cloud providers; do not store tokens unencrypted.
-   Privacy audit log: Users can see when/where each file/metadata item was stored, synced, deleted, and exported.
-   Permission model: Data never leaves device without explicit user approval.
-   Ability for users to permanently delete local or remote files/metadata; complete "right to erasure".

### 2.7. User Controls and Settings

-   Provider selection screens for metadata and file storage – flexible, granular controls.
-   Sync controls (auto/manual/per-item/per-type/global).
-   Data migration wizard for moving between providers.
-   Export/import function for bulk data movement or backups.
-   Notification and status dashboard for sync/errors/security actions.

### 2.8. Monetization and Extensibility

-   Core scanning, OCR, and basic organization features are free.
-   Premium features (offered by subscription/in-app purchase):
    -   Multiple cloud provider integration.
    -   AI-driven metadata extraction/categorization.
    -   Bulk export/import.
    -   Privacy/security audits.
    -   Advanced analytics and organization tools.
-   Easy API extension points for future 3rd-party provider integration (Dropbox, Box, etc.).

## 3. Non-Functional Requirements

### 3.1. Performance

-   Scans and searches must be responsive even with 1,000+ docs.
-   Sync operations must not block UI; always async with error states.
-   Memory and storage usage optimized for older devices as well as new.

### 3.2. Reliability

-   Local database must not corrupt even in power loss; use transactions.
-   Sync must ensure consistency across providers, prevent duplication.
-   Robust error handling and user feedback.

### 3.3. Privacy and Security

-   Source code must be auditable; no analytics or data tracking baked in.
-   All sensitive user data is encrypted at rest and in transit.
-   Password/biometrics can optionally protect app access.

### 3.4. Extensibility

-   All provider logic must be modular for future cloud or local targets.
-   Data schema and export/import logic documented and versioned.

## 4. Technical Requirements

### 4.1. Platform

-   Flutter/Dart for both Android and iOS.

### 4.2. Database

-   Local: Encrypted SQLite DB for metadata; local encrypted file store for images.
-   Cloud: Modular connectors for Google Drive, OneDrive with ability to store metadata and/or files.

### 4.3. OCR Library

-   Use ML Kit (Android) and Apple Vision (iOS) for text extraction.

### 4.4. Sync Engine

-   Background process to monitor changes, queue sync tasks, and manage conflicts or reverts.

### 4.5. Security Logic

-   Encryption libraries for DB and files must be state-of-the-art.
-   OAuth2 or secure API login for provider integrations.
-   Audit log stored (encrypted) locally.

## 5. Sample Database Schema

### Core Tables

#### documents table

```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,                    -- UUID
  title TEXT NOT NULL,                    -- User-defined or auto-generated
  image_path TEXT NOT NULL,               -- Local or remote path
  extracted_text TEXT,                    -- OCR extracted text
  type TEXT NOT NULL,                     -- Document type enum
  scan_date INTEGER NOT NULL,             -- Timestamp
  tags TEXT,                              -- JSON array of tags
  metadata TEXT,                          -- JSON object for additional data
  storage_provider TEXT NOT NULL,         -- Provider identifier
  is_encrypted INTEGER NOT NULL DEFAULT 1, -- Boolean
  confidence_score REAL NOT NULL,         -- OCR confidence (0.0-1.0)
  detected_language TEXT NOT NULL,        -- Language code
  device_info TEXT NOT NULL,              -- Device information
  notes TEXT,                             -- User notes
  location TEXT,                          -- GPS or user-defined location
  created_at INTEGER NOT NULL,            -- Creation timestamp
  updated_at INTEGER NOT NULL,            -- Last update timestamp
  is_synced INTEGER NOT NULL DEFAULT 0,   -- Sync status
  cloud_id TEXT,                          -- Remote provider ID
  last_synced_at INTEGER                  -- Last sync timestamp
);
```

#### search_index table (FTS5)

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

#### user_settings table

```sql
CREATE TABLE user_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
```

#### audit_log table

```sql
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,                   -- CREATE, READ, UPDATE, DELETE, SYNC, etc.
  resource_type TEXT NOT NULL,            -- document, settings, etc.
  resource_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  details TEXT,                           -- Additional context
  location TEXT,                          -- GPS coordinates if available
  device_info TEXT,
  is_success INTEGER NOT NULL,
  error_message TEXT
);
```

#### sync_queue table

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,                   -- UPLOAD, DOWNLOAD, DELETE
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  data TEXT NOT NULL,                     -- JSON payload
  created_at INTEGER NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_retry_at INTEGER,
  status TEXT NOT NULL DEFAULT 'pending'  -- pending, processing, completed, failed
);
```

### Export/Migration Format

#### Metadata Export (JSON)

```json
{
	"version": "1.0",
	"export_date": "2024-01-15T10:30:00Z",
	"documents": [
		{
			"id": "uuid-here",
			"title": "Receipt - Coffee Shop",
			"type": "receipt",
			"scan_date": "2024-01-15T09:15:00Z",
			"tags": ["business", "expense"],
			"metadata": {
				"amount": 4.5,
				"currency": "USD",
				"merchant": "Coffee Shop"
			},
			"extracted_text": "Coffee Shop\n123 Main St\nTotal: $4.50",
			"confidence_score": 0.95,
			"detected_language": "en"
		}
	],
	"settings": {
		"metadata_storage_provider": "local",
		"file_storage_provider": "googleDrive",
		"auto_sync": true
	}
}
```

## 6. Acceptance Criteria

-   [ ] App works fully offline
-   [ ] User can select/mix providers for files and metadata
-   [ ] Privacy and security controls are prominent and enforced
-   [ ] Performance benchmarks met (instant local search, <2s remote search)
-   [ ] Sync, migration, export/import, and audit features all working
-   [ ] No cloud analytics, ads, or unexpected data flows

## 7. Implementation Status

### ✅ Completed Features

-   [x] Core document models and data structures
-   [x] SQLite database with FTS5 search
-   [x] OCR service with Google ML Kit integration
-   [x] Camera service with image capture and processing
-   [x] Encryption service with AES-256 and biometric auth
-   [x] Storage provider abstraction (local and Google Drive)
-   [x] Riverpod state management
-   [x] Complete UI implementation (screens and widgets)
-   [x] Document scanning and text extraction
-   [x] Document organization and search
-   [x] Settings management
-   [x] Privacy audit logging
-   [x] Security and encryption

### 🚧 In Progress

-   [ ] Cloud storage provider integration testing
-   [ ] Background sync implementation
-   [ ] Data migration wizards
-   [ ] Export/import functionality
-   [ ] Performance optimization

### 📋 Pending

-   [ ] OneDrive integration
-   [ ] Advanced analytics
-   [ ] Premium features
-   [ ] Localization
-   [ ] App store deployment

## 8. Developer Instructions

### Data Storage Locations

-   **Local Metadata**: Encrypted SQLite database in app documents directory
-   **Local Files**: Encrypted image files in app documents/scans directory
-   **Cloud Metadata**: Provider-specific storage (Google Drive app data folder)
-   **Cloud Files**: Provider-specific storage with encryption

### Security Implementation

-   All local data encrypted with AES-256
-   Encryption keys stored in secure storage
-   Biometric authentication for app access
-   OAuth2 for cloud provider authentication
-   Audit trail for all data operations

### Provider Module Architecture

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

### Migration Scripts

-   Export utility: `lib/utils/export_helper.dart`
-   Import utility: `lib/utils/import_helper.dart`
-   Migration wizard: `lib/ui/screens/migration_screen.dart`

## 9. Appendix

### Architecture Diagrams

See `docs/architecture/` for detailed PlantUML diagrams:

-   System architecture
-   Data flow diagrams
-   Security model
-   Provider integration patterns

### UI Mockups

See `docs/user-guide/` for:

-   User interface mockups
-   User journey flows
-   Accessibility guidelines

### API Documentation

See `docs/api/` for:

-   Service interfaces
-   Provider APIs
-   Data models
-   Error handling

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Implementation Complete - Testing Phase
