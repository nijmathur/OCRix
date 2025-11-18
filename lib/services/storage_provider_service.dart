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
import 'encryption_service.dart';

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
  final Logger _logger = Logger();
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

      _logger.i('Local storage provider initialized');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize local storage: $e');
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

      _logger.i('File uploaded to local storage: $remotePath');
      return targetPath;
    } catch (e) {
      _logger.e('Failed to upload file to local storage: $e');
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

      _logger.i('File downloaded from local storage: $remotePath');
      return localPath;
    } catch (e) {
      _logger.e('Failed to download file from local storage: $e');
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
        _logger.i('File deleted from local storage: $remotePath');
      }
    } catch (e) {
      _logger.e('Failed to delete file from local storage: $e');
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
          final relativePath =
              path.relative(entity.path, from: storageDir.path);
          if (prefix == null || relativePath.startsWith(prefix)) {
            files.add(relativePath);
          }
        }
      }

      _logger.i('Listed ${files.length} files from local storage');
      return files;
    } catch (e) {
      _logger.e('Failed to list files from local storage: $e');
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
  final Logger _logger = Logger();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  drive.DriveApi? _driveApi;
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _logger.w('Google Sign-In cancelled');
        return false;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        _logger.e('Failed to get access token');
        return false;
      }

      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', auth.accessToken!,
              DateTime.now().add(const Duration(hours: 1))),
          auth.idToken,
          [
            drive.DriveApi.driveFileScope,
          ],
        ),
      );

      _driveApi = drive.DriveApi(authClient);
      _isInitialized = true;

      _logger.i('Google Drive storage provider initialized');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize Google Drive storage: $e');
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

      _logger.i('File uploaded to Google Drive: ${uploadedFile.id}');
      return uploadedFile.id ?? '';
    } catch (e) {
      _logger.e('Failed to upload file to Google Drive: $e');
      rethrow;
    }
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    try {
      if (!_isInitialized || _driveApi == null) {
        throw Exception('Google Drive not initialized');
      }

      final media = await _driveApi!.files.get(
        remotePath,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final file = File(localPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);

      _logger.i('File downloaded from Google Drive: $remotePath');
      return localPath;
    } catch (e) {
      _logger.e('Failed to download file from Google Drive: $e');
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
      _logger.i('File deleted from Google Drive: $remotePath');
    } catch (e) {
      _logger.e('Failed to delete file from Google Drive: $e');
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

      final fileIds = files.files
              ?.map((file) => file.id ?? '')
              .where((id) => id.isNotEmpty)
              .toList() ??
          [];

      _logger.i('Listed ${fileIds.length} files from Google Drive');
      return fileIds;
    } catch (e) {
      _logger.e('Failed to list files from Google Drive: $e');
      return [];
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      return _isInitialized && await _googleSignIn.isSignedIn();
    } catch (e) {
      _logger.e('Failed to check Google Drive connection: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      _isInitialized = false;
      _logger.i('Disconnected from Google Drive');
    } catch (e) {
      _logger.e('Failed to disconnect from Google Drive: $e');
    }
  }
}

class StorageProviderService {
  static final StorageProviderService _instance =
      StorageProviderService._internal();
  factory StorageProviderService() => _instance;
  StorageProviderService._internal();

  final Logger _logger = Logger();
  final Map<StorageProviderType, StorageProviderInterface> _providers = {};
  final EncryptionService _encryptionService = EncryptionService();

  Future<void> initialize() async {
    try {
      // Initialize local storage
      final localProvider = LocalStorageProvider();
      await localProvider.initialize();
      _providers[StorageProviderType.local] = localProvider;

      _logger.i('Storage provider service initialized');
    } catch (e) {
      _logger.e('Failed to initialize storage provider service: $e');
      rethrow;
    }
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

  Future<String> uploadDocument(
      Document document, StorageProviderType providerType) async {
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
        filePath = await _encryptionService.encryptFile(filePath);
      }

      // Upload to storage provider
      final remotePath = 'documents/${document.id}/${path.basename(filePath)}';
      final uploadedPath = await provider.uploadFile(filePath, remotePath);

      _logger.i('Document uploaded: ${document.id} to $providerType');
      return uploadedPath;
    } catch (e) {
      _logger.e('Failed to upload document: $e');
      rethrow;
    }
  }

  Future<String> downloadDocument(String documentId, String remotePath,
      String localPath, bool isEncrypted) async {
    try {
      // Determine provider type from remote path or use default
      final provider = await getProvider(
          StorageProviderType.local); // Default to local for now

      // Download from storage provider
      final downloadedPath = await provider.downloadFile(remotePath, localPath);

      // Decrypt if needed
      if (isEncrypted) {
        final decryptedPath =
            await _encryptionService.decryptFile(downloadedPath);
        _logger.i('Document downloaded and decrypted: $documentId');
        return decryptedPath;
      }

      _logger.i('Document downloaded: $documentId');
      return downloadedPath;
    } catch (e) {
      _logger.e('Failed to download document: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String documentId, String remotePath,
      StorageProviderType providerType) async {
    try {
      final provider = await getProvider(providerType);
      await provider.deleteFile(remotePath);
      _logger.i('Document deleted: $documentId from $providerType');
    } catch (e) {
      _logger.e('Failed to delete document: $e');
      rethrow;
    }
  }

  Future<List<String>> listDocuments(StorageProviderType providerType,
      {String? prefix}) async {
    try {
      final provider = await getProvider(providerType);
      return await provider.listFiles(prefix);
    } catch (e) {
      _logger.e('Failed to list documents: $e');
      return [];
    }
  }

  Future<bool> isProviderConnected(StorageProviderType providerType) async {
    try {
      final provider = await getProvider(providerType);
      return await provider.isConnected();
    } catch (e) {
      _logger.e('Failed to check provider connection: $e');
      return false;
    }
  }

  Future<void> disconnectProvider(StorageProviderType providerType) async {
    try {
      if (_providers.containsKey(providerType)) {
        await _providers[providerType]!.disconnect();
        _providers.remove(providerType);
        _logger.i('Disconnected from $providerType');
      }
    } catch (e) {
      _logger.e('Failed to disconnect provider: $e');
    }
  }

  Future<void> dispose() async {
    try {
      for (final provider in _providers.values) {
        await provider.disconnect();
      }
      _providers.clear();
      _logger.i('Storage provider service disposed');
    } catch (e) {
      _logger.e('Failed to dispose storage provider service: $e');
    }
  }
}
