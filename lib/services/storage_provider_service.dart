import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../models/storage_provider.dart';
import '../models/document.dart';
import '../core/interfaces/storage_provider_service_interface.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'encryption_service.dart';
import 'database_service.dart';

abstract class StorageProviderInterface {
  Future<bool> initialize();
  Future<String> uploadFile(String localPath, String remotePath);
  Future<String> downloadFile(String remotePath, String localPath);
  Future<void> deleteFile(String remotePath);
  Future<List<String>> listFiles(String? prefix);
  Future<bool> isConnected();
  Future<void> disconnect();
}

class LocalStorageProvider implements StorageProviderInterface {
  // Note: This is not a service, so it doesn't extend BaseService
  // Using Logger directly for now
  final logger = Logger();
  final String _basePath;

  LocalStorageProvider({String? basePath})
    : _basePath = basePath ?? 'documents';

  @override
  Future<bool> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final storageDir = Directory(path.join(directory.path, _basePath));

      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }

      logger.i('Local storage provider initialized');
      return true;
    } catch (e) {
      logger.e('Failed to initialize local storage: $e');
      return false;
    }
  }

  @override
  Future<String> uploadFile(String localPath, String remotePath) async {
    try {
      final sourceFile = File(localPath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $localPath');
      }

      final directory = await getApplicationDocumentsDirectory();
      final targetPath = path.join(directory.path, _basePath, remotePath);
      final targetFile = File(targetPath);

      // Create directory if it doesn't exist
      await targetFile.parent.create(recursive: true);

      // Copy file
      await sourceFile.copy(targetPath);

      logger.i('File uploaded to local storage: $remotePath');
      return targetPath;
    } catch (e) {
      logger.e('Failed to upload file to local storage: $e');
      rethrow;
    }
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sourcePath = path.join(directory.path, _basePath, remotePath);
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Remote file does not exist: $remotePath');
      }

      // Create target directory if it doesn't exist
      final targetFile = File(localPath);
      await targetFile.parent.create(recursive: true);

      // Copy file
      await sourceFile.copy(localPath);

      logger.i('File downloaded from local storage: $remotePath');
      return localPath;
    } catch (e) {
      logger.e('Failed to download file from local storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String remotePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, _basePath, remotePath);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        logger.i('File deleted from local storage: $remotePath');
      }
    } catch (e) {
      logger.e('Failed to delete file from local storage: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> listFiles(String? prefix) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final storageDir = Directory(path.join(directory.path, _basePath));

      if (!await storageDir.exists()) {
        return [];
      }

      final files = <String>[];
      await for (final entity in storageDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(
            entity.path,
            from: storageDir.path,
          );
          if (prefix == null || relativePath.startsWith(prefix)) {
            files.add(relativePath);
          }
        }
      }

      logger.i('Listed ${files.length} files from local storage');
      return files;
    } catch (e) {
      logger.e('Failed to list files from local storage: $e');
      return [];
    }
  }

  @override
  Future<bool> isConnected() async {
    return true; // Local storage is always "connected"
  }

  @override
  Future<void> disconnect() async {
    // Nothing to disconnect for local storage
  }
}

class GoogleDriveStorageProvider implements StorageProviderInterface {
  // Note: This is not a service, so it doesn't extend BaseService
  // Using Logger directly for now
  final logger = Logger();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    'https://www.googleapis.com/auth/drive.appdata', // Required for appDataFolder access
  ];

  drive.DriveApi? _driveApi;
  bool _isInitialized = false;
  GoogleSignInAccount? _currentUser;

  // Expose driveApi for advanced operations (like getting file metadata)
  drive.DriveApi? get driveApi => _driveApi;

  @override
  Future<bool> initialize() async {
    try {
      // Initialize GoogleSignIn if not already initialized
      await _googleSignIn.initialize();

      // Authenticate user
      GoogleSignInAccount? user;
      if (_googleSignIn.supportsAuthenticate()) {
        user = await _googleSignIn.authenticate(scopeHint: _scopes);
      } else {
        // For platforms that don't support authenticate (e.g., web)
        // Try lightweight authentication first
        final result = _googleSignIn.attemptLightweightAuthentication();
        if (result is Future<GoogleSignInAccount?>) {
          user = await result;
        }
      }

      if (user == null) {
        logger.w('Google Sign-In cancelled or failed');
        return false;
      }

      _currentUser = user;

      // Get authorization for the scopes
      final authorization = await user.authorizationClient
          .authorizationForScopes(_scopes);
      if (authorization == null) {
        // Need to request authorization
        final newAuth = await user.authorizationClient.authorizeScopes(_scopes);
        if (newAuth == null) {
          logger.e('Failed to get authorization');
          return false;
        }
      }

      // Get fresh authorization token
      final clientAuth = await user.authorizationClient.authorizationForScopes(
        _scopes,
      );
      if (clientAuth == null) {
        logger.e('Failed to get access token after authorization');
        return false;
      }

      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            clientAuth.accessToken,
            DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
          null, // idToken is no longer available in the same way
          _scopes,
        ),
      );

      _driveApi = drive.DriveApi(authClient);
      _isInitialized = true;

      logger.i('Google Drive storage provider initialized');
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        logger.w('User canceled sign-in');
      } else {
        logger.e(
          'Google Sign-In exception: ${e.description ?? e.code.toString()}',
        );
      }
      return false;
    } catch (e) {
      logger.e('Failed to initialize Google Drive storage: $e');
      return false;
    }
  }

  @override
  Future<String> uploadFile(String localPath, String remotePath) async {
    try {
      if (!_isInitialized || _driveApi == null) {
        throw Exception('Google Drive not initialized');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Source file does not exist: $localPath');
      }

      final bytes = await file.readAsBytes();
      final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

      final driveFile = drive.File();
      driveFile.name = path.basename(remotePath);
      driveFile.parents = ['appDataFolder']; // Store in app-specific folder

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      logger.i('File uploaded to Google Drive: ${uploadedFile.id}');
      return uploadedFile.id ?? '';
    } catch (e) {
      logger.e('Failed to upload file to Google Drive: $e');
      rethrow;
    }
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    try {
      if (!_isInitialized || _driveApi == null) {
        throw Exception('Google Drive not initialized');
      }

      final media =
          await _driveApi!.files.get(
                remotePath,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final file = File(localPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);

      logger.i('File downloaded from Google Drive: $remotePath');
      return localPath;
    } catch (e) {
      logger.e('Failed to download file from Google Drive: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String remotePath) async {
    try {
      if (!_isInitialized || _driveApi == null) {
        throw Exception('Google Drive not initialized');
      }

      await _driveApi!.files.delete(remotePath);
      logger.i('File deleted from Google Drive: $remotePath');
    } catch (e) {
      logger.e('Failed to delete file from Google Drive: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> listFiles(String? prefix) async {
    try {
      if (!_isInitialized || _driveApi == null) {
        throw Exception('Google Drive not initialized');
      }

      final files = await _driveApi!.files.list(
        q: "parents in 'appDataFolder'",
        spaces: 'appDataFolder',
      );

      final fileIds =
          files.files
              ?.map((file) => file.id ?? '')
              .where((id) => id.isNotEmpty)
              .toList() ??
          [];

      logger.i('Listed ${fileIds.length} files from Google Drive');
      return fileIds;
    } catch (e) {
      logger.e('Failed to list files from Google Drive: $e');
      return [];
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      return _isInitialized && _currentUser != null;
    } catch (e) {
      logger.e('Failed to check Google Drive connection: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      _isInitialized = false;
      _currentUser = null;
      logger.i('Disconnected from Google Drive');
    } catch (e) {
      logger.e('Failed to disconnect from Google Drive: $e');
    }
  }
}

class StorageProviderService extends BaseService
    implements IStorageProviderService {
  final Map<StorageProviderType, StorageProviderInterface> _providers = {};
  IEncryptionService? _encryptionService;
  StorageProviderType? _currentProvider;

  @override
  String get serviceName => 'StorageProviderService';

  // Dependency injection for encryption service
  void setEncryptionService(IEncryptionService encryptionService) {
    _encryptionService = encryptionService;
  }

  IEncryptionService get encryptionService {
    return _encryptionService ?? EncryptionService();
  }

  @override
  Future<void> initialize() async {
    try {
      // Initialize local storage
      final localProvider = LocalStorageProvider();
      await localProvider.initialize();
      _providers[StorageProviderType.local] = localProvider;
      _currentProvider = StorageProviderType.local;

      logInfo('Storage provider service initialized');
    } catch (e) {
      logError('Failed to initialize storage provider service', e);
      throw StorageException(
        'Failed to initialize storage provider service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  List<StorageProviderType> getAvailableProviders() {
    return StorageProviderType.values;
  }

  @override
  Future<StorageProviderType> getCurrentProvider() async {
    return _currentProvider ?? StorageProviderType.local;
  }

  @override
  Future<void> setProvider(StorageProviderType provider) async {
    _currentProvider = provider;
    await getProvider(provider); // Ensure provider is initialized
  }

  Future<StorageProviderInterface> getProvider(StorageProviderType type) async {
    if (_providers.containsKey(type)) {
      return _providers[type]!;
    }

    switch (type) {
      case StorageProviderType.local:
        final provider = LocalStorageProvider();
        await provider.initialize();
        _providers[type] = provider;
        return provider;

      case StorageProviderType.googleDrive:
        final provider = GoogleDriveStorageProvider();
        final initialized = await provider.initialize();
        if (initialized) {
          _providers[type] = provider;
        }
        return provider;

      default:
        throw Exception('Unsupported storage provider type: $type');
    }
  }

  @override
  Future<String> uploadDocument(Document document) async {
    final providerType = await getCurrentProvider();
    try {
      final provider = await getProvider(providerType);

      // Check if document has image data or image path
      if (document.imageData == null && document.imagePath == null) {
        throw Exception('Document has no image data or path to upload');
      }

      // For database-stored images, we need to create a temporary file
      String filePath;
      if (document.imageData != null) {
        // Create temporary file from image data
        final tempDir = await Directory.systemTemp.createTemp('upload_');
        final tempFile = File('${tempDir.path}/${document.id}.jpg');
        await tempFile.writeAsBytes(document.imageData!);
        filePath = tempFile.path;
      } else {
        // Use existing image path
        filePath = document.imagePath!;
      }

      // Encrypt the file if needed
      if (document.isEncrypted) {
        filePath = await encryptionService.encryptFile(filePath);
      }

      // Upload to storage provider
      final remotePath = 'documents/${document.id}/${path.basename(filePath)}';
      final uploadedPath = await provider.uploadFile(filePath, remotePath);

      logInfo('Document uploaded: ${document.id} to $providerType');
      return uploadedPath;
    } catch (e) {
      logError('Failed to upload document', e);
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException(
        'Failed to upload document: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> downloadDocument(String documentId, String localPath) async {
    // Simplified - in production, fetch remotePath from database
    final providerType = await getCurrentProvider();
    final remotePath = 'documents/$documentId'; // Simplified

    try {
      final provider = await getProvider(providerType);
      final downloadedPath = await provider.downloadFile(remotePath, localPath);

      logInfo('Document downloaded: $documentId');
      return downloadedPath;
    } catch (e) {
      logError('Failed to download document', e);
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException(
        'Failed to download document: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    final providerType = await getCurrentProvider();
    final remotePath = 'documents/$documentId'; // Simplified

    try {
      final provider = await getProvider(providerType);
      await provider.deleteFile(remotePath);
      logInfo('Document deleted: $documentId from $providerType');
    } catch (e) {
      logError('Failed to delete document', e);
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException(
        'Failed to delete document: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<String>> listDocuments({String? prefix}) async {
    final providerType = await getCurrentProvider();
    try {
      final provider = await getProvider(providerType);
      return await provider.listFiles(prefix);
    } catch (e) {
      logError('Failed to list documents', e);
      return [];
    }
  }

  @override
  Future<bool> isConnected() async {
    final providerType = await getCurrentProvider();
    try {
      final provider = await getProvider(providerType);
      return await provider.isConnected();
    } catch (e) {
      logError('Failed to check provider connection', e);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    final providerType = await getCurrentProvider();
    try {
      if (_providers.containsKey(providerType)) {
        await _providers[providerType]!.disconnect();
        _providers.remove(providerType);
        logInfo('Disconnected from $providerType');
      }
    } catch (e) {
      logError('Failed to disconnect provider', e);
    }
  }

  @override
  Future<void> syncToCloud() async {
    try {
      logInfo('Starting cloud sync (upload)');

      // Check if cloud provider is configured
      if (_currentProvider == StorageProviderType.local) {
        logWarning('Cannot sync to cloud: No cloud provider configured');
        return;
      }

      // Get database service to fetch unsynced documents
      final dbService = DatabaseService();
      final documents = await dbService.getAllDocuments();

      // Filter unsynced documents
      final unsyncedDocs = documents.where((doc) => !doc.isSynced).toList();

      if (unsyncedDocs.isEmpty) {
        logInfo('No documents to sync');
        return;
      }

      logInfo('Found ${unsyncedDocs.length} documents to sync');

      // Upload each unsynced document
      int syncedCount = 0;
      for (final doc in unsyncedDocs) {
        try {
          await uploadDocument(doc);

          // Mark as synced in database
          final updatedDoc = doc.copyWith(
            updatedAt: DateTime.now(),
            isSynced: true,
          );

          await dbService.updateDocument(updatedDoc);
          syncedCount++;

          logInfo('Synced document: ${doc.title}');
        } catch (e) {
          logError('Failed to sync document ${doc.title}', e);
          // Continue with next document
        }
      }

      logInfo(
        'Cloud sync completed: $syncedCount/${unsyncedDocs.length} documents synced',
      );
    } catch (e) {
      logError('Failed to sync to cloud', e);
      throw StorageException(
        'Failed to sync to cloud: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> syncFromCloud() async {
    try {
      logInfo('Starting cloud sync (download)');

      // Check if cloud provider is configured
      if (_currentProvider == StorageProviderType.local) {
        logWarning('Cannot sync from cloud: No cloud provider configured');
        return;
      }

      // Get list of files from cloud
      final provider = await getProvider(_currentProvider!);
      final cloudFiles = await provider.listFiles(null);

      if (cloudFiles.isEmpty) {
        logInfo('No files found in cloud storage');
        return;
      }

      logInfo('Found ${cloudFiles.length} files in cloud');

      // Get database service to check existing documents
      final dbService = DatabaseService();
      final localDocs = await dbService.getAllDocuments();
      final localFileNames = localDocs
          .where((d) => d.imagePath != null)
          .map((d) => path.basename(d.imagePath!))
          .toSet();

      // Download files that don't exist locally
      int downloadedCount = 0;
      final directory = await getApplicationDocumentsDirectory();

      for (final cloudFile in cloudFiles) {
        final fileName = path.basename(cloudFile);

        if (!localFileNames.contains(fileName)) {
          try {
            final localPath = path.join(directory.path, 'downloads', fileName);
            await provider.downloadFile(cloudFile, localPath);
            downloadedCount++;

            logInfo('Downloaded file from cloud: $fileName');
          } catch (e) {
            logError('Failed to download file $fileName', e);
            // Continue with next file
          }
        }
      }

      logInfo('Cloud sync completed: $downloadedCount new files downloaded');
    } catch (e) {
      logError('Failed to sync from cloud', e);
      throw StorageException(
        'Failed to sync from cloud: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // Backward compatibility methods
  Future<bool> isProviderConnected(StorageProviderType providerType) async {
    return await getProvider(providerType).then((p) => p.isConnected());
  }

  Future<void> disconnectProvider(StorageProviderType providerType) async {
    await disconnect();
  }

  Future<void> dispose() async {
    try {
      for (final provider in _providers.values) {
        await provider.disconnect();
      }
      _providers.clear();
      logInfo('Storage provider service disposed');
    } catch (e) {
      logError('Failed to dispose storage provider service', e);
    }
  }
}
