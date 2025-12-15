# Database Export/Import to Google Drive Feature

## Overview

This feature allows users to export and import the entire database to/from Google Drive with **password-based encryption** for portable, cross-device backups.

## Security Features

### Password-Based Encryption (Updated December 2024)
- **User-provided password**: Required for both export and import
- **PBKDF2 key derivation**: 100,000 iterations with HMAC-SHA256
- **AES-256 encryption**: Industry-standard symmetric encryption
- **Unique salt per export**: 32-byte salt for rainbow table resistance
- **Unique IV per file**: 16-byte initialization vector for security
- **Portable backups**: Works across devices and app versions
- **File format**: `[Salt (32 bytes)][IV (16 bytes)][Encrypted Data]`

**IMPORTANT:** User must remember the password. If forgotten, backups cannot be recovered!

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
  required String password,  // NEW: User password for encryption
  String? customFileName,
  Function(double)? onProgress,
})
```

**Process:**
1. Prompt user for password (via `PasswordDialog`)
2. Close database connection
3. Copy database to temporary location
4. Encrypt database file with password (PBKDF2 + AES-256)
   - Derive encryption key from password using PBKDF2
   - Generate unique salt (32 bytes)
   - Generate unique IV (16 bytes)
   - Encrypt: `[Salt][IV][Encrypted Data]`
5. Upload encrypted file to Google Drive's `appDataFolder`
6. Clean up temporary files
7. Reopen database connection
8. Log audit entry

**Returns:** Google Drive file ID

#### Import Database
```dart
Future<void> importDatabaseFromGoogleDrive({
  required String driveFileId,
  required String password,  // NEW: User password for decryption
  bool backupCurrent = true,
  Function(double)? onProgress,
})
```

**Process:**
1. List available backups from Google Drive
2. Prompt user for password (same as used during export)
3. Download encrypted file from Google Drive
4. Decrypt database file with password
   - Extract salt from first 32 bytes
   - Extract IV from next 16 bytes
   - Derive encryption key from password and salt
   - Decrypt remaining data
5. Backup current database (optional)
6. Close current database connection
7. Replace database with imported one
8. Reopen database connection
9. Log audit entry

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

### Using the Provider with Password Dialog

```dart
// In your widget
final exportNotifier = ref.read(databaseExportNotifierProvider.notifier);
final exportState = ref.watch(databaseExportNotifierProvider);

// Export database (requires password)
final password = await showExportPasswordDialog(context);
if (password != null) {
  final fileId = await exportNotifier.exportDatabase(password: password);
}

// Import database (requires password)
final password = await showImportPasswordDialog(context);
if (password != null) {
  final success = await exportNotifier.importDatabase(
    driveFileId: 'file_id_here',
    password: password,
    backupCurrent: true,
  );
}

// List backups
await exportNotifier.refreshBackups();
final backups = exportState.availableBackups;

// Delete backup
await exportNotifier.deleteBackup('file_id_here');
```

### Password Dialog UI

The `PasswordDialog` widget (`lib/ui/widgets/password_dialog.dart`) provides:

**For Export:**
```dart
final password = await showExportPasswordDialog(context);
```
- Password input with show/hide toggle
- Password confirmation field
- Strength indicator (weak/medium/strong)
- Warning about password loss
- Minimum 8 characters required

**For Import:**
```dart
final password = await showImportPasswordDialog(context);
```
- Password input with show/hide toggle
- No confirmation (user already knows password)
- No strength indicator

### State Management

The `DatabaseExportState` provides:
- `isExporting`: Whether export is in progress
- `isImporting`: Whether import is in progress
- `progress`: Progress percentage (0.0 - 1.0)
- `error`: Error message if operation failed
- `lastExportFileId`: ID of last exported file
- `availableBackups`: List of available backups

## Security Considerations

### Password-Based Encryption
- **User-provided password**: Required for both export and import operations
- **PBKDF2 key derivation**:
  - 100,000 iterations (NIST SP 800-132 recommended minimum)
  - HMAC-SHA256 for key derivation
  - 32-byte (256-bit) salt, unique per export
  - 32-byte (256-bit) derived key for AES-256
- **AES-256 encryption**: Industry-standard symmetric encryption
- **Unique IV per file**: 16-byte initialization vector prevents pattern analysis
- **No key storage**: Password never stored, only used for key derivation

### Encryption Strength
**Security parameters:**
- **Algorithm**: AES-256-CBC
- **Key derivation**: PBKDF2 with 100,000 iterations
- **Hash function**: HMAC-SHA256
- **Salt size**: 32 bytes (256 bits)
- **IV size**: 16 bytes (128 bits)
- **Output key**: 32 bytes (256 bits)

**Compliance:**
- NIST SP 800-132 compliant (PBKDF2 key derivation)
- FIPS 197 compliant (AES encryption)
- Follows OWASP cryptographic guidelines

### Data Privacy
- Database encrypted before leaving device
- Google Drive only stores encrypted data
- Password never transmitted or stored
- Even if Google Drive is compromised, data remains encrypted
- Only user with password can decrypt

### Portability Benefits
- ✅ Works across all devices (Android, iOS, different devices)
- ✅ No dependency on device-specific secure storage
- ✅ Survives app reinstalls and device migrations
- ✅ User controls encryption (not device-dependent)

### Security Trade-offs
- ✅ **Pro**: Portable across devices and platforms
- ✅ **Pro**: User control over encryption password
- ✅ **Pro**: No device dependency
- ⚠️ **Con**: Password must be remembered (unrecoverable if lost)
- ⚠️ **Con**: Vulnerable to weak passwords (mitigated by strength indicator and 8-char minimum)

### Best Practices
1. **Strong Password**: Use a unique, strong password (12+ characters, mixed case, numbers, symbols)
2. **Password Storage**: Store password in a secure password manager
3. **Regular Backups**: Export database regularly for safety
4. **Test Restores**: Periodically test import to ensure backups work
5. **Password Recovery**: Keep password in multiple secure locations (never forget it!)
6. **Unique Password**: Don't reuse passwords from other services

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

1. **Password Required**: User must remember password (unrecoverable if forgotten)
2. **File Size**: Google Drive has file size limits
3. **Network Required**: Requires internet connection
4. **Google Account**: Requires Google Sign-In
5. **Password Strength**: Weak passwords are vulnerable to brute-force attacks

## Future Enhancements

- [ ] Progress tracking for large databases
- [ ] Scheduled automatic backups
- [ ] Multiple backup versions
- [ ] Backup compression
- [ ] Export to other cloud providers
- [ ] Partial database export (selected documents only)
- [ ] Password hint/recovery questions (while maintaining security)
- [ ] Biometric unlock for stored passwords

## Migration from Old Format

### Breaking Change (December 2024)
Exports created before December 2024 used device-specific encryption keys and cannot be imported with the new password-based system.

**What changed:**
- **Old format**: `[Encrypted Data]` - encrypted with device-specific key
- **New format**: `[Salt (32)][IV (16)][Encrypted Data]` - encrypted with password-derived key

**Migration path:**
1. Before upgrading: Export database from old version
2. Upgrade app to new version
3. Re-export database with password
4. Test import on another device
5. Delete old backups (can't be imported)

**Recommendation:** Users should re-export their databases after upgrading to benefit from portable backups.

---

**Created**: January 2024
**Updated**: December 2024
**Branch**: `bugfix/scroll-and-db-import-fixes`
**Status**: ✅ Complete with password-based encryption

