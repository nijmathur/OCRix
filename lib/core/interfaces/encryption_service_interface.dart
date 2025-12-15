/// Interface for encryption operations
abstract class IEncryptionService {
  /// Check if service is initialized
  bool get isInitialized;

  /// Initialize the encryption service
  Future<void> initialize();

  /// Encrypt text
  Future<String> encryptText(String text);

  /// Decrypt text
  Future<String> decryptText(String encryptedText);

  /// Encrypt file
  Future<String> encryptFile(String filePath);

  /// Decrypt file
  Future<String> decryptFile(String encryptedFilePath);

  /// Encrypt bytes
  Future<List<int>> encryptBytes(List<int> bytes);

  /// Decrypt bytes
  Future<List<int>> decryptBytes(List<int> encryptedBytes);

  /// Encrypt file with password (for portable exports)
  Future<String> encryptFileWithPassword(String filePath, String password);

  /// Decrypt file with password (for portable imports)
  Future<String> decryptFileWithPassword(String encryptedFilePath, String password);

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable();

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String? reason});

  /// Change encryption key
  Future<void> changeEncryptionKey();

  /// Clear encryption key
  Future<void> clearEncryptionKey();

  /// Get encryption information
  Future<Map<String, dynamic>> getEncryptionInfo();
}
