import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Encrypter? _encrypter;
  IV? _iv;
  Key? _key;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      await _loadOrCreateKey();
      _isInitialized = true;
      _logger.i('Encryption service initialized');
    } catch (e) {
      _logger.e('Failed to initialize encryption service: $e');
      rethrow;
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
        _logger.i('New encryption key generated');
      } else {
        // Load existing key
        _key = Key.fromBase64(keyString);
        _logger.i('Existing encryption key loaded');
      }

      _encrypter = Encrypter(AES(_key!));
      _iv = IV.fromSecureRandom(16);
    } catch (e) {
      _logger.e('Failed to load or create encryption key: $e');
      rethrow;
    }
  }

  Future<String> encryptText(String text) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = _encrypter!.encrypt(text, iv: _iv!);
      _logger.i('Text encrypted successfully');
      return encrypted.base64;
    } catch (e) {
      _logger.e('Failed to encrypt text: $e');
      rethrow;
    }
  }

  Future<String> decryptText(String encryptedText) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      _logger.i('Text decrypted successfully');
      return decrypted;
    } catch (e) {
      _logger.e('Failed to decrypt text: $e');
      rethrow;
    }
  }

  Future<Uint8List> encryptBytes(Uint8List data) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = _encrypter!.encryptBytes(data, iv: _iv!);
      _logger.i(
          'Bytes encrypted successfully: ${data.length} -> ${encrypted.bytes.length}');
      return encrypted.bytes;
    } catch (e) {
      _logger.e('Failed to encrypt bytes: $e');
      rethrow;
    }
  }

  Future<Uint8List> decryptBytes(Uint8List encryptedData) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_encrypter == null || _iv == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = Encrypted(encryptedData);
      final decrypted = _encrypter!.decryptBytes(encrypted, iv: _iv!);
      _logger.i(
          'Bytes decrypted successfully: ${encryptedData.length} -> ${decrypted.length}');
      return Uint8List.fromList(decrypted);
    } catch (e) {
      _logger.e('Failed to decrypt bytes: $e');
      rethrow;
    }
  }

  Future<String> encryptFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final bytes = await file.readAsBytes();
      final encryptedBytes = await encryptBytes(bytes);

      // Save encrypted file with .enc extension
      final encryptedFilePath = '$filePath.enc';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      _logger.i('File encrypted: $filePath -> $encryptedFilePath');
      return encryptedFilePath;
    } catch (e) {
      _logger.e('Failed to encrypt file: $e');
      rethrow;
    }
  }

  Future<String> decryptFile(String encryptedFilePath) async {
    try {
      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file does not exist: $encryptedFilePath');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = await decryptBytes(encryptedBytes);

      // Remove .enc extension
      final decryptedFilePath = encryptedFilePath.replaceAll('.enc', '');
      final decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(decryptedBytes);

      _logger.i('File decrypted: $encryptedFilePath -> $decryptedFilePath');
      return decryptedFilePath;
    } catch (e) {
      _logger.e('Failed to decrypt file: $e');
      rethrow;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _logger.w('No biometrics enrolled');
        return false;
      }

      // Authenticate
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access encrypted documents',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger.w('Biometric authentication failed');
      }

      return isAuthenticated;
    } catch (e) {
      _logger.e('Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return isAvailable && availableBiometrics.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check biometric availability: $e');
      return false;
    }
  }

  String generateHash(String data) {
    try {
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      _logger.e('Failed to generate hash: $e');
      rethrow;
    }
  }

  String generateFileHash(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist: $filePath');
      }

      final bytes = file.readAsBytesSync();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      _logger.e('Failed to generate file hash: $e');
      rethrow;
    }
  }

  Future<bool> verifyFileIntegrity(String filePath, String expectedHash) async {
    try {
      final actualHash = generateFileHash(filePath);
      final isValid = actualHash == expectedHash;

      if (!isValid) {
        _logger.w('File integrity check failed for: $filePath');
      } else {
        _logger.i('File integrity verified for: $filePath');
      }

      return isValid;
    } catch (e) {
      _logger.e('Failed to verify file integrity: $e');
      return false;
    }
  }

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

      _logger.i('Encryption key changed successfully');
    } catch (e) {
      _logger.e('Failed to change encryption key: $e');
      rethrow;
    }
  }

  Future<void> clearEncryptionKey() async {
    try {
      await _secureStorage.delete(key: 'encryption_key');
      _key = null;
      _encrypter = null;
      _iv = null;
      _isInitialized = false;
      _logger.i('Encryption key cleared');
    } catch (e) {
      _logger.e('Failed to clear encryption key: $e');
      rethrow;
    }
  }

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
      _logger.e('Failed to get encryption info: $e');
      return {};
    }
  }
}
