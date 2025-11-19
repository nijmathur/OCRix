import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import '../core/interfaces/encryption_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

class EncryptionService extends BaseService implements IEncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Encrypter? _encrypter;
  IV? _iv;
  Key? _key;
  bool _isInitialized = false;

  @override
  String get serviceName => 'EncryptionService';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _loadOrCreateKey();
      _isInitialized = true;
      logInfo('Encryption service initialized');
    } catch (e) {
      logError('Failed to initialize encryption service', e);
      throw EncryptionException(
        'Failed to initialize encryption service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<void> _loadOrCreateKey() async {
    try {
      // Try to load existing key
      String? keyString = await _secureStorage.read(key: 'encryption_key');

      if (keyString == null) {
        // Generate new key
        _key = Key.fromSecureRandom(32);
        keyString = _key!.base64;
        await _secureStorage.write(key: 'encryption_key', value: keyString);
        logInfo('New encryption key generated');
      } else {
        // Load existing key
        _key = Key.fromBase64(keyString);
        logInfo('Existing encryption key loaded');
      }

      _encrypter = Encrypter(AES(_key!));
      _iv = IV.fromSecureRandom(16);
    } catch (e) {
      logError('Failed to load or create encryption key', e);
      throw EncryptionException(
        'Failed to load or create encryption key: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> encryptText(String text) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw EncryptionException('Encryption not initialized');
      }

      final encrypted = _encrypter!.encrypt(text, iv: _iv!);
      logInfo('Text encrypted successfully');
      return encrypted.base64;
    } catch (e) {
      logError('Failed to encrypt text', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to encrypt text: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> decryptText(String encryptedText) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw EncryptionException('Encryption not initialized');
      }

      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      logInfo('Text decrypted successfully');
      return decrypted;
    } catch (e) {
      logError('Failed to decrypt text', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to decrypt text: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<int>> encryptBytes(List<int> bytes) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw EncryptionException('Encryption not initialized');
      }

      final data = Uint8List.fromList(bytes);
      final encrypted = _encrypter!.encryptBytes(data, iv: _iv!);
      logInfo(
          'Bytes encrypted successfully: ${bytes.length} -> ${encrypted.bytes.length}');
      return encrypted.bytes.toList();
    } catch (e) {
      logError('Failed to encrypt bytes', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to encrypt bytes: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<int>> decryptBytes(List<int> encryptedBytes) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw EncryptionException('Encryption not initialized');
      }

      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
      final decrypted = _encrypter!.decryptBytes(encrypted, iv: _iv!);
      logInfo(
          'Bytes decrypted successfully: ${encryptedBytes.length} -> ${decrypted.length}');
      return decrypted.toList();
    } catch (e) {
      logError('Failed to decrypt bytes', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to decrypt bytes: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> encryptFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw EncryptionException('File does not exist: $filePath');
      }

      final bytes = await file.readAsBytes();
      final encryptedBytes = await encryptBytes(bytes);

      // Save encrypted file with .enc extension
      final encryptedFilePath = '$filePath.enc';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(Uint8List.fromList(encryptedBytes));

      logInfo('File encrypted: $filePath -> $encryptedFilePath');
      return encryptedFilePath;
    } catch (e) {
      logError('Failed to encrypt file', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to encrypt file: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> decryptFile(String encryptedFilePath) async {
    try {
      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw EncryptionException('Encrypted file does not exist: $encryptedFilePath');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = await decryptBytes(encryptedBytes);

      // Remove .enc extension
      final decryptedFilePath = encryptedFilePath.replaceAll('.enc', '');
      final decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(Uint8List.fromList(decryptedBytes));

      logInfo('File decrypted: $encryptedFilePath -> $decryptedFilePath');
      return decryptedFilePath;
    } catch (e) {
      logError('Failed to decrypt file', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to decrypt file: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        logWarning('Biometric authentication not available');
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        logWarning('No biometrics enrolled');
        return false;
      }

      // Authenticate
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access encrypted documents',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        logInfo('Biometric authentication successful');
      } else {
        logWarning('Biometric authentication failed');
      }

      return isAuthenticated;
    } catch (e) {
      logError('Biometric authentication error', e);
      return false;
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return isAvailable && availableBiometrics.isNotEmpty;
    } catch (e) {
      logError('Failed to check biometric availability', e);
      return false;
    }
  }

  @override
  Future<void> changeEncryptionKey() async {
    try {
      // Generate new key
      final newKey = Key.fromSecureRandom(32);
      final newKeyString = newKey.base64;

      // Store new key
      await _secureStorage.write(key: 'encryption_key', value: newKeyString);

      // Update current key
      _key = newKey;
      _encrypter = Encrypter(AES(_key!));
      _iv = IV.fromSecureRandom(16);

      logInfo('Encryption key changed successfully');
    } catch (e) {
      logError('Failed to change encryption key', e);
      throw EncryptionException(
        'Failed to change encryption key: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearEncryptionKey() async {
    try {
      await _secureStorage.delete(key: 'encryption_key');
      _key = null;
      _encrypter = null;
      _iv = null;
      _isInitialized = false;
      logInfo('Encryption key cleared');
    } catch (e) {
      logError('Failed to clear encryption key', e);
      throw EncryptionException(
        'Failed to clear encryption key: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getEncryptionInfo() async {
    try {
      final biometricAvailable = await isBiometricAvailable();
      final hasKey = await _secureStorage.containsKey(key: 'encryption_key');

      return {
        'isInitialized': _isInitialized,
        'hasKey': hasKey,
        'biometricAvailable': biometricAvailable,
        'algorithm': 'AES-256',
        'keySize': 256,
      };
    } catch (e) {
      logError('Failed to get encryption info', e);
      return {};
    }
  }

  // Additional utility methods (not in interface but used internally)
  String generateHash(String data) {
    try {
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      logError('Failed to generate hash', e);
      throw EncryptionException(
        'Failed to generate hash: ${e.toString()}',
        originalError: e,
      );
    }
  }

  String generateFileHash(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw EncryptionException('File does not exist: $filePath');
      }

      final bytes = file.readAsBytesSync();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      logError('Failed to generate file hash', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to generate file hash: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<bool> verifyFileIntegrity(String filePath, String expectedHash) async {
    try {
      final actualHash = generateFileHash(filePath);
      final isValid = actualHash == expectedHash;

      if (!isValid) {
        logWarning('File integrity check failed for: $filePath');
      } else {
        logInfo('File integrity verified for: $filePath');
      }

      return isValid;
    } catch (e) {
      logError('Failed to verify file integrity', e);
      return false;
    }
  }
}
