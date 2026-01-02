import 'dart:typed_data';
import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:ocrix/core/interfaces/encryption_service_interface.dart';
import 'package:ocrix/core/base/base_service.dart';
import 'package:ocrix/core/exceptions/app_exceptions.dart';

/// Mock encryption service for testing
/// Doesn't use flutter_secure_storage, so it works in unit tests
class MockEncryptionService extends BaseService implements IEncryptionService {
  Encrypter? _encrypter;
  IV? _iv;
  Key? _key;
  bool _isInitialized = false;

  @override
  String get serviceName => 'MockEncryptionService';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Generate a test key (not using secure storage)
      _key = Key.fromSecureRandom(32);
      _encrypter = Encrypter(AES(_key!));
      _iv = IV.fromSecureRandom(16);
      _isInitialized = true;
      logInfo('Mock encryption service initialized');
    } catch (e) {
      logError('Failed to initialize mock encryption service', e);
      throw EncryptionException(
        'Failed to initialize mock encryption service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> encryptText(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_encrypter == null || _iv == null) {
      throw const EncryptionException('Encryption not initialized');
    }

    final encrypted = _encrypter!.encrypt(text, iv: _iv!);
    return encrypted.base64;
  }

  @override
  Future<String> decryptText(String encryptedText) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_encrypter == null || _iv == null) {
      throw const EncryptionException('Encryption not initialized');
    }

    final encrypted = Encrypted.fromBase64(encryptedText);
    final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
    return decrypted;
  }

  @override
  Future<List<int>> encryptBytes(List<int> bytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_encrypter == null || _iv == null) {
      throw const EncryptionException('Encryption not initialized');
    }

    final encrypted = _encrypter!.encryptBytes(
      Uint8List.fromList(bytes),
      iv: _iv!,
    );
    return encrypted.bytes;
  }

  @override
  Future<List<int>> decryptBytes(List<int> encryptedBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_encrypter == null || _iv == null) {
      throw const EncryptionException('Encryption not initialized');
    }

    final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
    final decrypted = _encrypter!.decryptBytes(encrypted, iv: _iv!);
    return decrypted;
  }

  @override
  Future<String> encryptFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final encrypted = await encryptBytes(bytes);
    final encryptedFile = File('$filePath.encrypted');
    await encryptedFile.writeAsBytes(encrypted);
    return encryptedFile.path;
  }

  @override
  Future<String> decryptFile(String encryptedFilePath) async {
    final file = File(encryptedFilePath);
    final encryptedBytes = await file.readAsBytes();
    final decrypted = await decryptBytes(encryptedBytes);
    final decryptedFile = File(encryptedFilePath.replaceAll('.encrypted', ''));
    await decryptedFile.writeAsBytes(decrypted);
    return decryptedFile.path;
  }

  @override
  Future<String> encryptFileWithPassword(
    String filePath,
    String password,
  ) async {
    // Mock implementation - just use regular encrypt for testing
    return encryptFile(filePath);
  }

  @override
  Future<String> decryptFileWithPassword(
    String encryptedFilePath,
    String password,
  ) async {
    // Mock implementation - just use regular decrypt for testing
    return decryptFile(encryptedFilePath);
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return false; // Mock - not available in tests
  }

  @override
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    return false; // Mock - not available in tests
  }

  @override
  Future<void> changeEncryptionKey() async {
    // Mock implementation - just regenerate key
    _key = Key.fromSecureRandom(32);
    _encrypter = Encrypter(AES(_key!));
    _iv = IV.fromSecureRandom(16);
  }

  @override
  Future<void> clearEncryptionKey() async {
    _key = null;
    _encrypter = null;
    _iv = null;
    _isInitialized = false;
  }

  @override
  Future<Map<String, dynamic>> getEncryptionInfo() async {
    return {
      'isInitialized': _isInitialized,
      'algorithm': 'AES-256',
      'keySize': 32,
    };
  }
}
