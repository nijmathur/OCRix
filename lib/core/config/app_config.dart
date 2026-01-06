import 'package:camera/camera.dart';
import '../models/audit_log_level.dart';
import '../models/log_level.dart';

/// Centralized application configuration
class AppConfig {
  // Database configuration
  static const String databaseName = 'privacy_documents.db';
  static const int databaseVersion =
      9; // Vector embeddings table fix

  // Audit database configuration (now uses main database)
  // Kept for backward compatibility, but audit_entries table is in main database
  @Deprecated('Audit now uses main database')
  static const String auditDatabaseName = 'audit_log.db';
  @Deprecated('Audit now uses main database')
  static const int auditDatabaseVersion = 1;

  // Audit logging configuration
  static const AuditLogLevel defaultAuditLogLevel = AuditLogLevel.compulsory;

  // Image processing configuration
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int jpegQuality = 85;
  static const int maxImageSizeForProcessing = 2000; // pixels

  // Thumbnail configuration
  static const int thumbnailWidth = 300;
  static const int thumbnailHeight = 300;
  static const int thumbnailQuality = 70;

  // Image quality levels for different use cases
  static const int displayQuality = 80;
  static const int storageQuality = 85;

  // OCR configuration
  static const int ocrPreprocessingMaxSize = 2000;
  static const int ocrPreprocessingQuality = 95;
  static const double ocrContrastEnhancement = 1.2;

  // Camera configuration
  static const ResolutionPreset defaultCameraResolution = ResolutionPreset.high;
  static const bool defaultCameraAudio = false;

  // Storage configuration
  static const String localStorageBasePath = 'documents';
  static const String scansDirectory = 'scans';

  // Encryption configuration
  static const int encryptionKeySize = 32; // bytes
  static const int encryptionIVSize = 16; // bytes
  static const String encryptionKeyStorageKey = 'encryption_key';

  // Search configuration
  static const int defaultSearchLimit = 50;
  static const int maxSearchLimit = 1000;

  // Sync configuration
  static const int syncRetryAttempts = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // UI configuration
  static const int documentsPerPage = 20;
  static const Duration debounceDelay = Duration(milliseconds: 300);

  // Troubleshooting log configuration
  static const String logDirectory = 'logs';
  static const String logFileName = 'app.log';
  static const Duration logRotationInterval = Duration(
    hours: 24,
  ); // Rotate every 24 hours
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB max file size
  static const LogLevel defaultLogLevel =
      LogLevel.debug; // Verbose logging by default

  // File paths
  static String get scansPath => scansDirectory;
  static String get documentsPath => localStorageBasePath;
  static String get logsPath => logDirectory;
}
