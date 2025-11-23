import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/interfaces/storage_provider_service_interface.dart';
import '../models/audit_log.dart';
import '../models/storage_provider.dart';
import 'database_service.dart';
import 'storage_provider_service.dart';

/// Service for exporting and importing the entire database to/from Google Drive
/// with encryption at rest and in transit
class DatabaseExportService extends BaseService {
  final DatabaseService _databaseService;
  final IEncryptionService _encryptionService;

  DatabaseExportService({
    required DatabaseService databaseService,
    required IEncryptionService encryptionService,
    required IStorageProviderService storageProviderService,
  })  : _databaseService = databaseService,
        _encryptionService = encryptionService;

  @override
  String get serviceName => 'DatabaseExportService';

  /// Export the entire database to Google Drive with encryption
  /// 
  /// Steps:
  /// 1. Close the database connection
  /// 2. Copy the database file to a temporary location
  /// 3. Encrypt the database file (encryption at rest)
  /// 4. Upload to Google Drive (encryption in transit via HTTPS/TLS)
  /// 5. Reopen the database connection
  /// 6. Log audit entry
  /// 
  /// Returns the Google Drive file ID
  Future<String> exportDatabaseToGoogleDrive({
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      logInfo('Starting database export to Google Drive...');

      // Ensure encryption service is initialized
      if (!_encryptionService.isInitialized) {
        await _encryptionService.initialize();
      }

      // Step 1: Close database connection to ensure file is not locked
      await _databaseService.close();
      logInfo('Database connection closed for export');

      try {
        // Step 2: Get database file path
        final documentsDir = await getApplicationDocumentsDirectory();
        final dbPath = path.join(documentsDir.path, 'privacy_documents.db');
        final dbFile = File(dbPath);

        if (!await dbFile.exists()) {
          throw DatabaseException('Database file does not exist: $dbPath');
        }

        // Step 3: Copy database to temporary location for encryption
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final tempDbPath = path.join(
          tempDir.path,
          'privacy_documents_export_$timestamp.db',
        );
        final tempDbFile = await dbFile.copy(tempDbPath);
        logInfo('Database copied to temporary location: $tempDbPath');

        // Step 4: Encrypt the database file (encryption at rest)
        logInfo('Encrypting database file...');
        final encryptedFilePath = await _encryptionService.encryptFile(
          tempDbPath,
        );
        final encryptedFile = File(encryptedFilePath);
        
        if (!await encryptedFile.exists()) {
          throw EncryptionException('Encrypted file was not created');
        }

        final encryptedFileSize = await encryptedFile.length();
        logInfo(
          'Database encrypted: ${tempDbFile.lengthSync()} bytes -> $encryptedFileSize bytes',
        );

        // Step 5: Upload encrypted file to Google Drive (encryption in transit via HTTPS/TLS)
        logInfo('Uploading encrypted database to Google Drive...');
        
        // Generate filename with timestamp
        final fileName = customFileName ??
            'ocrix_database_backup_${DateTime.now().toIso8601String().split('T')[0]}.db.enc';
        
        final remotePath = 'backups/$fileName';

        // Get Google Drive provider via storage provider service
        final storageService = StorageProviderService();
        await storageService.initialize();
        
        // Get the Google Drive provider directly
        final provider = await storageService.getProvider(
          StorageProviderType.googleDrive,
        );

        // Ensure provider is initialized
        if (!await provider.isConnected()) {
          final initialized = await provider.initialize();
          if (!initialized) {
            throw StorageException('Failed to initialize Google Drive provider');
          }
        }

        // Upload encrypted file to Google Drive
        // Note: Google Drive API uses HTTPS/TLS automatically (encryption in transit)
        final driveFileId = await provider.uploadFile(encryptedFilePath, remotePath);

        logInfo('Database uploaded to Google Drive: $driveFileId');

        // Step 6: Clean up temporary files
        try {
          await tempDbFile.delete();
          await encryptedFile.delete();
          logInfo('Temporary files cleaned up');
        } catch (e) {
          logWarning('Failed to clean up temporary files: $e');
        }

        // Step 7: Reopen database connection
        await _databaseService.initialize();
        logInfo('Database connection reopened');

        // Step 8: Log audit entry
        await _databaseService.logAudit(
          AuditAction.backup,
          'database',
          'database_export',
          'Database exported to Google Drive: $driveFileId',
        );

        logInfo('Database export completed successfully: $driveFileId');
        return driveFileId;
      } catch (e) {
        // Ensure database is reopened even on error
        try {
          await _databaseService.initialize();
        } catch (reopenError) {
          logError('Failed to reopen database after export error', reopenError);
        }
        rethrow;
      }
    } catch (e) {
      logError('Failed to export database to Google Drive', e);
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException(
        'Failed to export database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Import the entire database from Google Drive with decryption
  /// 
  /// Steps:
  /// 1. Download encrypted database from Google Drive (encryption in transit via HTTPS/TLS)
  /// 2. Decrypt the database file
  /// 3. Close the current database connection
  /// 4. Backup current database (optional)
  /// 5. Replace current database with imported one
  /// 6. Reopen the database connection
  /// 7. Log audit entry
  /// 
  /// [driveFileId] - The Google Drive file ID to import from
  /// [backupCurrent] - Whether to backup the current database before import
  Future<void> importDatabaseFromGoogleDrive({
    required String driveFileId,
    bool backupCurrent = true,
    Function(double)? onProgress,
  }) async {
    try {
      logInfo('Starting database import from Google Drive: $driveFileId');

      // Ensure encryption service is initialized
      if (!_encryptionService.isInitialized) {
        await _encryptionService.initialize();
      }

      // Step 1: Get Google Drive provider
      final storageService = StorageProviderService();
      await storageService.initialize();
      
      final provider = await storageService.getProvider(
        StorageProviderType.googleDrive,
      );

      // Ensure provider is initialized
      if (!await provider.isConnected()) {
        final initialized = await provider.initialize();
        if (!initialized) {
          throw StorageException('Failed to initialize Google Drive provider');
        }
      }

      // Step 2: Download encrypted database from Google Drive (encryption in transit via HTTPS/TLS)
      logInfo('Downloading encrypted database from Google Drive...');
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final encryptedFilePath = path.join(
        tempDir.path,
        'ocrix_database_import_$timestamp.db.enc',
      );

      // Download using file ID (Google Drive uses IDs, not paths)
      await provider.downloadFile(driveFileId, encryptedFilePath);
      final encryptedFile = File(encryptedFilePath);

      if (!await encryptedFile.exists()) {
        throw StorageException('Downloaded file does not exist');
      }

      logInfo('Encrypted database downloaded: ${encryptedFile.lengthSync()} bytes');

      // Step 3: Decrypt the database file
      logInfo('Decrypting database file...');
      final decryptedFilePath = await _encryptionService.decryptFile(
        encryptedFilePath,
      );
      final decryptedFile = File(decryptedFilePath);

      if (!await decryptedFile.exists()) {
        throw EncryptionException('Decrypted file was not created');
      }

      logInfo(
        'Database decrypted: ${encryptedFile.lengthSync()} bytes -> ${decryptedFile.lengthSync()} bytes',
      );

      // Step 4: Backup current database if requested
      if (backupCurrent) {
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final currentDbPath = path.join(
            documentsDir.path,
            'privacy_documents.db',
          );
          final currentDbFile = File(currentDbPath);

          if (await currentDbFile.exists()) {
            final backupPath = path.join(
              documentsDir.path,
              'privacy_documents_backup_$timestamp.db',
            );
            await currentDbFile.copy(backupPath);
            logInfo('Current database backed up to: $backupPath');
          }
        } catch (e) {
          logWarning('Failed to backup current database: $e');
          // Continue with import even if backup fails
        }
      }

      // Step 5: Close current database connection
      await _databaseService.close();
      logInfo('Database connection closed for import');

      // Step 6: Replace current database with imported one
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final targetDbPath = path.join(
          documentsDir.path,
          'privacy_documents.db',
        );
        final targetDbFile = File(targetDbPath);

        // Delete existing database if it exists
        if (await targetDbFile.exists()) {
          await targetDbFile.delete();
        }

        // Copy imported database to target location
        await decryptedFile.copy(targetDbPath);
        logInfo('Database replaced with imported version');

        // Step 7: Clean up temporary files
        try {
          await encryptedFile.delete();
          await decryptedFile.delete();
          logInfo('Temporary files cleaned up');
        } catch (e) {
          logWarning('Failed to clean up temporary files: $e');
        }

        // Step 8: Reopen database connection
        await _databaseService.initialize();
        logInfo('Database connection reopened');

        // Step 9: Log audit entry
        await _databaseService.logAudit(
          AuditAction.restore,
          'database',
          'database_import',
          'Database imported from Google Drive: $driveFileId',
        );

        logInfo('Database import completed successfully');
      } catch (e) {
        // Ensure database is reopened even on error
        try {
          await _databaseService.initialize();
        } catch (reopenError) {
          logError('Failed to reopen database after import error', reopenError);
        }
        rethrow;
      }
    } catch (e) {
      logError('Failed to import database from Google Drive', e);
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException(
        'Failed to import database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// List all database backups available in Google Drive
  /// 
  /// Returns a list of file IDs and metadata
  Future<List<Map<String, dynamic>>> listDatabaseBackups() async {
    try {
      logInfo('Listing database backups from Google Drive...');

      final storageService = StorageProviderService();
      await storageService.initialize();
      
      final provider = await storageService.getProvider(
        StorageProviderType.googleDrive,
      );

      // Ensure provider is initialized
      if (!await provider.isConnected()) {
        final initialized = await provider.initialize();
        if (!initialized) {
          throw StorageException('Failed to initialize Google Drive provider');
        }
      }

      // Access Google Drive API directly to get file metadata
      if (provider is! GoogleDriveStorageProvider) {
        throw StorageException('Provider is not GoogleDriveStorageProvider');
      }

      final driveApi = provider.driveApi;
      if (driveApi == null) {
        throw StorageException('Google Drive API not initialized');
      }

      // Query Google Drive API for files in appDataFolder
      // Filter for files that look like database backups (.db.enc)
      final filesResponse = await driveApi.files.list(
        q: "parents in 'appDataFolder' and name contains '.db.enc'",
        spaces: 'appDataFolder',
      );

      final backups = <Map<String, dynamic>>[];
      
      if (filesResponse.files != null) {
        for (final file in filesResponse.files!) {
          backups.add({
            'fileId': file.id ?? '',
            'fileName': file.name ?? 'unknown.db.enc',
            'path': file.id ?? '',
            'createdAt': file.createdTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'modifiedAt': file.modifiedTime?.toIso8601String(),
            'size': file.size,
          });
        }
      }

      logInfo('Found ${backups.length} potential database backups');
      return backups;
    } catch (e) {
      logError('Failed to list database backups', e);
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException(
        'Failed to list database backups: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete a database backup from Google Drive
  Future<void> deleteDatabaseBackup(String driveFileId) async {
    try {
      logInfo('Deleting database backup from Google Drive: $driveFileId');

      final storageService = StorageProviderService();
      final provider = await storageService.getProvider(
        StorageProviderType.googleDrive,
      );

      // Ensure provider is initialized
      if (!await provider.isConnected()) {
        final initialized = await provider.initialize();
        if (!initialized) {
          throw StorageException('Failed to initialize Google Drive provider');
        }
      }

      await provider.deleteFile(driveFileId);

      // Log audit entry
      await _databaseService.logAudit(
        AuditAction.delete,
        'database_backup',
        driveFileId,
        'Database backup deleted from Google Drive',
      );

      logInfo('Database backup deleted successfully');
    } catch (e) {
      logError('Failed to delete database backup', e);
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException(
        'Failed to delete database backup: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

