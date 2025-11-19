/// Base exception for application errors
sealed class AppException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Encryption-related exceptions
class EncryptionException extends AppException {
  const EncryptionException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// OCR-related exceptions
class OCRException extends AppException {
  const OCRException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Camera-related exceptions
class CameraException extends AppException {
  const CameraException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Image processing exceptions
class ImageProcessingException extends AppException {
  const ImageProcessingException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}
