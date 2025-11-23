# Database Export/Import to Google Drive Feature

## Overview

This feature allows users to export and import the entire database to/from Google Drive with full encryption at rest and in transit.

## Security Features

### Encryption at Rest
- Database file is encrypted using AES-256 before upload
- Uses the app's encryption service (same key as local data)
- Encrypted file has `.enc` extension

### Encryption in Transit
- Google Drive API uses HTTPS/TLS automatically
- All data transmission is encrypted via TLS 1.2+
- No plaintext data is sent over the network

## Implementation

### Files Created

1. **`lib/services/database_export_service.dart`**
   - Main service for export/import operations
   - Handles encryption, upload, download, and decryption
   - Manages database connection lifecycle

2. **`lib/providers/database_export_provider.dart`**
   - Riverpod provider for state management
   - Provides `DatabaseExportNotifier` for UI integration

### Key Methods

#### Export Database
```dart
Future<String> exportDatabaseToGoogleDrive({
  String? customFileName,
  Function(double)? onProgress,
})
```

**Process:**
1. Close database connection
2. Copy database to temporary location
3. Encrypt database file (AES-256)
4. Upload encrypted file to Google Drive
5. Clean up temporary files
6. Reopen database connection
7. Log audit entry

#### Import Database
```dart
Future<void> importDatabaseFromGoogleDrive({
  required String driveFileId,
  bool backupCurrent = true,
  Function(double)? onProgress,
})
```

**Process:**
1. Download encrypted file from Google Drive
2. Decrypt database file
3. Backup current database (optional)
4. Close current database connection
5. Replace database with imported one
6. Reopen database connection
7. Log audit entry

#### List Backups
```dart
Future<List<Map<String, dynamic>>> listDatabaseBackups()
```

Returns list of available backups with metadata:
- File ID
- File name
- Creation date
- Modification date
- File size

#### Delete Backup
```dart
Future<void> deleteDatabaseBackup(String driveFileId)
```

## Usage

### Using the Provider

```dart
// In your widget
final exportNotifier = ref.read(databaseExportNotifierProvider.notifier);
final exportState = ref.watch(databaseExportNotifierProvider);

// Export database
final fileId = await exportNotifier.exportDatabase();

// Import database
final success = await exportNotifier.importDatabase(
  driveFileId: 'file_id_here',
  backupCurrent: true,
);

// List backups
await exportNotifier.refreshBackups();
final backups = exportState.availableBackups;

// Delete backup
await exportNotifier.deleteBackup('file_id_here');
```

### State Management

The `DatabaseExportState` provides:
- `isExporting`: Whether export is in progress
- `isImporting`: Whether import is in progress
- `progress`: Progress percentage (0.0 - 1.0)
- `error`: Error message if operation failed
- `lastExportFileId`: ID of last exported file
- `availableBackups`: List of available backups

## Security Considerations

### Encryption Key Management
- Uses the same encryption key as local data
- Key is stored in secure storage (flutter_secure_storage)
- Key never leaves the device
- Each device has its own encryption key

### Data Privacy
- Database is encrypted before leaving the device
- Google Drive only stores encrypted data
- Even if Google Drive is compromised, data remains encrypted
- User must have the encryption key to decrypt

### Best Practices
1. **Backup Encryption Key**: Users should backup their encryption key separately
2. **Regular Backups**: Export database regularly for safety
3. **Test Restores**: Periodically test import to ensure backups work
4. **Secure Storage**: Keep encryption key in a secure password manager

## Error Handling

All operations include comprehensive error handling:
- Database connection errors
- Encryption/decryption errors
- Google Drive API errors
- Network errors
- File system errors

Errors are logged and returned to the caller for UI display.

## Audit Logging

All export/import operations are logged in the audit log:
- `AuditAction.backup` for exports
- `AuditAction.restore` for imports
- `AuditAction.delete` for backup deletion

## File Naming

Exported files use the format:
```
ocrix_database_backup_YYYY-MM-DD.db.enc
```

Custom filenames can be provided via the `customFileName` parameter.

## Storage Location

Files are stored in Google Drive's `appDataFolder`:
- Hidden from user's main Drive view
- Only accessible by the app
- Automatically cleaned up if app is uninstalled

## Limitations

1. **File Size**: Google Drive has file size limits
2. **Network Required**: Requires internet connection
3. **Google Account**: Requires Google Sign-In
4. **Encryption Key**: Must be same on export and import devices

## Future Enhancements

- [ ] Progress tracking for large databases
- [ ] Scheduled automatic backups
- [ ] Multiple backup versions
- [ ] Backup compression
- [ ] Export to other cloud providers
- [ ] Partial database export (selected documents only)

---

**Created**: January 2024  
**Branch**: `feature/db-export-import-gdrive`  
**Status**: ✅ Complete

