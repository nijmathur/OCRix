class AppConstants {
  // App Information
  static const String appName = 'Privacy Document Scanner';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A privacy-first document scanner and search app with flexible storage providers';

  // Database
  static const String databaseName = 'privacy_documents.db';
  static const int databaseVersion = 1;

  // Storage
  static const String documentsFolder = 'documents';
  static const String scansFolder = 'scans';
  static const String backupsFolder = 'backups';
  static const String tempFolder = 'temp';

  // Encryption
  static const String encryptionKeyStorageKey = 'encryption_key';
  static const int encryptionKeyLength = 32;
  static const int ivLength = 16;

  // OCR
  static const double defaultOCRConfidenceThreshold = 0.7;
  static const int maxImageWidth = 2000;
  static const int maxImageHeight = 2000;
  static const int imageQuality = 95;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // File Extensions
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.bmp',
    '.gif',
    '.webp',
  ];

  static const List<String> supportedDocumentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.rtf',
  ];

  // Document Types
  static const Map<String, String> documentTypeIcons = {
    'receipt': 'receipt',
    'contract': 'description',
    'manual': 'menu_book',
    'invoice': 'request_quote',
    'businessCard': 'contact_page',
    'id': 'badge',
    'passport': 'travel_explore',
    'license': 'card_membership',
    'certificate': 'workspace_premium',
    'other': 'insert_drive_file',
  };

  // Storage Providers
  static const Map<String, String> storageProviderNames = {
    'local': 'Local Storage',
    'googleDrive': 'Google Drive',
    'oneDrive': 'OneDrive',
    'dropbox': 'Dropbox',
    'box': 'Box',
  };

  // Privacy & Support
  // TODO: Configure these URLs before enabling privacy policy/terms features
  // These are intentionally not set to prevent users from being misled by
  // placeholder URLs. Uncomment and set real values before using.
  // static const String privacyPolicyUrl = 'https://yourwebsite.com/privacy';
  // static const String termsOfServiceUrl = 'https://yourwebsite.com/terms';
  // static const String supportEmail = 'support@yourapp.com';

  // Sync
  static const int defaultSyncIntervalMinutes = 60;
  static const int maxSyncRetries = 3;
  static const Duration syncTimeout = Duration(minutes: 5);

  // Backup
  static const int maxBackupFiles = 10;
  static const Duration backupRetentionDays = Duration(days: 30);

  // Search
  static const int maxSearchResults = 100;
  static const int searchDebounceMs = 300;

  // Camera
  static const double cameraAspectRatio = 4.0 / 3.0;
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB

  // Error Messages
  static const String errorGeneric = 'An unexpected error occurred';
  static const String errorNetwork = 'Network connection error';
  static const String errorStorage = 'Storage error';
  static const String errorPermission = 'Permission denied';
  static const String errorCamera = 'Camera error';
  static const String errorOCR = 'OCR processing error';
  static const String errorEncryption = 'Encryption error';

  // Success Messages
  static const String successDocumentSaved = 'Document saved successfully';
  static const String successDocumentDeleted = 'Document deleted successfully';
  static const String successDocumentUpdated = 'Document updated successfully';
  static const String successSettingsSaved = 'Settings saved successfully';
  static const String successBackupCreated = 'Backup created successfully';
  static const String successSyncCompleted = 'Sync completed successfully';
}
