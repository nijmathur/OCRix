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
  Key? _key;
  bool _isInitialized = false;

  // Note: IV is no longer stored as an instance variable.
  // Each encryption operation generates a unique IV and prepends it to the
  // encrypted data. This ensures encrypted files are self-contained and can
  // be decrypted on any device with the same encryption key.

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

      if (_encrypter == null || _key == null) {
        throw EncryptionException('Encryption not initialized');
      }

      // Generate a unique IV for this encryption operation
      final uniqueIV = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(_key!));

      final encrypted = encrypter.encrypt(text, iv: uniqueIV);

      // Prepend IV to encrypted data: [IV (16 bytes)][Encrypted Data]
      final result = Uint8List(16 + encrypted.bytes.length);
      result.setRange(0, 16, uniqueIV.bytes);
      result.setRange(16, result.length, encrypted.bytes);

      logInfo('Text encrypted successfully');
      return base64.encode(result);
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

      if (_encrypter == null || _key == null) {
        throw EncryptionException('Encryption not initialized');
      }

      // Decode base64 to get [IV (16 bytes)][Encrypted Data]
      final encryptedBytes = base64.decode(encryptedText);

      if (encryptedBytes.length < 16) {
        throw EncryptionException(
            'Invalid encrypted text: too short (${encryptedBytes.length} bytes)');
      }

      // Extract IV from first 16 bytes
      final ivBytes = Uint8List.fromList(encryptedBytes.sublist(0, 16));
      final extractedIV = IV(ivBytes);

      // Extract encrypted data (everything after first 16 bytes)
      final encryptedData = Uint8List.fromList(encryptedBytes.sublist(16));

      final encrypter = Encrypter(AES(_key!));
      final encrypted = Encrypted(encryptedData);
      final decrypted = encrypter.decrypt(encrypted, iv: extractedIV);

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

      if (_encrypter == null || _key == null) {
        throw EncryptionException('Encryption not initialized');
      }

      // Generate a unique IV for this encryption operation
      // This ensures each encrypted file can be decrypted independently
      final uniqueIV = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(_key!));

      final data = Uint8List.fromList(bytes);
      final encrypted = encrypter.encryptBytes(data, iv: uniqueIV);

      // Prepend IV to encrypted data so it can be extracted during decryption
      // Format: [IV (16 bytes)][Encrypted Data]
      final result = Uint8List(16 + encrypted.bytes.length);
      result.setRange(0, 16, uniqueIV.bytes);
      result.setRange(16, result.length, encrypted.bytes);

      logInfo(
          'Bytes encrypted successfully: ${bytes.length} -> ${result.length} (IV: 16 bytes + encrypted: ${encrypted.bytes.length} bytes)');
      return result.toList();
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

      if (_encrypter == null || _key == null) {
        throw EncryptionException('Encryption not initialized');
      }

      // Encrypted data format: [IV (16 bytes)][Encrypted Data]
      if (encryptedBytes.length < 16) {
        throw EncryptionException(
            'Invalid encrypted data: too short (${encryptedBytes.length} bytes)');
      }

      // Extract IV from first 16 bytes
      final ivBytes = Uint8List.fromList(encryptedBytes.sublist(0, 16));
      final extractedIV = IV(ivBytes);

      // Extract encrypted data (everything after first 16 bytes)
      final encryptedData = Uint8List.fromList(encryptedBytes.sublist(16));

      final encrypter = Encrypter(AES(_key!));
      final encrypted = Encrypted(encryptedData);
      final decrypted = encrypter.decryptBytes(encrypted, iv: extractedIV);

      logInfo(
          'Bytes decrypted successfully: ${encryptedBytes.length} (IV: 16 bytes + encrypted: ${encryptedData.length} bytes) -> ${decrypted.length}');
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
        throw EncryptionException(
            'Encrypted file does not exist: $encryptedFilePath');
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

  // Password-based encryption methods
  // These use PBKDF2 to derive keys from passwords, making exports portable across devices

  /// Derive an encryption key from a password using PBKDF2
  /// Returns: [Key, Salt] - both are needed for encryption/decryption
  List<Uint8List> _deriveKeyFromPassword(String password, Uint8List? salt) {
    // Use provided salt or generate cryptographically secure random salt
    final keySalt = salt ?? IV.fromSecureRandom(32).bytes;

    // PBKDF2 parameters
    const iterations = 100000; // High iteration count for security
    const keyLength = 32; // 256 bits for AES-256

    // Derive key using PBKDF2 (implemented via repeated HMAC-SHA256)
    final passwordBytes = utf8.encode(password);
    var derivedKey = Uint8List(keyLength);
    var block = Uint8List(keySalt.length + 4);
    block.setRange(0, keySalt.length, keySalt);

    for (var i = 0; i < keyLength; i += 32) {
      // Block index (1-based)
      final blockIndex = (i ~/ 32) + 1;
      block[keySalt.length] = (blockIndex >> 24) & 0xff;
      block[keySalt.length + 1] = (blockIndex >> 16) & 0xff;
      block[keySalt.length + 2] = (blockIndex >> 8) & 0xff;
      block[keySalt.length + 3] = blockIndex & 0xff;

      // First iteration
      var u = Hmac(sha256, passwordBytes).convert(block).bytes;
      var result = Uint8List.fromList(u);

      // Remaining iterations
      for (var j = 1; j < iterations; j++) {
        u = Hmac(sha256, passwordBytes).convert(u).bytes;
        for (var k = 0; k < u.length; k++) {
          result[k] ^= u[k];
        }
      }

      // Copy to derived key
      final bytesToCopy = (i + 32 <= keyLength) ? 32 : keyLength - i;
      derivedKey.setRange(i, i + bytesToCopy, result);
    }

    return [derivedKey, keySalt];
  }

  /// Encrypt file with password
  /// Format: [Salt (32 bytes)][IV (16 bytes)][Encrypted Data]
  @override
  Future<String> encryptFileWithPassword(
    String filePath,
    String password,
  ) async {
    try {
      logInfo('Encrypting file with password: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw EncryptionException('File does not exist: $filePath');
      }

      // Read file content
      final fileBytes = await file.readAsBytes();

      // Derive key from password (generates new salt)
      final keyAndSalt = _deriveKeyFromPassword(password, null);
      final derivedKey = Key(keyAndSalt[0]);
      final salt = keyAndSalt[1];

      // Generate unique IV
      final iv = IV.fromSecureRandom(16);

      // Encrypt data
      final encrypter = Encrypter(AES(derivedKey));
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Prepend salt and IV to encrypted data
      // Format: [Salt (32 bytes)][IV (16 bytes)][Encrypted Data]
      final result = Uint8List(32 + 16 + encrypted.bytes.length);
      result.setRange(0, 32, salt);
      result.setRange(32, 48, iv.bytes);
      result.setRange(48, result.length, encrypted.bytes);

      // Save encrypted file
      final encryptedFilePath = '$filePath.enc';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(result);

      logInfo(
        'File encrypted with password: $filePath -> $encryptedFilePath '
        '(${fileBytes.length} bytes -> ${result.length} bytes)',
      );
      return encryptedFilePath;
    } catch (e) {
      logError('Failed to encrypt file with password', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to encrypt file with password: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Decrypt file with password
  @override
  Future<String> decryptFileWithPassword(
    String encryptedFilePath,
    String password,
  ) async {
    try {
      logInfo('Decrypting file with password: $encryptedFilePath');

      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw EncryptionException(
          'Encrypted file does not exist: $encryptedFilePath',
        );
      }

      // Read encrypted file
      final encryptedBytes = await encryptedFile.readAsBytes();

      // File format: [Salt (32 bytes)][IV (16 bytes)][Encrypted Data]
      if (encryptedBytes.length < 48) {
        throw EncryptionException(
          'Invalid encrypted file: too short (${encryptedBytes.length} bytes)',
        );
      }

      // Extract salt, IV, and encrypted data
      final salt = Uint8List.fromList(encryptedBytes.sublist(0, 32));
      final ivBytes = Uint8List.fromList(encryptedBytes.sublist(32, 48));
      final iv = IV(ivBytes);
      final encryptedData = Uint8List.fromList(encryptedBytes.sublist(48));

      // Derive key from password using extracted salt
      final keyAndSalt = _deriveKeyFromPassword(password, salt);
      final derivedKey = Key(keyAndSalt[0]);

      // Decrypt data
      final encrypter = Encrypter(AES(derivedKey));
      final encrypted = Encrypted(encryptedData);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      // Save decrypted file
      final decryptedFilePath = encryptedFilePath.replaceAll('.enc', '');
      final decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(decrypted);

      logInfo(
        'File decrypted with password: $encryptedFilePath -> $decryptedFilePath '
        '(${encryptedBytes.length} bytes -> ${decrypted.length} bytes)',
      );
      return decryptedFilePath;
    } catch (e) {
      logError('Failed to decrypt file with password', e);
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Failed to decrypt file with password: ${e.toString()}',
        originalError: e,
      );
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
